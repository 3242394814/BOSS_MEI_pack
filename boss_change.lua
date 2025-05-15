-- 此文件的代码参考了 boss合集(可调整血量,攻击,掉落物,体型,和怪物随时间成长) 模组代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2677451059
-- 感谢菜菜菜

local boss = {
    -- DST
	"deerclops", -- 独眼巨鹿
    "bearger", -- 熊獾
    "moose", -- 麋鹿鹅
    "minotaur", -- 远古守护者
    "spiderqueen", -- 蜘蛛女王
    "warg", -- 
    "dragonfly", -- 龙蝇
    "antlion", -- 蚁狮
    "beequeen", -- 蜂后
    "klaus", -- 克劳斯
    "stalker", -- 复活的骨甲(洞穴)

	"malbatross", -- 邪天翁
    "stalker_forest", -- 复活的骨甲(森林守护者)
    "toadstool", -- 毒菌蟾蜍
    "toadstool_dark", -- 悲惨的毒菌蟾蜍
    "stalker_atrium", -- 远古织影者
    "crabking", -- 帝王蟹
    "alterguardian_phase1", -- 天体英雄（第一阶段）
    "alterguardian_phase2", -- 天体英雄（第二阶段）
    "alterguardian_phase3", -- 天体英雄（第三阶段）

    -- 海难
    "tigershark", -- 虎鲨
    "kraken", -- 海妖
    "twister", -- 豹卷风
}

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

local function Get_players_number()
    local ClientObjs = TheNet:GetClientTable() or {}
    local players_number = #ClientObjs
    if not TheNet:GetServerIsClientHosted() then players_number = players_number - 1 end -- 专用服务器要排除掉【主机】

    return math.min(players_number, 20) -- 最高20倍
end

local function GetPlayerEnts(inst) -- 获取周围有多少活着的玩家
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 10, { "player" }, {"playerghost"})
    return #ents
end

local function set_boss_data(inst, data)
    local multiple = 0.5 * Get_players_number()
    if Get_players_number() == 1 then multiple = 0 end -- 只有1名玩家时不算
	if inst.components.health then ---- 检查目标是否拥有血量组件
		inst.components.health.maxhealth = inst.components.health.maxhealth + inst.components.health.maxhealth * multiple  --最大血量 这里需要注意一下 必须是先最大血量再当前血量 不然的话怪物会出现(当前血量/最大血量)(4000/50000)这种情况
	    inst.components.health.currenthealth = inst.components.health.currenthealth + inst.components.health.currenthealth * multiple --当前血量
	end

    local check_player_num, fight_player_num, last_fight_player_num -- 开启检测，当前BOSS对手数，上次记录的BOSS对手数
    inst:DoPeriodicTask(1,function() -- 每1秒检测一次
        if inst.components.health.currenthealth < 2000 then -- BOSS低于2000血时
            check_player_num = true
        end

        if check_player_num then
            if not (fight_player_num and last_fight_player_num) then -- 第一次初始化 当前BOSS对手数，上次记录的BOSS对手数
                fight_player_num = GetPlayerEnts(inst)
                last_fight_player_num = fight_player_num
            end

            fight_player_num = GetPlayerEnts(inst) -- 更新当前对手数
            if fight_player_num > last_fight_player_num then -- 检测到对手变多
                inst.components.health.currenthealth = inst.components.health.currenthealth + ((fight_player_num - last_fight_player_num) * 2000) -- 每来1个玩家+2000血
                last_fight_player_num = fight_player_num -- 更新记录的对手数
            end
        end
    end)

    local drop = Get_players_number()
	inst:ListenForEvent("death", function() --死亡后触发
        if inst.prefab == "kraken" then -- 海妖专属
            local x, y, z = inst.Transform:GetWorldPosition() -- 获取海妖位置
            inst:DoTaskInTime(3, function() -- 等3秒再判断
                if not inst.components.health:IsDead() then -- 确保是真死了
                    return
                end
                while drop > 1 do -- 额外掉落
                    drop = drop - 1
                    inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))  --额外掉落N倍
                    x = x + 1
                    kraken_SpawnChest(inst, x, y, z) -- 生成额外深渊宝箱
                end
            end)
        else
            while drop > 1 do -- 额外掉落
                drop = drop - 1
                inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))  --额外掉落N倍
            end
        end
	end)
end

for k,v in pairs(boss) do
	AddPrefabPostInit(v, set_boss_data)
end