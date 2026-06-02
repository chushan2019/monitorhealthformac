import Foundation
import Combine

/// Central metrics store. Collects all system stats concurrently and publishes snapshots.
@MainActor
final class MetricsStore: ObservableObject {
    @Published private(set) var snapshot: MetricsSnapshot?

    // Collectors
    private let cpuCollector = CPUCollector()
    private let memoryCollector = MemoryCollector()
    private let diskCollector = DiskCollector()
    private let diskIOCollector = DiskIOCollector()
    private let networkCollector = NetworkCollector()
    private let gpuCollector = GPUCollector()
    private let batteryCollector = BatteryCollector()
    private let tempCollector = TemperatureCollector()
    // TODO: Re-enable ProcessCollector after fixing crash
    private let processCollector = ProcessCollectorStub()

    // Previous states for delta-based collectors
    private var cpuPrev: CPUCollector.PreviousState?
    private var dioPrev: DiskIOCollector.PreviousState?
    private var netPrev: NetworkCollector.PreviousState?
    private var procPrev: ProcessCollectorStub.PreviousState?

    private var scheduler: UpdateScheduler?

    func start(interval: TimeInterval = 1.0) {
        scheduler = UpdateScheduler(interval: interval) { [weak self] in
            Task { [weak self] in await self?.tick() }
        }
        scheduler?.start()
    }

    func stop() {
        scheduler?.stop()
    }

    private func tick() async {
        async let cpu: CPUStats          = collectCPU()
        async let mem: MemoryStats       = collectMemory()
        async let disk: DiskStats        = collectDisk()
        async let dio: DiskIOStats       = collectDiskIO()
        async let net: NetworkStats      = collectNetwork()
        async let gpu: GPUStats          = collectGPU()
        async let batt: BatteryStats?    = collectBattery()
        async let temp: TemperatureStats = collectTemperature()
        async let procs: ProcessStats    = collectProcesses()

        self.snapshot = MetricsSnapshot(
            cpu: await cpu,
            memory: await mem,
            disk: await disk,
            diskIO: await dio,
            network: await net,
            gpu: await gpu,
            battery: await batt,
            temperature: await temp,
            processes: await procs,
            timestamp: Date()
        )
    }

    // MARK: - Delta-based collectors (carry previous state)

    private func collectCPU() async -> CPUStats {
        let prev = self.cpuPrev
        let (snap, next) = await Task.detached(priority: .utility) { [cpuCollector] in
            cpuCollector.collect(previous: prev)
        }.value
        self.cpuPrev = next
        return snap
    }

    private func collectDiskIO() async -> DiskIOStats {
        let prev = self.dioPrev
        let (snap, next) = await Task.detached(priority: .utility) { [diskIOCollector] in
            diskIOCollector.collect(previous: prev)
        }.value
        self.dioPrev = next
        return snap
    }

    private func collectNetwork() async -> NetworkStats {
        let prev = self.netPrev
        let (snap, next) = await Task.detached(priority: .utility) { [networkCollector] in
            networkCollector.collect(previous: prev)
        }.value
        self.netPrev = next
        return snap
    }

    private func collectProcesses() async -> ProcessStats {
        // TODO: Re-enable real process collection
        return ProcessStats(topProcesses: [])
    }

    // MARK: - Simple collectors (no previous state)

    private func collectMemory() async -> MemoryStats {
        await Task.detached(priority: .utility) { [memoryCollector] in
            memoryCollector.collect(previous: ()).0
        }.value
    }

    private func collectDisk() async -> DiskStats {
        await Task.detached(priority: .utility) { [diskCollector] in
            diskCollector.collect(previous: ()).0
        }.value
    }

    private func collectGPU() async -> GPUStats {
        await Task.detached(priority: .utility) { [gpuCollector] in
            gpuCollector.collect(previous: ()).0
        }.value
    }

    private func collectBattery() async -> BatteryStats? {
        await Task.detached(priority: .utility) { [batteryCollector] in
            batteryCollector.collect(previous: ()).0
        }.value
    }

    private func collectTemperature() async -> TemperatureStats {
        await Task.detached(priority: .utility) { [tempCollector] in
            tempCollector.collect(previous: ()).0
        }.value
    }
}
