import Foundation
import IOKit

// IOPowerSources C function declarations
@_silgen_name("IOPSCopyPowerSourcesInfo")
private func IOPSCopyPowerSourcesInfo() -> Unmanaged<CFMutableDictionary>?

@_silgen_name("IOPSCopyPowerSourcesList")
private func IOPSCopyPowerSourcesList(_ bag: CFDictionary) -> Unmanaged<CFArray>?

@_silgen_name("IOPSGetPowerSourceDescription")
private func IOPSGetPowerSourceDescription(_ bag: CFDictionary, _ ps: CFTypeRef) -> Unmanaged<CFDictionary>?

private let transportTypeKey = "Transport Type"
private let kIOPSInternalType = "Internal"
private let currentCapacityKey = "Current Capacity"
private let isChargingKey = "Is Charging"
private let timeToEmptyKey = "Time to Empty"

/// Collects battery status via IOPowerSources APIs.
/// Returns nil when no internal battery is found (desktop Macs).
final class BatteryCollector: MetricCollector {
    typealias Snapshot = BatteryStats?
    typealias PreviousState = Void
    var label: String { "Battery" }

    func collect(previous: Void?) -> (Snapshot, Void?) {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return (nil, nil) }

        for ps in list {
            guard let desc = IOPSGetPowerSourceDescription(info, ps)?
                .takeUnretainedValue() as? [String: Any] else { continue }
            guard desc[transportTypeKey] as? String == kIOPSInternalType else { continue }

            let charge = desc[currentCapacityKey] as? Int ?? 0
            let charging = desc[isChargingKey] as? Bool ?? false
            let timeMin = desc[timeToEmptyKey] as? Double

            return (BatteryStats(
                chargePercent: charge,
                isCharging: charging,
                timeRemainingMinutes: charging ? nil : timeMin
            ), nil)
        }

        return (nil, nil) // Desktop Mac (no internal battery)
    }
}
