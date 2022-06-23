MOD_NAME = "carpets"

CE = {
  sprites={},
  control=nil,
  map = {},
  camera = {min_x = 0, max_x = 0, min_y = 0, max_y = 0},
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
  CE.map = ce_create_map()
  ce_register_carpet("check_rug1", "sprites/checkrug.png")
  define_item()
  api_define_command("/check", "check_engines")
  api_define_command("/pos", "engine_pos")
  api_get_data()
  return "Success"
end

function ready()
  ce_set_camera()
  local engines = api_get_menu_objects(nil, "carpets_carpet_engine")
  if #engines == 0 then
    api_create_obj("carpets_carpet_engine", CE.camera.min_x, CE.camera.min_y)
  elseif #engines >= 2 then
    for index, value in ipairs(engines) do
      if index == 1 then
      else
        api_destroy_inst(value.id)
      end
    end
  end
end

function save()
  save_data = ce_flatten_map()
  api_set_data(save_data)
end

function data(ev, data)
  if ev == "LOAD" and data ~= nil then
    ce_expand_map(data)
  end

  if ev == "SAVE" then

  end

end

function key(key_code)
end

function click(button, click_type)
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

function tick()
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
  local cam = api_get_cam()
  api_sp(CE.control, "x", cam.x)
  api_sp(CE.control, "y", cam.y)
end

function rug_draw(obj_id)
  local cam = api_get_cam()
  for x=CE.camera.min_x, CE.camera.max_x do
    for y=CE.camera.min_y, CE.camera.max_y do
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

function check_engines(args)
  api_log("carpet_control:", CE.control)
  api_log("check engines:", api_get_menu_objects(nil, "carpets_carpet_engine"))
end

function engine_pos(args)
  local pos = { api_gp(CE.control, "x"), api_gp(CE.control, "y") }
  api_log("x,y", pos)
end

function ce_flatten_map()
  output_table = {}

  for x=CE.camera.min_x, CE.camera.max_x do
    for y=CE.camera.min_y, CE.camera.max_y do
      if CE.map[x][y] ~= nil then
        table.insert(output_table, {
          tile_x=x,
          tile_y=y,
          sprite=CE.map[x][y].sprite,
          frame=CE.map[x][y].frame,
          x=CE.map[x][y].x,
          y=CE.map[x][y].y
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
        sprite=value.sprite,
        frame=value.frame,
        x=value.x,
        y=value.y
      }
    end
  end
end

function ce_register_carpet(carpet_id, carpet_sprite)
  CE.sprites[carpet_id] = api_define_sprite(carpet_id, carpet_sprite, 16)
end

function _tile(tile_pos)
  return math.floor(tile_pos/16)
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
  for x=1,291 do
    row = {}
    for y=1, 291 do
      table.insert(row,nil)
    end
    table.insert(new_map,row)
  end
  return new_map
end

function ce_masktiles(tile_x, tile_y, placed)
  if placed == true then
    --placed
    ce_nearby_carpets({x=tile_x, y=tile_y}, true, true)
  else
    --removed
    CE.map[tile_x][tile_y] = nil
    ce_nearby_carpets({x=tile_x, y=tile_y}, true, false)
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
