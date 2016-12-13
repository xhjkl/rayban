//
//  Juicy
//
import Cocoa
import OpenGL.GL3

class RenderView: NSOpenGLView {

  override var mouseDownCanMoveWindow: Bool { return true }

  private var renderer: Renderer! = nil
  private var displayLink: CVDisplayLink? = nil
  private var nextSource: String? = nil

  var logListener: RenderLogListener? = nil {
    didSet {
      renderer?.logListener = logListener
    }
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    self.pixelFormat = NSOpenGLPixelFormat(attributes: [
      UInt32(NSOpenGLPFADoubleBuffer),
      UInt32(NSOpenGLPFAOpenGLProfile), UInt32(NSOpenGLProfileVersion4_1Core),
      0
    ])!
    self.openGLContext = NSOpenGLContext(format: pixelFormat!, share: nil)!
    self.openGLContext!.setValues([1], for: .swapInterval)
  }

  override func prepareOpenGL() {
    CVDisplayLinkCreateWithActiveCGDisplays(&self.displayLink)
    CVDisplayLinkSetOutputHandler(self.displayLink!, { [weak self] sender, now, time, flagsIn, flagsOut in
      self?.needsDisplay = true
      return kCVReturnSuccess
    })
    CVDisplayLinkStart(self.displayLink!)

    renderer = GLESRenderer()
    renderer.prepare()
    renderer.logListener = logListener
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    if let source = nextSource {
      recompile(source)
      nextSource = nil
    }

    renderer.yieldFrame()

    CGLFlushDrawable(self.openGLContext!.cglContextObj!)
  }

  func setSource(_ source: String) {
    self.nextSource = source
  }

  private func recompile(_ source: String) {
    renderer.setSource(source)
  }

  deinit {
    CVDisplayLinkStop(self.displayLink!)
  }
}
