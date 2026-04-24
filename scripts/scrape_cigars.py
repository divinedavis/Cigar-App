#!/usr/bin/env python3
"""Scrape cigarsinternational.com into cigars.json and push photos to Supabase Storage.

    pip install curl-cffi beautifulsoup4

    python3 scripts/scrape_cigars.py discover             # sitemap -> urls.txt
    python3 scripts/scrape_cigars.py scrape [--limit N]   # urls.txt -> cigars.jsonl (resumable)
    python3 scripts/scrape_cigars.py upload               # jsonl + local images -> Supabase
    python3 scripts/scrape_cigars.py export               # jsonl -> cigars.json (final)
    python3 scripts/scrape_cigars.py all

The site is behind Cloudflare so we impersonate Chrome 124 via curl-cffi.
"""
import argparse
import hashlib
import json
import logging
import mimetypes
import os
import random
import re
import sys
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set
from urllib.parse import urljoin, urlparse
from xml.etree import ElementTree as ET

try:
    from curl_cffi import requests  # Cloudflare-friendly HTTP client
except ImportError:
    print("Missing dependency: pip install curl-cffi", file=sys.stderr)
    sys.exit(1)

try:
    from bs4 import BeautifulSoup
except ImportError:
    print("Missing dependency: pip install beautifulsoup4", file=sys.stderr)
    sys.exit(1)

# --- paths + config ---------------------------------------------------------

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "scripts" / "cigars_data"
DATA.mkdir(parents=True, exist_ok=True)
URLS_FILE   = DATA / "urls.txt"
JSONL_FILE  = DATA / "cigars.jsonl"
FINAL_JSON  = DATA / "cigars.json"
IMG_DIR     = DATA / "images"
IMG_DIR.mkdir(exist_ok=True)

BASE = "https://www.cigarsinternational.com"
SITEMAP_INDEX = f"{BASE}/sitemap_index.xml"
IMPERSONATE = "chrome124"

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s",
                    datefmt="%H:%M:%S")
log = logging.getLogger("scrape")

# --- data model -------------------------------------------------------------

@dataclass
class ShapeImage:
    shape: str                 # e.g. "Robusto"
    dimensions: Optional[str]  # e.g. '5.2" x 50'
    source_url: str            # original image URL on cigarsinternational
    storage_path: Optional[str] = None  # supabase path once uploaded
    public_url: Optional[str] = None


@dataclass
class Cigar:
    slug: str                  # stable id, e.g. "arturo-fuente-don-carlos-ADA-PM"
    source_url: str
    name: str                  # from <h1>
    brand: Optional[str] = None
    shapes: List[str] = field(default_factory=list)
    wrapper: Optional[str] = None
    origin: Optional[str] = None
    binder: Optional[str] = None
    fillers: Optional[str] = None
    is_flavored: Optional[bool] = None
    has_tip: Optional[bool] = None
    is_sweet: Optional[bool] = None
    is_machine_made: Optional[bool] = None
    profile: Optional[str] = None
    summary: Optional[str] = None
    hero_image: Optional[ShapeImage] = None
    size_images: List[ShapeImage] = field(default_factory=list)

# --- http helpers -----------------------------------------------------------

def polite_sleep(min_s: float = 1.2, max_s: float = 2.4) -> None:
    time.sleep(random.uniform(min_s, max_s))


def http_get(url: str, *, tries: int = 3, timeout: int = 30) -> Optional[requests.Response]:
    for attempt in range(1, tries + 1):
        try:
            r = requests.get(url, impersonate=IMPERSONATE, timeout=timeout)
            if r.status_code == 200:
                return r
            log.warning("GET %s -> %s (try %d)", url, r.status_code, attempt)
        except Exception as exc:
            log.warning("GET %s threw %s (try %d)", url, exc, attempt)
        time.sleep(2 * attempt)
    return None

# --- discovery --------------------------------------------------------------

def _locs(xml_text: str) -> List[str]:
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError:
        return re.findall(r"<loc>([^<]+)</loc>", xml_text)
    ns = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
    return [e.text for e in root.findall(".//sm:loc", ns) if e.text]


def discover_urls() -> List[str]:
    """Walk the sitemap index and return all product URLs."""
    index = http_get(SITEMAP_INDEX)
    if index is None:
        raise SystemExit("failed to fetch sitemap index")

    product_urls: Set[str] = set()
    for sm in _locs(index.text):
        if "product" not in sm.lower():
            continue
        log.info("sitemap %s", sm)
        sub = http_get(sm)
        if sub is None:
            continue
        for loc in _locs(sub.text):
            if "/product/" in loc:
                product_urls.add(loc)
        polite_sleep(0.2, 0.5)

    return sorted(product_urls)


def cmd_discover(args: argparse.Namespace) -> None:
    urls = discover_urls()
    URLS_FILE.write_text("\n".join(urls) + "\n")
    log.info("wrote %d urls to %s", len(urls), URLS_FILE)

# --- parsing ----------------------------------------------------------------

_DIM_RE = re.compile(r'(\d+(?:\.\d+)?)\s*"\s*x\s*(\d+)', re.I)
# Match the LAST parenthesized group as the dimension; anything before is the shape.
# Handles 'No. 2 (Belicoso) (6.0" x 54)' -> shape='No. 2 (Belicoso)', dim='6.0" x 54'.
_SHAPE_FROM_ALT = re.compile(r"""^\s*(?P<shape>.+?)\s*\((?P<dim>[^()]*)\)\s*$""")


def _to_bool(raw: str) -> Optional[bool]:
    s = (raw or "").strip().lower()
    if s in ("true", "yes"): return True
    if s in ("false", "no"): return False
    return None


def _clean_ws(text: str) -> str:
    return re.sub(r"\s+", " ", text or "").strip()


def _summarize(text: str, sentences: int = 3, max_len: int = 320) -> Optional[str]:
    if not text:
        return None
    text = _clean_ws(text)
    parts = re.split(r"(?<=[.!?])\s+", text)
    summary = " ".join(parts[:sentences]).strip()
    if len(summary) > max_len:
        summary = summary[: max_len - 1].rsplit(" ", 1)[0] + "…"
    return summary or None


def slug_from_url(url: str) -> str:
    path = urlparse(url).path.strip("/")
    # /product/arturo-fuente-don-carlos/ADA-PM.html -> arturo-fuente-don-carlos-ADA-PM
    path = re.sub(r"^product/", "", path)
    path = re.sub(r"\.html?$", "", path, flags=re.I)
    return re.sub(r"[^a-zA-Z0-9._-]+", "-", path).strip("-")


def _extract_jsonld_product(soup: BeautifulSoup) -> Optional[dict]:
    """Return the first Product JSON-LD blob on the page, flattened if wrapped."""
    for tag in soup.find_all("script", type="application/ld+json"):
        raw = (tag.string or tag.get_text("") or "").strip()
        if not raw:
            continue
        try:
            blob = json.loads(raw)
        except Exception:
            continue

        def find_product(node):
            if isinstance(node, dict):
                if node.get("@type") == "Product":
                    return node
                for v in node.values():
                    hit = find_product(v)
                    if hit: return hit
            elif isinstance(node, list):
                for v in node:
                    hit = find_product(v)
                    if hit: return hit
            return None

        product = find_product(blob)
        if product:
            return product
    return None


def parse_product(url: str, html: str) -> Optional[Cigar]:
    soup = BeautifulSoup(html, "html.parser")

    h1 = soup.find("h1")
    if not h1:
        return None
    name = _clean_ws(h1.get_text())

    cigar = Cigar(slug=slug_from_url(url), source_url=url, name=name)

    # Key/value attribute grid.
    seen: Set[str] = set()
    for label in soup.select(".pd-attribute-label"):
        lbl = _clean_ws(label.get_text()).rstrip("?")
        val_node = label.find_next(class_="pd-attribute-value")
        if not val_node:
            continue
        value = _clean_ws(val_node.get_text())
        key = lbl.lower()
        if key in seen:
            continue
        seen.add(key)
        if key == "shape":
            cigar.shapes = [s.strip() for s in re.split(r",\s*", value) if s.strip()]
        elif key == "wrapper":
            cigar.wrapper = value or None
        elif key == "origin":
            cigar.origin = value or None
        elif key == "binder":
            cigar.binder = value or None
        elif key == "fillers":
            cigar.fillers = value or None
        elif key == "profile":
            cigar.profile = value or None
        elif key == "is flavored":
            cigar.is_flavored = _to_bool(value)
        elif key == "has tip":
            cigar.has_tip = _to_bool(value)
        elif key == "is sweet":
            cigar.is_sweet = _to_bool(value)
        elif key == "is machine made":
            cigar.is_machine_made = _to_bool(value)
        elif key == "brand":
            cigar.brand = value or None

    # JSON-LD Product block — best source for the hero image + description.
    jsonld = _extract_jsonld_product(soup)
    hero_from_ld: Optional[str] = None
    if jsonld:
        if not cigar.brand and isinstance(jsonld.get("brand"), dict):
            cigar.brand = jsonld["brand"].get("name") or cigar.brand
        imgs = jsonld.get("image")
        if isinstance(imgs, str):
            hero_from_ld = imgs
        elif isinstance(imgs, list) and imgs:
            hero_from_ld = imgs[0]

    # Description: JSON-LD -> dedicated section -> prose <p> mentioning the brand -> meta fallback.
    desc_txt = (jsonld or {}).get("description") or ""
    if not desc_txt:
        for sel in [".pd-description", ".product-description", ".pd-copy",
                    ".product-details-description", "[itemprop=description]",
                    ".pdp-description", ".product-overview"]:
            node = soup.select_one(sel)
            if node and node.get_text(strip=True):
                desc_txt = node.get_text(" ", strip=True)
                break
    if not desc_txt:
        brand_tokens = [t.lower() for t in (cigar.brand or name).split() if len(t) > 2]
        best = ""
        for p in soup.find_all(["p", "div"]):
            txt = _clean_ws(p.get_text(" "))
            if len(txt) < 150 or len(txt) > 1500:
                continue
            low = txt.lower()
            if any(skip in low for skip in ("javascript", "shopping cart", "sign up", "email address", "subscribe")):
                continue
            if any(tok in low for tok in brand_tokens) and len(txt) > len(best):
                best = txt
        desc_txt = best
    if not desc_txt:
        meta = soup.find("meta", attrs={"name": "description"})
        if meta and meta.get("content"):
            desc_txt = meta["content"]
    cigar.summary = _summarize(desc_txt)

    # Per-vitola images ship with alt text like:  'Robusto (5.2" x 50)'
    for img in soup.find_all("img"):
        alt = (img.get("alt") or "").strip()
        src = img.get("src") or img.get("data-src") or ""
        if not src or not alt:
            continue
        m = _SHAPE_FROM_ALT.match(alt)
        if not m:
            continue
        dim = m.group("dim").strip()
        if not _DIM_RE.search(dim):
            continue
        shape = _clean_ws(m.group("shape"))
        full = urljoin(url, src)
        cigar.size_images.append(ShapeImage(shape=shape, dimensions=dim, source_url=full))

    # Hero image: JSON-LD -> any img carrying data-lazy to a high-res /CI/ URL
    # -> first size image.
    hero_src = hero_from_ld
    if not hero_src:
        for img in soup.find_all("img"):
            for attr in ("data-lazy", "data-zoom-image", "data-main-image",
                         "data-src", "src"):
                v = img.get(attr) or ""
                if "/dw/image/" in v and "/CI/" in v and "/PSI/" not in v and v.endswith((".png", ".jpg", ".jpeg", ".webp")):
                    hero_src = v
                    break
            if hero_src:
                break
    if not hero_src and cigar.size_images:
        hero_src = cigar.size_images[0].source_url
    if hero_src:
        # Strip Scene7 query params so we get the native resolution.
        hero_src = hero_src.split("?")[0]
        cigar.hero_image = ShapeImage(shape="Hero", dimensions=None,
                                      source_url=urljoin(url, hero_src))

    return cigar

# --- scrape loop ------------------------------------------------------------

def _looks_like_cigar(cigar: Cigar) -> bool:
    # Skip humidors, accessories, samplers, etc. — they have no cigar specs.
    return bool(cigar.wrapper or cigar.origin or cigar.binder or cigar.fillers or cigar.shapes)


def _load_scraped_slugs() -> Set[str]:
    if not JSONL_FILE.exists():
        return set()
    done = set()
    with JSONL_FILE.open() as fh:
        for line in fh:
            try:
                done.add(json.loads(line)["slug"])
            except Exception:
                continue
    return done


def cmd_scrape(args: argparse.Namespace) -> None:
    if not URLS_FILE.exists():
        raise SystemExit("run `discover` first to populate urls.txt")
    urls = [u.strip() for u in URLS_FILE.read_text().splitlines() if u.strip()]
    done = _load_scraped_slugs()
    log.info("%d urls, %d already scraped", len(urls), len(done))

    processed = 0
    with JSONL_FILE.open("a") as sink:
        for url in urls:
            slug = slug_from_url(url)
            if slug in done:
                continue
            if args.limit and processed >= args.limit:
                break
            r = http_get(url)
            if r is None:
                continue
            try:
                cigar = parse_product(url, r.text)
            except Exception as exc:
                log.exception("parse failed for %s: %s", url, exc)
                continue
            if cigar is None:
                continue
            if args.only_cigars and not _looks_like_cigar(cigar):
                log.debug("skip non-cigar %s", url)
                continue
            sink.write(json.dumps(_asdict(cigar)) + "\n")
            sink.flush()
            processed += 1
            log.info("[%d] %s", processed, cigar.name)
            polite_sleep()

    log.info("scraped %d new records -> %s", processed, JSONL_FILE)


def _asdict(c: Cigar) -> dict:
    d = asdict(c)
    # Drop None-valued keys for a tidy JSON output.
    def prune(o):
        if isinstance(o, dict):
            return {k: prune(v) for k, v in o.items() if v is not None}
        if isinstance(o, list):
            return [prune(x) for x in o]
        return o
    return prune(d)

# --- image download ---------------------------------------------------------

def _local_image_path(slug: str, source_url: str, suffix: str = "") -> Path:
    ext = Path(urlparse(source_url).path).suffix.lower() or ".jpg"
    if ext not in (".jpg", ".jpeg", ".png", ".webp", ".gif"):
        ext = ".jpg"
    # One hash per source URL so we don't clobber different images for the same cigar.
    h = hashlib.sha1(source_url.encode()).hexdigest()[:10]
    tail = f"-{suffix}" if suffix else ""
    return IMG_DIR / slug / f"{h}{tail}{ext}"


def _download_image(source_url: str, dest: Path) -> bool:
    if dest.exists() and dest.stat().st_size > 0:
        return True
    dest.parent.mkdir(parents=True, exist_ok=True)
    r = http_get(source_url)
    if r is None:
        return False
    dest.write_bytes(r.content)
    return True

# --- supabase upload --------------------------------------------------------

def _load_env() -> dict:
    env_path = ROOT / "scripts" / "scraper.env"
    if not env_path.exists():
        raise SystemExit(f"create {env_path} from scraper.env.example")
    env = {}
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip()
    for required in ("SUPABASE_URL", "SUPABASE_KEY", "SUPABASE_BUCKET"):
        if not env.get(required):
            raise SystemExit(f"{required} missing in scraper.env")
    return env


def _supabase_upload(env: Dict[str, str], local: Path, path: str) -> Optional[str]:
    """Upload a single file to Storage; return the public URL."""
    bucket = env["SUPABASE_BUCKET"]
    endpoint = f"{env['SUPABASE_URL']}/storage/v1/object/{bucket}/{path}"
    content_type = mimetypes.guess_type(local.name)[0] or "application/octet-stream"
    headers = {
        "Authorization": f"Bearer {env['SUPABASE_KEY']}",
        "apikey": env["SUPABASE_KEY"],
        "Content-Type": content_type,
        "x-upsert": "true",
        "Cache-Control": "public, max-age=31536000, immutable",
    }
    with local.open("rb") as fh:
        r = requests.post(endpoint, data=fh.read(), headers=headers, impersonate=IMPERSONATE, timeout=60)
    if r.status_code not in (200, 201):
        log.warning("upload %s -> %s %s", path, r.status_code, r.text[:200])
        return None
    return f"{env['SUPABASE_URL']}/storage/v1/object/public/{bucket}/{path}"


def cmd_upload(args: argparse.Namespace) -> None:
    if not JSONL_FILE.exists():
        raise SystemExit("nothing to upload — run `scrape` first")
    env = _load_env()

    records: List[dict] = []
    with JSONL_FILE.open() as fh:
        for line in fh:
            if line.strip():
                records.append(json.loads(line))

    updated = 0
    for rec in records:
        slug = rec["slug"]
        images = []
        if rec.get("hero_image"):
            images.append(("hero", rec["hero_image"]))
        for i, si in enumerate(rec.get("size_images", [])):
            images.append((f"size-{i}", si))

        for tag, img in images:
            if img.get("public_url"):
                continue
            if not img.get("source_url"):
                continue
            local = _local_image_path(slug, img["source_url"], suffix=tag)
            if not _download_image(img["source_url"], local):
                continue
            storage_path = f"{slug}/{local.name}"
            public = _supabase_upload(env, local, storage_path)
            if public:
                img["storage_path"] = storage_path
                img["public_url"] = public
                updated += 1
            polite_sleep(0.1, 0.3)

    # Rewrite JSONL with updated URLs.
    with JSONL_FILE.open("w") as fh:
        for rec in records:
            fh.write(json.dumps(rec) + "\n")
    log.info("uploaded %d images", updated)


def cmd_export(args: argparse.Namespace) -> None:
    if not JSONL_FILE.exists():
        raise SystemExit("run `scrape` first")
    records = []
    with JSONL_FILE.open() as fh:
        for line in fh:
            if line.strip():
                records.append(json.loads(line))
    FINAL_JSON.write_text(json.dumps({"cigars": records}, indent=2))
    log.info("wrote %s (%d cigars)", FINAL_JSON, len(records))

# --- CLI --------------------------------------------------------------------

def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("discover", help="populate urls.txt from the sitemap").set_defaults(fn=cmd_discover)

    sp = sub.add_parser("scrape", help="fetch product pages, append to cigars.jsonl")
    sp.add_argument("--limit", type=int, default=0, help="stop after N new records")
    sp.add_argument("--only-cigars", action="store_true",
                    help="skip humidors/accessories (records with no wrapper/origin/shape)")
    sp.set_defaults(fn=cmd_scrape)

    sub.add_parser("upload", help="upload images to Supabase Storage").set_defaults(fn=cmd_upload)
    sub.add_parser("export", help="collapse jsonl -> cigars.json").set_defaults(fn=cmd_export)

    sp = sub.add_parser("all", help="discover + scrape + upload + export")
    sp.add_argument("--limit", type=int, default=0)
    sp.add_argument("--only-cigars", action="store_true", default=True)
    sp.set_defaults(fn=None)

    args = p.parse_args()
    if args.cmd == "all":
        cmd_discover(args); cmd_scrape(args); cmd_upload(args); cmd_export(args)
    else:
        args.fn(args)


if __name__ == "__main__":
    main()
