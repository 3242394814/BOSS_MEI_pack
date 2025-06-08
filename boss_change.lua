-- 此文件的代码参考了 boss合集(可调整血量,攻击,掉落物,体型,和怪物随时间成长) 模组代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2677451059
-- 感谢菜菜菜

local function Get_players_number()
    local ClientObjs = TheNet:GetClientTable() or {}
    local players_number = #ClientObjs
    if not TheNet:GetServerIsClientHosted() then players_number = players_number - 1 end -- 专用服务器要排除掉【主机】

    return GetModConfigData("test_boss_change") and 20 or math.min(players_number, 20) -- 最高20倍
end

local function GetPlayerEnts(inst) -- 获取周围有多少活着的玩家
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 10, { "player" }, {"playerghost"})
    return #ents
end

local boss = {
    -- DST
	["deerclops"] = {}, -- 独眼巨鹿
    ["bearger"] = {}, -- 熊獾
    ["moose"] = {}, -- 麋鹿鹅
    ["minotaur"] = { -- 远古守护者
        set_drop_fn = function(inst, drop)
            local function minotaur_SpawnChest(inst, x, y, z) -- 远古守护者专属（生成大号华丽箱子）
                local chest = SpawnPrefab("minotaurchestspawner")
                chest.Transform:SetPosition(x, y, z)
                for i = 1, 8 do
                    if chest:PutBackOnGround(TILE_SCALE * i) then
                        break
                    end
                end
                chest.minotaur = inst
            end

            local x, y, z = inst.Transform:GetWorldPosition() -- 获取远古守护者位置
            local _x = x
            while drop > 1 do -- 额外掉落
                drop = drop - 1
                inst.components.lootdropper:DropLoot(Vector3(_x, y, z))  --额外掉落N倍
                x = x + 2
                minotaur_SpawnChest(inst, x, y, z) -- 生成额外大号华丽箱子
            end
        end
    },
    ["spiderqueen"] = {}, -- 蜘蛛女王
    ["warg"] = {}, -- 座狼
    ["dragonfly"] = {}, -- 龙蝇
    ["antlion"] = { -- 蚁狮
        set_health_fn = "StartCombat"
    },
    ["beequeen"] = {}, -- 蜂王
    ["klaus"] = { -- 克劳斯
        set_drop_fn = function(inst, drop)
            local function klaus_death(inst, x, y, z) -- 克劳斯专属（生成额外掉落）
                if inst and inst:IsUnchained() then
                    -- 生成额外钥匙
                    local key = SpawnPrefab("klaussackkey")
                    key.Transform:SetPosition(x, y, z)

                    -- 生成额外赃物袋
                    local klaus_sack = SpawnPrefab("klaus_sack")
                    klaus_sack.Transform:SetPosition(x, y, z)
                end
            end

            local x, y, z = inst.Transform:GetWorldPosition() -- 获取克劳斯位置
            local _x = x
            while drop > 1 do -- 额外掉落
                drop = drop - 1
                inst.components.lootdropper:DropLoot(Vector3(_x, y, z))  --额外掉落N倍
                x = x + 2
                klaus_death(inst, x, y, z) -- 额外掉落钥匙、赃物袋
            end
            drop = Get_players_number() -- 重置掉落倍数
        end
    },
    -- "stalker", -- 复活的骨架(洞穴)
    ["shadowthrall_horns"] = {}, -- 恐怖之眼
    ["twinofterror1"] = {}, -- 激光眼
    ["twinofterror2"] = {}, -- 魔焰眼
    ["daywalker"] = {}, -- 梦魇疯猪
    ["daywalker2"] = {}, -- 拾荒疯猪

	["malbatross"] = {}, -- 邪天翁
    -- "stalker_forest", -- 复活的骨架(森林守护者) 想白嫖？不可能！
    ["toadstool"] = {}, -- 毒菌蟾蜍
    ["toadstool_dark"] = {}, -- 悲惨的毒菌蟾蜍
    ["stalker_atrium"] = {}, -- 远古织影者
    ["crabking"] = {}, -- 帝王蟹
    ["alterguardian_phase1"] = {}, -- 天体英雄（第一阶段）
    ["alterguardian_phase2"] = {}, -- 天体英雄（第二阶段）
    ["alterguardian_phase3"] = {}, -- 天体英雄（第三阶段）

    ["mutatedbearger"] = {}, -- 装甲熊獾
    ["mutatedwarg"] = {}, -- 附身座狼
    ["mutateddeerclops"] = {}, -- 晶体独眼巨鹿

    -- 海难
    ["tigershark"] = {}, -- 虎鲨
    ["kraken"] = { -- 海妖
        set_drop_fn = function(inst, drop)
            local function kraken_SpawnChest(inst, x, y, z) -- 海妖专属（生成深渊宝箱）
                inst.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")

                local chest = SpawnPrefab("krakenchest")
                chest.Transform:SetPosition(x, 0, z)

                local fx = SpawnPrefab("statue_transition_2")
                fx.Transform:SetPosition(x, y, z)
                fx.Transform:SetScale(1, 2, 1)

                fx = SpawnPrefab("statue_transition")
                fx.Transform:SetPosition(x, y, z)
                fx.Transform:SetScale(1, 1.5, 1)

                chest:AddComponent("scenariorunner")
                chest.components.scenariorunner:SetScript("chest_kraken")
                chest.components.scenariorunner:Run()
            end

            local x, y, z = inst.Transform:GetWorldPosition() -- 获取海妖位置
            local _x = x
            inst:DoTaskInTime(3, function() -- 等3秒再判断
                if not inst.components.health:IsDead() then -- 确保是真死了
                    return
                end
                while drop > 1 do -- 额外掉落
                    drop = drop - 1
                    inst.components.lootdropper:DropLoot(Vector3(_x, y, z))  --额外掉落N倍
                    x = x + 2
                    kraken_SpawnChest(inst, x, y, z) -- 生成额外深渊宝箱
                end
            end)
        end
    },
    ["twister"] = {}, -- 豹卷风
}

local function set_boss_data(inst, set_health_fn, set_drop_fn)
    local multiple = 0.5 * Get_players_number()
    if Get_players_number() == 1 then multiple = 0 end -- 只有1名玩家时不算

    if set_health_fn then
        local _StartCombat = inst[set_health_fn]
        inst[set_health_fn] = function(...)
            _StartCombat(...)
            if inst.components.health then ---- 检查目标是否拥有血量组件
                inst.components.health.maxhealth = inst.components.health.maxhealth + inst.components.health.maxhealth * multiple  --最大血量 这里需要注意一下 必须是先最大血量再当前血量 不然的话怪物会出现(当前血量/最大血量)(4000/50000)这种情况
                inst.components.health.currenthealth = inst.components.health.currenthealth + inst.components.health.currenthealth * multiple --当前血量
            end
        end
    else
        if inst.components.health then ---- 检查目标是否拥有血量组件
            inst.components.health.maxhealth = inst.components.health.maxhealth + inst.components.health.maxhealth * multiple  --最大血量 这里需要注意一下 必须是先最大血量再当前血量 不然的话怪物会出现(当前血量/最大血量)(4000/50000)这种情况
            inst.components.health.currenthealth = inst.components.health.currenthealth + inst.components.health.currenthealth * multiple --当前血量
        end
    end

    local check_player_num, fight_player_num, last_fight_player_num -- 开启检测，当前BOSS对手数，上次记录的BOSS对手数
    inst:DoPeriodicTask(1,function() -- 每1秒检测一次
        if inst.components and inst.components.health and inst.components.health.currenthealth < 2000 then -- BOSS低于2000血时
            check_player_num = true
        end

        if check_player_num then
            if not (fight_player_num and last_fight_player_num) then -- 第一次初始化 当前BOSS对手数，上次记录的BOSS对手数
                fight_player_num = GetPlayerEnts(inst)
                last_fight_player_num = fight_player_num
            end

            fight_player_num = GetPlayerEnts(inst) -- 更新当前对手数
            if fight_player_num > last_fight_player_num and inst.components and inst.components.health then -- 检测到对手变多
                inst.components.health.currenthealth = inst.components.health.currenthealth + ((fight_player_num - last_fight_player_num) * 2000) -- 每来1个玩家+2000血
                last_fight_player_num = fight_player_num -- 更新记录的对手数
            end
        end
    end)

    local drop = Get_players_number()
	inst:ListenForEvent("death", function() --死亡后触发
        if set_drop_fn then
            set_drop_fn(inst, drop)
        else
            while drop > 1 do -- 额外掉落
                drop = drop - 1
                inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))  --额外掉落N倍
            end
        end
	end)
end

for k,v in pairs(boss) do
	AddPrefabPostInit(k, function(inst)
        set_boss_data(inst, v.set_health_fn, v.set_drop_fn)
    end)
end