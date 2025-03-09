import Foundation

public func ensureClient() -> Bool {
  let result: CommandResult = runCommand("emacsclient --eval '(+ 40 2)'")
  let stdoutTrimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

  if stdoutTrimmed != "42" || result.exitCode != 0 {
    print(
      "emacsclient not ready: stdout: \(result.stdout), stderr: \(result.stderr), exit code: \(result.exitCode)"
    )

    // TODO: Start and wait for dameon
    return false
  } else {
    return true
  }
}

public func ensureFrame(createFrame: Bool = false) -> Bool {
  if !ensureClient() {
    return false
  }

  // Run this command, then check if the result is 1. If it is 1, then print foo: emacsclient --eval '(length (frame-list))'
  let result: CommandResult = runCommand("emacsclient --eval '(length (frame-list))'")
  let resultTrimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
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

public func openFilesInGui(files: [String], wait: Bool, createFrame: Bool) -> Bool {
  if !activateFrame(createFrame: createFrame) {
    return false
  }
  let filesString: String = files.joined(separator: " ")
  let waitClause: String = wait ? "" : "--no-wait "
  return runCommandAndCheck("emacsclient \(waitClause)\(filesString)")
}

public func openFilesInTerminal(files: [String]) -> Bool {
  if !ensureClient() {
    return false
  }
  var arguments: [String] = ["--tty"]
  arguments.append(contentsOf: files)
  execCommand("emacsclient", arguments: arguments)
  return false  // Reaching here would be a bug
}

public func openOrgLink(link: String, createFrame: Bool) -> Bool {
  if !activateFrame(createFrame: createFrame) {
    return false
  }
  return runCommandAndCheck("emacsclient \(link)")
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
  let task = Process()
  task.launchPath = "/bin/bash"
  task.arguments = ["-c", command]

  let pipeStdout = Pipe()
  let pipeStderr = Pipe()
  task.standardOutput = pipeStdout
  task.standardError = pipeStderr
  print("Running command: \(command)")
  task.launch()
  task.waitUntilExit()

  let stdoutData = pipeStdout.fileHandleForReading.readDataToEndOfFile()
  let stderrData = pipeStderr.fileHandleForReading.readDataToEndOfFile()

  return CommandResult(
    stdout: String(data: stdoutData, encoding: .utf8) ?? "",
    stderr: String(data: stderrData, encoding: .utf8) ?? "",
    exitCode: task.terminationStatus
  )
}

private func execCommand(_ command: String, arguments: [String]) {
  // Create a null-terminated array of C strings
  let args = [command] + arguments
  let cArgs = args.map { strdup($0) } + [nil]

  // Replace current process with the new command
  print("Running command (via exec): \(command) \(arguments.joined(separator: " "))")
  execvp(command, cArgs)

  // Will only reach this point if the execvp call failed
  perror("\(command) call failed")
  exit(EXIT_FAILURE)
}
