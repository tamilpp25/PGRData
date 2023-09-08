local XExPrequelManager = require("XEntity/XFuben/XExPrequelManager")
local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
local XChapterViewModel = require("XEntity/XFuben/XChapterViewModel")

XPrequelManagerCreator = function()
    local XPrequelManager = XExPrequelManager.New(XFubenConfigs.ChapterType.Prequel)
    local XPrequelFragmentManager = XExFubenBaseManager.New(XFubenConfigs.ChapterType.CharacterFragment)  -- 管理角色碎片章节

    local UnlockChallengeStages = {}
    local RewardedStages = {}
    local NextCheckPoint = nil
    -- manager层
    local Cover2ChapterMap = {}--记录上一个封面
    local CoverPrefix = "CoverPrefix"
    local Stage2ChapterMap = {}
    local CoverIdDataDic = {}

    function XPrequelManager.InitPrequelData(fubenPrequelData)
        if not fubenPrequelData then return end
        for _, v in pairs(fubenPrequelData.RewardedStages or {}) do
            RewardedStages[v] = true
        end
        for _, v in pairs(fubenPrequelData.UnlockChallengeStages or {}) do
            UnlockChallengeStages[v.StageId] = v
        end
    end

    function XPrequelManager.SaveCoverChapterHint(key, value)
        if XPlayer.Id then
            key = string.format("%s_%s", tostring(XPlayer.Id), key)
            XSaveTool.SaveData(key, value)
        end
    end

    function XPrequelManager.GetCoverChapterHint(key, defaultValue)
        if XPlayer.Id then
            key = string.format("%s_%s", tostring(XPlayer.Id), key)
            if XSaveTool.GetData(key) then
                local newPlayerHint =  XSaveTool.GetData(key)
                return (newPlayerHint == nil or newPlayerHint == 0) and defaultValue or newPlayerHint
            end
        end
        return defaultValue
    end

    function XPrequelManager.InitStageInfo()
        for chapterId, chapterCfg in pairs(XPrequelConfigs.GetPequelAllChapter() or {}) do
            for _, stageId in pairs(chapterCfg.StageId or {}) do
                Stage2ChapterMap[stageId] = chapterId
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.Prequel
                end
            end
        end

        for _, coverCfg in pairs(XPrequelConfigs.GetPrequelCoverList() or {}) do
            for _, stageId in pairs(coverCfg.ChallengeStage or {}) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.Prequel
                end
            end
        end
    end

    -- 弃用接口， 1.30更新副本入口后不再需要记录间章上一次打过的chapter
    -- [更新封面显示的chapter]
    function XPrequelManager.UpdateShowChapter(stageId)
        -- if not stageId then return end
        -- local chapterId = XPrequelConfigs.GetChapterByStageId(stageId)
        -- if not chapterId then return end
        -- local coverId = XPrequelConfigs.GetCoverByChapterId(chapterId)
        -- if not coverId then return end
        -- local key = string.format("%s%s", CoverPrefix, tostring(coverId))
        -- XPrequelManager.SaveCoverChapterHint(key, chapterId)
        -- Cover2ChapterMap[coverId] = chapterId
    end

    function XPrequelManager.ShowReward(winData)
        XLuaUiManager.Open("UiSettleWin", winData)
    end

    -- [获取已经解锁的挑战关卡，nil代表未解锁]
    function XPrequelManager.GetUnlockChallengeStagesByStageId(stageId)
        return UnlockChallengeStages[stageId]
    end

    -- [解锁挑战]
    function XPrequelManager.UnlockPrequelChallengeRequest(coverId, challengeIdx, stageId, cb)
        XNetwork.Call("UnlockPrequelChallengeRequest", { CoverId = coverId, ChallengeId = challengeIdx }, function(res)
            cb = cb or function() end
            if res.Code == XCode.Success then
                UnlockChallengeStages[stageId] = res.ChallengeStage
                cb(res)
            else
                XUiManager.TipCode(res.Code)
            end
        end)
    end
    -- [前传奖励领取]
    function XPrequelManager.ReceivePrequelRewardRequest(stageId, cb)
        XNetwork.Call("ReceivePrequelRewardRequest", { StageId = stageId }, function(res)
            cb = cb or function() end
            if res.Code == XCode.Success then
                RewardedStages[res.StageId] = true
                -- 显示奖励
                XUiManager.OpenUiObtain(res.RewardGoodsList, CS.XTextManager.GetText("DailyActiveRewardTitle"))
                cb(res)
            else
                XUiManager.TipCode(res.Code)
            end
        end)
    end

    -- [剧情]
    function XPrequelManager.FinishStoryRequest(stageId, cb)
        XNetwork.Call("EnterStoryRequest", { StageId = stageId }, function(res)
            cb = cb or function() end
            if res.Code == XCode.Success then
                cb(res)
            else
                XUiManager.TipCode(res.Code)
            end
        end)
    end

    function XPrequelManager.GetRewardedStages()
        return RewardedStages
    end

    function XPrequelManager.IsRewardStageCollected(stageId)
        return RewardedStages[stageId]
    end

    function XPrequelManager.IsStoryStage(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if not stageCfg then return false end
        return stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG
    end

    -- [服务器同步领取奖励的剧情关卡数据]
    function XPrequelManager.OnSyncRewardedStage(response)
        for _, v in pairs(response.RewardedStages or {}) do
            RewardedStages[v] = true
        end
    end

    -- [服务器同步解锁的挑战关卡数据]
    function XPrequelManager.OnSyncUnlockChallengeStage(response)
        UnlockChallengeStages = response.UnlockChallengeStages
        XEventManager.DispatchEvent(XEventId.EVENT_NOTICE_CHALLENGESTAGES_CHANGE)
    end

    function XPrequelManager.OnSyncSingleUnlockChallengeStage(response)
        local currentStage = response.ChallengeStage
        UnlockChallengeStages[currentStage.StageId] = currentStage
        XEventManager.DispatchEvent(XEventId.EVENT_NOTICE_CHALLENGESTAGES_CHANGE)
    end

    -- [刷新时间-需要通知界面及时更新]
    function XPrequelManager.OnSyncNextRefreshTime(response)
        NextCheckPoint = response.NextRefreshTime
        XEventManager.DispatchEvent(XEventId.EVENT_NOTICE_REFRESHTIME_CHANGE)
    end

    -- [判断解锁条件]
    function XPrequelManager.CheckPrequelStageOpen(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local isUnlock = stageInfo.Unlock
        if stageInfo.Unlock then
            for _, conditionId in pairs(stageCfg.ForceConditionId or {}) do
                local rect, _ = XConditionManager.CheckCondition(conditionId)
                if not rect then
                    return rect
                end
            end
        end
        if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG or stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG then
            return isUnlock and XDataCenter.FubenManager.GetUnlockHideStageById(stageId)
        end
        return isUnlock
    end

    function XPrequelManager.GetCoverUnlockDescription(coverId)
        local coverInfos = XPrequelConfigs.GetPrequelCoverById(coverId)
        local chapterIds = coverInfos.ChapterId

        for _, chapterId in pairs(chapterIds or {}) do
            local chapterInfo = XPrequelConfigs.GetPrequelChapterById(chapterId)
            for _, openConditoinId in pairs(chapterInfo.OpenCondition or {}) do
                local rect, desc = XConditionManager.CheckCondition(openConditoinId)
                if not rect then
                    return desc
                end
            end
        end
        return ""
    end

    -- 检查章节开启条件
    function XPrequelManager.GetChapterUnlockDescription(chapterId)
        local chapterTemplate = XPrequelConfigs.GetPrequelChapterById(chapterId)
        -- 如果处于活动，优先判断活动的Condition
        local inActivity = XPrequelManager.IsChapterInActivity(chapterId)
        if chapterTemplate.ActivityCondition ~= 0 and inActivity then
            local rect, desc = XConditionManager.CheckCondition(chapterTemplate.ActivityCondition)
            if not rect then
                return desc
            end
            return ""
        end

        for _, openConditoinId in pairs(chapterTemplate.OpenCondition or {}) do
            local rect, desc = XConditionManager.CheckCondition(openConditoinId)
            if not rect then
                return desc
            end
        end
        return ""
    end

    -- [进度]
    function XPrequelManager.GetChapterProgress(chapterId)
        local chapterInfos = XPrequelConfigs.GetPrequelChapterById(chapterId)
        local total = 0
        local finishedStageNum = 0
        for _, stageId in pairs(chapterInfos.StageId or {}) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
            if stageCfg.StageType ~= XFubenConfigs.STAGETYPE_STORYEGG and stageCfg.StageType ~= XFubenConfigs.STAGETYPE_FIGHTEGG then
                total = total + 1
                if stageInfo.Passed then
                    finishedStageNum = finishedStageNum + 1
                end
            end
        end
        return finishedStageNum, total
    end

    -- [寻找一个可以使用的章节]
    function XPrequelManager.GetSelectableChaperIndex(cover)
        local showChapter = cover.ShowChapter
        local defaultChapter = 1
        local hasDefault = false
        local reverseId = #cover.CoverActiveChapterIds --章节UI页签按钮是以倒序显示的
        for index, chapterId in pairs(cover.CoverActiveChapterIds or {}) do
            local isLock = XPrequelManager.GetChapterLockStatus(chapterId)
            if not isLock then
                if showChapter and showChapter == chapterId then
                    return reverseId
                end
                if not hasDefault then
                    hasDefault = true
                    defaultChapter = index
                end
            end
            reverseId = reverseId - 1
        end
        return defaultChapter
    end

    function XPrequelManager.GetIndexByChapterId(cover, chapterId)
        if not chapterId then return nil end
        local index = #cover.CoverActiveChapterIds
        for _, id in pairs(cover.CoverActiveChapterIds or {}) do
            if XPrequelManager.IsChapterInActivity(id) or not XPrequelManager.GetChapterLockStatus(id) then
                if chapterId == id then
                    return index
                end
            end
            index = index - 1
        end
        return index
    end

    -- [获取章节锁定状态] true 锁定  false 解锁
    function XPrequelManager.GetChapterLockStatus(chapterId)
        local chapterTemplate = XPrequelConfigs.GetPrequelChapterById(chapterId)
        -- 如果处于活动，优先判断活动的Condition
        local inActivity = XPrequelManager.IsChapterInActivity(chapterId)
        if chapterTemplate.ActivityCondition ~= 0 and inActivity then
            local rect = XConditionManager.CheckCondition(chapterTemplate.ActivityCondition)
            return not rect
        end

        local isLock = true
        for _, conditionId in pairs(chapterTemplate.OpenCondition or {}) do
            local rect, _ = XConditionManager.CheckCondition(conditionId)
            if rect then
                isLock = false
                break
            end
        end
        return isLock
    end

    -- [章节是否处于活动中]
    function XPrequelManager.IsInActivity()
        local chapters = XPrequelConfigs.GetPequelAllChapter()

        for chapterId in pairs(chapters) do
            if XPrequelManager.IsChapterInActivity(chapterId) then
                return true
            end
        end

        return false
    end

    -- [是否有章节处于活动中]
    function XPrequelManager.IsChapterInActivity(chapterId)
        local config = XPrequelConfigs.GetPrequelChapterById(chapterId)
        return XFunctionManager.CheckInTimeByTimeId(config.TimeId)
    end

    -- 支线奖励
    function XPrequelManager.CheckRewardAvailable(chapterId)
        local chapterInfos = XPrequelConfigs.GetPrequelChapterById(chapterId)
        local rewardedStages = XPrequelManager.GetRewardedStages()
        for _, stageId in pairs(chapterInfos.StageId or {}) do
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageCfg.FirstRewardShow > 0 and stageInfo.Passed and rewardedStages and (not rewardedStages[stageId]) then
                return true
            end
        end
        return false
    end

    -- function XPrequelManager.GetListCovers()
    --     local coverList = {}
    --     for k, v in pairs(XPrequelConfigs.GetPrequelCoverList() or {}) do
    --         local showChapter, isActivity, isAllChapterLock, isActivityNotOpen = XPrequelManager.GetPriorityChapter(v.ChapterId, k)
    --         local chapterWeight = 0
    --         if isActivity then
    --             chapterWeight = 4
    --         else
    --             if isAllChapterLock == false then
    --                 chapterWeight = 3
    --             end
    --             if isActivityNotOpen then
    --                 chapterWeight = 2
    --             end
    --         end
    --         local activeChapterIds = XPrequelManager.GetListActiveChapterIdsByCoverId(k)
    --         if #activeChapterIds > 0 then -- 如果存在当前时间下激活的章节才显示
    --             table.insert(coverList, {
    --                 CoverId = k,
    --                 CoverVal = v,
    --                 ShowChapter = showChapter,
    --                 IsActivity = isActivity,
    --                 IsAllChapterLock = isAllChapterLock,
    --                 IsActivityNotOpen = isActivityNotOpen,
    --                 ChapterWeight = chapterWeight,
    --                 CoverActiveChapterIds = activeChapterIds,
    --             })
    --         end
    --     end
    --     table.sort(coverList, function(coverA, coverB)
    --         local coverAWeight = coverA.ChapterWeight
    --         local coverBWeight = coverB.ChapterWeight
    --         if coverAWeight == coverBWeight then
    --             return coverA.CoverVal.Priority < coverB.CoverVal.Priority
    --         end
    --         return coverAWeight > coverBWeight
    --     end)

    --     if not next(CoverIdDataDic) then
    --         for k, coverData in pairs(coverList) do
    --             CoverIdDataDic[coverData.CoverId] = coverData
    --         end
    --     end

    --     return coverList
    -- end

    -- 2.2新接口替换旧接口，从表上拆开了间章和碎片的关系
    function XPrequelManager.GetChapterList()
        local chapterList = {}
        for k, chapterCfg in pairs(XPrequelConfigs.GetPequelAllChapter() or {}) do
            local isActivity = false
            if XPrequelManager.IsChapterInActivity(chapterCfg.ChapterId) then
                if chapterCfg.ActivityCondition <= 0 or (chapterCfg.ActivityCondition > 0
                and XConditionManager.CheckCondition(chapterCfg.ActivityCondition)) then
                    isActivity = true
                end
            end

            -- 定义排序权重
            local isLock = XPrequelManager.GetChapterLockStatus(chapterCfg.ChapterId)
            local chapterWeight = 1
            if isActivity then -- 活动限时开放优先显示
                chapterWeight = 2
            end
            if isLock then
                chapterWeight = 0
            end
         
            table.insert(chapterList, {
                ChapterId = k,
                PequelChapterCfg = chapterCfg,
                IsActivity = isActivity,
                IsLock = isLock,
                ChapterWeight = chapterWeight,
            })
        end

        table.sort(chapterList, function(chapterA, chapterB)
            if chapterA.ChapterWeight == chapterB.ChapterWeight then 
                return chapterA.PequelChapterCfg.Order < chapterB.PequelChapterCfg.Order
            end
            return chapterA.ChapterWeight > chapterB.ChapterWeight
        end)

        return chapterList
    end

    -- 获取当前时间已激活的章节Id列表
    function XPrequelManager.GetListActiveChapterIdsByCoverId(coverId)
        local coverTemplate = XPrequelConfigs.GetPrequelCoverById(coverId)
        local activeChapterIdList = {}
        local nowTimeStamp = XTime.GetServerNowTimestamp()
        for i, v in ipairs(coverTemplate.ChapterId) do
            local isActive = false
            if coverTemplate.ActiveTimes[i] ~= nil and coverTemplate.ActiveTimes[i] ~= "" then
                local activeTime = XTime.ParseToTimestamp(coverTemplate.ActiveTimes[i])
                if nowTimeStamp >= activeTime then
                    isActive = true
                end
            else
                isActive = true
            end

            if isActive then
                table.insert(activeChapterIdList, coverTemplate.ChapterId[i])
            end
        end

        return activeChapterIdList
    end

    function XPrequelManager.GetPriorityChapter(chapters, coverId)
        local currentChapter = chapters[1]
        local currentPriority = 0
        local isActivity = false
        local isActivityNotOpen = false
        local isAllChapterLock = true
        for _, chapterId in pairs(chapters or {}) do
            local chapterInfo = XPrequelConfigs.GetPrequelChapterById(chapterId)

            if XPrequelManager.IsChapterInActivity(chapterId) then
                if currentPriority < chapterInfo.Priority then
                    isActivityNotOpen = true
                    if chapterInfo.ActivityCondition <= 0 or (chapterInfo.ActivityCondition > 0
                    and XConditionManager.CheckCondition(chapterInfo.ActivityCondition)) then
                        --currentChapter = chapterId
                        currentPriority = chapterInfo.Priority
                        isActivity = true
                        isActivityNotOpen = false
                    end
                end
            end

            for _, conditionId in pairs(chapterInfo.OpenCondition or {}) do
                local rect, _ = XConditionManager.CheckCondition(conditionId)
                if rect then
                    isAllChapterLock = false
                end
            end
        end
        -- [寻找一个正确的显示在封面的章节]
        if (not isAllChapterLock) and (not isActivity) then
            for _, chapterId in pairs(chapters or {}) do
                if not XDataCenter.PrequelManager.GetChapterLockStatus(chapterId) then
                    --currentChapter = chapterId
                    break
                end
            end
        end
        -- 优先显示上一次打过的章节
        -- if not Cover2ChapterMap[coverId] then
        --     local key = string.format("%s%s", CoverPrefix, tostring(coverId))
        --     local recordChapter = XPrequelManager.GetCoverChapterHint(key, currentChapter)
        --     local isRecordChapterInActivity = XPrequelManager.IsChapterInActivity(recordChapter)
        --     local recordChapterDescription = XPrequelManager.GetChapterUnlockDescription(recordChapter)
        --     if isRecordChapterInActivity then
        --         --currentChapter = recordChapter
        --     else
        --         if recordChapterDescription == nil then
        --             --currentChapter = recordChapter
        --         end
        --     end
        -- elseif Cover2ChapterMap[coverId] and Cover2ChapterMap[coverId] ~= currentChapter then
        --     local recordChapter = Cover2ChapterMap[coverId]
        --     local recordChapterDescription = XPrequelManager.GetChapterUnlockDescription(recordChapter)
        --     local isRecordChapterInActivity = XPrequelManager.IsChapterInActivity(recordChapter)
        --     if isRecordChapterInActivity then
        --         --currentChapter = Cover2ChapterMap[coverId]
        --     else
        --         if recordChapterDescription == nil then
        --             --currentChapter = recordChapter
        --         end
        --     end
        -- end
        return currentChapter, isActivity, isAllChapterLock, isActivityNotOpen
    end

    function XPrequelManager.GetNextCheckPointTime()
        return NextCheckPoint
    end

    function XPrequelManager.GetChapterIdByStageId(stageId)
        return Stage2ChapterMap[stageId]
    end

    ------------------碎片副本入口扩展(带ChapterViewModel) start-------------------------
    function XPrequelFragmentManager.IsFragmentInActivity(fragmentId)
        local fragmentCfg = XPrequelConfigs.GetFragments()[fragmentId]
        local coverId = fragmentCfg.CoverId
        local coverCfg = XPrequelConfigs.GetPrequelCoverList()[coverId]
        local inActivity = XFunctionManager.CheckInTimeByTimeId(coverCfg.TimeId)
        return inActivity
    end

    -- [获取碎片关锁定状态]
    function XPrequelFragmentManager.GetFragmentLockStatus(fragmentId)
        local fragmentCfg = XPrequelConfigs.GetFragments()[fragmentId]
        local coverId = fragmentCfg.CoverId
        local coverCfg = XPrequelConfigs.GetPrequelCoverList()[coverId]
        -- 如果处于活动，优先判断活动的Condition
        local inActivity = XPrequelFragmentManager.IsFragmentInActivity(fragmentId)
        if coverCfg.ActivityCondition ~= 0 and inActivity then
            local rect = XConditionManager.CheckCondition(coverCfg.ActivityCondition)
            return not rect
        end

        -- 再判断碎片关入口原本的condition
        if XTool.IsNumberValid(coverCfg.OpenCondition) then
            local rect, _ = XConditionManager.CheckCondition(coverCfg.OpenCondition)
            return not rect
        end
    end

    -- [获取碎片关锁定的提示]
    function XPrequelFragmentManager.GetFragmentUnlockDescription(fragmentId)
        local fragmentCfg = XPrequelConfigs.GetFragments()[fragmentId]
        local coverId = fragmentCfg.CoverId
        local coverCfg = XPrequelConfigs.GetPrequelCoverList()[coverId]
        -- 如果处于活动，优先判断活动的Condition
        local inActivity = XPrequelFragmentManager.IsFragmentInActivity(fragmentId)
        if coverCfg.ActivityCondition ~= 0 and inActivity then
            local rect, desc = XConditionManager.CheckCondition(coverCfg.ActivityCondition)
            return desc
        end

        -- 再判断碎片关入口原本的condition
        if XTool.IsNumberValid(coverCfg.OpenCondition) then
            local rect, desc = XConditionManager.CheckCondition(coverCfg.OpenCondition)
            return desc
        end
    end

    function XPrequelFragmentManager:ExGetFunctionNameType()
        return XFunctionManager.FunctionName.Prequel
    end

    -- 检查是否展示红点
    function XPrequelFragmentManager:ExCheckIsShowRedPoint()
        for _, viewModel in ipairs(self:ExGetChapterViewModels()) do
            if viewModel:CheckHasRedPoint() then
                return true
            end
        end
   
        return false
    end

    function XPrequelFragmentManager:GetCharacterListIdByChapterViewModels()
        local result ={}
        for i, chapterViewModel in ipairs(self:ExGetChapterViewModels()) do
            local characterId = chapterViewModel:GetConfig().CharacterId
            result[i] = {Id = characterId}
            if not self.CharacterIdModelDic then
                self.CharacterIdModelDic = {}
            end
            self.CharacterIdModelDic[characterId] = chapterViewModel
        end
        return result
    end

    function XPrequelFragmentManager:SortModelViewByCharacterList(characterList)
        local result = {}
        for i, v in ipairs(characterList) do
            table.insert(result, self.CharacterIdModelDic[v.Id])
        end
        return result
    end

    local function SortModels(models)
        local lockList = {}
        local unLockList = {}
        for k, model in ipairs(models) do
            if model:GetIsLocked() then
                table.insert(lockList, model)
            else
                table.insert(unLockList, model)
            end            
        end
        -- 限时开放要在最前面
        table.sort(lockList, function (a, b)
            if a:CheckHasTimeLimitTag() ~= b:CheckHasTimeLimitTag() then
                return a:CheckHasTimeLimitTag()
            end
            return a:GetId() < b:GetId()
        end)
        table.sort(unLockList, function (a, b)
            if a:CheckHasTimeLimitTag() ~= b:CheckHasTimeLimitTag() then
                return a:CheckHasTimeLimitTag()
            end
            return a:GetId() < b:GetId()
        end)

        return appendArray(unLockList, lockList)
    end
    
    function XPrequelFragmentManager:ExGetChapterViewModels()
        if self.__ChapterViewModelDic == nil then self.__ChapterViewModelDic = {} end
        if next(self.__ChapterViewModelDic) then
            return SortModels(self.__ChapterViewModelDic)
        end
        local chapterConfigs = XPrequelConfigs.GetFragments()
        local coverList = XPrequelConfigs.GetPrequelCoverList()
        for _, config in ipairs(chapterConfigs) do
            local coverId = config.CoverId
            local coverCfg = coverList[coverId]
            local characterId = coverCfg.CharacterId
            table.insert(self.__ChapterViewModelDic, CreateAnonClassInstance({
                GetProgress = function(proxy)
                    return nil
                end,
                GetIsLocked = function(proxy)
                    -- return XPrequelManager.GetChapterLockStatus(config.ChapterId)
                    return XPrequelFragmentManager.GetFragmentLockStatus(config.Id)
                end,
                GetLockTip = function(proxy)
                    return XPrequelFragmentManager.GetFragmentUnlockDescription(config.Id)
                end,
                GetOpenDayString = function(proxy)
                    -- local name = config.RoleName
                    local name = XMVCA.XCharacter:GetCharacterTemplate(characterId).Name
                    return name, true
                end,
                CheckHasTimeLimitTag = function(proxy)
                    return XPrequelFragmentManager.IsFragmentInActivity(config.Id)
                end,
                IsDayLock = function(proxy)
                    return nil
                end,
                OpenUi = function(proxy)
                    XLuaUiManager.Open("UiPrequelFragment", config, coverCfg)
                end,
            }, XChapterViewModel
            , {
                Id = config.Id,
                ExtralName = XMVCA.XCharacter:GetCharacterTemplate(characterId).TradeName,
                Name = XMVCA.XCharacter:GetCharacterTemplate(characterId).TradeName,
                Desc = config.Desc,
                Icon = config.Icon,
                CharacterId = characterId,
                ExtralData = config,
            }))
        end

        return SortModels(self.__ChapterViewModelDic)
    end
    ------------------副本入口扩展 end-------------------------

    return XPrequelManager
end

XRpc.NotifyFubenPrequelData = function(response)
    if not response then return end
    XDataCenter.PrequelManager.InitPrequelData(response.FubenPrequelData)
end

-- [领取奖励]
XRpc.NotifyPrequelRewardedStages = function(response)
    if not response then return end
    XDataCenter.PrequelManager.OnSyncRewardedStage(response)
end

-- [解锁挑战关卡回复]
XRpc.NotifyPrequelUnlockChallengeStages = function(response)
    if not response then return end
    XDataCenter.PrequelManager.OnSyncUnlockChallengeStage(response)
end

XRpc.NotifyPrequelChallengeStage = function(response)
    if not response then return end
    XDataCenter.PrequelManager.OnSyncSingleUnlockChallengeStage(response)
end

-- [下一个刷新时间]
XRpc.NotifyPrequelChallengeRefreshTime = function(response)
    if not response then return end
    XDataCenter.PrequelManager.OnSyncNextRefreshTime(response)
end