local utils = ...
local S = utils.S



local function on_place (itemstack, placer, pointed_thing)
	if not utils.check_privs (placer) then
		return itemstack
	end

	local meta = itemstack:get_meta ()

	if meta then
		local phase = meta:get_int ("phase")

		if phase == 1 then
			local look_dir, _, under = utils.get_place_stats (placer, pointed_thing)

			if look_dir then
				local on_rightclick = utils.get_on_rightclick (under, placer)
				if on_rightclick then
					return on_rightclick (under, utils.get_far_node (under), placer, itemstack, pointed_thing)
				end

				local pos1 = minetest.string_to_pos (meta:get_string ("pos1"))
				local pos2 = table.copy (under)

				if pos2.y < pos1.y then
					local y = pos2.y
					pos2.y = pos1.y
					pos1.y = y
				end

				if (math.abs (pos2.x - pos1.x) * math.abs (pos2.y - pos1.y) *
					 math.abs (pos2.z - pos1.z)) > utils.settings.max_section_volume then

					utils.player_error_message (placer, "Volume to large to export!")
					meta:set_int ("phase", 0)

					return itemstack
				end

				local param2 = 0

				if pos2.x >= pos1.x and pos2.z < pos1.z then
					param2 = 1
				elseif pos2.x < pos1.x and pos2.z < pos1.z then
					param2 = 2
				elseif pos2.x < pos1.x and pos2.z >= pos1.z then
					param2 = 3
				end

				meta:set_int ("phase", 0)

				local tm = os.clock ()
				local spec = utils.copy_section (pos1, pos2, param2)

				if spec then
					local x = spec.lenx
					local y = spec.leny
					local z = spec.lenz
					local success

					success, spec = pcall (minetest.serialize, spec)

					if success and spec then
						spec =
						"formspec_version[3]"..
						"size[11,11]"..
						"textarea[0.5,0.5;10,10;clipboard;;"..
						 minetest.formspec_escape (spec).."]"

						utils.player_message (placer, string.format ("Export section %s to %s",
																					minetest.pos_to_string (pos1, 0),
																					minetest.pos_to_string (pos2, 0)))

						minetest.log ("action", string.format ("lwexport_tools export section by %s, %s to %s",
																			placer:get_player_name (),
																			minetest.pos_to_string (under, 0),
																			minetest.pos_to_string (pos2, 0)))

						minetest.show_formspec (placer:get_player_name (), "lwexport_tools:section", spec)

						minetest.log ("action", string.format ("[lwexport_tools] Export section %d nodes %dms",
																			(x * y * z) , ((os.clock () - tm) * 1000)))
					else
						utils.player_error_message (placer, "Error reading section to export!")
					end
				else
					utils.player_error_message (placer, "Error reading section to export!")
				end
			end

		else
			local _, _, under = utils.get_place_stats (placer, pointed_thing)

			if under then
				local on_rightclick = utils.get_on_rightclick (under, placer)
				if on_rightclick then
					return on_rightclick (under, utils.get_far_node (under), placer, itemstack, pointed_thing)
				end

				meta:set_string ("pos1", minetest.pos_to_string (under, 0))
				meta:set_int ("phase", 1)

				utils.player_message (placer, string.format ("Set first position of export section %s",
																			minetest.pos_to_string (under, 0)))
			end
		end
	end

	return itemstack
end



minetest.register_craftitem ("lwexport_tools:section", {
	description = S("Export Section"),
	short_description = S("Export Section"),
	groups = { },
	inventory_image = "lwexport_section.png",
	wield_image = "lwexport_section.png",
	stack_max = 1,
	on_place = on_place,
})
