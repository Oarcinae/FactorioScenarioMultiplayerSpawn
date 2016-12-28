# FactorioScenarioMultiplayerSpawn
A custom scenario for allowing separate spawn locations in multiplayer. Designed for Co-op and PvE.

## Instructions

### STEP 1

Download the zip. 

Place it in your Factorio/scenarios/... folder.

It should look something like this (for my windows steam install location):

C:\Users\user\AppData\Roaming\Factorio\scenarios\FactorioScenarioMultiplayerSpawn\control.lua

### STEP 2

ALSO download the zip for "locale" from https://github.com/Oarcinae/FactorioUtils

Place this inside the locale folder. It should look like this:

C:\Users\user\AppData\Roaming\Factorio\scenarios\FactorioScenarioMultiplayerSpawn\locale\oarc_utils.lua

### STEP 3

Go into config.lua and edit the strings to add your own server messages.

Rename the "FactorioScenarioMultiplayerSpawn" folder to something shorter and more convenient (optional).



## Configuration

Look in config.lua for some controls over the different modules.  

Not all configurations have been fully tested so modify at your own risk.

If you want to change the RSO config, look for the rso_config and rso_resource_config files.


## TODO

I need to update this with more details about the implementation and explain some of the configuration options.

For now, just take a look at the source and it should be easy to understand I hope.


## Credit

RSO is not my own creation. It was done by Orzelek. I requested permission to include it in my scenario.  

https://mods.factorio.com/mods/orzelek/rso-mod

Several other portions of the code (tags, frontier style rocket silo) have also been adapted from other scenario code.

Credit to 3Ra as well: https://github.com/3RaGaming/3Ra-Enhanced-Vanilla