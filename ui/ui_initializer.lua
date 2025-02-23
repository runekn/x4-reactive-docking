local function init()
	DebugError("Reactive Docking: extension_check Init")
	
	local extensions = GetExtensionList()
	local compat = false
    for _,extension in ipairs(extensions) do
        if extension.id == "kuerteeUIExtensionsAndHUD" and tonumber(extension.version) >= 2.06 and extension.enabled == true then
            DebugError("Reactive Docking: Found UIX")
						compat = true
						break
        end
    end
		
	if compat == true then
		DebugError("Reactive Docking: Loading in High Compatibility Mode")
		RKN_ReactiveDocking_UIX.init()
	else
		DebugError("Reactive Docking: Loading in Stand Alone Mode")
		RKN_ReactiveDocking_Standalone.init()
	end	
end

init()