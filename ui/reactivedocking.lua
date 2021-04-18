-- ffi setup 
local ffi = require("ffi") 
local C = ffi.C

local L = {}

local config = {
	subordinatedockingoptions = {
		[1] = { id = "docked",			text = ReadText(1001, 8630),	icon = "",	displayremoveoption = false },
		[2] = { id = "launched",		text = ReadText(1001, 8629),	icon = "",	displayremoveoption = false },
		[3] = { id = "reactive",		text = ReadText(181114415, 1),	icon = "",	displayremoveoption = false }
	},
	subordinatedockingoptions_nopilot = {
		[1] = { id = "docked",			text = ReadText(1001, 8630),	icon = "",	displayremoveoption = false },
		[2] = { id = "launched",		text = ReadText(1001, 8629),	icon = "",	displayremoveoption = false },
		[3] = { id = "reactive",		text = ReadText(181114415, 1),	icon = "",	displayremoveoption = false, active = false, mouseovertext = ReadText(181114415, 2) }
	},
	mapRowHeight = Helper.standardTextHeight
}

local function setReactiveDocking(inputobject, i, reactive)
	local pilotentityid = GetControlEntity(inputobject)
	local reactiveList = GetNPCBlackboard(pilotentityid, "$DockingReactive")
	if reactiveList == nil then
		reactiveList = {}
	end
	reactiveList[i] = reactive
	SetNPCBlackboard(pilotentityid, "$DockingReactive", reactiveList)
end

local function getReactiveDocking(inputobject, i)
	local pilotentityid = GetControlEntity(inputobject)
	if pilotentityid == nil then
		return false
	end
	local reactiveList = GetNPCBlackboard(pilotentityid, "$DockingReactive")
	if reactiveList == nil or reactiveList[i] == nil then
		return false
	else 
		return reactiveList[i] == 1
	end
end

local function getDockingStartingOrder(inputobject, i)
	local docked = C.ShouldSubordinateGroupDockAtCommander(inputobject, i)
	local reactive = getReactiveDocking(inputobject, i)
	if not docked and reactive then
		return "reactive"
	elseif not docked then
		return "launched"
	else
		return "docked"
	end
end

local function setDockingOptions(inputobject, i, newdockingoption)
	local docked = true
	local reactive = false
	if newdockingoption == "reactive" then
		docked = false
		reactive = true
	elseif newdockingoption == "launched" then
		docked = false
	end
	C.SetSubordinateGroupDockAtCommander(inputobject, i, docked)
	setReactiveDocking(inputobject, i, reactive)
end

local function getDockingOptionsList(inputobject)
	local pilotentityid = GetControlEntity(inputobject)
	if pilotentityid == nil then
		return config.subordinatedockingoptions_nopilot
	else
		return config.subordinatedockingoptions
	end
end
 
function L.addReactiveDockingMapMenu(row, inputobject, i, mode, active, mouseovertext, menu)
	-- Just create the vanilla button if its not a ship or a carrier
	if mode ~= "ship" or inputobject == nil or GetComponentData(inputobject, "shiptype") == "carrier" then
		row[3]:setColSpan(11):createButton({ active = active, mouseOverText = mouseovertext, height = config.mapRowHeight }):setText(function () return C.ShouldSubordinateGroupDockAtCommander(inputobject, i) and ReadText(1001, 8630) or ReadText(1001, 8629) end, { halign = "center" })
		row[3].handlers.onClick = function () return C.SetSubordinateGroupDockAtCommander(inputobject, i, not C.ShouldSubordinateGroupDockAtCommander(inputobject, i)) end
	-- Otherwise create a dropdown with the extra option
	else
		row[3]:setColSpan(11):createDropDown(getDockingOptionsList(inputobject), { active = active, mouseOverText = mouseovertext, height = config.mapRowHeight, startOption = function () return getDockingStartingOrder(inputobject, i) end })
		row[3].handlers.onDropDownActivated = function () menu.noupdate = true end
		row[3].handlers.onDropDownConfirmed = function (_, newdockingoption) setDockingOptions(inputobject, i, newdockingoption); menu.noupdate = false end
	end
end

function L.addReactiveDockingDockMenu(row, inputobject, i, active, mouseovertext, menu)
	-- Just create the vanilla button if its a carrier
	if inputobject == nil or GetComponentData(inputobject, "shiptype") == "carrier" then
		row[7]:setColSpan(5):createButton({ active = active, mouseOverText = mouseovertext }):setText(function () return C.ShouldSubordinateGroupDockAtCommander(menu.currentplayership, i) and ReadText(1001, 8630) or ReadText(1001, 8629) end, { halign = "center" })
		row[7].handlers.onClick = function () return C.SetSubordinateGroupDockAtCommander(menu.currentplayership, i, not C.ShouldSubordinateGroupDockAtCommander(menu.currentplayership, i)) end
	-- Otherwise create a dropdown with the extra option
	else
		row[7]:setColSpan(5):createDropDown(getDockingOptionsList(inputobject), { active = active, mouseOverText = mouseovertext, startOption = function () return getDockingStartingOrder(inputobject, i) end })
		row[7].handlers.onDropDownConfirmed = function (_, newdockingoption) setDockingOptions(inputobject, i, newdockingoption) end
	end
end 

return L