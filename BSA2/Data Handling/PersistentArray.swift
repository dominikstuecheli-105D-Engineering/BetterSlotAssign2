//
//	PersistentArray.swift
//  BSA2
//
//  Created by Dominik Stücheli on 14.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers



//I coded my own Array add&remove functions to also handle the position values as SwiftData saves everything as a Set and not really as an orderered Array.
protocol PersistentArrayCompatible: PersistentModel {
	var index: Int {get set}
	var id: UUID {get}
}

extension Array where Element: PersistentArrayCompatible {
	
	//Getting a specific element
	func getIndex(_ index: Int) -> Element? { return first(where: {$0.index == index}) }
	
	//Redoes the position values to always start at 1 and be 1 apart.
	///**OUTDATED, NOT USED INTERNALLY ANYMORE**
	mutating func reIndex() {
		var counter: Int = 1
		
		for item in self.indexSorted() {
			item.index = counter
			counter += 1
		}
	}
	
	//Adding elements
	mutating func add(_ element: Element) {
		if element.index > self.count { element.index = nextIndex(); self.append(element); return } //If no adjustment to the existing elements is needed, just skip the hassle
		
		//The elements existing position value is taken as the insert position, as most of the time the element is newly initialised, where the position value can be set in the initialiser. It does not need to be set in the function call here.
		for item in self { if item.index >= element.index {
			item.index += 1
		} }
		
		self.append(element)
	}
	
	//In case the elements index value should be overwritten
	mutating func add(_ element: Element, at index: Int) {
		element.index = index
		add(element)
	}
	
	//Appending another array
	mutating func add(_ otherArr: [Element]) {
		for item in otherArr.indexSorted() { addAtEnd(item) }
	}
	
	mutating func addAtEnd(_ element: Element) {
		element.index = nextIndex()
		add(element)
	}
	
	//Removing elements
	mutating func remove(_ element: Element, from context: ModelContext? = nil) {
		for item in self.enumerated() {
			if item.element == element { self.remove(at: item.offset) }

			if item.element.index >= element.index { item.element.index -= 1 }
		}
		
		if context != nil {context?.delete(element)} //Fully remove from modelContext if given
	}
	
	//Removing element if only index/position is known
	mutating func remove(itemPosition: Int, from context: ModelContext? = nil) {
		guard itemPosition <= self.count else {return}
		var removedElement: Element?
		
		for item in self.enumerated() {
			if item.element.index == itemPosition { removedElement = self.remove(at: item.offset) }
			
			if item.element.index >= itemPosition { item.element.index -= 1 }
		}
		
		if context != nil && removedElement != nil {context?.delete(removedElement!)} //Fully remove from modelContext if given
	}
	
	//Moving specific elements
	mutating func move(_ element: Element, to newIndex: Int) {
		let oldIndex = element.index
		
		if oldIndex < newIndex {
			for item in self { if item.index > oldIndex && item.index <= newIndex {
				item.index -= 1
			} }
			
			element.index = newIndex
			if element.index > nextIndex() { element.index = nextIndex() }
		}
		
		if oldIndex > newIndex {
			for item in self { if item.index < oldIndex && item.index >= newIndex {
				item.index += 1
			} }
			
			element.index = newIndex
			if element.index > nextIndex() { element.index = nextIndex() }
		}
	}
	
	mutating func moveFromTransferable(to newIndex: Int) {
		guard let element = ReferenceTransferable.reference as? Element else {return}
		move(element, to: newIndex)
	}
	
	//Sorting elements after index
	func indexSorted() -> Array<Element> {return self.sorted(by: {$0.index < $1.index})}
	
	//Adding all element to a modelContext
	func addToModelContext(_ modelContext: ModelContext) {
		for item in self { modelContext.insert(item) }
	}
	
	//The next index
	func nextIndex() -> Int {return self.count + 1}
}



struct ReferenceTransferable: Transferable, Codable {
	
	static var originInformation: Any? = nil
	static var reference: (any PersistentModel)? = nil
	
	init(for object: any PersistentModel, originInformation: Any? = nil) {
		ReferenceTransferable.reference = object
		ReferenceTransferable.originInformation = originInformation
	}
	
	static func reset() { ReferenceTransferable.reference = nil; ReferenceTransferable.originInformation = nil }
	
	static var transferRepresentation: some TransferRepresentation {
		CodableRepresentation(contentType: .data)
	}
}
