# FactorioScenarioMultiplayerSpawn
A custom scenario for allowing separate spawn locations in multiplayer. Designed for Co-op and PvE. 

## WARNING! STILL IN DEVELOPMENT!
I'm mostly cleaning up my 0.17 work at this point, it seems pretty stable. There could still be some game breaking bugs in there based on your config settings, but I'm feeling pretty good about it overall now. My own home server ran for 20+ game hours with a few consistent players so it seems playable now.

## 0.17 Changes

#### RSO removal
I removed RSO because it was a pain to implement and support as a soft mod. And the mod author seemed to change his mind later about allowing my use case. Either way, I dropped it since vanilla resource gen is much better now. You have to make usre to follow the next instructions about map gen settings if you want a good experience.

#### Removal of cmd line map gen settings
0.17 allows you to provide map generation settings using `--map-gen-settings` when you launch the scenario from the command line. You should be using that to generate your maps. I will include an example/recommended settings with the scenario but it's up to you to make sure your game launches with whatever settings you want. Also use `--map-settings`, it seems that works for me now.

`--map-gen-settings` is for terrain / resource / map gen
`--map-settings` is for enemy evo / pollution settings

NEVER MIND. I'm still struggling to get `--map-settings` to work... https://forums.factorio.com/viewtopic.php?f=7&t=67813&p=413154#p413154 Bug Report Filed I guess?

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
Start a multiplayer game on your client like normal. Using this method will mean you are stuck with the game's map/terrain config options. Railworld is your best option here.

#### OPTION 2 (Headless)
Generate a new map like in OPTION 1, save the game and use that save file to host.
This uses the "--start-server save_file.zip" cmd line option.
Example: `./factorio --start-server save_file.zip --server-settings your-server-settings.json`

#### OPTION 3 (Headless - No zip save BS)
Place the scenario code in the game's scenario folder, typically something like "..\Factorio\scenarios\FactorioScenarioMultiplayerSpawn\\.."

Start a new game (generates a random map based the config in your map-gen-settings.json file) from the command line:
`./factorio --start-server-load-scenario FactorioScenarioMultiplayerSpawn --map-gen-settings your-map-gen-settings.json --map-settings your-map-settings.json --server-settings my-server-settings.json`

If you want to RESUME from this method, use something like this:
`./factorio --start-server-load-latest --server-settings my-server-settings.json`

##### This is an example of my bash script that I use to start my game:
```
#!/bin/bash

settings_files="--server-settings oarc-server-settings.json --server-banlist banlist.json"
admin_list="--server-adminlist server-adminlist.json"
map_gen_settings="--map-gen-settings map-gen-oarc.json"
map_settings="--map-settings map-settings-oarc.json"
log_file="--console-log oarc-server.log"
start_scenario_cmd="--start-server-load-scenario FactorioScenarioMultiplayerSpawn"

/factorio/bin/x64/factorio $start_scenario_cmd $settings_files $log_file $admin_list $map_gen_settings $map_settings
```

## Configuration

Look in config.lua for some controls over the different modules.  
Not all configurations have been fully tested so modify at your own risk.

Resource & terrain map configuration should be done at launch or using --map-gen-settings.
Use the examples in the example folder if you want my take on map/resource/enemy gen.


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
