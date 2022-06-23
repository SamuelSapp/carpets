CE = {
  data = {},
  sprites = {},
  control = nil,
  map = {},
  camera = { min_x = 0, max_x = 0, min_y = 0, max_y = 0 },
  action = { placing = false, removing = false }
}

---------------------------------------------------------------------------------------------
--Hooks
---------------------------------------------------------------------------------------------

function ce_init()
  ce_define_items()
end

function ce_ready()
  CE.map = ce_create_map()
  api_get_data()
  local player_name = api_gp(api_get_player_instance(), "name")
  if CE["data"][player_name] == nil then
    CE["data"][player_name] = {}
  end
  ce_set_camera()
  local cam = api_get_cam()
  local engines = api_get_menu_objects(nil, "carpets_carpet_engine")
  if #engines == 0 then
    api_log("ready1", "making")
    api_create_obj("carpets_carpet_engine", cam.x, cam.y)
  elseif #engines == 1 then
    api_log("ready2", engines[1])
    CE.control = engines[1].id
    api_sp(CE.control, "x", cam.x)
    api_sp(CE.control, "y", cam.y)
  elseif #engines >= 2 then
    for index, value in ipairs(engines) do
      if index == 1 then
        api_log("ready3", value)
        CE.control = value.id
        api_sp(CE.control, "x", cam.x)
        api_sp(CE.control, "y", cam.y)
      else
        api_destroy_inst(value.id)
      end
    end
  end
end

function ce_save()
  local player_name = api_gp(api_get_player_instance(), "name")
  local save_data = CE.data
  save_data[player_name] = ce_flatten_map()
  api_set_data(save_data)
end

function ce_load(data)
  CE.data = data
  local player_name = api_gp(api_get_player_instance(), "name")
  if data[player_name] ~= nil then
    ce_expand_map(data[player_name])
  end
end

function ce_click(button, click_type)
  local mouse_tile = api_get_mouse_tile_position()
  local mx = _tile(mouse_tile.x)
  local my = _tile(mouse_tile.y)
  local equipped_item = api_get_equipped()
  if (button == "LEFT" and click_type == "PRESSED") then
    if equipped_item == "log" then
      CE.action.placing = true
      if CE.map[mx][my] == nil then
        CE.map[mx][my] = {
          sprite = "check_rug1",
          frame = 0,
          x = mouse_tile.x,
          y = mouse_tile.y
        }
        ce_masktiles(mx, my, true)
      end
    end

    if equipped_item == "stone" then
      CE.action.removing = true
      if CE.map[mx][my] ~= nil then
        CE.map[mx][my] = nil
        ce_masktiles(mx, my, false)
      end
    end
  end

  if (button == "LEFT" and click_type == "RELEASED") then
    CE.action.placing = false
    CE.action.removing = false
  end
end

function ce_tick()
  ce_set_camera()
  if CE.action.placing == true then
    local mouse_tile = api_get_mouse_tile_position()
    local mx = _tile(mouse_tile.x)
    local my = _tile(mouse_tile.y)
    if CE.map[mx][my] == nil then
      CE.map[mx][my] = {
        sprite = "check_rug1",
        frame = 0,
        x = mouse_tile.x,
        y = mouse_tile.y
      }
      ce_masktiles(mx, my, true)
    end
  end
  if CE.action.removing == true then
    local mouse_tile = api_get_mouse_tile_position()
    local mx = _tile(mouse_tile.x)
    local my = _tile(mouse_tile.y)
    if CE.map[mx][my] ~= nil then
      CE.map[mx][my] = nil
      ce_masktiles(mx, my, false)
    end
  end
end

---------------------------------------------------------------------------------------------
--Items and Register
---------------------------------------------------------------------------------------------

function ce_register_carpet(carpet_id, carpet_sprite, carpet_item_sprite)
  CE.sprites[carpet_id] = api_define_sprite(carpet_id, carpet_sprite, 16)
  ce_define_flooring(carpet_id, carpet_item_sprite)
end

function ce_define_flooring(carpet_id, carpet_item_sprite)
  --api_define_item()
end

function ce_define_items()

  -- define a custom item
  api_define_menu_object({
    id = "carpet_engine",
    name = "Carpet Engine",
    category = "Floors",
    tooltip = "Just pretend you don't see me.",
    menu = false,
    layout = {},
    cost = { buy = 1, sell = 1 },
    tools = { "hammer1" },
    buttons = {},
    info = {},
    machines = {},
    placeable = false,
    depth = -500 }, "sprites/carpets.png", "sprites/carpets.png", { define = "carpet_engine_define", tick = "carpet_engine_tick" },
    "ce_draw_map")

end

function carpet_engine_define(menu_id)
  local obj_id = api_get_menus_obj(menu_id)
  local immortal = api_set_immortal(obj_id, true)

  CE.control = obj_id
end

function carpet_engine_tick(menu_id)
  local cam = api_get_cam()
  api_sp(CE.control, "x", cam.x)
  api_sp(CE.control, "y", cam.y)
end

function ce_draw_map(obj_id)
  for x = CE.camera.min_x, CE.camera.max_x do
    for y = CE.camera.min_y, CE.camera.max_y do
      if CE.map[x][y] ~= nil then
        api_draw_sprite(
          CE.sprites[CE.map[x][y].sprite],
          CE.map[x][y].frame,
          CE.map[x][y].x,
          CE.map[x][y].y
        )
      end
    end
  end
end

---------------------------------------------------------------------------------------------
--Map Functions
---------------------------------------------------------------------------------------------

function ce_flatten_map()
  output_table = {}

  for x = CE.camera.min_x, CE.camera.max_x do
    for y = CE.camera.min_y, CE.camera.max_y do
      if CE.map[x][y] ~= nil then
        table.insert(output_table, {
          tile_x = x,
          tile_y = y,
          sprite = CE.map[x][y].sprite,
          frame = CE.map[x][y].frame,
          x = CE.map[x][y].x,
          y = CE.map[x][y].y
        })
      end
    end
  end
  return output_table
end

function ce_expand_map(input_table)
  for _, value in pairs(input_table) do
    if value ~= nil and value ~= {} then
      CE.map[value.tile_x][value.tile_y] = {
        sprite = value.sprite,
        frame = value.frame,
        x = value.x,
        y = value.y
      }
    end
  end
end

function _tile(tile_pos)
  return math.floor(tile_pos / 16)
end

function ce_set_camera()
  local camera = api_get_cam()
  local screen = api_get_game_size()
  CE.camera.min_x = _tile(camera.x)
  CE.camera.max_x = CE.camera.min_x + _tile(screen.width)
  CE.camera.min_y = _tile(camera.y)
  CE.camera.max_y = CE.camera.min_y + _tile(screen.height)
end

function ce_create_map()
  local new_map = {}
  for x = 1, 291 do
    row = {}
    for y = 1, 291 do
      table.insert(row, nil)
    end
    table.insert(new_map, row)
  end
  return new_map
end

function ce_masktiles(tile_x, tile_y, placed)
  if placed == true then
    --placed
    ce_nearby_carpets({ x = tile_x, y = tile_y }, true, true)
  else
    --removed
    CE.map[tile_x][tile_y] = nil
    ce_nearby_carpets({ x = tile_x, y = tile_y }, true, false)
  end
end

function ce_nearby_carpets(tile_pos, first, placed)
  local shape_num = 0
  local nearby_tiles = {
    up = { x = tile_pos.x, y = tile_pos.y - 1 },
    right = { x = tile_pos.x + 1, y = tile_pos.y },
    down = { x = tile_pos.x, y = tile_pos.y + 1 },
    left = { x = tile_pos.x - 1, y = tile_pos.y }
  }
  if first == true then
    --up (0001) +1
    if CE.map[nearby_tiles.up.x][nearby_tiles.up.y] ~= nil then
      shape_num = shape_num + 1
      ce_nearby_carpets(nearby_tiles.up, false)
    end
    --right (0010) +2
    if CE.map[nearby_tiles.right.x][nearby_tiles.right.y] ~= nil then
      shape_num = shape_num + 2
      ce_nearby_carpets(nearby_tiles.right, false)
    end
    --down (0100) +4
    if CE.map[nearby_tiles.down.x][nearby_tiles.down.y] ~= nil then
      shape_num = shape_num + 4
      ce_nearby_carpets(nearby_tiles.down, false)
    end
    --left (1000) +8
    if CE.map[nearby_tiles.left.x][nearby_tiles.left.y] ~= nil then
      shape_num = shape_num + 8
      ce_nearby_carpets(nearby_tiles.left, false)
    end
    if placed == true then
      CE.map[tile_pos.x][tile_pos.y].frame = shape_num
    end
  else
    --up (0001) +1
    if CE.map[nearby_tiles.up.x][nearby_tiles.up.y] ~= nil then
      shape_num = shape_num + 1
    end
    --right (0010) +2
    if CE.map[nearby_tiles.right.x][nearby_tiles.right.y] ~= nil then
      shape_num = shape_num + 2
    end
    --down (0100) +4
    if CE.map[nearby_tiles.down.x][nearby_tiles.down.y] ~= nil then
      shape_num = shape_num + 4
    end
    --left (1000) +8
    if CE.map[nearby_tiles.left.x][nearby_tiles.left.y] ~= nil then
      shape_num = shape_num + 8
    end
    CE.map[tile_pos.x][tile_pos.y].frame = shape_num
  end
end
