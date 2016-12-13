//
//  Overlay window main view
//  which watches sources for changes,
//  offers to select a new watching target
//  and tells its subordinate Render View to recompile
//  when needed
//
import Cocoa

class MainViewController: NSViewController {

  lazy var openPanel: NSOpenPanel = {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    return panel
  }()

  lazy var detailsCallout: NSPopover = {
    let callout = NSPopover()
    callout.behavior = .transient
    callout.contentViewController = self.detailsViewController
    return callout
  }()

  lazy var detailsViewController: NSViewController = (
    self.storyboard!.instantiateController(withIdentifier: "DetailsViewController")
  ) as! NSViewController

  @IBOutlet weak var currentShaderField: NSTextField!
  @IBOutlet weak var bottomStack: NSStackView!
  @IBOutlet weak var renderView: RenderView!

  private var filewatch = Filewatch()

  private var targetPath = "" {
    didSet {
      targetFilenameDidChange(path: targetPath)
      targetFileContentDidChange()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    renderView!.logListener = self

    filewatch.addHandler { [weak self] in
      self?.targetFileContentDidChange()
    }

    openPanel.orderFront(self)
    let result = openPanel.runModal()
    if result != NSFileHandlingPanelOKButton {
      NSApp.terminate(self)
    }
    openPanel.orderOut(self)

    let path = openPanel.urls.first!.path
    targetPath = path

    filewatch.setTarget(path: targetPath)
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }

  private func targetFilenameDidChange(path: String) {

    // Chop the home part
    guard let home = ProcessInfo.processInfo.environment["HOME"] else {
      // No home -- no chopping
      currentShaderField.stringValue = path
      return
    }

    var prettyPath = path
    if prettyPath.hasPrefix(home) {
      let afterHome = prettyPath.characters.index(prettyPath.startIndex, offsetBy: home.characters.count)
      let pathAfterTilde = path.substring(from: afterHome)
      prettyPath = "~"
      if !pathAfterTilde.hasPrefix("/") {
        prettyPath.append("/" as Character)
      }
      prettyPath.append(pathAfterTilde)
    }

    currentShaderField.stringValue = prettyPath
  }

  private func targetFileContentDidChange() {

    let targetURL = URL(fileURLWithPath: targetPath)

    // FS API could be slippery at times
    var data = try? Data(contentsOf: targetURL)
    if data == nil {
      data = try? Data(contentsOf: targetURL)
      if data == nil {
        do {
          data = try Data(contentsOf: targetURL)
        } catch(let error) {
          filewatch.setTarget(path: targetPath)
          complainAboutFS(error: error, filewatch: filewatch.working)
        }
      }
    }
    guard data != nil else {
      return
    }
    guard let source = String(data: data!, encoding: .utf8) else {
      return
    }

    clearMessages()
    renderView!.setSource(source)

    // Reset the filewatch for the case when the editor writes by and moves over
    filewatch.setTarget(path: targetPath)
    if !filewatch.working {
      complainAboutFilewatch()
    }
  }

  @IBAction func moreButtonHasBeenClicked(_ sender: NSButton) {
    self.detailsCallout.show(relativeTo: sender.frame, of: sender.superview!, preferredEdge: .minX)
  }

  @IBAction func currentShaderFieldHasBeenClicked(_ sender: AnyObject) {
    openPanel.orderFront(self)
    openPanel.begin(completionHandler: { [unowned self] status in
      self.openPanel.orderOut(self)
      if status != NSFileHandlingPanelOKButton {
        return
      }

      let path = self.openPanel.urls.first!.path
      self.targetPath = path
    })
  }

  @IBAction func quitButtonHasBeenClicked(_ sender: AnyObject) {
    NSApp.terminate(sender);
  }

  func clearMessages() {
    DispatchQueue.main.async { [unowned self] in
      self.bottomStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
  }

  func addMessage(severity: RenderLogMessageSeverity, header: String, body: String) {
    bottomStack.addArrangedSubview(makeReportView(severity, header, body))
  }

  private func complainAboutFS(error: Error, filewatch working: Bool) {
    NSLog("run-time expectation violated:\n"
      + "detected change in target file; however could not read it: \n\(error)\n"
      + "continuing to watch the same file")
    if !working {
      NSLog("moreover, file watch mechanism could not open the file for reading; suspending")
    }
  }

  private func complainAboutFilewatch() {
    NSLog("could not attach watcher to the target file; try picking the file again")
  }

  private func makeReportView(_ severity: RenderLogMessageSeverity, _ header: String, _ message: String) -> NSView {
    var bulletColor: NSColor! = nil
    switch severity {
    case .unknown:
      bulletColor = NSColor(calibratedHue: 0.86, saturation: 0.9, brightness: 0.9, alpha: 1.0)
    case .warning:
      bulletColor = NSColor(calibratedHue: 0.14, saturation: 0.9, brightness: 0.9, alpha: 1.0)
    case .error:
      bulletColor = NSColor(calibratedHue: 0.01, saturation: 0.9, brightness: 0.9, alpha: 1.0)
    }

    let fontSize = NSFont.systemFontSize()

    let sigilView = NSTextField()
    sigilView.isEditable = false
    sigilView.isSelectable = false
    sigilView.isBordered = false
    sigilView.drawsBackground = false
    sigilView.font = NSFont.monospacedDigitSystemFont(ofSize: 1.4 * fontSize, weight: 1.0)
    sigilView.textColor = bulletColor
    sigilView.stringValue = "•"
    sigilView.sizeToFit()

    let headerView = NSTextField()
    headerView.isEditable = false
    headerView.isSelectable = false
    headerView.isBordered = false
    headerView.drawsBackground = false
    headerView.font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: 1.0)
    headerView.textColor = .white
    headerView.stringValue = header
    headerView.sizeToFit()

    let messageView = NSTextField()
    messageView.isEditable = false
    messageView.isSelectable = true
    messageView.isBordered = false
    messageView.drawsBackground = false
    messageView.font = NSFont.systemFont(ofSize: fontSize, weight: 0.1)
    messageView.textColor = .white
    messageView.stringValue = message
    messageView.sizeToFit()

    let container = NSStackView(views: [sigilView, headerView, messageView])
    container.orientation = .horizontal
    container.alignment = .firstBaseline
    return container
  }
}

extension MainViewController: RenderLogListener {

  func onReport(_ message: RenderLogMessage) {
    let (severity, row, column, body) = message
    var header = ""
    if let row = row, let column = column {
      header = "\(row):\(column):  "
    }
    addMessage(severity: severity, header: header, body: body)
  }
}

class MainView: NSView {
  let borderRadius = CGFloat(8)
  let backgroundColor = NSColor(deviceRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.7)

  override init(frame: NSRect) {
    super.init(frame: frame)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let roundedRect = NSBezierPath(
      roundedRect: self.frame,
      xRadius: self.borderRadius,
      yRadius: self.borderRadius
    )
    self.backgroundColor.set()
    roundedRect.fill()
  }
}
