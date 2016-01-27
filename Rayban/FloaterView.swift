//
//  Overlay window main view
//
import Cocoa

class FloaterView: NSView {
    let borderRadius = CGFloat(8)
    let backgroundColor = NSColor(deviceRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.7)

    override init(frame: NSRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        let roundedRect = NSBezierPath(
            roundedRect: self.frame,
            xRadius: self.borderRadius,
            yRadius: self.borderRadius
        )
        self.backgroundColor.set()
        roundedRect.fill()
    }
}
