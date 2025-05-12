local XRedPointConditionMusicGameEntrance = {}
local SubConditions = nil
function XRedPointConditionMusicGameEntrance.GetSubConditions()
    SubConditions = SubConditions or
    {
        XRedPointConditions.Types.CONDITION_MUSICGAME_TASK,
        XRedPointConditions.Types.CONDITION_MUSICGAME_ENTRANCE_RHYTHMGAME,
        XRedPointConditions.Types.CONDITION_MUSICGAME_ENTRANCE_ARRANGEMENT,
    }
    return SubConditions
end

function XRedPointConditionMusicGameEntrance.Check()
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_MUSICGAME_TASK) then
        return true
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_MUSICGAME_ENTRANCE_ARRANGEMENT) then
        return true
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_MUSICGAME_ENTRANCE_RHYTHMGAME) then
        return true
    end
    
    -- 是否进入过检测
    local checkData = XSaveTool.GetData(XMVCA.XMusicGameActivity:GetHasEnterKey())
    if not checkData then
        return true
    end

    local curActivityConfig = XMVCA.XMusicGameActivity:GetCurActivityConfig()
    if not XTool.IsTableEmpty(curActivityConfig) then
        local musicIds = XMVCA.XArrangementGame:GetModelArrangementGameControl()[curActivityConfig.ArrangementGameControlId]
        for k, id in pairs(musicIds) do
            if XMVCA.XMusicGameActivity:CheckCanShowGridRed(id) then
                return true
            end
        end
    end
    
    return false
end

return XRedPointConditionMusicGameEntrance