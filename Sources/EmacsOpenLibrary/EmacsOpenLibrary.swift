import AppKit
import Foundation

/// Functions to interact with Emacs via emacsclient and the Emacs daemon
public struct EmacsOpenLibrary {

    static let shared = EmacsOpenLibrary()
    private init() {}

    /// Ensures that emacsclient is ready to accept commands, or returns false if unable.
    private func ensureClient() -> Bool {
        let result: CommandResult = runEmacsClient("--eval '(+ 40 2)'")
        let stdoutTrimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

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

    /// Ensures the presence of a visible Emacs frame, creating one if necessary or requested, or returns false if unable.
    private func ensureFrame(createFrame: Bool = false) -> Bool {
        if !ensureClient() { return false }

        if createFrame { return runEmacsClientAndCheck("--create-frame --no-wait") }

        // Run this command, then check if the result is 1. If it is 1, then print foo: emacsclient --eval '(length (frame-list))'
        let result: CommandResult = runEmacsClient("--eval '(length (frame-list))'")
        let resultTrimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        // PORTABILITY:With Doom and Emacs-plus there's always 1 frame, even if none are visible
        if resultTrimmed == "1" || resultTrimmed == "0" {
            return runEmacsClientAndCheck("--create-frame --no-wait")
        } else {
            return true
        }
    }

    /// Raise the first Emacs frame, if it exists. Returns whether was able to send the command.
    private func raiseFirstEmacsFrameSafe() -> Bool {
        // PORTABILITY: Emacs formulas which don't have an Emacs.app will need a different approach.
        //   Need a portable command which doesn't hang when run shortly after restarting the daemon.
        //   For now, assume an Emacs.app.
        let bundleID = "org.gnu.Emacs"
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
            app.activate()
            return true
        }
        return false
    }

    /// Ensure visible Emacs frame, creating one if necessary or requested, raise it to front, or return false if unable.
    public func activateFrame(createFrame: Bool = false) -> Bool {
        // Early activation attempt before ensureFrame call, to speed up common case where a frame already exists
        _ = raiseFirstEmacsFrameSafe()
        if !ensureFrame(createFrame: createFrame) { return false }
        // The intention is a command that also supports Emacs formulas which don't have an Emacs.app
        return raiseFirstEmacsFrameSafe()
    }

    /// Opens the given files or org-protocol link in a GUI frame, or returns false if unable.
    public func openInGui(filesOrLink: [String], block: Bool, createFrame: Bool) -> Bool {
        if !activateFrame(createFrame: createFrame) { return false }
        if filesOrLink.isEmpty {
            FileHandle.standardError.write("No files to open\n".data(using: .utf8)!)
            return false
        }
        let filesString = filesOrLink.joined(separator: " ")
        let blockClause = block ? "" : "--no-wait "
        return runEmacsClientAndCheck("\(blockClause)\(filesString)")
    }

    /// Opens the given files or org-protocol link in a tty Emacs frame in the calling terminal, or returns false if unable.
    /// Note: As soon as emacsclient is successfully /called/, this process will be replaced by the emacsclient process.
    public func openInTerminal(filesOrLink: [String]) -> Bool {
        if !ensureClient() { return false }
        var arguments = ["--tty"]
        arguments.append(contentsOf: filesOrLink)
        execEmacsClient(arguments: arguments)
        return false  // Reaching here would be a bug
    }

    /// Evaluates the given command using emacsclient, after ensuring that emacsclient is ready, or returns false if unable.
    /// Note: As soon as emacsclient is successfully /called/, this process will be replaced by the emacsclient process.
    public func evalInEmacs(command: String) -> Bool {
        if !ensureClient() { return false }
        execEmacsClient(arguments: ["--eval", command])
        return false  // Reaching here would be a bug
    }

    struct CommandResult {
        let stdout: String
        let stderr: String
        let exitCode: Int32
    }

    private func runEmacsClientAndCheck(_ argumentsString: String) -> Bool {
        runEmacsClient(argumentsString).exitCode == 0
    }

    private func runEmacsClient(_ argumentsString: String) -> CommandResult {
        let task = Process()
        task.launchPath = "/bin/bash"
        let fullCommand: String = getEmacsClientPath() + " " + argumentsString
        task.arguments = ["-c", fullCommand]

        let pipeStdout = Pipe()
        let pipeStderr = Pipe()
        task.standardOutput = pipeStdout
        task.standardError = pipeStderr
        print("Running command: \(fullCommand)")
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

    private func execEmacsClient(arguments: [String]) {
        // TODO: grok and update this
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
        "/opt/homebrew/bin/emacsclient"
    }

}

/// EmacsOpenLibrary singleton instance
public let emacsOpen = EmacsOpenLibrary.shared
