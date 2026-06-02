import Foundation

/// Protocol for all metric collectors.
/// `Snapshot` is the high-level stats type (e.g. CPUStats).
/// `PreviousState` carries raw counters between ticks for delta-based computation.
protocol MetricCollector: AnyObject {
    associatedtype Snapshot
    associatedtype PreviousState

    /// Collect current metrics. Returns snapshot and optional previous state for next tick.
    func collect(previous: PreviousState?) -> (Snapshot, PreviousState?)

    /// Human-readable label for this collector (e.g. "CPU", "Memory")
    var label: String { get }
}
