//
//  Reactive
//
import Foundation

class Observed<T> {
    ///  Callable to be invoked when the state changes
    typealias ObservationCallback = (T)->(Void)

    ///  All callbacks that are invoked on every state change
    private(set) var observers: [ObservationCallback] = []

    ///  Include a new observer to be notified in the next change of the state
    func addObserver(callback: ObservationCallback) {
        self.observers.append(callback)
    }

    ///  State whose changes are being observed
    var value: T {
        didSet {
            self.observers.forEach { $0(self.value) }
        }
    }

    init(initialValue: T) {
        self.value = initialValue
    }
}
