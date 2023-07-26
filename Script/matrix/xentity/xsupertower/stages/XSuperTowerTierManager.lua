--===========================
--超级爬塔 爬塔关卡 管理器
--模块负责：吕天元
--===========================
local XSuperTowerTierManager = XClass(nil, "XSuperTowerTierManager")
local StageType = {
    None = 0, -- 缺省类型，表示空值(用于查询时)
    SingleTeamOneWave = 1, -- 单队伍单波
    SingleTeamMultiWave = 2, -- 单队伍多波
    MultiTeamMultiWave = 3, -- 多队伍多波
    LllimitedTower = 4, -- 无限爬塔
}
function XSuperTowerTierManager:Ctor(theme)
    self.Theme = theme
    self:Init()
end
--=================
--初始化管理器
--=================
function XSuperTowerTierManager:Init()
    self:InitTierStages()
end
--=================
--初始化爬塔关卡
--=================
function XSuperTowerTierManager:InitTierStages()
    local stageList = XSuperTowerConfigs.GetTierStagesByThemeId(self.Theme:GetId())
    local script = require("XEntity/XSuperTower/Stages/XSuperTowerTierStage")
    self.TierStages = {}
    self.MaxScore = 0
    self.MaxTier = #stageList
    for tier, tierStage in pairs(stageList) do
        self.TierStages[tier] = script.New(self, tierStage)
        self.MaxScore = self.MaxScore + self.TierStages[tier]:GetMaxScore()
        local stageId = self.TierStages[tier]:GetStageId()
        if not self.Theme.StageId2StageType[stageId] then
            self.Theme.StageId2StageType[stageId] = StageType.LllimitedTower
            self.Theme.StageId2Index[stageId] = 1
        end
    end
end

function XSuperTowerTierManager:InitStageInfo()
    for _, tierStage in pairs(self.TierStages) do
        tierStage:InitStageInfo()
    end
end
--=================
--爬塔状态重置
--=================
function XSuperTowerTierManager:Reset()
    --重置时，若是新的层纪录，则刷新历史记录
    if self.IsNewTierRecord then
        self.HistoryHighestTier = self.CurrentTier
    end
    --重置时，若是新的层纪录，则刷新历史记录
    if self.IsNewScoreRecord then
        self.HistoryHighestScore = self.CurrentScore
    end
    self.CurrentTier = 0
    self.IsNewTierRecord = false
    self.CurrentScore = 0
    self.IsNewScoreRecord = false
    self.EnhancerIds = nil
    self.PluginInfos = nil
    self:ResetTierChara()
end
--=================
--刷新推送数据
--@param data(StTierInfo):{
--当前层 int Tier,
--历史最高层 int MaxTier,
--当前积分 int Score,
--历史最高积分 int MaxScore,
--增益列表 List<int> EnhancerIds,
--插件列表 List<StPluginInfo> PluginInfos,
--出战角色列表 List<StTierCharacterInfo> CharacterInfos
--}
--=================
function XSuperTowerTierManager:RefreshNotifyData(data, needReset)
    --if not needReset then
        self.CurrentTier = data.Tier
        self.CurrentScore = data.Score
        self.EnhancerIds = data.EnhancerIds
        self.PluginInfos = data.PluginInfos
        if self:CheckIsPlaying() then
            self:RefreshTierChara(data.TeamInfo)
        end
    --end
    self.IsNewTierRecord = self.CurrentTier > self:GetHistoryHighestTier()
    self.IsNewScoreRecord = self.CurrentScore > self:GetHistoryHighestScore()
    if not needReset then
        self.HistoryHighestTier = data.MaxTier
        self.HistoryHighestScore = data.MaxScore
    end
    self:SetResetFlag(needReset or false)
end
--=================
--通知角色管理器爬塔状态重置
--=================
function XSuperTowerTierManager:ResetTierChara()
    XDataCenter.SuperTowerManager.GetRoleManager():ResetTierRoleData()
end
--=================
--刷新推送爬塔角色数据
--@param data(List<StTierCharacterInfo>)StTierCharacterInfo:{
--角色id int Id，
--血量剩余百分比 int HpLeft，
--机器人id int RobotId，(当角色是机器人时才会有值)
--}
--=================
function XSuperTowerTierManager:RefreshTierChara(infos)
    local team = XDataCenter.SuperTowerManager.GetTeamByStageType(XDataCenter.SuperTowerManager.StageType.LllimitedTower)
    team:UpdateFirstFightPos(infos.FirstPos)
    team:UpdateCaptainPos(infos.CaptainPos)
    -- 更新队伍实体位置
    local characterInfo
    for pos = 1, XEntityHelper.TEAM_MAX_ROLE_COUNT do
        characterInfo = infos.CharacterInfos[pos]
        if characterInfo then
            if characterInfo.RobotId and characterInfo.RobotId > 0 then 
                team:UpdateEntityTeamPos(characterInfo.RobotId, pos, true)
            elseif characterInfo.Id and characterInfo.Id > 0 then
                team:UpdateEntityTeamPos(characterInfo.Id, pos, true)
            else
                team:UpdateEntityTeamPos(0, pos, true)
            end
        else
            team:UpdateEntityTeamPos(0, pos, true)
        end
    end
    XDataCenter.SuperTowerManager.GetRoleManager():RefreshTierRoleData(infos.CharacterInfos)
end
--=================
--根据层数获取爬塔关卡对象
--@param tier:层数
--=================
function XSuperTowerTierManager:GetTierStageByTier(tier)
    return self.TierStages[tier]
end
--=================
--获取爬塔角色数据
--=================
function XSuperTowerTierManager:GetTeam()
    return self.TeamInfos or {}
end
--=================
--获取爬塔玩家现在积分
--=================
function XSuperTowerTierManager:GetCurrentScore()
    return self.CurrentScore or 0
end
--=================
--获取爬塔玩家历史最高积分
--=================
function XSuperTowerTierManager:GetHistoryHighestScore()
    return self.HistoryHighestScore or 0
end
--=================
--获取爬塔关卡最大可获得的积分
--=================
function XSuperTowerTierManager:GetMaxScore()
    return self.MaxScore or 0
end
--=================
--获取爬塔关卡现在积分显示
--格式: 历史荣誉分/最大可获得荣誉分
--=================
function XSuperTowerTierManager:GetScoreStr()
    return XUiHelper.GetText("STTierScoreStr", self:GetHistoryHighestScore(), self:GetMaxScore())
end
--=================
--获取爬塔玩家现在层数
--=================
function XSuperTowerTierManager:GetCurrentTier()
    return self.CurrentTier or 0
end
--=================
--获取爬塔玩家历史通过最高层
--=================
function XSuperTowerTierManager:GetHistoryHighestTier()
    return self.HistoryHighestTier or 0
end
--=================
--获取爬塔关卡总层数
--=================
function XSuperTowerTierManager:GetMaxTier()
    return self.MaxTier or 0
end
--=================
--获取爬塔关卡现在层数进度显示
--=================
function XSuperTowerTierManager:GetTierStr()
    return self:GetCurrentTier() .. "/" .. self:GetMaxTier()
end
--=================
--获取爬塔关卡利时最大层数进度显示
--=================
function XSuperTowerTierManager:GetHistoryTierStr()
    return self:GetHistoryHighestTier() .. "/" .. self:GetMaxTier()
end
--=================
--获取已获得的爬塔增益ID列表
--=================
function XSuperTowerTierManager:GetEnhanceIds()
    return self.EnhancerIds or {}
end
--=================
--获取已获得的插件信息
--=================
function XSuperTowerTierManager:GetPluginInfos()
    return self.PluginInfos or {}
end
--=================
--获取爬塔分数上限值
--=================
function XSuperTowerTierManager:GetMaxScore()
    return self.MaxScore
end
--=================
--检查现在是否正在爬塔
--=================
function XSuperTowerTierManager:CheckIsPlaying()
    return self:GetCurrentTier() > 0
end
--=================
--检查最新的更新是否刷新了新层数纪录
--=================
function XSuperTowerTierManager:CheckIsNewTierRecord()
    return self.IsNewTierRecord
end
--=================
--检查最新的更新是否刷新了分数纪录
--=================
function XSuperTowerTierManager:CheckIsNewScoreRecord()
    return self.IsNewScoreRecord
end
--=================
--检查重置标记，若需重置则重置爬塔
--=================
function XSuperTowerTierManager:CheckReset()
    if not self.ResetFlag then return end
    self.ResetFlag = false
    self:Reset()
end
--=================
--获取当前重置标记状态
--=================
function XSuperTowerTierManager:GetResetFlag()
    return self.ResetFlag
end
--=================
--设置当前重置标记状态
--=================
function XSuperTowerTierManager:SetResetFlag(value)
    self.ResetFlag = value
end
--=================
--根据分数类型获取爬塔分数计数
--@param scoreType:分数类型 XSuperTowerManager.ScoreType
--=================
function XSuperTowerTierManager:GetTierScoreCountByScoreType(scoreType)
    local count = 0
    local score = 0
    for i = 1, self:GetCurrentTier() do
        local num = self.TierStages[i]:GetScoreByIndex(scoreType)
        if num > 0 then
            count = count + 1
            score = score + num
        end
    end
    return count, score
end

return XSuperTowerTierManager