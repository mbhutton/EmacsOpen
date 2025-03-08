import ArgumentParser
import EmacsOpenLibrary

struct EmacsOpenCLI: ParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "A utility to integrate Emacs with macOS.",
        subcommands: [
            // TODO Fail if any args
            EnsureClient.self,
            // TODO Fail if any args
            EnsureFrame.self,
            // TODO Fail if any args
            ActivateFrame.self,
            // TODO: Fail if arg count is zero
            OpenFilesWait.self,
            // TODO: Fail if arg count is zero
            OpenFilesNoWait.self,
            // TODO: Fail if arg count is zero
            OpenFilesTerminal.self,
            // TODO: Fail if arg count is not 1
            OpenOrgLink.self,
            // TODO: Fail if arg count is not 1
            Eval.self,
        ],
        defaultSubcommand: ActivateFrame.self
    )
}

struct EnsureClient: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Make sure emacsclient is ready.")

    func run() throws {
        ensureClient()
    }
}

struct EnsureFrame: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Ensure an Emacs frame.")

    func run() throws {
        ensureFrame()
    }
}

struct ActivateFrame: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Activate Emacs frame.")

    func run() throws {
        activateFrame()
    }
}

struct OpenFilesWait: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Open files in Emacs, waiting until buffer closed.")

    @Argument var files: [String]

    func run() throws {
        openFiles(files: files, wait: true, terminal: false)
    }
}

struct OpenFilesNoWait: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Open files in Emacs without waiting.")

    @Argument var files: [String]

    func run() throws {
        openFiles(files: files, wait: false, terminal: false)
    }
}

struct OpenFilesTerminal: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Open files in Emacs in the current terminal.")

    @Argument var files: [String]

    func run() throws {
        openFiles(files: files, wait: false, terminal: true)
    }
}

struct OpenOrgLink: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Open the org-protocol link in Emacs.")

    @Argument var link: String

    func run() throws {
        openOrgLink(link: link)
    }
}

struct Eval: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Evaluate Emacs Lisp commands.")

    @Argument var command: String

    func run() throws {
        evalInEmacs(command: command)
    }
}

EmacsOpenCLI.main()
