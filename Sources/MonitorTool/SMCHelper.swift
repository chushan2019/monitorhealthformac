import Foundation
import IOKit

/// Low-level SMC (System Management Controller) helper for reading temperature sensors.
/// Communicates with the AppleSMC user client via IOKit.
/// Temperature data is in `sp78` fixed-point format: value = byte[0] + byte[1]/256.
enum SMCHelper {
    private static var connection: io_connect_t = 0

    // SMC method selector: kSMCReadKey = 2
    private static let kSMCReadKey: UInt32 = 2

    private static func openConnection() -> io_connect_t {
        guard connection == 0 else { return connection }

        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSMC")
        )
        guard service != MACH_PORT_NULL else { return 0 }

        let kr = IOServiceOpen(service, mach_task_self_, 0, &connection)
        IOObjectRelease(service)
        return kr == KERN_SUCCESS ? connection : 0
    }

    static func readTemperature(key: String) -> Double? {
        let conn = openConnection()
        guard conn != 0 else { return nil }

        // Build SMC input key structure
        var input = SMCHandle()
        input.key = fourCharCode(from: key)
        input.dataSize = 2

        var outputData = SMCKeyData()
        var outputSize = Int(MemoryLayout<SMCKeyData>.size)

        let kr = IOConnectCallStructMethod(
            conn, kSMCReadKey,
            &input, MemoryLayout<SMCHandle>.size,
            &outputData, &outputSize
        )

        guard kr == KERN_SUCCESS else { return nil }

        // sp78 format: integer byte + fraction byte / 256
        let byte0 = outputData.bytes.0
        let byte1 = outputData.bytes.1
        return Double(byte0) + Double(byte1) / 256.0
    }

    private static func fourCharCode(from string: String) -> UInt32 {
        var result: UInt32 = 0
        for b in string.utf8 {
            result = (result << 8) | UInt32(b)
        }
        return result
    }
}

// SMC key input structure (matches IOKit internal layout)
struct SMCHandle {
    var key: UInt32 = 0
    var vers: UInt32 = 0
    var plistLen: UInt8 = 0
    var dataSize: UInt8 = 0
    var dataType: UInt8 = 0
    var dataAttr: UInt8 = 0
    var keyInfo: UInt32 = 0
    var result: UInt8 = 0
    var _pad: UInt8 = 0
    var data: UInt32 = 0
}

// SMC response structure with 32-byte data buffer
struct SMCKeyData {
    var key: UInt32 = 0
    var vers: UInt32 = 0
    var plistLen: UInt8 = 0
    var dataSize: UInt8 = 0
    var dataType: UInt8 = 0
    var dataAttr: UInt8 = 0
    var keyInfo: UInt32 = 0
    var result: UInt8 = 0
    var _pad: UInt8 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) =
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}
