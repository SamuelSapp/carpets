MOD_NAME = "carpets"

function register()

  return {
    name = MOD_NAME,
    hooks = { "ready", "save", "data", "click", "tick" },
    modules = { "carpet_engine" }
  }
end

function init()
  api_set_devmode(true)
  ce_init()
  ce_register_carpet("check_rug1", "sprites/checkrug1.png", "sprites/checkrug1_item.png")
  return "Success"
end

function ready()
  ce_ready()
end

function save()
  ce_save()
end

function data(ev, data)
  if ev == "LOAD" and data ~= nil then
    ce_load(data)
  end

  if ev == "SAVE" then

  end

end

function click(button, click_type)
  ce_click(button, click_type)
end

function tick()
  ce_tick()
end
