---@class XMainLine2Control : XControl
---@field _Model XMainLine2Model
local XMainLine2Control = XClass(XControl, "XMainLine2Control")
function XMainLine2Control:OnInit()
    --初始化内部变量
end

function XMainLine2Control:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XMainLine2Control:RemoveAgencyEvent()

end

function XMainLine2Control:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

--#region 服务端数据 -------------------------------------------------------------------------------------------------
-- 获取主章节是否已领取成就
function XMainLine2Control:IsAchievementGet(mainId)
    return self._Model:IsAchievementGet(mainId)
end

-- 获取章节奖励是否已领取，服务器记录的下标从0开始
function XMainLine2Control:IsTreasureGet(chapterId, index)
    return self._Model:IsTreasureGet(chapterId, index)
end

--#endregion ---------------------------------------------------------------------------------------------------------

--#region 配置表 --------------------------------------------------------------------------------------------------
-- 获取主章节配置表
function XMainLine2Control:GetConfigMain(mainId)
    return self._Model:GetConfigMain(mainId)
end

-- 获取主章节的成就
function XMainLine2Control:GetMainAchievementId(mainId)
    return self._Model:GetMainAchievementId(mainId)
end

-- 获取章节配置表
function XMainLine2Control:GetConfigChapter(chapterId)
    return self._Model:GetConfigChapter(chapterId)
end

-- 获取章节难度
function XMainLine2Control:GetChapterDifficult(chapterId)
    return self._Model:GetChapterDifficult(chapterId)
end

-- 获取章节限时开放TimerId
function XMainLine2Control:GetChapterActivityTimeId(chapterId)
    return self._Model:GetChapterActivityTimeId(chapterId)
end

-- 获取章节预置名称
function XMainLine2Control:GetChapterPrefabName(chapterId)
    return self._Model:GetChapterPrefabName(chapterId)
end

-- 获取章节背景图对应关卡下标列表
function XMainLine2Control:GetChapterBgStageIndexs(chapterId)
    return self._Model:GetChapterBgStageIndexs(chapterId)
end

-- 获取主章节标题
function XMainLine2Control:GetMainTitle(chapterId)
    return self._Model:GetMainTitle(chapterId)
end

-- 获取关卡分组表
function XMainLine2Control:GetConfigStageGroup(partId)
    return self._Model:GetConfigStageGroup(partId)
end

-- 获取关卡表
function XMainLine2Control:GetConfigStage(stageId)
    return self._Model:GetConfigStage(stageId)
end

-- 获取关卡细分类型
function XMainLine2Control:GetStageDetailType(stageId)
    return self._Model:GetStageDetailType(stageId)
end

-- 关卡是否忽略新章节标签、完成进度的计算
function XMainLine2Control:IsStageIgnore(stageId)
    return self._Model:IsStageIgnore(stageId)
end

-- 获取关卡VideoId
function XMainLine2Control:GetStageVideoId(stageId)
    return self._Model:GetStageVideoId(stageId)
end

-- 获取关卡特殊序号
function XMainLine2Control:GetStageSpecialorder(stageId)
    return self._Model:GetStageSpecialorder(stageId)
end

-- 获取关卡怪物头像
function XMainLine2Control:GetStageMonsterHead(stageId)
    return self._Model:GetStageMonsterHead(stageId)
end

-- 获取关卡怪物半身像
function XMainLine2Control:GetStageMonsterHalfBody(stageId)
    return self._Model:GetStageMonsterHalfBody(stageId)
end

-- 获取通关奖励表
function XMainLine2Control:GetConfigTreasure(treasureId)
    return self._Model:GetConfigTreasure(treasureId)
end

-- 获取成就表
function XMainLine2Control:GetConfigAchievement(achievementId)
    return self._Model:GetConfigAchievement(achievementId)
end

-- 获取成就奖励Id
function XMainLine2Control:GetAchievementClearRewardId(achievementId)
    return self._Model:GetAchievementClearRewardId(achievementId)
end

-- 获取成就图标
function XMainLine2Control:GetAchievementIcon(achievementId)
    return self._Model:GetAchievementIcon(achievementId)
end

-- 获取客户端配置表参数
function XMainLine2Control:GetClientConfigParams(key, index)
    return self._Model:GetClientConfigParams(key, index)
end

--#endregion 配置表 -----------------------------------------------------------------------------------------------

--- 章节是否通关
---@param chapterId number 章节Id
function XMainLine2Control:IsChapterPassed(chapterId)
    return self._Model:IsChapterPassed(chapterId)
end

--- 章节是否解锁
---@param chapterId number 章节Id
function XMainLine2Control:IsChapterUnlock(chapterId)
    return self._Model:IsChapterUnlock(chapterId)
end

--- 章节奖励是否领取完成
---@param chapterId number 章节Id
function XMainLine2Control:IsChapterTreasureFinish(chapterId)
    return self._Model:IsChapterTreasureFinish(chapterId)
end

--- 章节是否显示蓝点
---@param chapterId number 章节Id
function XMainLine2Control:IsChapterRed(chapterId)
    return self._Model:IsChapterRed(chapterId)
end

--- 获取章节通关进度
---@param chapterId number 章节Id
function XMainLine2Control:GetChapterProgress(chapterId)
    return self._Model:GetChapterProgress(chapterId)
end

--- 获取章节所有关卡入口的数据
---@param chapterId number 章节Id
function XMainLine2Control:GetChapterEntranceDatas(chapterId)
    local entrances = {}
    local chapterCfg = self:GetConfigChapter(chapterId)
    for _, groupId in ipairs(chapterCfg.StageGroupIds) do
        local groupCfg = self:GetConfigStageGroup(groupId)

        -- 一个关卡一个入口
        if groupCfg.GroupType == XEnumConst.MAINLINE2.GROUP_TYPE.INDEPENDENT_ENTRANCE then
            for _, stageId in ipairs(groupCfg.StageIds) do
                table.insert(entrances, { StageIds = {stageId}, GroupId = groupId })
            end
        -- 多个关卡同个入口
        elseif groupCfg.GroupType == XEnumConst.MAINLINE2.GROUP_TYPE.COMBINE_ENTRANCE then
            local stageIds = XTool.Clone(groupCfg.StageIds)
            table.insert(entrances, { StageIds = stageIds, GroupId = groupId })
        end
    end
    return entrances
end

--- 获取章节打的下一关入口
---@param chapterId number 章节Id
function XMainLine2Control:GetChapterNextEntrance(chapterId)
    return self._Model:GetChapterNextEntrance(chapterId)
end

--- 获取关卡的通关进度
---@param stageId number 关卡Id
function XMainLine2Control:GetStageProgress(stageId)
    local conditions = self._Model:GetStageProgressConditions(stageId)
    if #conditions > 0 then
        local reachCnt = 0
        for _, condition in ipairs(conditions) do
            local isReach, desc = XConditionManager.CheckCondition(condition)
            if isReach then
                reachCnt = reachCnt + 1
            end
        end
        return reachCnt, #conditions
    end

    return 0, 0
end

--- 获取关卡成就完成情况
---@param stageId number 关卡Id
function XMainLine2Control:GetStageAchievementMap(stageId)
    return self._Model:GetStageAchievementMap(stageId)
end

--- 获取关卡成就信息
---@param stageId number 关卡Id
---@param isFighting boolean 是否在战斗中
---@param stageIds table 同个入口的所有关卡id列表
function XMainLine2Control:GetStagesAchievementInfos(stageId, isFighting, stageIds)
    return self._Model:GetStagesAchievementInfos(stageId, isFighting, stageIds)
end

--- 关卡是否解锁
---@param stageId number 关卡Id
function XMainLine2Control:IsStageUnlock(stageId)
    return self._Model:IsStageUnlock(stageId)
end

--- 获取关卡是否通关
---@param stageId number 关卡Id
function XMainLine2Control:IsStagePass(stageId)
    return self._Model:IsStagePass(stageId)
end

--- 缓存章节Id对应的主章节Id
---@param chapterId number 章节Id
---@param mainId number 主章节Id
function XMainLine2Control:CacheChapterMainId(chapterId, mainId)
    self._Model:CacheChapterMainId(chapterId, mainId)
end

--- 获取章节对应的mainId
---@param chapterId number 章节Id
function XMainLine2Control:GetChapterMainId(chapterId)
    return self._Model:GetChapterMainId(chapterId)
end

--- 缓存关卡Id对应的章节Id
---@param stageId number 关卡Id
---@param chapterId number 章节Id
function XMainLine2Control:CacheStageChapterId(stageId, chapterId)
    self._Model:CacheStageChapterId(stageId, chapterId)
end

--- 获取关卡对应的章节Id
---@param stageId number 关卡Id
function XMainLine2Control:GetStageChapterId(stageId)
    return self._Model:GetStageChapterId(stageId)
end

--- 缓存关卡Id所在的关卡列表
---@param stageId number 关卡Id
---@param stageIds number[] 关卡Id列表
function XMainLine2Control:CacheStageStageIds(stageId, stageIds)
    self._Model:CacheStageStageIds(stageId, stageIds)
end

--- 获取关卡所在的关卡列表
---@param stageId number 关卡Id
---@return number[] 关卡Id列表
function XMainLine2Control:GetStageStageIds(stageId)
    return self._Model:GetStageStageIds(stageId)
end

--- 获取章节最后打的关卡Id
---@param chapterId number 章节Id
function XMainLine2Control:GetLastPassStage(chapterId)
    return self._Model:GetLastPassStage(chapterId)
end

return XMainLine2Control