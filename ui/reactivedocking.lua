-- ffi setup 
local ffi = require("ffi")
local C = ffi.C

RKN_ReactiveDocking = {}

local config = {
	subordinatedockingoptions = {
		[1] = { id = "docked",			text = ReadText(1001, 8630),	icon = "",	displayremoveoption = false },
		[2] = { id = "launched",		text = ReadText(1001, 8629),	icon = "",	displayremoveoption = false },
		[3] = { id = "reactive",		text = ReadText(181114415, 1),	icon = "",	displayremoveoption = false }
	},
	subordinatedockingoptions_resupplier = {
		[1] = { id = "docked",			text = ReadText(1001, 8630),	icon = "",	displayremoveoption = false, active = false, mouseovertext = ReadText(181114415, 2) },
		[2] = { id = "launched",		text = ReadText(1001, 8629),	icon = "",	displayremoveoption = false },
		[3] = { id = "reactive",		text = ReadText(181114415, 1),	icon = "",	displayremoveoption = false }
	},
	mapRowHeight = Helper.standardTextHeight
}

-- Returns whether reactive is on based on settings, dropdown selection, and shiptype.
local function isReactive(inputobject, checked, station)
	local playerID = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
	local settings = GetNPCBlackboard(playerID, "$RKN_ReactiveDockingSettings")
	local shiptype = GetComponentData(inputobject, "shiptype")
	local carrier = shiptype == "carrier"
	local resupplier = shiptype == "resupplier"
	local default = false
	if station then
		default = settings.default_station_reactive == 1
	elseif resupplier then
		default = settings.default_resupply_reactive == 1
	elseif not carrier then
		default = settings.default_noncarrier_reactive == 1
	elseif carrier then
		default = settings.default_carrier_reactive == 1
	end
	return (checked and not default) or (not checked and default)
end

local function getReactiveTable(inputObject)
	local idcode = ffi.string(C.GetObjectIDCode(inputObject))
	local playerID = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
	local all = GetNPCBlackboard(playerID, "$RKN_ReactiveOptions")
	if all then
		return all[idcode] or {}
	else
		return {}
	end
end

local function setReactiveTable(inputObject, table)
	local idcode = ffi.string(C.GetObjectIDCode(inputObject))
	local playerID = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
	local all = GetNPCBlackboard(playerID, "$RKN_ReactiveOptions")
	if not all then
		all = {}
	end
	all[idcode] = table
	return SetNPCBlackboard(playerID, "$RKN_ReactiveOptions", all)
end

local function setReactiveDocking(inputobject, i, selectedReactive, station)
	local reactive = isReactive(inputobject, selectedReactive, station)
	local reactiveList = getReactiveTable(inputobject)
	reactiveList[i] = reactive
	setReactiveTable(inputobject, reactiveList)
end

local function getReactiveDocking(inputobject, i)
	local pilotentityid = GetControlEntity(inputobject)
	if pilotentityid == nil then
		return false
	end
	local reactiveList = getReactiveTable(inputobject)
	if reactiveList[i] == nil then
		return false
	else
		return reactiveList[i] == 1
	end
end

local function getDockingStartingOrder(inputobject, i, station)
	local docked = C.ShouldSubordinateGroupDockAtCommander(inputobject, i)
	local checked = getReactiveDocking(inputobject, i)
	local reactive = isReactive(inputobject, checked, station)
	if not docked and reactive then
		return "reactive"
	elseif not docked then
		return "launched"
	else
		return "docked"
	end
end

local function setDockingOptions(inputobject, i, newdockingoption)
	local isdocked = C.ShouldSubordinateGroupDockAtCommander(inputobject, i)
	local docked
	local reactive
	if newdockingoption == "reactive" then
		docked = false
		reactive = true
	elseif newdockingoption == "launched" then
		docked = false
		reactive = false
	else
		docked = true
		reactive = false
	end
	if isdocked == docked then
		C.SetSubordinateGroupDockAtCommander(inputobject, i, not docked)
	end
	C.SetSubordinateGroupDockAtCommander(inputobject, i, docked)
	setReactiveDocking(inputobject, i, reactive)
end

local function getDockingOptionsList(inputobject, assignment)
	local resupplier = GetComponentData(inputobject, "shiptype") == "resupplier" and assignment == "trade"
	if resupplier then
		return config.subordinatedockingoptions_resupplier
	else
		return config.subordinatedockingoptions
	end
end

function RKN_ReactiveDocking.addReactiveDockingMapMenu(row, inputobject, i, mode, active, mouseovertext, menu, isstation, isdockingpossible)
	if (type(active) == 'function') then
		active = active()
	end
	-- Reevaluate 'active', since vanilla just sets it false for any station and resupplier.
	menu.updateSubordinateGroupInfo(inputobject)
	if isstation or (menu.subordinategroups[i] and menu.subordinategroups[i].assignment == "trade") then
		active = true
		if not GetComponentData(inputobject, "hasshipdockingbays") then
			active = false
			mouseovertext = ReadText(1026, 8604)
		elseif not isdockingpossible then
			active = false
			mouseovertext = ReadText(1026, 8605)
		end
	end
	row[3]:setColSpan(11):createDropDown(getDockingOptionsList(inputobject, menu.subordinategroups[i].assignment), { active = active, mouseOverText = mouseovertext, height = config.mapRowHeight, startOption = function () return getDockingStartingOrder(inputobject, i, isstation) end })
	row[3].handlers.onDropDownActivated = function () menu.noupdate = true end
	row[3].handlers.onDropDownConfirmed = function (_, newdockingoption) setDockingOptions(inputobject, i, newdockingoption); menu.noupdate = false end
end

function RKN_ReactiveDocking.addReactiveDockingDockMenu(row, inputobject, i, active, mouseovertext, menu, isdockingpossible)
	if (type(active) == 'function') then
		active = active()
	end
	-- Reevaluate 'active', since vanilla just sets it false for any station and resupplier.
	menu.updateSubordinateGroupInfo(inputobject)
	if menu.subordinategroups[i] and menu.subordinategroups[i].assignment == "trade" then
		active = true
		if not GetComponentData(inputobject, "hasshipdockingbays") then
			active = false
			mouseovertext = ReadText(1026, 8604)
		elseif not isdockingpossible then
			active = false
			mouseovertext = ReadText(1026, 8605)
		end
	end
	row[7]:setColSpan(5):createDropDown(getDockingOptionsList(inputobject, menu.subordinategroups[i].assignment), { active = active, mouseOverText = mouseovertext, startOption = function () return getDockingStartingOrder(inputobject, i) end })
	row[7].handlers.onDropDownConfirmed = function (_, newdockingoption) setDockingOptions(inputobject, i, newdockingoption) end
end