//
//	Search.swift
//  BSA2
//
//  Created by Dominik Stücheli on 27.07.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



struct SearchToken<Identifier> {
	let value: String
	let identifier: Identifier
	
	init(_ value: String, identifier: Identifier) {
		self.value = value
		self.identifier = identifier
	}
}



protocol SearchTokenProvider: AnyObject, ViewForceUpdater {
	associatedtype TokenIdentifier: Hashable
	var searchTokens: [SearchToken<TokenIdentifier>] {get}
	var matchingTokensOnLastSearch: Set<TokenIdentifier> {get set}
}



extension String {
	func containsSubstring(_ searchedSubString: String) -> Bool {
		var searchedForCharacterIndex: Int = 0
		guard var searchedForCharacter: Character = searchedSubString.char(at: 0) else {return false}
		
		var charactersLeft = self.count
		
		for character in self {
			guard charactersLeft >= searchedSubString.count-searchedForCharacterIndex else {return false} //If the still searched for substring is longer than the characters left in self the searched for substring is not contained in self
			charactersLeft -= 1
			
			//If the character that is being searched is found, start looking for the next character
			if character == searchedForCharacter {
				searchedForCharacterIndex += 1
			//If the character is not found, start from the beginning of the searched substring
			} else {
				searchedForCharacterIndex = 0
			}
			
			//If all characters of the searched for substring have been found, return true
			if searchedForCharacterIndex > searchedSubString.count-1 {
				return true
			} else {
				searchedForCharacter = searchedSubString.char(at: searchedForCharacterIndex)!
			}
		}
		
		return false
	}
}



extension Array where Element: SearchTokenProvider {
	
	func searchBy(_ searchString: String) -> [Element] {
		
		guard searchString != "" else {
			for item in self { item.matchingTokensOnLastSearch = []; item.forceViewUpdate() }
			return self
		}
		
		let simplifiedSearchString = searchString.simplify()
		
		var matchingItems: [Element] = []
		
		for item in self {
			var hasBeenAddedToMatchingItems: Bool = false
			
			item.matchingTokensOnLastSearch = []
			
			for searchToken in item.searchTokens {
				guard searchToken.value != "" else {continue}
				let simplifiedSearchToken = searchToken.value.simplify()
				
				if simplifiedSearchToken.containsSubstring(simplifiedSearchString) {
					item.matchingTokensOnLastSearch.insert(searchToken.identifier)
					item.forceViewUpdate()
					if !hasBeenAddedToMatchingItems { matchingItems.append(item) }
					hasBeenAddedToMatchingItems = true
					continue
				}
				
				if simplifiedSearchString.containsSubstring(simplifiedSearchToken) {
					item.matchingTokensOnLastSearch.insert(searchToken.identifier)
					item.forceViewUpdate()
					if !hasBeenAddedToMatchingItems { matchingItems.append(item) }
					hasBeenAddedToMatchingItems = true
				}
			}
			
		}
		
		return matchingItems
	}
	
}
