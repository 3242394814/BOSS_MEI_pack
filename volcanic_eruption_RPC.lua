AddClientModRPCHandler("BOSS_MEI_pack", "play_volcano_quake",function(duration) -- 播放地震音效(音效持续时间)
    TheWorld.SoundEmitter:PlaySound("dontstarve/cave/earthquake", "volcano_earthquake")
    TheWorld.SoundEmitter:SetParameter("volcano_earthquake", "intensity", 0.08)
    TheWorld:DoTaskInTime(duration or 0, function()
        TheWorld.SoundEmitter:KillSound("volcano_earthquake")
    end)
end)

AddClientModRPCHandler("BOSS_MEI_pack", "play_volcano_eruption",function() -- 播放火山开始爆发时的音效
    TheWorld.SoundEmitter:PlaySound("ia/music/music_volcano_active") -- 火山爆发
    -- TheWorld.SoundEmitter:PlaySound("ia/music/music_volcano_dormant") -- 火山休眠
end)

-- AddClientModRPCHandler("BOSS_MEI_pack", "play_volcano_dormant",function() -- 播放火山休眠音效（用不着）
--     TheWorld.SoundEmitter:PlaySound("ia/music/music_volcano_dormant") -- 火山休眠
-- end)