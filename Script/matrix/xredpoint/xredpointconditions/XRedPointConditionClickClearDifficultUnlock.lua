----------------------------------------------------------------
--点消小游戏普通关卡解锁检测
local XRedPointConditionClickClearDifficultUnlock = {}
local Events = nil
function XRedPointConditionClickClearDifficultUnlock.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CLICKCLEARGAME_FINISHED_GAME),
    }
    return Events
end

function XRedPointConditionClickClearDifficultUnlock.Check(difficulty)
    return XDataCenter.XClickClearGameManager.CheckDifficultyRedPoint(difficulty)
end

return XRedPointConditionClickClearDifficultUnlock