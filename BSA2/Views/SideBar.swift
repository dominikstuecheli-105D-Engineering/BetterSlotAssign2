//
//	SideBar.swift
//  BSA2
//
//  Created by Dominik Stücheli on 14.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



enum LeftRight {
	case left
	case right
}



struct FatHDivider: View {
	var body: some View {
		Rectangle()
			.frame(width: 1.5*5)
			.foregroundStyle(.gray.opacity(0.3/2))
	}
}



struct SideBar<Content: View>: View {
	
	var content: () -> Content
	
	init(_ side: LeftRight, expanded: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
		self.content = content
		self.side = side
		self._expanded = expanded
	}
	
	var side: LeftRight
	@Binding var expanded: Bool
	@State var width: CGFloat = 200
	
    var body: some View {
		HStack(spacing: 0) {
			if expanded {
				if side == .right {
					FatHDivider()
						.ignoresSafeArea()
					
						.overlay {
							Color.clear .frame(width: 20)
							
								.onHover { hovering in
									if hovering {NSCursor.resizeLeftRight.push()
									} else {NSCursor.pop()}
								}
							
								.gesture(DragGesture() .onChanged { value in width = width - value.translation.width})
						}
				}
				
				content()
					.onChange(of: width) { _, new in
						width = max(min(width, 400), 200)
					}
				
					.frame(width: width)
				
				if side == .left {
					FatHDivider()
						.ignoresSafeArea()
					
						.overlay {
							Color.clear .frame(width: 20)
							
								.onHover { hovering in
									if hovering {NSCursor.resizeLeftRight.push()
									} else {NSCursor.pop()}
								}
							
								.gesture(DragGesture() .onChanged { value in width = width + value.translation.width})
						}
				}
			}
		}
    }
}

#Preview {
	@Previewable @State var expandedLeft: Bool = true
	@Previewable @State var expandedRight: Bool = true
	
	HStack {
		SideBar(.left, expanded: $expandedLeft) {
			Rectangle()
				.opacity(0.05)
		}
		
		Spacer()
		
		SideBar(.right, expanded: $expandedRight) {
			Rectangle()
				.opacity(0.05)
		}
	}
	.padding(100)
}
