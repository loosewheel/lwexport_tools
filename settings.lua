local utils = ...


utils.settings = { }

utils.settings.max_section_volume =
	tonumber(minetest.settings:get ("lwexport_tools_max_section_volume", true) or 64000)
