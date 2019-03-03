# FactorioScenarioMultiplayerSpawn
A custom scenario for allowing separate spawn locations in multiplayer. Designed for Co-op and PvE. 

## WARNING! IN DEVELOPMENT! NOT STABLE!
I just started 0.17 compatibility work... this is buggy as HELL. Don't expect any smooth experience. And with scenarios, you lose ALL progress when it crashes. This is NOT like a mod where you can remove it and sometimes recover your map.

## 0.17 Changes

#### Soft mods removal
I have removed most of the soft mods, including RSO. Now that 0.17 has proper auto mod syncing with the server, you should use actual mods. That will make the scenario easier to maintain and require less changes whenever you update since there will be less to configure.

#### Removal of cmd line map gen settings
0.17 allows you to provide map generation settings using --map-gen-settings when you launch the scenario from the command line. You should be using that to generate your maps. I will include an example/recommended settings with the scenario but it's up to you to make sure your game launches with whatever settings you want. 

## Instructions for starting a server

### STEP 1

Download the zip. 

Place it in your Factorio/scenarios/... folder.

It should look something like this (for my windows steam install location):

C:\Users\user\AppData\Roaming\Factorio\scenarios\FactorioScenarioMultiplayerSpawn\control.lua


### STEP 2

Go into config.lua and edit the strings to add your own server messages.

Rename the "FactorioScenarioMultiplayerSpawn" folder to something shorter and more convenient (optional).


### STEP 3

#### OPTION 1 (Client Hosted)
Start a multiplayer game on your client like normal.

#### OPTION 2 (Headless)
Generate a new map like normal, save the game and use that save file to host.
This uses the "--start-server save_file.zip" cmd line option.
Example: ./factorio --start-server save_file.zip --server-settings your-server-settings.json

#### OPTION 3 (Headless - No zip save BS)
Place the scenario code in the game's scenario folder, typically something like "..\Factorio\scenarios\FactorioScenarioMultiplayerSpawn\\.."

Start a new game (generates a random map based on the config in config.lua) from the command line:
./factorio --start-server-load-scenario FactorioScenarioMultiplayerSpawn --server-settings my-server-settings.json

If you want to RESUME from this method, use something like this:
./factorio --start-server-load-latest --server-settings my-server-settings.json

##### This is an example of my bash script that I use to start my game:
 #!/bin/bash

settings_files="--server-settings oarc-server-settings.json --server-banlist banlist.json"
admin_list="--server-adminlist server-adminlist.json"
map_gen_settings="--map-gen-settings map-gen-oarc.json"
log_file="--console-log oarc-server.log"
start_scenario_cmd="--start-server-load-scenario FactorioScenarioMultiplayerSpawn"

/factorio/bin/x64/factorio $start_scenario_cmd $settings_files $log_file $admin_list $map_gen_settings


## Configuration

Look in config.lua for some controls over the different modules.  
Not all configurations have been fully tested so modify at your own risk.

Resource & terrain map configuration should be done at launch or using --map-gen-settings.


## TODO

I need to update this with more details about the implementation and explain some of the configuration options.

For now, just take a look at the source and it should be easy to understand I hope.


## Credit

Several other portions of the code (tags, frontier style rocket silo) have also been adapted from other scenario code.

Credit to 3Ra for help as well: https://github.com/3RaGaming

Praise be to Mylon


## Random Notes

Feel free to submit bugs/fixes/requests/pulls/forks whatever you want.

I do not plan on supporting PvP, but I will help anyone who wants to make it a configurable option.
