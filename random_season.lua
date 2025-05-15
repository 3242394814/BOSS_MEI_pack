local world_type = TheWorld:HasTag("porkland") and "猪镇"
or TheWorld:HasTag("island") and "海难"
or TheWorld:HasTag("volcano") and "火山"
or TheWorld:HasTag("cave") and "洞穴"
or "森林"  -- 默认

local function generate_DST_season_data() -- 创建新的DST随机季节数据
    local mod_data = RW_Data:LoadData()

    local winter_num = math.random(15, 30) -- 冬季
    local spring_num = math.random(5, 20) -- 春季
    local summer_num = math.random(10, 25) -- 夏季
    local autumn_num = math.random(3, math.min(10, math.min(winter_num, spring_num, summer_num))) -- 秋季(不超过10天)

    -- 设置数据
    mod_data["autumn_num"] = autumn_num
    mod_data["winter_num"] = winter_num
    mod_data["spring_num"] = spring_num
    mod_data["summer_num"] = summer_num

    RW_Data:SaveData(mod_data or {}) -- 存储数据

    return autumn_num, winter_num, spring_num, summer_num
end

local function generate_SW_season_data() -- 创建新的海难随机季节数据
    local mod_data = RW_Data:LoadData()

    local wet_num = math.random(15, 30) -- 飓风季
    local green_num = math.random(5, 20) -- 雨季
    local dry_num = math.random(10, 25) -- 旱季
    local mild_num = math.random(3, math.min(10, math.min(wet_num, green_num, dry_num))) -- 温和季(不超过10天)

    -- 设置数据
    mod_data["mild_num"] = mild_num
    mod_data["wet_num"] = wet_num
    mod_data["green_num"] = green_num
    mod_data["dry_num"] = dry_num

    RW_Data:SaveData(mod_data or {}) -- 存储数据

    return mild_num, wet_num, green_num, dry_num
end

local function Apply_SW_season(season, length)
    TheWorld:PushEvent("ms_setseasonlength_tropical", {season = season, length = length}) -- 海难
end

local function Apply_DST_season(season, length)
    TheWorld:PushEvent("ms_setseasonlength", {season = season, length = length}) -- 森林
end

local function Apply_HAM_season(season, length)
    TheWorld:PushEvent("ms_setseasonlength_plateau", {season = season, length = length}) -- 猪镇
end

-- 自动设置季节
if not TheShard:IsSecondary() then -- 仅主世界生效
    local mod_data = RW_Data:LoadData()

    -- 海难季节
    local mild_num, wet_num, green_num, dry_num = mod_data["mild_num"], mod_data["wet_num"], mod_data["green_num"], mod_data["dry_num"]
    if not (mild_num and wet_num and green_num and dry_num) then
        mild_num, wet_num, green_num, dry_num = generate_SW_season_data()
    end

    Apply_SW_season("mild", mild_num)
    Apply_SW_season("wet", wet_num)
    Apply_SW_season("green", green_num)
    Apply_SW_season("dry", dry_num)

    -- DST季节
    local autumn_num, winter_num, spring_num, summer_num = mod_data["autumn_num"], mod_data["winter_num"], mod_data["spring_num"], mod_data["summer_num"]
    if not (autumn_num and winter_num and spring_num and summer_num) then
        autumn_num, winter_num, spring_num, summer_num = generate_DST_season_data()
    end

    Apply_DST_season("autumn", autumn_num)
    Apply_DST_season("winter", winter_num)
    Apply_DST_season("spring", spring_num)
    Apply_DST_season("summer", summer_num)


    GLOBAL.c_reset_random_season = function() -- 手动重置随机季节数据(从世界会自动同步)
        local mild_num, wet_num, green_num, dry_num = generate_SW_season_data()
        Apply_SW_season("mild", mild_num)
        Apply_SW_season("wet", wet_num)
        Apply_SW_season("green", green_num)
        Apply_SW_season("dry", dry_num)

        local autumn_num, winter_num, spring_num, summer_num = generate_DST_season_data()
        Apply_DST_season("autumn", autumn_num)
        Apply_DST_season("winter", winter_num)
        Apply_DST_season("spring", spring_num)
        Apply_DST_season("summer", summer_num)

        c_announce("已重置各季节天数！")
    end
end