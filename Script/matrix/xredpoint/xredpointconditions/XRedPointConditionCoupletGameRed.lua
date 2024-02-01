----------------------------------------------------------------
--春节对联小游戏入口
local XRedPointConditionCoupletGameRed = {}
local SubCondition = nil
local Events = nil
function XRedPointConditionCoupletGameRed.GetSubConditions()
    SubCondition =  SubCondition or
    {
        XRedPointConditions.Types.CONDITION_COUPLET_GAME_REWARD_TASK,
        XRedPointConditions.Types.CONDITION_COUPLET_GAME_PLAY_VIDEO,
    }
    return SubCondition
end

function XRedPointConditionCoupletGameRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX),
    }
    return Events
end

function XRedPointConditionCoupletGameRed.Check()
    if XDataCenter.CoupletGameManager.CheckCanExchangeWord() then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_COUPLET_GAME_REWARD_TASK) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_COUPLET_GAME_PLAY_VIDEO) then
        return true
    end

    return false
end

return XRedPointConditionCoupletGameRed