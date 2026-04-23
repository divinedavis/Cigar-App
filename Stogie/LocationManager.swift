import Foundation
import CoreLocation
import MapKit

/// Wraps CoreLocation + MKLocalSearch to find cigar lounges near the user.
///
/// MapKit has no dedicated POI category for tobacco shops, so we run
/// keyword searches ("cigar lounge", "cigar shop", "tobacconist",
/// "humidor") in parallel, dedupe by coordinate, and return results
/// within ~400m of the user.
@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var nearbyStores: [CigarStore] = []
    @Published var isSearching = false

    private let manager = CLLocationManager()
    private let radiusMeters: CLLocationDistance = 400

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func refreshNearbyCigarStores() async {
        guard let loc = manager.location else {
            manager.requestLocation()
            return
        }
        await search(around: loc.coordinate)
    }

    private func search(around coordinate: CLLocationCoordinate2D) async {
        isSearching = true
        defer { isSearching = false }

        let queries = ["cigar lounge", "cigar shop", "tobacconist", "humidor", "cigar bar"]
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radiusMeters * 2,
            longitudinalMeters: radiusMeters * 2
        )

        var collected: [CigarStore] = []
        for query in queries {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = region
            request.resultTypes = .pointOfInterest
            do {
                let response = try await MKLocalSearch(request: request).start()
                for item in response.mapItems {
                    let placemark = item.placemark
                    let center = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    let here = CLLocation(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude)
                    if center.distance(from: here) > radiusMeters { continue }
                    let store = CigarStore(
                        id: UUID(),
                        name: item.name ?? placemark.name ?? "Cigar lounge",
                        address: Self.formatAddress(placemark),
                        latitude: placemark.coordinate.latitude,
                        longitude: placemark.coordinate.longitude
                    )
                    if !collected.contains(where: { abs($0.latitude - store.latitude) < 0.0001
                        && abs($0.longitude - store.longitude) < 0.0001 }) {
                        collected.append(store)
                    }
                }
            } catch {
                continue
            }
        }

        // Sort by distance, closest first.
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        collected.sort {
            origin.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))
                < origin.distance(from: CLLocation(latitude: $1.latitude, longitude: $1.longitude))
        }
        nearbyStores = collected
    }

    private static func formatAddress(_ placemark: MKPlacemark) -> String {
        [placemark.subThoroughfare, placemark.thoroughfare, placemark.locality, placemark.administrativeArea]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            await self.search(around: loc.coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
