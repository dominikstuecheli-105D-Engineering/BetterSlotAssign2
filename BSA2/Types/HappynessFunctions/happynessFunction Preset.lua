--Created by Dominik Stücheli on 17.07.2026
--/\ Autor und Datum hier notieren /\


--INPUTS/FUNCTION ARGUMENTS

--das student Argument ist ein table, welcher wie folgt formattiert ist:
--  {
--    "name" = String,
--		"gender" = String, (Geschlechtsfeld)
--		"group" = String, (Gruppen/Klassenfeld)
--		"profile" = String, (Profilfeld)
--		"choices" = {Integer} (Table), (Der Integer ist die Nummer der gewählten Kategorie und der Index in welcher Wahl diese gewählt wurde, also erste, zweite usw.)
--		"mandatoryPartner" = String,
--  }

--inChoice ist ein Integer, welcher aussagt, in welcher Wahl der/die Schüler*in sich befindet (respektive für welche Wahl der Glücklichkeitswert berechnet werden sollte, wird ja nachher gecacht), also erste, zweite usw.

--choiceAmount ist ein Integer, welcher besagt, wie oft die Schüler*innen ihre Kategorien wählen konnten


--OUTPUT/RETURN

--Der return sollte eine Zahl zwischen 0 und 1 sein, wobei 1 maximal glücklich und 0 maximal unglücklich entspricht. Der Algorithmus strebt nach der maximalen Glücklichkeitssumme aller Schüler*innen.


--KOMMENTAR ZU CACHING

--Die function wird am Anfang des Zuteilungsprozesses einmal für alle Schüler*innen einzeln choiceAmount mal ausgeführt und das Resultat gespeichert, welches danach zum Vergleich abgerufen wird. Das LUA-Script muss also nicht wahnsinnig optimiert sein.


--Löschen sie diese function nicht! Wenn keine function namens happynessFunction existiert, kann das Skript nicht ausgeführt werden (error: LuaValueError.nilValue).
function happynessFunction(student, inChoice, choiceAmount)
  value = 1
  return value
end
