import ArgumentParser
import Darwin
import EmacsOpenLibrary
import Foundation

let execClause: String = "\nReplaces process with emacsclient process."
let incompatibleClause: String = "\nIncompatible with all other OPTIONS."

struct EmacsOpenCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "emacsopen",
        abstract: "Open files and links in Emacs"
    )

    @Flag(
        name: .shortAndLong,
        help: "Block until buffer is closed.\nRequires at least one <file> or <link> argument."
    )
    var block: Bool = false
    @Flag(name: .shortAndLong, help: "Create a new frame.")
    var createFrame: Bool = false
    @Flag(
        name: .shortAndLong,
        help:
        "Evaluate Emacs Lisp commands.\nRequires exactly one <command> argument.\(incompatibleClause)\(execClause)"
    )
    var eval: Bool = false
    @Flag(name: .shortAndLong, help: "Open files in terminal.\(incompatibleClause)\(execClause)")
    var tty: Bool = false
    @Argument(help: "File(s) or org-protocol link to open, or single command in the --eval case.")
    var files: [String] = []

    func run() throws {
        if tty && (block || createFrame || eval) {
            failAndExit("The --tty option is incompatible with all other OPTIONS\n")
        }
        if eval && (tty || block || createFrame) {
            failAndExit("The --eval option is incompatible with all other OPTIONS\n")
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
                failAndExit(
                    "The --block option requires at least one file or org-protocol link argument\n")
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

func failIfFalse(_ flag: Bool) {
    if !flag {
        Darwin.exit(1)
    }
}

EmacsOpenCLI.main()
