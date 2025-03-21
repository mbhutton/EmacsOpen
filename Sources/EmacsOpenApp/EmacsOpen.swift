import EmacsOpenLibrary
import SwiftUI

@main struct MenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("My App", systemImage: "link") {
            VStack {
                Text("My Share Extension App").padding()

                Divider()

                Button("Activate Frame") {
                    print("Activating Frame")
                    _ = activateFrame()
                }.padding()

                Divider()

                Button("Create Frame") {
                    print("Creating Frame")
                    _ = activateFrame(createFrame: true)
                }.padding()

                Divider()

                Button("Quit EmacsOpen") {
                    print("Quitting EmacsOpen")
                    NSApplication.shared.terminate(nil)
                }.padding()
            }
        }.menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    let path = "/Users/matt/sw/emacsopen/emacsopen"

    func applicationDidFinishLaunching(_: Notification) {
        let path = "/Users/matt/sw/emacsopen/emacsopen"
        runCommand("echo hello")
        runCommand(path)

        print("Hello World from SwiftUI menu bar app!")

        _ = activateFrame(createFrame: false)
    }
    func applicationWillTerminate(_ notification: Notification) { print("bye from callback") }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.scheme == "org-protocol" {
                runCommand("\(path) emacsopen \(url.absoluteString)")
            } else {
                runCommand("\(path) eemacsopen \(url.path)")
            }
        }
        NSApp.terminate(nil)
    }

}

func runCommand(_ command: String) {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", command]
    task.launch()
    task.waitUntilExit()
}
