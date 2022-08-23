local utils = ...



if minetest.get_translator and minetest.get_translator ("lwexport_tools") then
	utils.S = minetest.get_translator ("lwexport_tools")
elseif minetest.global_exists ("intllib") then
   if intllib.make_gettext_pair then
      utils.S = intllib.make_gettext_pair ()
   else
      utils.S = intllib.Getter ()
   end
else
   utils.S = function (s) return s end
end



local minetest_version

do
	local parts = { }

	for n in string.gmatch (minetest.get_version ().string or "", "%d+") do
		parts[#parts + 1] = n
	end

	minetest_version =
	{
		major = (tonumber (parts[1]) or 0),
		minor = (tonumber (parts[2]) or 0),
		patch = (tonumber (parts[3]) or 0)
	}
end



function utils.get_minetest_version ()
	return minetest_version
end



function utils.player_message (player, msg)
	local name

	if type (player) == "string" then
		name = player
	elseif player and player:is_player () then
		name = player:get_player_name ()
	else
		return
	end

	minetest.chat_send_player (name, tostring (msg))
end



function utils.player_error_message (player, msg)
	utils.player_message (player, minetest.colorize ("#FF0000FF", tostring (msg)))
end



function utils.check_privs (player)
	local name = (player and player:get_player_name ()) or ""

	if name:len () > 0 then
		if minetest.get_player_privs (name).lwexport_tools == true then
			return true
		end

		utils.player_error_message (name, "Privilege lwexport_tools required to use this tool.")
	end

	return false
end



function utils.get_far_node (pos)
	local node = minetest.get_node (pos)

	if node.name == "ignore" then
		minetest.get_voxel_manip ():read_from_map (pos, pos)

		node = minetest.get_node (pos)

		if node.name == "ignore" then
			return nil
		end
	end

	return node
end



function utils.find_item_def (name)
	local def = minetest.registered_items[name]

	if not def then
		def = minetest.registered_craftitems[name]
	end

	if not def then
		def = minetest.registered_nodes[name]
	end

	if not def then
		def = minetest.registered_tools[name]
	end

	return def
end



function utils.get_on_rightclick (pos, player)
	local node = utils.get_far_node (pos)

	if node then
		local def = minetest.registered_nodes[node.name]

		if def and def.on_rightclick and
			not (player and player:is_player () and
				  player:get_player_control ().sneak) then

				return def.on_rightclick
		end
	end

	return nil
end



function utils.get_place_stats (player, pointed_thing)
	if player and player:is_player () and pointed_thing and
		pointed_thing.type == "node" then

		local above = vector.new (pointed_thing.above)
		local under = vector.new (pointed_thing.under)
		local param2 = minetest.dir_to_wallmounted (vector.normalize (player:get_look_dir ()))
		local look_dir = minetest.wallmounted_to_dir (param2)
		local point_dir = vector.direction (above, under)
		local node = utils.get_far_node (under)

		if not node then
			return nil
		end

		if node.name == "air" then
			return nil
		else
			local def = minetest.registered_nodes[node.name]

			if not def then
				return nil
			end

			if def.buildable_to and def.liquidtype == "none" then
				above = under
				under = vector.add (under, point_dir)
				node = utils.get_far_node (under)

				if not node then
					return nil
				end

				if node.name == "air" then
					return nil
				else
					def = minetest.registered_nodes[node.name]

					if not def then
						return nil
					end
				end
			end
		end

		return look_dir, point_dir, under, above, param2
	end

	return
end



function utils.get_node_data (pos, metas)
	local node = utils.get_far_node (pos)

	if node then
		if node.name ~= "air" then
			local def = utils.find_item_def (node.name)

			if def then
				local meta_table = nil

				if metas[minetest.pos_to_string (pos, 0)] then
					local meta = minetest.get_meta (pos)

					if not meta then
						return nil
					end

					meta_table = meta:to_table ()

					if meta_table and meta_table.inventory then
						for list, inv in pairs (meta_table.inventory) do
							if type (inv) == "table" then
								for slot, item in pairs (inv) do
									if type (item) == "userdata" then
										inv[slot] = item:to_string ()
									end
								end
							end
						end
					end
				end

				return { node = node, meta = meta_table }
			end
		else
			return { node = { name = "air" } }
		end
	end

	return nil
end



local function get_node_meta_list (pos1, pos2)
	local list = minetest.find_nodes_with_meta (pos1, pos2)
	local metas = { }

	for i = 1, #list, 1 do
		metas[minetest.pos_to_string (list[i], 0)] = true
	end

	return metas
end



function utils.copy_section (pos1, pos2, param2)
	local map
	local metas = get_node_meta_list (pos1, pos2)

	if param2 == 3 or param2 == 1 then
		local incx = (pos2.z < pos1.z and -1) or 1
		local incy = (pos2.y < pos1.y and -1) or 1
		local incz = (pos2.x < pos1.x and -1) or 1
		local lenx = math.abs (pos2.z - pos1.z)
		local leny = math.abs (pos2.y - pos1.y)
		local lenz = math.abs (pos2.x - pos1.x)

		map = { lenx = lenx + 1, leny = leny + 1, lenz = lenz + 1, param2 = param2 }

		for y = 0, leny do
			map[y] = { }

			for z = 0, lenz do
				map[y][z] = { }

				for x = 0, lenx do
					local pos =
					{
						x = pos1.x + (z * incz),
						y = pos1.y + (y * incy),
						z = pos1.z + (x * incx)
					}

					map[y][z][x] = utils.get_node_data (pos, metas)
				end

				utils.long_process.expire (0.03)
			end
		end
	else
		local incx = (pos2.x < pos1.x and -1) or 1
		local incy = (pos2.y < pos1.y and -1) or 1
		local incz = (pos2.z < pos1.z and -1) or 1
		local lenx = math.abs (pos2.x - pos1.x)
		local leny = math.abs (pos2.y - pos1.y)
		local lenz = math.abs (pos2.z - pos1.z)

		map = { lenx = lenx + 1, leny = leny + 1, lenz = lenz + 1, param2 = param2 }

		for y = 0, leny do
			map[y] = { }

			for z = 0, lenz do
				map[y][z] = { }

				for x = 0, lenx do
					local pos =
					{
						x = pos1.x + (x * incx),
						y = pos1.y + (y * incy),
						z = pos1.z + (z * incz)
					}

					map[y][z][x] = utils.get_node_data (pos, metas)
				end

				utils.long_process.expire (0.03)
			end
		end
	end

	return map
end



local long_processes = { }



local function long_processes_callback (id, result, ...)
	for player_name, data in pairs (long_processes) do
		if data.id == id then
			local callback = data.callback

			long_processes[player_name] = nil

			if callback then
				callback (id, result, ...)
			end

			return
		end
	end
end



function utils.add_long_process (player_name, func, callback, ...)
	if not long_processes[player_name] then
		local id = utils.long_process.add (func, long_processes_callback, ...)

		if id then
			long_processes[player_name] =
			{
				id = id,
				callback = callback
			}

			return true
		end
	end

	return false
end
