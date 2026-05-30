//
//	CustomLoadingIndicator.swift
//  BSA2
//
//  Created by Dominik Stücheli on 07.04.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct CustomLoadingIndicator: View {
	
	let n: Int = 5
	let colors: [Color] = [.blue, .green, .yellow, .red]
	
	func color(offset: Double) -> Color {
		return .gray
	}
	
	@State var counter: Int = 1
	let counterMax: Int = 120
	
    var body: some View {
		HStack(spacing: standartPadding) {
			ForEach(1...n, id: \.self) { i in
				RoundedRectangle(cornerRadius: standartPadding)
					.frame(height: standartPadding*3)
			}
		}
    }
}

#Preview {
    CustomLoadingIndicator()
}
