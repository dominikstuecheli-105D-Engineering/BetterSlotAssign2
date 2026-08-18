//
//	SearchedAndFoundOverlay.swift
//  BSA2
//
//  Created by Dominik Stücheli on 27.07.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct MarkAsSearchedAndFoundViewModifier: ViewModifier {
	
	var mark: Bool
	
	func body(content: Content) -> some View {
		content
			.overlay { if mark {
				SearchedAndFoundOverlay(color1: .blue, color2: .white) .allowsHitTesting(false)
			} }
	}
}

extension View {
	func markAsSearchedAndFound(_ mark: Bool) -> some View {
		modifier(MarkAsSearchedAndFoundViewModifier(mark: mark))
	}
	
	func markWhenSearchTokenMatched<Item: SearchTokenProvider>(_ item: Item, matchingToken: Item.TokenIdentifier) -> some View {
		modifier(MarkAsSearchedAndFoundViewModifier(mark: item.matchingTokensOnLastSearch.contains(matchingToken)))
	}
}



struct SearchedAndFoundOverlay: View {
	
	let thickness = standartPadding*0.75
	let color1: Color
	let color2: Color
	
	func drawRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, into context: GraphicsContext, color: Color) {
		context.fill(Path { path in
			path.addRect(CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height)))
		}, with: .color(color))
	}
	
    var body: some View {
		Canvas { context, size in
			
			//drawing corners
			drawRect(x: 0, y: 0, width: thickness, height: thickness, into: context, color: color2)
			drawRect(x: size.width-thickness, y: 0, width: thickness, height: thickness, into: context, color: color2)
			drawRect(x: 0, y: size.height-thickness, width: thickness, height: thickness, into: context, color: color2)
			drawRect(x: size.width-thickness, y: size.height-thickness, width: thickness, height: thickness, into: context, color: color2)
			
			//horizontal lines
			let horizontalRectangleCount: CGFloat = ((size.width-2*thickness)/(thickness*2)).rounded()*2 - 1
			let horizontalRectangleWidth: CGFloat = (size.width-2*thickness)/horizontalRectangleCount
			
			for i in 0...Int(horizontalRectangleCount)-1 {
				drawRect(x: CGFloat(i)*horizontalRectangleWidth + thickness, y: 0, width: horizontalRectangleWidth, height: thickness, into: context, color: isEven(i) ? color1 : color2)
				drawRect(x: CGFloat(i)*horizontalRectangleWidth + thickness, y: size.height-thickness, width: horizontalRectangleWidth, height: thickness, into: context, color: isEven(i) ? color1 : color2)
			}
			
			//vertical lines
			let verticalRectangleCount: CGFloat = ((size.height-2*thickness)/(thickness*2)).rounded()*2 - 1
			let verticalRectangleHeight: CGFloat = (size.height-2*thickness)/verticalRectangleCount
			
			for i in 0...Int(verticalRectangleCount)-1 {
				drawRect(x: 0, y: CGFloat(i)*verticalRectangleHeight + thickness, width: thickness, height: verticalRectangleHeight, into: context, color: isEven(i) ? color1 : color2)
				drawRect(x: size.width-thickness, y: CGFloat(i)*verticalRectangleHeight + thickness, width: thickness, height: verticalRectangleHeight, into: context, color: isEven(i) ? color1 : color2)
			}
			
			//Edges
			drawRect(x: 0, y: 0, width: size.width, height: thickness/3, into: context, color: color1)
			drawRect(x: size.width-thickness/3, y: 0, width: thickness/3, height: size.height, into: context, color: color1)
			drawRect(x: 0, y: size.height-thickness/3, width: size.width, height: thickness/3, into: context, color: color1)
			drawRect(x: 0, y: 0, width: thickness/3, height: size.height, into: context, color: color1)
		}
    }
}
