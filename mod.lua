MOD_NAME = "tiling_engine"

function register()

  return {
    name = MOD_NAME,
    hooks = { "ready", "save", "data", "click", "tick", "tdraw"},
    modules = { "carpet_engine" }
  }
end

function init()
  api_set_devmode(true)
  ce_init(MOD_NAME)
  ce_register_flooring({id="check_rug1", name="Checkered Rug", tooltip="This is a checkered rug.", shop_buy = 5, shop_sell = 2,}, "sprites/checkrug1.png", "sprites/checkrugitem.png", true, 16)
  ce_register_flooring({id="check_pink", name="Pink Checkered Rug", tooltip="This is a pink checkered rug.", shop_buy = 5, shop_sell = 2,}, "sprites/checkrug_pink.png", "sprites/checkrug_pink_item.png", true, 16)
  ce_register_flooring({id="fake_swamp", name = "Fake Swamp", tooltip="This floor looks all swampy!", shop_buy = 50, shop_sell = 1}, "sprites/fake_swamp.png", "sprites/fake_swamp_item.png", true, 48)
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