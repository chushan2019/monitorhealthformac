import Foundation

/// Collects temperature readings from Apple SMC (System Management Controller).
/// Contains a curated list of known temperature key names that vary across Mac models.
/// Note: On Apple Silicon Macs, many SMC temperature keys are restricted by the kernel.
final class TemperatureCollector: MetricCollector {
    typealias Snapshot = TemperatureStats
    typealias PreviousState = Void
    var label: String { "Temperature" }

    // SMC key names verified across multiple Mac generations
    private let tempKeys: [(key: String, label: String)] = [
        ("TC0D", "CPU Die"),
        ("TC0H", "CPU Heatsink"),
        ("TC0P", "CPU Proximity"),
        ("TC1D", "CPU Core 1"),
        ("TC2D", "CPU Core 2"),
        ("TG0D", "GPU Die"),
        ("TG0P", "GPU Proximity"),
        ("TB0T", "Battery"),
        ("TN0P", "Northbridge"),
        ("TH0P", "Hard Drive"),
        ("TW0P", "Airport"),
        ("Ts0S", "SSD"),
        ("Tp0P", "Power Supply"),
    ]

    func collect(previous: Void?) -> (Snapshot, Void?) {
        var sensors: [TemperatureStats.SensorReading] = []
        for (key, label) in tempKeys {
            if let temp = SMCHelper.readTemperature(key: key) {
                sensors.append(TemperatureStats.SensorReading(
                    id: key, label: label, celsius: temp
                ))
            }
        }
        return (TemperatureStats(sensors: sensors), nil)
    }
}
