//
//	Student Conditions.swift
//  BSA2
//
//  Created by Dominik Stücheli on 09.04.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



extension Student {
	
	//MARK: NAME
	func nameConditon(in session: Session) -> ConditionReturn {
		//Name not given
		if name == "" {return .invalid(errorText: "Es muss ein Name gegeben sein")}
		
		//There is already another student with the same name
		if let other = session.students.first(where: {$0.name == name && $0.id != id}) {
			let updateGroup = mergeUpdateGroups(
				[CellIndex(item: other, row: 1)], //The other students name cell to also mark as identical
				BSA2.updateGroup(row: session.studentTableRowCount(), lineCount: session.students.count) //Whole last row in case name changes mess with the mandatory partner stuff
			)
			
			return .validButNotAllowed(errorText: "Es gibt bereits eine Person mit diesem Namen", updateGroup: updateGroup)
		}
		//Everything ok
		let updateGroup = BSA2.updateGroup(row: session.studentTableRowCount(), lineCount: session.students.count) //Even tho the name is ok, changing the names may interfere with the whole mandatory partner thing so check that again anyways
		
		return .met(updateGroup: updateGroup)
	}
	
	//MARK: CHOICES
	func choiceCondition(index i: Int, value: Int, session: Session) -> ConditionReturn {
		//Category doesnt exist
		if !session.categories.contains(where: {$0.number == value}) {
			return .validButNotAllowed(errorText: "Es existiert keine Kategorie mit dieser Nummer", updateGroup: [])
		}
		
		//Check if the partner exists to already add to the update group
		var partner: Student? = nil
		var partnerChoiceCellUpdateGroup: [CellIndex] = []
		if let foundPartner = session.students.first(where: {$0.name == mandatoryPartner && $0.name != ""}) {
			partner = foundPartner
			partnerChoiceCellUpdateGroup = [CellIndex(item: foundPartner, row: i+1)]
		}
		
		//Cannot choose the same category twice
		if choices.contains(where: {$1 == value && $0 != i}) {
			let updateGroup = updateGroup(startCell: 2, cellCount: session.choiceAmount, line: self.index)
			
			return .validButNotAllowed(errorText: "Diese Person hat diese Kategorie schon einmal gewählt", updateGroup: mergeUpdateGroups(updateGroup, partnerChoiceCellUpdateGroup))
		}
		
		//If student has mandatory Partner, additional conditions apply
		if let partner {
			if partner.choices[i] != choices[i] && session.allowForMandatoryPartners {
				return .validButNotAllowed(errorText: "Zwingende Partner müssen identisch wählen", updateGroup: [CellIndex(item: partner, row: i+1)])
			}
		}
		
		//Everything ok
		return .met()
	}
	
	//MARK: MANDATORY PARTNER
	func mandatoryPartnerCondition(session: Session) -> ConditionReturn {
		guard mandatoryPartner != "" else {return .met()}
		
		//Chose themselves
		if mandatoryPartner == name {
			return .validButNotAllowed(errorText: "Der eigene Name ist hier nicht erlaubt", updateGroup: [])
		}
		
		//Chose someone who doesnt exist
		guard let wantedPartner = session.students.first(where: {$0.name == mandatoryPartner}) else {
			let updateGroup = BSA2.updateGroup(row: session.studentTableRowCount(), lineCount: session.students.count) //Update all mandatory partner fields
			
			return .validButNotAllowed(errorText: "Es existiert keine andere Person mit diesem Namen", updateGroup: updateGroup)
		}
		
		//The other person did not choose this person back
		if wantedPartner.mandatoryPartner != name {
			let updateGroup = BSA2.updateGroup(row: session.studentTableRowCount(), lineCount: session.students.count) //Update all mandatory partner fields
			
			return .conflictOfInterest(errorText: "\(wantedPartner.name) und \(name) haben sich nicht gegenseitig als Partner*innen eingetragen", updateGroup: updateGroup)
		}
		
		//Everything ok
		return .met()
	}
}



@MainActor extension Session {
	///The function that provides the CellConditionHosts for every cell to the ErrorCollector
	func provideCellConditionHostsForStudentTableToErrorCollector() { //Very compact function name I know
		ErrorCollector.setup({ [self] in
			
			var cellConditionHosts: [CellIndex:any CellConditionHost] = [:]
			
			for student in students {
				
				cellConditionHosts[CellIndex(item: student, row: 1)] = TextCellConditionHost(getValue: {return student.name}, update: {_ in student.nameConditon(in: self)})
				
				for choiceIndex in 1...choiceAmount {
					cellConditionHosts[CellIndex(item: student, row: 1+choiceIndex)] = IntegerCellConditionHost(getValue: {
						if student.choices[choiceIndex] == nil { student.choices[choiceIndex] = nil } //Making sure an entry with that index exists in the dictionary
						return student.choices[choiceIndex] ?? nil
					}, update: { input in student.choiceCondition(index: choiceIndex, value: input, session: self)})
				}
				
				if allowForMandatoryPartners {
					cellConditionHosts[CellIndex(item: student, row: studentTableRowCount())] = TextCellConditionHost(getValue: {return student.mandatoryPartner}, update: {_ in student.mandatoryPartnerCondition(session: self)})
				}
			}
			
			return cellConditionHosts
		})
	}
}
