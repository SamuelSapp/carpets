--[[
  items = {[oid] = {sprite = sprite, infinite = boolean, size = number}},
  map = {
    [1-291] = {
      [1-291] = {
        sprite_id = oid,
        frame = number,
        x = number,
        y = number
      }
    }
  },
]]--

CE = {
  mod_name = "",
  data = {},
  items = {},
  preview_sprite = nil,
  map = {},
  camera = { min_x = 0, max_x = 0, min_y = 0, max_y = 0 },
  action = { placing = nil, removing = false },
  frames = {
    [48] = {
      [208] = 0,
      [248] = 1,
      [104] = 2,
      [64] = 3,
      [80] = 4,
      [88] = 5,
      [72] = 6,
      [127] = 7,
      [95] = 8,
      [223] = 9,
      [214] = 10,
      [255] = 11,
      [107] = 12,
      [66] = 13,
      [82] = 14,
      [90] = 15,
      [74] = 16,
      [123] = 17,
      [222] = 19,
      [22] = 20,
      [31] = 21,
      [11]  = 22,
      [2] = 23,
      [18] = 24,
      [26] = 25,
      [10] = 26,
      [251] = 27,
      [250] = 28,
      [254] = 29,
      [16] = 30,
      [24] = 31,
      [8] = 32,
      [0] = 33,
      [120] = 34,
      [75] = 35,
      [86] = 36,
      [216] = 37,
      [91] = 38,
      [94] = 39,
      [30] = 40,
      [27] = 41,
      [219] = 42,
      [126] = 43,
      [210] = 44,
      [106] = 47,
      [122] = 48,
      [218] = 49
    },
    [16] = {
      [80] = 0,
      [88] = 1,
      [72] = 2,
      [64] = 3,
      [82] = 4,
      [90] = 5,
      [74] = 6,
      [66] = 7,
      [18] = 8,
      [26] = 9,
      [10]  = 10,
      [2] = 11,
      [16] = 12,
      [24] = 13,
      [8] = 14,
      [0] = 15,
    }
  }
}

---------------------------------------------------------------------------------------------
--Hooks
---------------------------------------------------------------------------------------------

function ce_init(mod_name)
  CE.mod_name = mod_name
  ce_define_items()
end

function ce_ready()
  CE.map = ce_create_map()
  api_get_data()
  local save_id = api_get_filename()
  if CE["data"][save_id] == nil then
    CE["data"][save_id] = {}
  end
  ce_set_camera()
end

function ce_save()
  local save_id = api_get_filename()
  local save_data = CE.data
  save_data[save_id] = ce_flatten_map()
  return save_data
end

function ce_load(data)
  if data["ce_map"] ~= nil then
    CE.data = data["ce_map"]
    local save_id = api_get_filename()
    if data["ce_map"][save_id] ~= nil then
      ce_expand_map(data["ce_map"][save_id])
    end
  else
    CE.data = {}
  end
end


--player place range = 9 tiles
function ce_click(button, click_type)
  
  local equipped_item = api_get_equipped()
  if (button == "LEFT" and click_type == "PRESSED") then
    if CE.items[equipped_item] ~= nil then
      CE.action.placing = equipped_item
      ce_place_tile()
    end

    if equipped_item == CE.mod_name.."_scraper" then
      CE.action.removing = true
      ce_remove_tile()
    end
  end

  if (button == "LEFT" and click_type == "RELEASED") then
    CE.action.placing = nil
    CE.action.removing = false
  end
end

function ce_tick()
  ce_set_camera()
  ce_tile_preview()
  if CE.action.placing ~= nil then
    ce_place_tile()
  end
  if CE.action.removing == true then
    ce_remove_tile()
  end
end

function ce_tdraw()
  local cam = api_get_camera_position()
  for x = CE.camera.min_x, CE.camera.max_x do
    for y = CE.camera.min_y, CE.camera.max_y do
      if CE.map[x][y] ~= nil then
        api_draw_sprite(
          CE.items[CE.map[x][y].sprite_id].sprite,
          CE.map[x][y].frame,
          CE.map[x][y].x - cam.x,
          CE.map[x][y].y - cam.y
        )
      end
    end
  end
  local mouse_tile = api_get_mouse_tile_position()
  if CE.preview_sprite_id ~= nil then
    api_draw_sprite_ext(
          CE.items[CE.preview_sprite_id].sprite,
          CE.frames[CE.items[CE.preview_sprite_id].size][0],
          mouse_tile.x - cam.x,
          mouse_tile.y - cam.y,
          1,
          1,
          0,
          nil,
          0.4
        )
  end
end

---------------------------------------------------------------------------------------------
--Items and Register
---------------------------------------------------------------------------------------------

function ce_register_flooring(item_def, carpet_sprite, carpet_item_sprite, infinite_use, sprite_size)
  CE.items[CE.mod_name.."_"..item_def.id] = {sprite = nil, infinite = infinite_use, size = sprite_size}
  CE.items[CE.mod_name.."_"..item_def.id].sprite = api_define_sprite(item_def.id, carpet_sprite, sprite_size)
  ce_define_flooring(item_def, carpet_item_sprite, infinite_use)
end

function ce_define_flooring(item_def, carpet_item_sprite, infinite_use)
  api_define_item({
    id = item_def.id,
    name = item_def.name,
    category = "Flooring",
    tooltip = item_def.tooltip,
    shop_buy = item_def.shop_buy,
    shop_sell = item_def.shop_sell,
    singular = infinite_use
  },carpet_item_sprite)
end


function ce_define_items()
  api_define_item({
    id = "scraper",
    name = "Scraper",
    category = "Decoration",
    tooltip = "Used to remove tiles.",
    singular = true
  }, "sprites/scraper_item.png")
end

---------------------------------------------------------------------------------------------
--Map Functions
---------------------------------------------------------------------------------------------

function ce_flatten_map()
  local output_table = {}

  for x = 1, 291 do
    for y = 1, 291 do
      if CE.map[x][y] ~= nil then
        table.insert(output_table, {
          tile_x = x,
          tile_y = y,
          sprite_id = CE.map[x][y].sprite_id,
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
        sprite_id = value.sprite_id,
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

function ce_place_tile()
  local mouse_tile = api_get_mouse_tile_position()
  if ce_check_ground(mouse_tile.x, mouse_tile.y) then
    local player_tile = api_get_player_tile_position()
    if ce_distance(player_tile.x, player_tile.y, mouse_tile.x, mouse_tile.y) <= 144 then
      local mx = _tile(mouse_tile.x)
      local my = _tile(mouse_tile.y)
      if CE.map[mx][my] == nil then
        CE.map[mx][my] = {
          sprite_id = CE.action.placing,
          frame = 0,
          x = mouse_tile.x,
          y = mouse_tile.y
        }
        ce_masktiles(mx, my, true)
      end
    end
  end
end

function ce_remove_tile()
  local mouse_tile = api_get_mouse_tile_position()
  local player_tile = api_get_player_tile_position()
  if ce_distance(player_tile.x, player_tile.y, mouse_tile.x, mouse_tile.y) <= 144 then
    local mx = _tile(mouse_tile.x)
    local my = _tile(mouse_tile.y)
    if CE.map[mx][my] ~= nil then
      CE.map[mx][my] = nil
      ce_masktiles(mx, my, false)
    end
  end
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
    local row = {}
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
  --1 = up, 2 = left, 3 = right, 4 = down
  --5 = up+left, 6 = up+right, 7 = down+left, 8 = down+right
  local nearby_tiles = {
    [1] = { x = tile_pos.x, y = tile_pos.y - 1, value = 2, ready = 2, helps = {5,6} },
    [2] = { x = tile_pos.x - 1, y = tile_pos.y, value = 8, ready = 2, helps = {5,7} },
    [3] = { x = tile_pos.x + 1, y = tile_pos.y, value = 16, ready = 2, helps = {6,8} },
    [4] = { x = tile_pos.x, y = tile_pos.y + 1, value = 64, ready = 2, helps = {7,8} },
    [5] = { x = tile_pos.x - 1, y = tile_pos.y - 1, value = 1, ready = 0 },
    [6] = { x = tile_pos.x + 1, y = tile_pos.y - 1, value = 4, ready = 0 },
    [7] = { x = tile_pos.x - 1, y = tile_pos.y + 1, value = 32, ready = 0 },
    [8] = { x = tile_pos.x + 1, y = tile_pos.y + 1, value = 128, ready = 0 }
  }
  local size = 1
  if first == false or placed == true then
    size = CE.items[CE.map[tile_pos.x][tile_pos.y].sprite_id].size
  end
  
  

  if first == true then
    for index, next_tile in ipairs(nearby_tiles) do
      if CE.map[next_tile.x][next_tile.y] ~= nil then
        if next_tile.ready == 2 then
          if (size == 48 or index <= 4) and size ~= 1 then
            shape_num = shape_num + next_tile.value
          end
          if next_tile.helps ~= nil then
            nearby_tiles[next_tile.helps[1]].ready = nearby_tiles[next_tile.helps[1]].ready + 1
            nearby_tiles[next_tile.helps[2]].ready = nearby_tiles[next_tile.helps[2]].ready + 1
          end
          ce_nearby_carpets(next_tile, false, true)
        end
      end
    end
    if placed == true then
      CE.map[tile_pos.x][tile_pos.y].frame = CE.frames[size][shape_num]
    end
  else
    for index, next_tile in ipairs(nearby_tiles) do
      if CE.map[next_tile.x][next_tile.y] ~= nil then
        if next_tile.ready == 2 then
          if (size == 48 or index <= 4) and size ~= 1 then
            shape_num = shape_num + next_tile.value
          end
          if next_tile.helps ~= nil then
            nearby_tiles[next_tile.helps[1]].ready = nearby_tiles[next_tile.helps[1]].ready + 1
            nearby_tiles[next_tile.helps[2]].ready = nearby_tiles[next_tile.helps[2]].ready + 1
          end
        end
      end
    end
    CE.map[tile_pos.x][tile_pos.y].frame = CE.frames[size][shape_num]
  end
end

function ce_distance ( x1, y1, x2, y2 )
  local dx = x1 - x2
  local dy = y1 - y2
  return math.sqrt ( dx * dx + dy * dy )
end

function ce_check_ground(tx, ty)
  local ground = api_get_ground(tx,ty)
  local floor = api_get_floor(tx,ty)
  if string.sub(ground,1,5) == "grass" or floor ~= "tile0" then
    return true
  else
    return false
  end
end

function ce_tile_preview()
  local equipped_item = api_get_equipped()
  if CE.items[equipped_item] ~= nil then
    CE.preview_sprite_id = equipped_item
  else
    CE.preview_sprite_id = nil
  end
end