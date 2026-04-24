#!/usr/bin/env python3
"""Idempotently create the Maduro app record in App Store Connect.

Reads scripts/asc-config.env for credentials. Performs:
  1. Register the bundle ID in the developer portal if missing.
  2. Create the App Store Connect app record if missing.
  3. Write the resulting ASC_APP_ID back into asc-config.env so
     subsequent ship.sh runs can reference it.

Safe to run multiple times — each step is a no-op when the resource
already exists.
"""
from __future__ import annotations

import os
import sys
import time
import json
import pathlib
import jwt
import requests


CONFIG_PATH = pathlib.Path(__file__).resolve().parent / "asc-config.env"
API_BASE = "https://api.appstoreconnect.apple.com/v1"

APP_NAME = "Maduro"
SKU = "maduro-ios-001"
PRIMARY_LOCALE = "en-US"


def load_config() -> dict:
    if not CONFIG_PATH.exists():
        raise SystemExit(f"missing {CONFIG_PATH}. copy from .example and fill in.")
    cfg: dict = {}
    for line in CONFIG_PATH.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, _, value = line.partition("=")
        value = value.strip().strip('"').strip("'")
        value = os.path.expandvars(value)
        cfg[key.strip()] = value
    return cfg


def write_app_id(app_id: str) -> None:
    """Persist ASC_APP_ID back into asc-config.env."""
    lines = CONFIG_PATH.read_text().splitlines()
    out = []
    found = False
    for line in lines:
        if line.startswith("ASC_APP_ID="):
            out.append(f"ASC_APP_ID={app_id}")
            found = True
        else:
            out.append(line)
    if not found:
        out.append(f"ASC_APP_ID={app_id}")
    CONFIG_PATH.write_text("\n".join(out) + "\n")


def make_token(cfg: dict) -> str:
    private_key = pathlib.Path(cfg["ASC_KEY_PATH"]).read_text()
    headers = {"alg": "ES256", "kid": cfg["ASC_KEY_ID"], "typ": "JWT"}
    payload = {
        "iss": cfg["ASC_ISSUER_ID"],
        "exp": int(time.time()) + 20 * 60,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, private_key, algorithm="ES256", headers=headers)


def get_bundle_id(token: str, identifier: str) -> dict | None:
    r = requests.get(
        f"{API_BASE}/bundleIds",
        params={"filter[identifier]": identifier, "limit": 1},
        headers={"Authorization": f"Bearer {token}"},
        timeout=30,
    )
    r.raise_for_status()
    data = r.json().get("data") or []
    return data[0] if data else None


def create_bundle_id(token: str, identifier: str, name: str) -> dict:
    body = {
        "data": {
            "type": "bundleIds",
            "attributes": {
                "identifier": identifier,
                "name": name,
                "platform": "IOS",
            },
        }
    }
    r = requests.post(
        f"{API_BASE}/bundleIds",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        data=json.dumps(body),
        timeout=30,
    )
    if r.status_code >= 300:
        raise SystemExit(f"create bundleId failed: {r.status_code} {r.text}")
    return r.json()["data"]


def get_app(token: str, bundle_id: str) -> dict | None:
    r = requests.get(
        f"{API_BASE}/apps",
        params={"filter[bundleId]": bundle_id, "limit": 1},
        headers={"Authorization": f"Bearer {token}"},
        timeout=30,
    )
    r.raise_for_status()
    data = r.json().get("data") or []
    return data[0] if data else None


def create_app(token: str, bundle_id_record_id: str) -> dict:
    body = {
        "data": {
            "type": "apps",
            "attributes": {
                "bundleId": "com.divinedavis.stogie",
                "name": APP_NAME,
                "primaryLocale": PRIMARY_LOCALE,
                "sku": SKU,
            },
            "relationships": {
                "bundleId": {
                    "data": {"type": "bundleIds", "id": bundle_id_record_id}
                }
            },
        }
    }
    r = requests.post(
        f"{API_BASE}/apps",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        data=json.dumps(body),
        timeout=30,
    )
    if r.status_code >= 300:
        raise SystemExit(f"create app failed: {r.status_code} {r.text}")
    return r.json()["data"]


def main() -> int:
    cfg = load_config()
    token = make_token(cfg)
    identifier = cfg["ASC_BUNDLE_ID"]

    # 1. Bundle ID -------------------------------------------------
    bundle = get_bundle_id(token, identifier)
    if bundle:
        print(f"==> bundle id {identifier} already registered (id {bundle['id']})")
    else:
        print(f"==> registering bundle id {identifier}")
        bundle = create_bundle_id(token, identifier, APP_NAME)
        print(f"    created (id {bundle['id']})")

    # 2. App record ------------------------------------------------
    # Apple's ASC API forbids POST /v1/apps for most teams — the app
    # record must be created once in the ASC web UI. After that this
    # script picks it up and proceeds.
    app = get_app(token, identifier)
    if app:
        print(f"==> app record already exists (id {app['id']})")
        write_app_id(app["id"])
        print(f"==> wrote ASC_APP_ID={app['id']} to asc-config.env")
        return 0

    print(
        "\n!! No App Store Connect app record exists for "
        f"{identifier}.\n"
        "   Apple's API does not allow creating apps programmatically.\n"
        "   One-time manual step:\n"
        "     1. https://appstoreconnect.apple.com/apps\n"
        "     2. Click + (top left) -> New App\n"
        f"     3. Platform: iOS, Name: {APP_NAME}, Primary Language: English (U.S.)\n"
        f"        Bundle ID: {identifier} (already registered)\n"
        f"        SKU: {SKU}\n"
        "     4. Click Create.\n"
        "   Then re-run this script and ship.sh — both will pick up the new app id.\n"
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
