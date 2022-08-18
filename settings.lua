local utils = ...


utils.settings = { }

utils.settings.max_section_volume =
	tonumber(minetest.settings:get ("lwexport_tools_max_section_volume")) or 64000

utils.settings.max_section_length =
	tonumber(minetest.settings:get ("lwexport_tools_max_section_length")) or 500000
