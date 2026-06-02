import Foundation
import Darwin

/// Simple wrappers around sysctlbyname for common system queries.
enum SysctlHelper {
    static func logicalCPUCount() -> Int {
        var count: Int32 = 0
        var size = MemoryLayout<Int32>.size
        sysctlbyname("hw.logicalcpu", &count, &size, nil, 0)
        return Int(count)
    }

    static func physicalMemoryBytes() -> UInt64 {
        var mem: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &mem, &size, nil, 0)
        return mem
    }

    static func physicalMemoryGB() -> Double {
        Double(physicalMemoryBytes()) / 1_073_741_824.0
    }

    static func hostname() -> String {
        var buf = [CChar](repeating: 0, count: Int(MAXHOSTNAMELEN))
        gethostname(&buf, Int(MAXHOSTNAMELEN))
        return String(cString: buf)
    }
}
