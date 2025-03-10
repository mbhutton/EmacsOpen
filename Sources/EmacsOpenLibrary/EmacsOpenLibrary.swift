import Foundation

private func ensureClient() -> Bool {
  let result: CommandResult = runCommand("emacsclient --eval '(+ 40 2)'")
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
    return runCommandAndCheck("emacsclient --create-frame --no-wait")
  }

  // Run this command, then check if the result is 1. If it is 1, then print foo: emacsclient --eval '(length (frame-list))'
  let result: CommandResult = runCommand("emacsclient --eval '(length (frame-list))'")
  let resultTrimmed: String = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
  // PORTABILITY:With Doom and Emacs-plus there's always 1 frame, even if none are visible
  if resultTrimmed == "1" || resultTrimmed == "0" {
    return runCommandAndCheck("emacsclient --create-frame --no-wait")
  } else {
    return true
  }
}

public func activateFrame(createFrame: Bool = false) -> Bool {
  if !ensureFrame(createFrame: createFrame) {
    return false
  }
  // The intention is a command that also supports Emacs flavours which don't have an Emacs.app
  return runCommandAndCheck(
    // PORTABILITY: Emacs flavours which don't have an Emacs.app will need a different approach.
    //   Need a portable command which doesn't hand when run shortly after restarting the daemon.
    //   For now, assume an Emacs.app.
    "osascript -e 'tell application \"Emacs\" to activate'"
  )
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
  return runCommandAndCheck("emacsclient \(blockClause)\(filesString)")
}

public func openInTerminal(filesOrLink: [String]) -> Bool {
  if !ensureClient() {
    return false
  }
  var arguments: [String] = ["--tty"]
  arguments.append(contentsOf: filesOrLink)
  execCommand("emacsclient", arguments: arguments)
  return false  // Reaching here would be a bug
}

public func evalInEmacs(command: String) -> Bool {
  if !ensureClient() {
    return false
  }
  execCommand("emacsclient", arguments: ["--eval", command])
  return false  // Reaching here would be a bug
}

struct CommandResult {
  let stdout: String
  let stderr: String
  let exitCode: Int32
}

private func runCommandAndCheck(_ command: String) -> Bool {
  return runCommand(command).exitCode == 0
}

private func runCommand(_ command: String) -> CommandResult {
  let task: Process = Process()
  task.launchPath = "/bin/bash"
  task.arguments = ["-c", command]

  let pipeStdout: Pipe = Pipe()
  let pipeStderr: Pipe = Pipe()
  task.standardOutput = pipeStdout
  task.standardError = pipeStderr
  print("Running command: \(command)")
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

private func execCommand(_ command: String, arguments: [String]) {
  // Create a null-terminated array of C strings
  let args: [String] = [command] + arguments
  let cArgs: [UnsafeMutablePointer<CChar>?] = args.map { strdup($0) } + [nil]

  // Replace current process with the new command
  print("Running command (via exec): \(command) \(arguments.joined(separator: " "))")
  execvp(command, cArgs)

  // Will only reach this point if the execvp call failed
  perror("\(command) call failed")
  exit(EXIT_FAILURE)
}
