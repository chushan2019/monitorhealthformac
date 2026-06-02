import Foundation
import IOKit

/// Collects disk I/O via IOKit IOBlockStorageDriver statistics.
/// Reads total Bytes (Read) and Bytes (Write) from all block storage devices.
/// Uses string literals for IOKit keys since Swift 6 doesn't expose them.
final class DiskIOCollector: MetricCollector {
    typealias Snapshot = DiskIOStats

    struct PreviousState {
        var totalRead: UInt64
        var totalWrite: UInt64
        var timestamp: Date
    }

    var label: String { "Disk I/O" }

    func collect(previous: PreviousState?) -> (Snapshot, PreviousState?) {
        var totalRead: UInt64 = 0
        var totalWrite: UInt64 = 0

        // IOKit class name for block storage drivers
        let matching = IOServiceMatching("IOBlockStorageDriver")
        var iterator = io_iterator_t()
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard kr == KERN_SUCCESS else { return (.unavailable, nil) }
        defer { IOObjectRelease(iterator) }

        while case let service = IOIteratorNext(iterator), service != IO_OBJECT_NULL {
            defer { IOObjectRelease(service) }
            // Statistics dictionary key name
            if let stats = IORegistryEntryCreateCFProperty(
                service,
                "Statistics" as CFString,
                kCFAllocatorDefault,
                0
            ).takeRetainedValue() as? [String: Any] {
                totalRead  += stats["Bytes (Read)"]  as? UInt64 ?? 0
                totalWrite += stats["Bytes (Write)"] as? UInt64 ?? 0
            }
        }

        let now = Date()
        guard let prev = previous else {
            return (.unavailable, PreviousState(totalRead: totalRead, totalWrite: totalWrite, timestamp: now))
        }

        let elapsed = now.timeIntervalSince(prev.timestamp)
        guard elapsed > 0 else {
            return (.unavailable, PreviousState(totalRead: totalRead, totalWrite: totalWrite, timestamp: now))
        }

        let readRate  = Double(Int64(totalRead) - Int64(prev.totalRead))  / elapsed
        let writeRate = Double(Int64(totalWrite) - Int64(prev.totalWrite)) / elapsed
        let next = PreviousState(totalRead: totalRead, totalWrite: totalWrite, timestamp: now)

        return (DiskIOStats(
            readBytesPerSec: max(0, readRate),
            writeBytesPerSec: max(0, writeRate)
        ), next)
    }
}
