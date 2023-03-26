# 0.8.1

## Compiled files altered

- DenpaEngine.exe
- assets/images/alphabet.png
- assets/images/alphabet.xml

## Changelog

### Additions

- The Time Bar now has its own entering animation for normal and pixel stages.

- Alphabet now supports the characters `¿`, `¡`, and `ñ`.

### Improvements

- Windows Builds now utilize DPI Awareness for higher fidelity visuals on resolutions greater than 1280x720.

### Fixes

- Freeplay vocals can no longer persist into PlayState.

- Icon animations now all respect `gfSpeed`.

- Ghost Tapping animations now consider whether the current section is a `gfSection`.

- FlxBars no longer have choppy filling due to a rounding error.

- FlxBars no longer incorrectly floor their percentage `Float` and now have a `roundedPercentage` value for the floored version.

- Strums are now perfectly centered.

- The Bold `(`, `)`, and `.` characters are no longer improperly offset when using the Alphabet class.

- The Duet and Mirror Section buttons in the Charter now work properly on all key amounts.

- Mod Maps now properly refresh where they should be.

- Note splashes are no longer spawned in `popUpScore()` and will spawn if ratings are disabled for the note, but not notesplashes.

- `popUpScore()` is no longer run when a note has its ratings disabled.

### Optimizations

- Note Spawning now `shift()`s instead of `splice()`ing.

- Philly Glow Particles are now `recycle()`ed instead of recreated whenever a new one is needed.

- Modifier indicators are now made with much more compact code that only adds the sprites if needed.

- The majoroity of objects are now properly `remove()`ed and `destroy()`ed instead of `kill()`ed and `destroy()`ed, as `kill()`ing does nothing since it is immediately destroyed.

- Text made using the Alphabet class now loads characters on demand, rather than loading a huge sprite sheet, which saves on RAM usage.

- Crossfades are now `recycle()`ed rather than being made anew whenever one is needed.

- The Discouragement Elevator track, and the bfBeep, scrollMenu, confirmMenu, and cancelMenu sound effects are no longer cleared from the cache, allowing for faster load times on the Manual, as well as not needing to reload the basic menu sounds every time you swap states.

- Icons no longer load their graphic twice when changing icons.

### Removals

- N/A
