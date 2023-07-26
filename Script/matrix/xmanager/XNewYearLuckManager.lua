local XNewYearLuckLevel = require("XEntity/XNewYearLuck/XNewYearLuckLevel")
XNewYearLuckManagerCreator = function() 
    local XNewYearLuckManager = {}
    local activityId = 1
    ---@type XTable.XTableNewYearLuckActivity
    local activityCfg
    local LevelEntity = {}
    function XNewYearLuckManager.InitActivityData(data)
        if not data or not data.ActivityId or data.ActivityId == 0  then
            return
        end
        activityId = data.ActivityId
        activityCfg = XNewYearLuckConfigs.GetActivityConfig(activityId)  
        LevelEntity[XNewYearLuckConfigs.TicketType.Normal] = {}
        LevelEntity[XNewYearLuckConfigs.TicketType.Special] = {}
        for i, price in pairs(activityCfg.NormalTicketPrices) do
            local entity = XNewYearLuckLevel.New(XNewYearLuckConfigs.TicketType.Normal, i, price)
            table.insert(LevelEntity[XNewYearLuckConfigs.TicketType.Normal], entity)
        end

        for i, price in pairs(activityCfg.SpecialTicketPrices) do
            local entity = XNewYearLuckLevel.New(XNewYearLuckConfigs.TicketType.Special, i, price)
            table.insert(LevelEntity[XNewYearLuckConfigs.TicketType.Special], entity)
        end
        
        for _,level in pairs(data.LuckLevels) do
            local groupType = XNewYearLuckConfigs.GetLevelTypeById(level.LevelId, activityId)
            LevelEntity[groupType][level.GridIndex]:UpdateData(level)
        end
    end
    
    function XNewYearLuckManager.GetActivityStartTime()
        return XFunctionManager.GetStartTimeByTimeId(activityCfg.TimeId)
    end
    
    function XNewYearLuckManager.GetActivityEndTime()
        return XFunctionManager.GetEndTimeByTimeId(activityCfg.TimeId)
    end
    
    function XNewYearLuckManager.GetDrawTime()
        return XFunctionManager.GetStartTimeByTimeId(activityCfg.OpenPrizeTimeId)
    end
    
    function XNewYearLuckManager.GetUseItemId()
        return activityCfg.UseItem
    end
    
    function XNewYearLuckManager.IsFirstInActivity()
        local isFirstIn = XSaveTool.GetData(string.format("NewYearLuck%d",XPlayer.Id))
        if isFirstIn then
            return false
        else
            return true
        end
    end
    
    function XNewYearLuckManager.IsCanReward()
        local now = XTime.GetServerNowTimestamp()
        return XNewYearLuckManager.GetDrawTime() <= now
    end
    
    function XNewYearLuckManager.OpenMainUi()
        if not activityCfg then
            return
        end
        if not XFunctionManager.CheckInTimeByTimeId(activityCfg.TimeId) then
            return 
        end
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.NewYearLuck) then
            return
        end
        XLuaUiManager.Open("UiNewYearLuckMain")
    end

    function XNewYearLuckManager.GetActivityChapters()
        if not activityCfg then
            return
        end
        local chapters = {}
        if XFunctionManager.CheckInTimeByTimeId(activityCfg.TimeId) then
            local tempChapter = {}
            tempChapter.Id = activityId
            tempChapter.Name = activityCfg.Name
            tempChapter.Type = XDataCenter.FubenManager.ChapterType.NewYearLuck
            tempChapter.BannerBg = activityCfg.BannerBg
            table.insert(chapters, tempChapter)
        end
        return chapters
    end
    
    function XNewYearLuckManager.GetProgress()
        local passCount = 0
        local totalCount = 0
        for k,list in pairs(LevelEntity) do
            totalCount = totalCount + #list
            for _,entity in pairs(list) do
                if entity:IsDraw() or entity:IsRewarded() then
                    passCount = passCount + 1
                end
            end
        end
        return passCount,totalCount
    end
    
    function XNewYearLuckManager.GetLevelPrice(groupType,index)
        if groupType == XNewYearLuckConfigs.TicketType.Normal then
            return activityCfg.NormalTicketPrices[index]
        elseif groupType == XNewYearLuckConfigs.TicketType.Special then
            return activityCfg.SpecialTicketPrices[index]
        end
    end
    
    function XNewYearLuckManager.GetLevelConfig(id)
        return XNewYearLuckConfigs.GetLevelConfig(id, activityId)
    end
    
    function XNewYearLuckManager.GetLevelListByType(groupType)
        local levelList = XNewYearLuckConfigs.GetLevelListByType(groupType, activityId)
        return levelList
    end
    
    function XNewYearLuckManager.GetLevelEntity(groupType,index)
        return LevelEntity[groupType][index]
    end
    
    function XNewYearLuckManager.GetNormalCount()
        return activityCfg.NormalUnlockMax
    end
    
    function XNewYearLuckManager.GetSpecialCount()
        return activityCfg.SpecialUnlockMax
    end
    
    return XNewYearLuckManager
end

XRpc.NotifyNewYearLuckData = function(data)
    XDataCenter.NewYearLuckManager.InitActivityData(data)
end