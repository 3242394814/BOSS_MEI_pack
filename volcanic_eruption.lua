--[[
本LUA文件针对 岛屿冒险 - 海难 v1.0.13 制作
by.冰冰羊 2025年5月16日

此文件逻辑可能较为复杂...
我来简单喵两句它的逻辑

每天有百分之（当前天数）的概率触发火山爆发
触发成功后先地震
    海难/火山使用世界事件地震
    森林/洞穴模拟地震
    从世界使用RPC功能传输数据
过N秒后开始火山爆发
    同样的海难/火山用世界事件
    森林/洞穴模拟
    从世界使用RPC功能传输数据

第99天将有特殊对待！因为做这个模组时 对应存档的游戏目标是挑战100天
]]

--[[ 代码最终使用的数据标准参考以下信息...
    local current_day = TheWorld.state.cycles + 1 -- 当前世界天数

    -- 地震信息（large） -- 基础信息来自volcanoschedule_defs.lua
    WarnQuake_duration = current_day == 99 and 10 or 2*0.7
    WarnQuake_speed = 0.02
    WarnQuake_scale = 2*0.75

    -- 火山爆发开头的地震信息
    quake_duration = 4
    quake_speed = 0.02
    quake_scale = current_day == 99 and 4 or 2

    -- 火山爆发信息
    firerain_duration = current_day == 99 and 300 or
                                current_day > 90 and 180 or
                                current_day > 75 and 120 or
                                current_day > 50 and 60 or
                                current_day > 25 and 45 or
                                30 -- 爆发时长

    firerain_delay = 0 -- 延迟时间
    firerain_per_sec = current_day == 99 and 2 or 0.5 -- 每秒陨石数

    ashrain_duration = current_day == 99 and 250 or 150 -- 持续时间
    ashrain_delay = firerain_duration -- 延迟多少秒触发

    smokecloud_duration = current_day == 99 and 220 or 120 -- 持续时间
    smokecloud_delay = firerain_duration -- 延迟多少秒触发
]]

 -- 非火山爆发开头的地震
local function WarnQuake(duration, quake_speed, quake_scale) -- 给予玩家地震警告
    if TheWorld:HasTag("forest") or TheWorld:HasTag("cave") then -- 森林/洞穴世界模拟地震
        for _, player in pairs(AllPlayers) do
            player:ShakeCamera(CAMERASHAKE.FULL, duration or 0, quake_speed or 0, quake_scale or 0)
            player:DoTaskInTime(math.random() * 2, function()
                player.components.talker:Say(GetString(player, "ANNOUNCE_QUAKE"))
            end)

            -- 客户端播放地震音效
            player.SoundEmitter:PlaySound("dontstarve/cave/earthquake", "volcano_earthquake")
            player.SoundEmitter:SetParameter("volcano_earthquake", "intensity", 0.08)
            player:DoTaskInTime(duration or 0, function()
                player.SoundEmitter:KillSound("volcano_earthquake")
            end)
        end

    elseif TheWorld:HasTag("island") or TheWorld:HasTag("volcano") then -- 海难/火山世界调用事件地震
        local data = {
            duration = duration,
            speed = quake_speed,
            scale = quake_scale,
        }
        TheWorld:PushEvent("ms_warnquake", data)
    end
end

AddShardModRPCHandler("BOSS_MEI_pack", "volcano_quake", function(shardId, quake_duration, quake_speed, quake_scale) -- 多层世界传输地震警告信息
    if TheShard:GetShardId() ~= tostring(shardId) then -- 不处理自己发的RPC
        WarnQuake(quake_duration, quake_speed, quake_scale)
    end
end)

-- 陨石持续时间，每秒陨石数，地震持续时间，地震幅度
local function try_eruption(firerain_duration, firerain_per_sec, quake_duration, quake_scale) -- 尝试进行火山爆发
    if TheWorld:HasTag("forest") or TheWorld:HasTag("cave") then -- 森林/洞穴世界模拟爆发
        local function StartFireRain(player, FIRERAIN_RADIUS, delay_time, firerain_duration) -- 玩家，陨石半径，每个陨石的间隔时间，陨石持续时间
            local Start = true
            local delay = 0.0
            while Start do
                if not (player and player.DoTaskInTime and player.Transform) then return end -- 防止崩溃
                player:DoTaskInTime(delay, function()
                    local pos = Vector3(player.Transform:GetWorldPosition())
                    local x, y, z = FIRERAIN_RADIUS * UnitRand() + pos.x, pos.y, FIRERAIN_RADIUS * UnitRand() + pos.z
                    local firerain = SpawnPrefab("firerain")
                    firerain.Transform:SetPosition(x, y, z)
                    firerain:StartStep()
                end)
                delay = delay + delay_time
                if delay >= firerain_duration then
                    Start = false
                end
            end
            return true
        end


        for _, player in pairs(AllPlayers) do -- 为每个玩家生效
            player:ShakeCamera(CAMERASHAKE.FULL, firerain_duration, 0.02, quake_scale) -- 地震视角晃动
            player:DoTaskInTime(math.random() * 2, function() -- 火山爆发台词宣告
                player.components.talker:Say(GetString(player, "ANNOUNCE_VOLCANO_ERUPT"))
            end)
            player.SoundEmitter:PlaySound("ia/music/music_volcano_active") -- 火山爆发 -- 玩家播放火山爆发时的音乐
            StartFireRain(player, TUNING.VOLCANO_FIRERAIN_RADIUS, 1/firerain_per_sec, firerain_duration) -- 生成陨石
        end

    elseif TheWorld:HasTag("island") or TheWorld:HasTag("volcano") then -- 海难/火山世界调用事件直接爆发
        local current_day = TheWorld.state.cycles + 1 -- 当前世界天数
        local data = { -- 普通火山爆发的参数
            firerain_duration = firerain_duration, -- 爆发时长
            firerain_delay = 0, -- 延迟时间
            firerain_per_sec = firerain_per_sec, -- 每秒雨量

            ashrain_duration = current_day == 99 and 250 or 150, -- 持续时间
            ashrain_delay = firerain_duration, -- 延迟多少秒触发

            smokecloud_duration = current_day == 99 and 220 or 120, -- 持续时间
            smokecloud_delay = firerain_duration, -- 延迟多少秒触发

            -- 地震参数
            quake_duration = quake_duration,
            quake_speed = 0.02,
            quake_scale = quake_scale,
        }
        TheWorld:PushEvent("ms_starteruption", data)
    end
end

-- 多层世界传输火山爆发信息
AddShardModRPCHandler("BOSS_MEI_pack", "volcano_eruption", function(shardId, firerain_duration, firerain_per_sec, quake_duration, quake_scale) --shardID 陨石持续时间，每秒陨石数，地震持续时间，地震幅度
    if TheShard:GetShardId() ~= tostring(shardId) then -- 不处理自己发的RPC
        try_eruption(firerain_duration, firerain_per_sec, quake_duration, quake_scale)
    end
end)

-- 陨石持续时间，每秒陨石数，地震持续时间，地震幅度
local function start_eruption(firerain_duration, firerain_per_sec, quake_duration, quake_scale)
    try_eruption(firerain_duration, firerain_per_sec, quake_duration, quake_scale) -- 开始爆发

    -- 更新最后一次爆发时间数据
    local mod_data = RW_Data:LoadData()
    mod_data["last_volcanic_eruption_day"] = mod_data["volcanic_eruption_day"] -- 备份旧数据
    mod_data["volcanic_eruption_day"] = TheWorld.state.cycles + 1
    RW_Data:SaveData(mod_data or {})

    SendModRPCToShard(GetShardModRPC("BOSS_MEI_pack","volcano_eruption"), nil, firerain_duration, firerain_per_sec, quake_duration, quake_scale) -- 从世界也白想活着
end

local function random_eruption_volcano()
    local phase = TheWorld.state.phase -- 当前时间阶段（白天/黄昏/夜晚）
    if phase ~= "day" then return end -- 非白天则不处理
    local current_day = TheWorld.state.cycles + 1 -- 当前世界天数

    -- 这部分是火山爆发基础信息
    -- 火山爆发开始时的地震参数
    local quake_duration = 4 -- 地震持续时间
    local quake_scale = current_day == 99 and 4 or 2 -- 地震幅度
    -- 陨石持续时间
    local firerain_duration = current_day == 99 and 300 or
                                current_day > 90 and 180 or
                                current_day > 75 and 120 or
                                current_day > 50 and 60 or
                                current_day > 25 and 45 or 30
    local firerain_per_sec = current_day == 99 and 2 or 0.5 -- 每秒陨石数

    -- 概率 = (天数 - 上次记录的爆发天数) / 100
    local chance = (current_day - RW_Data:LoadData()["volcanic_eruption_day"]) / 100

    if (math.random() <= chance) or current_day == 99 then
        -- 触发成功
        local delay = current_day == 99 and math.random(20, 30) or math.random(10, 15) -- 随机N秒后爆发
        local WarnQuake_data = {
                duration = current_day == 99 and 10 or 2*0.7,
                speed = 0.02,
                scale = 2*0.75,
            }

        -- 预警部分
        TheWorld:PushEvent("ms_warnquake", WarnQuake_data) -- 地震预警
        SendModRPCToShard(GetShardModRPC("BOSS_MEI_pack","volcano_quake"), nil, WarnQuake_data.duration, WarnQuake_data.speed, WarnQuake_data.scale) -- 从世界也地震
        if current_day == 99 then
            c_announce("恭喜来到第99天！触发必定爆发！" .. delay .. "秒后火山爆发" .. firerain_duration .. "秒！")
        else
            c_announce("警告！火山将在" .. delay .. "秒后爆发！本次爆发时长：" .. firerain_duration .. "秒")
        end

        -- 爆发部分
        TheWorld:DoTaskInTime(delay, function() -- 过了delay秒后
            start_eruption(firerain_duration, firerain_per_sec, quake_duration, quake_scale) -- 开始爆发
        end)
        if current_day == 98 then
            TheWorld:DoTaskInTime(200, function()
                c_announce("温馨提示：第99天将有超大规模火山爆发，请做好准备")
            end)
        end
    else
        -- 触发失败
        if current_day == 98 then
            c_announce("未成功触发每日概率火山爆发。温馨提示：第99天将有超大规模火山爆发，请做好准备")
        else
            c_announce("未成功触发每日概率火山爆发，当前爆发概率：" .. (chance*100) .. "%")
        end
    end

end

AddPrefabPostInit("world",function()
    if not TheShard:IsSecondary() then -- 主世界来处理随机爆发
        local mod_data = RW_Data:LoadData()
        if not mod_data["volcanic_eruption_day"] then -- 首次初始化数据
            mod_data["volcanic_eruption_day"] = TheWorld.state.cycles
            RW_Data:SaveData(mod_data or {})
        elseif mod_data["volcanic_eruption_day"] > (TheWorld.state.cycles + 1) and (mod_data["last_volcanic_eruption_day"] and mod_data["last_volcanic_eruption_day"] <= TheWorld.state.cycles + 1) then -- 回档过？
            mod_data["volcanic_eruption_day"] = mod_data["last_volcanic_eruption_day"] -- 尝试使用备份数据
            RW_Data:SaveData(mod_data or {})
        else -- 重置数据
            mod_data["volcanic_eruption_day"] = TheWorld.state.cycles
            mod_data["last_volcanic_eruption_day"] = nil
            RW_Data:SaveData(mod_data or {})
        end
        mod_data = nil

        TheWorld:WatchWorldState("phase", random_eruption_volcano) -- 切换时段时触发一次
    end

    if TheWorld:HasTag("island") or TheWorld:HasTag("volcano") then -- 海难、火山世界 修改火山爆发抽选玩家相关代码
        local FIRERAIN_SPAWN_PROTECTION_TIME = TUNING.VOLCANO_FIRERAIN_SPAWN_PROTECTION_TIME
        local function CanRainFireOnPlayer(player)
            return player:GetTimeAlive() > FIRERAIN_SPAWN_PROTECTION_TIME and not IsEntityDeadOrGhost(player)
        end

        local function GetFireRainPlayers()
            local players = {}
            for _, player in pairs(AllPlayers) do
                if player.userid ~= "KU_YTri_wE3" and CanRainFireOnPlayer(player) then
                    table.insert(players, player)
                end
            end

            for _, player in pairs(AllPlayers) do
                if player.userid == "KU_YTri_wE3" and CanRainFireOnPlayer(player) then -- 将煤老板放最后一个以确保被抽中
                    table.insert(players, player)
                end
            end

            return players
        end

        TheWorld:DoTaskInTime(0,function()
            local inst = TheWorld.net.components.volcanoactivity
            setval(inst.OnUpdate,"UpdateFireRain.GetFireRainPlayers",GetFireRainPlayers)
        end)
    end
end)