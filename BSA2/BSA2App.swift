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



//App should close fully when window is closed
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return true }
}



@main
struct BSA2App: App {
	
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	private let updateController = UpdateController()
	
    var body: some Scene {
		WindowGroup {
			ContentView()
				.environmentObject(updateController)
		}
		
		.modelContainer(for: [Session.self, PersistentSettings.self], inMemory: false)
		.windowToolbarStyle(.unifiedCompact)
		.windowStyle(.hiddenTitleBar)
		
		.commands {
			CommandGroup(after: .appInfo) { CheckForUpdatesView(updater: updateController.controller.updater) }
		}
    }
}
