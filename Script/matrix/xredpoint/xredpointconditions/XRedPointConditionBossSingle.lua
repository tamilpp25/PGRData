----------------------------------------------------------------
--超难关：有可挑战的关卡

local XRedPointConditionBossSingle = {}
local Events = nil
function XRedPointConditionBossSingle.GetSubEvents()
    Events = Events or
    {
    }
    return Events
end

--有关卡还没打， 而且开放了
function XRedPointConditionBossSingle.Check()
    local isOpen = XActivityBrieIsOpen.Get(XActivityBriefConfigs.ActivityGroupId.BossSingle)
    if isOpen then
        local sectionId = XDataCenter.FubenActivityBossSingleManager.GetCurSectionId()
        local stageIds = XDataCenter.FubenActivityBossSingleManager.GetSectionStageIdList(sectionId)
        for i,stageId in ipairs(stageIds) do
            local isUnLock = XDataCenter.FubenActivityBossSingleManager.IsChallengeUnlockByStageId(stageId)
            if isUnLock then
                local isPassed = XDataCenter.FubenActivityBossSingleManager.IsChallengePassedByStageId(stageId)
                if not isPassed then
                    return true
                end
            end
        end

        return false
    else
        return false
    end
end

return XRedPointConditionBossSingle