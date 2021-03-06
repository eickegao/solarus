local map = ...
-- Outside world C3

local fighting_boss = false
local arrows_timer

function map:on_started(destination)

  local new_music = nil
  if destination ~= nil and destination:get_name() == "from_ending" then
    -- game ending sequence
    hero:freeze()
    hero:set_visible(false)
    map:get_game():set_hud_enabled(false)
    map:set_entities_enabled("enemy", false)
    new_music = "fanfare"
    map:set_entities_enabled("roof_entrance", false)
  else
    -- enable dark world
    if map:get_game():get_value("b905") then
      new_music = "dark_mountain"
      map:set_tileset(13)
    else
      new_music = "overworld"
    end

    -- boss fight
    if destination ~= nill and destination:get_name() == "from_dungeon_10_5f" then

      if not map:get_game():get_value("b299") then
	-- boss not killed yet
        new_music = "none"
        map:set_entities_enabled("enemy", false) -- disable all simple enemies
      elseif not map:get_game():get_value("b298") then
	-- boss killed but sword not got yet
	local variant = 2
	if map:get_game():get_ability("sword") >= 2 then
	  -- the player already has the second one: give the third one instead
	  variant = 3
	end
	map:create_pickable{
	  treasure_name = "sword",
	  treasure_variant = variant,
	  treasure_savegame_variable = "b298",
	  x = 440,
	  y = 157,
	  layer = 1
	}
      end
    else
      map:set_entities_enabled("roof_entrance", false)
    end
  end

  sol.audio.play_music(new_music)
end

function map:on_opening_transition_finished(destination)

  if destination ~= nil and destination:get_name() == "from_ending" then
    map:start_dialog("credits_6", function()
      sol.timer.start(2000, function()
        hero:teleport(131, "from_ending")
      end)
    end)
    map:move_camera(440, 96, 20, function() end, 1e6)
  end
end

local function repeat_give_arrows()

  -- give arrows if necessary during the boss fight
  if map:get_game():get_item("bow"):get_amount() == 0 then
    local positions = {
      { x = 408, y = 189 },
      { x = 472, y = 189 },
    }
    arrow_xy = positions[math.random(#positions)]
    map:create_pickable{
      treasure_name = "arrow",
      treasure_variant = 3,
      x = arrow_xy.x,
      y = arrow_xy.y,
      layer = 1
    }
  end
  arrows_timer = sol.timer.start(20000, repeat_give_arrows)
end

function start_boss_sensor:on_activated()

  if not map:get_game():get_value("b299")
      and not fighting_boss then

    -- boss fight
    hero:freeze()
    map:set_entities_enabled("roof_entrance", false)
    roof_stairs:set_enabled(false)
    roof_teletransporter:set_enabled(false)
    sol.audio.play_sound("door_closed")
    sol.timer.start(1000, function()
      sol.audio.play_music("boss")
      boss:set_enabled(true)
      hero:unfreeze()
      fighting_boss = true
      arrows_timer = sol.timer.start(20000, repeat_give_arrows)
    end)
  end
end

if boss ~= nil then
  function boss:on_dead()
    -- give the second sword
    local variant = 2
    if map:get_game():get_ability("sword") == 2 then
      -- the player already has the second one: give the third one instead
      variant = 3
    end
    map:create_pickable{
      treasure_name = "sword",
      treasure_variant = variant,
      treasure_savegame_variable = "b298",
      x = 440,
      y = 189,
      layer = 1
    }
    if arrows_timer ~= nil then
      arrows_timer:stop()
      arrows_timer = nil
    end
  end
end

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if item:get_name() == "sword" then
    sol.audio.play_music("excalibur")
  end
end

function map:on_obtained_treasure(item, variant, savegame_variable)

  if item:get_name() == "sword" then
    hero:start_victory(function()
      map:get_game():set_dungeon_finished(10)
      hero:teleport(119, "from_dungeon_10")
      map:set_entities_enabled("enemy", true) -- enable simple enemies back

      sol.timer.start(1000, function()
        if map:get_game():get_value("b905") then
          sol.audio.play_music("dark_mountain")
        else
          sol.audio.play_music("overworld")
        end
      end)
    end)
  end
end

