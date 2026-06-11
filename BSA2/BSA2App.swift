//
//	BSA2App.swift
//  BSA2
//
//  Created by Dominik Stücheli on 12.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import SwiftData
import AppKit
import Sparkle



//App should close fully when window is closed; only on macOS
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return true }
}



@main
struct BSA2App: App {
	
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
	
    var body: some Scene {
		WindowGroup {
			ContentView()
		}
		
		.modelContainer(for: [Session.self, PersistentSettings.self], inMemory: false)
		.windowToolbarStyle(.unifiedCompact)
		.windowStyle(.hiddenTitleBar)
		
		.commands {
			CommandGroup(after: .appInfo) {
				CheckForUpdatesView(updater: updaterController.updater)
			}
		}
    }
}
