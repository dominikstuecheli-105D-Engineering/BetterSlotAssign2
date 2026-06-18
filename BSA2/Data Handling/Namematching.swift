//
//	Namematching.swift
//  BSA2
//
//  Created by Dominik Stücheli on 17.06.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



fileprivate let germanLowercaseAccentsMap: [Character:String] = ["ä": "ae", "ö": "oe", "ü": "ue", "ß": "ss"]



extension String {
	///Formats a name to the format: "firstname maybemiddlename surname" (no capital, no special characters) to make name matching easier
	func nameFormat() -> String {
		var newName = ""
		
		var characterIndexCounter: Int = 0
		var spaceCounter: Int = 0
		
		for character in self {
			characterIndexCounter += 1
			
			//Lowercase
			var revisedCharacter = String(character.lowercased())
			
			//Replace accents with non-german letters
			if let accentReplacement = germanLowercaseAccentsMap[character] { revisedCharacter = accentReplacement }
			
			//Spaces
			if character == " " {
				spaceCounter += 1
				if spaceCounter > 1 {revisedCharacter = ""} ///Replace multiple spaces with only one
				if characterIndexCounter == 1 || characterIndexCounter == self.count { revisedCharacter = "" } ///If the space is the first or last character, disregard
			} else { spaceCounter = 0 }
			
			//Remove diacratic stuff like ê -> e
			revisedCharacter = revisedCharacter.folding(options: .diacriticInsensitive, locale: nil)
			
			newName.append(revisedCharacter)
		}
		
		return newName
	}
}



///String similarity between 0 and 1
func stringSimilarity(_ string1: String, _ string2: String) -> Float {
	guard string1 != string2 else { return 1 }
	
	var totalScore: Float = 0
	var totalCountedCharacters: Int = 0
	
	var finished = false
	var index = 0
	
	while !finished {
		let string1charAtIndex = string1.char(at: index)
		let string2charAtIndex = string2.char(at: index)
		
		guard string1charAtIndex != nil || string2charAtIndex != nil else {finished = true; break}
		
		if string1charAtIndex == string2charAtIndex {
			totalScore += 1; totalCountedCharacters += 1
		///Also check the characters one away in case something was misspelled and the rest of the string is 1 character "behind" or "ahead"
		} else if string1charAtIndex == string2.char(at: index-1) || string1charAtIndex == string2.char(at: index+1) {
			totalScore += 0.5; totalCountedCharacters += 1
		} else { totalCountedCharacters += 1 }
		
		index += 1
	}
	
	return totalScore / Float(totalCountedCharacters)
}



///A similarity that also takes into account differently ordered substrings/words
func stringSimilarityDisregardingWordOrder(_ string1: String, _ string2: String) -> Float {
	let string1substrings = string1.components(separatedBy: " ")
	let string2substrings = string2.components(separatedBy: " ")
	
	let largerSubstringSet: [String]
	let smallerSubstringSet: [String]
	
	if string1substrings.count > string2substrings.count {
		largerSubstringSet = string1substrings
		smallerSubstringSet = string2substrings
	} else {
		largerSubstringSet = string2substrings
		smallerSubstringSet = string1substrings
	}
	
	var totalScore: Float = 0
	var totalCountedCharacterSimilarities: Float = 0
	
	///For every substring in the longer substringset count the best possible match with the smaller substringset
	for substring1 in largerSubstringSet {
		var bestMatch: String = ""
		var bestMatchScore: Float = 0
		
		for substring2 in smallerSubstringSet {
			let similarity = stringSimilarity(substring1, substring2)
			if similarity > bestMatchScore { bestMatchScore = similarity; bestMatch = substring2 }
		}
		let avarageSubstringLength: Float = Float(substring1.count + bestMatch.count) / 2
		
		totalScore += bestMatchScore * avarageSubstringLength
		totalCountedCharacterSimilarities += avarageSubstringLength
	}
	
	return totalScore / totalCountedCharacterSimilarities
}



extension Student {
	///A function that tries to match the blatantly misspelled names of chosen mandatory partner cells
	func findMisspelledPartner(in session: Session, minimumCertainty: Float = 0) -> (partner: Student?, certainty: Float) {
		
		let formattedSearchedName = mandatoryPartner.nameFormat()
		
		var bestMatch: Student?
		var bestMatchCertainty: Float = minimumCertainty ///Set to minimumCertainty so that bestMatch is only set when something above the minimum certainty is found
		
		for student in session.students {
			let formattedName = student.name.nameFormat()
			let similarity = stringSimilarityDisregardingWordOrder(formattedSearchedName, formattedName)
			if similarity >= bestMatchCertainty { bestMatch = student; bestMatchCertainty = similarity }
		}
		
		return (partner: bestMatch, certainty: bestMatchCertainty)
		
	}
}
