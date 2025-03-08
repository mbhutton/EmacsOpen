import SwiftUI

struct EmacsOpenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        runCommand("emacsopen activate-frame")
        NSApp.terminate(nil)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.scheme == "org-protocol" {
                runCommand("emacsopen open-org-link \(url.absoluteString)")
            } else {
                runCommand("emacsopen open-files \(url.path)")
            }
        }
        NSApp.terminate(nil)
    }

    func runCommand(_ command: String) {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        task.launch()
        task.waitUntilExit()
    }
}
