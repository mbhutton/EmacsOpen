import Foundation

public func ensureClient() {
  // TODO: Start and wait for dameon if this command fails with matching error
  _ = runCommand("emacsclient --eval '(server-running-p)'")
}

public func ensureFrame() {
  ensureClient()

  // Run this command, then check if the result is 1. If it is 1, then print foo: emacsclient --eval '(length (frame-list))'
  let result = runCommand("emacsclient --eval '(length (frame-list))'")
  let resultTrimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
  if resultTrimmed == "1" {
    _ = runCommand("emacsclient --create-frame --no-wait")
  }
}

public func activateFrame() {
  ensureFrame()
  // The intention is a command that also supports Emacs flavours which don't have an Emacs.app
  _ = runCommand(
    "osascript -e 'tell application \"System Events\" to set frontmost of process \"Emacs\" to true'"
  )
}

public func openFiles(files: [String], wait: Bool, terminal: Bool) {
  activateFrame()
  let filesString: String = files.joined(separator: " ")
  let waitClause: String = wait && !terminal ? "" : "--no-wait "
  let terminalClause: String = terminal ? " --tty " : ""
  _ = runCommand("emacsclient \(waitClause)\(terminalClause)\(filesString)")
}

public func openOrgLink(link: String) {
  activateFrame()
  _ = runCommand("emacsclient \(link)")
}

public func evalInEmacs(command: String) {
  // ensureClient() TODO: do as fallback instead
  _ = runCommand("emacsclient --eval '\(command)'")
}

private func runCommand(_ command: String) -> String {
  let task = Process()
  task.launchPath = "/bin/bash"
  task.arguments = ["-c", command]

  let pipe = Pipe()
  task.standardOutput = pipe
  print("Running command: \(command)")
  task.launch()
  task.waitUntilExit()

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  return String(data: data, encoding: .utf8) ?? ""
}
