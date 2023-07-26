local XExFubenCollegeStudyManager = require("XEntity/XFuben/XExFubenCollegeStudyManager")

XPartnerTeachingManagerCreator = function()
    local XPartnerTeachingManager = XExFubenCollegeStudyManager.New(XFubenConfigs.ChapterType.PartnerTeaching)

    -------------------------------------------------------副本相关------------------------------------------------------
    function XPartnerTeachingManager.InitStageInfo()
        local allChapterId = XPartnerTeachingConfigs.GetAllChapterId()
        for _, chapterId in pairs(allChapterId) do
            local stageIdList = XPartnerTeachingConfigs.GetChapterStageIds(chapterId)
            for i, stageId in ipairs(stageIdList) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                stageInfo.Type = XDataCenter.FubenManager.StageType.PartnerTeaching
                stageInfo.OrderId = i
            end
        end
    end
    --------------------------------------------------------------------------------------------------------------------

    ---
    --- 'chapterId'章节是否处于活动时间
    ---@return boolean
    function XPartnerTeachingManager.WhetherInActivity(chapterId)
        local activeTimeId = XPartnerTeachingConfigs.GetChapterActivityTimeId(chapterId)
        return XFunctionManager.CheckInTimeByTimeId(activeTimeId)
    end

    ---
    --- 获取活动的剩余时间戳
    function XPartnerTeachingManager.GetLeftTimeStamp(chapterId)
        local activeTimeId = XPartnerTeachingConfigs.GetChapterActivityTimeId(chapterId)
        local endTime = XFunctionManager.GetEndTimeByTimeId(activeTimeId)
        return endTime > 0 and endTime - XTime.GetServerNowTimestamp() or 0
   end

    ---
    --- 'chapterId'章节是否解锁，如果未解锁，额外返回未满足条件的描述
    ---@return boolean|string 是否解锁|未满足条件的描述
    function XPartnerTeachingManager.WhetherUnLockChapter(chapterId)
        local isInActive = XPartnerTeachingManager.WhetherInActivity(chapterId)

        local conditionList
        if isInActive then
            conditionList = XPartnerTeachingConfigs.GetChapterActivityCondition(chapterId)
        else
            conditionList = XPartnerTeachingConfigs.GetChapterOpenCondition(chapterId)
        end

        local lockTip
        local isUnlock = true
        if conditionList or next(conditionList) then
            for _, conditionId in ipairs(conditionList) do
                local result, desc = XConditionManager.CheckCondition(conditionId)
                if not result then
                    lockTip = desc
                    isUnlock = false
                    break
                end
            end
        end
        return isUnlock, lockTip
    end

    ---
    --- 得到排序后的教学章节Id数组
    function XPartnerTeachingManager.GetSortedChapterList()
        local allChapterIdList = XPartnerTeachingConfigs.GetAllChapterId()

        table.sort(allChapterIdList, function(a, b)
            -- 解锁 > 锁定
            local aIsUnlock = XPartnerTeachingManager.WhetherUnLockChapter(a)
            local bIsUnlock = XPartnerTeachingManager.WhetherUnLockChapter(b)
            if aIsUnlock ~= bIsUnlock then
                return aIsUnlock
            end

            -- 活动状态 > 普通状态
            local aIsInActive = XPartnerTeachingManager.WhetherInActivity(a)
            local bIsInActive = XPartnerTeachingManager.WhetherInActivity(b)
            if aIsInActive ~= bIsInActive then
                return aIsInActive
            end

            -- 未通关 > 通关
            local aIsPass = XPartnerTeachingManager.WhetherPassChapter(a)
            local bIsPass = XPartnerTeachingManager.WhetherPassChapter(b)
            if aIsPass ~= bIsPass then
                return bIsPass
            end
            return a < b
        end)

        return allChapterIdList
    end

    ---
    --- 得到 'chapterId' 的关卡进度
    ---@return number 通关关卡数|总关卡数
    function XPartnerTeachingManager.GetChapterProgress(chapterId)
        local stageIdList = XPartnerTeachingConfigs.GetChapterStageIds(chapterId)
        local passNum = 0
        local totalNum = #stageIdList

        for _, stageId in ipairs(stageIdList) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo.Passed then
                passNum = passNum + 1
            end
        end

        return passNum, totalNum
    end

    ---
    --- 是否通关了 'chapterId' 章节
    ---@return boolean
    function XPartnerTeachingManager.WhetherPassChapter(chapterId)
        local passStageNum, totalStageNum = XPartnerTeachingManager.GetChapterProgress(chapterId)
        return passStageNum == totalStageNum
    end

    ---
    --- 获取 'chapterId' 中 ‘stageId' 的编号名称
    function XPartnerTeachingManager.GetOrderName(chapterId, stageId)
        local stagePrefix = XPartnerTeachingConfigs.GetChapterStagePrefix(chapterId)
        local orderId = XDataCenter.FubenManager.GetStageOrderId(stageId)
        return string.format("%s%d", stagePrefix, orderId)
    end

    ------------------副本入口扩展 start-------------------------
    function XPartnerTeachingManager:ExGetTagInfo()
        for k, id in pairs(XPartnerTeachingConfigs.GetAllChapterId()) do
            if XPartnerTeachingManager.WhetherInActivity(id) then
                return true, CS.XTextManager.GetText("PartnerTeachingTag")
            end
        end

        return false
    end

    function XPartnerTeachingManager:ExGetIcon()
        for k, id in pairs(XPartnerTeachingConfigs.GetAllChapterId()) do
            if XPartnerTeachingManager.WhetherInActivity(id) then
                return XPartnerTeachingConfigs.GetActivityChapterIconById(id)
            end
        end

        return self:ExGetConfig().Icon
    end

    function XPartnerTeachingManager:ExOpenMainUi()
        if XFunctionManager.DetectionFunction(self:ExGetFunctionNameType()) then
            XLuaUiManager.Open("UiPartnerTeachingBanner")
        end
    end
    
    ------------------副本入口扩展 end-------------------------

    return XPartnerTeachingManager
end