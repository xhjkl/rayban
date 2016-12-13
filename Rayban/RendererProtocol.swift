//
//  Abstract renderer
//


// What kind of diagnostics graphics compiler could emit
//
enum RenderLogMessageSeverity {
  case unknown
  case warning
  case error
}

// Parsed output of the compiler
//
typealias RenderLogMessage = (severity: RenderLogMessageSeverity, row: UInt?, column: UInt?, message: String)

// Listener to messages from shader compiler
//
protocol RenderLogListener {
  func onReport(_: RenderLogMessage)
}

// Algorithmic automaton which is to conjure ordained apparitions
// unto the sight of the viewer
//
protocol Renderer {

  // Compiler messages listener
  //
  var logListener: RenderLogListener? { get set }

  // One-time setup before could carry out duties
  //
  func prepare()

  // Accept a new program to make images through
  //
  func setSource(_: String)

  // Produce a single unit of imagery to the screen
  //
  func yieldFrame()
}
