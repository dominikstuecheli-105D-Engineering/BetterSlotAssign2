//
//	Namematching.swift
//  BSA2
//
//  Created by Dominik Stücheli on 17.06.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



///String similarity between 0 and 1
func stringSimilarity(_ string1: String, _ string2: String, minimumSimilarity: Float = 0) -> Float {
	guard string1 != string2 else { return 1 }
	
	if minimumSimilarity != 0 && (Float(string1.count) >= Float(string2.count)/minimumSimilarity || Float(string1.count) <= Float(string2.count)*minimumSimilarity) { return 0 } ///If the strings lengths are too far apart and would very probably be less similar than dictated by minimumSimilarity just end early and return
	
	let chars1 = Array(string1)
	let chars2 = Array(string2)
	
	var totalScore: Float = 0
	var totalCountedCharacters: Int = 0
	
	var finished = false
	var index = 0
	
	while !finished {
		let string1charAtIndex = chars1.char(at: index)
		let string2charAtIndex = chars2.char(at: index)
		
		guard string1charAtIndex != nil || string2charAtIndex != nil else {finished = true; break}
		
		if string1charAtIndex == string2charAtIndex {
			totalScore += 1; totalCountedCharacters += 1
		///Also check the characters one away in case something was misspelled and the rest of the string is 1 character "behind" or "ahead"
		} else if string1charAtIndex == chars2.char(at: index-1) || string1charAtIndex == chars2.char(at: index+1) {
			totalScore += 0.5; totalCountedCharacters += 1
		} else { totalCountedCharacters += 1 }
		
		index += 1
	}
	
	return totalScore / Float(totalCountedCharacters)
}



///A similarity that also takes into account differently ordered substrings/words
func stringSimilarityDisregardingWordOrder(_ string1: String, _ string2: String, minimumSimilarity: Float = 0) -> Float {
	if minimumSimilarity != 0 && (Float(string1.count) >= Float(string2.count)/minimumSimilarity || Float(string1.count) <= Float(string2.count)*minimumSimilarity) { return 0 }
	
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
			let similarity = stringSimilarity(substring1, substring2, minimumSimilarity: minimumSimilarity)
			if similarity > bestMatchScore { bestMatchScore = similarity; bestMatch = substring2 }
		}
		let avarageSubstringLength: Float = Float(substring1.count + bestMatch.count) / 2
		
		totalScore += bestMatchScore * avarageSubstringLength
		totalCountedCharacterSimilarities += avarageSubstringLength
	}
	
	return totalScore / totalCountedCharacterSimilarities
}



//Cache objects
///Name pair after which similarities can be indexed
fileprivate struct NamePair: Hashable {
	let name1: String
	let name2: String
	
	init(_ name1: String, _ name2: String) {
		self.name1 = name1
		self.name2 = name2
	}
	
	func inversed() -> NamePair {
		return NamePair(name2, name1)
	}
}



///Actual cache object that handles the data
final class NameSimilarityCache {
	private static var nameSimilarities: [NamePair:Float] = [:]
	
	static func getExistingSimilarity(_ name1: String, _ name2: String) -> Float? {
		let namePair = NamePair(name1, name2)
		if let existing1 = nameSimilarities[namePair] { return existing1 }
		else { return nameSimilarities[namePair.inversed()] }
	}
	
	static func addSimilarity(_ name1: String, _ name2: String, similarity: Float) {
		nameSimilarities[NamePair(name1, name2)] = similarity
	}
	
	///Scheduling logic so that a clean only happens once per cell update, even when called multiple times from different cell updates
	private static var cleaningWorkItem: DispatchWorkItem?
	static func scheduleClean(for session: Session) {
		self.cleaningWorkItem?.cancel()
		self.cleaningWorkItem = cleaningWork(for: session)
		DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: cleaningWorkItem!)
	}
	
	///Cleans the cache from all name pairs that are not relevant anymore because one of the names does not exist anymore
	private static func cleaningWork(for session: Session) -> DispatchWorkItem {
		return DispatchWorkItem {
			let initialNamePairCount = nameSimilarities.count
			let startTime: Date = .now
			
			var relevantNames: Set<String> = []
			
			for student in session.students {
				relevantNames.insert(student.formattedName)
				relevantNames.insert(student.mandatoryPartner.simplify())
			}
			
			for namePair in nameSimilarities {
				let name1 = namePair.key.name1
				let name2 = namePair.key.name2
				
				///If one of the two mentioned names is the current one of a student, keep the entry
				if relevantNames.contains(name1) && relevantNames.contains(name2) {continue}
				
				nameSimilarities.removeValue(forKey: namePair.key)
			}
			
			print("Removed \(initialNamePairCount-nameSimilarities.count) name similarities from the NameSimilarityCache (\(-startTime.timeIntervalSinceNow)s)")
		}
	}
}



extension Student {
	///A function that tries to match the blatantly misspelled names of mandatory partner text cells
	func findMisspelledPartner(in session: Session, minimumCertainty: Float = 0) -> (partner: Student?, certainty: Float) {
		
		let formattedSearchedName = mandatoryPartner.simplify()
		let cache = NameSimilarityCache.self
		
		var bestMatch: Student?
		var bestMatchCertainty: Float = minimumCertainty ///Set to minimumCertainty so that bestMatch is only set when something above the minimum certainty is found
		
		for student in session.students {
			let similarity: Float
			
			if let existingSimilarity = cache.getExistingSimilarity(formattedSearchedName, student.formattedName) {
				similarity = existingSimilarity
			} else {
				similarity = stringSimilarityDisregardingWordOrder(formattedSearchedName, student.formattedName, minimumSimilarity: minimumCertainty)
				cache.addSimilarity(formattedSearchedName, student.formattedName, similarity: similarity)
			}
			
			if similarity >= bestMatchCertainty { bestMatch = student; bestMatchCertainty = similarity }
		}
		
		cache.scheduleClean(for: session)
		return (partner: bestMatch, certainty: bestMatchCertainty)
	}
}
