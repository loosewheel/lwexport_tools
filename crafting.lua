
if minetest.global_exists ("default") then


minetest.register_craft({
	output = "lwexport_tools:section 1",
	recipe = {
		{ "default:wood" },
		{ "default:stick" },
		{ "default:wood" },
	}
})


else


local game_id = Settings (minetest.get_worldpath ()..DIR_DELIM..'world.mt'):get ('gameid')

if game_id == "mineclone2" then

minetest.register_craft({
	output = "lwexport_tools:section 1",
	recipe = {
		{ "mcl_core:wood" },
		{ "mcl_core:stick" },
		{ "mcl_core:wood" },
	}
})

end


end



--
