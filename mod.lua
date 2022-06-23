MOD_NAME = "carpets"

CE = {
  sprites={},
  control=nil,
  map = {},
  draw_map = {},
  player_tile = nil,
  action = {placing = false, removing = false}
}

function register()

  return {
    name = MOD_NAME,
    hooks = { "ready", "save", "data", "key", "click", "tick" },
    modules = {}
  }
end

function init()
  api_set_devmode(true)
  register_carpet("check_rug1", "sprites/checkrug.png")
  define_item()
  api_define_command("/check", "check_engines")
  api_define_command("/pos", "engine_pos")
  api_get_data()
  return "Success"
end

function ready()
  CE.player_tile = api_get_player_tile_position()
  local engines = api_get_menu_objects(nil, "carpets_carpet_engine")
  if #engines == 0 then
    api_create_obj("carpets_carpet_engine", CE.player_tile.x-208, CE.player_tile.y-160)
  elseif #engines >= 2 then
    for index, value in ipairs(engines) do
      if index == 1 then
      else
        api_destroy_inst(value.id)
      end
    end
  end
  condense_carpets({x=CE.player_tile.x+16,y=CE.player_tile.y+16})
end

function save()
  save_data = flatten_table(CE.map)
  api_log("save", "i'm saving")
  api_set_data(save_data)
end

function data(ev, data)
  if ev == "LOAD" and data ~= nil then
    --api_log("load", data)
    CE.map = expand_table(data)
  end

  if ev == "SAVE" then

  end

end

function key(key_code)
end

function click(button, click_type)
  if (button == "LEFT" and click_type == "PRESSED") then
    if (b_is_equipped("log")) then
      CE.action.placing = true
      local tile = api_get_mouse_tile_position()
      if CE.map[tile.x] == nil then
        CE.map[tile.x] = {}
        morph_carpet(tile, true)
        condense_carpets(CE.player_tile)
      else
        morph_carpet(tile, true)
        condense_carpets(CE.player_tile)
      end
    end
    if (b_is_equipped("stone")) then
      CE.action.removing = true
      local tile = api_get_mouse_tile_position()
      if CE.map[tile.x] ~= nil then
        if CE.map[tile.x][tile.y] ~= nil then
          morph_carpet(tile, false)
          condense_carpets(CE.player_tile)
        end
      end
    end
  end
  if (button == "LEFT" and click_type == "RELEASED") then
    CE.action.placing = false
    CE.action.removing = false
  end
end

function tick()
  if CE.action.placing == true then
    local tile = api_get_mouse_tile_position()
    if CE.map[tile.x] == nil then
      CE.map[tile.x] = {}
      morph_carpet(tile, true)
      condense_carpets(CE.player_tile)
    elseif CE.map[tile.x][tile.y] == nil then
      morph_carpet(tile, true)
      condense_carpets(CE.player_tile)
    end
  end
  if CE.action.removing == true then
    local tile = api_get_mouse_tile_position()
    if CE.map[tile.x] ~= nil then
      if CE.map[tile.x][tile.y] ~= nil then
        morph_carpet(tile, false)
        condense_carpets(CE.player_tile)
      end
    end
  end
end

function define_item()

  -- define a custom item
  api_define_menu_object({
    id = "carpet_engine",
    name = "Chair Rug",
    category = "Floors",
    tooltip = "rug that looks like a chair!",
    menu = false,
    layout = {},
    cost = { buy = 1, sell = 1 },
    tools = { "hammer1" },
    buttons = {},
    info = {},
    machines = {},
    placeable = true,
    depth = -500 }, "sprites/carpets.png", "sprites/carpets.png", { define = "carpet_define", tick = "carpet_tick" },
    "rug_draw")

end

function carpet_define(menu_id)
  local obj_id = api_get_menus_obj(menu_id)
  local immortal = api_set_immortal(obj_id, true)

  CE.control = obj_id
end

function carpet_tick(menu_id)
  local player_pos = api_get_player_tile_position()

  if player_pos.x ~= CE.player_tile.x or player_pos.y ~= CE.player_tile.y then
    api_sp(CE.control, "x", player_pos.x - 208)
    api_sp(CE.control, "y", player_pos.y - 160)
    condense_carpets(player_pos)
  end
end

function rug_draw(obj_id)
  for _, next_tile in pairs(CE.draw_map) do
    api_draw_sprite(CE.sprites["check_rug1"], next_tile.shape, next_tile.x, next_tile.y)
  end
end

function b_is_equipped(item)
  -- Get the currently equipped item
  local equipped_item = api_get_equipped();

  if (string.match(equipped_item, item)) then
    return true
  else
    return false
  end
end

function check_engines(args)
  api_log("carpet_control:", CE.control)
  api_log("check engines:", api_get_menu_objects(nil, "carpets_carpet_engine"))
end

function engine_pos(args)
  local pos = { api_gp(CE.control, "x"), api_gp(CE.control, "y") }
  api_log("x,y", pos)
end

function condense_carpets(player_pos)
  CE.draw_map = {}
  CE.player_tile = player_pos
  local min_x = player_pos.x - (16 * 22)
  local max_x = player_pos.x + (16 * 22)
  local min_y = player_pos.y - (16 * 13)
  local max_y = player_pos.y + (16 * 13)
  ----[[
  for x_val, y_table in pairs(CE.map) do
    if x_val > (min_x) and x_val < (max_x) then
      for y_val, shape in pairs(y_table) do
        if y_val > (min_y) and y_val < (max_y) then
          table.insert(CE.draw_map, { x = x_val, y = y_val, shape = shape })
        end
      end
    end
  end
  --]]--
  --[[
  for x_val=min_x, max_x, 16 do
    if CE.map[x_val] ~= nil then
      for y_val=min_y, max_y, 16 do
        if CE.map[x_val][y_val] ~= nil then
          carpet_draw[#carpet_draw+1] = {x = x_val, y = y_val, shape = CE.map[x_val][y_val]}
        end
      end
    end
  end
  ]]--
end

function morph_carpet(tile_pos, placed)
  if placed == true then
    --placed
    CE.map[tile_pos.x][tile_pos.y] = 0
    nearby_carpets(tile_pos, true, true)
  else
    --removed
    CE.map[tile_pos.x][tile_pos.y] = nil
    nearby_carpets(tile_pos, true, false)
  end
end

function nearby_carpets(tile_pos, first, placed)
  local shape_num = 0
  local nearby_tiles = {
    up = { x = tile_pos.x, y = tile_pos.y - 16 },
    right = { x = tile_pos.x + 16, y = tile_pos.y },
    down = { x = tile_pos.x, y = tile_pos.y + 16 },
    left = { x = tile_pos.x - 16, y = tile_pos.y }
  }
  if first == true then
    --up (0001) +1
    if CE.map[nearby_tiles.up.x] ~= nil then
      if CE.map[nearby_tiles.up.x][nearby_tiles.up.y] ~= nil then
        shape_num = shape_num + 1
        nearby_carpets(nearby_tiles.up, false)
      end
    end
    --right (0010) +2
    if CE.map[nearby_tiles.right.x] ~= nil then
      if CE.map[nearby_tiles.right.x][nearby_tiles.right.y] ~= nil then
        shape_num = shape_num + 2
        nearby_carpets(nearby_tiles.right, false)
      end
    end
    --down (0100) +4
    if CE.map[nearby_tiles.down.x] ~= nil then
      if CE.map[nearby_tiles.down.x][nearby_tiles.down.y] ~= nil then
        shape_num = shape_num + 4
        nearby_carpets(nearby_tiles.down, false)
      end
    end
    --left (1000) +8
    if CE.map[nearby_tiles.left.x] ~= nil then
      if CE.map[nearby_tiles.left.x][nearby_tiles.left.y] ~= nil then
        shape_num = shape_num + 8
        nearby_carpets(nearby_tiles.left, false)
      end
    end
    if placed == true then
      CE.map[tile_pos.x][tile_pos.y] = shape_num
    end
  else
    --up (0001) +1
    if CE.map[nearby_tiles.up.x] ~= nil then
      if CE.map[nearby_tiles.up.x][nearby_tiles.up.y] ~= nil then
        shape_num = shape_num + 1
      end
    end
    --right (0010) +2
    if CE.map[nearby_tiles.right.x] ~= nil then
      if CE.map[nearby_tiles.right.x][nearby_tiles.right.y] ~= nil then
        shape_num = shape_num + 2
      end
    end
    --down (0100) +4
    if CE.map[nearby_tiles.down.x] ~= nil then
      if CE.map[nearby_tiles.down.x][nearby_tiles.down.y] ~= nil then
        shape_num = shape_num + 4
      end
    end
    --left (1000) +8
    if CE.map[nearby_tiles.left.x] ~= nil then
      if CE.map[nearby_tiles.left.x][nearby_tiles.left.y] ~= nil then
        shape_num = shape_num + 8
      end
    end
    CE.map[tile_pos.x][tile_pos.y] = shape_num
  end
end

function flatten_table(input_table)
  output_table = {}

  for x_val, y_table in pairs(input_table) do
    for y_val, shape in pairs(y_table) do
      table.insert(output_table, { x = x_val, y = y_val, shape = shape })
    end
  end
  return output_table
end

function expand_table(input_table)
  output_table = {}
  for _, value in pairs(input_table) do
    if output_table[value.x] == nil then
      output_table[value.x] = {}
      output_table[value.x][value.y] = value.shape
    elseif output_table[value.x][value.y] == nil then
      output_table[value.x][value.y] = value.shape
    end
  end
  return output_table
end

function register_carpet(carpet_id, carpet_sprite)
  CE.sprites[carpet_id] = api_define_sprite(carpet_id, carpet_sprite, 16)
end

function table_dump_recursion(starting_table, recursion_count)
  msg = ""
  for key, value in pairs(starting_table) do
    if type(value) == 'table' then
      msg = msg .. tostring(key) .. "->"
      msg = msg .. table_dump_recursion(value, recursion_count + 1)
    else
      msg = msg .. "{" .. tostring(key) .. "=" .. tostring(value) .. "}"
    end
    if (recursion_count == 0) then
      api_log("table_dump_recursion()", msg)
      msg = ""
    end
  end
  return msg
end
