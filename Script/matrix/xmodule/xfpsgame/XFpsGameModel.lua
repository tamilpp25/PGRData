---@class XFpsGameModel : XModel
---@field _ActivityId number 活动Id
---@field _StageStarMap table<number,number> 关卡星级
---@field _StageFinishMap table<number,boolean> 关卡通关
---@field _ChapterRewardIds table<number,table<number,boolean>> 章节奖励领取
---@field _StageHistoryScore table<number,number> 关卡总分
local XFpsGameModel = XClass(XModel, "XFpsGameModel")

local TableKey = {
    FpsGameClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    FpsGameActivity = { CacheType = XConfigUtil.CacheType.Normal },
    FpsGameChapter = { CacheType = XConfigUtil.CacheType.Normal },
    FpsGameStage = { CacheType = XConfigUtil.CacheType.Normal, Identifier = "StageId" },
    FpsGameStarReward = { CacheType = XConfigUtil.CacheType.Normal },
    FpsGameWeapon = { CacheType = XConfigUtil.CacheType.Normal },
    FpsGameScore = { CacheType = XConfigUtil.CacheType.Normal },
    FpsGameScoreLevel = { CacheType = XConfigUtil.CacheType.Normal },
}

function XFpsGameModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fuben/FpsGame", TableKey)
end

function XFpsGameModel:ClearPrivate()
    self._StageModeMap = nil
    self._RewardGroupMap = nil
end

function XFpsGameModel:ResetAll()
    self._ActivityId = nil
    self._StageStarMap = nil
    self._StageFinishMap = nil
    self._ChapterRewardIds = nil
end

----------public start----------

function XFpsGameModel:IsStagePass(stageId)
    return self._StageFinishMap and self._StageFinishMap[stageId]
end

function XFpsGameModel:IsStageUnlock(stageId)
    local stage = self:GetStageById(stageId)
    if XTool.IsNumberValid(stage.PreStageId) then
        return self:IsStagePass(stage.PreStageId)
    end
    return true
end

function XFpsGameModel:IsWeaponUnlock(weaponId)
    if not XTool.IsNumberValid(weaponId) then
        return true
    end
    local conditionId = self:GetWeaponById(weaponId).UnlockCondition
    return not XTool.IsNumberValid(conditionId) or XConditionManager.CheckCondition(conditionId)
end

function XFpsGameModel:IsStoryPass()
    local cur, all = self:GetProgress(XEnumConst.FpsGame.Story)
    return cur >= all
end

function XFpsGameModel:IsChallengePass()
    local cur, all = self:GetProgress(XEnumConst.FpsGame.Challenge)
    return cur >= all
end

function XFpsGameModel:IsRewardGain(chapterId, rewardId)
    return self._ChapterRewardIds and self._ChapterRewardIds[chapterId] and self._ChapterRewardIds[chapterId][rewardId]
end

function XFpsGameModel:IsNewScore(stageId, score)
    if not self._StageHistoryScore then
        return true
    end
    local historyScore = self._StageHistoryScore[stageId]
    if not historyScore then
        return true
    end
    return score > historyScore
end

function XFpsGameModel:IsChapterRewardGain(chapterId)
    local progress = self:GetProgress(chapterId)
    local chapter = self:GetChapterById(chapterId)
    local rewards = self:GetRewardsByGroup(chapter.StarRewardGroupId)
    for _, reward in pairs(rewards) do
        if progress >= reward.Star then
            if not self:IsRewardGain(chapterId, reward.Id) then
                return true
            end
        end
    end
    return false
end

function XFpsGameModel:GetStageStar(stageId)
    if not self:IsStagePass(stageId) then
        return 0
    end
    return self._StageStarMap and self._StageStarMap[stageId] or 0
end

function XFpsGameModel:GetActivityTimeId()
    return self:GetActivityById(self._ActivityId).TimeId
end

---@return XTableFpsGameStage[]
function XFpsGameModel:GetStagesByChapter(chapter)
    if not self._StageModeMap then
        self._StageModeMap = {}
    end
    if not self._StageModeMap[chapter] then
        self._StageModeMap[chapter] = {}
        local stages = self:GetStages()
        for _, v in pairs(stages) do
            if v.ChapterId == chapter then
                table.insert(self._StageModeMap[chapter], v)
            end
        end
        for _, tb in pairs(self._StageModeMap) do
            table.sort(tb, function(a, b)
                return a.StageId < b.StageId
            end)
        end
    end
    return self._StageModeMap[chapter]
end

---@return XTableFpsGameStarReward[]
function XFpsGameModel:GetRewardsByGroup(groupId)
    if not self._RewardGroupMap then
        self._RewardGroupMap = {}
    end
    if not self._RewardGroupMap[groupId] then
        self._RewardGroupMap[groupId] = {}
        local rewards = self:GetRewards()
        for _, v in pairs(rewards) do
            if v.GroupId == groupId then
                table.insert(self._RewardGroupMap[groupId], v)
            end
        end
    end
    return self._RewardGroupMap[groupId]
end

function XFpsGameModel:SetBattleData(battleWeapon, battleCharacterId)
    self._BattleWeapon = battleWeapon
    self._BattleCharacterId = battleCharacterId
end

function XFpsGameModel:GetBattleWeapon()
    return self._BattleWeapon
end

function XFpsGameModel:GetBattleCharacterId()
    return self._BattleCharacterId
end

function XFpsGameModel:GetStarsCount(starsMark)
    if not XTool.IsNumberValid(starsMark) then
        return 0
    end
    return (starsMark & 1) + (starsMark & 2 > 0 and 1 or 0) + (starsMark & 4 > 0 and 1 or 0)
end

function XFpsGameModel:GetScoreLevel(score)
    local configs = self:GetScoreLevels()
    for _, v in pairs(configs) do
        if v.MinScore <= score and v.MaxScore >= score then
            return v
        end
    end
    XLog.Error("找不到对应的评分配置.分数：" .. score)
    return nil
end

function XFpsGameModel:GetStageHistoryScore(stageId)
    return self._StageHistoryScore and self._StageHistoryScore[stageId]
end

function XFpsGameModel:IsEnterMainPanel()
    return self._IsEnterMainPanel
end

function XFpsGameModel:SetEnterMainPanel()
    self._IsEnterMainPanel = true
end

function XFpsGameModel:GetChapterOpenTime(chapterId)
    local chapter = self:GetChapterById(chapterId)
    if XTool.IsNumberValid(chapter.OpenTimeId) then
        return XFunctionManager.GetStartTimeByTimeId(chapter.OpenTimeId)
    end
    return 0
end

function XFpsGameModel:CheckChapterOpen(chapterId, isTip)
    local time = self:GetChapterOpenTime(chapterId) - XTime.GetServerNowTimestamp()
    if time > 0 then
        if isTip then
            XUiManager.TipError(XUiHelper.GetText("FpsGameChallengeTime", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)))
        end
        return false
    end

    local chapter = self:GetChapterById(chapterId)
    if XTool.IsNumberValid(chapter.Condition) then
        local result, desc = XConditionManager.CheckCondition(chapter.Condition)
        if not result then
            if isTip then
                XUiManager.TipError(desc)
            end
            return false
        end
    end

    return true
end

---从活动主界面进入关卡界面时播放镜头动画
function XFpsGameModel:SetTriggerEnableCameraAnim()
    self._IsTriggerEnableCameraAnim = true
end

function XFpsGameModel:GetTriggerEnableCameraAnim()
    local bo = self._IsTriggerEnableCameraAnim
    self._IsTriggerEnableCameraAnim = false
    return bo
end

----------public end----------

----------private start----------

function XFpsGameModel:GetProgress(chapter)
    local cur, all = 0, 0
    local stages = self:GetStagesByChapter(chapter)
    for _, v in pairs(stages) do
        all = all + v.StarCount
        cur = cur + self:GetStageStar(v.StageId)
    end
    return cur, all
end

----------private end----------

----------config start----------

---@return XTableFpsGameActivity
function XFpsGameModel:GetActivityById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FpsGameActivity, id)
end

---@return XTableFpsGameClientConfig
function XFpsGameModel:GetClientConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FpsGameClientConfig, id)
end

---@return XTableFpsGameChapter
function XFpsGameModel:GetChapterById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FpsGameChapter, id)
end

---@return XTableFpsGameStage
function XFpsGameModel:GetStageById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FpsGameStage, id)
end

---@return XTableFpsGameStarReward
function XFpsGameModel:GetRewardById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FpsGameStarReward, id)
end

---@return XTableFpsGameWeapon
function XFpsGameModel:GetWeaponById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FpsGameWeapon, id)
end

---@return XTableFpsGameScore
function XFpsGameModel:GetScoreById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FpsGameScore, id)
end

---@return XTableFpsGameStage[]
function XFpsGameModel:GetStages()
    return self._ConfigUtil:GetByTableKey(TableKey.FpsGameStage)
end

---@return XTableFpsGameStarReward[]
function XFpsGameModel:GetRewards()
    return self._ConfigUtil:GetByTableKey(TableKey.FpsGameStarReward)
end

---@return XTableFpsGameWeapon[]
function XFpsGameModel:GetWeapons()
    return self._ConfigUtil:GetByTableKey(TableKey.FpsGameWeapon)
end

---@return XTableFpsGameScoreLevel[]
function XFpsGameModel:GetScoreLevels()
    return self._ConfigUtil:GetByTableKey(TableKey.FpsGameScoreLevel)
end

----------config end----------

function XFpsGameModel:NotifyFpsGameData(data)
    self._ActivityId = data.ActivityId
    -- 章节已领取奖励
    self._ChapterRewardIds = {}
    if not XTool.IsTableEmpty(data.ChapterDatas) then
        for _, chapter in pairs(data.ChapterDatas) do
            self._ChapterRewardIds[chapter.ChapterId] = {}
            for _, rewardId in pairs(chapter.GetRewardIds) do
                self._ChapterRewardIds[chapter.ChapterId][rewardId] = true
            end
        end
    end
    -- 关卡星级&通关列表
    self._StageStarMap = {}
    self._StageFinishMap = {}
    self._StageHistoryScore = {}
    if not XTool.IsTableEmpty(data.StageDatas) then
        for _, stage in pairs(data.StageDatas) do
            if stage.IsFinish then
                self._StageFinishMap[stage.StageId] = true
            end
            self._StageStarMap[stage.StageId] = self:GetStarsCount(stage.Star)
            self._StageHistoryScore[stage.StageId] = stage.TotalScore or 0
        end
    end
end

function XFpsGameModel:AddChapterReward(chapterId, rewardIds)
    if not self._ChapterRewardIds then
        self._ChapterRewardIds = {}
    end
    if not self._ChapterRewardIds[chapterId] then
        self._ChapterRewardIds[chapterId] = {}
    end
    for _, rewardId in pairs(rewardIds) do
        self._ChapterRewardIds[chapterId][rewardId] = true
    end
end

function XFpsGameModel:AddFinishStage(stageId)
    if not self._StageFinishMap then
        self._StageFinishMap = {}
    end
    self._StageFinishMap[stageId] = true
end

function XFpsGameModel:UpdateStageStar(stageId, star)
    if not star then
        XLog.Error("结算错误 星级为nil")
        return
    end
    if not self._StageStarMap then
        self._StageStarMap = {}
    end
    local curStar = self._StageStarMap[stageId] or 0
    self._StageStarMap[stageId] = math.max(curStar, star)
end

function XFpsGameModel:UpdateStageScore(stageId, score)
    if not score then
        XLog.Error("结算错误 分数为nil")
        return
    end
    if not self._StageHistoryScore then
        self._StageHistoryScore = {}
    end
    local historyScore = self._StageHistoryScore[stageId] or 0
    self._StageHistoryScore[stageId] = math.max(historyScore, score)
end

return XFpsGameModel