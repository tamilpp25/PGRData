local XRedPointConditionMusicGameEntranceArrangement = {}

function XRedPointConditionMusicGameEntranceArrangement.Check()
    local musicGameControlConfig = XMVCA.XMusicGameActivity:GetCurActivityConfig()
    if not musicGameControlConfig then
        return false
    end
    
    -- 检查门票
    local itemId = XDataCenter.ItemManager.ItemId.MusicGameArrangementItem
    local itemCount = XDataCenter.ItemManager.GetCount(itemId)
    if itemCount < musicGameControlConfig.ArrangementUseItemCount then
        return false
    end

    local arrangementControlConfig = XMVCA.XArrangementGame:GetModelArrangementGameControl()[musicGameControlConfig.ArrangementGameControlId]
    if XTool.IsNumberValid(arrangementControlConfig.Condition) then
        local res, desc = XConditionManager.CheckCondition(arrangementControlConfig.Condition)
        if not res then
            return false
        end
    end

    -- 所有编曲结果已完成
    local passList = XMVCA.XMusicGameActivity:GetPassArrangementMusicIds()
    if #passList >= #arrangementControlConfig.MusicIds then
        return false
    end

    return true
end

return XRedPointConditionMusicGameEntranceArrangement