#	BSA2 1.1.0 (Build 3)
###	Dominik Stücheli, 23. Juni 2026

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/dominikstuecheli-105D-Engineering/BetterSlotAssign2/blob/main/BSA2/105DLogo.png?raw=true">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/dominikstuecheli-105D-Engineering/BetterSlotAssign2/blob/main/BSA2/105DLogoBright.png?raw=true">
  <img alt="Fallback image description" src="https://github.com/dominikstuecheli-105D-Engineering/BetterSlotAssign2/blob/main/BSA2/105DLogo.png?raw=true">
</picture>

**Hauptveränderungen**
- Performance: Weitere Verbesserungen im Kernalgorithmus - Zuteilungen dauern selten mehrere Sekunden. Dadurch konnte die standartmässige Suchtiefe auf 10 gesetzt werden, da der Algorithmus nur selten wirklich davon gebrauch machen muss.
- Performance: Verbesserungen im Name-matching Algorithmus (~10x schneller) durch Caching bereits berechneter Ähnlichkeitswerten und früheren Abbrüchen bei zu grossen Diskrepanzen von String- oder Subtringlängen
- Performance: Ruckellosere Tabellenansichten durch seperate Metal-gerenderte (SwiftUI Canvas) Tabellenlinien und Auslagerung des FocusState in ein Singleton statt der ContentView(), um View-rebuilding zu minimieren
- Zusätzliche Möglichkeit zum Akzeptieren von Vorschlägen direkt in der Zelle durch einen zusätzlichen Haken-Knopf

**Nebenveränderungen**
- Fortschrittswert bei der Zuteilungsgeneration entfernt, da er nicht aussagekräftig und allgemein inkorrekt war
- Man kann in der Kategorienliste die letzte Kategorie nicht mehr löschen, wenn nur noch eine in der Liste ist, da man sonst keine mehr hinzufügen könnte (Schreibfehler im Code)
