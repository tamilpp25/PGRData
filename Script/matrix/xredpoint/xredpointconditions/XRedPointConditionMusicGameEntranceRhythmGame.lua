local XRedPointConditionMusicGameEntranceRhythmGame = {}

function XRedPointConditionMusicGameEntranceRhythmGame.Check()
    local musicGameControlConfig = XMVCA.XMusicGameActivity:GetCurActivityConfig()
    if not musicGameControlConfig then
        return false
    end

    local rhythmGameControlConfig = XMVCA.XRhythmGame:GetModeltRhythmGameControl()[musicGameControlConfig.RhythmGameControlId]
    -- 总入口condition
    if XTool.IsNumberValid(rhythmGameControlConfig.Condition) then
        local res, desc = XConditionManager.CheckCondition(rhythmGameControlConfig.Condition)
        if not res then
            return false
        end
    end
    
    -- 活动时间
    if rhythmGameControlConfig.TimeId then
        if not XFunctionManager.CheckInTimeByTimeId(rhythmGameControlConfig.TimeId) then
            return false
        end
    end

    -- 可游玩关卡通关检测
    local allEnableMapIds = XMVCA.XMusicGameActivity:GetEnableMapIds()
    if #allEnableMapIds == 0 then
        return false
    end

    local isEnableMapsAllPass = true
    for _, mapId in ipairs(allEnableMapIds) do
        if not XMVCA.XRhythmGame:CheckHasRecordEnterMapCache(mapId) then
            isEnableMapsAllPass = false
            break
        end
    end
    -- 可游玩关卡全部点击过的话
    if isEnableMapsAllPass then
        return false
    end

    return true
end

return XRedPointConditionMusicGameEntranceRhythmGame