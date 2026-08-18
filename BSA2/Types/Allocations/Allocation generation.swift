//
//	Allocation generation.swift
//  BSA2
//
//  Created by Dominik Stücheli on 19.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



//This file contains all the code that actually generates allocations.



//MARK: HELPER FUNCTIONS

//Truncating the student choice dictionary to remove unused nil values and sort it
extension Dictionary where Key == Int, Value == Int? {
	func truncated(toLength length: Int) -> [Int:Int?] {
		var returnSet: [Int:Int?] = [:]
		for choice in self.sorted(by: {$0.key < $1.key}) {
			if choice.key <= length { returnSet[choice.key] = choice.value }
		}
		return returnSet
	}
}

extension Allocation {
	
	//Make a documentation entry
	fileprivate func document(_ stepCode: String, _ timestamp: TimeInterval, _ type: AllocationDocumentationEntryType, into modelContext: ModelContext, _ desc: String) {
		let newEntry = AllocationDocumentationEntry(stepCode, timestamp: timestamp, index: documentation.nextIndex(), type, desc)
		modelContext.insert(newEntry)
		documentation.add(newEntry)
	}
	
	//Happyness score
	///For the whole allocation, **returns a total and not an avarage value!!!**
	fileprivate func totalHappynessScore(of categoryArr: [[AllocatedStudentDummy]]) -> Double {
		var totalScore: Double = 0
		
		for category in categoryArr.enumerated() {
			for student in category.element.enumerated() {
				totalScore += student.element.happynessScores[student.element.choiceFromCategory[category.offset]!]
			}
		}; return totalScore
	}
}

//Nice-ified print statement
nonisolated func nicePrint(_ string: String, do execute: Bool = true, level: Int = 1) {
	if execute { switch level {
	case 0:
		print("")
		print("|0")
		print(string)
		print("|0")
		print("")
	case 1: print(string)
	default:
		var newString = ""
		for _ in 1...level-1 {
			newString.append("|-----")
		}
		print("\(newString) \(string)")
	} }
}



//MARK: HELPER OBJECTS

//Helper object to transmit progress data to a view
@MainActor @Observable final class AsyncProgress {
	var currentStep: String = ""
}

//Helper object to easier give information to functions
///It may seem stupid at first but always giving these three variables in each function call makes it a lot worse trust me
private nonisolated final class ShuffleInformation {
	let choiceAmount: Int
	let capacities: [Int]
	let minMembers: [Int]
	let maxSearchDepth: Int
	var debugMode: Bool
	
	//Time management
	let startTime: Date
	var maxTime: TimeInterval
	let allowDymanicTime: Bool
	
	func timeSinceStart() -> TimeInterval {return -startTime.timeIntervalSinceNow}
	func maxTimeExceeded() -> Bool {
		switch allowDymanicTime {
		case true: return false
		case false: return timeSinceStart() > maxTime
		}
	}
	
	init(choiceAmount: Int, capacities: [Int], minMembers: [Int], maxSearchDepth: Int, startTime: Date, maxTime: TimeInterval, allowDymanicTime: Bool, debugMode: Bool) {
		self.choiceAmount = choiceAmount
		self.capacities = capacities
		self.minMembers = minMembers
		self.maxSearchDepth = maxSearchDepth
		self.debugMode = debugMode
		
		self.startTime = startTime
		self.maxTime = maxTime
		self.allowDymanicTime = allowDymanicTime
	}
	
	init(from existing: ShuffleInformation, modifiedDepth: Int) {
		self.choiceAmount = existing.choiceAmount
		self.capacities = existing.capacities
		self.minMembers = existing.minMembers
		self.debugMode = existing.debugMode
		
		self.startTime = existing.startTime
		self.maxTime = existing.maxTime
		self.allowDymanicTime = existing.allowDymanicTime
		
		if modifiedDepth >= existing.maxSearchDepth {
			self.maxSearchDepth = existing.maxSearchDepth
		} else {
			self.maxSearchDepth = modifiedDepth
		}
	}
}



//Multithreading actor that following functions build up on
private actor MultiResultTracker {
	var bestScore: Double
	var bestArr: [[AllocatedStudentDummy]]
	
	init(initialScore: Double, initialArr: [[AllocatedStudentDummy]]) {
		self.bestScore = initialScore; self.bestArr = initialArr
	}
	
	func submit(score: Double, with newArr: [[AllocatedStudentDummy]]) {
		if score > bestScore {bestScore = score; bestArr = newArr}
	}
}



//Dummy struct that can be used in multithreading
final class AllocatedStudentDummy: Equatable {
	let name: String
	let id: UUID
	var mandatoryPartner: AllocatedStudentDummy?
	
	let categoryFromChoice: [Int:Int] //Dictionary where the key is the choice index and the value is the category index
	let choiceFromCategory: [Int:Int] //Dictionary where the key is the category index and the value is the choice index
	let happynessScores: [Double] //Key is inChoice
	
	var gender: String
	var group: String
	var profile: String
	
	init(from student: Student, happynessFunction: HappynessFunction, choiceAmount: Int) throws {
		self.name = student.name
		self.id = student.id
		
		self.gender = student.gender
		self.group = student.group
		self.profile = student.profile
		
		var categoryFromChoice: [Int:Int] = [:]
		var choiceFromCategory: [Int:Int] = [:]
		
		for choice in student.choices {
			if choice.key <= choiceAmount {
				categoryFromChoice[choice.key] = choice.value!
				choiceFromCategory[choice.value!] = choice.key
			}
		}
		
		self.categoryFromChoice = categoryFromChoice
		self.choiceFromCategory = choiceFromCategory
		
		var happynessScores: [Double] = [0]
		
		try happynessFunction.openLuaState()
		for i in 1...choiceAmount {
			try happynessScores.append(happynessFunction.execute(student: student, inChoice: i, choiceAmount: choiceAmount, openLuaState: false, closeLuaState: false))
		}
		happynessFunction.closeLuaState()
		
		self.happynessScores = happynessScores
	}
	
	static func == (lhs: AllocatedStudentDummy, rhs: AllocatedStudentDummy) -> Bool {
		return lhs.id == rhs.id
	}
}



//MARK: CORE SHUFFLE FUNCTIONS

extension Array where Element == [AllocatedStudentDummy] {
	
	//MARK: Moving students
	///This function does not ensure that a move happens. It only executes if it possible or returns false when not possible.
	nonisolated mutating fileprivate func tryToMoveStudent(_ student: AllocatedStudentDummy, from oldCategory: Int, to newCategory: Int, info: ShuffleInformation) async -> (possible: Bool, scoreDelta: Double) {
		//Different code for movement with or without partner
		if let partner = await student.mandatoryPartner {
			//Check if there is enough capacity before moving, then move (with partner)
			if self[newCategory].count <= info.capacities[newCategory]-2 && self[oldCategory].count >= info.minMembers[oldCategory]+2 {
				let oldScore = student.happynessScores[student.choiceFromCategory[oldCategory]!]*2 //*2 because of the identical partner
				
				self[newCategory].append(student)
				self[oldCategory].removeAll(where: {$0.id == student.id})
				self[newCategory].append(partner)
				self[oldCategory].removeAll(where: {$0.id == partner.id})
				
				let newScore = student.happynessScores[student.choiceFromCategory[newCategory]!]*2
				return (true, newScore-oldScore) //Moved student and partner
			}
		} else {
			//Check if there is enough capacity before moving, then move
			if self[newCategory].count <= info.capacities[newCategory]-1 && self[oldCategory].count >= info.minMembers[oldCategory]+1 {
				let oldScore = student.happynessScores[student.choiceFromCategory[oldCategory]!]
				
				self[newCategory].append(student)
				self[oldCategory].removeAll(where: {$0.id == student.id})
				
				let newScore = student.happynessScores[student.choiceFromCategory[newCategory]!]
				return (true, newScore-oldScore) //Moved student
			}
		}; return (false, 0) //Couldnt move
	}
	
	//MARK: Forcefully moving students
	///Try to move students, and if not possible, try to free up space in the destination category
	nonisolated mutating fileprivate func forcefullyMoveStudent(_ student: AllocatedStudentDummy, from oldCategory: Int, to newCategory: Int, path: [Int] = [], info: ShuffleInformation, currentDepth: Int = 1) async -> (possible: Bool, scoreDelta: Double) {
		guard currentDepth <= info.maxSearchDepth && !info.maxTimeExceeded() else {return (false, 0)}
		
		let localStartTime: Date = .now
		
		let triedMoveResult = await tryToMoveStudent(student, from: oldCategory, to: newCategory, info: info)
		if triedMoveResult.possible {return triedMoveResult}
		
		if await student.mandatoryPartner == nil {
			let forceResult = await forcefullyFreeUpSlot(at: newCategory, path: path, info: info, currentDepth: currentDepth+1)
			let newTriedMoveResult = await tryToMoveStudent(student, from: oldCategory, to: newCategory, info: info)
			
			let returnValue = (newTriedMoveResult.possible, forceResult.scoreDelta + newTriedMoveResult.scoreDelta)
			nicePrint("exited forcefullyMoveStudent() at Level \(currentDepth) after \(-localStartTime.timeIntervalSinceNow)s with return \(returnValue)", do: info.debugMode, level: currentDepth)
			return returnValue
		} else {
			//When the student has a mandatory partner, two slots need to be vacated
			let forceResult1 = await forcefullyFreeUpSlot(at: newCategory, path: path, info: info, currentDepth: currentDepth+1)
			let forceResult2 = await forcefullyFreeUpSlot(at: newCategory, path: path, info: info, currentDepth: currentDepth+1)
			let newTriedMoveResult = await tryToMoveStudent(student, from: oldCategory, to: newCategory, info: info)
			
			let returnValue = (newTriedMoveResult.possible, forceResult1.scoreDelta + forceResult2.scoreDelta + newTriedMoveResult.scoreDelta)
			nicePrint("exited forcefullyMoveStudent() at Level \(currentDepth) after \(-localStartTime.timeIntervalSinceNow)s with return \(returnValue)", do: info.debugMode, level: currentDepth)
			return returnValue
		}
	}
	
	//MARK: Forcefully free up a slot
	///find the option to do that that results in the highest happyness score based on the given happyness function
	nonisolated mutating fileprivate func forcefullyFreeUpSlot(at categoryIndex: Int, path: [Int] = [], info: ShuffleInformation, currentDepth: Int = 1) async -> (possible: Bool, scoreDelta: Double) {
		guard currentDepth < info.maxSearchDepth && !info.maxTimeExceeded() else {return (false, 0)}
		
		let localStartTime: Date = .now
		let resultTracker = MultiResultTracker(initialScore: -255, initialArr: self)
		var additionalLevelCounter = 0
		var tryingChoiceIndex = 1
		var updatedPath = path; updatedPath.append(categoryIndex) //So we dont fill where were trying to make space
		
		while await resultTracker.bestScore == -255 && tryingChoiceIndex <= info.choiceAmount && !info.maxTimeExceeded() {
			await withTaskGroup(of: Void.self) { group in
				let capturedSelf = self
				let newLocalInfo = ShuffleInformation(from: info, modifiedDepth: currentDepth + additionalLevelCounter) //New info object with modified maxSearchDepth to not directly run loose but in increasing steps look deeper when needed
				
				for student in self[categoryIndex].shuffled() {
					
					let nextCategoryIndex = student.categoryFromChoice[tryingChoiceIndex]!
					
					guard nextCategoryIndex != categoryIndex else {return} //Exclude self
					guard !updatedPath.contains(nextCategoryIndex) else {return} //Dont create a problem where we already solved it so dont try to fill a slot where we already had to vacate one
					
					group.addTask {
						var newArr = capturedSelf
						
						let forceResult = await newArr.forcefullyMoveStudent(student, from: categoryIndex, to: nextCategoryIndex, path: updatedPath, info: newLocalInfo, currentDepth: currentDepth)
						guard forceResult.possible else {return}
						
						await resultTracker.submit(score: forceResult.scoreDelta, with: newArr)
					}
				}
			}
			
			if currentDepth+additionalLevelCounter < info.maxSearchDepth {
				additionalLevelCounter += 1
			} else {
				tryingChoiceIndex += 1
				additionalLevelCounter = 0
			}
		}
		
		let bestHappynessScoreDelta = await resultTracker.bestScore
		let bestArr = await resultTracker.bestArr
		
		//If no change was possible, return 0
		guard bestHappynessScoreDelta != -255 else {
			let returnValue: (possible: Bool, scoreDelta: Double) = (false, 0)
			nicePrint("exited forcefullyFreeUpSlot() at Level \(currentDepth) after \(-localStartTime.timeIntervalSinceNow)s with return \(returnValue)", do: info.debugMode, level: currentDepth)
			return returnValue
		}
		
		let returnValue = (true, bestHappynessScoreDelta)
		self = bestArr
		nicePrint("exited forcefullyFreeUpSlot() at Level \(currentDepth) after \(-localStartTime.timeIntervalSinceNow)s with return \(returnValue)", do: info.debugMode, level: currentDepth)
		return returnValue
	}
	
	
	
	//MARK: Forcefully fill up a slot
	///By trying to move every possible student and finding the option with the highest happyness score
	nonisolated mutating fileprivate func forcefullyFillSlot(at categoryIndex: Int, info: ShuffleInformation, currentDepth: Int = 1) async -> (possible: Bool, scoreDelta: Double) {
		guard currentDepth < info.maxSearchDepth && !info.maxTimeExceeded() else {return (false, 0)}
		
		let localStartTime: Date = .now
		let resultTracker = MultiResultTracker(initialScore: -255, initialArr: self)
		
		await withTaskGroup(of: Void.self) { group in
			let capturedSelf = self
			
			for category in self.enumerated() {
				guard category.offset != categoryIndex else {return} //Exclude self
				
				for student in category.element.filter({$0.categoryFromChoice.contains(where: {$0.value == categoryIndex})}).shuffled() { group.addTask {
					var newArr = capturedSelf
					
					let forceResult = await newArr.forcefullyMoveStudent(student, from: category.offset, to: categoryIndex, path: [categoryIndex], info: info, currentDepth: currentDepth)
					guard forceResult.possible else {return}
					
					await resultTracker.submit(score: forceResult.scoreDelta, with: newArr)
				} }
			}
		}
		
		let bestHappynessScoreDelta = await resultTracker.bestScore
		let bestArr = await resultTracker.bestArr
		
		//If no change was possible, return 0
		guard bestHappynessScoreDelta != -255 else {
			let returnValue: (possible: Bool, scoreDelta: Double) = (false, 0)
			nicePrint("exited forcefullyFillSlot() at Level \(currentDepth) after \(-localStartTime.timeIntervalSinceNow)s with return \(returnValue)", do: info.debugMode, level: currentDepth)
			return returnValue
		}
		
		let returnValue = (true, bestHappynessScoreDelta)
		self = bestArr
		nicePrint("exited forcefullyFillSlot() at Level \(currentDepth) after \(-localStartTime.timeIntervalSinceNow)s with return \(returnValue)", do: info.debugMode, level: currentDepth)
		return returnValue
	}
	
	//MARK: Check for improvements
	//
	nonisolated mutating fileprivate func checkForImprovements(info: ShuffleInformation, currentDepth: Int = 1) async -> (possible: Bool, scoreDelta: Double) {
		let localStartTime: Date = .now
		var improvementsPossible = true
		var anyImprovementsDone = false
		var totalHappynessScoreDelta: Double = 0
		var additionalLevelCounter = 0
		
		//var changelog: [Int] //note down what movements happened to check if something may now be possible that wasnt possible before (At each index show what student count delta has bee achieved at that category index)
		
		while improvementsPossible || currentDepth+additionalLevelCounter <= info.maxSearchDepth {
			improvementsPossible = false
			
			let resultTracker = MultiResultTracker(initialScore: 0, initialArr: self)
			
			await withTaskGroup(of: Void.self) { group in
				let capturedSelf = self
				let newLocalInfo = ShuffleInformation(from: info, modifiedDepth: currentDepth + additionalLevelCounter) //New info object with modified maxSearchDepth to not directly run loose but in increasing steps look deeper when needed
				
				for category in self.enumerated() { for student in category.element.shuffled() {
					for choice in student.categoryFromChoice {
						
						guard choice.value != category.offset else {return} //Exclude trying to move to self
						guard choice.key < student.choiceFromCategory[category.offset]! else {return} //Exclude option that would move the student to a worse choice, movement to worse choices is already handled :)
						
						group.addTask {
							var newArr = capturedSelf
							
							let forceResult = await newArr.forcefullyMoveStudent(student, from: category.offset, to: choice.value, info: newLocalInfo, currentDepth: currentDepth)
							guard forceResult.possible else {return}
							
							await resultTracker.submit(score: forceResult.scoreDelta, with: newArr)
						}
					}
				} }
			}
			
			additionalLevelCounter += 1
			
			let bestHappynessScoreDelta = await resultTracker.bestScore
			let bestArr = await resultTracker.bestArr
			
			if bestHappynessScoreDelta != 0 {
				improvementsPossible = true
				anyImprovementsDone = true
				totalHappynessScoreDelta += bestHappynessScoreDelta
				self = bestArr
			}
		}
		
		let returnValue = (anyImprovementsDone, totalHappynessScoreDelta)
		nicePrint("exited checkForImprovements() at Level \(currentDepth) after \(-localStartTime.timeIntervalSinceNow)s with return \(returnValue)", do: info.debugMode, level: currentDepth)
		return returnValue
	}
}
	
	
	
//MARK: MAIN GENERATE FUNCTION

extension Allocation {
	func generate(from session: Session, into modelContext: ModelContext, with happynessFunction: HappynessFunction, progress: AsyncProgress) async {
		
		//Time management
		let startTime: Date = .now
		func timeSinceStart() -> TimeInterval {return -startTime.timeIntervalSinceNow}
		
		nicePrint("Task started", level: 0)
		document("", timeSinceStart(), .stageSeperator, into: modelContext, "Automatische Zuteilung begonnen")
		
		func maxTimeExceeded() -> Bool {
			if allowDymanicTime && !documentation.contains(where: {$0.type == .error}) {
				maxTime = timeSinceStart() + 5
				return false
			} else {
				return timeSinceStart() > maxTime
			}
		}
		func documentTimeExceed(at stepCode: String) {
			document(stepCode, timeSinceStart(), .exitError, into: modelContext, "Maximale Laufzeit ohne Anzeichen einer unmöglichen Zuteilung überschritten (\(timeSinceStart().rounded())s). Versuchen sie die Kapazitäten zu erhöhen oder geben sie den Schüler*innen allenfalls mehr Wahlmöglichkeiten.")
		}
		
		//Starting
		progress.currentStep = "Daten kopieren"
		var mainCategoryArr: [[AllocatedStudentDummy]] = [] ///This array makes handling students and modifying copies easier because no object duplication is required
		
		///The following arrays are duplicates of the data in each AllocatedCategory object but are the ones actually respected by the algorithm. they are sometimes also changed in the process to for example empty a category by setting its capacity to 0 because it couldnt be filled.
		var capacities: [Int] = []
		var minMembers: [Int] = []
		
		//MARK: Copying data
		
		mainCategoryArr.insert([], at: 0) //At index 0 are the unallocated students
		capacities.insert(0, at: 0)
		minMembers.insert(0, at: 0)
		
		///Small helper function to generate the helper object for all the helper functions
		func infoObject() -> ShuffleInformation {
			ShuffleInformation(choiceAmount: choiceAmount, capacities: capacities, minMembers: minMembers, maxSearchDepth: maxSearchDepth, startTime: startTime, maxTime: maxTime, allowDymanicTime: allowDymanicTime, debugMode: debugMode)
		}
		
		//Copying categories
		var categoryIndexCounter = 1
		
		for category in session.categories.indexSorted() {
			if let newInstance = AllocatedCategory(from: category) {
				
				///Not following to the last category with number n+1
				if newInstance.index != categoryIndexCounter {
					document("Copying data/Copying categories", timeSinceStart(), .exitError, into: modelContext, "Die Nummer von \"\(category.name)\" folgt nicht um +1 der davor. Die Nummern der Kategorien müssen einer anderen aus technischen Gründen (Integer as Array Index) um jeweils +1 folgen.")
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
				///No number given
				if category.number == nil {
					document("Copying data/Copying categories", timeSinceStart(), .exitError, into: modelContext, "\"\(category.name)\" konnte nicht übernommen werden: keine Nummer gegeben")
				}
				///No Capacity given
				if category.capacity == nil {
					document("Copying data/Copying categories", timeSinceStart(), .exitError, into: modelContext, "\"\(category.name)\" konnte nicht übernommen werden: keine Kapazität gegeben")
				}
				///No min. Member count given
				if category.minParticipantRequirement == nil {
					document("Copying data/Copying categories", timeSinceStart(), .exitError, into: modelContext, "\"\(category.name)\" konnte nicht übernommen werden: keine Mindestanzahl für Teilnehmer gegeben")
				}
			}
		}
		
		//Copying students (into mainCategoryArr[0])
		var studentDummyByName: [String:AllocatedStudentDummy] = [:]
		var studentsWithValidPartners: [Student] = []
		
		for student in session.students {
			var invalid = false
			var invalidPartner = false
			
			//Choice validity
			for choice in student.choices {
				/// Is a choice given?
				if choice.value == nil && choice.key <= choiceAmount {
					document("Copying data/Copying students", timeSinceStart(), .destructiveAction, into: modelContext, "\(student.name) Hat als \(choice.key). Wahl nichts angegeben und wird ab jetzt nicht mehr berücksichtigt.")
					invalid = true
				///Is it a valid choice?
				}else if !categories.contains(where: {$0.index == choice.value}) && choice.key <= choiceAmount {
					document("Copying data/Copying students", timeSinceStart(), .destructiveAction, into: modelContext, "\(student.name) Hat als \(choice.key). Wahl eine Kategorie angegeben, die es nicht gibt und wird ab jetzt nicht mehr berücksichtigt.")
					invalid = true
				}
			}
			
			//Is the given mandatory partner valid?
			if allowForMandatoryPartners && student.mandatoryPartner != "" && !invalid {
				if let partner = session.students.first(where: {$0.name == student.mandatoryPartner}) {
					if partner.choices.truncated(toLength: choiceAmount) != student.choices.truncated(toLength: choiceAmount) { ///The .truncated() function sorts (SwiftData sometimes shuffles the key-value pairs in the array) and shortens the dictionary to only the used choices so that this check does not return true even tho they are "identical"
						///Not the same choices
						document("Copying data/Copying students", timeSinceStart(), .destructiveAction, into: modelContext, "\(student.name) und \(partner.name) haben nicht identisch gewählt und werden nicht als Partner*innen berücksichtigt.")
						invalidPartner = true
					} else if partner.mandatoryPartner != student.name {
						///Not chosen as partner in both directions
						document("Copying data/Copying students", timeSinceStart(), .destructiveAction, into: modelContext, "\(student.name) und \(partner.name) haben sich nicht gegenseitig als Partner*innen gewählt und werden deshalb nicht als solche berücksichtigt.")
						invalidPartner = true
					}
				} else {
					///Partner not found
					document("Copying data/Copying students", timeSinceStart(), .destructiveAction, into: modelContext, "\(student.name) Hat als zwingender Partner eine Person*innen angegeben, die nicht gefunden wurde.")
					invalidPartner = true
				}
			}
			
			///Create AllocatedStudentDummy instance and insert
			if !invalid {
				let newInstance: AllocatedStudentDummy
				do {
					newInstance = try AllocatedStudentDummy(from: student, happynessFunction: happynessFunction, choiceAmount: choiceAmount)
				} catch {
					document("Copying data/Copying students", timeSinceStart(), .exitError, into: modelContext, "Error mit der Glücklichkeitsfunktion (LUA Error): \(error.localizedDescription)"); return
				}
				mainCategoryArr[0].append(newInstance)
				studentDummyByName[newInstance.name] = newInstance
				
				if !invalidPartner { studentsWithValidPartners.append(student) }
			} else {
				//If invalid, directly bypass the algorithm and go into unAllocatedStudents as AllocatedStudent instance
				let newInstance = AllocatedStudent(from: student, choiceAmount: choiceAmount)
				modelContext.insert(newInstance)
				unAllocatedStudents.addAtEnd(newInstance)
			}
		}
		
		//Linking partners
		for student in studentsWithValidPartners {
			studentDummyByName[student.name]?.mandatoryPartner = studentDummyByName[student.mandatoryPartner]
		}
		
		//Checking if there is enough capacity in total
		var totalCapacity: Int = 0
		for category in categories {
			totalCapacity += category.capacity
		}
		if mainCategoryArr[0].count > totalCapacity {
			document("1.5", timeSinceStart(), .exitError, into: modelContext, "Es ist gesamt nicht genügend Kapazität gegeben")
			return
		}
		
		//Assigning everyone to first choice
		let unassigned = mainCategoryArr[0]
		mainCategoryArr[0] = []
		for student in unassigned {
			let newCategoryIndex = student.categoryFromChoice[1]!
			mainCategoryArr[newCategoryIndex].append(student)
		}
		
		//MARK: Core loops
		//Juggling students around
		nicePrint("arrived at core loops at \(timeSinceStart())", level: 0)
		
		///I'm sorry for the indentation you're about to witness **(^-^)
		var overshootFinished: Bool = false
		var undershootFinished: Bool = false
		
		while !overshootFinished || !undershootFinished { //Main loop
			progress.currentStep = "Zuteilung generieren"
			
			//Handling overshoot (More students than capacity)
			while !overshootFinished { overshootFinished = true; for categoryIndex in 1...mainCategoryArr.count-1 { //Overshoot loop
				let category = mainCategoryArr[categoryIndex]
				let capacity = capacities[categoryIndex]
				
				if category.count > capacity {
					overshootFinished = false
					if await !mainCategoryArr.forcefullyFreeUpSlot(at: categoryIndex, info: infoObject()).possible {
						document("Core loops/Handling overshoot", timeSinceStart(), .error, into: modelContext, "Kategorie \(categoryIndex) Hat zu viele Teilnehmer (\(category.count)/\(capacity)) von denen niemand bewegt werden kann.")
					}
				}
				
				//Safeguard for impossible allocations
				if maxTimeExceeded() {overshootFinished = true; undershootFinished = true; documentTimeExceed(at: "Core loops/Handling overshoot"); return}
				
			} } //END < for categoryIndex in 1...mainCategoryArr.count-1 > //END Overshoot loop
			
			//Handling undershoot (Less students than required)
			while !undershootFinished && overshootFinished { undershootFinished = true; for category in self.categories { ///Undershoot loop
				if mainCategoryArr[category.index].count < category.minParticipants { switch studentBalancing {
					
				case .deleteCategoriesWithNotEnoughMembers:
					if capacities[category.index] != 0 {
						capacities[category.index] = 0
						document("Core loops/Handling undershoot", timeSinceStart(), .error, into: modelContext, "\(category.name) hat nicht genügend Teilnehmer; Teilnehmer werden nun anders verteilt.")
						overshootFinished = false //So that the overshoot loop is triggered again
					}
					
				case .tryToFillCategoriesWithNotEnoughMembers:
					undershootFinished = false
					if await !mainCategoryArr.forcefullyFillSlot(at: category.index, info: infoObject()).possible {
						document("Core loops/Handling undershoot", timeSinceStart(), .error, into: modelContext, "\(category.name) hat nicht genügend Teilnehmer und lässt sich mit niemandem füllen.")
					}
					overshootFinished = false //So that the overshoot loop is triggered again
				} }
				
				//Safeguard for impossible allocations
				if maxTimeExceeded() {overshootFinished = true; undershootFinished = true; documentTimeExceed(at: "Core loops/Handlung undershoot"); return}
				
			} } //END < for category in categories > //END Undershoot loop
			
			//Checking for possible improvements
			progress.currentStep = "Fertige Zuteilung überprüfen"
			if await mainCategoryArr.checkForImprovements(info: infoObject()).possible {
				overshootFinished = false; undershootFinished = false
			}
			
			//Safeguard for impossible allocations
			if maxTimeExceeded() {overshootFinished = true; undershootFinished = true; documentTimeExceed(at: "Core loops"); return}
			
		} //END Main loop
		
		//MARK: Finish
		
		progress.currentStep = "Fertige Daten übertragen"
		nicePrint("exited core loops at \(timeSinceStart())", level: 0)
		
		//Append all students from the mainCategoryArr to the actual category classes and other finishing touches
		let totalHappynessScore = totalHappynessScore(of: mainCategoryArr)
		var studentCounter = 0
		
		///Part of this is also repairing all index values because they havent really been respected because of the duplicate arrays and stuff
		for category in categories {
			for student in mainCategoryArr[category.index] {
				let newInstance = AllocatedStudent(from: student)
				modelContext.insert(newInstance)
				category.students.addAtEnd(newInstance)
				studentCounter += 1
			}
		}
		
		//Happyness score
		happynessScore = totalHappynessScore/Double(studentCounter)
		
		//Making the happynessFunction snapshot
		let newHappynessFunctionSnapshot = HappynessFunctionSnapshot(happynessFunction)
		modelContext.insert(newHappynessFunctionSnapshot)
		happynessFunctionSnapshot = newHappynessFunctionSnapshot
		
		if documentation.last?.type != .exitError {
			document("", timeSinceStart(), .stageSeperator, into: modelContext, "Automatische Zuteilung erfolgreich beendet")
		}
		
		progress.currentStep = "Fertig!"
		nicePrint("exited generate() function after \(timeSinceStart())s", level: 0)
		generationDuration = timeSinceStart()
	}
}
