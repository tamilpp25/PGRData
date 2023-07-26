XWorldBossManagerCreator = function()
    local XWorldBossActivityEntity = require("XEntity/XWorldBoss/XWorldBossActivityEntity")
    local XBuffEntity = require("XEntity/XWorldBoss/XBuffEntity")
    local XWorldBossManager = {}
    local CSTextManagerGetText = CS.XTextManager.GetText
    local CSXGameClientConfig = CS.XGame.ClientConfig

    local METHOD_NAME = {
        GetWorldBossGlobalDataRequest = "GetWorldBossGlobalDataRequest",
        GetAttributeAreaRewardRequest = "GetAttributeAreaRewardRequest",
        GetAttributeAreaStageRewardRequest = "GetAttributeAreaStageRewardRequest",
        GetBossPhasesRewardRequest = "GetBossPhasesRewardRequest",
        WorldBossShopBuyRequest = "WorldBossShopBuyRequest",
        WorldBossAttributeAreaRankRequest = "WorldBossAttributeAreaRankRequest",
        GetWorldBossReportRequest = "GetWorldBossReportRequest",
    }

    local SYNC_GLOBALDATA_SECOND = 30
    local LastSyncGlobaldataTime = 0

    local WorldBossActivityDic = {}
    local WorldBossGlobalData = {}
    local WorldBossMySelfData = {}
    local WorldBossBuffDic = {}
    local WorldBossBuffGroupDic = {}
    local WorldBossBossStageDic = {}
    local FightReportList = {}
    local AreaRankData = {}
    local BossStageLevel = 1

    function XWorldBossManager.Init()
        WorldBossBuffGroupDic = {}
        XWorldBossManager.CreateWorldBossActivity()
        XWorldBossManager.CreateWorldBossBuffDic()
        XWorldBossManager.CreateWorldBossBossStageDic()
    end

    function XWorldBossManager.CreateWorldBossActivity()
        local activityCfgs = XWorldBossConfigs.GetActivityTemplates()
        for _, cgf in pairs(activityCfgs) do
            WorldBossActivityDic[cgf.Id] = XWorldBossActivityEntity.New(cgf.Id)
        end
    end

    function XWorldBossManager.UpdateWorldBossActivity()
        local worldBossActivity = XWorldBossManager.GetCurWorldBossActivity()
        if worldBossActivity then
            local tmpData = {}
            tmpData.GlobalData = WorldBossGlobalData
            tmpData.PrivateData = WorldBossMySelfData
            worldBossActivity:UpdateData(tmpData)
            worldBossActivity:UpdateEntityDic()
        end
    end

    function XWorldBossManager.CreateWorldBossBuffDic()
        local buffCfgs = XWorldBossConfigs.GetBuffTemplates()
        for _, buffCfg in pairs(buffCfgs) do
            local tmpEntity = XBuffEntity.New(buffCfg.Id)
            WorldBossBuffDic[buffCfg.Id] = tmpEntity
        end
    end

    function XWorldBossManager.UpdateGetedBossBuff(buffList)--如果在多个地方都涉及buff更新，则因为等级关系所带来的条件提示文字也会得到正确的影响
        for _, buffId in pairs(buffList) do
            local buffEntity = XWorldBossManager.GetWorldBossBuffById(buffId)
            local tmpEntity = WorldBossBuffGroupDic[buffEntity:GetGroupId()]
            local tmpData = {}
            if buffEntity:GetGroupId() == 0 then
                tmpData.LockDesc = buffEntity:GetType() == XWorldBossConfigs.BuffType.Buff and
                CSTextManagerGetText("WorldBossBuffGeted") or CSTextManagerGetText("WorldBossRobotGeted")
                tmpData.LockDescColor = CSXGameClientConfig:GetString("WorldBossBuffUnLockColor")
                tmpData.InfoTextColor = CSXGameClientConfig:GetString("WorldBossUnLockInfoColor")
                buffEntity:UpdateData(tmpData)
            else
                if (not tmpEntity) or (tmpEntity:GetLevel() <= buffEntity:GetLevel()) then
                    if tmpEntity then
                        tmpData.LockDesc = CSTextManagerGetText("WorldBossBuffLevelLow")
                        tmpData.LockDescColor = CSXGameClientConfig:GetString("WorldBossBuffLowColor")
                        tmpData.InfoTextColor = CSXGameClientConfig:GetString("WorldBossLockInfoColor")
                        tmpEntity:UpdateData(tmpData)
                    end
                    tmpData.LockDesc = buffEntity:GetType() == XWorldBossConfigs.BuffType.Buff and
                    CSTextManagerGetText("WorldBossBuffGeted") or CSTextManagerGetText("WorldBossRobotGeted")
                    tmpData.LockDescColor = CSXGameClientConfig:GetString("WorldBossBuffUnLockColor")
                    tmpData.InfoTextColor = CSXGameClientConfig:GetString("WorldBossUnLockInfoColor")
                    buffEntity:UpdateData(tmpData)
                    WorldBossBuffGroupDic[buffEntity:GetGroupId()] = buffEntity
                else
                    tmpData.LockDesc = CSTextManagerGetText("WorldBossBuffLevelLow")
                    tmpData.LockDescColor = CSXGameClientConfig:GetString("WorldBossBuffLowColor")
                    tmpData.InfoTextColor = CSXGameClientConfig:GetString("WorldBossLockInfoColor")
                    buffEntity:UpdateData(tmpData)
                end
            end
            buffEntity:UpdateData({ IsLock = false })
        end
    end

    function XWorldBossManager.CreateWorldBossBossStageDic()
        local stageCfgs = XWorldBossConfigs.GetBossStageTemplates()
        for _, stageCfg in pairs(stageCfgs) do
            local bossStage = WorldBossBossStageDic[stageCfg.StageId]
            if not bossStage then
                bossStage = {}
                WorldBossBossStageDic[stageCfg.StageId] = bossStage
            end
            bossStage[stageCfg.Level] = bossStage[stageCfg.Level] or {}
            bossStage[stageCfg.Level] = stageCfg
        end
    end

    function XWorldBossManager.IsInActivity()
        local worldBossActivity = XWorldBossManager.GetCurWorldBossActivity()
        if worldBossActivity then
            local nowTime = XTime.GetServerNowTimestamp()
            if nowTime > worldBossActivity:GetBeginTime() and nowTime < worldBossActivity:GetEndTime() then
                return true
            end
        end
        return false
    end

    function XWorldBossManager.GetCurWorldBossActivity()
        local activityId = WorldBossMySelfData.ActivityId
        if not activityId then
            return nil
        end
        return WorldBossActivityDic[activityId]
    end

    function XWorldBossManager.GetWorldBossActivityById(activityId)
        if not activityId then
            return
        end
        return WorldBossActivityDic[activityId]
    end

    function XWorldBossManager.GetWorldBossBuffDic()
        return WorldBossBuffDic
    end

    function XWorldBossManager.GetWorldBossBuffById(id)
        return WorldBossBuffDic[id]
    end

    function XWorldBossManager.GetBossStageGroupByIdAndLevel(stageId, Level)
        if not WorldBossBossStageDic[stageId] then
            XLog.Error("Share/Fuben/WorldBoss/WorldBossBossStage.tab Id = " .. stageId .. " Is Null")
            return
        end
        return Level and WorldBossBossStageDic[stageId][Level] or WorldBossBossStageDic[stageId]
    end

    function XWorldBossManager.GetSameGroupBossBuffByGroupId(id)
        local buffList = {}
        if not id or id == 0 then
            return nil
        end
        for _, buff in pairs(WorldBossBuffDic) do
            if buff:GetGroupId() == id then
                table.insert(buffList, buff)
            end
        end
        table.sort(buffList, function(a, b)
            return a:GetLevel() < b:GetLevel()
        end)
        return buffList
    end

    function XWorldBossManager.GetSameGroupToLevelpBossBuffByGroupId(id)
        local buffList = {}
        local DefaultIndex = 1
        if not id or id == 0 then
            return nil
        end
        for _, buff in pairs(WorldBossBuffDic) do
            if buff:GetGroupId() == id then
                table.insert(buffList, buff)
            end
        end

        table.sort(buffList, function(a, b)
            if a:GetIsLock() and b:GetIsLock() then
                return a:GetLevel() < b:GetLevel()
            elseif not a:GetIsLock() and not b:GetIsLock() then
                return a:GetLevel() > b:GetLevel()
            else
                return not a:GetIsLock()
            end
        end)

        return buffList[DefaultIndex]
    end

    function XWorldBossManager.GetFightReportTypeById(id)
        local reportCfg = XWorldBossConfigs.GetReportTemplatesById(id)
        if reportCfg.Type == 1 or reportCfg.Type == 2 or reportCfg.Type == 3 then
            return 1
        else
            return 2
        end
    end

    function XWorldBossManager.GetWorldBossSection()--获取入口数据
        local sections = {}
        if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.WorldBoss) then
            return sections
        end
        local worldBossActivity = XWorldBossManager.GetCurWorldBossActivity()
        if worldBossActivity and XWorldBossManager.IsInActivity() then
            local defaultBossAreaId = worldBossActivity:GetBossAreaIds()[1]
            local bossArea = worldBossActivity:GetBossAreaEntityById(defaultBossAreaId)
            local section = {
                Id = worldBossActivity:GetId(),
                Type = XDataCenter.FubenManager.ChapterType.WorldBoss,
                Name = worldBossActivity:GetName(),
                BannerBg = worldBossActivity:GetBg(),
                BossHpPercent = bossArea:GetHpPercent(),
            }
            table.insert(sections, section)
        end

        return sections
    end

    function XWorldBossManager.GetWorldBossBossTaskDataDic()
        local bossAreaDatas = XWorldBossManager.GetBossAreaDic()
        local bossTaskDataDic = {}
        if not bossAreaDatas then
            return bossTaskDataDic
        end
        for _, data in pairs(bossAreaDatas) do
            local taskIds = data:GetBossTaskIds()
            for _, taskId in pairs(taskIds) do
                bossTaskDataDic[taskId] = bossTaskDataDic[taskId] or {}
                table.insert(bossTaskDataDic[taskId], data)
            end
        end
        return bossTaskDataDic
    end

    function XWorldBossManager.GetAttributeAreaDic()
        local worldBossActivity = XWorldBossManager.GetCurWorldBossActivity()
        return worldBossActivity and worldBossActivity:GetAttributeAreaEntityDic()
    end

    function XWorldBossManager.GetBossAreaDic()
        local worldBossActivity = XWorldBossManager.GetCurWorldBossActivity()
        return worldBossActivity and worldBossActivity:GetBossAreaEntityDic()
    end

    function XWorldBossManager.GetSpecialSaleDic()
        local worldBossActivity = XWorldBossManager.GetCurWorldBossActivity()
        return worldBossActivity and worldBossActivity:GetSpecialSaleEntityDic()
    end

    function XWorldBossManager.GetAttributeAreaById(id)
        local worldBossActivity = XWorldBossManager.GetCurWorldBossActivity()
        return worldBossActivity and worldBossActivity:GetAttributeAreaEntityById(id)
    end

    function XWorldBossManager.GetAttributeStageById(areaId, id)
        local worldBossActivity = XWorldBossManager.GetCurWorldBossActivity()
        local attributeArea = worldBossActivity:GetAttributeAreaEntityById(areaId)
        return worldBossActivity and attributeArea and attributeArea:GetStageEntityById(id)
    end

    function XWorldBossManager.GetBossAreaById(id)
        local worldBossActivity = XWorldBossManager.GetCurWorldBossActivity()
        return worldBossActivity and worldBossActivity:GetBossAreaEntityById(id)
    end

    function XWorldBossManager.GetSpecialSaleById(id)
        local worldBossActivity = XWorldBossManager.GetCurWorldBossActivity()
        return worldBossActivity and worldBossActivity:GetSpecialSaleEntityById(id)
    end


    function XWorldBossManager.GetCurrentActivityNo()--获取当前活动ID,如果活动未开始则返回默认活动ID
        local DefaultActivityId = XWorldBossConfigs.GetActivityLastTemplate().Id
        return WorldBossMySelfData.ActivityId or DefaultActivityId
    end

    function XWorldBossManager.GetActivityBeginTime()
        local activityId = XWorldBossManager.GetCurrentActivityNo()
        if not activityId then
            return nil
        end
        local worldBossActivity = XWorldBossManager.GetWorldBossActivityById(activityId)
        return worldBossActivity and worldBossActivity:GetBeginTime() or 0
    end

    function XWorldBossManager.GetActivityEndTime()
        local activityId = XWorldBossManager.GetCurrentActivityNo()
        if not activityId then
            return nil
        end
        local worldBossActivity = XWorldBossManager.GetWorldBossActivityById(activityId)
        return worldBossActivity and worldBossActivity:GetEndTime() or 0
    end

    function XWorldBossManager.SetBossStageLevel(level)
        BossStageLevel = level
    end

    function XWorldBossManager.GetBossStageLevel()
        return BossStageLevel
    end

    function XWorldBossManager.UpdateWorldBossGlobalData(globalData)
        WorldBossGlobalData = globalData
    end

    function XWorldBossManager.UpdateWorldBossMySelfData(mySelfData)
        WorldBossMySelfData = mySelfData
    end

    function XWorldBossManager.SetWorldBossReportList(reportList)
        FightReportList = reportList
    end

    function XWorldBossManager.GetWorldBossReportList()
        return FightReportList
    end

    function XWorldBossManager.GetWorldBossNewReport()
        return FightReportList and #FightReportList > 0 and FightReportList[#FightReportList] or nil
    end

    function XWorldBossManager.SetAreaRankData(rankList)
        AreaRankData = rankList
    end

    function XWorldBossManager.GetMyAreaRankData()
        local tmpData = {}
        tmpData.Rank = AreaRankData.Rank
        tmpData.ToTalRank = AreaRankData.ToTalRank
        tmpData.Score = AreaRankData.Score
        return tmpData
    end

    function XWorldBossManager.GetOtherAreaRankData()
        return AreaRankData.RankList or {}
    end

    function XWorldBossManager.UpdateMySelfBossAreaData(mySelfData)
        local IsHave = false
        for index, areaData in pairs(WorldBossMySelfData.BossAreaDatas) do
            if areaData.Id == mySelfData.Id then
                WorldBossMySelfData.BossAreaDatas[index] = mySelfData
                IsHave = true
                break
            end
        end
        if not IsHave then
            table.insert(WorldBossMySelfData.BossAreaDatas, mySelfData)
        end
    end

    function XWorldBossManager.UpdateMySelfAttributeAreaData(mySelfData)
        local IsHave = false
        for index, areaData in pairs(WorldBossMySelfData.AttributeAreaDatas) do
            if areaData.Id == mySelfData.Id then
                WorldBossMySelfData.AttributeAreaDatas[index] = mySelfData
                IsHave = true
                break
            end
        end
        if not IsHave then
            table.insert(WorldBossMySelfData.AttributeAreaDatas, mySelfData)
        end
    end

    function XWorldBossManager.CheckWorldBossActivityReset()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        local notInActivity = not XWorldBossManager.IsInActivity()
        if notInActivity then
            XUiManager.TipMsg(CS.XTextManager.GetText("WorldBossNotInActivityTime"))
            XScheduleManager.ScheduleOnce(function()
                XLuaUiManager.RunMain()
            end, 200)
        end
    end

    function XWorldBossManager.CheckWorldBossActivityRedPoint()
        local worldBossActivity = XWorldBossManager.GetCurWorldBossActivity()
        local attributeAreaIds = worldBossActivity:GetAttributeAreaIds()
        local bossAreaIds = worldBossActivity:GetBossAreaIds()
        local IsHaveRed = false
        for _, areaId in pairs(attributeAreaIds) do
            IsHaveRed = XWorldBossManager.CheckWorldBossAttributeArearRedPoint(areaId)
            if IsHaveRed then
                return true
            end
        end
        for _, areaId in pairs(bossAreaIds) do
            IsHaveRed = XWorldBossManager.CheckWorldBossBossArearRedPoint(areaId)
            if IsHaveRed then
                return true
            end
        end
    end

    function XWorldBossManager.CheckWorldBossBossArearRedPoint(areaId)
        local IsHaveRed = false
        local areaData = XWorldBossManager.GetBossAreaById(areaId)
        local phasesRewardDatas = areaData:GetPhasesRewardEntityDic()
        for _, phasesRewardData in pairs(phasesRewardDatas) do
            local IsCanGet = phasesRewardData:GetIsCanGet()
            local IsGeted = phasesRewardData:GetIsGeted()
            IsHaveRed = IsCanGet and not IsGeted
            if IsHaveRed then
                return true
            end
        end
        return IsHaveRed
    end

    function XWorldBossManager.CheckWorldBossAttributeArearRedPoint(areaId)
        local IsHaveRed = false
        local areaData = XWorldBossManager.GetAttributeAreaById(areaId)
        local stageIds = areaData:GetStageIds()

        local IsCanGet = areaData:GetIsAreaFinish()
        local IsGeted = areaData:GetIsRewardGeted()

        IsHaveRed = IsCanGet and not IsGeted
        if IsHaveRed then
            return true
        end

        for _, stageId in pairs(stageIds) do
            IsHaveRed = XWorldBossManager.CheckWorldBossStageRedPoint(areaId, stageId)
            if IsHaveRed then
                return true
            end
        end
        return IsHaveRed
    end

    function XWorldBossManager.CheckWorldBossStageRedPoint(areaId, stageId)
        local stageData = XWorldBossManager.GetAttributeStageById(areaId, stageId)
        local rewardId = stageData:GetFinishReward()
        local IsCanGet = stageData:GetIsFinish()
        local IsGeted = stageData:GetIsRewardGeted()
        local IsHaveRed = IsCanGet and not IsGeted and rewardId > 0
        return IsHaveRed
    end

    function XWorldBossManager.CheckAnyTaskFinished()
        local taskDatas = XDataCenter.TaskManager.GetWorldBossFullTaskList()
        if not taskDatas then
            return false
        end

        local achieved = XDataCenter.TaskManager.TaskState.Achieved
        for _, taskData in pairs(taskDatas or {}) do
            if taskData.State == achieved then
                return true
            end
        end

        return false
    end

    ---------------------------------------stage相关-------------------------------------->>>
    function XWorldBossManager.InitStageInfo()
        for _, activity in pairs(WorldBossActivityDic) do
            local attributeAreaDic = activity:GetAttributeAreaEntityDic()
            local bossAreaDic = activity:GetBossAreaEntityDic()
            for _, attributeArea in pairs(attributeAreaDic) do
                for _, stageId in pairs(attributeArea:GetStageIds()) do
                    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                    stageInfo.Type = XDataCenter.FubenManager.StageType.WorldBoss
                    stageInfo.ChapterName = attributeArea:GetName()
                    stageInfo.AreaType = XWorldBossConfigs.AreaType.Attribute
                end
            end

            for _, bossArea in pairs(bossAreaDic) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(bossArea:GetStageId())
                stageInfo.Type = XDataCenter.FubenManager.StageType.WorldBoss
                stageInfo.ChapterName = bossArea:GetName()
                stageInfo.AreaType = XWorldBossConfigs.AreaType.Boss
            end
        end
    end

    function XWorldBossManager.FinishFight(settle)
        if settle.IsWin then
            XLuaUiManager.Open("UiSettleWinWorldBoss", settle)
        else
            XLuaUiManager.Open("UiSettleLose", settle)
        end
    end

    function XWorldBossManager.OpenWorldMainWind()
        XWorldBossManager.GetWorldBossGlobalData(function()
            XWorldBossManager.GetWorldBossReport(function()
                XLuaUiManager.Open("UiWorldBossMain")
            end)
        end)
    end

    ---------------------------------------stage相关---------------------------------------<<<
    function XWorldBossManager.CheckIsNewStoryID(Id)
        if XSaveTool.GetData(string.format("%d%s%s", XPlayer.Id, "WorldBossStory", Id)) then
            return false
        end
        return true
    end

    function XWorldBossManager.MarkStoryID(Id)
        if not XSaveTool.GetData(string.format("%d%s%s", XPlayer.Id, "WorldBossStory", Id)) then
            XSaveTool.SaveData(string.format("%d%s%s", XPlayer.Id, "WorldBossStory", Id), Id)
        end
    end

    function XWorldBossManager.GetWorldBossGlobalData(cb)
        local now = XTime.GetServerNowTimestamp()
        local syscTime = LastSyncGlobaldataTime

        if syscTime and now - syscTime < SYNC_GLOBALDATA_SECOND then
            if cb then
                cb()
            end
            return
        end

        XNetwork.Call(METHOD_NAME.GetWorldBossGlobalDataRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XWorldBossManager.UpdateWorldBossGlobalData(res.GlobalData)
            XWorldBossManager.UpdateWorldBossActivity()
            LastSyncGlobaldataTime = XTime.GetServerNowTimestamp()
            XEventManager.DispatchEvent(XEventId.EVENT_WORLDBOSS_SYNCDATA)
            if cb then cb() end
        end)
    end

    function XWorldBossManager.GetAttributeAreaReward(areaId, cb)
        XNetwork.Call(METHOD_NAME.GetAttributeAreaRewardRequest, { AreaId = areaId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.OpenUiObtain(res.RewardGoodsList)
            if cb then cb() end
        end)
    end

    function XWorldBossManager.GetAttributeAreaStageReward(areaId, stageId, cb)
        XNetwork.Call(METHOD_NAME.GetAttributeAreaStageRewardRequest, { AreaId = areaId, StageId = stageId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.OpenUiObtain(res.RewardGoodsList)
            if cb then cb() end
        end)
    end

    function XWorldBossManager.GetBossPhasesReward(bossAreaId, bossPhasesId, cb)
        XNetwork.Call(METHOD_NAME.GetBossPhasesRewardRequest, { AreaId = bossAreaId, PhasesId = bossPhasesId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.OpenUiObtain(res.RewardGoodsList)
            if cb then cb() end
        end)
    end

    function XWorldBossManager.WorldBossShopBuy(bossShopId, cb)
        XNetwork.Call(METHOD_NAME.WorldBossShopBuyRequest, { ShopId = bossShopId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.OpenUiObtain(res.RewardGoodsList)
            if cb then cb() end
        end)
    end

    function XWorldBossManager.GetAttributeAreaRank(areaId, cb)
        XNetwork.Call(METHOD_NAME.WorldBossAttributeAreaRankRequest, { AreaId = areaId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XWorldBossManager.SetAreaRankData(res)
            if cb then cb() end
        end)
    end

    function XWorldBossManager.GetWorldBossReport(cb)
        XNetwork.Call(METHOD_NAME.GetWorldBossReportRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XEventManager.DispatchEvent(XEventId.EVENT_WORLDBOSS_REPORT)
            XWorldBossManager.SetWorldBossReportList(res.ReportList)
            if cb then cb() end
        end)
    end

    XWorldBossManager.Init()
    return XWorldBossManager
end

XRpc.NotifyWorldBossData = function(data)
    XDataCenter.WorldBossManager.UpdateWorldBossMySelfData(data.SingleData)
    XDataCenter.WorldBossManager.UpdateWorldBossGlobalData(data.GlobalData)
    XDataCenter.WorldBossManager.UpdateWorldBossActivity()
    XEventManager.DispatchEvent(XEventId.EVENT_WORLDBOSS_TASK_RESET)
end

XRpc.NotifyWorldBossAttributeAreaData = function(data)
    XDataCenter.WorldBossManager.UpdateMySelfAttributeAreaData(data.AttributeAreaData)
    XDataCenter.WorldBossManager.UpdateWorldBossActivity()
end

XRpc.NotifyWorldBossBossAreaData = function(data)
    XDataCenter.WorldBossManager.UpdateMySelfBossAreaData(data.BossAreaData)
    XDataCenter.WorldBossManager.UpdateWorldBossActivity()
end