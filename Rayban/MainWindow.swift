//
//  Main window decoration
//
import Cocoa

class MainWindow: NSWindow {
  override init(
    contentRect: NSRect, styleMask aStyle: NSWindowStyleMask,
    backing bufferingType: NSBackingStoreType,
    defer flag: Bool
  ) {
    super.init(
      contentRect: contentRect, styleMask: aStyle,
      backing: bufferingType, defer: flag)

    self.isOpaque = false
    self.isExcludedFromWindowsMenu = true
    self.backgroundColor = NSColor.clear

    //  Allow to drag it by shader view and by black stripes
    self.isMovableByWindowBackground = true

    //  Fix it above all
    self.level = Int(CGWindowLevelForKey(.floatingWindow))
  }
}
