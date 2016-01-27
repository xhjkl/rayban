//
//  Juicy
//
import Cocoa
import OpenGL.GL3

class ShaderView: NSOpenGLView {
    override var mouseDownCanMoveWindow: Bool { get { return true } }
    var program: (render: GLuint, passThrough: GLuint) = (0, 0)
    var shader: (vert: GLuint, frag: GLuint) = (0, 0)

    override func prepareOpenGL() {
        ObservedSource.sharedInstance().addObserver({data in self.loadSource(data)})

        glClearColor(1.0, 0.33, 0.77, 1.0)
        self.program.render = glCreateProgram()
        self.program.passThrough = glCreateProgram()

        if let contents = ObservedSource.sharedInstance().value {
            NSLog("initialising with %@", contents)
            self.recompile(contents)
        } else {
            NSLog("no source to start with")
        }
    }

    func loadSource(data: NSData?) {
        if let data = data {
            NSLog("would now compile %@", data)
        } else {
            NSLog("no such file")
        }
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        glClear(UInt32(GL_COLOR_BUFFER_BIT))
        glFlush()
    }

    func recompile(source: NSData) {
        ///  glShaderSource
    }
}
