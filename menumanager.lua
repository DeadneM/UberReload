_G.ReloadTweaks = _G.ReloadTweaks or {}

ReloadTweaks.save_data_path = SavePath .. "ReloadTweaks.txt"
ReloadTweaks.mod_path = ModPath
ReloadTweaks.hooks = {
	["lib/units/beings/player/states/playerstandard"] = "Hooks/playerstandard.lua",
	["lib/units/weapons/raycastweaponbase"] = "Hooks/raycastweaponbase.lua",
	["lib/tweak_data/weapontweakdata"] = "Hooks/weapontweakdata.lua",
	["lib/units/weapons/newraycastweaponbase"] = "Hooks/newraycastweaponbase.lua"
}
ReloadTweaks.settings = {
	reload_cancel = true,
	reload_cancel_barrelmag = true,
	freeswap = true,
	prevent_reload_cancel = 0.3,
	prevent_run_cancel = true,
	reload_style = 2,
	reload_realistic = true,
	reload_throw = true,
	reload_tased = true
}
ReloadTweaks.globals = {
	reload_allowed = true
}

function ReloadTweaks:GetSettings()
	ReloadTweaks:Load()
	return ReloadTweaks.settings
end

function ReloadTweaks:Load()
	
	local file = io.open(self.save_data_path, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.settings[k] = v
		end
	else
		ReloadTweaks:Save()
	end
end

function ReloadTweaks:Save()
	local file = io.open(self.save_data_path,"w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end

	
Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_ReloadTweaks", function( loc )
	loc:load_localization_file( ReloadTweaks.mod_path .. "Loc/en.txt")
end)
	
	
Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_ReloadTweaks", function(menu_manager)
		
	
	MenuCallbackHandler.reloadtweaks_toggle_clbk = function(self, item)
		ReloadTweaks.settings[item:name()] = item:value() == "on"
		ReloadTweaks:Save()
	end

	MenuCallbackHandler.reloadtweaks_multichoice_clbk = function(self, item)
		ReloadTweaks.settings.reload_style = item:value()
		ReloadTweaks:Save()
	end
	
	MenuCallbackHandler.reloadtweaks_prevent_cancel_clbk = function(self, item)
		ReloadTweaks.settings.prevent_reload_cancel = item:value()
		ReloadTweaks:Save()
	end

	MenuCallbackHandler.reloadtweaks_close_clbk = function(this)
		ReloadTweaks:Save()
	end
		
	ReloadTweaks:Load()
	MenuHelper:LoadFromJsonFile(ReloadTweaks.mod_path .. "options.txt", ReloadTweaks, ReloadTweaks.settings)
		
end)

if ReloadTweaks.hooks[RequiredScript] then
	dofile(ReloadTweaks.mod_path .. ReloadTweaks.hooks[RequiredScript])
end