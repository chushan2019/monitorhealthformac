import Foundation

/// Stub process collector - returns empty process list.
/// Real ProcessCollector disabled due to Swift 6 struct layout issues.
final class ProcessCollectorStub: MetricCollector {
    typealias Snapshot = ProcessStats
    struct PreviousState {
        var timestamp: Date
    }
    var label: String { "Processes" }

    func collect(previous: PreviousState?) -> (Snapshot, PreviousState?) {
        return (ProcessStats(topProcesses: []), PreviousState(timestamp: Date()))
    }
}

// Keep the original collector code for future use
import Darwin

/// Collects per-process CPU and memory usage via libproc.
/// TODO: Re-enable after fixing Swift 6 struct layout issues
final class ProcessCollector: MetricCollector {
    typealias Snapshot = ProcessStats
    struct PreviousState {
        var cpuTimeMap: [Int: UInt64]
        var timestamp: Date
    }
    var label: String { "Processes" }

    func collect(previous: PreviousState?) -> (Snapshot, PreviousState?) {
        return (ProcessStats(topProcesses: []), PreviousState(cpuTimeMap: [:], timestamp: Date()))
    }
}
