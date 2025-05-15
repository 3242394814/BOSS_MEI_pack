local function random_day() -- 创建新的随机季节数据
    local mod_data = RW_Data:LoadData()

    local total = 3 -- 一天有3种阶段

    -- 生成两个随机切点
    local x1 = math.random() * total
    local x2 = math.random() * total

    -- 排序切点
    if x1 > x2 then
        x1, x2 = x2, x1
    end

    -- 得到三段
    local a = x1
    local b = x2 - x1
    local c = total - x2

    if b <= a and b <= c then
        a, b = b, a
    elseif c <= a and c <= b then
        a, c = c, a
    end

    -- 随机打乱 b 和 c 的顺序
    if math.random() < 0.5 then
        b, c = c, b
    end

    -- 赋值
    local day = a -- 白天时间最短！
    local dusk = b
    local night = c

    -- 设置数据
    mod_data["day"] = day
    mod_data["dusk"] = dusk
    mod_data["night"] = night

    RW_Data:SaveData(mod_data or {}) -- 存储数据

    return day, dusk, night
end

local function Apply_day(data)
    TheWorld:PushEvent("ms_setseasonsegmodifier", data)
end

if not TheShard:IsSecondary() then -- 仅主世界执行
    local mod_data = RW_Data:LoadData()
    local day, dusk, night = mod_data["day"], mod_data["dusk"], mod_data["night"] -- 尝试读取存储的数据

    if not (day and dusk and night) then
        day, dusk, night = random_day() -- 如果没数据就新生成一个
    end

    local data = {
        day = day,
        dusk = dusk,
        night = night
    }
    Apply_day(data) -- 应用随机生成的各阶段长度


    -- 每日自动重置各阶段数据
    local function updatephase()
        local phase = TheWorld.state.phase
        if phase ~= "day" then return end -- 如果白天了

        local day, dusk, night = random_day() -- 重置当天各阶段数据
        local data = {
            day = day,
            dusk = dusk,
            night = night
        }
        Apply_day(data)
    end
    TheWorld:WatchWorldState("phase", updatephase)
end
