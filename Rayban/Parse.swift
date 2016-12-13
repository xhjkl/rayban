//
// Diagnostics and GLSL parsing facilities
//

// Split one piece of GLSL compiler standartized output to components
//
//  `WARNING: xxx` -> RenderLogMessage(.warning, nil, nil, "xxx")
//  `ERROR: 0:1: xyz` -> RenderLogMessage(.error, 0, 1, "xyz")
//  `invalid shader` -> RenderLogMessage(.unknown, nil, nil, "invalid shader")
//
func parseLogLine(_ line: String) -> RenderLogMessage {
  var type: RenderLogMessageSeverity = .unknown

  var parts = line.characters.split(separator: ":", maxSplits: 3, omittingEmptySubsequences: false).map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) })
  if parts.count == 1 {
    return RenderLogMessage(.unknown, nil, nil, line)
  }

  let marker = parts.first!.lowercased()
  if marker.hasPrefix("error") {
    type = .error
  } else if marker.hasPrefix("warning") {
    type = .warning
  } else {
    return RenderLogMessage(.unknown, nil, nil, line)
  }

  let message = parts.last!
  if parts.count != 4 {
    return RenderLogMessage(type, nil, nil, message)
  }

  let row = UInt(parts[1])
  let column = UInt(parts[2])
  return RenderLogMessage(type, row, column, message)
}

// Compose finely structured messages from GLSL compiler output
//
func parseLog(_ log: String) -> [RenderLogMessage] {
  return log.characters.split(separator: "\n").map({ parseLogLine(String($0)) })
}
