local XRedPointConditionFashionStoryHaveStage = {}

function XRedPointConditionFashionStoryHaveStage.Check(activityId)
    local curActivity = activityId
    if not curActivity then
       local activeChapter = XDataCenter.FashionStoryManager.GetActivityChapters()
        if not XTool.IsTableEmpty(activeChapter) then
            -- 参数activityId为空时(主界面快捷入口的红点检测不会传入检测的activityId)，默认取第一个活动的Id来检测
            -- 如果有多个活动同时开启，这里需要处理
            curActivity = activeChapter[1].Id
        else
            return false
        end
    end
    
    if XDataCenter.FashionStoryManager.IsActivityInTime(curActivity) then
        -- 章节关是否未全部通关
        local passNum, totalNum = XDataCenter.FashionStoryManager.GetChapterProgress(curActivity)
        if passNum < totalNum then
            return true
        end

        -- 试玩关是否有未通关关卡
        local trialList = XFashionStoryConfigs.GetTrialStagesList(curActivity)
        if not XTool.IsTableEmpty(trialList) then
            for _, trialId in ipairs(trialList) do
                if XDataCenter.FashionStoryManager.IsTrialStageInTime(trialId) then
                    local isPassed = XDataCenter.FubenManager.CheckStageIsPass(trialId)
                    if not isPassed then
                        return true
                    end
                end
            end
        end
    end
    return false
end

return XRedPointConditionFashionStoryHaveStage