import Foundation
import Darwin

/// Collects network I/O via getifaddrs.
/// Reads if_data.ifi_ibytes (rx) and if_data.ifi_obytes (tx) per interface.
/// Filters to en* and bridge* interfaces. Requires previous state for delta.
final class NetworkCollector: MetricCollector {
    typealias Snapshot = NetworkStats

    struct PreviousState {
        var rxMap: [String: UInt64]
        var txMap: [String: UInt64]
        var timestamp: Date
    }

    var label: String { "Network" }

    func collect(previous: PreviousState?) -> (Snapshot, PreviousState?) {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrs) == 0, let first = addrs else {
            return (NetworkStats(interfaces: []), nil)
        }
        defer { freeifaddrs(first) }

        var rxMap: [String: UInt64] = [:]
        var txMap: [String: UInt64] = [:]

        // Iterate the linked list using raw pointer arithmetic
        var rawPtr: UnsafeMutableRawPointer? = UnsafeMutableRawPointer(first)
        while let raw = rawPtr {
            let ifa = raw.assumingMemoryBound(to: ifaddrs.self).pointee
            let name = String(cString: ifa.ifa_name)
            if name.hasPrefix("en") || name.hasPrefix("bridge") {
                // ifa_data may be nil for some interfaces
                if let dataPtr = ifa.ifa_data {
                    let data = dataPtr.assumingMemoryBound(to: if_data.self).pointee
                    rxMap[name] = UInt64(data.ifi_ibytes)
                    txMap[name] = UInt64(data.ifi_obytes)
                }
            }
            // Advance to next element (ifa_next is UnsafeMutablePointer<ifaddrs>)
            let nextPtr = raw.assumingMemoryBound(to: ifaddrs.self).pointee.ifa_next
            rawPtr = UnsafeMutableRawPointer(nextPtr)
        }

        let now = Date()
        guard let prev = previous else {
            return (NetworkStats(interfaces: []),
                    PreviousState(rxMap: rxMap, txMap: txMap, timestamp: now))
        }

        let elapsed = now.timeIntervalSince(prev.timestamp)
        guard elapsed > 0 else {
            return (NetworkStats(interfaces: []),
                    PreviousState(rxMap: rxMap, txMap: txMap, timestamp: now))
        }

        var interfaces: [NetworkStats.InterfaceStats] = []
        let allKeys = Set(rxMap.keys).union(prev.rxMap.keys).sorted()
        for name in allKeys {
            let curRx = rxMap[name, default: 0]
            let prevRx = prev.rxMap[name, default: 0]
            let curTx = txMap[name, default: 0]
            let prevTx = prev.txMap[name, default: 0]

            let rxRate = Double(Int64(curRx) - Int64(prevRx)) / elapsed
            let txRate = Double(Int64(curTx) - Int64(prevTx)) / elapsed

            if rxRate > 0 || txRate > 0 {
                interfaces.append(NetworkStats.InterfaceStats(
                    id: name,
                    rxBytesPerSec: max(0, rxRate),
                    txBytesPerSec: max(0, txRate)
                ))
            }
        }

        return (NetworkStats(interfaces: interfaces),
                PreviousState(rxMap: rxMap, txMap: txMap, timestamp: now))
    }
}
