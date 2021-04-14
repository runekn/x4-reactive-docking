-- ffi setup 
local ffi = require("ffi") 
local C = ffi.C 
 
local Lib = require("extensions.sn_mod_support_apis.lua_library") 
local menu = {}
local dock_menu = {}
local do_menu = {}

local config = {
	subordinatedockingoptions = {
		[1] = { id = "docked",			text = ReadText(1001, 8630),	icon = "",	displayremoveoption = false },
		[2] = { id = "launched",		text = ReadText(1001, 8629),	icon = "",	displayremoveoption = false },
		[3] = { id = "reactive",		text = ReadText(181114415, 1),	icon = "",	displayremoveoption = false }
	},
	-- For setupLoadoutInfoSubmenuRows() --
	mapRowHeight = Helper.standardTextHeight,
	-------------------------------------
	-- For display() --
	modes = {
		[1] = { id = "travel",			name = ReadText(1002, 1158),	stoptext = ReadText(1002, 1159),	action = 303 },
		[2] = { id = "scan",			name = ReadText(1002, 1156),	stoptext = ReadText(1002, 1157),	action = 304 },
		[3] = { id = "scan_longrange",	name = ReadText(1002, 1155),	stoptext = ReadText(1002, 1160),	action = 305 },
		[4] = { id = "seta",			name = ReadText(1001, 1132),	stoptext = ReadText(1001, 8606),	action = 225 },
	},
	consumables = {
		{ id = "satellite",		type = "civilian",	getnum = C.GetNumAllSatellites,		getdata = C.GetAllSatellites,		callback = C.LaunchSatellite },
		{ id = "navbeacon",		type = "civilian",	getnum = C.GetNumAllNavBeacons,		getdata = C.GetAllNavBeacons,		callback = C.LaunchNavBeacon },
		{ id = "resourceprobe",	type = "civilian",	getnum = C.GetNumAllResourceProbes,	getdata = C.GetAllResourceProbes,	callback = C.LaunchResourceProbe },
		{ id = "lasertower",	type = "military",	getnum = C.GetNumAllLaserTowers,	getdata = C.GetAllLaserTowers,		callback = C.LaunchLaserTower },
		{ id = "mine",			type = "military",	getnum = C.GetNumAllMines,			getdata = C.GetAllMines,			callback = C.LaunchMine },
	},
	inactiveButtonProperties = { bgColor = Helper.defaultUnselectableButtonBackgroundColor, highlightColor = Helper.defaultUnselectableButtonHighlightColor },
	activeButtonTextProperties = { halign = "center" },
	inactiveButtonTextProperties = { halign = "center", color = Helper.color.grey },
	dronetypes = {
		{ id = "orecollector",	name = ReadText(20214, 500) },
		{ id = "gascollector",	name = ReadText(20214, 400) },
		{ id = "defence",		name = ReadText(20214, 300) },
		{ id = "transport",		name = ReadText(20214, 900) },
	}
	------------------
}
 
local function init()
	menu = Lib.Get_Egosoft_Menu("MapMenu")
	menu.setupLoadoutInfoSubmenuRows = do_menu.setupLoadoutInfoSubmenuRows
	
	dock_menu = Lib.Get_Egosoft_Menu("DockedMenu")
	dock_menu.display = do_menu.display
end 

local function setReactiveDocking(pilotentityid, i, reactive)
	local reactiveList = GetNPCBlackboard(pilotentityid, "$DockingReactive")
	if reactiveList == nil then
		reactiveList = {}
	end
	reactiveList[i] = reactive
	SetNPCBlackboard(pilotentityid, "$DockingReactive", reactiveList)
end

local function getReactiveDocking(pilotentityid, i)
	local reactiveList = GetNPCBlackboard(pilotentityid, "$DockingReactive")
	if reactiveList == nil or reactiveList[i] == nil then
		return false
	else 
		return reactiveList[i] == 1
	end
end
 
function do_menu.setupLoadoutInfoSubmenuRows(mode, inputtable, inputobject, instance) 
  local object64 = ConvertStringTo64Bit(tostring(inputobject))
	local isplayerowned, isonlineobject, isenemy, ishostile = GetComponentData(object64, "isplayerowned", "isonlineobject", "isenemy", "ishostile")
	local titlecolor = Helper.color.white
	if isplayerowned then
		titlecolor = menu.holomapcolor.playercolor
		if object64 == C.GetPlayerObjectID() then
			titlecolor = menu.holomapcolor.currentplayershipcolor
		end
	elseif isonlineobject and menu.getFilterOption("layer_think") and menu.getFilterOption("think_diplomacy_highlightvisitor") then
		titlecolor = menu.holomapcolor.visitorcolor
	elseif ishostile then
		titlecolor = menu.holomapcolor.hostilecolor
	elseif isenemy then
		titlecolor = menu.holomapcolor.enemycolor
	end

	local loadout = {}
	if mode == "ship" or mode == "station" then
		loadout = { ["component"] = {}, ["macro"] = {}, ["ware"] = {} }
		for i, upgradetype in ipairs(Helper.upgradetypes) do
			if upgradetype.supertype == "macro" then
				loadout.component[upgradetype.type] = {}
				local numslots = 0
				if C.IsComponentClass(inputobject, "defensible") then
					numslots = tonumber(C.GetNumUpgradeSlots(inputobject, "", upgradetype.type))
				end
				for j = 1, numslots do
					local current = C.GetUpgradeSlotCurrentComponent(inputobject, upgradetype.type, j)
					if current ~= 0 then
						table.insert(loadout.component[upgradetype.type], current)
					end
				end
			elseif upgradetype.supertype == "virtualmacro" then
				loadout.macro[upgradetype.type] = {}
				local numslots = tonumber(C.GetNumVirtualUpgradeSlots(inputobject, "", upgradetype.type))
				for j = 1, numslots do
					local current = ffi.string(C.GetVirtualUpgradeSlotCurrentMacro(inputobject, upgradetype.type, j))
					if current ~= "" then
						table.insert(loadout.macro[upgradetype.type], current)
					end
				end
			elseif upgradetype.supertype == "software" then
				loadout.ware[upgradetype.type] = {}
				local numslots = C.GetNumSoftwareSlots(inputobject, "")
				local buf = ffi.new("SoftwareSlot[?]", numslots)
				numslots = C.GetSoftwareSlots(buf, numslots, inputobject, "")
				for j = 0, numslots - 1 do
					local current = ffi.string(buf[j].current)
					if current ~= "" then
						table.insert(loadout.ware[upgradetype.type], current)
					end
				end
			elseif upgradetype.supertype == "ammo" then
				loadout.macro[upgradetype.type] = {}
			end
		end
	end

	local cheatsecrecy = false
	-- secrecy stuff
	local nameinfo =					cheatsecrecy or C.IsInfoUnlockedForPlayer(inputobject, "name")
	local defenceinfo_low =				cheatsecrecy or C.IsInfoUnlockedForPlayer(inputobject, "defence_level")
	local defenceinfo_high =			cheatsecrecy or C.IsInfoUnlockedForPlayer(inputobject, "defence_status")
	local unitinfo_capacity =			cheatsecrecy or C.IsInfoUnlockedForPlayer(inputobject, "units_capacity")
	local unitinfo_amount =				cheatsecrecy or C.IsInfoUnlockedForPlayer(inputobject, "units_amount")
	local unitinfo_details =			cheatsecrecy or C.IsInfoUnlockedForPlayer(inputobject, "units_details")
	local equipment_mods =				cheatsecrecy or C.IsInfoUnlockedForPlayer(inputobject, "equipment_mods")

	--- title ---
	local row = inputtable:addRow(false, {fixed = true, bgColor = Helper.defaultTitleBackgroundColor})
	row[1]:setColSpan(13):createText(ReadText(1001, 9413), Helper.headerRow1Properties)

	local objectname = Helper.unlockInfo(nameinfo, ffi.string(C.GetComponentName(inputobject)))
	-- object name
	local row = inputtable:addRow("info_focus", { fixed = true, bgColor = Helper.defaultTitleBackgroundColor })
	row[13]:createButton({ width = config.mapRowHeight, cellBGColor = Helper.color.transparent }):setIcon("menu_center_selection", { width = config.mapRowHeight, height = config.mapRowHeight, y = (Helper.headerRow1Height - config.mapRowHeight) / 2 })
	row[13].handlers.onClick = function () return C.SetFocusMapComponent(menu.holomap, menu.infoSubmenuObject, true) end
	if (mode == "ship") or (mode == "station") then
		row[1]:setBackgroundColSpan(12):setColSpan(6):createText(objectname, Helper.headerRow1Properties)
		row[1].properties.color = titlecolor
		row[7]:setColSpan(6):createText(Helper.unlockInfo(nameinfo, ffi.string(C.GetObjectIDCode(inputobject))), Helper.headerRow1Properties)
		row[7].properties.halign = "right"
		row[7].properties.color = titlecolor
	else
		row[1]:setBackgroundColSpan(12):setColSpan(12):createText(objectname, Helper.headerRow1Properties)
		row[1].properties.color = titlecolor
	end

	if mode == "ship" then
		local pilot = GetComponentData(inputobject, "assignedpilot")
		pilot = ConvertIDTo64Bit(pilot)
		local pilotname, skilltable, postname, aicommandstack, aicommand, aicommandparam, aicommandaction, aicommandactionparam = "-", {}, ReadText(1001, 4847), {}
		if pilot and IsValidComponent(pilot) then
			pilotname, skilltable, postname, aicommandstack, aicommand, aicommandparam, aicommandaction, aicommandactionparam = GetComponentData(pilot, "name", "skills", "postname", "aicommandstack", "aicommand", "aicommandparam", "aicommandaction", "aicommandactionparam")
		end

		local isbigship = C.IsComponentClass(inputobject, "ship_m") or C.IsComponentClass(inputobject, "ship_l") or C.IsComponentClass(inputobject, "ship_xl")
		-- weapon config
		if isplayerowned and (#loadout.component.weapon > 0) then
			local row = inputtable:addRow(false, { bgColor = Helper.defaultTitleBackgroundColor })
			row[1]:setColSpan(13):createText(ReadText(1001, 9409), Helper.headerRowCenteredProperties) -- Weapon Configuration
			-- subheader
			local row = inputtable:addRow(false, { bgColor = Helper.color.unselectable })
			row[3]:setColSpan(5):createText(ReadText(1001, 9410), { font = Helper.standardFontBold }) -- Primary
			row[8]:setColSpan(6):createText(ReadText(1001, 9411), { font = Helper.standardFontBold }) -- Secondary
			-- active weapon groups
			local row = inputtable:addRow("info_weaponconfig_active", { bgColor = Helper.color.transparent })
			row[2]:createText(ReadText(1001, 11218))
			for j = 1, 4 do
				row[2 + j]:createCheckBox(function () return C.GetDefensibleActiveWeaponGroup(inputobject, true) == j end, { width = config.mapRowHeight, height = config.mapRowHeight, symbol = "arrow", bgColor = function () return menu.infoWeaponGroupCheckBoxColor(inputobject, j, true) end })
				row[2 + j].handlers.onClick = function () C.SetDefensibleActiveWeaponGroup(inputobject, true, j) end
			end
			for j = 1, 4 do
				row[7 + j]:createCheckBox(function () return C.GetDefensibleActiveWeaponGroup(inputobject, false) == j end, { width = config.mapRowHeight, height = config.mapRowHeight, symbol = "arrow", bgColor = function () return menu.infoWeaponGroupCheckBoxColor(inputobject, j, false) end })
				row[7 + j].handlers.onClick = function () C.SetDefensibleActiveWeaponGroup(inputobject, false, j) end
			end
			inputtable:addEmptyRow(config.mapRowHeight / 2)
			-- weapons
			for i, gun in ipairs(loadout.component.weapon) do
				local gun = ConvertStringTo64Bit(tostring(gun))
				local numweapongroups = C.GetNumWeaponGroupsByWeapon(inputobject, gun)
				local rawweapongroups = ffi.new("UIWeaponGroup[?]", numweapongroups)
				numweapongroups = C.GetWeaponGroupsByWeapon(rawweapongroups, numweapongroups, inputobject, gun)
				local uiweapongroups = { primary = {}, secondary = {} }
				for j = 0, numweapongroups - 1 do
					-- there are two sets: primary and secondary.
					-- each set has four groups.
					-- .primary tells you if this particular weapon is active in a group in the primary or secondary group set.
					-- .idx tells you which group in that group set it is active in.
					if rawweapongroups[j].primary then
						uiweapongroups.primary[rawweapongroups[j].idx] = true
					else
						uiweapongroups.secondary[rawweapongroups[j].idx] = true
					end
					--print("primary: " .. tostring(rawweapongroups[j].primary) .. ", idx: " .. tostring(rawweapongroups[j].idx))
				end

				local row = inputtable:addRow("info_weaponconfig" .. i, { bgColor = Helper.color.transparent })
				row[2]:createText(ffi.string(C.GetComponentName(gun)))

				-- primary weapon groups
				for j = 1, 4 do
					row[2 + j]:createCheckBox(uiweapongroups.primary[j], { width = config.mapRowHeight, height = config.mapRowHeight, bgColor = function () return menu.infoWeaponGroupCheckBoxColor(inputobject, j, true) end })
					row[2 + j].handlers.onClick = function() menu.infoSetWeaponGroup(inputobject, gun, true, j, not uiweapongroups.primary[j]) end
				end

				-- secondary weapon groups
				for j = 1, 4 do
					row[7 + j]:createCheckBox(uiweapongroups.secondary[j], { width = config.mapRowHeight, height = config.mapRowHeight, bgColor = function () return menu.infoWeaponGroupCheckBoxColor(inputobject, j, false) end })
					row[7 + j].handlers.onClick = function() menu.infoSetWeaponGroup(inputobject, gun, false, j, not uiweapongroups.secondary[j]) end
				end

				if IsComponentClass(gun, "missilelauncher") then
					local nummissiletypes = C.GetNumAllMissiles(inputobject)
					local missilestoragetable = ffi.new("AmmoData[?]", nummissiletypes)
					nummissiletypes = C.GetAllMissiles(missilestoragetable, nummissiletypes, inputobject)

					local gunmacro = GetComponentData(gun, "macro")
					local dropdowndata = {}
					for j = 0, nummissiletypes-1 do
						local ammomacro = ffi.string(missilestoragetable[j].macro)
						if C.IsAmmoMacroCompatible(gunmacro, ammomacro) then
							table.insert(dropdowndata, {id = ammomacro, text = GetMacroData(ammomacro, "name"), icon = "", displayremoveoption = false})
						end
					end

					-- if the ship has no compatible ammunition in ammo storage, have the dropdown print "Out of ammo" and make it inactive.
					local currentammomacro = "empty"
					local dropdownactive = true
					if #dropdowndata == 0 then
						dropdownactive = false
						table.insert(dropdowndata, {id = "empty", text = ReadText(1001, 9412), icon = "", displayremoveoption = false})	-- Out of ammo
					else
						-- NB: currentammomacro can be null
						currentammomacro = ffi.string(C.GetCurrentAmmoOfWeapon(gun))
					end

					row = inputtable:addRow(("info_weaponconfig" .. i .. "_ammo"), { bgColor = Helper.color.transparent })
					row[2]:createText((ReadText(1001, 2800) .. ReadText(1001, 120)))	-- Ammunition, :
					row[3]:setColSpan(11):createDropDown(dropdowndata, {startOption = currentammomacro, active = dropdownactive})
					row[3].handlers.onDropDownConfirmed = function(_, newammomacro) C.SetAmmoOfWeapon(gun, newammomacro) end
				elseif pilot and IsValidComponent(pilot) and IsComponentClass(gun, "bomblauncher") then
					local numbombtypes = C.GetNumAllInventoryBombs(pilot)
					local bombstoragetable = ffi.new("AmmoData[?]", numbombtypes)
					numbombtypes = C.GetAllInventoryBombs(bombstoragetable, numbombtypes, pilot)

					local gunmacro = GetComponentData(gun, "macro")
					local dropdowndata = {}
					for j = 0, numbombtypes-1 do
						local ammomacro = ffi.string(bombstoragetable[j].macro)
						if C.IsAmmoMacroCompatible(gunmacro, ammomacro) then
							table.insert(dropdowndata, {id = ammomacro, text = GetMacroData(ammomacro, "name"), icon = "", displayremoveoption = false})
						end
					end

					-- if the ship has no compatible ammunition in ammo storage, have the dropdown print "Out of ammo" and make it inactive.
					local currentammomacro = "empty"
					local dropdownactive = true
					if #dropdowndata == 0 then
						dropdownactive = false
						table.insert(dropdowndata, {id = "empty", text = ReadText(1001, 9412), icon = "", displayremoveoption = false})	-- Out of ammo
					else
						-- NB: currentammomacro can be null
						currentammomacro = ffi.string(C.GetCurrentAmmoOfWeapon(gun))
					end

					row = inputtable:addRow(("info_weaponconfig" .. i .. "_ammo"), { bgColor = Helper.color.transparent })
					row[2]:createText((ReadText(1001, 2800) .. ReadText(1001, 120)))	-- Ammunition, :
					row[3]:setColSpan(11):createDropDown(dropdowndata, {startOption = currentammomacro, active = dropdownactive})
					row[3].handlers.onDropDownConfirmed = function(_, newammomacro) C.SetAmmoOfWeapon(gun, newammomacro) end
				end
			end
		end
	end
	if (mode == "ship") or (mode == "station") then
		-- turret behaviour
		if isplayerowned and #loadout.component.turret > 0 then
			local hasnormalturrets = false
			local hasmissileturrets = false
			local hasoperationalnormalturrets = false
			local hasoperationalmissileturrets = false

			local row = inputtable:addRow(false, { bgColor = Helper.defaultTitleBackgroundColor })
			row[1]:setColSpan(13):createText(ReadText(1001, 8612), Helper.headerRowCenteredProperties) -- Turret Behaviour
			menu.turrets = {}
			local numslots = tonumber(C.GetNumUpgradeSlots(inputobject, "", "turret"))
			for j = 1, numslots do
				local groupinfo = C.GetUpgradeSlotGroup(inputobject, "", "turret", j)
				if (ffi.string(groupinfo.path) == "..") and (ffi.string(groupinfo.group) == "") then
					local current = C.GetUpgradeSlotCurrentComponent(inputobject, "turret", j)
					if current ~= 0 then
						if (not hasmissileturrets) or (not hasnormalturrets) then
							local ismissileturret = C.IsComponentClass(current, "missileturret")
							hasmissileturrets = hasmissileturrets or ismissileturret
							hasnormalturrets = hasnormalturrets or (not ismissileturret)
						end
						table.insert(menu.turrets, current)
					end
				end
			end

			menu.turretgroups = {}
			local n = C.GetNumUpgradeGroups(inputobject, "")
			local buf = ffi.new("UpgradeGroup2[?]", n)
			n = C.GetUpgradeGroups2(buf, n, inputobject, "")
			for i = 0, n - 1 do
				if (ffi.string(buf[i].path) ~= "..") or (ffi.string(buf[i].group) ~= "") then
					local group = { context = buf[i].contextid, path = ffi.string(buf[i].path), group = ffi.string(buf[i].group) }
					local groupinfo = C.GetUpgradeGroupInfo2(inputobject, "", group.context, group.path, group.group, "turret")
					if (groupinfo.count > 0) then
						group.operational = groupinfo.operational
						group.currentmacro = ffi.string(groupinfo.currentmacro)
						group.slotsize = ffi.string(groupinfo.slotsize)
						if (not hasmissileturrets) or (not hasnormalturrets) then
							local ismissileturret = IsMacroClass(group.currentmacro, "missileturret")
							hasmissileturrets = hasmissileturrets or ismissileturret
							hasnormalturrets = hasnormalturrets or (not ismissileturret)
							if ismissileturret then
								if not hasoperationalmissileturrets then
									hasoperationalmissileturrets = group.operational > 0
								end
							else
								if not hasoperationalnormalturrets then
									hasoperationalnormalturrets = group.operational > 0
								end
							end
						end
						table.insert(menu.turretgroups, group)
					end
				end
			end

			if (#menu.turrets > 0) or (#menu.turretgroups > 0) then
				if mode == "ship" then
					local turretmodes = {
						[1] = { id = "defend",			text = ReadText(1001, 8613),	icon = "",	displayremoveoption = false },
						[2] = { id = "attackenemies",	text = ReadText(1001, 8614),	icon = "",	displayremoveoption = false },
						[3] = { id = "attackcapital",	text = ReadText(1001, 8624),	icon = "",	displayremoveoption = false },
						[4] = { id = "attackfighters",	text = ReadText(1001, 8625),	icon = "",	displayremoveoption = false },
						[5] = { id = "mining",			text = ReadText(1001, 8616),	icon = "",	displayremoveoption = false },
						[6] = { id = "missiledefence",	text = ReadText(1001, 8615),	icon = "",	displayremoveoption = false },
						[7] = { id = "autoassist",		text = ReadText(1001, 8617),	icon = "",	displayremoveoption = false },
					}

					local row = inputtable:addRow("info_turretconfig", { bgColor = Helper.color.transparent })
					row[2]:setColSpan(3):createText(ReadText(1001, 2963))
					row[5]:setColSpan(9):createDropDown(turretmodes, { startOption = function () return menu.getDropDownTurretModeOption(inputobject, "all") end })
					row[5].handlers.onDropDownConfirmed = function(_, newturretmode) menu.noupdate = false; C.SetAllTurretModes(inputobject, newturretmode) end
					row[5].handlers.onDropDownActivated = function () menu.noupdate = true end

					local row = inputtable:addRow("info_turretconfig_2", { bgColor = Helper.color.transparent })
					row[5]:setColSpan(9):createButton({ height = config.mapRowHeight }):setText(function () return menu.areTurretsArmed(inputobject) and ReadText(1001, 8631) or ReadText(1001, 8632) end, { halign = "center" })
					row[5].handlers.onClick = function () return C.SetAllTurretsArmed(inputobject, not menu.areTurretsArmed(inputobject)) end

					local dropdownCount = 1
					for i, turret in ipairs(menu.turrets) do
						inputtable:addEmptyRow(config.mapRowHeight / 2)

						local row = inputtable:addRow("info_turretconfig" .. i, { bgColor = Helper.color.transparent })
						row[2]:setColSpan(3):createText(ffi.string(C.GetComponentName(turret)))
						row[5]:setColSpan(9):createDropDown(turretmodes, { startOption = function () return menu.getDropDownTurretModeOption(turret) end })
						row[5].handlers.onDropDownConfirmed = function(_, newturretmode) menu.noupdate = false; C.SetWeaponMode(turret, newturretmode) end
						row[5].handlers.onDropDownActivated = function () menu.noupdate = true end
						dropdownCount = dropdownCount + 1
						if dropdownCount == 14 then
							inputtable.properties.maxVisibleHeight = inputtable:getFullHeight()
						end

						local row = inputtable:addRow("info_turretconfig" .. i .. "_2", { bgColor = Helper.color.transparent })
						row[5]:setColSpan(9):createButton({ height = config.mapRowHeight }):setText(function () return C.IsWeaponArmed(turret) and ReadText(1001, 8631) or ReadText(1001, 8632) end, { halign = "center" })
						row[5].handlers.onClick = function () return C.SetWeaponArmed(turret, not C.IsWeaponArmed(turret)) end
					end

					for i, group in ipairs(menu.turretgroups) do
						inputtable:addEmptyRow(config.mapRowHeight / 2)

						local name = ReadText(1001, 8023) .. " " .. i .. ((group.currentmacro ~= "") and (" (" .. menu.getSlotSizeText(group.slotsize) .. " " .. GetMacroData(group.currentmacro, "shortname") .. ")") or "")

						local row = inputtable:addRow("info_turretgroupconfig" .. i, { bgColor = Helper.color.transparent })
						row[2]:setColSpan(3):createText(name, { color = (group.operational > 0) and Helper.color.white or Helper.color.red })
						row[5]:setColSpan(9):createDropDown(turretmodes, { startOption = function () return menu.getDropDownTurretModeOption(inputobject, group.context, group.path, group.group) end, active = group.operational > 0 })
						row[5].handlers.onDropDownConfirmed = function(_, newturretmode) menu.noupdate = false; C.SetTurretGroupMode2(inputobject, group.context, group.path, group.group, newturretmode) end
						row[5].handlers.onDropDownActivated = function () menu.noupdate = true end
						dropdownCount = dropdownCount + 1
						if dropdownCount == 14 then
							inputtable.properties.maxVisibleHeight = inputtable:getFullHeight()
						end

						local row = inputtable:addRow("info_turretgroupconfig" .. i .. "_2", { bgColor = Helper.color.transparent })
						row[5]:setColSpan(9):createButton({ height = config.mapRowHeight }):setText(function () return C.IsTurretGroupArmed(inputobject, group.context, group.path, group.group) and ReadText(1001, 8631) or ReadText(1001, 8632) end, { halign = "center" })
						row[5].handlers.onClick = function () return C.SetTurretGroupArmed(inputobject, group.context, group.path, group.group, not C.IsTurretGroupArmed(inputobject, group.context, group.path, group.group)) end
					end
				elseif mode == "station" then
					local turretmodes = {
						[1] = { id = "defend",			text = ReadText(1001, 8613),	icon = "",	displayremoveoption = false },
						[2] = { id = "attackenemies",	text = ReadText(1001, 8614),	icon = "",	displayremoveoption = false },
						[3] = { id = "attackcapital",	text = ReadText(1001, 8624),	icon = "",	displayremoveoption = false },
						[4] = { id = "attackfighters",	text = ReadText(1001, 8625),	icon = "",	displayremoveoption = false },
						[5] = { id = "missiledefence",	text = ReadText(1001, 8615),	icon = "",	displayremoveoption = false },
					}

					if hasnormalturrets then
						-- non-missile
						local row = inputtable:addRow("info_turretconfig", { bgColor = Helper.color.transparent })
						row[2]:setColSpan(3):createText(ReadText(1001, 8397))
						row[5]:setColSpan(9):createDropDown(turretmodes, { startOption = function () return menu.getDropDownTurretModeOption(inputobject, "all", false) end, active = hasoperationalnormalturrets, mouseOverText = (not hasoperationalnormalturrets) and ReadText(1026, 3235) or nil })
						row[5].handlers.onDropDownConfirmed = function(_, newturretmode) menu.noupdate = false; C.SetAllNonMissileTurretModes(inputobject, newturretmode) end
						row[5].handlers.onDropDownActivated = function () menu.noupdate = true end

						local row = inputtable:addRow("info_turretconfig_2", { bgColor = Helper.color.transparent })
						row[5]:setColSpan(9):createButton({ height = config.mapRowHeight }):setText(function () return menu.areTurretsArmed(inputobject, false) and ReadText(1001, 8631) or ReadText(1001, 8632) end, { halign = "center" })
						row[5].handlers.onClick = function () return C.SetAllNonMissileTurretsArmed(inputobject, not menu.areTurretsArmed(inputobject, false)) end
					end
					if hasmissileturrets then
						-- missile
						local row = inputtable:addRow("info_turretconfig_missile", { bgColor = Helper.color.transparent })
						row[2]:setColSpan(3):createText(ReadText(1001, 9031))
						row[5]:setColSpan(9):createDropDown(turretmodes, { startOption = function () return menu.getDropDownTurretModeOption(inputobject, "all", true) end, active = hasoperationalmissileturrets, mouseOverText = (not hasoperationalnormalturrets) and ReadText(1026, 3235) or nil })
						row[5].handlers.onDropDownConfirmed = function(_, newturretmode) menu.noupdate = false; C.SetAllMissileTurretModes(inputobject, newturretmode) end
						row[5].handlers.onDropDownActivated = function () menu.noupdate = true end

						local row = inputtable:addRow("info_turretconfig_missile_2", { bgColor = Helper.color.transparent })
						row[5]:setColSpan(9):createButton({ height = config.mapRowHeight }):setText(function () return menu.areTurretsArmed(inputobject, true) and ReadText(1001, 8631) or ReadText(1001, 8632) end, { halign = "center" })
						row[5].handlers.onClick = function () return C.SetAllMissileTurretsArmed(inputobject, not menu.areTurretsArmed(inputobject, true)) end
					end
				end
			end
		end
		-- drones
		local isplayeroccupiedship = menu.infoSubmenuObject == ConvertStringTo64Bit(tostring(C.GetPlayerOccupiedShipID()))

		local unitstoragetable = C.IsComponentClass(object64, "defensible") and GetUnitStorageData(object64) or { stored = 0, capacity = 0 }
		local locunitcapacity = Helper.unlockInfo(unitinfo_capacity, tostring(unitstoragetable.capacity))
		local locunitcount = Helper.unlockInfo(unitinfo_amount, tostring(unitstoragetable.stored))
		menu.drones = {}
		local dronetypes = {
			{ id = "orecollector",	name = ReadText(20214, 500),	displayonly = true },
			{ id = "gascollector",	name = ReadText(20214, 400),	displayonly = true },
			{ id = "defence",		name = ReadText(20214, 300) },
			{ id = "transport",		name = ReadText(20214, 900) },
			{ id = "build",			name = ReadText(20214, 1000),	skipmode = true },
			{ id = "repair",		name = ReadText(20214, 1100),	skipmode = true },
		}
		for _, dronetype in ipairs(dronetypes) do
			if C.GetNumStoredUnits(inputobject, dronetype.id, false) > 0 then
				local entry
				if not dronetype.skipmode then
					entry = {
						type = dronetype.id,
						name = dronetype.name,
						current = ffi.string(C.GetCurrentDroneMode(inputobject, dronetype.id)),
						modes = {},
						displayonly = dronetype.displayonly,
					}
					local n = C.GetNumDroneModes(inputobject, dronetype.id)
					local buf = ffi.new("DroneModeInfo[?]", n)
					n = C.GetDroneModes(buf, n, inputobject, dronetype.id)
					for i = 0, n - 1 do
						local id = ffi.string(buf[i].id)
						if (id ~= "trade") or (id == entry.current) then
							table.insert(entry.modes, { id = id, text = ffi.string(buf[i].name), icon = "", displayremoveoption = false })
						end
					end
				else
					entry = {
						type = dronetype.id,
						name = dronetype.name,
					}
				end
				table.insert(menu.drones, entry)
			end
		end
		if unitstoragetable.capacity > 0 then
			-- title
			local row = inputtable:addRow(false, { bgColor = Helper.defaultTitleBackgroundColor })
			row[1]:setColSpan(13):createText(ReadText(1001, 8619), Helper.headerRowCenteredProperties)
			-- capcity
			local row = inputtable:addRow(false, { bgColor = Helper.color.unselectable })
			row[2]:createText(ReadText(1001, 8393))
			row[8]:setColSpan(6):createText(locunitcount .. " / " .. locunitcapacity, { halign = "right" })
			-- drones
			if unitinfo_details then
				for i, entry in ipairs(menu.drones) do
					if i ~= 1 then
						inputtable:addEmptyRow(config.mapRowHeight / 2)
					end
					local hasmodes = (mode == "ship") and entry.current
					-- drone name, amount and mode
					local row1 = inputtable:addRow("drone_config", { bgColor = Helper.color.transparent })
					row1[2]:createText(entry.name)
					row1[3]:setColSpan(isplayerowned and 2 or 11):createText(function () return Helper.unlockInfo(unitinfo_amount, C.GetNumStoredUnits(inputobject, entry.type, false)) end, { halign = isplayerowned and "left" or "right" })
					-- active and armed status
					local row2 = inputtable:addRow("drone_config", { bgColor = Helper.color.transparent })
					row2[2]:createText("    " .. ReadText(1001, 11229), { color = hasmodes and function () return C.IsDroneTypeArmed(inputobject, entry.type) and Helper.color.white or Helper.color.grey end or nil })
					row2[3]:setColSpan(isplayerowned and 2 or 11):createText(function () return Helper.unlockInfo(unitinfo_amount, C.GetNumUnavailableUnits(inputobject, entry.type)) end, { halign = isplayerowned and "left" or "right", color = hasmodes and function () return C.IsDroneTypeBlocked(inputobject, entry.type) and Helper.color.warningorange or (C.IsDroneTypeArmed(inputobject, entry.type) and Helper.color.white or Helper.color.grey) end or nil })
					
					-- drone mode support - disabled for mining drones, to avoid conflicts with order defined drone behaviour
					if hasmodes then
						local isblocked = C.IsDroneTypeBlocked(inputobject, entry.type)
						if isplayerowned then
							local active = (isplayeroccupiedship or (not entry.displayonly)) and (not isblocked)
							local mouseovertext = ""
							if isblocked then
								mouseovertext = ReadText(1026, 3229)
							elseif (not isplayeroccupiedship) and entry.displayonly then
								mouseovertext = ReadText(1026, 3230)
							end

							row1[5]:setColSpan(9):createDropDown(entry.modes, { startOption = function () return ffi.string(C.GetCurrentDroneMode(inputobject, entry.type)) end, active = active, mouseOverText = mouseovertext })
							row1[5].handlers.onDropDownConfirmed = function (_, newdronemode) C.SetDroneMode(inputobject, entry.type, newdronemode) end

							row2[5]:setColSpan(9):createButton({ active = active, mouseOverText = mouseovertext, height = config.mapRowHeight }):setText(function () return C.IsDroneTypeArmed(inputobject, entry.type) and ReadText(1001, 8622) or ReadText(1001, 8623) end, { halign = "center" })
							row2[5].handlers.onClick = function () return C.SetDroneTypeArmed(inputobject, entry.type, not C.IsDroneTypeArmed(inputobject, entry.type)) end
						end
					end
				end
			end
		end
		-- subordinates
		if isplayerowned then
			if C.IsComponentClass(inputobject, "controllable") then
				local subordinates = GetSubordinates(inputobject)
				local groups = {}
				local usedassignments = {}
				for _, subordinate in ipairs(subordinates) do
					local purpose, shiptype = GetComponentData(subordinate, "primarypurpose", "shiptype")
					local group = GetComponentData(subordinate, "subordinategroup")
					if group and group > 0 then
						if groups[group] then
							table.insert(groups[group].subordinates, subordinate)
							if shiptype == "resupplier" then
								groups[group].numassignableresupplyships = groups[group].numassignableresupplyships + 1
							end
							if purpose == "mine" then
								groups[group].numassignableminingships = groups[group].numassignableminingships + 1
							end
						else
							local assignment = ffi.string(C.GetSubordinateGroupAssignment(inputobject, group))
							usedassignments[assignment] = group
							groups[group] = { assignment = assignment, subordinates = { subordinate }, numassignableresupplyships = (shiptype == "resupplier") and 1 or 0, numassignableminingships = (purpose == "mine") and 1 or 0 }
						end
					end
				end

				if #subordinates > 0 then
					-- title
					local row = inputtable:addRow(false, { bgColor = Helper.defaultTitleBackgroundColor })
					row[1]:setColSpan(13):createText(ReadText(1001, 8626), Helper.headerRowCenteredProperties)

					local isstation = C.IsComponentClass(inputobject, "station")
					for i = 1, isstation and 4 or 10 do
						if groups[i] then
							local supplyactive = (groups[i].numassignableresupplyships == #groups[i].subordinates) and ((not usedassignments["supplyfleet"]) or (usedassignments["supplyfleet"] == i))
							local subordinateassignments = {
								[1] = { id = "defence",			text = ReadText(20208, 40301),	icon = "",	displayremoveoption = false },
								[2] = { id = "supplyfleet",		text = ReadText(20208, 40701),	icon = "",	displayremoveoption = false, active = supplyactive, mouseovertext = supplyactive and "" or ReadText(1026, 8601) },
							}
							if GetComponentData(inputobject, "shiptype") == "resupplier" then
								table.insert(subordinateassignments, { id = "trade",			text = ReadText(20208, 40101),	icon = "",	displayremoveoption = false })
							end

							if isstation then
								local miningactive = (groups[i].numassignableminingships == #groups[i].subordinates) and ((not usedassignments["mining"]) or (usedassignments["mining"] == i))
								table.insert(subordinateassignments, { id = "mining", text = ReadText(20208, 40201), icon = "", displayremoveoption = false, active = miningactive, mouseovertext = miningactive and "" or ReadText(1026, 8602) })
								local tradeactive = ((not usedassignments["trade"]) or (usedassignments["trade"] == i))
								table.insert(subordinateassignments, { id = "trade", text = ReadText(20208, 40101), icon = "", displayremoveoption = false, active = tradeactive, mouseovertext = tradeactive and ((groups[i].numassignableminingships > 0) and (Helper.convertColorToText(Helper.color.warningorange) .. ReadText(1026, 8607)) or "") or ReadText(1026, 7840) })
								local tradeforbuildstorageactive = (groups[i].numassignableminingships == 0) and ((not usedassignments["tradeforbuildstorage"]) or (usedassignments["tradeforbuildstorage"] == i))
								table.insert(subordinateassignments, { id = "tradeforbuildstorage", text = ReadText(20208, 40801), icon = "", displayremoveoption = false, active = tradeforbuildstorageactive, mouseovertext = tradeforbuildstorageactive and "" or ReadText(1026, 8603) })
							elseif C.IsComponentClass(inputobject, "ship") then
								table.insert(subordinateassignments, { id = "attack", text = ReadText(20208, 40901), icon = "", displayremoveoption = false })
								table.insert(subordinateassignments, { id = "interception", text = ReadText(20208, 41001), icon = "", displayremoveoption = false })
								table.insert(subordinateassignments, { id = "follow", text = ReadText(20208, 41301), icon = "", displayremoveoption = false })
								local active = true
								local mouseovertext = ""
								local buf = ffi.new("Order")
								if not C.GetDefaultOrder(buf, inputobject) then
									active = false
									mouseovertext = ReadText(1026, 8606)
								end
								table.insert(subordinateassignments, { id = "assist", text = ReadText(20208, 41201), icon = "", displayremoveoption = false, active = active, mouseovertext = mouseovertext })
							end

							local isdockingpossible = false
							for _, subordinate in ipairs(groups[i].subordinates) do
								if IsDockingPossible(subordinate, inputobject) then
									isdockingpossible = true
									break
								end
							end
							local active = true
							local mouseovertext = ""
							if not GetComponentData(inputobject, "hasshipdockingbays") then
								active = false
								mouseovertext = ReadText(1026, 8604)
							elseif not isdockingpossible then
								active = false
								mouseovertext = ReadText(1026, 8605)
							end

							local row = inputtable:addRow("subordinate_config", { bgColor = Helper.color.transparent })
							row[2]:createText(function () menu.updateSubordinateGroupInfo(inputobject); return ReadText(20401, i) .. (menu.subordinategroups[i] and (" (" .. ((not C.ShouldSubordinateGroupDockAtCommander(inputobject, i)) and ((#menu.subordinategroups[i].subordinates - menu.subordinategroups[i].numdockedatcommander) .. "/") or "") .. #menu.subordinategroups[i].subordinates ..")") or "") end, { color = isblocked and Helper.color.warningorange or nil })
							row[3]:setColSpan(11):createDropDown(subordinateassignments, { startOption = function () menu.updateSubordinateGroupInfo(inputobject); return menu.subordinategroups[i] and menu.subordinategroups[i].assignment or "" end })
							row[3].handlers.onDropDownActivated = function () menu.noupdate = true end
							row[3].handlers.onDropDownConfirmed = function (_, newassignment) C.SetSubordinateGroupAssignment(inputobject, i, newassignment); menu.noupdate = false end
							local row = inputtable:addRow("subordinate_config", { bgColor = Helper.color.transparent })
							
							-- Runekn's Docking Options edits begin here --
							-- This has been replaced
							--row[3]:setColSpan(11):createButton({ active = active, mouseOverText = mouseovertext, height = config.mapRowHeight }):setText(function () return C.ShouldSubordinateGroupDockAtCommander(inputobject, i) and ReadText(1001, 8630) or ReadText(1001, 8629) end, { halign = "center" })
							--row[3].handlers.onClick = function () return C.SetSubordinateGroupDockAtCommander(inputobject, i, not C.ShouldSubordinateGroupDockAtCommander(inputobject, i)) end
							-- With this
							local pilotentityid = GetControlEntity(inputobject)
							local shiptype = GetComponentData(inputobject, "shiptype")
							local iscarrier = shiptype == "carrier"
							if iscarrier then
								row[3]:setColSpan(11):createButton({ active = active, mouseOverText = mouseovertext, height = config.mapRowHeight }):setText(function () return C.ShouldSubordinateGroupDockAtCommander(inputobject, i) and ReadText(1001, 8630) or ReadText(1001, 8629) end, { halign = "center" })
								row[3].handlers.onClick = function () return C.SetSubordinateGroupDockAtCommander(inputobject, i, not C.ShouldSubordinateGroupDockAtCommander(inputobject, i)) end
							else
								row[3]:setColSpan(11):createDropDown(config.subordinatedockingoptions, { active = active, mouseOverText = mouseovertext, height = config.mapRowHeight, startOption = function () 
									local docked = C.ShouldSubordinateGroupDockAtCommander(inputobject, i)
									local reactive = getReactiveDocking(pilotentityid, i)
									if not docked and reactive then
										return "reactive"
									elseif not docked then
										return "launched"
									else
										return "docked"
									end
								end })
								row[3].handlers.onDropDownActivated = function () menu.noupdate = true end
								row[3].handlers.onDropDownConfirmed = function (_, newdockingoption)
									local docked = true
									local reactive = false
									if newdockingoption == "reactive" then
										docked = false
										reactive = true
									elseif newdockingoption == "launched" then
										docked = false
									end
									C.SetSubordinateGroupDockAtCommander(inputobject, i, docked)
									setReactiveDocking(pilotentityid, i, reactive)
									menu.noupdate = false
								end
							end
							-- Runekn's Docking Options edits end here
						end
					end
				end
			end
		end
		-- ammunition
		local nummissiletypes = C.GetNumAllMissiles(inputobject)
		local missilestoragetable = ffi.new("AmmoData[?]", nummissiletypes)
		nummissiletypes = C.GetAllMissiles(missilestoragetable, nummissiletypes, inputobject)
		local totalnummissiles = 0
		for i = 0, nummissiletypes - 1 do
			totalnummissiles = totalnummissiles + missilestoragetable[i].amount
		end
		local missilecapacity = 0
		if C.IsComponentClass(inputobject, "defensible") then
			missilecapacity = GetComponentData(inputobject, "missilecapacity")
		end
		local locmissilecapacity = Helper.unlockInfo(defenceinfo_low, tostring(missilecapacity))
		local locnummissiles = Helper.unlockInfo(defenceinfo_high, tostring(totalnummissiles))
		if totalnummissiles > 0 then
			-- title
			local row = inputtable:addRow(false, { bgColor = Helper.defaultTitleBackgroundColor })
			row[1]:setColSpan(12):createText(ReadText(1001, 2800), Helper.headerRowCenteredProperties) -- Ammunition
			-- capcity
			local row = inputtable:addRow(false, { bgColor = Helper.color.unselectable })
			row[2]:createText(ReadText(1001, 8393))
			row[8]:setColSpan(6):createText(locnummissiles .. " / " .. locmissilecapacity, { halign = "right" })
			if defenceinfo_high then
				for i = 0, nummissiletypes - 1 do
					local macro = ffi.string(missilestoragetable[i].macro)
					local row = inputtable:addRow({ "info_weapons", macro, inputobject }, { bgColor = Helper.color.transparent })
					row[2]:createText(GetMacroData(macro, "name"))
					row[8]:setColSpan(6):createText(tostring(missilestoragetable[i].amount), { halign = "right" })
				end
			end
		end
	end
	if mode == "ship" then
		-- countermeasures
		local numcountermeasuretypes = C.GetNumAllCountermeasures(inputobject)
		local countermeasurestoragetable = ffi.new("AmmoData[?]", numcountermeasuretypes)
		numcountermeasuretypes = C.GetAllCountermeasures(countermeasurestoragetable, numcountermeasuretypes, inputobject)
		local totalnumcountermeasures = 0
		for i = 0, numcountermeasuretypes - 1 do
			totalnumcountermeasures = totalnumcountermeasures + countermeasurestoragetable[i].amount
		end
		local countermeasurecapacity = GetComponentData(object64, "countermeasurecapacity")
		local loccountermeasurecapacity = Helper.unlockInfo(defenceinfo_low, tostring(countermeasurecapacity))
		local locnumcountermeasures = Helper.unlockInfo(defenceinfo_high, tostring(totalnumcountermeasures))
		if totalnumcountermeasures > 0 then
			-- title
			local row = inputtable:addRow(false, { bgColor = Helper.defaultTitleBackgroundColor })
			row[1]:setColSpan(13):createText(ReadText(20215, 1701), Helper.headerRowCenteredProperties) -- Countermeasures
			-- capcity
			local row = inputtable:addRow(false, { bgColor = Helper.color.unselectable })
			row[2]:createText(ReadText(1001, 8393))
			row[8]:setColSpan(6):createText(locnumcountermeasures .. " / " .. loccountermeasurecapacity, { halign = "right" })
			if defenceinfo_high then
				for i = 0, numcountermeasuretypes - 1 do
					local row = inputtable:addRow(true, { bgColor = Helper.color.transparent, interactive = false })
					row[2]:createText(GetMacroData(ffi.string(countermeasurestoragetable[i].macro), "name"))
					row[8]:setColSpan(6):createText(tostring(countermeasurestoragetable[i].amount), { halign = "right" })
				end
			end
		end
		-- deployables
		local consumables = {
			{ id = "satellite",		type = "civilian",	getnum = C.GetNumAllSatellites,		getdata = C.GetAllSatellites,		callback = C.LaunchSatellite },
			{ id = "navbeacon",		type = "civilian",	getnum = C.GetNumAllNavBeacons,		getdata = C.GetAllNavBeacons,		callback = C.LaunchNavBeacon },
			{ id = "resourceprobe",	type = "civilian",	getnum = C.GetNumAllResourceProbes,	getdata = C.GetAllResourceProbes,	callback = C.LaunchResourceProbe },
			{ id = "lasertower",	type = "military",	getnum = C.GetNumAllLaserTowers,	getdata = C.GetAllLaserTowers,		callback = C.LaunchLaserTower },
			{ id = "mine",			type = "military",	getnum = C.GetNumAllMines,			getdata = C.GetAllMines,			callback = C.LaunchMine },
		}
		local totalnumdeployables = 0
		local consumabledata = {}
		for _, entry in ipairs(consumables) do
			local n = entry.getnum(inputobject)
			local buf = ffi.new("AmmoData[?]", n)
			n = entry.getdata(buf, n, inputobject)
			consumabledata[entry.id] = {}
			for i = 0, n - 1 do
				table.insert(consumabledata[entry.id], { macro = ffi.string(buf[i].macro), name = GetMacroData(ffi.string(buf[i].macro), "name"), amount = buf[i].amount, capacity = buf[i].capacity })
				totalnumdeployables = totalnumdeployables + buf[i].amount
			end
		end
		local deployablecapacity = C.GetDefensibleDeployableCapacity(inputobject)
		local printednumdeployables = Helper.unlockInfo(defenceinfo_low, tostring(totalnumdeployables))
		local printeddeployablecapacity = Helper.unlockInfo(defenceinfo_low, tostring(deployablecapacity))
		if totalnumdeployables > 0 then
			-- title
			local row = inputtable:addRow(false, { bgColor = Helper.defaultTitleBackgroundColor })
			row[1]:setColSpan(13):createText(ReadText(1001, 1332), Helper.headerRowCenteredProperties) -- Deployables
			-- capcity
			local row = inputtable:addRow(false, { bgColor = Helper.color.unselectable })
			row[2]:createText(ReadText(1001, 8393))
			row[8]:setColSpan(6):createText(printednumdeployables .. " / " .. printeddeployablecapacity, { halign = "right" })
			if defenceinfo_high then
				for _, entry in ipairs(consumables) do
					if #consumabledata[entry.id] > 0 then
						for _, data in ipairs(consumabledata[entry.id]) do
							local row = inputtable:addRow({ "info_deploy", data.macro, inputobject }, { bgColor = Helper.color.transparent })
							row[2]:createText(data.name)
							row[8]:setColSpan(6):createText(data.amount, { halign = "right" })
						end
					end
				end
				if isplayerowned then
					-- deploy
					local row = inputtable:addRow("info_deploy", { bgColor = Helper.color.transparent })
					row[3]:setColSpan(11):createButton({ height = config.mapRowHeight, active = function () return next(menu.infoTablePersistentData[instance].macrostolaunch) ~= nil end }):setText(ReadText(1001, 8390), { halign = "center" })
					row[3].handlers.onClick = function () return menu.buttonDeploy(instance) end
				end
			end
		end
	end
	if (mode == "ship") or (mode == "station") then
		-- loadout
		if (#loadout.component.weapon > 0) or (#loadout.component.turret > 0) or (#loadout.component.shield > 0) or (#loadout.component.engine > 0) or (#loadout.macro.thruster > 0) or (#loadout.ware.software > 0) then
			if defenceinfo_high then
				local hasshown = false
				-- title
				local row = inputtable:addRow(false, { bgColor = Helper.defaultTitleBackgroundColor })
				row[1]:setColSpan(13):createText(ReadText(1001, 9413), Helper.headerRowCenteredProperties) -- Loadout
				local row = inputtable:addRow(false, { bgColor = Helper.color.unselectable })
				row[2]:setColSpan(5):createText(ReadText(1001, 7935), { font = Helper.standardFontBold })
				row[7]:setColSpan(4):createText(ReadText(1001, 1311), { font = Helper.standardFontBold, halign = "right" })
				row[11]:setColSpan(3):createText(ReadText(1001, 12), { font = Helper.standardFontBold, halign = "right" })

				inputtable:addEmptyRow(config.mapRowHeight / 2)

				local macroequipment = {
					{ type = "weapon", encyclopedia = "info_weapon" },
					{ type = "turret", encyclopedia = "info_weapon" },
					{ type = "shield", encyclopedia = "info_equipment" },
					{ type = "engine", encyclopedia = "info_equipment" },
				}
				for _, entry in ipairs(macroequipment) do
					if #loadout.component[entry.type] > 0 then
						if hasshown then
							inputtable:addEmptyRow(config.mapRowHeight / 2)
						end
						hasshown = true
						local locmacros = menu.infoCombineLoadoutComponents(loadout.component[entry.type])
						for macro, data in pairs(locmacros) do
							local row = inputtable:addRow({ entry.encyclopedia, macro, inputobject }, { bgColor = Helper.color.transparent })
							row[2]:setColSpan(5):createText(GetMacroData(macro, "name"))
							row[7]:setColSpan(4):createText(data.count .. " / " .. data.count + data.construction, { halign = "right" })
							local shieldpercent = data.shieldpercent
							local hullpercent = data.hullpercent
							if data.count > 0 then
								shieldpercent = shieldpercent / data.count
								hullpercent = hullpercent / data.count
							end
							row[11]:setColSpan(3):createShieldHullBar(shieldpercent, hullpercent, { scaling = false, width = row[11]:getColSpanWidth() / 2, x = row[11]:getColSpanWidth() / 4 })

							AddKnownItem(GetMacroData(macro, "infolibrary"), macro)
						end
					end
				end

				if #loadout.macro.thruster > 0 then
					if hasshown then
						inputtable:addEmptyRow(config.mapRowHeight / 2)
					end
					hasshown = true
					-- ships normally only have 1 set of thrusters. in case a ship has more, this will list all of them.
					for i, val in ipairs(loadout.macro.thruster) do
						local row = inputtable:addRow({ "info_equipment", macro, inputobject }, { bgColor = Helper.color.transparent })
						row[2]:setColSpan(12):createText(GetMacroData(val, "name"))

						AddKnownItem(GetMacroData(val, "infolibrary"), val)
					end
				end
				if #loadout.ware.software > 0 then
					if hasshown then
						inputtable:addEmptyRow(config.mapRowHeight / 2)
					end
					hasshown = true
					for i, val in ipairs(loadout.ware.software) do
						local row = inputtable:addRow({ "info_software", val, inputobject }, { bgColor = Helper.color.transparent })
						row[2]:setColSpan(12):createText(GetWareData(val, "name"))

						AddKnownItem("software", val)
					end
				end
			else
				local row = inputtable:addRow(false, { bgColor = Helper.color.unselectable })
				row[2]:setColSpan(12):createText(ReadText(1001, 3210))
			end
		end
	end
	if mode == "ship" then
		-- mods
		-- title
		local row = inputtable:addRow(false, { bgColor = Helper.defaultTitleBackgroundColor })
		row[1]:setColSpan(13):createText(ReadText(1001, 8031), Helper.headerRowCenteredProperties)
		if equipment_mods and GetComponentData(object64, "hasanymod") then
			local hasshown = false
			-- chassis
			local hasinstalledmod, installedmod = Helper.getInstalledModInfo("ship", inputobject)
			if hasinstalledmod then
				if hasshown then
					inputtable:addEmptyRow(config.mapRowHeight / 2)
				end
				hasshown = true
				row = menu.addEquipmentModInfoRow(inputtable, "ship", installedmod, ReadText(1001, 8008))
			end
			-- weapon
			for i, weapon in ipairs(loadout.component.weapon) do
				local hasinstalledmod, installedmod = Helper.getInstalledModInfo("weapon", weapon)
				if hasinstalledmod then
					if hasshown then
						inputtable:addEmptyRow(config.mapRowHeight / 2)
					end
					hasshown = true
					row = menu.addEquipmentModInfoRow(inputtable, "weapon", installedmod, ffi.string(C.GetComponentName(weapon)))
				end
			end
			-- turret
			for i, turret in ipairs(loadout.component.turret) do
				local hasinstalledmod, installedmod = Helper.getInstalledModInfo("turret", turret)
				if hasinstalledmod then
					if hasshown then
						inputtable:addEmptyRow(config.mapRowHeight / 2)
					end
					hasshown = true
					row = menu.addEquipmentModInfoRow(inputtable, "weapon", installedmod, ffi.string(C.GetComponentName(turret)))
				end
			end
			-- shield
			local shieldgroups = {}
			local n = C.GetNumShieldGroups(inputobject)
			local buf = ffi.new("ShieldGroup[?]", n)
			n = C.GetShieldGroups(buf, n, inputobject)
			for i = 0, n - 1 do
				local entry = {}
				entry.context = buf[i].context
				entry.group = ffi.string(buf[i].group)
				entry.component = buf[i].component

				table.insert(shieldgroups, entry)
			end
			for i, entry in ipairs(shieldgroups) do
				if (entry.context == inputobject) and (entry.group == "") then
					shieldgroups.hasMainGroup = true
					-- force maingroup to first index
					table.insert(shieldgroups, 1, entry)
					table.remove(shieldgroups, i + 1)
					break
				end
			end
			for i, shieldgroupdata in ipairs(shieldgroups) do
				local hasinstalledmod, installedmod = Helper.getInstalledModInfo("shield", inputobject, shieldgroupdata.context, shieldgroupdata.group)
				if hasinstalledmod then
					local name = GetMacroData(GetComponentData(ConvertStringTo64Bit(tostring(shieldgroupdata.component)), "macro"), "name")
					if (i == 1) and shieldgroups.hasMainGroup then
						name = ReadText(1001, 8044)
					end
					if hasshown then
						inputtable:addEmptyRow(config.mapRowHeight / 2)
					end
					hasshown = true
					row = menu.addEquipmentModInfoRow(inputtable, "shield", installedmod, name)
				end
			end
			-- engine
			local hasinstalledmod, installedmod = Helper.getInstalledModInfo("engine", inputobject)
			if hasinstalledmod then
				if hasshown then
					inputtable:addEmptyRow(config.mapRowHeight / 2)
				end
				hasshown = true
				row = menu.addEquipmentModInfoRow(inputtable, "engine", installedmod, ffi.string(C.GetComponentName(loadout.component.engine[1])))
			end
		else
			local row = inputtable:addRow(false, { bgColor = Helper.color.unselectable })
			row[2]:setColSpan(12):createText(Helper.unlockInfo(equipment_mods, ReadText(1001, 8394)))
		end
	end
	if mode == "none" then
		local row = inputtable:addRow(false, { bgColor = Helper.color.unselectable })
		row[2]:setColSpan(12):createText(ReadText(1001, 6526))
	end
end


function do_menu.display()
	local menu = dock_menu
	Helper.removeAllWidgetScripts(menu)

	local width = Helper.viewWidth
	local height = Helper.viewHeight
	local xoffset = 0
	local yoffset = 0

	menu.frame = Helper.createFrameHandle(menu, { width = width, x = xoffset, y = yoffset, backgroundID = "solid", backgroundColor = Helper.color.semitransparent, standardButtons = ((menu.mode == "docked") and (menu.currentplayership ~= 0)) and {} or { close = true, back = true } })

	menu.createTopLevel(menu.frame)

	local table_topleft, table_header, table_button, row

	local isdocked = (menu.currentplayership ~= 0) and GetComponentData(menu.currentplayership, "isdocked")
	local ownericon, owner, shiptrader, isdock, canbuildships, isplayerowned, issupplyship, canhavetradeoffers = GetComponentData(menu.currentcontainer, "ownericon", "owner", "shiptrader", "isdock", "canbuildships", "isplayerowned", "issupplyship", "canhavetradeoffers")
	local cantrade = canhavetradeoffers and isdock
	local canwareexchange = cantrade and isplayerowned
	--NB: equipment docks currently do not have ship traders
	local dockedplayerships = {}
	Helper.ffiVLA(dockedplayerships, "UniverseID", C.GetNumDockedShips, C.GetDockedShips, menu.currentcontainer, "player")
	local canequip = false
	local cansupply = false
	for _, ship in ipairs(dockedplayerships) do
		if C.CanContainerEquipShip(menu.currentcontainer, ship) then
			canequip = true
		end
		if isplayerowned and C.CanContainerSupplyShip(menu.currentcontainer, ship) then
			cansupply = true
		end
	end
	local canmodifyship = (shiptrader ~= nil) and (canequip or cansupply) and isdock
	local canbuyship = (shiptrader ~= nil) and canbuildships and isdock
	--print("cantrade: " .. tostring(cantrade) .. ", canbuyship: " .. tostring(canbuyship) .. ", canmodifyship: " .. tostring(canmodifyship))

	width = (width / 3) - Helper.borderSize

	-- set up a new table
	table_topleft = menu.frame:addTable(1, { tabOrder = 0, width = Helper.playerInfoConfig.width, height = Helper.playerInfoConfig.height, x = Helper.playerInfoConfig.offsetX, y = Helper.playerInfoConfig.offsetY, scaling = false })

	row = table_topleft:addRow(false, { fixed = true, bgColor = Helper.color.transparent60 })
	local icon = row[1]:createIcon(function () local logo = C.GetCurrentPlayerLogo(); return ffi.string(logo.icon) end, { width = Helper.playerInfoConfig.height, height = Helper.playerInfoConfig.height, color = Helper.getPlayerLogoColor })

	local fontsize = Helper.scaleFont(Helper.standardFont, Helper.standardFontSize)
	local textheight = math.ceil(C.GetTextHeight(Helper.playerInfoConfigTextLeft(), Helper.standardFont, Helper.playerInfoConfig.fontsize, Helper.playerInfoConfig.width - Helper.playerInfoConfig.height - Helper.borderSize))
	icon:setText(Helper.playerInfoConfigTextLeft,	{ fontsize = Helper.playerInfoConfig.fontsize, halign = "left",  x = Helper.playerInfoConfig.height + Helper.borderSize, y = (Helper.playerInfoConfig.height - textheight) / 2 })
	icon:setText2(Helper.playerInfoConfigTextRight,	{ fontsize = Helper.playerInfoConfig.fontsize, halign = "right", x = Helper.borderSize,          y = (Helper.playerInfoConfig.height - textheight) / 2 })

	local xoffset = (Helper.viewWidth - width) / 2
	local yoffset = 25

	table_header = menu.frame:addTable(11, { tabOrder = 1, width = width, x = xoffset, y = menu.topLevelOffsetY + Helper.borderSize + yoffset, highlightMode = "off" })
	table_header:setColWidth(1, math.floor((width - 2 * Helper.borderSize) / 3), false)
	table_header:setColWidth(3, Helper.standardTextHeight)
	table_header:setColWidth(4, Helper.standardTextHeight)
	table_header:setColWidth(5, Helper.standardTextHeight)
	table_header:setColWidth(6, Helper.standardTextHeight)
	table_header:setColWidth(8, Helper.standardTextHeight)
	table_header:setColWidth(9, Helper.standardTextHeight)
	table_header:setColWidth(10, Helper.standardTextHeight)
	table_header:setColWidth(11, Helper.standardTextHeight)
	table_header:setDefaultColSpan(1, 1)
	table_header:setDefaultColSpan(2, 5)
	table_header:setDefaultColSpan(7, 5)
	table_header:setDefaultBackgroundColSpan(1, 11)

	local row = table_header:addRow(false, { fixed = true, bgColor = Helper.color.transparent })
	local color = Helper.color.white
	if isplayerowned then
		if menu.currentcontainer == C.GetPlayerObjectID() then
			color = Helper.color.playergreen
		else
			color = Helper.color.green
		end
	end
	row[1]:setColSpan(11):createText(menu.currentcontainer and ffi.string(C.GetComponentName(menu.currentcontainer)) or "", Helper.headerRowCenteredProperties)
	row[1].properties.color = color

	height = Helper.scaleY(Helper.standardTextHeight)

	local row = table_header:addRow(false, { fixed = true, bgColor = Helper.color.unselectable })
	if menu.mode == "cockpit" then
		row[2]:createText(ffi.string(C.GetObjectIDCode(menu.currentcontainer)), { halign = "center", color = color })
	else
		row[1]:createIcon(ownericon, { width = height, height = height, x = row[1]:getWidth() - height, scaling = false })
		row[2]:createText(function() return GetComponentData(menu.currentcontainer, "ownername") end, { halign = "center" })
		row[7]:createText(function() return "[" .. GetUIRelation(GetComponentData(menu.currentcontainer, "owner")) .. "]" end, { halign = "left" })
	end

	table_header:addEmptyRow(yoffset)

	if menu.mode == "cockpit" then
		local row = table_header:addRow("buttonRow1", { bgColor = Helper.color.transparent, fixed = true })
		row[1]:createButton(config.inactiveButtonProperties):setText("", config.inactiveButtonTextProperties)	-- dummy
		local active = (menu.currentplayership ~= 0) and C.CanPlayerStandUp()
		row[2]:createButton(active and { mouseOverText = GetLocalizedKeyName("action", 277), helpOverlayID = "docked_getup", helpOverlayText = " ", helpOverlayHighlightOnly = true } or config.inactiveButtonProperties):setText(ReadText(1002, 20014), active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- "Get Up"
		if active then
			row[2].handlers.onClick = menu.buttonGetUp
		end
		row[7]:createButton({ mouseOverText = GetLocalizedKeyName("action", 316), helpOverlayID = "docked_shipinformation", helpOverlayText = " ", helpOverlayHighlightOnly = true }):setText(ReadText(1001, 8602), { halign = "center" })	-- "Ship Information"
		row[7].handlers.onClick = menu.buttonShipInfo

		local row = table_header:addRow("buttonRow3", { bgColor = Helper.color.transparent, fixed = true })
		local currentactivity = GetPlayerActivity()
		if currentactivity ~= "none" then
			local text = ""
			for _, entry in ipairs(config.modes) do
				if entry.id == currentactivity then
					text = entry.stoptext
					break
				end
			end
			local active = menu.currentplayership ~= 0
			row[2]:createButton(active and {helpOverlayID = "docked_stopmode", helpOverlayText = " ", helpOverlayHighlightOnly = true } or config.inactiveButtonProperties):setText(text, active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- "Stop Mode"
			if active then
				row[2].handlers.onClick = menu.buttonStopMode
				row[2].properties.uiTriggerID = "stopmode"
			end
		else
			local active = menu.currentplayership ~= 0
			local modes = {}
			if active then
				for _, entry in ipairs(config.modes) do
					local active = true
					local visible = true
					if entry.id == "travel" then
						active = (menu.currentplayership ~= 0) and C.CanStartTravelMode(menu.currentplayership)
					elseif entry.id == "seta" then
						visible = C.CanActivateSeta(false)
					end
					local mouseovertext = GetLocalizedKeyName("action", entry.action)
					if visible then
						table.insert(modes, { id = entry.id, text = entry.name, icon = "", displayremoveoption = false, active = active, mouseovertext = mouseovertext })
					end
				end
			end
			row[2]:createDropDown(modes, {
				helpOverlayID = "docked_modes",		
				helpOverlayText = " ", 
				helpOverlayHighlightOnly = true, 
				height = Helper.standardButtonHeight,
				startOption = "",
				textOverride = ReadText(1002, 1001),
				bgColor = active and Helper.defaultButtonBackgroundColor or Helper.defaultUnselectableButtonBackgroundColor,
				highlightColor = active and Helper.defaultButtonHighlightColor or Helper.defaultUnselectableButtonHighlightColor
			}):setTextProperties(active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- Modes
			if active then
				row[2].handlers.onDropDownConfirmed = menu.dropdownMode
				row[2].properties.uiTriggerID = "startmode"
			end
		end
		local civilian, military, isinhighway = {}, {}, false
		if menu.currentplayership ~= 0 then
			for _, consumabledata in ipairs(config.consumables) do
				local numconsumable = consumabledata.getnum(menu.currentplayership)
				if numconsumable > 0 then
					local consumables = ffi.new("AmmoData[?]", numconsumable)
					numconsumable = consumabledata.getdata(consumables, numconsumable, menu.currentplayership)
					for j = 0, numconsumable - 1 do
						if consumables[j].amount > 0 then
							local macro = ffi.string(consumables[j].macro)
							if consumabledata.type == "civilian" then
								table.insert(civilian, { id = consumabledata.id .. ":" .. macro, text = GetMacroData(macro, "name"), text2 = "(" .. consumables[j].amount .. ")", icon = "", displayremoveoption = false })
							else
								table.insert(military, { id = consumabledata.id .. ":" .. macro, text = GetMacroData(macro, "name"), text2 = "(" .. consumables[j].amount .. ")", icon = "", displayremoveoption = false })
							end
						end
					end
				end
			end
			isinhighway = C.GetContextByClass(menu.currentplayership, "highway", false) ~= 0
		end
		local active = (#civilian > 0) and (not isinhighway)
		local mouseovertext = ""
		if #civilian == 0 then
			mouseovertext = ReadText(1026, 7818)
		elseif isinhighway then
			mouseovertext = ReadText(1026, 7845)
		end
		row[1]:createDropDown(civilian, {
			helpOverlayID = "docked_deploy_civ",
			helpOverlayText = " ",
			helpOverlayHighlightOnly = true,
			height = Helper.standardButtonHeight,
			startOption = "",
			textOverride = ReadText(1001, 8607),
			text2Override = " ",
			bgColor = active and Helper.defaultButtonBackgroundColor or Helper.defaultUnselectableButtonBackgroundColor,
			highlightColor = active and Helper.defaultButtonHighlightColor or Helper.defaultUnselectableButtonHighlightColor,
			mouseOverText = mouseovertext,
		}):setTextProperties(active and config.activeButtonTextProperties or config.inactiveButtonTextProperties):setText2Properties(active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- Deploy Civilian
		row[1].properties.text2.halign = "right"
		row[1].properties.text2.x = Helper.standardTextOffsetx
		if active then
			row[1].handlers.onDropDownConfirmed = menu.dropdownDeploy
		end
		local active = (#military > 0) and (not isinhighway)
		local mouseovertext = ""
		if #military == 0 then
			mouseovertext = ReadText(1026, 7819)
		elseif isinhighway then
			mouseovertext = ReadText(1026, 7845)
		end
		row[7]:createDropDown(military, {
			helpOverlayID = "docked_deploy_mil",
			helpOverlayText = " ",
			helpOverlayHighlightOnly = true,
			height = Helper.standardButtonHeight,
			startOption = "",
			textOverride = ReadText(1001, 8608),
			text2Override = " ",
			bgColor = active and Helper.defaultButtonBackgroundColor or Helper.defaultUnselectableButtonBackgroundColor,
			highlightColor = active and Helper.defaultButtonHighlightColor or Helper.defaultUnselectableButtonHighlightColor,
			mouseOverText = mouseovertext,
		}):setTextProperties(active and config.activeButtonTextProperties or config.inactiveButtonTextProperties):setText2Properties(active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- Deploy Military
		row[7].properties.text2.halign = "right"
		row[7].properties.text2.x = Helper.standardTextOffsetx
		if active then
			row[7].handlers.onDropDownConfirmed = menu.dropdownDeploy
		end

		local row = table_header:addRow("buttonRow2", { bgColor = Helper.color.transparent, fixed = true })
		local active = (menu.currentplayership ~= 0) and C.HasShipFlightAssist(menu.currentplayership)
		row[1]:createButton(active and { mouseOverText = GetLocalizedKeyName("action", 221), helpOverlayID = "docked_flightassist", helpOverlayText = " ", helpOverlayHighlightOnly = true } or config.inactiveButtonProperties):setText(ReadText(1001, 8604), active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- "Flight Assist"
		if active then
			row[1].handlers.onClick = menu.buttonFlightAssist
		end
		row[2]:createButton({ bgColor = menu.dockButtonBGColor, highlightColor = menu.dockButtonHighlightColor, helpOverlayID = "docked_dock", helpOverlayText = " ", helpOverlayHighlightOnly = true }):setText(ReadText(1001, 8605), { halign = "center", color = menu.dockButtonTextColor })	-- "Dock"
		row[2].properties.mouseOverText = GetLocalizedKeyName("action", 175)
		row[2].handlers.onClick = menu.buttonDock
		local active = (menu.currentplayership ~= 0) and C.ToggleAutoPilot(true)
		row[7]:createButton(active and { mouseOverText = GetLocalizedKeyName("action", 179), helpOverlayID = "docked_autopilot", helpOverlayText = " ", helpOverlayHighlightOnly = true } or config.inactiveButtonProperties):setText(ReadText(1001, 8603), active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- "Autopilot"
		if active then
			row[7].handlers.onClick = menu.buttonAutoPilot
		end

		if menu.currentplayership ~= 0 then
			local weapons = {}
			local numslots = tonumber(C.GetNumUpgradeSlots(menu.currentplayership, "", "weapon"))
			for j = 1, numslots do
				local current = C.GetUpgradeSlotCurrentComponent(menu.currentplayership, "weapon", j)
				if current ~= 0 then
					table.insert(weapons, current)
				end
			end
			local pilot = GetComponentData(menu.currentplayership, "assignedpilot")
			menu.currentammo = {}
			if #weapons > 0 then
				table_header:addEmptyRow(yoffset)

				local titlerow = table_header:addRow(false, { bgColor = Helper.color.transparent })
				titlerow[1]:setColSpan(11):createText(ReadText(1001, 9409), Helper.headerRowCenteredProperties)
				titlerow[1].properties.helpOverlayID = "docked_weaponconfig"
				titlerow[1].properties.helpOverlayText = " "
				titlerow[1].properties.helpOverlayHeight = titlerow:getHeight()
				titlerow[1].properties.helpOverlayHighlightOnly = true
				titlerow[1].properties.helpOverlayScaling = false

				local row = table_header:addRow(false, { bgColor = Helper.color.unselectable })
				row[2]:createText(ReadText(1001, 9410), { font = Helper.standardFontBold, halign = "center" })
				row[7]:createText(ReadText(1001, 9411), { font = Helper.standardFontBold, halign = "center" })
				titlerow[1].properties.helpOverlayHeight = titlerow[1].properties.helpOverlayHeight + row:getHeight() + Helper.borderSize

				-- active weapon groups
				local row = table_header:addRow("weaponconfig_active", { bgColor = Helper.color.transparent })
				row[1]:setColSpan(2):createText(ReadText(1001, 11218))
				row[7]:setColSpan(1)
				for j = 1, 4 do
					row[2 + j]:createCheckBox(function () return C.GetDefensibleActiveWeaponGroup(menu.currentplayership, true) == j end, { width = Helper.standardTextHeight, height = Helper.standardTextHeight, symbol = "arrow", bgColor = function () return menu.checkboxWeaponGroupColor(j, true) end })
					row[2 + j].handlers.onClick = function () C.SetDefensibleActiveWeaponGroup(menu.currentplayership, true, j) end
				end
				for j = 1, 4 do
					row[7 + j]:createCheckBox(function () return C.GetDefensibleActiveWeaponGroup(menu.currentplayership, false) == j end, { width = Helper.standardTextHeight, height = Helper.standardTextHeight, symbol = "arrow", bgColor = function () return menu.checkboxWeaponGroupColor(j, false) end })
					row[7 + j].handlers.onClick = function () C.SetDefensibleActiveWeaponGroup(menu.currentplayership, false, j) end
				end
				table_header:addEmptyRow(Helper.standardTextHeight / 2)

				for _, weapon in ipairs(weapons) do
					local numweapongroups = C.GetNumWeaponGroupsByWeapon(menu.currentplayership, weapon)
					local rawweapongroups = ffi.new("UIWeaponGroup[?]", numweapongroups)
					numweapongroups = C.GetWeaponGroupsByWeapon(rawweapongroups, numweapongroups, menu.currentplayership, weapon)
					local uiweapongroups = { primary = {}, secondary = {} }
					for j = 0, numweapongroups-1 do
						if rawweapongroups[j].primary then
							uiweapongroups.primary[rawweapongroups[j].idx] = true
						else
							uiweapongroups.secondary[rawweapongroups[j].idx] = true
						end
					end

					local row = table_header:addRow("weaponconfig", { bgColor = Helper.color.transparent })
					row[1]:setColSpan(2):createText(ffi.string(C.GetComponentName(weapon)))
					row[7]:setColSpan(1)
					for j = 1, 4 do
						row[2 + j]:createCheckBox(uiweapongroups.primary[j], { width = Helper.standardTextHeight, height = Helper.standardTextHeight, bgColor = function () return menu.checkboxWeaponGroupColor(j, true) end })
						row[2 + j].handlers.onClick = function() menu.checkboxWeaponGroup(menu.currentplayership, weapon, true, j, not uiweapongroups.primary[j]) end
					end
					for j = 1, 4 do
						row[7 + j]:createCheckBox(uiweapongroups.secondary[j], { width = Helper.standardTextHeight, height = Helper.standardTextHeight, bgColor = function () return menu.checkboxWeaponGroupColor(j, false) end })
						row[7 + j].handlers.onClick = function() menu.checkboxWeaponGroup(menu.currentplayership, weapon, false, j, not uiweapongroups.secondary[j]) end
					end
					titlerow[1].properties.helpOverlayHeight = titlerow[1].properties.helpOverlayHeight + row:getHeight() + Helper.borderSize

					if C.IsComponentClass(weapon, "missilelauncher") then
						local nummissiletypes = C.GetNumAllMissiles(menu.currentplayership)
						local missilestoragetable = ffi.new("AmmoData[?]", nummissiletypes)
						nummissiletypes = C.GetAllMissiles(missilestoragetable, nummissiletypes, menu.currentplayership)

						local weaponmacro = GetComponentData(ConvertStringTo64Bit(tostring(weapon)), "macro")
						local dropdowndata = {}
						for j = 0, nummissiletypes-1 do
							local ammomacro = ffi.string(missilestoragetable[j].macro)
							if C.IsAmmoMacroCompatible(weaponmacro, ammomacro) then
								table.insert(dropdowndata, {id = ammomacro, text = GetMacroData(ammomacro, "name"), icon = "", displayremoveoption = false})
							end
						end

						-- if the ship has no compatible ammunition in ammo storage, have the dropdown print "Out of ammo" and make it inactive.
						menu.currentammo[tostring(weapon)] = "empty"
						local dropdownactive = true
						if #dropdowndata == 0 then
							dropdownactive = false
							table.insert(dropdowndata, {id = "empty", text = ReadText(1001, 9412), icon = "", displayremoveoption = false})	-- Out of ammo
						else
							-- NB: currentammomacro can be null
							menu.currentammo[tostring(weapon)] = ffi.string(C.GetCurrentAmmoOfWeapon(weapon))
						end

						local row = table_header:addRow("ammo_config", { bgColor = Helper.color.transparent })
						row[1]:createText("    " .. ReadText(1001, 2800) .. ReadText(1001, 120))	-- Ammunition, :
						row[2]:setColSpan(10):createDropDown(dropdowndata, { startOption = function () return menu.getDropDownOption(weapon) end, active = dropdownactive })
						row[2].handlers.onDropDownConfirmed = function(_, newammomacro) C.SetAmmoOfWeapon(weapon, newammomacro) end
						titlerow[1].properties.helpOverlayHeight = titlerow[1].properties.helpOverlayHeight + row:getHeight() + Helper.borderSize
					elseif pilot and C.IsComponentClass(weapon, "bomblauncher") then
						local pilot64 = ConvertIDTo64Bit(pilot)
						local numbombtypes = C.GetNumAllInventoryBombs(pilot64)
						local bombstoragetable = ffi.new("AmmoData[?]", numbombtypes)
						numbombtypes = C.GetAllInventoryBombs(bombstoragetable, numbombtypes, pilot64)

						local weaponmacro = GetComponentData(ConvertStringTo64Bit(tostring(weapon)), "macro")
						local dropdowndata = {}
						for j = 0, numbombtypes-1 do
							local ammomacro = ffi.string(bombstoragetable[j].macro)
							if C.IsAmmoMacroCompatible(weaponmacro, ammomacro) then
								table.insert(dropdowndata, { id = ammomacro, text = GetMacroData(ammomacro, "name"), icon = "", displayremoveoption = false })
							end
						end

						-- if the ship has no compatible ammunition in ammo storage, have the dropdown print "Out of ammo" and make it inactive.
						menu.currentammo[tostring(weapon)] = "empty"
						local dropdownactive = true
						if #dropdowndata == 0 then
							dropdownactive = false
							table.insert(dropdowndata, { id = "empty", text = ReadText(1001, 9412), icon = "", displayremoveoption = false })	-- Out of ammo
						else
							-- NB: currentammomacro can be null
							menu.currentammo[tostring(weapon)] = ffi.string(C.GetCurrentAmmoOfWeapon(weapon))
						end

						local row = table_header:addRow("ammo_config", { bgColor = Helper.color.transparent })
						row[1]:createText("    " .. ReadText(1001, 2800) .. ReadText(1001, 120))	-- Ammunition, :
						row[2]:setColSpan(10):createDropDown(dropdowndata, { startOption = function () return menu.getDropDownOption(weapon) end, active = dropdownactive })
						row[2].handlers.onDropDownConfirmed = function(_, newammomacro) C.SetAmmoOfWeapon(weapon, newammomacro) end
						titlerow[1].properties.helpOverlayHeight = titlerow[1].properties.helpOverlayHeight + row:getHeight() + Helper.borderSize
					end
				end
			end

			menu.turrets = {}
			local numslots = tonumber(C.GetNumUpgradeSlots(menu.currentplayership, "", "turret"))
			for j = 1, numslots do
				local groupinfo = C.GetUpgradeSlotGroup(menu.currentplayership, "", "turret", j)
				if (ffi.string(groupinfo.path) == "..") and (ffi.string(groupinfo.group) == "") then
					local current = C.GetUpgradeSlotCurrentComponent(menu.currentplayership, "turret", j)
					if current ~= 0 then
						table.insert(menu.turrets, current)
					end
				end
			end

			menu.turretgroups = {}
			local n = C.GetNumUpgradeGroups(menu.currentplayership, "")
			local buf = ffi.new("UpgradeGroup2[?]", n)
			n = C.GetUpgradeGroups2(buf, n, menu.currentplayership, "")
			for i = 0, n - 1 do
				if (ffi.string(buf[i].path) ~= "..") or (ffi.string(buf[i].group) ~= "") then
					local group = { context = buf[i].contextid, path = ffi.string(buf[i].path), group = ffi.string(buf[i].group) }
					local groupinfo = C.GetUpgradeGroupInfo2(menu.currentplayership, "", group.context, group.path, group.group, "turret")
					if (groupinfo.count > 0) then
						group.operational = groupinfo.operational
						group.currentmacro = ffi.string(groupinfo.currentmacro)
						group.slotsize = ffi.string(groupinfo.slotsize)
						table.insert(menu.turretgroups, group)
					end
				end
			end

			if (#menu.turrets > 0) or (#menu.turretgroups > 0) then
				table_header:addEmptyRow(yoffset)

				local row = table_header:addRow(false, { bgColor = Helper.color.transparent })
				row[1]:setColSpan(11):createText(ReadText(1001, 8612), Helper.headerRowCenteredProperties)

				local row = table_header:addRow(false, { bgColor = Helper.color.unselectable })
				row[2]:createText(ReadText(1001, 8620), { font = Helper.standardFontBold, halign = "center" })
				row[7]:createText(ReadText(1001, 12),   { font = Helper.standardFontBold, halign = "center" })

				local turretmodes = {
					[1] = { id = "defend",			text = ReadText(1001, 8613),	icon = "",	displayremoveoption = false },
					[2] = { id = "attackenemies",	text = ReadText(1001, 8614),	icon = "",	displayremoveoption = false },
					[3] = { id = "attackcapital",	text = ReadText(1001, 8624),	icon = "",	displayremoveoption = false },
					[4] = { id = "attackfighters",	text = ReadText(1001, 8625),	icon = "",	displayremoveoption = false },
					[5] = { id = "mining",			text = ReadText(1001, 8616),	icon = "",	displayremoveoption = false },
					[6] = { id = "missiledefence",	text = ReadText(1001, 8615),	icon = "",	displayremoveoption = false },
					[7] = { id = "autoassist",		text = ReadText(1001, 8617),	icon = "",	displayremoveoption = false },
				}

				local row = table_header:addRow("turret_config", { bgColor = Helper.color.transparent })
				row[1]:createText(ReadText(1001, 2963))
				row[2]:setColSpan(5):createDropDown(turretmodes, { startOption = function () return menu.getDropDownTurretModeOption(menu.currentplayership, "all") end, helpOverlayID = "docked_turretconfig_modes", helpOverlayText = " ", helpOverlayHighlightOnly = true  })
				row[2].handlers.onDropDownConfirmed = function(_, newturretmode) C.SetAllTurretModes(menu.currentplayership, newturretmode) end
				row[7]:setColSpan(5):createButton({ helpOverlayID = "docked_turretconfig_arm", helpOverlayText = " ", helpOverlayHighlightOnly = true  }):setText(function () return menu.areTurretsArmed(menu.currentplayership) and ReadText(1001, 8631) or ReadText(1001, 8632) end, { halign = "center" })
				row[7].handlers.onClick = function () return C.SetAllTurretsArmed(menu.currentplayership, not menu.areTurretsArmed(menu.currentplayership)) end

				local turretscounter = 0
				for i, turret in ipairs(menu.turrets) do
					local row = table_header:addRow("turret_config", { bgColor = Helper.color.transparent })
					turretscounter = turretscounter + 1
					local turretname = ffi.string(C.GetComponentName(turret))
					local mouseovertext = ""
					local textwidth = C.GetTextWidth(turretname, Helper.standardFont, Helper.scaleFont(Helper.standardFont, Helper.standardFontSize)) + Helper.scaleX(Helper.standardTextOffsetx)
					if (textwidth > row[1]:getWidth()) then
						mouseovertext = turretname
					end
					row[1]:createText(turretname, { mouseOverText = mouseovertext })
					row[2]:setColSpan(5):createDropDown(turretmodes, { startOption = function () return menu.getDropDownTurretModeOption(turret) end, helpOverlayID = "docked_turrets_modes".. turretscounter, helpOverlayText = " ", helpOverlayHighlightOnly = true  })
					row[2].handlers.onDropDownConfirmed = function(_, newturretmode) C.SetWeaponMode(turret, newturretmode) end
					row[7]:setColSpan(5):createButton({helpOverlayID = "docked_turrets_arm" .. turretscounter, helpOverlayText = " ", helpOverlayHighlightOnly = true   }):setText(function () return C.IsWeaponArmed(turret) and ReadText(1001, 8631) or ReadText(1001, 8632) end, { halign = "center" })
					row[7].handlers.onClick = function () return C.SetWeaponArmed(turret, not C.IsWeaponArmed(turret)) end
				end

				local turretgroupscounter = 0
				for i, group in ipairs(menu.turretgroups) do
					local row = table_header:addRow("turret_config", { bgColor = Helper.color.transparent })
					turretgroupscounter = turretgroupscounter + 1
					local groupname = ReadText(1001, 8023) .. " " .. i .. ((group.currentmacro ~= "") and (" (" .. menu.getSlotSizeText(group.slotsize) .. " " .. GetMacroData(group.currentmacro, "shortname") .. ")") or "")
					local mouseovertext = ""
					local textwidth = C.GetTextWidth(groupname, Helper.standardFont, Helper.scaleFont(Helper.standardFont, Helper.standardFontSize)) + Helper.scaleX(Helper.standardTextOffsetx)
					if (textwidth > row[1]:getWidth()) then
						mouseovertext = groupname
					end
					row[1]:createText(groupname, { color = (group.operational > 0) and Helper.color.white or Helper.color.red, mouseOverText = mouseovertext })
					row[2]:setColSpan(5):createDropDown(turretmodes, { startOption = function () return menu.getDropDownTurretModeOption(menu.currentplayership, group.context, group.path, group.group) end, active = group.operational > 0, helpOverlayID = "docked_turretgroups_modes".. turretgroupscounter, helpOverlayText = " ", helpOverlayHighlightOnly = true  })
					row[2].handlers.onDropDownConfirmed = function(_, newturretmode) C.SetTurretGroupMode2(menu.currentplayership, group.context, group.path, group.group, newturretmode) end
					row[7]:setColSpan(5):createButton({ helpOverlayID = "docked_turretgroups_arm" .. turretgroupscounter, helpOverlayText = " ", helpOverlayHighlightOnly = true  }):setText(function () return C.IsTurretGroupArmed(menu.currentplayership, group.context, group.path, group.group) and ReadText(1001, 8631) or ReadText(1001, 8632) end, { halign = "center" })
					row[7].handlers.onClick = function () return C.SetTurretGroupArmed(menu.currentplayership, group.context, group.path, group.group, not C.IsTurretGroupArmed(menu.currentplayership, group.context, group.path, group.group)) end
				end
			end

			menu.drones = {}
			for _, dronetype in ipairs(config.dronetypes) do
				if C.GetNumStoredUnits(menu.currentplayership, dronetype.id, false) > 0 then
					local entry = {
						type = dronetype.id,
						name = dronetype.name,
						current = ffi.string(C.GetCurrentDroneMode(menu.currentplayership, dronetype.id)),
						modes = {},
					}
					local n = C.GetNumDroneModes(menu.currentplayership, dronetype.id)
					local buf = ffi.new("DroneModeInfo[?]", n)
					n = C.GetDroneModes(buf, n, menu.currentplayership, dronetype.id)
					for i = 0, n - 1 do
						local id = ffi.string(buf[i].id)
						if (id ~= "trade") or (id == entry.current) then
							table.insert(entry.modes, { id = id, text = ffi.string(buf[i].name), icon = "", displayremoveoption = false })
						end
					end
					table.insert(menu.drones, entry)
				end
			end

			if #menu.drones > 0 then
				table_header:addEmptyRow(yoffset)

				local row = table_header:addRow(false, { bgColor = Helper.color.transparent })
				row[1]:setColSpan(11):createText(ReadText(1001, 8619), Helper.headerRowCenteredProperties)

				local row = table_header:addRow(false, { bgColor = Helper.color.unselectable })
				row[2]:createText(ReadText(1001, 8620), { font = Helper.standardFontBold, halign = "center" })
				row[7]:createText(ReadText(1001, 12), { font = Helper.standardFontBold, halign = "center" })

				for _, entry in ipairs(menu.drones) do
					local isblocked = C.IsDroneTypeBlocked(menu.currentplayership, entry.type)
					local row = table_header:addRow("drone_config", { bgColor = Helper.color.transparent })
					row[1]:createText(function () return entry.name .. " (" .. (C.IsDroneTypeArmed(menu.currentplayership, entry.type) and (C.GetNumUnavailableUnits(menu.currentplayership, entry.type) .. "/") or "") .. C.GetNumStoredUnits(menu.currentplayership, entry.type, false) ..")" end, { color = isblocked and Helper.color.warningorange or nil })
					row[2]:setColSpan(5):createDropDown(entry.modes, { startOption = function () return ffi.string(C.GetCurrentDroneMode(menu.currentplayership, entry.type)) end, active = not isblocked })
					row[2].handlers.onDropDownConfirmed = function (_, newdronemode) C.SetDroneMode(menu.currentplayership, entry.type, newdronemode) end
					row[7]:setColSpan(5):createButton({ active = not isblocked }):setText(function () return C.IsDroneTypeArmed(menu.currentplayership, entry.type) and ReadText(1001, 8622) or ReadText(1001, 8623) end, { halign = "center" })
					row[7].handlers.onClick = function () return C.SetDroneTypeArmed(menu.currentplayership, entry.type, not C.IsDroneTypeArmed(menu.currentplayership, entry.type)) end
					row[7].properties.helpOverlayID = "docked_drones_" .. entry.type
					row[7].properties.helpOverlayText = " "
					row[7].properties.helpOverlayHighlightOnly = true 
				end
			end
			-- subordinates
			local subordinates = GetSubordinates(menu.currentplayership)
			local groups = {}
			local usedassignments = {}
			for _, subordinate in ipairs(subordinates) do
				local purpose, shiptype = GetComponentData(subordinate, "primarypurpose", "shiptype")
				local group = GetComponentData(subordinate, "subordinategroup")
				if group and group > 0 then
					if groups[group] then
						table.insert(groups[group].subordinates, subordinate)
						if shiptype == "resupplier" then
							groups[group].numassignableresupplyships = groups[group].numassignableresupplyships + 1
						end
						if purpose == "mine" then
							groups[group].numassignableminingships = groups[group].numassignableminingships + 1
						end
					else
						local assignment = ffi.string(C.GetSubordinateGroupAssignment(menu.currentplayership, group))
						usedassignments[assignment] = i
						groups[group] = { assignment = assignment, subordinates = { subordinate }, numassignableresupplyships = (shiptype == "resupplier") and 1 or 0, numassignableminingships = (purpose == "mine") and 1 or 0 }
					end
				end
			end

			if #subordinates > 0 then
				table_header:addEmptyRow(yoffset)

				local row = table_header:addRow(false, { bgColor = Helper.color.transparent })
				row[1]:setColSpan(11):createText(ReadText(1001, 8626), Helper.headerRowCenteredProperties)

				local row = table_header:addRow(false, { bgColor = Helper.color.unselectable })
				row[1]:createText(ReadText(1001, 8627), { font = Helper.standardFontBold, halign = "center" })
				row[2]:createText(ReadText(1001, 8373), { font = Helper.standardFontBold, halign = "center" })
				row[7]:createText(ReadText(1001, 8628), { font = Helper.standardFontBold, halign = "center" })

				for i = 1, 10 do
					if groups[i] then
						local supplyactive = (groups[i].numassignableresupplyships == #groups[i].subordinates) and ((not usedassignments["supplyfleet"]) or (usedassignments["supplyfleet"] == i))
						local subordinateassignments = {
							[1] = { id = "defence",			text = ReadText(20208, 40301),	icon = "",	displayremoveoption = false },
							[2] = { id = "supplyfleet",		text = ReadText(20208, 40701),	icon = "",	displayremoveoption = false, active = supplyactive, mouseovertext = supplyactive and "" or ReadText(1026, 8601) },
						}

						if C.IsComponentClass(menu.currentplayership, "station") then
							local miningactive = (groups[i].numassignableminingships == #groups[i].subordinates) and ((not usedassignments["mining"]) or (usedassignments["mining"] == i))
							table.insert(subordinateassignments, { id = "mining", text = ReadText(20208, 40201), icon = "", displayremoveoption = false, active = miningactive, mouseovertext = miningactive and "" or ReadText(1026, 8602) })
							local tradeactive = (not usedassignments["trade"]) or (usedassignments["trade"] == i)
							table.insert(subordinateassignments, { id = "trade", text = ReadText(20208, 40101), icon = "", displayremoveoption = false, active = tradeactive, mouseovertext = tradeactive and ((groups[i].numassignableminingships > 0) and (Helper.convertColorToText(Helper.color.warningorange) .. ReadText(1026, 8607)) or "") or ReadText(1026, 7840) })
							local tradeforbuildstorageactive = (groups[i].numassignableminingships == 0) and ((not usedassignments["tradeforbuildstorage"]) or (usedassignments["tradeforbuildstorage"] == i))
							table.insert(subordinateassignments, { id = "tradeforbuildstorage", text = ReadText(20208, 40801), icon = "", displayremoveoption = false, active = tradeforbuildstorageactive, mouseovertext = tradeforbuildstorageactive and "" or ReadText(1026, 8603) })
						elseif C.IsComponentClass(menu.currentplayership, "ship") then
							table.insert(subordinateassignments, { id = "attack", text = ReadText(20208, 40901), icon = "", displayremoveoption = false })
							table.insert(subordinateassignments, { id = "interception", text = ReadText(20208, 41001), icon = "", displayremoveoption = false })
							table.insert(subordinateassignments, { id = "follow", text = ReadText(20208, 41301), icon = "", displayremoveoption = false })
							local active = true
							local mouseovertext = ""
							local buf = ffi.new("Order")
							if not C.GetDefaultOrder(buf, menu.currentplayership) then
								active = false
								mouseovertext = ReadText(1026, 8606)
							end
							table.insert(subordinateassignments, { id = "assist", text = ReadText(20208, 41201), icon = "", displayremoveoption = false, active = active, mouseovertext = mouseovertext })
							if GetComponentData(menu.currentplayership, "shiptype") == "resupplier" then
								table.insert(subordinateassignments, { id = "trade", text = ReadText(20208, 40101), icon = "", displayremoveoption = false })
							end
						end

						local isdockingpossible = false
						for _, subordinate in ipairs(groups[i].subordinates) do
							if IsDockingPossible(subordinate, menu.currentplayership) then
								isdockingpossible = true
								break
							end
						end
						local active = true
						local mouseovertext = ""
						if not GetComponentData(menu.currentplayership, "hasshipdockingbays") then
							active = false
							mouseovertext = ReadText(1026, 8604)
						elseif not isdockingpossible then
							active = false
							mouseovertext = ReadText(1026, 8605)
						end

						local row = table_header:addRow("subordinate_config", { bgColor = Helper.color.transparent })
						row[1]:createText(function () menu.updateSubordinateGroupInfo(); return ReadText(20401, i) .. (menu.subordinategroups[i] and (" (" .. ((not C.ShouldSubordinateGroupDockAtCommander(menu.currentplayership, i)) and ((#menu.subordinategroups[i].subordinates - menu.subordinategroups[i].numdockedatcommander) .. "/") or "") .. #menu.subordinategroups[i].subordinates ..")") or "") end, { color = isblocked and Helper.color.warningorange or nil })
						row[2]:setColSpan(5):createDropDown(subordinateassignments, { startOption = function () menu.updateSubordinateGroupInfo(); return menu.subordinategroups[i] and menu.subordinategroups[i].assignment or "" end })
						row[2].handlers.onDropDownConfirmed = function (_, newassignment) C.SetSubordinateGroupAssignment(menu.currentplayership, i, newassignment) end
						
						-- Runekn's Docking Options edits begin here --
						-- This has been replaced
						--row[7]:setColSpan(5):createButton({ active = active, mouseOverText = mouseovertext }):setText(function () return C.ShouldSubordinateGroupDockAtCommander(menu.currentplayership, i) and ReadText(1001, 8630) or ReadText(1001, 8629) end, { halign = "center" })
						--row[7].handlers.onClick = function () return C.SetSubordinateGroupDockAtCommander(menu.currentplayership, i, not C.ShouldSubordinateGroupDockAtCommander(menu.currentplayership, i)) end
						-- With this
						local pilotentityid = GetControlEntity(menu.currentplayership)
						local shiptype = GetComponentData(menu.currentplayership, "shiptype")
						local iscarrier = shiptype == "carrier"
						if iscarrier then
							row[7]:setColSpan(5):createButton({ active = active, mouseOverText = mouseovertext }):setText(function () return C.ShouldSubordinateGroupDockAtCommander(menu.currentplayership, i) and ReadText(1001, 8630) or ReadText(1001, 8629) end, { halign = "center" })
							row[7].handlers.onClick = function () return C.SetSubordinateGroupDockAtCommander(menu.currentplayership, i, not C.ShouldSubordinateGroupDockAtCommander(menu.currentplayership, i)) end
						else
							row[7]:setColSpan(5):createDropDown(config.subordinatedockingoptions, { active = active, mouseOverText = mouseovertext, startOption = function () 
								local docked = C.ShouldSubordinateGroupDockAtCommander(menu.currentplayership, i)
								local reactive = getReactiveDocking(pilotentityid, i)
								if not docked and reactive then
									return "reactive"
								elseif not docked then
									return "launched"
								else
									return "docked"
								end
							end })
							row[7].handlers.onDropDownConfirmed = function (_, newdockingoption)
								local docked = true
								local reactive = false
								if newdockingoption == "reactive" then
									docked = false
									reactive = true
								elseif newdockingoption == "launched" then
									docked = false
								end
								C.SetSubordinateGroupDockAtCommander(menu.currentplayership, i, docked)
								setReactiveDocking(pilotentityid, i, reactive)
							end
						end
						-- Runekn's Docking Options edits end here --
					end
				end
			end
		end
	else
		local row = table_header:addRow("buttonRow1", { bgColor = Helper.color.transparent, fixed = true })
		local active = canwareexchange
		row[1]:createButton(active and {helpOverlayID = "docked_transferwares", helpOverlayText = " ", helpOverlayHighlightOnly = true } or config.inactiveButtonProperties):setText(ReadText(1001, 8618), active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- "Transfer Wares"
		if active then
			row[1].handlers.onClick = function() return menu.buttonTrade(true) end
		end
		local active = menu.currentplayership ~= 0
		row[2]:createButton(active and { mouseOverText = GetLocalizedKeyName("action", 277), helpOverlayID = "docked_getup", helpOverlayText = " ", helpOverlayHighlightOnly = true } or config.inactiveButtonProperties):setText(ReadText(1002, 20014), active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- "Get Up"
		row[2].handlers.onClick = menu.buttonGetUp
		local active = menu.currentplayership ~= 0
		row[7]:createButton(active and { mouseOverText = GetLocalizedKeyName("action", 316), helpOverlayID = "docked_shipinfo", helpOverlayText = " ", helpOverlayHighlightOnly = true } or config.inactiveButtonProperties):setText(ReadText(1001, 8602), active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- "Ship Information"
		if active then
			row[7].handlers.onClick = menu.buttonDockedShipInfo
		end

		local row = table_header:addRow("buttonRow2", { bgColor = Helper.color.transparent, fixed = true })
		local active = canbuyship
		row[1]:createButton(active and {helpOverlayID = "docked_buyships", helpOverlayText = " ", helpOverlayHighlightOnly = true } or config.inactiveButtonProperties):setText(ReadText(1002, 8008), active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- "Buy Ships"
		if active then
			row[1].handlers.onClick = menu.buttonBuyShip
		end
		local active = cantrade
		row[2]:createButton(active and {helpOverlayID = "docked_trade", helpOverlayText = " ", helpOverlayHighlightOnly = true } or config.inactiveButtonProperties):setText(ReadText(1002, 9005), active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- "Trade"
		if active then
			row[2].handlers.onClick = function() return menu.buttonTrade(false) end
		end
		local active = canmodifyship
		row[7]:createButton(active and {helpOverlayID = "docked_upgrade_repair", helpOverlayText = " ", helpOverlayHighlightOnly = true } or config.inactiveButtonProperties):setText(issupplyship and ReadText(1001, 7877) or ReadText(1001, 7841), active and config.activeButtonTextProperties or config.inactiveButtonTextProperties)	-- Upgrade / Repair Ship
		if dockedplayerships[1] and (not canequip) then
			row[7].properties.mouseOverText = (C.IsComponentClass(dockedplayerships[1], "ship_l") or C.IsComponentClass(dockedplayerships[1], "ship_xl")) and ReadText(1026, 7807) or ReadText(1026, 7806)
		elseif not isdock then
			row[7].properties.mouseOverText = ReadText(1026, 8014)
		end
		if active then
			row[7].handlers.onClick = menu.buttonModifyShip
		end

		local row = table_header:addRow("buttonRow3", { bgColor = Helper.color.transparent, fixed = true })
		row[1]:createButton(config.inactiveButtonProperties):setText("", config.inactiveButtonTextProperties)	-- dummy
		if menu.currentplayership ~= 0 then
			row[2]:createButton({ mouseOverText = GetLocalizedKeyName("action", 175), bgColor = menu.undockButtonBGColor, highlightColor = menu.undockButtonHighlightColor, helpOverlayID = "docked_undock", helpOverlayText = " ", helpOverlayHighlightOnly = true }):setText(ReadText(1002, 20013), { halign = "center", color = menu.undockButtonTextColor })	-- "Undock"
			row[2].handlers.onClick = menu.buttonUndock
		else
			row[2]:createButton({ mouseOverText = GetLocalizedKeyName("action", 175), helpOverlayID = "docked_gotoship", helpOverlayText = " ", helpOverlayHighlightOnly = true }):setText(ReadText(1001, 7305), { halign = "center" })	-- "Go to Ship"
			row[2].handlers.onClick = menu.buttonGoToShip
		end
		row[7]:createButton(config.inactiveButtonProperties):setText("", config.inactiveButtonTextProperties)	-- dummy

		local row = table_header:addRow(false, { bgColor = Helper.color.transparent, fixed = true })
		row[1]:setColSpan(11):createBoxText(menu.infoText, { halign = "center", color = Helper.color.warningorange, boxColor = menu.infoBoxColor })
	end


	if menu.table_header then
		table_header:setTopRow(GetTopRow(menu.table_header))
		table_header:setSelectedRow(menu.selectedRows.header or Helper.currentTableRow[menu.table_header])
		table_header:setSelectedCol(menu.selectedCols.header or Helper.currentTableCol[menu.table_header] or 0)
	else
		table_header:setSelectedRow(menu.selectedRows.header)
		table_header:setSelectedCol(menu.selectedCols.header or 0)
	end
	menu.selectedRows.header = nil
	menu.selectedCols.header = nil

	table_header.properties.maxVisibleHeight = Helper.viewHeight - table_header.properties.y - Helper.frameBorder
	menu.frame.properties.height = math.min(Helper.viewHeight, table_header:getVisibleHeight() + table_header.properties.y + Helper.scaleY(Helper.standardButtonHeight))

	-- display view/frame
	menu.frame:display()
end 

init()