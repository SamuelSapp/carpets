MOD_NAME = "tiling_engine"

check_rug_def = {id="check_rug1", name="Checkered Rug", tooltip="This is a checkered rug.", shop_buy = 5, shop_sell = 2, carpet_sprite = "sprites/checkrug1.png", carpet_item_sprite = "sprites/checkrugitem.png", infinite_use = true, sprite_size = 16}
pink_rug_def = {id="check_pink", name="Pink Checkered Rug", tooltip="This is a pink checkered rug.", shop_buy = 5, shop_sell = 2, carpet_sprite ="sprites/checkrug_pink.png",carpet_item_sprite = "sprites/checkrug_pink_item.png",infinite_use = false,sprite_size = 16}
fake_swamp_def = {id="fake_swamp", name = "Fake Swamp", tooltip="This floor looks all swampy!", shop_buy = 50, shop_sell = 1, carpet_sprite = "sprites/fake_swamp.png", carpet_item_sprite = "sprites/fake_swamp_item.png", infinite_use =true,sprite_size = 48}
blue_rug_def = {id="check_blue", name="Blue Checkered Rug", tooltip="This is a blue checkered rug.", shop_buy = 5, shop_sell = 2, carpet_sprite ="sprites/checkrug_blue.png",carpet_item_sprite = "sprites/checkrug_blue_item.png",infinite_use = true,sprite_size = 1}

function register()

  return {
    name = MOD_NAME,
    hooks = { "ready", "save", "data", "click", "tick", "tdraw", "worldgen"},
    modules = { "carpet_engine" }
  }
end

function init()
  api_set_devmode(true)
  ce_init(MOD_NAME)
  ce_register_flooring(check_rug_def)
  ce_register_flooring(pink_rug_def)
  ce_register_flooring(fake_swamp_def)
  ce_register_flooring(blue_rug_def)
  api_define_command("/carpet_test", "carpet_test_command")
  return "Success"
end

function ready()
  ce_ready()
end

function save()
  local save_data = {}
  save_data["ce_map"] = ce_save()
  api_set_data(save_data)
end

function data(ev, data)
  if ev == "LOAD" and data ~= nil then
    ce_load(data)
  end
end

function click(button, click_type)
  ce_click(button, click_type)
end

function tick()
  ce_tick()
end

function tdraw()
  ce_tdraw()
end

function worldgen(before_objects)
  ce_worldgen()
end

function carpet_test_command(args)
  local player_pos = api_get_player_position()
  for oid, props in pairs(CE.items) do
    local num = 1
    api_log("props", props)
    if props.infinite == false then
      num = 99
    end
    api_create_item(oid, num, player_pos.x, player_pos.y)
  end
  api_create_item("tiling_engine_scraper", 1, player_pos.x, player_pos.y)
end
