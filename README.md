# UnlimitedMultiBattles [![Game](https://img.shields.io/badge/Game-Raid:_Shadow_Legends-yellow.svg?style=flat-square)](https://plarium.com/en/download-games/raid-shadow-legends/?view=plariumplay) [![Operative System](https://img.shields.io/badge/Operative_System-Windows-blue.svg?style=flat-square)](https://www.microsoft.com/es-es/windows) [![Powered by](https://img.shields.io/badge/Powered_by-AutoHotKey-green.svg?style=flat-square)](https://www.autohotkey.com/)

<img src="https://github.com/rafaco/UnlimitedMultiBattles/blob/master/media/social.jpg">

This application allows unlimited auto battles on official 'Raid: Shadow Legends' for Windows. It has an easy to use interface and can be used on background while doing other things with your PC. 

### Features:
- Graphic interface to easily configure, control and see progresses
- Can be use on background
- Adjustable time between battles to minimise the total time
- Adjustable number of battles to avoid wasting your energy. Three modes available:
  - Manual: enter any number of battles
  - Calculated: Use our mini-calculator to run the exact battle to maximise your champions considering their stars, stage and xp boosts
  - Infinite: Run battles indefinitely, till you stop it or till your energy run outs
- Remember your previous configuration for the next time you open our app
- Detect if the game is not open or the game is closed while working


# Usage

1. Download ```UnlimitedMultiBattles.exe``` from [latest release](https://github.com/rafaco/UnlimitedMultiBattles/releases/latest) or [compile your exe](#compile-your-exe).
2. Open ```Raid: Shadow Legends``` on your PC, select a stage and prepare your team but don't press "Play" already.
3. Open ```UnlimitedMultiBattles.exe``` on your PC, select your options and press "Start Multi-Battle".

**Time between battles**: Enter how many seconds you want us to wait between each replay. It depends on your current team speed for the stage you are in. Use your longer run time plus a small margin for the loading screens. If a battle take longer a replay will be missed and you will waste some time, but the next one replay will carry on with the followings ones.

**Number of battles**: Select how many times you want to play the stage. In order to avoid wasting your precious energy, you have three available modes: you can run it INFINITELY, enter a MANUAL number or use our handy CALCULATOR to know how many runs you need to max out your level 1 champions.

# Compile your exe

You can easily generate your own exe from the sources to avoid using an executable files downloaded from internet.

1. Install [AutoHotKey](https://www.autohotkey.com/) for Windows in your PC.
2. Download a copy of our script [UnlimitedMultiBattles.ahk](https://github.com/rafaco/UnlimitedMultiBattles/blob/master/UnlimitedMultiBattles.ahk).
3. Right click on the downloaded file and press "Compile", your own exe will be generated in the same folder.

# Disclaimer:
This application is not an autoclicker and it works using standard hotkeys. Periodically, we quickly swap to the game window, press a in-game hotkey to replay and restore the window you were in. You could get exactly the same results by periodically pressing ```Alt```+```Tab``` (swap window), ```R``` (replay) and ```Alt```+```Tab``` again (restore window).

I believe this is not against the T&C of the game, as it just automatise the most annoying and less creative part of this game by using the hotkeys provided by the game itself. It also encourage players to spend more gems as they will run out of energy quicker. Please, let me know if I'm wrong.

# License
```
Copyright 2020 Rafael Acosta Alvarez

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
