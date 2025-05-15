GLOBAL.setmetatable(env, {
    __index = function(t, k)
        return GLOBAL.rawget(GLOBAL, k)
    end
})

function getval(fn, path)
	if fn == nil or type(fn)~="function" then return end
	local val = fn
	local i
	for entry in path:gmatch("[^%.]+") do
		i = 1
		while true do
			local name, value = debug.getupvalue(val, i)
			if name == entry then
				val = value
				break
			elseif name == nil then
				return
			end
			i = i + 1
		end
	end
	return val, i
end

function setval(fn, path, new)
	if fn == nil or type(fn)~="function" then return end
	local val = fn
	local prev = nil
	local i
	for entry in path:gmatch("[^%.]+") do
		i = 1
		prev = val
		while true do
			local name, value = debug.getupvalue(val, i)
			if name == entry then
				val = value
				break
			elseif name == nil then
				return
			end
			i = i + 1
		end
	end
	debug.setupvalue(prev, i, new)
end

-- 读写模组Data文件
RW_Data = {}
local DATA_FILE = 'BOSS_MEI_Adventure_data'

function RW_Data:SaveData(data)
	local str = json.encode(data)
	local insz, outsz = SavePersistentString(DATA_FILE, str)
end

function RW_Data:LoadData()
	local data
	TheSim:GetPersistentString(DATA_FILE, function(load_success, str)
		if load_success then
			if string.len(str) > 0 and not string.find(str,"return") then
				data = json.decode(str) or {}
			else
				data = {}
			end
		end
	end)
	return data or {}
end

if GetModConfigData("volcanic_eruption") then
	modimport("volcanic_eruption_RPC") -- 火山爆发 服务器与客户端通信的RPC
end

if TheNet:GetIsServer() then
	AddPrefabPostInit("world",function()
		if GetModConfigData("disable_save_command") then -- 禁用保存指令
			GLOBAL.c_save = function()
				c_announce("提示：存档指令已被禁用！")
			end
		end

		if GetModConfigData("random_season") then -- 随机季节
			TheWorld:DoTaskInTime(0,function()
				modimport("random_season")
			end)
		end

		if GetModConfigData("random_day") then -- 随机昼夜长度
			TheWorld:DoTaskInTime(0,function()
				modimport("random_day")
			end)
		end

	end)

	if GetModConfigData("volcanic_eruption") then -- 每天概率火山爆发（概率=当前世界天数，爆发后清零）
		modimport("volcanic_eruption")
	end

	if GetModConfigData("boss_change") then -- BOSS血量&掉落物 随人数翻倍
		modimport("boss_change")
	end
end
