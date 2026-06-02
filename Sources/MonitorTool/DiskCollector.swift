import Foundation

/// Collects disk usage via getfsstat.
/// Filters to MNT_LOCAL volumes only (local disks, not network mounts).
final class DiskCollector: MetricCollector {
    typealias Snapshot = DiskStats
    typealias PreviousState = Void
    var label: String { "Disk" }

    func collect(previous: Void?) -> (Snapshot, Void?) {
        let mountCount = getfsstat(nil, 0, MNT_NOWAIT)
        guard mountCount > 0 else { return (DiskStats(volumes: []), nil) }

        let buf = UnsafeMutablePointer<statfs>.allocate(capacity: Int(mountCount))
        defer { buf.deallocate() }

        let bufferSize = Int32(Int(mountCount) * MemoryLayout<statfs>.stride)
        let actualCount = getfsstat(buf, bufferSize, MNT_NOWAIT)

        var volumes: [DiskStats.VolumeInfo] = []
        for i in 0..<Int(actualCount) {
            let fs = buf.advanced(by: i).pointee
            guard (fs.f_flags & UInt32(MNT_LOCAL)) != 0 else { continue }

            let totalGB = Double(fs.f_blocks) * Double(fs.f_bsize) / 1_073_741_824.0
            let freeGB  = Double(fs.f_bavail)  * Double(fs.f_bsize) / 1_073_741_824.0
            let usedGB  = totalGB - freeGB

            // fs.f_mntonname and fs.f_mntfromname are fixed-size CChar tuples in Swift 6
            // Use withUnsafePointer to get a C string pointer
            let mountPoint = withUnsafePointer(to: fs.f_mntonname) { ptr in
                ptr.withMemoryRebound(to: CChar.self, capacity: 1) { cPtr in
                    String(cString: cPtr)
                }
            }
            let deviceName = withUnsafePointer(to: fs.f_mntfromname) { ptr in
                ptr.withMemoryRebound(to: CChar.self, capacity: 1) { cPtr in
                    String(cString: cPtr)
                }
            }

            if totalGB > 0.1 { // skip tiny pseudo-volumes
                volumes.append(DiskStats.VolumeInfo(
                    id: mountPoint,
                    name: deviceName,
                    usedGB: usedGB,
                    totalGB: totalGB
                ))
            }
        }

        // Sort: root (/) first, then by name
        volumes.sort { a, b in
            if a.id == "/" { return true }
            if b.id == "/" { return false }
            return a.name < b.name
        }

        return (DiskStats(volumes: volumes), nil)
    }
}
