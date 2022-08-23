local version = "0.1.4"



lwexport_tools = { }



function lwexport_tools.version ()
	return version
end


local utils = { }
local modpath = minetest.get_modpath ("lwexport_tools")

loadfile (modpath.."/settings.lua") (utils)
loadfile (modpath.."/utils.lua") (utils)
loadfile (modpath.."/long_process.lua") (utils)
loadfile (modpath.."/section.lua") (utils)
loadfile (modpath.."/crafting.lua") (utils)



minetest.register_privilege ("lwexport_tools", {
	description = "Allow export tool usage.",
	give_to_singleplayer = true,
	give_to_admin = true,
	on_grant = function (name, granter_name)
		return false
	end,
	on_revoke = function (name, revoker_name)
		return false
	end,
})
