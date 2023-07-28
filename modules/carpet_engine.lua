-- controller
CE = {
  delete_data = false,
  mod_name = "",
  player_inst_id = nil,
  data = {},
  items = {},
  preview_sprite = nil,
  map = {},
  camera = { min_x = 0, max_x = 0, min_y = 0, max_y = 0 },
  action = { placing = nil, removing = false },
  frames = {
    [48] = { 
      [208] = 0, [248] = 1, [104] = 2, [64] = 3, [80] = 4, [88] = 5, [72] = 6, [127] = 7, 
      [95] = 8, [223] = 9, [214] = 10, [255] = 11, [107] = 12, [66] = 13, [82] = 14, [90] = 15, 
      [74] = 16, [123] = 17, [222] = 19, [22] = 20, [31] = 21, [11] = 22, [2] = 23, 
      [18] = 24, [26] = 25, [10] = 26, [251] = 27, [250] = 28, [254] = 29, [16] = 30, [24] = 31, 
      [8] = 32, [0] = 33, [120] = 34, [75] = 35, [86] = 36, [216] = 37, [91] = 38, [94] = 39, 
      [219] = 42, [126] = 43, [210] = 44, [30] = 45, [27] = 46, [106] = 47, [122] = 48, [218] = 49
    },
    [16] = { 
      [80] = 0, [88] = 1, [72] = 2, [64] = 3, [82] = 4, [90] = 5, [74] = 6, [66] = 7, 
      [18] = 8, [26] = 9, [10] = 10, [2] = 11, [16] = 12, [24] = 13, [8] = 14, [0] = 15,
    },
    [1] = {[0] = 0}
  }
}

---------------------------------------------------------------------------------------------
--Hooks
---------------------------------------------------------------------------------------------

-- define items
function ce_init(mod_name)
  CE.mod_name = mod_name
  ce_define_items()
end

-- get map when ready
function ce_ready()
  CE.map = ce_create_map()
  api_get_data()
  local save_id = api_get_filename()
  if CE["data"][save_id] == nil then
    CE["data"][save_id] = {}
  end
  CE.player_inst_id = api_get_player_instance()
end

-- save current grid map
function ce_save()
  local save_id = api_get_filename()
  local save_data = CE.data
  save_data[save_id] = ce_flatten_map()
  return save_data
end

-- load existing grid map if any
function ce_load(data)
  if data["ce_map"] ~= nil then
    CE.data = data["ce_map"]
    local save_id = api_get_filename()
    if data["ce_map"][save_id] ~= nil and CE.delete_data == false then
      ce_expand_map(data["ce_map"][save_id])
    end
  else
    CE.data = {}
  end
end

-- handle tile place/remove plus start stop any mouse drag
function ce_click(button, click_type)
  -- get equipped item
  local equipped_item = api_get_equipped()
  if (button == "LEFT" and click_type == "PRESSED") then
    -- check if equipped item is registered as a carpet
    if CE.items[equipped_item] ~= nil then
      CE.action.placing = equipped_item
      ce_place_tile()
    end
    -- check if equipped item is registered as a scraper
    if equipped_item == CE.mod_name .. "_scraper" then
      CE.action.removing = true
      ce_remove_tile()
    end
  end

  if (button == "LEFT" and click_type == "RELEASED") then
    CE.action.placing = nil
    CE.action.removing = false
  end
end

-- handle tile preview update and placing/removing during mouse drag
function ce_tick()
  ce_tile_preview()
  if CE.action.placing ~= nil then
    if CE.action.placing ~= api_get_equipped() then
      CE.action.placing = nil
    else
      ce_place_tile()
    end
  end
  if CE.action.removing == true then
    if api_get_equipped() ~= CE.mod_name .. "_scraper" then
      CE.action.removing = false
    else
      ce_remove_tile()
    end
  end
end

-- draw tile preview if any
-- tiles themselves drawn automatically by lightweights
function ce_tdraw()
  local cam = api_get_camera_position()
  if CE.preview_sprite_id ~= nil then
    local mouse_tile = api_get_mouse_tile_position()
    api_draw_sprite_ext(
      CE.items[CE.preview_sprite_id].sprite,
      CE.frames[CE.items[CE.preview_sprite_id].size][0],
      mouse_tile.x - cam.x, mouse_tile.y - cam.y,
      1, 1, 0, nil, 0.4
    )
  end
end

-- reset grid on new world
function ce_worldgen()
  CE.delete_data = true
end

---------------------------------------------------------------------------------------------
--Items and Register
---------------------------------------------------------------------------------------------

function ce_register_flooring(item_def)
  local new_item_def = {
    id = item_def.id or "error_no_id",
    name = item_def.name or "error_no_name",
    tooltip = item_def.tooltip or "error_no_tooltip",
    shop_buy = item_def.shop_buy or 0,
    shop_sell = item_def.shop_sell or 0,
    carpet_sprite = item_def.carpet_sprite or "error_no_sprite",
    carpet_item_sprite = item_def.carpet_item_sprite or "error_no_item_sprite",
    infinite_use = item_def.infinite_use or false,
    sprite_size = item_def.sprite_size or 16 }
  CE.items[CE.mod_name .. "_" .. new_item_def.id] = { sprite = nil, infinite = new_item_def.infinite_use, size = new_item_def.sprite_size }
  CE.items[CE.mod_name .. "_" .. new_item_def.id].sprite = api_define_sprite(new_item_def.id, new_item_def.carpet_sprite, new_item_def.sprite_size)
  ce_define_flooring(new_item_def)
end

function ce_define_flooring(item_def)
  api_define_item({
    id = item_def.id,
    name = item_def.name,
    category = "Flooring",
    tooltip = item_def.tooltip,
    shop_buy = item_def.shop_buy,
    shop_sell = item_def.shop_sell,
    singular = item_def.infinite_use
  }, item_def.carpet_item_sprite)
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

-- flatten map to remove empty cells
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

-- exapdn map into full world grid, creating new lightweights as needed
function ce_expand_map(input_table)
  for _, value in pairs(input_table) do
    if value ~= nil and value ~= {} then
      CE.map[value.tile_x][value.tile_y] = {
        sprite_id = value.sprite_id,
        frame = value.frame,
        x = value.x,
        y = value.y,
        lw = ce_create_tile(CE.items[value.sprite_id].sprite, value.frame, value.x, value.y)
      }
    end
  end
end

-- create a new lightweight for tile drawing
function ce_create_tile(sprite_id, frame, x, y) 
  return api_create_lightweight("tile", sprite_id, frame, x, y)
end

-- place a tile at a set position as long as it's on grass or tiles
function ce_place_tile()
  local mouse_tile = api_get_mouse_tile_position()
  if ce_check_ground(mouse_tile.x, mouse_tile.y) then
    local player_tile = api_get_player_tile_position()
    if ce_distance(player_tile.x, player_tile.y, mouse_tile.x, mouse_tile.y) <= 160 then
      local mx = math.floor(mouse_tile.x / 16)
      local my = math.floor(mouse_tile.y / 16)
      if CE.map[mx][my] == nil then
        CE.map[mx][my] = {
          sprite_id = CE.action.placing,
          frame = 0,
          x = mouse_tile.x,
          y = mouse_tile.y,
          lw = ce_create_tile(CE.items[CE.action.placing].sprite, 0, mouse_tile.x, mouse_tile.y)
        }
        ce_set_tilemask({ x = mx, y = my }, true, true)
        if CE.items[CE.action.placing].infinite == false then
          ce_reduce_equipped_item()
        end
      end
    end
  end
end

-- remove a tile at a set position, removing the lightweight too
function ce_remove_tile()
  local mouse_tile = api_get_mouse_tile_position()
  local player_tile = api_get_player_tile_position()
  if ce_distance(player_tile.x, player_tile.y, mouse_tile.x, mouse_tile.y) <= 160 then
    local mx = math.floor(mouse_tile.x / 16)
    local my = math.floor(mouse_tile.y / 16)
    if CE.map[mx][my] ~= nil then
      if CE.items[CE.map[mx][my].sprite_id].infinite == false then
        ce_give_tile_item(CE.map[mx][my].sprite_id,mouse_tile.x, mouse_tile.y)
      end
      api_destroy_inst(CE.map[mx][my].lw)
      CE.map[mx][my] = nil
      ce_set_tilemask({ x = mx, y = my }, true, false)
    end
  end
end

-- reduce equipped item (mouse or hotbar)
function ce_reduce_equipped_item()
  local mouse_inst = api_get_mouse_inst()
  if mouse_inst.item == CE.action.placing then
    api_slot_decr(mouse_inst.id)
  else
    api_slot_decr(api_get_slot(CE.player_inst_id,api_gp(CE.player_inst_id, "hotbar")+1).id)
  end
end

-- item create helper
function ce_give_tile_item(item_id, mouse_x, mouse_y)
  api_create_item(item_id, 1, mouse_x, mouse_y)
end

-- create a new map grid for tiles
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

-- set the tile bitmasking based off neighbour cells in the map grid
function ce_set_tilemask(tile_pos, first, placed)
  local shape_num = 0
  --1 = up, 2 = left, 3 = right, 4 = down
  --5 = up+left, 6 = up+right, 7 = down+left, 8 = down+right
  local nearby_tiles = {
    [1] = { x = tile_pos.x, y = tile_pos.y - 1, value = 2, ready = 2, helps = { 5, 6 } },
    [2] = { x = tile_pos.x - 1, y = tile_pos.y, value = 8, ready = 2, helps = { 5, 7 } },
    [3] = { x = tile_pos.x + 1, y = tile_pos.y, value = 16, ready = 2, helps = { 6, 8 } },
    [4] = { x = tile_pos.x, y = tile_pos.y + 1, value = 64, ready = 2, helps = { 7, 8 } },
    [5] = { x = tile_pos.x - 1, y = tile_pos.y - 1, value = 1, ready = 0 },
    [6] = { x = tile_pos.x + 1, y = tile_pos.y - 1, value = 4, ready = 0 },
    [7] = { x = tile_pos.x - 1, y = tile_pos.y + 1, value = 32, ready = 0 },
    [8] = { x = tile_pos.x + 1, y = tile_pos.y + 1, value = 128, ready = 0 }
  }
  local size = 1
  if first == false or placed == true then
    size = CE.items[CE.map[tile_pos.x][tile_pos.y].sprite_id].size
  end

  for index, next_tile in ipairs(nearby_tiles) do
    if CE.map[next_tile.x][next_tile.y] ~= nil and next_tile.ready == 2 then
      if (size == 48 or index <= 4) and size ~= 1 then
        shape_num = shape_num + next_tile.value
      end
      if next_tile.helps ~= nil then
        nearby_tiles[ next_tile.helps[1] ].ready = nearby_tiles[ next_tile.helps[1] ].ready + 1
        nearby_tiles[ next_tile.helps[2] ].ready = nearby_tiles[ next_tile.helps[2] ].ready + 1
      end
      if first == true then ce_set_tilemask(next_tile, false, true) end
    end
  end
  if placed == true then
    ce_update_tile(tile_pos.x, tile_pos.y, CE.frames[size][shape_num])
  end

end

-- update the tile in the map grid plus the lightweight frame it should draw with
function ce_update_tile(x, y, frame)
  tile = CE.map[x][y]
  tile.frame = frame
  api_sp(tile.lw, "image_index", frame)
end

-- get distance between 2 points
function ce_distance(x1, y1, x2, y2)
  local dx = x1 - x2
  local dy = y1 - y2
  return math.sqrt(dx * dx + dy * dy)
end

-- check if tile position is grass or has a tile
function ce_check_ground(tx, ty)
  local ground = api_get_ground(tx, ty)
  local floor = api_get_floor(tx, ty)
  if string.sub(ground, 1, 5) == "grass" or floor ~= "tile0" then
    return true
  else
    return false
  end
end

-- set tile preview to be shown
function ce_tile_preview()
  local equipped_item = api_get_equipped()
  if CE.items[equipped_item] ~= nil then
    CE.preview_sprite_id = equipped_item
  else
    CE.preview_sprite_id = nil
  end
end