Stichwörter
===========

_Notice: The app is currently only localized in German._

Ein Stichwortverzeichnis für ein Buch zu erstellen ist sowohl einfach als auch langweilig: Es ist eine Liste von Wörtern und den Seitenzahlen, auf denen sie auftauchen. Dabei muss man immer beachten, dass jedes Wort nur einmal in der Liste ist (mit mehreren Seitenzahlen). Dieses Tool vereinfacht das ganze etwas. Man gibt einfach ein Wort und die Seitenzahl ein, und das Programm erledigt den Rest.

Tricks
------

Die meiste Zeit sollte man das Tool nur mit der Tastatur bedienen können:

*	Wort eingeben
*	Eintragen mit Return. Die eingestellte Seite bleibt gleich.
*	Wiederholen
*	Mit Befehl-Alt-N wird der Seitenzähler um eins erhöht.

Man kann die Einträge hinterher in der Liste bearbeiten. Wenn sich die Seitenzahlen einer großen Sektion gleichförmig geändert haben, kann man auch über Bearbeiten/Seitenzahlen verschieben alle Seitenzahlen des Bereiches ändern.

Auch Quicklook und Spotlight werden für die erstellten Dateien unterstützt.

Export
------

Das Tool kann die Dateien als Word oder HTML-Dateien exportieren, und hier wahlweise als Liste oder, meist sinnvoller, als Verzeichnis. Beim Verzeichnis wird das Datum der einzelnen Einträge nicht mit gespeichert.

Entwicklung
-----------

Das Tool verwendet das Mac OS X 10.6 SDK, welches standardmäßig nicht in Xcode 4.4 (Mountain Lion) oder höher enthalten ist. Man kann Xcode 4.3 über das Mac Developer Center herunterladen und dass SDK daraus verwenden, oder alternativ das Projekt auf 10.7 oder 10.8 upgraden.