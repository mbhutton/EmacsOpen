import ArgumentParser
import Darwin
import EmacsOpenLibrary
import Foundation

struct EmacsOpenCLI: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "emacsopen", abstract: "Open files and links in Emacs")

    @Flag(name: .shortAndLong, help: "Block until buffer is closed.") var block: Bool = false
    @Flag(name: .shortAndLong, help: "Create a new frame.") var createFrame: Bool = false
    @Flag(name: .shortAndLong, help: "Evaluate Emacs Lisp commands.") var eval: Bool = false
    @Flag(name: .shortAndLong, help: "Open files in terminal.") var tty: Bool = false
    @Argument(help: "File(s) or org-protocol link to open.") var files: [String] = []

    func run() throws {
        if tty && (block || createFrame || eval) {
            failAndExit("The --tty option is incompatible with --block, --create-frame, and --eval\n")
        }
        if eval && (tty || block || createFrame) {
            failAndExit("The --eval option is incompatible with --tty, --block, and --create-frame\n")
        }
        if eval {
            if files.count == 1 {
                failIfFalse(evalInEmacs(command: files[0]))
            } else {
                failAndExit("The --eval option requires exactly one command argument\n")
            }
        } else if tty {
            failIfFalse(openInTerminal(filesOrLink: files))
        } else {
            if block && files.isEmpty {
                failAndExit("The --block option requires at least one file or org-protocol link argument\n")
            }
            if files.isEmpty {
                failIfFalse(activateFrame(createFrame: createFrame))
            } else {
                failIfFalse(openInGui(filesOrLink: files, block: block, createFrame: createFrame))
            }
        }
    }
}

func failAndExit(_ message: String) {
    let formattedMessage: Data = message.data(using: .utf8)!
    FileHandle.standardError.write(formattedMessage)
    Darwin.exit(1)
}

func failIfFalse(_ flag: Bool) { if !flag { Darwin.exit(1) } }

EmacsOpenCLI.main()
