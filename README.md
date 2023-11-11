![Supported Platforms](https://img.shields.io/badge/supported%20platforms-windows%2C%20linux-blue)
![GitHub Commits Since Latest (By Date)](https://img.shields.io/github/commits-since/UmbratheUmbreon/PublicDenpaEngine/latest)
[![Repo Size](https://img.shields.io/github/repo-size/UmbratheUmbreon/PublicDenpaEngine)](https://github.com/UmbratheUmbreon/PublicDenpaEngine)
[![GitHub Issues](https://img.shields.io/github/issues/UmbratheUmbreon/PublicDenpaEngine)](https://github.com/UmbratheUmbreon/PublicDenpaEngine/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/UmbratheUmbreon/PublicDenpaEngine)](https://github.com/UmbratheUmbreon/PublicDenpaEngine/pulls)
![GitHub All Downloads](https://img.shields.io/github/downloads/UmbratheUmbreon/PublicDenpaEngine/total)
![GitHub Latest (Including Pre-releases)](https://img.shields.io/github/v/release/UmbratheUmbreon/PublicDenpaEngine?include_prereleases&label=latest%20version)
[![Discord](https://img.shields.io/discord/993277169876873326?label=discord)](https://discord.gg/BFaMfmTNaa)

[![Star History Chart](https://api.star-history.com/svg?repos=UmbratheUmbreon/PublicDenpaEngine&type=Timeline)](https://star-history.com/#UmbratheUmbreon/PublicDenpaEngine&Timeline)

# Friday Night Funkin': "DENPA" Engine

## Synopsis

Denpa Engine is a Friday Night Funkin' engine created by the likes of BlueVapor1234, Toadette8394, YanniZ06, jorge, MemeHoovy, Ziad, and much much more. Being intended to enhance the user experience, improve game performance, and increase the capabilities and efficiency of mod making, Denpa Engine is the most feature ready FNF engine to date. With features ranging from HScript and Lua scripting, to fully fitted editors, the engine is ready to go right out of the box.

## Denpa Engine Team

![at](https://user-images.githubusercontent.com/101066547/221386616-ff55be43-b6d3-4315-96b0-0b6140afb873.png)

BlueVapor1234 - Main Programmer & Creator

![toadette](https://user-images.githubusercontent.com/101066547/221386629-e6b8cd50-a59e-4a3a-a439-5f906806a1c7.png)

Toadette8394 - Co Programmer

![yanniz06](https://user-images.githubusercontent.com/101066547/221386639-5a42d43c-69e0-4d4b-92b1-1d431d8c0c49.png)

YanniZ06 - Co Programmer

![thrift](https://user-images.githubusercontent.com/101066547/221387392-7e12b656-81e0-4700-891f-ac9a1dbd60c3.png)

ThriftySoles - Main Composer & Additional Artist

![kn1ght](https://user-images.githubusercontent.com/101066547/221386690-2e46cce9-da4a-4b2a-a89c-ae2c7c6eca5f.png)

Kn1ghtNight - Programmer & Artist

![tsan](https://user-images.githubusercontent.com/101066547/221386696-0473d2ce-f636-4dce-9cfc-df54d38f0e31.png)

T-San - Artist

![jorge](https://user-images.githubusercontent.com/101066547/221386704-72ab8afe-f5e5-4327-ac82-3064a9e486b5.png)

jorge - Base HaxeScript Support

![placeholder](https://user-images.githubusercontent.com/101066547/221386730-1c4b4fa3-b143-40a5-b304-dd71c8139afc.png)

Ziad - Multiplayer Support

![shygee](https://user-images.githubusercontent.com/101066547/221386726-7822788b-fa38-4b26-b0e3-0aac056198c6.png)

Shygee - Additional Programmer

## License Summary

### Permitted Actions

You are permitted to perform the following actions:

- Download and install this engine.

### Required Actions

You must obtain permission to perform the following actions:

- Redistribute the unmodified engine on a website other than GameBanana, Gamejolt, or Github.
- Use parts of this engine in another engine or mod and provide credit.

### Permitted Actions with Conditions

You are permitted to perform the following actions under the following conditions:

- Modify this engine and redistribute the modified engine on GameBanana, GameJolt, or GitHub, provided that you offer the same rights to others.

### Prohibited Actions

You are not allowed to perform the following actions under any circumstances:

- Use this engine or parts of this engine for commercial purposes.
- Use parts of this engine in another engine or mod without providing credit.
- Publicly distribute malicious or potentially harmful scripts that utilize this engine. 

### Additional Conditions

You agree to the following additional conditions:

- You will not modify this engine in any way that violates the license agreement.
- You will not distribute any modified versions of this engine that do not comply with the terms of this license agreement.

This license agreement is subject to change at any time, and continued use of the engine constitutes acceptance of any such changes.

## Installation

### Release Copies

1) Download the latest .7z/.zip archive from Gamebana, Gamejolt, or Github.
2) Extract the file by right clicking on it, using either the default OS tools, 7zip, or WinRAR to extract.
3) Run the DenpaEngine executable file in the extracted folder.

### Source Code

1) Download the latest source .zip/.gz file.
2) Extract the file using the default OS tools, 7zip, or WinRAR to extract.
3) Install Haxe 4.3.0 from <https://haxe.org>.
4) Run the QUICK SETUP.bat file to install the haxe libraries needed.
5) Install Visual Studio Community 2017/2019.
6) Open Visual Studio Installer.
7) Click Modify on your Visual Studio 2017/2019 install.
8) Click "Individual Components" at the top.
9) Install the "MSVC v142 - VS 2019 C++ x64/x86 build tools Latest" and "Windows SDK (10.0.17763.0)" components.
10) Run any of the batch files in the batch folder of the source code or continue to step 11.
11) Open command prompt and use the "cd" command to set the current directory to your source code folder.
12) Type "lime test [your platform here]" and the compile should start.

## Features (Unfinished List!)

### Anti-Crash Functionality

- The engine will not crash from most small critical errors, such as a missing chart .json or a .hscript error.
- JSONs are checked for in the charter, pause menu, freeplay menu, story menu, and when going to the next story song.

### Camera

- The camera is now smooth during gameplay.
- The camera speed can be altered at any time.
- The camera can be toggled to pan with the direction the characters are singing.

### Characters

- Characters can now be loaded using jsons instead of being hard coded.
- Playing as opponents no longer causes offset and animation errors.
- Characters can be set to float with different speeds and magnitudes.
- Characters can be set to have a trail/afterimage like Spirit with different properties.
- Characters can be set to drain health at a specific rate, and with a stopping point.
- Characters can be set to shake the screen, scare bf, and scare gf.
- Character icons can have their offsets set.
- Opponents automatically stop singing rather than stopping when the camera moves to the player.
- Characters can now have looping animations that automatically trigger (See week 4).
- Characters can be set to use the normal idle, or use the dance left and dance right type.
- Characters can be loaded from Sparrow, Packer, Texture, and Animate Atlases.
- Characters without miss animations now change colour and play their sing animation when missing.

### Character Select

- You can select a different playable character that carries over between songs via a submenu in freeplay.
- Characters are automatically loaded from mods with playable characters (such as characters with "-player" at the end of their name).
- You can preview the animations of the character by pressing the note keys.
- The character's icon is automatically loaded and displayed with their name.
- Selecting Boyfriend sets the game to the default player behaviour.

![charaselect](https://user-images.githubusercontent.com/101066547/222318982-bdb653b4-3873-41cc-8428-c7f2615aba46.gif)

### Credits Menu

- Contributors can be added to the credits menu using a simple txt file.
- Contributors can have custom icons and background colours.
- Contributors can have nicknames, roles, and quotes/descriptions displayed.
- Pressing enter will take you to the selected Contributor's social media if linked.
- A placeholder icon and colour will be loaded if an icon is not found.
- Catagories can be created to sort contributors by.

![credits](https://user-images.githubusercontent.com/101066547/222319005-5cc07a80-3582-444c-8620-87c4ab4a1844.gif)

### Crossfade

- When a crossfade section is enabled and a note is hit, an after image is generated.
- A notetype to trigger crossfade is also present.
- Different modes can be set for the crossfade (Default, Static, Subtle, Eccentric)
- Crossfades can be toggled off.
- The player's crossfade can be customized with alpha, colour, and fade time.
- Crossfades automatically take the colour of the character's healthbar.

![crossfade](https://user-images.githubusercontent.com/101066547/222319026-cff9d078-e117-4ce6-871e-e5873669efc5.gif)

### Character Editor (Formerly Animation Debug)

- Animation offsets can be edited and saved.
- There is a ghost character that can be set to any animation to reduce the amount of guesswork for offsets.
- Animations can be added, removed, and saved.
- Animations can be set to loop, with a specific loop point.
- Animations can optionally have indices to fine tune frame order.
- Xml prefixes are automatically added to a dropdown to make it simpler and easier to set up an animation.
- Character starting and camera positions can be edited and saved.
- Character's singing duration multiplier, scale, and antialiasing can all be edited and saved.
- The camera can optionally automatically pan to the location it will appear in game when you change the camera offset.
- Character animation offsets and camera offsets can optionally be dragged with the left and right mouse buttons.
- Character health bar colors can be edited and saved.
- The dominant color of the icon can be grabbed to set as the health bar color.
- There is an eyedropper to set the color of the health bar.
- You can set and save the game over properties of the character.
- You can toggle floating, and set the magnitude and speed.
- You can turn on and customize a trail for the character.
- You can turn on health drain and set the amount and stopping point.
- You can turn on screen shaking, as well as whether to scare bf/gf.
- You can set and save the icon antialiasing.
- You can add and edit icon offsets.
- You can toggle between the different icon states.
- You can swap between different backgrounds to help with offsets (including mod backgrounds)

![chara](https://user-images.githubusercontent.com/101066547/222319040-84b497bc-ea04-421a-89fb-1ac5273af260.gif)

### Chart Editor

- There are now keybinds for most actions (Copying, Cutting, Pasting, and Deleting sections, in addition to Saving)
- Performance is significantly better overall, and the editor does not become exponentially slower with more notes.
- The background colour changes depending on which character is on the left side.
- You can start playing directly at the current section or at the beginning.
- There are prompts before potentially unwanted actions.
- UI elements are sorted more cleanly into distinct tabs.
- You can quickly add a section of repeated notes using UI elements in the Note tab.
- A waveform of the Instrumental or Vocals can be toggled on to assist in charting timings.
- Sustains are coloured properly rather than being white.
- You can alter the playback speed of the song to assist in chart timing.
- There is a metronome to help you chart on beat.
- Hitsounds can be toggled on for the opponent or player notes.
- Autosave can be toggled on and the interval can be changed to anywhere between 5 seconds to 600 seconds.
- The volume of the Instrumental and Vocals can be lowered/raised.
- A "Vortex" mode is present allowing you to place notes with the 1-8 keys while the song is playing, as well as snap to certain quantizations.
- You can chart with different key amounts simply by changing the "mania" option.
- You can change the grid zoom to place notes closer or farther from each other while still snapped to the grid.
- You can jump to any section in the chart by using the Jump Section button in the Section tab.
- When saving, the file explorer will automatically open to the folder where the chart should be saved (if it exists).
- There is a difficulty dropdown to allow you to change which difficulty you are loading or saving without reloading the editor.

![charter](https://user-images.githubusercontent.com/101066547/222319055-c11f7eb9-e827-4062-a817-61a92a6b0bc9.gif)

### Dialogue Editor

- Dialogue can be loaded, edited and saved as a json.
- Different animated expressions can be set per dialogue.
- The dialogue box can be toggled between a normal and extreme speech bubble.
- Different dialogue sounds can be set per dialogue.
- Different typing speeds can be set per dialogue.
- A large number of characters are supported.

### Dialogue Character Editor

- Dialogue characters can be loaded, edited, and saved as jsons.
- Animations can be added and edited, including offsets and looping support.
- Characters can be set to appear from the left, center, or right.
- Offsets can be set and saved.
- Scale can be set and saved.

### Events

- Custom events can be created and used at any point in a song, saved to the chart, or as a seperate json.
- Custom events can use Lua or HaxeScript.
- There are 31 included events by default, designed to do generic things such as changing the zoom or causing a camera flash.

### Flinching Icons

- The player icon can optionally be toggled to "flinch" when health is lost.
- The icon will temporarily turn into the losing icon of the player.

### Freeplay Menu

- Songs are no longer hard coded, and are loaded from week jsons.
- The score on a song, rating, and accuracy are now all displayed.
- Icons are displayed next to the songs.
- The background changes colour based on the song.
- The score of the selected song can be reset by opening a submenu with R.
- The icons automatically bop to the beat of the current song.
- The selected song can be played by pressing SPACE.
- ALT can be pressed to open the character select submenu.
- Songs can be divided into different sections defined in the week jsons.
- COMMA can be pressed to open a submenu to change sections.
- CONTROL can be pressed to open a submenu to change modifiers.

![freeplaysection](https://user-images.githubusercontent.com/101066547/222319069-f3b992b1-f520-41e2-9667-08e765f56586.gif)

### Game-Over Menu

- The dead character, death sound, background music, restart sound, and bpm can all be changed depending on the character.
- The camera automatically zooms in/out depending on the size of the character.

### Gameplay Modifiers

- Gameplay modifiers can be added to change and spice up gameplay.
- The scroll speed can be set, or multiplied.
- The playback speed can be set from anywhere between 0.1x and 10x.
- The health gain and loss multipliers can be set.
- Instakill on miss can be toggled on/off.
- Sick only can be toggled on/off to kill you when you get a good or below.
- Poison can be toggled on to punish you with health drain when you miss.
- Freeze can be toggled on to punish you with not being able to move for 2 seconds when you miss.
- Flashlight can be toggled on to make it more difficult to see upcoming notes.
- Ghost Mode can be toggled on to make notes disappear before they reach the strums.
- Random Mode can be toggled to randomize the entire chart.
- Flip can be toggled to flip the chart and strums for an extra challenge.
- Practice Mode can be toggled to disable dying.
- Botplay can be toggled to make the game play itself.

![modifiers](https://user-images.githubusercontent.com/101066547/222319123-484866f3-99a1-4808-ae72-cdabc73830ab.gif)

### Lua Support

- Lua files can be loaded in game.
- Lua has a multitude of functions to allow it to be very versitile.
- Any number of lua scripts can be loaded at any time.
- Lua scripts can be loaded based on characters, stages, songs, etc.

### Manual

- A fully inclusive manual is included to help you use the engine.
- The manual can be opened at almost any time by pressing the Manual keybind.
- The manual covers controls, functionality, and several other aspects of the different menus and editors.

### Menu Character Editor

- Menu Characters can be loaded, edited, and saved as jsons.
- Menu Characters are no longer all on one sprite sheet, and can be loaded seperately.
- Offsets can be set and saved.
- Scale can be set and saved.
- Menu characters other than BF can now also play their own selection animation.

### Mod Support

- Mods can be added and loaded from the "mods" folder in the engine directory.
- Mods can be seperated into subdirectories in the mods folder, such as "mods/ourple_guy"
- Character, Stages, and Icons can be loaded across mod subdirectories for gameplay, and editors.
- Weeks, Songs, Stages, Scripts, Modcharts, Shaders, Fonts, Dialogue, Characters, Music, Sounds, Images, and Videos can all be used/created with mods.

### Multikey Support

- The engine supports key counts from 1 to 9.
- Key count can be changed at any time using the Change Mania event.
- Keys are easily managed in the charter with an automatically resizing grid.

### Notetypes

- Notes can have different types, with different effects.
- Notetypes can be made using Lua or HaxeScript.
- 8 Note types are included by default for basic alterations such as hurt notes, and notes to make gf sing.

### Options Menu

- A fully custom options menu sorted into catagories is present to customize the engine to your needs.
- Most options are sorted into the General, Gameplay, Graphics, and Misc catagories.

![options](https://user-images.githubusercontent.com/101066547/222319219-753b2fac-d136-491d-9a3a-540458cab731.gif)

- Notes can also be altered to have custom colors using hue, saturation, and brightness shifting.
- Any color shifts will transfer between note skins, and be individual to each note.

![notes](https://user-images.githubusercontent.com/101066547/222319212-3b88030b-a87f-4cc9-a4bd-72ac94c186c3.gif)

- In addition to all other options, all keybinds are rebindable to allow you to play how you want.
- Keybinds can be set to two different keys, so you can use any of the two.

![keybinds](https://user-images.githubusercontent.com/101066547/222319228-dd5c03cd-6d9d-47d7-9838-415fa666a13a.gif)

### Pause Menu

- The Pause Menu has been improved to allow you to do more things than just resume, restart, and exit.
- You can access the options menu from the pause menu.
- You can change the gameplay modifiers from the pause menu.
- You can replay the cutscene (if there is one).
- You can change the difficulty of the song.
- Several tools are included for charters and coders such as being able to skip to any time, instantly end the song, etc.

### Performance Optimized

- The engine is optimized very well in order to run the best it can at any given moment.
- The engine is capable of running upwards of 900+ frames per second on higher end computers.
- The engine will not memory leak excessively, and stay within a reasonable realm of usage.
- The engine uses at max 2 GB of ram at any time during vanilla gameplay.

### Second Opponent

- A second opponent can be enabled to allow you to have multiple opponents for songs that use multiple opponents at once.
- The second opponent will have their own strum line that can be charted with the "Third Strum" Notetype.
- The second opponent can be positioned, changed, and otherwise used in the same way the normal opponent can.

### Scripting Support

- Psych Engine lua files can be loaded and used just the same as in Psych Engine.
- HaxeScript is the main available scripting language, and can be used to create States, Substates, Classes, and Misc. Scripts, utilizing the require function to include any classes you wish.
- Scripts can be used to alter songs, create events, create stages, create modcharts, and much more.

### Sustains

- Sustain notes are now near perfectly connected.
- Sustain notes now smoothly increase player health.
- Sustain notes are now rendered underneath the strums, and look much nicer overall.

### Splash Screen

- A custom splash screen is present, replacing the HaxeFlixel splash.
- Several random versions of the splash can be chosen.
- Several easter eggs exist in the splash screen.
- Pressing Enter will skip straight to the title screen.
- On debug mode, there are keybinds to jump straight to a majority of menus from the splash screen.

![splash](https://user-images.githubusercontent.com/101066547/222319156-26f390e8-9573-406c-9b48-314e2a5a7343.gif)

### Title Screen

- The entire intro is soft coded and can be changed with intro.json using commands and beat timings.
- The title, start prompt, and gf can all be offset individually using offsets.json.
- Antialiasing can be set for the title, start prompt, gf, and custom bg using offsets.json.
- Gf can be rescaled using offsets.json.
- A custom background can be added, using eitehr a static image or a looping animation which is loaded automatically.
- The bpm can be set in offsets.json.
- The newgrounds shoutout can be replaced with any number of randomly selected shoutouts using shoutouts.json, using custom images.
- A hue swap shader is present and automatically activates upon waiting 180 ticks.
- The title screen is more active, zooming on each beat.

![title](https://user-images.githubusercontent.com/101066547/222319163-8d5d7f98-db33-4673-b46a-b47f496d5351.gif)

### Updating

- The engine will automatically download and install an update when prompted.
- Checking for updates can be disabled in the options menu.
- Updates only download what is necessary, instead of the entire new build.
- Updates can be ignored at any time.

### Vanilla Overhauls

- The majority of the base game has been overhauled to be a new and fresh experience.
- Toggleable subtitles have been added to Tutorial, Monster, and Winter Horrorland.
- Dad Battle has had its chart adjusted to no longer have awkward charting.
- The default stage has been adjusted to no longer have the characters "slide" due to an incorrect scroll speed.
- Spookeez now includes Hey! animations for Skid and Pump.
- Spookeez now has lightning whenever the lightning happens in the song.
- South is now darker than Spookeez as originally intended.
- Monster has been entirely overhauled with a new stage and events.
- Philly nice now sees boyfriend doing his Hey! animation.
- Blammed now has special effects during the drop.
- Week 4 now has billboards in the background, and the cars can be in front of or behind the car.
- There is now a custom death screen for Week 4.
- Week 5 now has snow, in addition to hey animations from the crowd and Girlfriend.
- Eggnog now has its working transition cutscene to Winter Horrorland.
- Winter Horrorland's stage has been altered to no longer be awkwardly set up.
- Week 6's dialogue has been entirely overhauled to have portraits, custom dialogue sounds, and better performance.
- Senpai now has special effects and a transition cutscene between Roses.
- Roses now has special effects during the drop, and has a transition cutscene between Thorns.
- The thorns cutscene has been improved to be more cinematic and ominous.
- Thorns has been changed to be more visually climactic.
- The BG Girls now show up during the "Hey!" parts of thorns.
- Week 7's cutscenes have been optimized and play in game using FlxAnimate.
- Guns has a new, improved chart, and now has special affects during the "Ascension" part.
- Stress now has special effects, and properly zooms in on Pico during his solo.

### Week Editor

- Weeks can be loaded, edited, and saved as jsons.
- Songs can be added, with icons and freeplay colors per song.
- Both the Freeplay and Story Mode menus can be previewed.
- Weeks can be locked, and hidden until unlocked.
- Weeks can be hidden in Freeplay or Story Mode.
- The story mod characters can be set for the week.
- The difficulties can be set for the week.
- The freeplay sections can be set for the week.
- Weeks graphics are now seperate instead of being one sprite sheet.
- A background can be set to appear when the week is selected.

## Limitations

- The Engine is not compatible with most other engines.
- The Engine does not support Lua outside of gameplay.
- The Engine does not support adding haxelibs without source code.
- The Engine is constrained to a modified HaxeFlixel's capabilities.
