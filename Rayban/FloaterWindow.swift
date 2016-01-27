//
//  Overlay window
//
import Cocoa

class FloaterWindow: NSWindow {
    override init(
        contentRect: NSRect, styleMask aStyle: Int,
        backing bufferingType: NSBackingStoreType,
        `defer` flag: Bool
    ) {
        super.init(
            contentRect: contentRect, styleMask: aStyle,
            backing: bufferingType, `defer`: flag)

        self.opaque = false
        self.excludedFromWindowsMenu = true
        self.backgroundColor = NSColor.clearColor()

        ///  Allow to drag it by shader view and by black stripes
        self.movableByWindowBackground = true

        ///  Fix it above all
        self.level = Int(CGWindowLevelForKey(.FloatingWindowLevelKey))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
