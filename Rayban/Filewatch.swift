//
// File modification responder
//

import Dispatch

// Responder to FS events
//
public class Filewatch {

  private var handlers: Array<() -> ()> = []
  private var eventSource: DispatchSourceFileSystemObject! = nil
  private var fd: Int32! = nil

  // True iff notifications shall work with current target
  //
  public var working: Bool { return fd != nil }

  public init() {
  }

  // Set target immediately after initialization
  //
  public convenience init(path: String) {
    self.init()

    self.setTarget(path: path)
  }

  // Decide how to respond to FS events
  //
  public func addHandler(_ handler: @escaping () -> ()) {
    handlers.append(handler)
  }

  // Decide what file to look to
  //
  // While being watched, the file is identified by its descriptor.
  // Note that if the file was moved,
  // its path might change, whereas the descriptor shall stay the same.
  //
  public func setTarget(path: String) {

    if fd != nil {
      close(fd)
    }

    path.withCString { [unowned self] bytes in
      self.fd = open(bytes, O_RDONLY)

      if self.fd == -1 {
        self.fd = nil
      }
    }
    if fd == nil {
      return
    }

    eventSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: [.all])
    eventSource.setEventHandler { [weak self] in
      guard self != nil else { return }

      self!.handlers.forEach { $0() }
    }
    eventSource.resume()
  }

  deinit {
    if fd != nil {
      close(fd)
    }
  }
}
