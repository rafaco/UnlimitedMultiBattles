# UnlimitedMultiBattles 
[![Game](https://img.shields.io/badge/Game-Raid:_Shadow_Legends-yellow.svg?style=flat-square)](https://plarium.com/en/download-games/raid-shadow-legends/?view=plariumplay) [![Operative System](https://img.shields.io/badge/Operative_System-Windows-blue.svg?style=flat-square)](https://www.microsoft.com/es-es/windows) [![Powered by](https://img.shields.io/badge/Powered_by-AutoHotKey-green.svg?style=flat-square)](https://www.autohotkey.com/)

<img src="https://github.com/rafaco/UnlimitedMultiBattles/blob/master/images/Screenshots.gif">

**This application allows unlimited auto battles on official 'Raid: Shadow Legends' for Windows. It provide an easy to use graphic user interface and it can be used on background while you do other things with your PC.**

You only have to select a "number of battle" and a "battle duration" in our UI, assisted by our campaign calculator. Then, we will make use of standard hotkeys provided by the game to give you that multi-battles. Every "battle duration" we bring to top the game window, press a hotkey on it and restore the window you were in. We do it very quickly and we do it a "number of battles" times for you.

*Shortlink: [`https://git.io/UMB`](https://git.io/UMB)*

### Features
- Graphic user interface to configure, control and track the progress
- Can be use on background
- Adjustable time between battles to minimise the total time
- Adjustable number of battles to avoid wasting your energy. Three modes available:
  - Manual: enter any number of battles
  - Calculated: Use our calculator to run the exact battles to maximise your champions considering stars, level, difficulty, map, stage and xp boosts
  - Infinite: Run battles indefinitely, till you stop it or till your energy run outs
- Get extra info before start: Energy cost, Silver reward and total duration
- Get progress detail while multi-battling
- Configurable action on finish: bring up game (champions replacement), bring up results or only load results on background.
- Auto-detect game closed and allow opening it
- Auto-detect admin rights required and allow relaunching as admin
- Remember all settings between usages
- Include help screen and link to this repo


# Set up

For a quick start, **download** a precompiled ```UnlimitedMultiBattles.exe``` from our [latest release](https://github.com/rafaco/UnlimitedMultiBattles/releases/latest):

<p align="center">
    <a href="https://github.com/rafaco/UnlimitedMultiBattles/releases/latest/download/UnlimitedMultiBattles.exe" alt="Latest">
        <img src="https://img.shields.io/badge/Latest-UnlimitedMultiBattles.exe-brightgreen.svg?style=for-the-badge&logo=github"/></a>
</p>

Using exe files downloaded from internet is widely discourage and Windows will alert you when runnning it for the first time. To avoid this inconvenience, you can **generate your own exe** from our sources:

1. Clone [this repository](https://github.com/rafaco/UnlimitedMultiBattles.git) in a local folder on your PC.
2. Download and install [AutoHotKey for Windows](https://www.autohotkey.com/) in your PC.
3. Open Ahk2Exe.exe from the installation folder or from  Start->Programs->AutoHotkey->"Convert .ahk to .exe".
4. Select our script file as source ([UnlimitedMultiBattles.ahk](https://github.com/rafaco/UnlimitedMultiBattles/blob/master/UnlimitedMultiBattles.ahk)), any local folder as destination and our icon as custom icon ([images/icon.ico](https://github.com/rafaco/UnlimitedMultiBattles/blob/master/images/icon.ico)).
5. Press 'Convert' and your exe will be created in your destination folder.


# Usage

Open our executable file on your PC, configure your options and start multi-battling:
1. **Prepare your Team**: Go to the game, select a stage and prepare your team, but don't press 'Play' and come back to our app.
2. **Select number of battles**: Select how many times you want to play the stage. In order to avoid wasting your precious energy, you have three available modes:
   * Manual: Enter any number of battles
   * Calculated: Use exact number to max out your champions in campaign
   * Infinite: Run forever till you stop us or your energy run out
3. **Select battle duration**: Enter how many seconds you want us to wait between each replay. It depends on your current team speed for the stage you are in. Use your longer run time plus a small margin for the loading screens. If a battle take longer a replay will be missed and you will waste some time, but the next replay will carry on with the followings ones.
4. Press **Start Multi-Battle** in our application when ready. We will start the first battle and replay the followings.


# Contributing
There are many ways to contribute starting from giving us a GitHub :star:, recommending this library to your clan members :loudspeaker: or sending us your [feedback/bug/request](https://github.com/rafaco/UnlimitedMultiBattles/issues/new) :love_letter:. Pull requests are more then welcome :nerd_face:.


# Disclaimer
This application is not an autoclicker as it works using standard hotkeys. You could get exactly the same results by pressing ```Enter``` on the selection screen to start and then periodically: ```Alt```+```Tab``` (swap window), ```R``` (replay) and ```Alt```+```Tab``` again (restore window).

I believe this is not against the T&C of the game, as it just automatise the most annoying and less creative part of this game by using the hotkeys provided by the game itself. It also encourage players to spend more gems as they will run out of energy quicker. Please, let me know if I'm wrong.


# Thanks
- To [Myckoz](https://www.reddit.com/user/Myckoz/) for his [Campaign Run Calculator](https://www.reddit.com/r/RaidShadowLegends/comments/bgmoy0/campaign_run_calculator/) spreadsheet.


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
