//
//  Wrapper around kqueue
//  that notifies all of its specified observers
//  whenever the given resource changes
//
import Foundation

class ObservedFile: Observed<NSData?> {
    var path: String = "" {
        didSet {
            self.value = NSFileManager.defaultManager().contentsAtPath(self.path)
        }
    }
    internal(set) var kqueueId: Int32

    init(queue: Int32) {
        self.kqueueId = queue
        super.init(initialValue: nil)

        let dispatchQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        dispatch_async(dispatchQueue) {
            let selection: [kevent] = [kevent(
                ident: 0,
                filter: EVFILT_VNODE & 0xFFFF,
                flags: EV_ADD as Int16,
                fflags: 0,
                data: 0,
                udata: nil
            ) as! kevent]
        }
    }

    convenience init() {
        let newQueue = kqueue()
        self.init(queue: newQueue)
    }

    deinit {
    }
}
