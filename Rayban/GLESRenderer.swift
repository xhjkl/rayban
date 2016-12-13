//
// OpenGL renderer
//

import Cocoa
import OpenGL.GL3

fileprivate let passThroughVertSrc = "#version 100\n"
  + "attribute vec2 position;"
  + "varying vec2 Position;"
  + "void main() {"
  + "gl_Position = vec4((Position = position), 0.0, 1.0);"
  + "}"

fileprivate let passThroughFragSrc = "#version 100\n"
  + "uniform sampler2D texture;"
  + "uniform vec2 resolution;"
  + "void main() {"
  + "gl_FragColor = texture2D(texture, gl_FragCoord.xy / resolution);"
  + "}"

fileprivate let unitQuadVertices = Array<GLfloat>([
  +1.0, -1.0,
  -1.0, -1.0,
  +1.0, +1.0,
  -1.0, +1.0,
])

// OpenGL ES 2
//
class GLESRenderer: Renderer {

  private var progId = GLuint(0)
  private var vertexArrayId = GLuint(0)
  private var unitQuadBufferId = GLuint(0)

  private var timeUniform: GLuint? = nil
  private var densityUniform: GLuint? = nil
  private var resolutionUniform: GLuint? = nil

  var logListener: RenderLogListener? = nil

  func prepare() {
    glClearColor(1.0, 0.33, 0.77, 1.0)

    glGenVertexArrays(1, &vertexArrayId)
    glBindVertexArray(vertexArrayId)

    let size = unitQuadVertices.count * MemoryLayout<GLfloat>.size
    glGenBuffers(1, &unitQuadBufferId)
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), unitQuadBufferId)
    unitQuadVertices.withUnsafeBufferPointer { bytes in
      glBufferData(GLenum(GL_ARRAY_BUFFER), size, bytes.baseAddress, GLenum(GL_STATIC_DRAW))
    }

    glVertexAttribPointer(0, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(0), UnsafeRawPointer(bitPattern: 0))
    glEnableVertexAttribArray(0)
  }

  func setSource(_ source: String) {
    if glIsProgram(progId) == GLboolean(GL_TRUE) {
      glDeleteProgram(progId)
    }

    let newProgId = makeShader(vertSource: passThroughVertSrc, fragSource: source)
    guard newProgId != nil else {
      return
    }

    progId = newProgId!
    glUseProgram(progId)
  }

  func yieldFrame() {
    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
  }

  private func retrieveCompilationLog(id: GLuint) -> String {
    let oughtToBeEnough = 1024
    var storage = ContiguousArray<CChar>(repeating: 0, count: oughtToBeEnough)
    var log: String! = nil

    storage.withUnsafeMutableBufferPointer { mutableBytes in
      glGetShaderInfoLog(id, GLsizei(oughtToBeEnough), nil, mutableBytes.baseAddress!)
      log = String(cString: mutableBytes.baseAddress!)
    }

    return log
  }

  private func retrieveLinkageLog(id: GLuint) -> String {
    let oughtToBeEnough = 1024
    var storage = ContiguousArray<CChar>(repeating: 0, count: oughtToBeEnough)
    var log: String! = nil

    storage.withUnsafeMutableBufferPointer { mutableBytes in
      glGetProgramInfoLog(id, GLsizei(oughtToBeEnough), nil, mutableBytes.baseAddress!)
      log = String(cString: mutableBytes.baseAddress!)
    }

    return log
  }

  private func makeShader(vertSource: String, fragSource: String) -> GLuint? {
    var status: GLint = 0

    let progId = glCreateProgram()

    let vertId = glCreateShader(GLenum(GL_VERTEX_SHADER))
    defer { glDeleteShader(vertId) }
    vertSource.withCString { bytes in
      glShaderSource(vertId, 1, [bytes], nil)
    }
    glCompileShader(vertId)
    glGetShaderiv(vertId, GLenum(GL_COMPILE_STATUS), &status)
    guard status == GL_TRUE else {
      let log = retrieveCompilationLog(id: vertId)
      emitReports(per: log)
      return nil
    }

    let fragId = glCreateShader(GLenum(GL_FRAGMENT_SHADER))
    defer { glDeleteShader(fragId) }
    fragSource.withCString { bytes in
      glShaderSource(fragId, 1, [bytes], nil)
    }
    glCompileShader(fragId)
    glGetShaderiv(fragId, GLenum(GL_COMPILE_STATUS), &status)
    guard status == GL_TRUE else {
      let log = retrieveCompilationLog(id: fragId)
      emitReports(per: log)
      return nil
    }

    glBindAttribLocation(progId, 0, "position")

    glAttachShader(progId, vertId)
    glAttachShader(progId, fragId)
    glLinkProgram(progId)
    defer {
      glDetachShader(progId, vertId)
      glDetachShader(progId, fragId)
    }
    glGetProgramiv(progId, GLenum(GL_LINK_STATUS), &status)
    guard status == GL_TRUE else {
      let log = retrieveLinkageLog(id: progId)
      emitReports(per: log)
      return nil
    }
    
    return progId
  }

  private func emitReports(per log: String) {
    guard logListener != nil else {
      return
    }

    let reports = parseLog(log)
    for report in reports {
      logListener!.onReport(report)
    }
  }
}
