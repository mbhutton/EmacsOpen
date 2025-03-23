import EmacsOpenLibrary
import SwiftUI
import UserNotifications

@main struct MenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("My App", systemImage: "link") {
            VStack {
                Text("My Share Extension App").padding()

                Divider()

                Button("Activate Frame") {
                    print("Activating Frame")
                    _ = emacsOpen.activateFrame()
                }.padding()

                Divider()

                Button("Create Frame") {
                    print("Creating Frame")
                    _ = emacsOpen.activateFrame(createFrame: true)
                }.padding()

                Divider()

                Button("Show Notification") {
                    print("Showing Notification")
                    showNotification(title: "Hello", message: "This is a test notification.")
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
        NSApp.setActivationPolicy(.accessory)
        let path = "/Users/matt/sw/emacsopen/emacsopen"
        runCommand("echo hello")
        runCommand(path)

        print("Hello World from SwiftUI menu bar app!")

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
                return
            }
            if granted { print("Notification permissions granted") } else { print("Notification permissions denied") }
        }

        _ = emacsOpen.activateFrame(createFrame: false)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        _ = emacsOpen.activateFrame(createFrame: false)
        return true
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

func showNotification(title: String, message: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.sound = UNNotificationSound.default

    // Create a request with immediate trigger
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

    // Add the request to notification center
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error { print("Error showing notification: \(error.localizedDescription)") }
    }
}
