import Foundation

/// Stub collector that returns unavailable stats.
/// Used for fallback when real collectors fail.
final class StubCollector<Snapshot: Equatable> {
    let stub: Snapshot
    init(_ stub: Snapshot) { self.stub = stub }
}
