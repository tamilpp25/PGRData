--===========================
--超级爬塔主题实体
--模块负责：吕天元
--===========================
local XSuperTowerTheme = XClass(nil, "XSuperTowerTheme")

function XSuperTowerTheme:Ctor(stageManager, themeId, themeIndex)
    self.StageManager = stageManager
    self.ActivityManager = stageManager.ActivityManager
    self:InitTheme(themeId)
    self.ThemeIndex = themeIndex
    self.StageId2StageType = {}
    self.StageId2Stage = {}
    self.StageId2Index = {} -- 获取关卡<->目标关卡的序号
    self.MaxStageCount = 0
    self:InitTargetStages() -- 普通关卡
    self:InitTierStage() -- 爬塔
end
--=================
--初始化主题
--@param themeId:主题Id
--=================
function XSuperTowerTheme:InitTheme(themeId)
    self.ThemeCfg = XSuperTowerConfigs.GetThemeById(themeId)
    self.EnhancerAndPluginsDropCfg = XSuperTowerConfigs.GetEnDConfigByThemeId(themeId)
    self.ThemeMapEffectCfg = XSuperTowerConfigs.GetMapEffectCfgByKey(themeId)
end
--=================
--初始化目标关卡
--=================
function XSuperTowerTheme:InitTargetStages()
    local script = require("XEntity/XSuperTower/Stages/XSuperTowerTargetStage")
    local stageList = XSuperTowerConfigs.GetTargetStagesByThemeId(self:GetId())
    self.TargetStageDic = {}
    self.TargetStageList = {}
    for orderIndex, targetStage in pairs(stageList) do
        local stage = script.New(self, targetStage)
        self.TargetStageDic[targetStage.Id] = stage
        self.TargetStageList[orderIndex] = stage
        local stageIds = stage:GetStageId()
        for index, stageId in pairs(stageIds) do
            self.StageId2StageType[stageId] = stage:GetStageType()
            self.StageId2Stage[stageId] = stage
            self.StageId2Index[stageId] = index
            if index > self.MaxStageCount then
                self.MaxStageCount = index
            end
        end
    end
end
--=================
--初始化爬塔关卡管理器
--=================
function XSuperTowerTheme:InitTierStage()
    local script = require("XEntity/XSuperTower/Stages/XSuperTowerTierManager")
    self.TierManager = script.New(self)
end
--=================
--刷新推送数据
--@param data(StMapInfo):{
--地图id int Id,
--爬塔数据 StTierInfo TierInfo,
--目标信息列表 List<StMapTargetInfo> TargetInfos
--}
--=================
function XSuperTowerTheme:RefreshNotifyInfo(data)
    self:RefreshNotifyTierInfo(data.TierInfo)
    self:RefreshTargetStageByNotifyInfo(data.TargetInfos)
end
--=================
--刷新爬塔推送数据
--@param StTierInfo TierInfo
--=================
function XSuperTowerTheme:RefreshNotifyTierInfo(data, needReset)
    self.TierManager:RefreshNotifyData(data, needReset)
end
--=================
--检查爬塔数据的重置标记
--=================
function XSuperTowerTheme:CheckReset()
    self.TierManager:CheckReset()
end
--=================
--获取爬塔数据的重置标记
--=================
function XSuperTowerTheme:GetResetFlag()
    return self.TierManager:GetResetFlag()
end
--=================
--刷新推送数据
--@param data(List<StMapTargetInfo>)
--StMapTargetInfo:{
--目标id int Id,
--进度 int Progress
--}
--=================
function XSuperTowerTheme:RefreshTargetStageByNotifyInfo(targetInfos)
    for _, info in pairs(targetInfos) do
        if self.TargetStageDic[info.Id] then
            self.TargetStageDic[info.Id]:RefreshProgress(info.Progress)
        end
    end
    self.CurrentTargetIndex = 1
    for orderIndex, stage in pairs(self.TargetStageList) do
        if stage:CheckStageIsOpen() then
            self.CurrentTargetIndex = orderIndex
        end
    end
end

function XSuperTowerTheme:InitStageInfo()
    self.TierManager:InitStageInfo()
    for _, targetStage in pairs(self.TargetStageList) do
        targetStage:InitStageInfo()
    end
end
--=================
--重置爬塔关卡
--=================
function XSuperTowerTheme:ResetTierStage()
    self.TierManager:Reset()
end
--=================
--放弃爬塔进度，结算
--=================
function XSuperTowerTheme:RequestReset(callBack)
    XNetwork.Call("StResetTierRequest", { MapId = self:GetId() }, function(reply)
            if reply.Code ~= XCode.Success then
                XUiManager.TipCode(reply.Code)
                return
            end
            if callBack then callBack() end
            self.StageManager:RefreshStMapTierData(reply.Operation)
            self.TierManager:SetResetFlag(true)
            XLuaUiManager.Open("UiSuperTowerInfiniteSettleWin", nil, self)
        end)
end
--=================
--获取主题配置表Id
--=================
function XSuperTowerTheme:GetId()
    return self.ThemeCfg and self.ThemeCfg.Id
end
--=================
--获取主题序号
--=================
function XSuperTowerTheme:GetIndex()
    return self.ThemeIndex
end
--=================
--获取主题名称
--=================
function XSuperTowerTheme:GetName()
    return self.ThemeCfg and self.ThemeCfg.Name or ""
end
--=================
--获取主题对应爬塔名称
--=================
function XSuperTowerTheme:GetTierName()
    return self.ThemeCfg and self.ThemeCfg.TierName or ""
end
--=================
--获取主题开放的TimeId
--=================
function XSuperTowerTheme:GetTimeId()
    return self.ThemeCfg and self.ThemeCfg.TimeId or 0
end
--=================
--获取主题通常地图特效
--=================
function XSuperTowerTheme:GetMapNormalEffect()
    return self.ThemeMapEffectCfg and self.ThemeMapEffectCfg.MapNormalEffect
end
--=================
--获取主题上锁地图特效
--=================
function XSuperTowerTheme:GetMapLockEffect()
    return self.ThemeMapEffectCfg and self.ThemeMapEffectCfg.MapLockEffect
end
--=================
--获取主题当前地图特效
--=================
function XSuperTowerTheme:GetMapCurrentEffect()
    return self.ThemeMapEffectCfg and self.ThemeMapEffectCfg.MapCurrentEffect
end
--=================
--获取主题地形地图特效
--=================
function XSuperTowerTheme:GetMapTerrainEffect()
    return self.ThemeMapEffectCfg and self.ThemeMapEffectCfg.MapTerrainEffect
end
--=================
--获取主题关卡上锁特效
--=================
function XSuperTowerTheme:GetStageLockEffect(IsSp)
    return self.ThemeMapEffectCfg and (IsSp and
        self.ThemeMapEffectCfg.SpStageLockEffect or
        self.ThemeMapEffectCfg.NorStageLockEffect)
end
--=================
--获取主题关卡特效
--=================
function XSuperTowerTheme:GetStageUnLockEffect(IsSp)
    return self.ThemeMapEffectCfg and (IsSp and
        self.ThemeMapEffectCfg.SpStageUnLockEffect or
        self.ThemeMapEffectCfg.NorStageUnLockEffect)
end
--=================
--获取主题关卡当前关卡特效
--=================
function XSuperTowerTheme:GetStageCurrentEffect(IsSp)
    return self.ThemeMapEffectCfg and (IsSp and
        self.ThemeMapEffectCfg.SpStageCurrentEffect or
        self.ThemeMapEffectCfg.NorStageCurrentEffect)
end
--=================
--获取主题关卡选中关卡特效
--=================
function XSuperTowerTheme:GetStageSelectEffect(IsSp)
    return self.ThemeMapEffectCfg and (IsSp and
        self.ThemeMapEffectCfg.SpStageSelectEffect or
        self.ThemeMapEffectCfg.NorStageSelectEffect)
end
--=================
--获取主题开放的时间戳
--=================
function XSuperTowerTheme:GetStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self:GetTimeId())
end
--=================
--获取主题结束的时间戳
--=================
function XSuperTowerTheme:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self:GetTimeId())
end
--=================
--获取主题开放的本地时间日期字符串
--@param isFullDate:是否显示全部时间显示格式。true显示年月日时分秒，false显示月日
--=================
function XSuperTowerTheme:GetStartTimeStr(isFullDate)
    return XTime.TimestampToLocalDateTimeString(self:GetStartTime(), isFullDate and "yyyy-MM-dd HH:mm:ss" or "MM-dd")
end
--=================
--获取主题爬塔现在积分显示
--=================
function XSuperTowerTheme:GetTierScore()
    return self.TierManager and self.TierManager:GetScoreStr() or "0/0"
end
--=================
--获取主题爬塔现在层数进度显示
--=================
function XSuperTowerTheme:GetTierStr()
    return self.TierManager and self.TierManager:GetTierStr() or "0/0"
end
--=================
--获取主题爬塔现在积分
--=================
function XSuperTowerTheme:GetCurrentTierScore()
    return self.TierManager and self.TierManager:GetCurrentScore()
end
--=================
--获取主题爬塔现在层数
--=================
function XSuperTowerTheme:GetCurrentTier()
    return self.TierManager and self.TierManager:GetCurrentTier() or 1
end
--=================
--获取主题爬塔历史最高分
--=================
function XSuperTowerTheme:GetHistoryTierScore()
    return self.TierManager and self.TierManager:GetHistoryHighestScore()
end
--=================
--获取主题爬塔最大层数
--=================
function XSuperTowerTheme:GetMaxTier()
    return self.TierManager and self.TierManager:GetMaxTier() or 1
end
--=================
--获取主题爬塔本周进度纪录字符串
--=================
function XSuperTowerTheme:GetHistoryTierStr()
    return self.TierManager and self.TierManager:GetHistoryTierStr() or "0/0"
end
--=================
--获取主题爬塔本周进度纪录
--=================
function XSuperTowerTheme:GetHistoryHighestTier()
    return self.TierManager and self.TierManager:GetHistoryHighestTier()
end
--=================
--获取主题爬塔可获得的分数上限
--=================
function XSuperTowerTheme:GetTierMaxScore()
    return self.TierManager and self.TierManager:GetMaxScore() or 0
end
--=================
--获取主题爬塔是否刷新层数纪录
--=================
function XSuperTowerTheme:CheckIsNewTierRecord()
    return self.TierManager and self.TierManager:CheckIsNewTierRecord()
end
--=================
--获取主题爬塔是否刷新分数纪录
--=================
function XSuperTowerTheme:CheckIsNewScoreRecord()
    return self.TierManager and self.TierManager:CheckIsNewScoreRecord()
end
--=================
--根据层数获取爬塔关卡对象
--@param tier:层数
--=================
function XSuperTowerTheme:GetTierStageByTier(tier)
    return self.TierManager:GetTierStageByTier(tier)
end
--=================
--获取当前爬塔关卡ID
--=================
function XSuperTowerTheme:GetCurrentTierStageId()
    local tierStage = self:GetTierStageByTier(self:GetCurrentTier() + 1)
    return tierStage:GetStageId()
end
--=================
--根据活动关卡ID获取目标关卡对象
--@param stStageId:活动关卡ID
--=================
function XSuperTowerTheme:GetTargetStageByStStageId(stStageId)
    return self.TargetStageDic[stStageId]
end
--=================
--根据关卡ID获取目标关卡对象
--@param stStageId:关卡ID
--=================
function XSuperTowerTheme:GetTargetStageByStageId(stageId)
    return self.StageId2Stage[stageId]
end
--=================
--获取目标关卡最大子关卡数
--=================
function XSuperTowerTheme:GetMaxStageCount()
    return self.MaxStageCount
end
--=================
--获取目标关卡列表
--=================
function XSuperTowerTheme:GetTargetStageList()
    return self.TargetStageList
end
--=================
--获取主题爬塔收益预览层名称
--=================
function XSuperTowerTheme:GetPluginsPreviewName()
    return self.EnhancerAndPluginsDropCfg and
    self.EnhancerAndPluginsDropCfg.PluginsPreviewName
end
--=================
--获取主题爬塔收益预览插件配置ID
--=================
function XSuperTowerTheme:GetPluginsPreviewId()
    return self.EnhancerAndPluginsDropCfg and
    self.EnhancerAndPluginsDropCfg.PluginsPreviewId
end
--=================
--获取插件掉落预览数据
--=================
function XSuperTowerTheme:GetPluginsDropPreview()
    local previewName = self:GetPluginsPreviewName()
    local previewPluginsPreviewId = self:GetPluginsPreviewId()
    local previewData = {}
    for index, name in pairs(previewName) do
        local newData = {
            Name = name,
            PluginId = previewPluginsPreviewId[index]
        }
        previewData[index] = newData
    end
    return previewData
end
--=================
--检查现在该主题是否正在爬塔
--=================
function XSuperTowerTheme:CheckTierIsPlaying()
    return self.TierManager:CheckIsPlaying()
end
--=================
--检查主题是否目标关卡是否全部Clear
--=================
function XSuperTowerTheme:CheckIsAllClear()
    if self.IsClear then return true end
    for _, stage in pairs(self.TargetStageList) do
        if not stage:CheckIsClear() then
            return false
        end
    end
    self.IsClear = true
    return true
end
--=================
--检查主题是否目标关卡是否全部Clear
--=================
function XSuperTowerTheme:GetStageClearStr()
    local clearCount = 0
    local maxCount = #self.TargetStageList
    for _, stage in pairs(self.TargetStageList) do
        if stage:CheckIsClear() then
            clearCount = clearCount + 1
        end
    end
    return string.format("%d/%d", clearCount, maxCount)
end
--=================
--获取爬塔现在已获得的增益列表
--=================
function XSuperTowerTheme:GetTierEnhanceIds()
    return self.TierManager:GetEnhanceIds() or {}
end
--=================
--获取爬塔现在已获得的插件列表
--=================
function XSuperTowerTheme:GetTierPluginInfos()
    return self.TierManager:GetPluginInfos() or {}
end
--=================
--根据活动关卡ID检查关卡是否在该主题中
--=================
function XSuperTowerTheme:CheckStStageIdIsInTheme(stStageId)
    return self.TargetStageDic[stStageId] ~= nil
end
--=================
--根据关卡ID检查关卡是否在该主题中
--=================
function XSuperTowerTheme:CheckStageIdIsInTheme(stageId)
    return self.StageId2StageType[stageId] ~= nil
end
--=================
--根据关卡ID获取关卡类型
--=================
function XSuperTowerTheme:GetStageTypeByStageId(stageId)
    return self.StageId2StageType[stageId]
end
--=================
--根据关卡ID获取关卡序号
--=================
function XSuperTowerTheme:GetStageIndexByStageId(stageId)
    return self.StageId2Index[stageId]
end
--=================
--根据关卡ID获取目标活动关卡ID
--=================
function XSuperTowerTheme:GetTargetStageIdByStageId(stageId)
    return self.StageId2Stage[stageId]:GetId()
end
--=================
--检查主题是否开放
--=================
function XSuperTowerTheme:CheckIsOpen()
    local startTime = self:GetStartTime()
    local endTime = self:GetEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    return nowTime >= startTime and nowTime < endTime
end
--=================
--获取爬塔是否已经到达顶层
--=================
function XSuperTowerTheme:CheckTierIsFinish()
    return self.TierManager:GetCurrentTier() >= self.TierManager:GetMaxTier()
end

function XSuperTowerTheme:GetTierScoreCountByScoreType(scoreType)
    return self.TierManager:GetTierScoreCountByScoreType(scoreType)
end
--=================
--获取爬塔掉落页面增益掉落用列表
--@param showAll:展示所有增益，否则会根据队伍成员展示掉落
--=================
function XSuperTowerTheme:GetTierEnhanceDropShowList(showAll)
    local resultList = {}
    local dropGroupId = self.EnhancerAndPluginsDropCfg.EnhancerDropGroupId
    local allEnhanceIds = XSuperTowerConfigs.GetEnhanceIdListByGroupId(dropGroupId)
    if allEnhanceIds then
        local characterIdDic = {}
        if not showAll then
            local team = XDataCenter.SuperTowerManager.GetTeamByStageType(XDataCenter.SuperTowerManager.StageType.LllimitedTower)
            for i = 1, 3 do
                local id = team:GetEntityIdByTeamPos(i)
                if id and id > 0 then
                    local role = XDataCenter.SuperTowerManager.GetRoleManager():GetRole(id)
                    characterIdDic[role:GetCharacterId()] = true
                end
            end
        end
        local getDic = {}
        local getEnhanceIds = self:GetTierEnhanceIds()
        for _, enhanceId in pairs(getEnhanceIds) do
            local enhanceCfg = XSuperTowerConfigs.GetEnhanceCfgById(enhanceId)
            local data = {
                EnhanceId = enhanceId,
                IsExist = true,
                Priority = enhanceCfg.Priority
            }
            table.insert(resultList, data)
        end
        for _, id in pairs(getEnhanceIds) do
            getDic[id] = true
        end

        for _, enhanceId in pairs(allEnhanceIds) do
            local enhanceCfg = XSuperTowerConfigs.GetEnhanceCfgById(enhanceId)
            if not getDic[enhanceId] and (showAll or enhanceCfg.CharacterId == 0 or
                (enhanceCfg.CharacterId > 0 and characterIdDic[enhanceCfg.CharacterId])) then
                local data = {
                    EnhanceId = enhanceId,
                    IsExist = false,
                    Priority = enhanceCfg.Priority
                }
                table.insert(resultList, data)
            end
        end
        table.sort(resultList, function(data1, data2)
                if data1.IsExist and not data2.IsExist then
                    return true
                end
                if not data1.IsExist and data2.IsExist then
                    return false
                end
                return data1.Priority < data2.Priority
            end)
    end
    return resultList
end
--=================
--获取爬塔掉落页面插件掉落用列表
--@param showAll:展示所有插件，否则会根据队伍成员展示掉落
--=================
function XSuperTowerTheme:GetTierPluginDropShowList(showAll)
    local resultList = {}
    local dropLevels = self.EnhancerAndPluginsDropCfg.PluginsDropLevel
    local dropGroupIds = self.EnhancerAndPluginsDropCfg.PluginsDropGroupId
    local pluginInfos = self:GetTierPluginInfos()
    local getDic = {}
    for _, pluginInfo in pairs(pluginInfos) do
        getDic[pluginInfo.Id] = true
    end
    for _, pluginInfo in pairs(pluginInfos) do
        for i = 1, pluginInfo.Count do
            local pluginCfg = XSuperTowerConfigs.GetPluginCfgById(pluginInfo.Id)
            local data = {
                PluginId = pluginCfg.Id,
                IsExist = true,
                Level = 1,
                Priority = pluginCfg.Priority
            }
            table.insert(resultList, data)
        end
    end
    local characterIdDic = {}
    if not showAll then
        local team = XDataCenter.SuperTowerManager.GetTeamByStageType(XDataCenter.SuperTowerManager.StageType.LllimitedTower)
        for i = 1, 3 do
            local id = team:GetEntityIdByTeamPos(i)
            if id > 0 then
                local role = XDataCenter.SuperTowerManager.GetRoleManager():GetRole(id)
                characterIdDic[role:GetCharacterId()] = true
            end
        end
    end
    for index, level in pairs(dropLevels) do
        local pluginList = XSuperTowerConfigs.GetPluginIdListByGroupId(dropGroupIds[index])
        if pluginList then
            for _, pluginId in pairs(pluginList) do
                local pluginCfg = XSuperTowerConfigs.GetPluginCfgById(pluginId)
                if not getDic[pluginCfg.Id] and (showAll or pluginCfg.CharacterId == 0 or
                    (pluginCfg.CharacterId > 0 and characterIdDic[pluginCfg.CharacterId])) then
                    local data = {
                        PluginId = pluginId,
                        IsExist = false,
                        Level = level,
                        Priority = pluginCfg.Priority
                    }
                    table.insert(resultList, data)
                end
            end
        end
    end
    table.sort(resultList, function(data1, data2)
            if data1.IsExist and not data2.IsExist then
                return true
            end
            if not data1.IsExist and data2.IsExist then
                return false
            end
            if not data1.IsExist and data1.Level ~= data2.Level then
                return data1.Level < data2.Level
            end
            return data1.Priority < data2.Priority
        end)
    return resultList
end

return XSuperTowerTheme