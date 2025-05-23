-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local TableKey = 
{
    MainLine2Main = { CacheType = XConfigUtil.CacheType.Normal },
    MainLine2Chapter = { CacheType = XConfigUtil.CacheType.Normal, Identifier = "ChapterId" },
    MainLine2StageGroup = { CacheType = XConfigUtil.CacheType.Normal },
    MainLine2Stage = { CacheType = XConfigUtil.CacheType.Normal },
    MainLine2Treasure = { CacheType = XConfigUtil.CacheType.Normal },
    MainLine2Achievement = { CacheType = XConfigUtil.CacheType.Normal },
    MainLine2ClientConfig = { CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.String, DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key" },
}

---@class XMainLine2Model : XModel
local XMainLine2Model = XClass(XModel, "XMainLine2Model")
function XMainLine2Model:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    -- 服务器数据

    -- config相关
    self._ConfigUtil:InitConfigByTableKey("Fuben/MainLine2", TableKey)
end

function XMainLine2Model:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XMainLine2Model:ResetAll()
    -- 重登数据清理
    self.MainDataDic = nil
    self.ChapterDataDic = nil
    self.LastPassStage = nil
    self.FirstPassTime = nil

    if self.MainDic then
        for _, main in pairs(self.MainDic) do
            main:Release()
        end
    end
    self.MainDic = nil
    self.ChapterMainIdDic = nil
    self.StageChapterIdDic = nil
    self.StageGroupIdDic = nil
    self.CacheMainReleaseDataDic = nil
end

--#region 服务端数据 -------------------------------------------------------------------------------------------------
-- 登陆收到主线2数据
function XMainLine2Model:OnLoginNotify(fubenMainLine2Data)
    self.MainDataDic = {}
    self.ChapterDataDic = {}
    self.LastPassStage = fubenMainLine2Data.LastPassStage or {}
    self.FirstPassTime = fubenMainLine2Data.FirstPassTime or {}
    if fubenMainLine2Data.MainDatas then
        for _, mainData in ipairs(fubenMainLine2Data.MainDatas) do
            self.MainDataDic[mainData.Id] = mainData
        end
    end
    if fubenMainLine2Data.ChapterDatas then
        for _, chapterData in ipairs(fubenMainLine2Data.ChapterDatas) do
            self.ChapterDataDic[chapterData.Id] = chapterData
        end
    end
end

-- 收到主章节成就
function XMainLine2Model:OnReceiveAchievement(mainId)
    if self.MainDataDic[mainId] then
        self.MainDataDic[mainId].IsAchievementGet = true
    else
        self.MainDataDic[mainId] = { Id = mainId, IsAchievementGet = true, MainTreasureIdxs = {} }
    end 
end

-- 收到章节通关进度奖励
function XMainLine2Model:OnReceiveTreasure(chapterId, rewardIdxs)
    local chapterData = self.ChapterDataDic[chapterId]
    if not chapterData then
        chapterData = { Id = chapterId, TreasureIdxs = {} }
        self.ChapterDataDic[chapterId] = chapterData
    end

    for _, idx in ipairs(rewardIdxs) do
        table.insert(chapterData.TreasureIdxs, idx)
    end
end

-- 收到主章节通关进度奖励
function XMainLine2Model:OnReceiveMainTreasure(mainId, rewardIdxs)
    local mainData = self.MainDataDic[mainId]
    if not mainData then
        mainData = { Id = mainId, IsAchievementGet = false, MainTreasureIdxs = {} }
        self.MainDataDic[mainId] = mainData
    end

    if not mainData.MainTreasureIdxs then
        mainData.MainTreasureIdxs = {}
    end
    for _, idx in ipairs(rewardIdxs) do
        table.insert(mainData.MainTreasureIdxs, idx)
    end
end

-- 获取主章节成就是否已领取
function XMainLine2Model:IsAchievementGet(mainId)
    local mainData = self.MainDataDic[mainId]
    return mainData and mainData.IsAchievementGet or false
end

-- 获取章节通关进度奖励是否已领取，服务器记录的下标从0开始
function XMainLine2Model:IsTreasureGet(chapterId, index)
    local chapterData = self.ChapterDataDic[chapterId]
    if chapterData and chapterData.TreasureIdxs then
        for _, idx in ipairs(chapterData.TreasureIdxs) do
            if idx == index then
                return true
            end
        end
    else
        return false
    end
end

-- 获取主章节通关进度奖励是否已领取，服务器记录的下标从0开始
function XMainLine2Model:IsMainTreasureGet(mainId, index)
    local mainData = self.MainDataDic[mainId]
    if mainData and mainData.MainTreasureIdxs then
        for _, idx in ipairs(mainData.MainTreasureIdxs) do
            if idx == index then
                return true
            end
        end
    else
        return false
    end
end

--#endregion ---------------------------------------------------------------------------------------------------------


--#region 配置表 --------------------------------------------------------------------------------------------------

-- 主章节是否存在
function XMainLine2Model:IsMainExit(mainId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.MainLine2Main)
    return cfgs[mainId] ~= nil
end

-- 获取章节配置表列表，通过故事类型和组Id
function XMainLine2Model:GetMainCfgsByStoryTypeGroupId(storyType, groupId)
    local cfgs = self:GetConfigMain()
    local result = {}
    for _, cfg in pairs(cfgs) do
        if cfg.StoryType == storyType and cfg.GroupId == groupId then
            table.insert(result, cfg)
        end
    end
    return result
end

function XMainLine2Model:GetConfigMain(mainId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.MainLine2Main)
    if mainId then
        if cfgs[mainId] then
            return cfgs[mainId]
        else
            XLog.Error("请检查配置表Share/Fuben/MainLine2/MainLine2Main.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XMainLine2Model:GetMainTitle(mainId)
    local config = self:GetConfigMain(mainId)
    return config and config.Title or ""
end

function XMainLine2Model:GetMainChapterIds(mainId)
    local config = self:GetConfigMain(mainId)
    return config and config.ChapterIds or {}
end

function XMainLine2Model:GetMainAchievementId(mainId)
    local config = self:GetConfigMain(mainId)
    return config and config.AchievementId or 0
end

function XMainLine2Model:GetMainRedTimeId(mainId)
    local config = self:GetConfigMain(mainId)
    return config and config.RedTimeId or 0
end

function XMainLine2Model:GetMainSpecialCondition(mainId)
    local config = self:GetConfigMain(mainId)
    return config and config.SpecialCondition or 0
end

function XMainLine2Model:GetMainSpecialTagName(mainId)
    local config = self:GetConfigMain(mainId)
    return config and config.SpecialTagName or ""
end

function XMainLine2Model:GetSpecialEffect(mainId)
    local config = self:GetConfigMain(mainId)
    return config and config.SpecailEffect or ""
end

function XMainLine2Model:GetMainHideChapterOption(mainId)
    local config = self:GetConfigMain(mainId)
    return config and config.HideChapterOption == 1 or false
end

function XMainLine2Model:GetMainTreasureId(mainId)
    local config = self:GetConfigMain(mainId)
    return config and config.TreasureId or 0
end

-- 获取主章节结算背景图
function XMainLine2Model:GetMainSettlementBg(mainId)
    local config = self:GetConfigMain(mainId)
    return config and config.SettlementBg or ""
end

-- 章节是否存在
function XMainLine2Model:IsChapterExit(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.MainLine2Chapter)
    return cfgs[id] ~= nil
end

function XMainLine2Model:GetConfigChapter(chapterId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.MainLine2Chapter)
    if chapterId then
        if cfgs[chapterId] then
            return cfgs[chapterId]
        else
            XLog.Error("请检查配置表Share/Fuben/MainLine2/MainLine2Chapter.tab，未配置行ChapterId = " .. tostring(chapterId))
        end
    else
        return cfgs
    end
end

function XMainLine2Model:GetChapterDifficult(chapterId)
    local config = self:GetConfigChapter(chapterId)
    return config and config.Difficult or 0
end

function XMainLine2Model:GetChapterDifficultName(chapterId)
    local config = self:GetConfigChapter(chapterId)
    return config and config.DifficultName or ""
end

function XMainLine2Model:GetChapterDifficultEnName(chapterId)
    local config = self:GetConfigChapter(chapterId)
    return config and config.DifficultEnName or ""
end

-- 获取章节难度颜色
function XMainLine2Model:GetChapterDifficultColor(chapterId)
    local config = self:GetConfigChapter(chapterId)
    return config and config.DifficultColor or ""
end

function XMainLine2Model:GetChapterDesc(chapterId)
    local config = self:GetConfigChapter(chapterId)
    return config and config.Desc or ""
end

function XMainLine2Model:GetChapterActivityTimeId(chapterId)
    local config = self:GetConfigChapter(chapterId)
    return config and config.ActivityTimeId or 0
end

function XMainLine2Model:GetChapterStoryType(chapterId)
    local config = self:GetConfigChapter(chapterId)
    return config and config.StoryType or 0
end

function XMainLine2Model:GetChapterStoryId(chapterId)
    local config = self:GetConfigChapter(chapterId)
    return config and config.StoryId or 0
end

function XMainLine2Model:GetChapterStageGroupIds(chapterId)
    local config = self:GetConfigChapter(chapterId)
    return config and config.StageGroupIds or {}
end

function XMainLine2Model:GetChapterPrefabName(chapterId)
    local config = self:GetConfigChapter(chapterId)
    return config and config.PrefabName or nil
end

function XMainLine2Model:GetChapterBgStageIndexs(chapterId)
    local config = self:GetConfigChapter(chapterId)
    return config and config.BgStageIndexs or {}
end

function XMainLine2Model:GetChapterTreasureId(chapterId)
    local config = self:GetConfigChapter(chapterId)
    return config and config.TreasureId or 0
end

function XMainLine2Model:GetChapterLastStageId(chapterId)
    local stageGroupId = self:GetChapterStageGroupIds(chapterId)
    local lastGroupId = stageGroupId[#stageGroupId]
    local stageIds = self:GetGroupStageIds(lastGroupId)
    local lastStageId = stageIds[#stageIds]
    return lastStageId
end

function XMainLine2Model:GetConfigStageGroup(groupId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.MainLine2StageGroup)
    if groupId then
        if cfgs[groupId] then
            return cfgs[groupId]
        else
            XLog.Error("请检查配置表Share/Fuben/MainLine2/MainLine2StageGroup.tab，未配置行Id = " .. tostring(groupId))
        end
    else
        return cfgs
    end
end

function XMainLine2Model:GetGroupStageIds(groupId)
    local config = self:GetConfigStageGroup(groupId)
    return config and config.StageIds or {}
end

-- 关卡是否存在
function XMainLine2Model:IsStageExit(stageId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.MainLine2Stage)
    return cfgs[stageId] ~= nil
end

function XMainLine2Model:GetConfigStage(stageId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.MainLine2Stage)
    if stageId then
        if cfgs[stageId] then
            return cfgs[stageId]
        else
            XLog.Error("请检查配置表Share/Fuben/MainLine2/MainLine2Stage.tab，未配置行Id = " .. tostring(stageId))
        end
    else
        return cfgs
    end
end

function XMainLine2Model:GetStageDetailType(stageId)
    local config = self:GetConfigStage(stageId)
    return config and config.StageDetailType or 0
end

function XMainLine2Model:GetStageVideoId(stageId)
    local config = self:GetConfigStage(stageId)
    return config and config.VideoId or 0
end

function XMainLine2Model:GetStageSpecialorder(stageId)
    local config = self:GetConfigStage(stageId)
    return config and config.Specialorder or nil
end

function XMainLine2Model:GetStageMonsterHeads(stageId)
    local config = self:GetConfigStage(stageId)
    return config and config.MonsterHeads or {}
end

function XMainLine2Model:GetStageMonsterReplaceOrders(stageId)
    local config = self:GetConfigStage(stageId)
    return config and config.MonsterReplaceOrders or {}
end

function XMainLine2Model:GetStageProgressConditions(stageId)
    local config = self:GetConfigStage(stageId)
    return config and config.ProgressConditions or {}
end

-- 关卡是否忽略新章节标签、完成进度的计算
function XMainLine2Model:IsStageIgnore(stageId)
    local config = self:GetConfigStage(stageId)
    return config and config.Ignore or false
end

--- 获取关卡成就名称
function XMainLine2Model:GetStageAchievementName(stageId, index)
    local config = self:GetConfigStage(stageId)
    return config.AchievementNames[index]
end

-- 获取关卡成就描述
function XMainLine2Model:GetStageAchievementBriefDesc(stageId, index)
    local config = self:GetConfigStage(stageId)
    return config.AchievementBriefDescs[index]
end

function XMainLine2Model:GetConfigTreasure(treasureId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.MainLine2Treasure)
    if treasureId then
        if cfgs[treasureId] then
            return cfgs[treasureId]
        else
            XLog.Error("请检查配置表Share/Fuben/MainLine2/MainLine2Treasure.tab，未配置行Id = " .. tostring(treasureId))
        end
    else
        return cfgs
    end
end

function XMainLine2Model:GetConfigAchievement(achievementId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.MainLine2Achievement)
    if achievementId then
        if cfgs[achievementId] then
            return cfgs[achievementId]
        else
            XLog.Error("请检查配置表Share/Fuben/MainLine2/MainLine2Achievement.tab，未配置行Id = " .. tostring(achievementId))
        end
    else
        return cfgs
    end
end

function XMainLine2Model:GetAchievementCount(achievementId)
    local config = self:GetConfigAchievement(achievementId)
    return config and config.Count or 0
end

function XMainLine2Model:GetAchievementClearRewardId(achievementId)
    local config = self:GetConfigAchievement(achievementId)
    return config and config.ClearRewardId or 0
end

function XMainLine2Model:GetAchievementIcon(achievementId)
    local config = self:GetConfigAchievement(achievementId)
    return config and config.Icon or ""
end

function XMainLine2Model:GetAchievementIconLock(achievementId)
    local config = self:GetConfigAchievement(achievementId)
    return config and config.IconLock or ""
end

function XMainLine2Model:GetAchievementChapterIcon(achievementId)
    local config = self:GetConfigAchievement(achievementId)
    return config and config.ChapterIcon or nil
end

function XMainLine2Model:GetAchievementChapterIconLock(achievementId)
    local config = self:GetConfigAchievement(achievementId)
    return config and config.ChapterIconLock or nil
end

function XMainLine2Model:GetClientConfigParams(key, index)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MainLine2ClientConfig, key)
    if not config then
        XLog.Error("请检查配置表Client/Fuben/MainLine2/MainLine2ClientConfig.tab，未配置行Key = " .. tostring(key))
        return nil
    end

    if index then
        return config.Params[index]
    else
        return config.Params
    end
end

--#endregion 配置表 -----------------------------------------------------------------------------------------------

--- 获取主章节实例
function XMainLine2Model:GetMain(mainId)
    if not self:IsMainExit(mainId) then
        return
    end

    if self.MainDic == nil then self.MainDic = {} end
    if self.MainDic[mainId] then
        return self.MainDic[mainId]
    end

    local config = self:GetConfigMain(mainId)
    local XMainLine2Main = require("XModule/XMainLine2/XEntity/XMainLine2Main")
    self.MainDic[mainId] = XMainLine2Main.New(config)
    return self.MainDic[mainId]
end

--- 获取所有主章节实例
function XMainLine2Model:GetAllMains()
    local mains = {}
    local mainCfgs = self:GetConfigMain()
    for _, mainCfg in pairs(mainCfgs) do
        local main = self:GetMain(mainCfg.Id)
        table.insert(mains, main)
    end
    return mains
end

--- 主章节是否全通关
---@param mainId number 主章节Id
function XMainLine2Model:IsMainPassed(mainId)
    local chapterIds = self:GetMainChapterIds(mainId)
    for _, chapterId in ipairs(chapterIds) do
        if not self:IsChapterPassed(chapterId) then
            return false
        end
    end
    return true
end

--- 主章节是否解锁
---@param mainId number 主章节Id
function XMainLine2Model:IsMainUnlock(mainId)
    local firstTips
    local mainCfg = self:GetConfigMain(mainId)
    for _, chapterId in ipairs(mainCfg.ChapterIds) do
        local isUnlock, tips = self:IsChapterUnlock(chapterId)
        if isUnlock then
            return true
        else
            firstTips = firstTips or tips
        end
    end

    return false, firstTips
end

--- 主章节奖励是否领取完成
---@param mainId number 主章节Id
function XMainLine2Model:IsMainTreasureFinish(mainId)
    local treasureId = self:GetMainTreasureId(mainId)
    if treasureId ~= 0 then
        local treasureCfg = self:GetConfigTreasure(treasureId)
        for i, _ in ipairs(treasureCfg.StageCounts) do
            local isGet = self:IsMainTreasureGet(mainId, i-1)
            if not isGet then
                return false
            end
        end
    end

    return true
end

--- 获取主章节进度
---@param mainId number 主章节Id
function XMainLine2Model:GetMainProgress(mainId)
    local allPassCnt = 0
    local allMaxCnt = 0
    local chapterIds = self:GetMainChapterIds(mainId)
    for _, chapterId in ipairs(chapterIds) do
        local passCnt, maxCnt = self:GetChapterProgress(chapterId)
        allPassCnt = allPassCnt + passCnt
        allMaxCnt = allMaxCnt + maxCnt
    end
    return allPassCnt, allMaxCnt
end

--- 章节是否通关
---@param chapterId number 章节Id
function XMainLine2Model:IsChapterPassed(chapterId)
    local chapterCfg = self:GetConfigChapter(chapterId)
    for _, groupId in ipairs(chapterCfg.StageGroupIds) do
        local groupCfg = self:GetConfigStageGroup(groupId)
        for _, stageId in ipairs(groupCfg.StageIds) do
            local isIgnore = self:IsStageIgnore(stageId)
            if not isIgnore and not self:IsStagePass(stageId) then
                return false
            end
        end
    end
    return true
end

--- 章节是否解锁
---@param chapterId number 章节Id
function XMainLine2Model:IsChapterUnlock(chapterId)
    local chapterCfg = self:GetConfigChapter(chapterId)
    local conditionId = chapterCfg.OpenCondition

    -- 限时开启时，以限时配置的ConditionId为准
    if XFunctionManager.CheckInTimeByTimeId(chapterCfg.ActivityTimeId) then
        conditionId = chapterCfg.ActivityCondition
    end

    if conditionId ~= 0 then
        local isUnlock, tips = XConditionManager.CheckCondition(conditionId)
        return isUnlock, tips
    end
    return true, ""
end

--- 章节奖励是否领取完成
---@param chapterId number 章节Id
function XMainLine2Model:IsChapterTreasureFinish(chapterId)
    local treasureId = self:GetChapterTreasureId(chapterId)
    if treasureId ~= 0 then
        local treasureCfg = self:GetConfigTreasure(treasureId)
        for i, stageCount in ipairs(treasureCfg.StageCounts) do
            local isGet = self:IsTreasureGet(chapterId, i-1)
            if not isGet then
                return false
            end
        end
    end

    return true
end

--- 章节是否显示蓝点
---@param chapterId number 章节Id
function XMainLine2Model:IsChapterRed(chapterId)
    local treasureId = self:GetChapterTreasureId(chapterId)
    if treasureId ~= 0 then
        local treasureCfg = self:GetConfigTreasure(treasureId)
        local passCnt, maxCnt = self:GetChapterProgress(chapterId)
        for i, stageCount in ipairs(treasureCfg.StageCounts) do
            local isGet = self:IsTreasureGet(chapterId, i-1)
            local isReach = passCnt >= stageCount
            if not isGet and isReach then
                return true
            end
        end
    end

    return false
end

--- 获取章节通关进度
---@param chapterId number 章节Id
function XMainLine2Model:GetChapterProgress(chapterId)
    local passCnt = 0
    local maxCnt = 0
    local chapterCfg = self:GetConfigChapter(chapterId)
    for _, groupId in ipairs(chapterCfg.StageGroupIds) do
        local groupCfg = self:GetConfigStageGroup(groupId)
        for _, stageId in ipairs(groupCfg.StageIds) do
            local isIgnore = self:IsStageIgnore(stageId)
            if not isIgnore then
                maxCnt = maxCnt + 1
                if self:IsStagePass(stageId) then
                    passCnt = passCnt + 1
                end
            end
        end
    end
    return passCnt, maxCnt
end

--- 获取章节Id
---@param mainId number 主章节Id
---@param difficultyId number 难度Id
function XMainLine2Model:GetChapterId(mainId, difficultyId)
    local mainCfg = self:GetConfigMain(mainId)
    for _, chapterId in ipairs(mainCfg.ChapterIds) do
        local chapterCfg = self:GetConfigChapter(chapterId)
        if chapterCfg.Difficult == difficultyId then
            return chapterId
        end
    end
    return
end

--- 缓存章节Id对应的主章节Id
---@param chapterId number 章节Id
---@param mainId number 主章节Id
function XMainLine2Model:CacheChapterMainId(chapterId, mainId)
    self.ChapterMainIdDic = self.ChapterMainIdDic or {}
    self.ChapterMainIdDic[chapterId] = mainId
end

--- 获取章节对应的主章节Id
---@param chapterId number 章节Id
function XMainLine2Model:GetChapterMainId(chapterId, ignoreError)
    local mainId = self.ChapterMainIdDic and self.ChapterMainIdDic[chapterId]
    if mainId then
        return mainId
    end

    local mainCfgs = self:GetConfigMain()
    for _, mainCfg in pairs(mainCfgs) do
        for _, cId in ipairs(mainCfg.ChapterIds) do
            if cId == chapterId then
                self:CacheChapterMainId(chapterId, mainCfg.Id)
                if not ignoreError then
                    XLog.Warning("XMainLine2Model:GetChapterMainId 请提前缓存好ChapterId对应的MainId。若为战斗回放可不用管。")
                end
                return mainCfg.Id
            end
        end
    end
end

--- 获取章节最后打的关卡Id
function XMainLine2Model:GetLastPassStage(chapterId)
    return self.LastPassStage[chapterId] or 0
end

--- 记录章节最后打的关卡Id
function XMainLine2Model:SetLastPassStage(stageId)
    local chapterId = self:GetStageChapterId(stageId)
    self.LastPassStage[chapterId] = stageId
end

--- 获取关卡首通时间
function XMainLine2Model:GetFirstPassTime(stageId)
    return self.FirstPassTime[stageId]
end

--- 记录关卡首通时间
function XMainLine2Model:SetFirstPassTime(stageId)
    if not self.FirstPassTime[stageId] then
        self.FirstPassTime[stageId] = XTime.GetServerNowTimestamp()
    end
end

--- 获取章节打的下一关入口
---@param chapterId number 章节Id
---@return uiIndex int 对应UI预制体下标
---@return orderId int 关卡Stage表的OrderId
function XMainLine2Model:GetChapterNextEntrance(chapterId)
    local groupIds = self:GetChapterStageGroupIds(chapterId)
    local uiIndex = 0
    local lastStageId = 0
    for _, groupId in ipairs(groupIds) do
        local groupCfg = self:GetConfigStageGroup(groupId)
        if groupCfg.GroupType == XEnumConst.MAINLINE2.GROUP_TYPE.INDEPENDENT_ENTRANCE then
            for _, stageId in ipairs(groupCfg.StageIds) do
                uiIndex = uiIndex + 1
                lastStageId = stageId
                if self:IsPreStagePass(stageId) and not self:IsStagePass(stageId) then
                    local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(stageId)
                    return uiIndex, stageCfg.OrderId
                end
            end
        else
            uiIndex = uiIndex + 1
            lastStageId = groupCfg.StageIds[1]
            for _, stageId in ipairs(groupCfg.StageIds) do
                if self:IsPreStagePass(stageId) and not self:IsStageIgnore(stageId) and not self:IsStagePass(stageId) then
                    local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(stageId)
                    return uiIndex, stageCfg.OrderId
                end
            end
        end
    end

    local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(lastStageId)
    return uiIndex, stageCfg.OrderId
end

--- 缓存关卡Id对应的章节Id
---@param stageId number 关卡Id
---@param chapterId number 章节Id
function XMainLine2Model:CacheStageChapterId(stageId, chapterId)
    self.StageChapterIdDic = self.StageChapterIdDic or {}
    self.StageChapterIdDic[stageId] = chapterId
end

--- 获取关卡的章节Id，战斗时需要通过stageId获取章节成就信息
---@param stageId number 关卡Id
function XMainLine2Model:GetStageChapterId(stageId)
    -- 读取缓存
    local chapterId = self.StageChapterIdDic and self.StageChapterIdDic[stageId]
    if chapterId then
        return chapterId
    end

    -- 未触发缓存，遍历查找
    -- 请在使用前添加缓存，避免3个for循环进行遍历取值
    local chapterCfgs = self:GetConfigChapter()
    for _, chapterCfg in pairs(chapterCfgs) do
        for _, groupId in ipairs(chapterCfg.StageGroupIds) do
            local groupCfg = self:GetConfigStageGroup(groupId)
            for _, sId in ipairs(groupCfg.StageIds) do
                if sId == stageId then
                    self:CacheStageChapterId(stageId, chapterCfg.ChapterId)
                    XLog.Warning("XMainLine2Model:GetStageChapterId 请提前缓存好stageId对应的ChapterId。若为战斗回放可不用管。")
                    return chapterCfg.ChapterId
                end
            end
        end
    end
end

--- 缓存关卡Id所在的组Id
---@param stageId number 关卡Id
---@param groupId number 关卡组Id
function XMainLine2Model:CacheStageGroupId(stageId, groupId)
    self.StageGroupIdDic = self.StageGroupIdDic or {}
    self.StageGroupIdDic[stageId] = groupId
end

--- 获取关卡Id所在的组Id
---@param stageId number 关卡Id
function XMainLine2Model:GetStageGroupId(stageId)
    return self.StageGroupIdDic and self.StageGroupIdDic[stageId] or 0
end

--- 获取关卡所在的关卡列表
---@param stageId number 关卡Id
---@return number[] 关卡Id列表
function XMainLine2Model:GetStageStageIds(stageId)
    local groupId = self:GetStageGroupId(stageId)
    if not groupId or groupId == 0 then
        XLog.Warning("XMainLine2Model:GetStageStageIds 请提前缓存好stageId对应的groupId。若为战斗回放可不用管。")
        return {stageId}
    end
    
    local groupCfg = self:GetConfigStageGroup(groupId)
    if groupCfg.GroupType == XEnumConst.MAINLINE2.GROUP_TYPE.INDEPENDENT_ENTRANCE then
        return { stageId }
    else
        return groupCfg.StageIds
    end
end

--- 获取关卡Id所在的组Id
---@param stageId number 关卡Id
function XMainLine2Model:GetStageAchievementIsCombine(stageId)
    local groupId = self:GetStageGroupId(stageId)
    if not groupId or groupId == 0 then
        XLog.Warning("XMainLine2Model:GetStageAchievementIsCombine 请提前缓存好stageId对应的groupId。若为战斗回放可不用管。")
        return false
    end

    local groupCfg = self:GetConfigStageGroup(groupId)
    return groupCfg.AchievementIsCombine == 1
end

--- 前置关卡是否通过
---@param stageId number 关卡Id
function XMainLine2Model:IsPreStagePass(stageId)
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    local config = fubenAgency:GetStageCfg(stageId)
    for _, sId in ipairs(config.PreStageId) do
        local isPass = fubenAgency:CheckStageIsPass(sId)
        if not isPass then
            return false
        end
    end

    return true
end

--- 关卡是否解锁
---@param stageId number 关卡Id
function XMainLine2Model:IsStageUnlock(stageId)
    local stageCfg = self:GetConfigStage(stageId)
    if stageCfg.UnlockCondition ~= 0 then
        local isUnlock, desc = XConditionManager.CheckCondition(stageCfg.UnlockCondition)
        return isUnlock, desc
    end

    return true
end

--- 关卡是否显示
---@param stageId number 关卡Id
function XMainLine2Model:IsStageShow(stageId)
    local stageInfo = XMVCA.XFuben:GetStageInfo(stageId)
    return stageInfo.Unlock
end

--- 获取关卡是否通关
---@param stageId number 关卡Id
function XMainLine2Model:IsStagePass(stageId)
    local conditions = self:GetStageProgressConditions(stageId)
    if #conditions > 0 then
        for _, condition in ipairs(conditions) do
            local isReach, desc = XConditionManager.CheckCondition(condition)
            if not isReach then
                return false, desc
            end
        end
        return true
    end

    local isPass = XMVCA:GetAgency(ModuleId.XFuben):CheckStageIsPass(stageId)
    return isPass
end

--- 获取关卡成就完成情况
---@param stageId number 关卡Id
function XMainLine2Model:GetStageAchievementMap(stageId)
    local stageData = XMVCA:GetAgency(ModuleId.XFuben):GetStageData(stageId)
    if not stageData or not stageData.Achievement or stageData.Achievement == 0 then
        return 0, nil
    end

    local stageCfg = self:GetConfigStage(stageId)
    return self:GetAchievementMap(stageData.Achievement, stageCfg.AchievementTpyes, stageId)
end

--- 获取成就完成情况
---@param achievement number 已完成成就 位字段
---@param achievementTpyes number[] 成就类型数组
function XMainLine2Model:GetAchievementMap(achievement, achievementTpyes, stageId)
    local n = achievement
    local map = {}
    local count = 0
    while(n > 0) do
        local isAchieve = n % 2 == 1
        n = math.floor(n / 2)
        table.insert(map, isAchieve)
        
        -- 隐藏成就不计入完成数量里
        local index = #map
        if isAchieve and (achievementTpyes[index] == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.NORMAL or achievementTpyes[index] == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.SPECIAL) then
            count = count + 1
        end
        if isAchieve and not achievementTpyes[index] then
            XLog.Error(string.format("关卡%s服务器下发achievement = %s, 但是配置表只配置了%s个成就", tostring(stageId), tostring(achievement), tostring(#achievementTpyes)))
        end
    end

    return count, map
end

--- 获取关卡列表的成就信息
-----@param stageId number 关卡Id
-----@param isFighting boolean 是否在战斗中
-----@param isCombineStageGroup boolean 是否合并同个关卡组的成就
function XMainLine2Model:GetStagesAchievementInfos(stageId, isFighting, isCombineStageGroup)
    if isCombineStageGroup == nil then
        isCombineStageGroup = self:GetStageAchievementIsCombine(stageId)
    end
    local stageIds = isCombineStageGroup and self:GetStageStageIds(stageId) or { stageId }

    -- 当前战斗关卡已完成的成就
    local _, curAchieveMap
    if isFighting then
        local curStageId = CS.XFight.Instance.FightData.StageId
        local curAchievement = CS.XFight.Instance.Result.Data.Achievement
        if curStageId == stageId then
            local curStageCfg = self:GetConfigStage(curStageId)
            _, curAchieveMap = self:GetAchievementMap(curAchievement, curStageCfg.AchievementTpyes, stageId)
        end
    end

    -- 获取同个入口所有关卡的成就
    local defaultUndoneDesc = self:GetClientConfigParams("StageAchievementUnlockDesc", 1)
    local achieveInfos = {}
    local index = 1
    for _, sId in ipairs(stageIds) do
        local stageCfg = self:GetConfigStage(sId)
        local achieveCnt = #stageCfg.AchievementTpyes
        if achieveCnt > 0 then
            local count, achieveMap = self:GetStageAchievementMap(sId)
            for i = 1, achieveCnt do
                local name = stageCfg.AchievementNames[i]
                local desc = stageCfg.AchievementDescs[i] or ""
                local type = stageCfg.AchievementTpyes[i] -- ACHIEVEMENT_TYPE
                local briefDesc = stageCfg.AchievementBriefDescs[i] or ""
                local undoneDesc = stageCfg.AchievementUndoneDescs[i] or ""
                local isSpecial = type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.SPECIAL

                local fullDesc = desc .. briefDesc
                if string.IsNilOrEmpty(undoneDesc) then 
                    undoneDesc = isSpecial and defaultUndoneDesc or fullDesc
                end
                local isUnLock = achieveMap and achieveMap[i] == true -- 是否已解锁
                local isFightUnLock = sId == stageId and curAchieveMap and curAchieveMap[i] == true -- 是否本场战斗解锁
                local info = { Index = index, Name = name, Desc = desc, BriefDesc = briefDesc, UndoneDesc = undoneDesc, FullDesc = fullDesc,
                    Type = type, IsUnLock = isUnLock, IsFightUnLock = isFightUnLock }
                table.insert(achieveInfos, info)
                index = index + 1
            end
        end
    end

    -- 成就排序
    if #achieveInfos > 1 then
        table.sort(achieveInfos, function(a, b) 
            if a.Type ~= b.Type then
                return a.Type < b.Type
            end
            return a.Index < b.Index
        end)
    end

    return achieveInfos
end

--- 设置播放过第一次进入特效
function XMainLine2Model:SetIsPlayFirstEnterEffect(mainId)
    local saveKey = self:GetFirstEnterEffectKey(mainId)
    XSaveTool.SaveData(saveKey, true)
end

--- 是否播放过第一次进入特效
function XMainLine2Model:GetIsPlayFirstEnterEffect(mainId)
    local saveKey = self:GetFirstEnterEffectKey(mainId)
    return XSaveTool.GetData(saveKey) == true
end

function XMainLine2Model:GetFirstEnterEffectKey(mainId)
    return string.format("XMainLine2Model:GetMainFirstEnterEffectKey_PlayerId:%s_MainId:%s", XPlayer.Id, mainId)
end

--- 设置播放过章节切换特效
---@param chapterId number 主章节Id
function XMainLine2Model:SetIsPlaySwitchEnterEffect(chapterId)
    local saveKey = self:GetSwitchEnterEffectKey(chapterId)
    XSaveTool.SaveData(saveKey, true)
end

--- 是否播放过章节切换特效
---@param chapterId number 主章节Id
function XMainLine2Model:GetIsPlaySwitchEnterEffect(chapterId)
    local saveKey = self:GetSwitchEnterEffectKey(chapterId)
    return XSaveTool.GetData(saveKey) == true
end

function XMainLine2Model:GetSwitchEnterEffectKey(chapterId)
    return string.format("XMainLine2Model:GetSwitchEnterEffectKey_PlayerId:%s_ChapterId:%s", XPlayer.Id, chapterId)
end

-- 缓存主章节释放的数据
function XMainLine2Model:CacheMainReleaseData(mainId, data)
    self.CacheMainReleaseDataDic = self.CacheMainReleaseDataDic or {}
    self.CacheMainReleaseDataDic[mainId] = data
end

-- 获取主章节上次释放时的数据
function XMainLine2Model:GetMainReleaseData(mainId)
    return self.CacheMainReleaseDataDic and self.CacheMainReleaseDataDic[mainId] or nil
end

return XMainLine2Model
