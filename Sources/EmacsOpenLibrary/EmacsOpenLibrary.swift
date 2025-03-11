import AppKit
import Foundation

private func ensureClient() -> Bool {
  let result: CommandResult = runEmacsClient("--eval '(+ 40 2)'")
  let stdoutTrimmed: String = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

  if stdoutTrimmed != "42" || result.exitCode != 0 {
    print(
      "emacsclient not ready: stdout: \(result.stdout), stderr: \(result.stderr), exit code: \(result.exitCode)"
    )

    // TODO: Start and wait for daemon
    return false
  } else {
    return true
  }
}

private func ensureFrame(createFrame: Bool = false) -> Bool {
  if !ensureClient() {
    return false
  }

  if createFrame {
    return runEmacsClientAndCheck("--create-frame --no-wait")
  }

  // Run this command, then check if the result is 1. If it is 1, then print foo: emacsclient --eval '(length (frame-list))'
  let result: CommandResult = runEmacsClient("--eval '(length (frame-list))'")
  let resultTrimmed: String = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
  // PORTABILITY:With Doom and Emacs-plus there's always 1 frame, even if none are visible
  if resultTrimmed == "1" || resultTrimmed == "0" {
    return runEmacsClientAndCheck("--create-frame --no-wait")
  } else {
    return true
  }
}

/// Raise the first Emacs frame, if it exists.
/// Returns whether was able to send the command.
private func raiseFirstEmacsFrameSafe() -> Bool {
  // PORTABILITY: Emacs flavours which don't have an Emacs.app will need a different approach.
  //   Need a portable command which doesn't hang when run shortly after restarting the daemon.
  //   For now, assume an Emacs.app.
  let bundleID: String = "org.gnu.Emacs"
  if let app: NSRunningApplication = NSRunningApplication.runningApplications(
    withBundleIdentifier: bundleID
  ).first {
    return app.activate(options: NSApplication.ActivationOptions.activateIgnoringOtherApps)
  }
  return false
}

public func activateFrame(createFrame: Bool = false) -> Bool {
  // Early activation attempt before ensureFrame call, to speed up common case where a frame already exists
  _ = raiseFirstEmacsFrameSafe()
  if !ensureFrame(createFrame: createFrame) {
    return false
  }
  // The intention is a command that also supports Emacs flavours which don't have an Emacs.app
  return raiseFirstEmacsFrameSafe()
}

public func openInGui(filesOrLink: [String], block: Bool, createFrame: Bool) -> Bool {
  if !activateFrame(createFrame: createFrame) {
    return false
  }
  if filesOrLink.isEmpty {
    FileHandle.standardError.write("No files to open\n".data(using: .utf8)!)
    return false
  }
  let filesString: String = filesOrLink.joined(separator: " ")
  let blockClause: String = block ? "" : "--no-wait "
  return runEmacsClientAndCheck("\(blockClause)\(filesString)")
}

public func openInTerminal(filesOrLink: [String]) -> Bool {
  if !ensureClient() {
    return false
  }
  var arguments: [String] = ["--tty"]
  arguments.append(contentsOf: filesOrLink)
  execEmacsClient(arguments: arguments)
  return false  // Reaching here would be a bug
}

public func evalInEmacs(command: String) -> Bool {
  if !ensureClient() {
    return false
  }
  execEmacsClient(arguments: ["--eval", command])
  return false  // Reaching here would be a bug
}

struct CommandResult {
  let stdout: String
  let stderr: String
  let exitCode: Int32
}

private func runEmacsClientAndCheck(_ argumentsString: String) -> Bool {
  return runEmacsClient(argumentsString).exitCode == 0
}

private func runEmacsClient(_ argumentsString: String) -> CommandResult {
  let task: Process = Process()
  task.launchPath = "/bin/bash"
  let fullCommand: String = getEmacsClientPath() + " " + argumentsString
  task.arguments = ["-c", fullCommand]

  let pipeStdout: Pipe = Pipe()
  let pipeStderr: Pipe = Pipe()
  task.standardOutput = pipeStdout
  task.standardError = pipeStderr
  print("Running command: \(fullCommand)")
  task.launch()
  task.waitUntilExit()

  let stdoutData: Data = pipeStdout.fileHandleForReading.readDataToEndOfFile()
  let stderrData: Data = pipeStderr.fileHandleForReading.readDataToEndOfFile()

  return CommandResult(
    stdout: String(data: stdoutData, encoding: .utf8) ?? "",
    stderr: String(data: stderrData, encoding: .utf8) ?? "",
    exitCode: task.terminationStatus
  )
}

private func execEmacsClient(arguments: [String]) {
  // TODO:grok and update this
  let emacsClientPath: String = getEmacsClientPath()
  // Create a null-terminated array of C strings
  let commandAndArgsStrings: [String] = [emacsClientPath] + arguments
  let commandAndArgsCStrings: [UnsafeMutablePointer<CChar>?] = commandAndArgsStrings.map { strdup($0) } + [nil]

  // Replace current process with the new command
  print("Running command (via exec): \(commandAndArgsStrings.joined(separator: " "))")
  execvp(emacsClientPath, commandAndArgsCStrings)

  // Will only reach this point if the execvp call failed
  perror("Failed to replace process with \(emacsClientPath)")
  exit(EXIT_FAILURE)
}

private func getEmacsClientPath() -> String {
  // TODO: Make this configurable and/or auto-detect
  return "/opt/homebrew/bin/emacsclient"
}
