
----------------------------------------------------------------
--主线跑团世界BOSS红点检测
local XRedPointTRPGWorldBossReward = {}
local Events = nil

function XRedPointTRPGWorldBossReward.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TRPG_BOSS_HP_SYN)
    }
    return Events
end

function XRedPointTRPGWorldBossReward.Check()
    return XDataCenter.TRPGManager.CheckWorldBossReward()
end

return XRedPointTRPGWorldBossReward