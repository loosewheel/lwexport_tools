local utils = ...
local S = utils.S



local player_data = { }



local function show_form (player_name)
	local data = player_data[player_name]

	if data then
		utils.player_message (player_name, string.format ("Export section %s to %s",
																		  minetest.pos_to_string (data.pos1, 0),
																		  minetest.pos_to_string (data.pos2, 0)))

		minetest.show_formspec (player_name, "lwexport_tools:section", data.spec)

		minetest.log ("action", string.format ("lwexport_tools export section by %s, %s to %s (%d nodes %d bytes)",
															player_name,
															minetest.pos_to_string (data.pos1, 0),
															minetest.pos_to_string (data.pos2, 0),
															data.volume,
															data.length))

		player_data[player_name] = nil
	end
end



local function display_warning (player_name)
	local data = player_data[player_name]

	if data then
		local warning

		if data.spec:len () > 1000000 then
			warning = "Displaying the form will take a VERY long time!"
		elseif data.spec:len () > 500000 then
			warning = "Displaying the form could take a long time!"
		elseif data.spec:len () > 150000 then
			warning = "Displaying the form could take a while."
		else
			show_form (player_name)

			return
		end

		local spec =
		"formspec_version[3]"..
		"size[10.5,4.3,false]"..
		"label[1.0,1.4;"..warning.."]"..
		"button_exit[1.0,2.5;2.5,0.8;continue;Continue]"..
		"button_exit[7.0,2.5;2.5,0.8;cancel;Cancel]"

		minetest.show_formspec (player_name, "lwexport_tools:section", spec)
	end
end



local function export_section_runner (player_name, pos1, pos2, param2, volume)
	if not player_data[player_name] then
		local spec = utils.copy_section (pos1, pos2, param2)

		if spec then
			local success

			success, spec = pcall (minetest.serialize, spec)

			if success and spec then
				spec =
				"formspec_version[3]"..
				"size[11,11]"..
				"textarea[0.5,0.5;10,10;clipboard;;"..
				minetest.formspec_escape (spec).."]"

				if spec:len () > utils.settings.max_section_length then
					utils.player_error_message (player_name,
														 string.format ("Buffer to long to export (%d)!",
														 spec:len ()))

					return
				end

				return player_name, spec, pos1, pos2, volume, spec:len ()

			else
				utils.player_error_message (player_name, "Error reading section to export!")
			end
		else
			utils.player_error_message (player_name, "Error reading section to export!")
		end
	else
		utils.player_error_message (player_name, "An operation is already in progress!")
	end
end



local function export_section_callback (id, result, player_name, spec, pos1, pos2, volume, length)
	if result and player_name and not player_data[player_name] then
		player_data[player_name] =
		{
			spec = spec,
			pos1 = pos1,
			pos2 = pos2,
			volume = volume,
			length = spec:len ()
		}

		display_warning (player_name)
	end
end



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

				meta:set_int ("phase", 0)

				local pos1 = minetest.string_to_pos (meta:get_string ("pos1"))
				local pos2 = table.copy (under)

				if pos2.y < pos1.y then
					local y = pos2.y
					pos2.y = pos1.y
					pos1.y = y
				end

				local volume = (math.abs (pos2.x - pos1.x) + 1) *
									(math.abs (pos2.y - pos1.y) + 1) *
									(math.abs (pos2.z - pos1.z) + 1)

				if volume > utils.settings.max_section_volume then
					utils.player_error_message (placer, "Volume to large to export!")

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

				if not utils.add_long_process (placer:get_player_name (), export_section_runner, export_section_callback,
														 placer:get_player_name (), pos1, pos2, param2, volume) then
					utils.player_error_message (placer:get_player_name (), "An operation is already in progress!")
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



minetest.register_on_player_receive_fields (function (player, formname, fields)
   if formname == "lwexport_tools:section" and player and player:is_player () then
		if fields.continue then
			local data = player_data[player:get_player_name ()]

			if data then
				show_form (player:get_player_name ())

				return
			end
		end

		if fields.quit then
			player_data[player:get_player_name ()] = nil
		end
	end
end)
