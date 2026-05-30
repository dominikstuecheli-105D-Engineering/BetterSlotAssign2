//
//	Allocation generation.swift
//  BSA2
//
//  Created by Dominik Stücheli on 19.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



//HELPER FUNCTIONS

extension Allocation {
	//Make a documentation entry
	fileprivate func document(_ stepCode: String, _ type: AllocationDocumentationEntryType, into modelContext: ModelContext, _ desc: String) {
		let newEntry = AllocationDocumentationEntry(stepCode, index: documentation.nextIndex(), type, desc)
		modelContext.insert(newEntry)
		documentation.add(newEntry)
	}
	
	//Happyness score
	///For a student in a specific category
//	fileprivate func happynessScore(inChoice n: Int) -> Double {
//		switch happynessFunction {
//		case .exponentialDivideSuffering:
//			return -pow(Double(n-1) / Double(choiceAmount-1), 2) + 1
//		case .linear:
//			return -Double(n-1) / Double(choiceAmount-1) + 1
//		case .exponentialConcentrateSuffering:
//			return pow(Double(n-choiceAmount) / Double(choiceAmount-1), 2)
//		}
//	}
	
	fileprivate func happynessScore(_ student: AllocatedStudent, inIndex: Int) -> Double {
		return happynessScore(inChoice: studentIsInChoice(student, inIndex: inIndex))
	}
	
	///For the whole allocation, **returns a total and not an avarage value!!!**
	fileprivate func totalHappynessScore(of categoryArr: [[AllocatedStudent]]) -> Double {
		var totalScore: Double = 0
		
		for category in categoryArr.enumerated() {
			let categoryIndex = category.offset
			
			for student in category.element.enumerated() {
				for choice in student.element.choices {
					if choice.value == categoryIndex {
						totalScore += happynessScore(inChoice: choice.key)
						break
					}
				}
			}
		}; return totalScore
	}
	
	//Finding out in which choice a student is
	///Has to be inside of Allocation because of choiceAmount
	fileprivate func studentIsInChoice(_ student: AllocatedStudent, inIndex: Int) -> Int {
		for choice in student.choices {
			if choice.value == inIndex {return choice.key}
		}
		return choiceAmount //Results in 0 for the happyness score
	}
}

//Helper object to easier give information to functions
///It may seem stupid at first but always giving these three variables in each function call make it worse trust me
private struct ShuffleInformation {
	let allocation: Allocation
	let capacities: [Int]
	let minMembers: [Int]
	let maxSearchDepth: Int
	
	init(allocation: Allocation, capacities: [Int], minMembers: [Int], maxSearchDepth: Int) {
		self.allocation = allocation
		self.capacities = capacities
		self.minMembers = minMembers
		self.maxSearchDepth = maxSearchDepth
	}
}



extension Array where Element == [AllocatedStudent] {
	
	//Moving students
	///This function does not ensure that a move happens. It only executes if it possible or returns false when not possible.
	mutating fileprivate func tryToMoveStudent(_ student: AllocatedStudent, from oldCategory: Int, to newCategory: Int, info: ShuffleInformation) -> (possible: Bool, scoreDelta: Double) {
		if student.mandatoryPartnerName != "" {
			let partner = self[newCategory].first(where: {$0.name == student.mandatoryPartnerName})!
			//Check if there is enough capacity before moving, then move (with partner)
			if self[newCategory].count <= info.capacities[newCategory]-2 && self[oldCategory].count >= info.minMembers[oldCategory]+2 {
				let oldScore = info.allocation.happynessScore(student, inIndex: oldCategory)*2 //*2 because of the identical partner
				
				self[newCategory].append(student)
				self[oldCategory].removeAll(where: {$0.id == student.id})
				self[newCategory].append(partner)
				self[oldCategory].removeAll(where: {$0.id == partner.id})
				
				let newScore = info.allocation.happynessScore(student, inIndex: newCategory)*2
				return (true, newScore-oldScore) //Moved student and partner
			}
		} else {
			//Check if there is enough capacity before moving, then move
			if self[newCategory].count <= info.capacities[newCategory]-1 && self[oldCategory].count >= info.minMembers[oldCategory]+1 {
				let oldScore = info.allocation.happynessScore(student, inIndex: oldCategory)
				
				self[newCategory].append(student)
				self[oldCategory].removeAll(where: {$0.id == student.id})
				
				let newScore = info.allocation.happynessScore(student, inIndex: newCategory)
				return (true, newScore-oldScore) //Moved student
			}
		}; return (false, 0) //Couldnt move
	}
	
	//Forcefully moving students
	///Try to move students, and if not possible, try to free up space in the destination category
	mutating fileprivate func forcefullyMoveStudent(_ student: AllocatedStudent, from oldCategory: Int, to newCategory: Int, info: ShuffleInformation, currentDepth: Int = 1) -> (possible: Bool, scoreDelta: Double) {
		guard currentDepth <= info.allocation.maxSearchDepth else {return (false, 0)}
		
		let triedMoveResult = tryToMoveStudent(student, from: oldCategory, to: newCategory, info: info)
		if triedMoveResult.possible {return triedMoveResult}
		
		if student.mandatoryPartnerName == "" {
			let forceResult = forcefullyFreeUpSlot(at: newCategory, info: info, currentDepth: currentDepth+1)
			let newTriedMoveResult = tryToMoveStudent(student, from: oldCategory, to: newCategory, info: info)
			return (newTriedMoveResult.possible, forceResult.scoreDelta + newTriedMoveResult.scoreDelta)
		} else {
			//When the student has a mandatory partner, two slots need to be vacated
			let forceResult1 = forcefullyFreeUpSlot(at: newCategory, info: info, currentDepth: currentDepth+1)
			let forceResult2 = forcefullyFreeUpSlot(at: newCategory, info: info, currentDepth: currentDepth+1)
			let newTriedMoveResult = tryToMoveStudent(student, from: oldCategory, to: newCategory, info: info)
			return (newTriedMoveResult.possible, forceResult1.scoreDelta + forceResult2.scoreDelta + newTriedMoveResult.scoreDelta)
		}
	}
	
	//Forcefully free up a slot
	///find the option to do that that results in the highest happyness score based on the given happyness function
	mutating fileprivate func forcefullyFreeUpSlot(at categoryIndex: Int, info: ShuffleInformation, currentDepth: Int = 1) -> (possible: Bool, scoreDelta: Double) {
		guard currentDepth < info.allocation.maxSearchDepth else {return (false, 0)}
		
		var bestArr = self
		var bestHappynessScoreDelta: Double = -255
		
		for student in self[categoryIndex] {
			var newArr = self
			//If the next choice doesnt exist, move on
			guard let nextCategoryIndex = student.choices[info.allocation.studentIsInChoice(student, inIndex: categoryIndex)+1] else {continue}
			
			let forceResult = newArr.forcefullyMoveStudent(student, from: categoryIndex, to: nextCategoryIndex!, info: info, currentDepth: currentDepth)
			guard forceResult.possible else {continue}
			
			if forceResult.scoreDelta > bestHappynessScoreDelta {
				bestArr = newArr; bestHappynessScoreDelta = forceResult.scoreDelta
			}
		}
		
		guard bestHappynessScoreDelta != -255 else {return (false, 0)}
		self = bestArr; return (true, bestHappynessScoreDelta)
	}
	
	//Forcefully fill up a slot
	///By trying to move every possible student and finding the option with the highest happyness score
	mutating fileprivate func forcefullyFillSlot(at categoryIndex: Int, info: ShuffleInformation, currentDepth: Int = 1) -> (possible: Bool, scoreDelta: Double) {
		var bestArr = self
		var bestHappynessScoreDelta: Double = -255
		
		for category in self.enumerated().filter({$0.offset != categoryIndex}) {
			for student in category.element.filter({$0.choices.contains(where: {$0.value == categoryIndex})}) {
				var newArr = self
				
				let forceResult = newArr.forcefullyMoveStudent(student, from: category.offset, to: categoryIndex, info: info, currentDepth: currentDepth)
				guard forceResult.possible else {continue}
				
				if forceResult.scoreDelta > bestHappynessScoreDelta {
					bestArr = newArr; bestHappynessScoreDelta = forceResult.scoreDelta
				}
			}
		}
		
		guard bestHappynessScoreDelta != -255 else {return (false, 0)}
		self = bestArr; return (true, bestHappynessScoreDelta)
	}
	
	//Checking if anything is improveable
	mutating fileprivate func checkForImprovements(info: ShuffleInformation, currentDepth: Int = 1) -> (possible: Bool, scoreDelta: Double) {
		var improvementsPossible = true
		var anyImprovementsDone = false
		var totalHappynessScoreDelta: Double = 0
		
		while improvementsPossible {
			improvementsPossible = false
			var bestArr = self
			var bestHappynessScoreDelta: Double = 0
			
			for category in self.enumerated() { for student in category.element {
				for choice in student.choices.filter({$0.value != category.offset}) {
					var newArr = self
					
					let forceResult = newArr.forcefullyMoveStudent(student, from: category.offset, to: choice.value!, info: info, currentDepth: currentDepth)
					guard forceResult.possible else {continue}
					
					if forceResult.scoreDelta > bestHappynessScoreDelta {
						bestArr = newArr; bestHappynessScoreDelta = forceResult.scoreDelta
						improvementsPossible = true
					}
				} }
			}
			
			if improvementsPossible {
				anyImprovementsDone = true
				totalHappynessScoreDelta += bestHappynessScoreDelta
				self = bestArr
			}
		}
		
		return (anyImprovementsDone, totalHappynessScoreDelta)
	}
}
	
	
	
//MAIN GENERATE FUNCTION

extension Allocation {
	func generateOLD(from session: Session, into modelContext: ModelContext) {
		
		//Time management
		let startTime: Date = .now
		
		func timeSinceStart() -> TimeInterval {return -startTime.timeIntervalSinceNow}
		func maxTimeExceeded() -> Bool {return timeSinceStart() > maxTime}
		func documentTimeExceed(at stepCode: String) {
			document(stepCode, .exitError, into: modelContext, "Maximale Laufzeit überschritten (\(timeSinceStart().rounded())s): Zuteilung wahrscheinlich nicht möglich. Versuchen sie die Kapazitäten zu erhöhen oder geben sie den Schüler*innen allenfalls mehr Wahlmöglichkeiten.")
		}
		
		//Starting
		var mainCategoryArr: [[AllocatedStudent]] = [] ///This array makes handling students and modifying copies easier because no object duplication is required
		
		///The following arrays are duplicates of the data in each AllocatedCategory object but are the ones actually respected by the algorithm. they are sometimes also changed in the process to for example empty a category by setting its capacity to 0 because it couldnt be filled.
		var capacities: [Int] = []
		var minMembers: [Int] = []
		
		document("", .stageSeperator, into: modelContext, "Automatische Zuteilung begonnen")
		
		//1. Copying existing data
		mainCategoryArr.insert([], at: 0) //At index 0 are the unallocated students
		capacities.insert(0, at: 0)
		minMembers.insert(0, at: 0)
		
		///Small helper function to generate the helper object for all the helper functions
		//MARK: ALREADY PREPARED FOR MULTITHREADING, NOT ALL PROPERTIES MAY BE NEEDED
		func infoObject() -> ShuffleInformation {return ShuffleInformation(allocation: self, capacities: capacities, minMembers: minMembers, maxSearchDepth: maxSearchDepth)}
		
		///**1.1** Copying students into mainCategoryArr[0]
		for student in session.students {
			let newInstance = AllocatedStudent(from: student, choiceAmount: choiceAmount)
			modelContext.insert(newInstance)
			mainCategoryArr[0].add(newInstance)
		}
		
		///**1.2** Linking mandatory partners
		if allowForMandatoryPartners { for student in mainCategoryArr[0] {
			if student.mandatoryPartnerName != "" {
				if let partner = mainCategoryArr[0].first(where: {$0.name == student.mandatoryPartnerName}) {
					if student.choices == partner.choices {
						student.mandatoryPartnerName = partner.name
					} else {
						document("1.2.1", .error, into: modelContext, "\(student.name) und \(partner.name) haben nicht identisch gewählt und werden nicht als Partner berücksichtigt.")
					}
				} else {
					document("1.2.2", .error, into: modelContext, "Zwingende*r Partner*in von \(student.name) Konnte nicht gefunden werden und wird nicht berücksichtigt.")
				}
			}
		} }
		
		///**1.3** Copying categories
		var categoryIndexCounter = 1
		
		for category in session.categories.indexSorted() {
			if let newInstance = AllocatedCategory(from: category) {
				
				///1.3.1 Not following to the last category with number n+1
				if newInstance.index != categoryIndexCounter {
					document("1.3.1", .exitError, into: modelContext, "Die Nummer von \"\(category.name)\" folgt nicht um +1 der davor. Die Nummern der Kategorien müssen einer anderen um jeweils +1 folgen.")
					return
				} else {
					categoryIndexCounter += 1
				}
				
				modelContext.insert(newInstance)
				categories.append(newInstance) //Intentionally not .add() so that index values are not messed with since the index is now the number
				mainCategoryArr.insert([], at: newInstance.index)
				capacities.insert(newInstance.capacity, at: newInstance.index)
				
				if studentBalancing == .tryToFillCategoriesWithNotEnoughMembers {
					minMembers.insert(newInstance.minParticipants, at: newInstance.index) //If underfilled categories should be filled, set the actual value here
				} else {
					minMembers.insert(0, at: newInstance.index) //If underfilled categories should be deleted, just set 0 so that students are allowed to be moved out of these categories
				}
			} else {
				///1.3.2 No number given
				if category.number == nil {
					document("1.3.2", .error, into: modelContext, "\"\(category.name)\" konnte nicht übernommen werden: keine Nummer gegeben")
				}
				///1.3.3 No Capacity given
				if category.capacity == nil {
					document("1.3.3", .error, into: modelContext, "\"\(category.name)\" konnte nicht übernommen werden: keine Kapazität gegeben")
				}
				///1.3.4 No min. Member count given
				if category.minParticipantRequirement == nil {
					document("1.3.4", .error, into: modelContext, "\"\(category.name)\" konnte nicht übernommen werden: keine Mindestanzahl für Teilnehmer gegeben")
				}
			}
		}
		
		///**1.4** Checking if there is enough capacity in total
		var totalCapacity: Int = 0
		for category in categories {
			totalCapacity += category.capacity
		}
		if mainCategoryArr[0].count > totalCapacity {
			document("1.4", .exitError, into: modelContext, "Es ist gesamt nicht genügend Kapazität gegeben")
			return
		}
		
		///**1.5** Check if given choices are valid
		for student in mainCategoryArr[0] {
			var invalid = false
			
			for choice in student.choices {
				///**2.1** Is a choice given?
				if choice.value == nil {
					document("1.5.1", .error, into: modelContext, "\"\(student.name)\" Hat als \(choice.key). Wahl nichts angegeben und wird ab jetzt nicht mehr berücksichtigt.")
					invalid = true
				///**2.2** Is it a valid choice?
				}else if !categories.contains(where: {$0.index == choice.value}) {
					document("1.5.2", .error, into: modelContext, "\"\(student.name)\" Hat als \(choice.key). Wahl eine Kategorie angegeben, die es nicht gibt und wird ab jetzt nicht mehr berücksichtigt.")
					invalid = true
				}
			}
			
			if invalid {
				mainCategoryArr[0].remove(student)
				unAllocatedStudents.addAtEnd(student)
			}
		}
		
		//2. Assigning everyone to first choice
		for student in mainCategoryArr[0] {
			let newCategoryIndex = student.choices[1]!!
			mainCategoryArr[0].remove(student)
			mainCategoryArr[newCategoryIndex].add(student)
		}
		
		//3. Juggling students around
		
		///I'm sorry for the indentation you're about to witness **(^-^)
		var overshootFinished: Bool = false
		var undershootFinished: Bool = false
		
		while !overshootFinished || !undershootFinished { //Main loop
			
			///**3.1** Handling overshoot (More students than capacity)
			while !overshootFinished { overshootFinished = true; for categoryIndex in 1...mainCategoryArr.count-1 { //Overshoot loop
				let category = mainCategoryArr[categoryIndex]
				let capacity = capacities[categoryIndex]
				
				if category.count > capacity {
					overshootFinished = false
					if !mainCategoryArr.forcefullyFreeUpSlot(at: categoryIndex, info: infoObject()).possible {
						document("3.1", .error, into: modelContext, "Kategorie \(categoryIndex) Hat zu viele Teilnehmer (\(category.count)/\(capacity)) von denen niemand bewegt werden kann.")
					}
				}
				
				//Safeguard for impossible allocations
				if maxTimeExceeded() {overshootFinished = true; undershootFinished = true; documentTimeExceed(at: "3.1")}
				
			} } //END < for categoryIndex in 1...mainCategoryArr.count-1 > //END Overshoot loop
			
			///**3.2** Handlung undershoot (Less students than required)
			while !undershootFinished && overshootFinished { undershootFinished = true; for category in self.categories { //Undershoot loop
				if mainCategoryArr[category.index].count < category.minParticipants { switch studentBalancing {
					
					///**3.2.1**
				case .deleteCategoriesWithNotEnoughMembers:
					if capacities[category.index] != 0 {
						capacities[category.index] = 0
						document("3.2.1", .error, into: modelContext, "\(category.name) hat nicht genügend Teilnehmer; Teilnehmer werden nun anders verteilt.")
						overshootFinished = false //So that the overshoot loop is triggered again
					}
					
					///**3.2.2**
				case .tryToFillCategoriesWithNotEnoughMembers:
					undershootFinished = false
					if !mainCategoryArr.forcefullyFillSlot(at: category.index, info: infoObject()).possible {
						document("3.2.2", .error, into: modelContext, "\(category.name) hat nicht genügend Teilnehmer und lässt sich mit niemandem füllen.")
					}
					overshootFinished = false //So that the overshoot loop is triggered again
				} }
				
				//Safeguard for impossible allocations
				if maxTimeExceeded() {overshootFinished = true; undershootFinished = true; documentTimeExceed(at: "3.2")}
				
			} } //END < for category in categories > //END Undershoot loop
			
			///**3.3** Checking for possible improvements
			if mainCategoryArr.checkForImprovements(info: infoObject()).possible {
				overshootFinished = false; undershootFinished = false
			}
			
			//Safeguard for impossible allocations
			if maxTimeExceeded() {overshootFinished = true; undershootFinished = true; documentTimeExceed(at: "3.3")}
			
		} //END Main loop
		
		//4. Append all students from the mainCategoryArr to the actual category classes and other finishing touches
		let totalHappynessScore = totalHappynessScore(of: mainCategoryArr)
		var studentCounter = 0
		
		///Part of this is also repairing all index values because they havent really been respected because of the duplicate arrays and stuff
		for category in categories {
			mainCategoryArr[category.index].reIndex()
			category.students = mainCategoryArr[category.index]
			studentCounter += category.students.count
		}
		
		///Unallocated students
		mainCategoryArr[0].reIndex()
		unAllocatedStudents = mainCategoryArr[0]
		studentCounter += unAllocatedStudents.count
		
		///Happyness score
		happynessScore = totalHappynessScore/Double(studentCounter)
		
		if documentation.last?.type != .exitError {
			document("", .stageSeperator, into: modelContext, "Automatische Zuteilung beendet")
		}
		
		print("exited generate() function after \(timeSinceStart())s")
	}
}
