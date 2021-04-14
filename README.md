# Reactive Docking v0.1

## Description
In vanilla X4: Foundations subordinates assigned to a carrier with the 'Launched' option will remain docked until something relevant to their group's order happens. 
Forexample if leader is attacked then groups with 'defend' will launch to defend.
Though for non-carrier capital ship subordinates in 'Launched' mode will instead remain launched constantly whether they are needed or not.

This mod provides an additional docking option to non-carrier capital ships that has landing pads. This new docking option is called 'Reactive' and makes subordinates behave like they are carrier-based.
To provide this extra option the Docking/Launched button found in loadout info submenu and 'Enter' menu has been changed to a dropdown for non-carriers.

Carriers will not have this option and their 'Launched' mode remains unchanged.

## Requirements

* SirNuke's Mod Support API [[Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=2042901274) | [Nexus](https://www.nexusmods.com/x4foundations/mods/503)]

## Compatibility
This mod is save compatible. You can add it to an existing save, and remove it without errors. If removed then groups with the 'Reactive' option enabled will simply change to 'Launched'.

This mod is currently not compatible with other mods that change the loadout menu (forexample Subsystem Targeting Orders by Alkeena).

## FAQ
	
1. *When I have ships in storage, and one on the pad, and all are to launch why does the ship currently on the pad not launch first, rather than stow only to launch after another has?*
	- As far as I can tell this is vanilla behavior for the game. So I dunno what I could do about it. The game doesn't seem to make any priority for ships already on a pad if both it and one in storage needs to launch.

2. *When they return to dock on my leader with one pad, only 1 ship docks and the rest just cancel their docking?*
	- Again, seems to be vanilla behavior. They get cancelled because the pad is occupied. Why they don't just queue up to dock I don't know atm.

3. *I wanna fix your shitty code*
	- You are very welcome to make requests to the [github](https://github.com/runekn/x4-reactive-docking).

## TODO

* v1
	- Make compatible with STO



This is a v0.1 launch because I want to at least make it compatible with Subsystem Targeting Orders before I consider it done.

## Thanks to
* Alkeena for making another mod that does somewhat the same things, so that I could easily see how to achieve what I wanted despite this being my first mod :P