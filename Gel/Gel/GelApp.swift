import SwiftUI

@main
struct GelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // The main window is owned by AppDelegate (so the menu bar and launcher can show it);
        // this empty Settings scene satisfies SwiftUI's need for at least one scene.
        Settings { EmptyView() }
    }
}
