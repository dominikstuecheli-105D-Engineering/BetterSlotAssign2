//
//	LUA Editor.swift
//  BSA2
//
//  Created by Dominik Stücheli on 14.07.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftUI
import CodeEditor



struct LUAEditor: View {
	
	@Binding var code: String
	
	@Environment(\.colorScheme) private var colorScheme: ColorScheme
	
	var body: some View {
			CodeEditor(source: $code, language: .lua, theme: CodeEditor.ThemeName(rawValue: colorScheme == .light ? "tomorrow" : "tomorrow-night-eighties"))
	}
}
