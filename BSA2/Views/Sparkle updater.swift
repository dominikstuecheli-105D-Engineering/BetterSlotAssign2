//
//	Sparkle updater.swift
//  BSA2
//
//  Created by Dominik Stücheli on 11.06.2026.
//

import Foundation
import SwiftUI
import Sparkle
internal import Combine



//MARK: MOST CODE HERE IS COPIED FROM THE SPARKLE INSTRUCTIONS AND NOT WRITTEN BY ME



// This view model class publishes when new updates can be checked by the user
final class CheckForUpdatesViewModel: ObservableObject {
	@Published var canCheckForUpdates = false

	init(updater: SPUUpdater) {
		updater.publisher(for: \.canCheckForUpdates)
			.assign(to: &$canCheckForUpdates)
	}
}

// This is the view for the Check for Updates menu item
// Note this intermediate view is necessary for the disabled state on the menu item to work properly before Monterey.
// See https://stackoverflow.com/questions/68553092/menu-not-updating-swiftui-bug for more info
struct CheckForUpdatesView: View {
	@ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
	private let updater: SPUUpdater
	
	init(updater: SPUUpdater) {
		self.updater = updater
		
		// Create our view model for our CheckForUpdatesView
		self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
	}
	
	var body: some View {
		Button("Nach Updates suchen", action: updater.checkForUpdates) ///Translated to german
			.disabled(!checkForUpdatesViewModel.canCheckForUpdates)
	}
}



//Wrapper to work with SwiftUI
@MainActor final class UpdateController: ObservableObject {
	let controller: SPUStandardUpdaterController
	
	init() {
		controller = SPUStandardUpdaterController(
			startingUpdater: true,
			updaterDelegate: nil,
			userDriverDelegate: nil
		)
	}
}



extension Bundle {
	var appVersion: String {
		infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
	}
	
	var buildNumber: String {
		infoDictionary?["CFBundleVersion"] as? String ?? "–"
	}
}
