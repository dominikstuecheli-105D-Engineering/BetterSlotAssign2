#	BSA2 2.0.0 (Build 4): Das LUA Scripting Update!
###	Dominik Stücheli, XXXXX
![](https://github.com/dominikstuecheli-105D-Engineering/BetterSlotAssign2/blob/main/BSA2/105DLogo.png?raw=true)
**Hauptveränderung: LUA-Scripting**
- Die Glücklichkeitsfunktionen sind nun nicht mehr fix in Swift gecodete Funktionen sondern in LUA geschriebene Funktionen, welche dann durch die eigebettete LUA C-API (LuaSwift von tomsci) bei Runtime compiled werden. **Dies bedeutet, dass der/die NutzerIn auch eigene Glücklichkeitsfunktionen schreiben kann.**
- Um Glücklichkeitsfunktionen bearbeiten und testen zu können gibt es nun ein eigenes "Lua-Scripting" Fenster, in dem LUA-Code bearbeitet (CodeEditor von ZeeZide) und mit verschiedenen Funktionsargumenten getestet werden kann.
- Die LUA-Glücklichkeitsfunktionen sind SchülerInnen-spezifisch, das heisst sie bekommen sämtliche Daten aller SchülerInnen und werden pro SchülerIn einzeln ausgewertet. Dies erlaubt zusätzliche Flexibilität.

- **Warum LUA?**
	- LUA ist meines Wissens die einzige Programmiersprache die embeddable ist.
	- Es gibt eine gut ausgebaute Swift API.
	- LUA ist eine ausserordentlich einfach zu lernende Sprache, vor allem für eine solch simple Anwendung (Kein OOP, keine concurrency etc.). Sie ist weit verbreitet, es gibt also dementsprechend viele Lernmaterialen und die Dokumentation ist gut.
	- LUA Baut auf C, ist also schnell.

*Für weitere und spezifischere Details zum LUA-Scripting sehen Sie die Informationen im "LUA-Scripting" Fenster an.*

**Andere Hauptveränderungen**
- Such-/Filterfelder für alle Tabellenansichten
- Dokumentationseinträge des Zuteilungsalgorithmus werden nicht mehr mit einer Nummer sondern mit Namen der "Bereiche" Unterteilt. Dies macht es einfacher, neue mögliche Einträge hinzuzufügen ohne die Identifikationsnummern aller anderen zu ändern, was ein Nummernsystem etwas Sinnlos machen würde.

**Nebenveränderungen**
- Performance: SchülerInnen werden nun in einem @Transient dictionary im Session Objekt per Name indexiert, um sie schneller per Name zu finden, zB. wenn man zwingende PartnerInnen sucht.
- Veränderungen im Reinigungsprozess des NameSimilarityCache: Es wird nicht ein DispatchWorkItem in dem eine Funktion die eine Task erstellt erstellt, sondern direkt ein DispatchWorkItem erstellt.
- Performance: Sämtliche classes sind nun mit "final" markiert, um dynamic dispatch zu reduzieren.
- Alle Dependencies sind neu SPM-Dependencies und nicht einfach zusätzliche Ordner in der Codebase
- Ein neues README.md auf Github
- 105D-Logos: für die Releasenotes (Rückwirkend auf alle Versionen, aber leider nur sichtbar wenn man die Releasenotes auf zB. Github anschaut. Sparkle rendert die Bilder im Markdown nicht.), im README und unten links in der App als Banner

- Durch LUA-Scripting hinzugefügte Package Dependencies:
	- LuaSwift (tomsci): [github.com/tomsci/LuaSwift](https://github.com/tomsci/LuaSwift)
	- CodeEditor (Zeezide): [github.com/ZeeZide/CodeEditor](https://github.com/ZeeZide/CodeEditor)
