import ArgumentParser
import Darwin
import EmacsOpenLibrary
import Foundation

struct EmacsOpenCLI: ParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "A utility to integrate Emacs with macOS.",
        subcommands: [
            EnsureClient.self,
            EnsureFrame.self,
            ActivateFrame.self,
            OpenFiles.self,
            OpenOrgLink.self,
            Eval.self,
        ],
        defaultSubcommand: ActivateFrame.self
    )
}

struct EnsureClient: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Make sure emacsclient is ready.")

    func run() throws {
        exitIfFalse(ensureClient())
    }
}

struct EnsureFrame: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Ensure an Emacs frame.")

    @Flag(name: .shortAndLong, help: "Create a new frame.")
    var createFrame: Bool = false

    func run() throws {
        exitIfFalse(ensureFrame(createFrame: createFrame))
    }
}

struct ActivateFrame: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Activate Emacs frame.")

    @Flag(name: .shortAndLong, help: "Create a new frame.")
    var createFrame: Bool = false

    func run() throws {
        exitIfFalse(activateFrame(createFrame: createFrame))
    }
}

struct OpenFiles: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Open files in Emacs, waiting until buffer closed.")

    @Flag(name: .shortAndLong, help: "Wait until buffer is closed.")
    var wait: Bool = false
    @Flag(name: .shortAndLong, help: "Create a new frame.")
    var createFrame: Bool = false
    @Flag(name: .shortAndLong, help: "Open files in terminal.")
    var tty: Bool = false
    @Argument var files: [String]

    func run() throws {
        if tty {
            if wait || createFrame {
                FileHandle.standardError.write(
                    "The --tty options is incompatible with --wait and --create-frame\n"
                        .data(using: .utf8)!)
                Darwin.exit(1)
            } else {
                exitIfFalse(openFilesInTerminal(files: files))
            }
        } else {
            exitIfFalse(
                openFilesInGui(files: files, wait: wait, createFrame: createFrame))
        }
    }
}

struct OpenOrgLink: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Open the org-protocol link in Emacs.")

    @Flag(name: .shortAndLong, help: "Create a new frame.")
    var createFrame: Bool = false
    @Argument var link: String

    func run() throws {
        exitIfFalse(openOrgLink(link: link, createFrame: createFrame))
    }
}

struct Eval: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Evaluate Emacs Lisp commands.")

    @Argument var command: String

    func run() throws {
        exitIfFalse(evalInEmacs(command: command))
    }
}

func exitIfFalse(_ flag: Bool) {
    if !flag {
        Darwin.exit(1)
    }
}

EmacsOpenCLI.main()
