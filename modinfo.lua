---@diagnostic disable: lowercase-global
name = "梅老板的奇妙之旅"
author = "冰冰羊"
description = [[

]]
version = "0.1"
dst_compatible = true
forge_compatible = false
gorge_compatible = false
dont_starve_compatible = false
client_only_mod = false
server_only_mod = false
all_clients_require_mod = true
--icon_atlas = "modicon.xml"
--icon = "modicon.tex"
forumthread = ""
api_version_dst = 10
-- priority = 0
mod_dependencies = {}
server_filter_tags = {"梅老板的奇妙之旅"}

configuration_options =
{
    {
		name = "disable_save_command",
		label = "禁用保存指令",
		hover = "",
		options =	{
						{description = "是", data = true, hover = ""},
						{description = "否", data = false, hover = ""},
					},
		default = false,
	},
    {
		name = "random_season",
		label = "随机季节",
		hover = "",
		options =	{
						{description = "是", data = true, hover = ""},
						{description = "否", data = false, hover = ""},
					},
		default = false,
	},
	{
		name = "random_day",
		label = "随机昼夜长度",
		hover = "",
		options =	{
						{description = "是", data = true, hover = ""},
						{description = "否", data = false, hover = ""},
					},
		default = false,
	},
	{
		name = "boss_change",
		label = "BOSS血量&掉落倍率 随人数翻倍",
		hover = "",
		options =	{
						{description = "是", data = true, hover = ""},
						{description = "否", data = false, hover = ""},
					},
		default = false,
	},
	{
		name = "volcanic_eruption",
		label = "火山爆发",
		hover = "每天都有（当前世界天数）的概率火山爆发\n爆发过后概率重新计算",
		options =	{
						{description = "是", data = true, hover = ""},
						{description = "否", data = false, hover = ""},
					},
		default = false,
	},
}