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

    let size = (Float64(frame.size.width), Float64(frame.size.height))
    let time = monotonicTime()
    renderer.yieldFrame(size: size, time: time)

    CGLFlushDrawable(self.openGLContext!.cglContextObj!)
  }

  func setSource(_ source: String) {
    self.nextSource = source
  }

  private func recompile(_ source: String) {
    renderer.setSource(source)
  }

  private func monotonicTime() -> Float64 {
    var tb: mach_timebase_info_data_t = mach_timebase_info_data_t(numer: 0, denom: 1)
    mach_timebase_info(&tb)
    let nanoseconds = mach_absolute_time() * UInt64(tb.numer) / UInt64(tb.denom)
    return Float64(nanoseconds) * 1e-9
  }

  deinit {
    CVDisplayLinkStop(self.displayLink!)
  }
}
