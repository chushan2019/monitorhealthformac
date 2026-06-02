import Foundation

/// Wraps a DispatchSourceTimer for periodic metric collection.
/// Runs on a utility-priority background queue to avoid blocking the main thread.
final class UpdateScheduler {
    private let timer: DispatchSourceTimer
    private let queue = DispatchQueue(label: "com.monitortool.scheduler", qos: .utility)

    init(interval: TimeInterval, handler: @escaping @Sendable () -> Void) {
        self.timer = DispatchSource.makeTimerSource(queue: queue)
        self.timer.schedule(deadline: .now() + interval, repeating: interval)
        self.timer.setEventHandler(handler: handler)
    }

    func start() { timer.resume() }
    func stop()  { timer.cancel() }
}
