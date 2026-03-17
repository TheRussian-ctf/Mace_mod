local BASE_DAMAGE = 5
local fall_start_y = {}
local fall_speed = {}

local function get_fall_damage(blocks)
    return math.floor(BASE_DAMAGE + (blocks * 50))
end

local function spawn_wind_particles(pos)
    minetest.add_particlespawner({amount=120,time=0.1,minpos=vector.subtract(pos,0.2),maxpos=vector.add(pos,0.2),minvel={x=-14,y=4,z=-14},maxvel={x=14,y=18,z=14},minacc={x=0,y=-10,z=0},maxacc={x=0,y=-10,z=0},minexptime=0.4,maxexptime=1.0,minsize=2.0,maxsize=4.5,collisiondetection=false,vertical=false,texture="mace_wind_particle.png",glow=10})
end

local function launch_player(player)
    local name = player:get_player_name()
    local pos = player:get_pos()
    local fell = fall_start_y[name] and (fall_start_y[name] - pos.y) or 0
    if fell < 2 then return end
    player:set_armor_groups({immortal=1})
    player:add_velocity({x=0, y=26, z=0})
    spawn_wind_particles(pos)
    minetest.chat_send_player(name, "💨 Launched! ("..math.floor(fell).." blocks → "..get_fall_damage(fell).." dmg)")
    minetest.after(0.5, function()
        if player and player:is_player() then
            player:set_armor_groups({immortal=0})
        end
    end)
end

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local vel = player:get_velocity()
        local pos = player:get_pos()
        if vel and pos then
            if vel.y < -1 then
                if not fall_start_y[name] or fall_start_y[name] == 0 then
                    fall_start_y[name] = pos.y
                end
                fall_speed[name] = math.abs(vel.y)
            elseif vel.y >= -0.5 and fall_speed[name] and fall_speed[name] > 2 then
                fall_speed[name] = 0
                fall_start_y[name] = 0
            elseif vel.y > 0 then
                fall_speed[name] = 0
                fall_start_y[name] = 0
            end
        end
    end
end)

-- Hit player
minetest.register_on_punchplayer(function(player, hitter, time, caps, dir, damage)
    if hitter and hitter:is_player() then
        if hitter:get_wielded_item():get_name() == "mace_mod:mace" then
            launch_player(hitter)
        end
    end
end)

-- Hit mob — just launch the attacker, let tool_capabilities handle damage normally
minetest.register_on_mods_loaded(function()
    for n, def in pairs(minetest.registered_entities) do
        local old_on_punch = def.on_punch
        def.on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
            if puncher and puncher:is_player() then
                if puncher:get_wielded_item():get_name() == "mace_mod:mace" then
                    launch_player(puncher)
                end
            end
            if old_on_punch then
                return old_on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
            end
        end
    end
end)

minetest.register_tool("mace_mod:mace", {
    description = "Mace",
    inventory_image = "mace_item.png",
    wield_image = "mace_item.png",
    wield_scale = {x=1.5,y=1.5,z=1.0},
    tool_capabilities = {
        full_punch_interval = 0.9,
        max_drop_level = 1,
        groupcaps = {
            fleshy={times={[1]=1.5,[2]=0.9,[3]=0.6},uses=200,maxlevel=2},
            snappy={times={[1]=2.0,[2]=1.0,[3]=0.5},uses=200,maxlevel=3},
            choppy={times={[1]=2.5,[2]=1.4,[3]=1.0},uses=200,maxlevel=2},
        },
        damage_groups = {fleshy=BASE_DAMAGE},
    },
})

minetest.register_craft({output="mace_mod:mace",recipe={{"default:steel_ingot","default:steel_ingot"},{"default:steel_ingot","default:steel_ingot"},{"","default:stick"}}})
minetest.log("action", "[mace_mod] Mace mod loaded!")
