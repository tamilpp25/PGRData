local XRedpointConditionHitMouse = {}

function XRedpointConditionHitMouse.Check()
    local stages = XDataCenter.HitMouseManager.GetStageCfgs()
    for _, stageCfg in pairs(stages or {}) do
        local stageId = stageCfg.Id
        local isUnlock = XDataCenter.HitMouseManager.CheckStageUnlock(stageId)
        if not isUnlock then
            local isPreUnlock = XDataCenter.HitMouseManager.CheckPreStageUnlock(stageId)
            if isPreUnlock then
                local isPreClear = XDataCenter.HitMouseManager.CheckPreStageClear(stageId)
                if isPreClear then
                    local itemId = XDataCenter.HitMouseManager.GetUnlockItemId()
                    local cfg = XHitMouseConfigs.GetCfgByIdKey(XHitMouseConfigs.TableKey.Stage, stageId)
                    if XDataCenter.ItemManager.CheckItemCountById(itemId, cfg.UnlockItemCount) then
                        return true
                    end
                end
            end
        end
    end

    local scores = XDataCenter.HitMouseManager.GetRewardScores()
    for index, v in pairs(scores) do
        local canGet = XDataCenter.HitMouseManager.CheckRewardCanGet(index)
        if canGet then
            return true
        end
    end
    return false
end

return XRedpointConditionHitMouse