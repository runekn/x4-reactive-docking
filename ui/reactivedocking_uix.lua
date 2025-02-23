local map_menu = {}
local dock_menu = {}
local do_menu = {}

RKN_ReactiveDocking_UIX = {}

function RKN_ReactiveDocking_UIX.init()
	DebugError("Reactive Docking UI Init")

	map_menu = Helper.getMenu("MapMenu")
	map_menu.registerCallback("rd_addReactiveDockingMapMenu", do_menu.addReactiveDockingMapMenu)
	
	dock_menu = Helper.getMenu("DockedMenu")
	dock_menu.registerCallback("rd_addReactiveDockingDockMenu", do_menu.addReactiveDockingDockMenu)
end

function do_menu.addReactiveDockingMapMenu(row, inputobject, i, mode, active, mouseovertext)
	RKN_ReactiveDocking.addReactiveDockingMapMenu(row, inputobject, i, mode, active, mouseovertext, map_menu)
	return true
end

function do_menu.addReactiveDockingDockMenu(row, inputobject, i, active, mouseovertext)
	RKN_ReactiveDocking.addReactiveDockingDockMenu(row, inputobject, i, active, mouseovertext, dock_menu)
	return true
end