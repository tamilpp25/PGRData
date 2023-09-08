local XExFubenActivityManager = require("XEntity/XFuben/XExFubenActivityManager")
local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
local XFubenBaseAgency = require("XModule/XBase/XFubenBaseAgency")

XFubenManagerExCreator = function()
    ---@class FubenManagerEx
    local FubenManagerEx = {}
    local ManagerDic = {}
    ---@type table<number, XExFubenBaseManager>
    local ActivityManagers = {}
    local _IsInCheckShowFinish = false
    local _InCheckShowTimeCache = 0

    -- 初始化
    function FubenManagerEx.Init()
        _IsInCheckShowFinish = false
        -- 注册FubenActivity配置的活动
        local activityConfigs = XFubenConfigs.GetAllConfigs(XFubenConfigs.TableKey.FubenActivity)
        local manager = nil
        for _, config in ipairs(activityConfigs) do
            if config.IsAgency == 0 then
                if string.IsNilOrEmpty(config.ManagerName) then
                    manager = CreateAnonClassInstance({}, XExFubenActivityManager, nil, config)
                else
                    manager = XDataCenter[config.ManagerName]
                    if manager == nil then
                        XLog.Error("FubenManagerEx.Init Failed: XDataCenter." .. config.ManagerName .. " is nil !!")
                    end
                    if not CheckClassSuper(manager, XExFubenActivityManager) then
                        if manager.__cname ~= "XExFubenActivityManager" then
                            local method = manager.ExOverrideBaseMethod and manager:ExOverrideBaseMethod() or {}
                            manager = CreateAnonClassInstance(method, XExFubenActivityManager, nil, config)
                        end
                    end
                end
                table.insert(ActivityManagers, manager)
            end
        end
    end

    --兼容XMVCA注册活动manager
    function FubenManagerEx.RegisterActivityAgency(agencyList)
        for _, agency in ipairs(agencyList) do
            table.insert(ActivityManagers, agency)
        end
    end

    --兼容XMVCA注册副本
    function FubenManagerEx.RegisterFubenAgency(agencyList)
        for _, agency in ipairs(agencyList) do
            FubenManagerEx.RegisterManager(agency)
        end
    end

    -- 注册管理器
    function FubenManagerEx.RegisterManager(manager)
        local chapterType = manager:ExGetChapterType()
        ManagerDic[chapterType] = ManagerDic[chapterType] or {}
        table.insert(ManagerDic[chapterType], manager)
    end

    -- 根据XFubenConfigs.ChapterType获取管理器数据
    function FubenManagerEx.GetManagers(chapterType)
        return ManagerDic[chapterType] or {}
    end

    -- 根据XFubenConfigs.ChapterType获取管理器数据，默认第一个
    ---@return XExFubenBaseManager
    function FubenManagerEx.GetManager(chapterType)
        return FubenManagerEx.GetManagers(chapterType)[1]
    end

    -- 获取FubenActivity配置的活动数据
    function FubenManagerEx.GetActivityManagers()
        local managers = {}
        for _, manager in ipairs(ActivityManagers or {}) do
            if manager:ExCheckInTime() then
                table.insert(managers, manager)
            end
        end
        --获取的时候再排序
        table.sort(managers, function (managerA, managerB)
            return managerA:ExGetConfig().Order < managerB:ExGetConfig().Order
        end)
        return managers
    end

    -- 获取主线管理器
    function FubenManagerEx.GetMainLineManager()
        return ManagerDic[XFubenConfigs.ChapterType.MainLine][1]
    end

    -- 获取展示在主界面的周常副本管理器
    ---@return XExFubenBaseManager[]
    function FubenManagerEx.GetShowOnMainWeeklyManagers(isNotSort)
        local managerChapterList = XFubenConfigs.GetChallengeShowGridList()
        local managers = {}
        local indexRecord = {}
        for _, chapterType in ipairs(managerChapterList) do
            local manager = FubenManagerEx.GetManager(chapterType)
            managers[#managers + 1] = manager
            indexRecord[manager:ExGetChapterType()] = #managers
        end
        if isNotSort then
            return managers
        end
        ---@param managerA XExFubenBaseManager
        ---@param managerB XExFubenBaseManager
        table.sort(managers, function (managerA, managerB)
            if managerA:ExGetIsLocked() ~= managerB:ExGetIsLocked() then
                return not managerA:ExGetIsLocked() 
            end
            if managerA:ExCheckIsClear() ~= managerB:ExCheckIsClear() then
                return not managerA:ExCheckIsClear()
            end
            return indexRecord[managerA:ExGetChapterType()] < indexRecord[managerB:ExGetChapterType()]
        end)
        local result = {}
        for _, manager in ipairs(managers) do
            if #result >= XFubenConfigs.GetChallengeShowGridCount() then
                break
            else
                result[#result + 1] = manager
            end
        end
        return result
    end
    
    function FubenManagerEx.CheckShowManagersFinish(cb)
        local nowTime = XTime.GetServerNowTimestamp()
        -- 有汇报未知操作下导致_IsInCheckShowFinish未解开
        -- 因此新增时间计时超过5s重新刷新时锁未解开则直接解锁
        if nowTime - _InCheckShowTimeCache > 5 then
            if _IsInCheckShowFinish then
                XLog.Debug("Weekly Activity Panel Refresh Auto UnLock")
                _IsInCheckShowFinish = false
            end
            _InCheckShowTimeCache = nowTime
        end
        if _IsInCheckShowFinish then
            return
        end
        _IsInCheckShowFinish = true
        local managerChapterList = XFubenConfigs.GetChallengeShowGridList()
        local managerCount = #managerChapterList
        
        if managerCount <= 0 and cb then
            cb()
            return
        end
        local waitData = function()
            managerCount = managerCount - 1
            if managerCount <= 0 and cb then
                _IsInCheckShowFinish = false
                cb()
            end
        end
        for _, chapterType in ipairs(managerChapterList) do
            FubenManagerEx.GetManager(chapterType):ExCheckIsFinished(waitData)
        end
    end
    
    -- 获取当前主界面展示的主线\浮点\活动记录最新章节（限时章节优先级最高）
    function FubenManagerEx.GetCurrentRecordChapterAndManager()
        local currConfig = nil
        -- 先检查限时开放
        local chapterViewModels = {}
        -- 主线剧情
        local mainLineManager = FubenManagerEx.GetMainLineManager()
        for _, config in ipairs(mainLineManager:ExGetChapterGroupConfigs()) do
            chapterViewModels = appendArray(chapterViewModels, mainLineManager:ExGetChapterViewModels(config.Id))
        end
        local mainLineManagerIndex = #chapterViewModels
        -- 浮点纪实
        local shortStoryManager = XDataCenter.ShortStoryChapterManager
        chapterViewModels = appendArray(chapterViewModels, shortStoryManager:ExGetChapterViewModels())
        local shortStoryManagerIndex = #chapterViewModels
        -- 外篇
        local extraManager = XDataCenter.ExtraChapterManager
        chapterViewModels = appendArray(chapterViewModels, extraManager:ExGetChapterViewModels(XDataCenter.FubenMainLineManager.DifficultNormal))
        chapterViewModels = appendArray(chapterViewModels, extraManager:ExGetChapterViewModels(XDataCenter.FubenMainLineManager.DifficultHard))
        -- 活动记录
        local festivalManager = XDataCenter.FubenFestivalActivityManager
        chapterViewModels = appendArray(chapterViewModels, festivalManager:ExGetChapterViewModels(XFestivalActivityConfig.UiType.ExtralLine))
        local festivalManagerIndex = #chapterViewModels
        -- 根据下标获取管理器
        local getManagerFunc = function(index)
            if mainLineManagerIndex >= index then
                return mainLineManager
            end
            if shortStoryManagerIndex >= index then
                return shortStoryManager
            end
            if festivalManagerIndex >= index then
                return festivalManager
            end
        end
        local currActivityViewModel = nil
        local currActivityManager = nil
        for i, viewModel in ipairs(chapterViewModels) do
            local currPrg, totalPrg = viewModel:GetCurrentAndMaxProgress()
            local isPass = currPrg >= totalPrg

            if viewModel:CheckHasTimeLimitTag() and not isPass then
                currActivityViewModel = viewModel
                currActivityManager = getManagerFunc(i)
                if not viewModel:GetIsLocked() then
                    return viewModel, getManagerFunc(i)
                end
            end
        end

        -- 如果没有【限时开放】，开始执行下列代码
        local configs = XFubenConfigs.GetAllConfigs(XFubenConfigs.TableKey.FubenStoryLine)
        local normalList = {}
        local passSkipConditionList = {} -- 通过SkipCondition条件的chapter

        -- 分类
        for id, v in pairs(configs) do
            if v.SkipCondition and v.SkipCondition > 0 and XConditionManager.CheckCondition(v.SkipCondition) then
                table.insert(passSkipConditionList,v)
            else
                table.insert(normalList,v)
            end
        end

        -- 检查condition 规则：
        -- 1.若当前condition通过,continue
        -- 2.若未通过，选择当前数据作为currConfig
        local checkNum = 0 --检测通过的次数
        for i, v in ipairs(normalList) do
            if not XConditionManager.CheckCondition(v.Condition) then
                currConfig = v
                break
            end
            checkNum = checkNum + 1
        end

        -- 如果nm的condition全部通过就开始检查 passSkipConditionList 的condition
        local isAllNormalPass = checkNum == #normalList
        if isAllNormalPass and passSkipConditionList and next(passSkipConditionList) then
            for i, v in ipairs(passSkipConditionList) do
                if not XConditionManager.CheckCondition(v.Condition) then
                    currConfig = v
                    break
                end
            end
        end

        local cuurChapterViewModel, currManager
        if currConfig then
            currManager = FubenManagerEx.GetManagers(currConfig.ChapterType)[1]
            cuurChapterViewModel = currManager:ExGetChapterViewModelBySubChapterId(currConfig.ChapterId)
        end

        -- 如果限时和当前进度中的chapter都上锁了，进入判断
        if currActivityViewModel and currActivityViewModel:GetIsLocked() and cuurChapterViewModel and cuurChapterViewModel:GetIsLocked() then
            local currViewModelFirstStage = cuurChapterViewModel:GetConfig().FirstStage
            local activityCondition = currActivityViewModel:GetConfig().ActivityCondition
            if currViewModelFirstStage and activityCondition then
                local stageRequireLevel = XDataCenter.FubenManager.GetStageCfg(currViewModelFirstStage).RequireLevel
                local conditionTemplate = XConditionManager.GetConditionTemplate(activityCondition)
                if conditionTemplate and conditionTemplate.Type == 10101 and stageRequireLevel then -- 如果2者都是等级限制条件
                    if conditionTemplate.Params[1] <= stageRequireLevel then -- 且如果限时条件副本所需等级 <= 正常进度副本所需等级 ，则优先显示限时的
                        cuurChapterViewModel = currActivityViewModel
                        currManager = currActivityManager
                    end
                end
            end
        end

        --所有的condition已通过 则返回nil
        return cuurChapterViewModel, currManager
    end

    -- 获取主界面一级标签配置
    function FubenManagerEx.GetMainUiTabConfigs()
        return XFubenConfigs.GetAllConfigs(XFubenConfigs.TableKey.FubenTabConfig)
    end

    -- 获取主界面活动提示
    function FubenManagerEx.GetActivityMainUiTips()
        local configs = XFubenConfigs.GetAllConfigs(XFubenConfigs.TableKey.FubenActivityTimeTips)
        for i = #configs, 1, -1 do
            if XFunctionManager.CheckInTimeByTimeId(configs[i].TimeId) then
                return configs[i].Desc
            end
        end
        return ""
    end

    -- 根据chapter类型获取标签信息
    function FubenManagerEx.GetTagConfigByChapterType(chapterType)
        if not chapterType then return end
        if chapterType == XFubenConfigs.ChapterType.MainLine then   -- 主线特殊 无2级标签
            for k, v in pairs(FubenManagerEx.GetMainUiTabConfigs()) do
                if v.UiParentName == "PanelMainLine" then
                    return v.Id
                end
            end
        end

        local firstTag, secondtagIndex, secondTagId   -- secondtagIndex。二级tag对应的左侧按钮的index 、Id
        local allSecondTagConfigs = XFubenConfigs.GetAllConfigs(XFubenConfigs.TableKey.FubenSecondTag)
        for k, config in pairs(allSecondTagConfigs) do
            for k, type in pairs(config.ChapterType) do
                if chapterType == type then
                    firstTag = config.FirstTagId
                    secondtagIndex = config.Order
                    secondTagId = config.Id
                    return firstTag, secondtagIndex, secondTagId
                end
            end
        end
    end

    -- 根据一级标签id，检测该标签下是否有入口开放
    function FubenManagerEx.CheckHasOpenByFirstTagId(firstTagId)
        if not firstTagId then return end
        local allSecondTag = XFubenConfigs.GetSecondTagConfigsByFirstTagId(firstTagId) -- 拿到该模式下所有的二级标签
        if not allSecondTag or not next(allSecondTag) then --没用二级标签配置的特殊标签都不会上锁(主线和战斗面板都没有配置，主线是自动生成的)
            return true
        end

        for _, secondTagconfig in pairs(allSecondTag) do
            if FubenManagerEx.CheckHasOpenBySecondTagId(secondTagconfig.Id) then
                return true
            end
        end

        return false
    end

    -- 根据二级标签id，检测该标签下是否有入口开放
    function FubenManagerEx.CheckHasOpenBySecondTagId(secondTagId)
        if not secondTagId then return end
        local secondTagConfig = XFubenConfigs.GetSecondTagConfigById(secondTagId)
        if not secondTagConfig or not next(secondTagConfig) then
            return true
        end

        local allManagers = {}
        for k, chapterType in pairs(secondTagConfig.ChapterType) do
            for k, manager in pairs(FubenManagerEx.GetManagers(chapterType)) do
                table.insert(allManagers, manager) -- 根据2级标签拿到所有manager
            end
        end

        -- 如果manager有顺序，要按顺序检测
        if allManagers[1]:ExGetConfig().Priority then
            table.sort(allManagers, function (managerA, managerB)
                return managerA:ExGetConfig().Priority < managerB:ExGetConfig().Priority
            end)
        end

        -- 检测是否有开放(没上锁的)
        for k, manager in ipairs(allManagers) do
            if not manager:ExGetIsLocked() then
                return true
            end
        end
        
        -- 如果上锁的标签有多个入口，返回优先级最高的manager的拦截提示
        return false, allManagers[1]:ExGetLockTip()
    end

    -- 根据二级标签id，返回离当前标签最近的解锁的id的下标
    function FubenManagerEx.GetUnLockMostNearSecondTagIndex(secondTagId)
        if not secondTagId then return end
        local secondTagConfig = XFubenConfigs.GetSecondTagConfigById(secondTagId)
        local firstTagId = secondTagConfig.FirstTagId
        local currSecondIndex = secondTagConfig.Order
        local allSecondTag = XFubenConfigs.GetSecondTagConfigsByFirstTagId(firstTagId)
        local unLockSecondTags = {} -- 当前同级1级标签下 所有解锁的2级标签
        for k, secondTagconfig in pairs(allSecondTag) do
            if FubenManagerEx.CheckHasOpenBySecondTagId(secondTagconfig.Id) then
                table.insert(unLockSecondTags, {
                    SecondTagId = secondTagconfig.Id,
                    IndexDistance =  math.abs(currSecondIndex - secondTagconfig.Order),
                    Index = secondTagconfig.Order
                })
            end
        end
        if not next(unLockSecondTags) then
            return 1
        end

        table.sort(unLockSecondTags, function (a, b)
            return a.IndexDistance < b.IndexDistance
        end)

        return unLockSecondTags[1].Index
    end

    function FubenManagerEx.GetStoryStagePassCount(stageList)
        local count = 0 
        local total = 0
        for k, stageId in pairs(stageList) do
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
                total = total + 1
                if XDataCenter.FubenManager.CheckStageIsPass(stageId) then
                    count = count + 1
                end
            end
        end
        return count, total
    end

    -- 记录隐藏关卡每日红点,点击进活动界面，红点消失，当天未重置前不再显示
    -- 每天凌晨5点（通用重置时间）检测是否存在未通关关卡，存在则刷新红点显示
    -- 检查红点是否显示
    function FubenManagerEx.CheckHideChapterRedPoint(viewModel)
        if viewModel:GetIsLocked() then -- 上锁不显示红点
            return false
        end

        -- 如果没有隐藏关就返回false
        local finishCount, totalCount = viewModel:GetCurrentAndMaxProgress()
        if finishCount < totalCount and not FubenManagerEx.CheckHideChapterIsOpen(viewModel:GetId()) then
            return true
        end
        return false
    end

    -- 本地保存key
    function FubenManagerEx.GetHideChapterKey(chapterId)
        return string.format("%s_%s_%s", "FubenHideChapterCheckResetDaily", XPlayer.Id, chapterId)
    end

    function FubenManagerEx.CheckHideChapterIsOpen(chapterId)
        local key = FubenManagerEx.GetHideChapterKey(chapterId)
        local updateTime = XSaveTool.GetData(key)
        if not updateTime then
            return false
        end
        return XTime.GetServerNowTimestamp() < updateTime
    end

    function FubenManagerEx.SaveHideChapterIsOpen(chapterId)
        if FubenManagerEx.CheckHideChapterIsOpen(chapterId) then
            return
        end
        local key = FubenManagerEx.GetHideChapterKey(chapterId)
        local updateTime = XTime.GetSeverTomorrowFreshTime()
        XSaveTool.SaveData(key, updateTime)
    end
    
    function FubenManagerEx.IsFubenBase(cls)
        if not cls then
            return false
        end
        
        return CheckClassSuper(cls, XExFubenBaseManager) or CheckClassSuper(cls, XFubenBaseAgency)
    end

    return FubenManagerEx
end