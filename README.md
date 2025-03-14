# Reactive Docking

## 3.0 Update Info!
In prior version of Reactive Docking, the "Reactive" option selection was tied to the commander pilot. This lead to problems where taking over manual control of a ship, or changing pilot, would reset or otherwise change the docking behaviour. For 3.0 I wanted to fix this by switching where I store the selected docking behaviour to a place such that it could now be tied to the ship, rather than the pilot. 3.0 includes some migration code which will migrate the selected docking options to the new storage and delete the old. This means that loading a save that has used 3.0 of Reactive Docking with an earlier version, will result in a full or partial reset of reactive docking options.

## Description
In vanilla X4: Foundations subordinates assigned to a carrier with the 'Launched' option will remain docked until something relevant to their standing order happens. 
For example if the leader is attacked then groups with 'defend' will launch to defend. 
Most other subordinate groups just have the options to always be launched, always docked, or no dockiong options at all. The overall intend with this mod is to expand this carrier 'reactive' docking behaviour to more ship types.

### Docking behaviour options
You can change the default option for any of these cases in the Extension Options (requires SirNuke's Mod Support API). **It is recommended this is only done once at the start of the game, as changing the default options will flip all reactive/launched docking options**.

#### Non-carrier escort wing
Example: Fighter assigned to intercepting for Colossus XL carrier.

1. Docked: Same behaviour as vanilla. Subordinates will remain docked.
2. Launched (default): Same as vanilla. Subordinates will remain launched, and only dock if leader wants to travel far distances.
3. Reactive: Subordinates will dock, but launch if something happens that is relevant to their standing order.

#### Carrier escort wing
Example: Fighter assigned to attacking with Behemoth L destroyer.

1. Docked: Same behaviour as vanilla. Subordinates will remain docked.
2. Launched: Subordinates will remain launched, and only dock if leader wants to travel far distances.
3. Reactive (default): Same as vanilla launched. Subordinates will dock, but launch if something happens that is relevant to their standing order.

#### Station defence wing
Example: Fighter assigned to defence of player HQ station.

1. Docked: Subordinates will remain docked.
2. Launched (default): Same as vanilla. Subordinates will patrol around the station in a random pattern, and engage any enemy entering the zone of control.
3. Reactive: When no enemies are detected, ships will move towards available docking pads while keeping a lookout. If within 8km of docking pads they will initiate dock. Will launch and attack if enemies enter the zone of control. Also works with capital ships.

#### Auxiliary trader
Example: Courier Vanguard assigned to trade for Nomad.

1. Docked: Option not available.
2. Launched (default): Same as vanilla. Ships will look for trades for the auxiliary ship, and launch as soon as it has completed a trade.
3. Reactive: Trader will dock at auxiliary if it has found no valid trades for some time. Will remain docked to auxiliary after completing trade, until it has found another.

## Requirements
* (OPTIONAL) SirNuke's Mod Support API [[Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=2042901274) | [Nexus](https://www.nexusmods.com/x4foundations/mods/503)] - Required for changing default docking options, but otherwise not needed. Will require UI Protection mode be disabled.
* (OPTIONAL) Kuertee's's UI Extension and HUD version >= 2.0.6 [[Nexus](https://www.nexusmods.com/x4foundations/mods/552?tab=description)] - Increase compatibility with other UI mods.

## Compatibility
This mod is save compatible. You can add it to an existing save, and remove it without errors. If removed then groups with the 'Reactive' option enabled will simply change to 'Launched'.

This mod achieves compatibility with other UI mods through the UI Extension and HUD mod.

## FAQ
	
1. *When I have ships in storage, and one on the pad, and all are to launch why does the ship currently on the pad not launch first, rather than stow only to launch after another has?*
	- As far as I can tell this is vanilla behaviour for the game. So I dunno what I could do about it. The game doesn't seem to make any priority for ships already on a pad if both it and one in storage needs to launch.

2. *When they return to dock on my leader with one pad, only 1 ship docks and the rest just cancel their docking?*
	- Again, seems to be vanilla behaviour. They get cancelled because the pad is occupied. Why they don't just queue up to dock I don't know atm.

3. *I wanna fix your shitty code*
	- You are very welcome to make requests to the [github](https://github.com/runekn/x4-reactive-docking).

4. *My auxiliary trader is not docking after switching to Reactive*
	- Reactive mode for auxiliary traders will not dock until it has failed to find valid trades for some time.

## Thanks to
* Allectus for making another mod that does somewhat the same things, so that I could easily see how to achieve what I wanted despite this being my first mod :P
* Forleyor for making the integration with UI Extension and HUD
* ArkBlade2015 for japanese translation (though now removed)

## Updates

* 3.0.0: Support for station defend subordinates. Support for auxiliary trade subordinates. Docking settings are now tied to the ship, rather than the pilot. Removed japanese translations, since they are outdated.
* 2.3.3: Fix Reactive docking preventing Expanded Configuration Loader from working
* 2.3.2: Use new official UI file declaration to avoid requiring disabled UI protection mode
* 2.3.1: Fix compatibility with 7.50
* 2.3.0: Add options menu for default behaviour of player ships. New docking behaviour is now instantly applied when chosen from dropdown.
* 2.2.1: Fixed docking menu
* 2.2.0: Updated standalone UI mode for 7.0
* 2.1.0: Updated standalone UI mode for 6.0
* 2.0.0: Launched option for carrier groups now behave as non-carriers. Added Reactive option to carrier groups.
* 1.4.0: Fixed compability with 5.0 when not using kuertee's UI mod
* 1.3.1: Added Japanese by ArkBlade2015
* 1.3.0: Fixed error logs when opening loadout menu on ship without captain. Reactive mode is now disabled if there is no captain.
* 1.2.0: Fixed reactive mode when leader is M ship.
* 1.1.0: Better mod compatibility. Disabled Reactive modes for stations.
* 1.0.0: Fixed ingame mod dependency. Added STO compatible version.
* 0.1.0: Initial release.
