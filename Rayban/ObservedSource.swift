//
//  A singleton holding an intance of `ObservedResource`
//  which is attached to the source being watched
//
import Cocoa

class ObservedSource: NSObject {
    private static let _instance = ObservedFile()
    private override init() { super.init() }
    static func sharedInstance() -> ObservedFile {
        return ObservedSource._instance
    }
}
