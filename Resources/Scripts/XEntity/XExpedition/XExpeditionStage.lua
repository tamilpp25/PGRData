-- 虚像地平线关卡对象
local XExpeditionStage = XClass(nil, "XExpeditionStage")

local StageType = {
    Story = 1,
    Battle = 2,
    Infinity = 3
    }
--================
--构造函数
--@param eStageId:虚像地平线关卡ID
--================
function XExpeditionStage:Ctor(eStageId)
    self:Init(eStageId)
end
--================
--定义StageInfo
--@param eStageId:虚像地平线关卡ID
--================
local InitStageInfo = function(stageInfo)
    stageInfo.Type = XDataCenter.FubenManager.StageType.Expedition
end
--================
--初始化
--@param eStageId:虚像地平线关卡ID
--================
function XExpeditionStage:Init(eStageId)
    self.EStageCfg = XExpeditionConfig.GetEStageCfg(eStageId)
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.EStageCfg.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.EStageCfg.StageId)
    InitStageInfo(stageInfo)
end
--================
--获取关卡基础配置
--================
function XExpeditionStage:GetStageCfg()
    return self.StageCfg
end
--================
--获取关卡Id
--================
function XExpeditionStage:GetStageId()
    return self.EStageCfg and self.EStageCfg.StageId
end
--================
--获取关卡类型
--================
function XExpeditionStage:GetStageType()
    return self.EStageCfg and self.EStageCfg.StageType or 1
end
--================
--获取是否无尽关卡
--================
function XExpeditionStage:GetIsInfinity()
    return self:GetStageType() == StageType.Infinity
end
--================
--获取故事ID
--================
function XExpeditionStage:GetBeginStoryId()
    return self.StageCfg and self.StageCfg.BeginStoryId
end
--================
--获取关卡序号
--================
function XExpeditionStage:GetOrderId()
    return self.EStageCfg and self.EStageCfg.OrderId or 1
end
--================
--获取关卡奖励招募次数
--================
function XExpeditionStage:GetDrawTimesReward()
    return self.EStageCfg and self.EStageCfg.DrawTimesReward or 0
end
--================
--获取关卡奖励招募次数字符串
--================
function XExpeditionStage:GetDrawTimesRewardStr()
    local str = ""
    if not self:GetIsPass() then
        str = CS.XTextManager.GetText("ExpeditionRecruitTimes", self:GetDrawTimesReward())
    end
    return str
end
--================
--获取关卡首通奖励ID
--================
function XExpeditionStage:GetFirstRewardId()
    return self.StageCfg and self.StageCfg.FirstRewardId
end
--================
--获取关卡预制体地址
--================
function XExpeditionStage:GetPrefabPath()
    return self.EStageCfg and self.EStageCfg.StagePrefabPath or ""
end
--================
--获取关卡是否通过
--================
function XExpeditionStage:GetIsPass()
    local stageId = self:GetStageId()
    if not stageId then return false end
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    return stageInfo and stageInfo.Passed
end
--================
--获取关卡是否解锁
--================
function XExpeditionStage:GetIsUnlock()
    local stageId = self:GetStageId()
    if not stageId then return false end
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    return stageInfo and stageInfo.Unlock
end
--================
--获取关卡难度
--================
function XExpeditionStage:GetDifficulty()
    return self.EStageCfg and self.EStageCfg.Difficulty
end
--================
--获取是否噩梦关卡
--================
function XExpeditionStage:GetIsNightMareStage()
    if self.IsNightMare ~= nil then return self.IsNightMare end
    local difficulty = self:GetDifficulty()
    self.IsNightMare = difficulty == XDataCenter.ExpeditionManager.StageDifficulty.NightMare
    return self.IsNightMare
end
--================
--获取关卡名称
--================
function XExpeditionStage:GetStageName()
    return self.EStageCfg and self.StageCfg.Name
end
--================
--获取关卡封面(BOSS关卡使用)
--================
function XExpeditionStage:GetStageCover()
    return self.EStageCfg and self.EStageCfg.BossStageCover
end
--================
--获取关卡描述
--================
function XExpeditionStage:GetStageDes()
    return self.StageCfg and self.StageCfg.Description
end
--================
--获取关卡星数描述
--================
function XExpeditionStage:GetStageTargetDesc()
    return self.StageCfg and self.StageCfg.StarDesc
end
--================
--获取关卡词缀ID
--================
function XExpeditionStage:GetStageWords()
    return self.EStageCfg and self.EStageCfg.StageWords
end
--================
--获取关卡词缀配置
--================
function XExpeditionStage:GetStageEvents()
    local events = {}
    local stageFightEvent = self:GetStageWords()
    if stageFightEvent then
        for i = 1, #stageFightEvent do
            events[i] = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(stageFightEvent[i])
        end
    end
    return events or {}
end
--================
--获取关卡推荐等级
--================
function XExpeditionStage:GetRecommentStar()
    return self.EStageCfg and self.EStageCfg.RecommentStar
end
--================
--获取困难警告差值
--================
function XExpeditionStage:GetWarningCap()
    return self.EStageCfg and self.EStageCfg.WarningStarCap
end
--================
--获取危险警告差值
--================
function XExpeditionStage:GetDangerCap()
    return self.EStageCfg and self.EStageCfg.DangerStarCap
end
--================
--获取关卡警告等级(根据全队队员星级)
--================
function XExpeditionStage:GetStageIsDanger()
    local recommentStar = self:GetRecommentStar()
    if not recommentStar then return XDataCenter.ExpeditionManager.StageWarning.NoWarning end
    local average = XDataCenter.ExpeditionManager.GetTeamAverageStar()
    local levelCap = self:GetRecommentStar() - average
    if levelCap < self:GetWarningCap() then
        return XDataCenter.ExpeditionManager.StageWarning.NoWarning
    elseif levelCap >= self:GetWarningCap() and levelCap < self:GetDangerCap() then
        return XDataCenter.ExpeditionManager.StageWarning.Warning
    else
        return XDataCenter.ExpeditionManager.StageWarning.Danger
    end   
end
--================
--获取出战界面警告等级(随出战队伍变化而变化)
--================
function XExpeditionStage:GetStageIsDangerByBattleTeam(curTeam)
    local teamData = curTeam or XDataCenter.ExpeditionManager.GetExpeditionTeam()
    local totalStar = 0
    local memberNum = 0
    for _, eBaseId in pairs(teamData.TeamData) do
        if eBaseId > 0 then
            local eChara = XDataCenter.ExpeditionManager.GetTeam():GetCharaByEBaseId(eBaseId)
            if eChara then
                memberNum = memberNum + 1
                totalStar = totalStar + eChara:GetRank()
            end
        end
    end
    if memberNum == 0 then return XDataCenter.ExpeditionManager.StageWarning.Danger end
    local average = math.floor(totalStar / memberNum)
    local levelCap = self:GetRecommentStar() - average
    if levelCap < self:GetWarningCap() then
        return XDataCenter.ExpeditionManager.StageWarning.NoWarning
    elseif levelCap < self:GetDangerCap() and levelCap >= self:GetWarningCap() then
        return XDataCenter.ExpeditionManager.StageWarning.Warning
    else
        return XDataCenter.ExpeditionManager.StageWarning.Danger
    end
end
--================
--设置关卡通关(应用于剧情关)
--================
function XExpeditionStage:SetPass()
    local stageId = self:GetStageId()
    if not stageId then return end
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    stageInfo.Passed = true
end
--================
--重置关卡通过状态
--================
function XExpeditionStage:Reset()
    local stageId = self:GetStageId()
    if not stageId then return end
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if not stageInfo then return end
    if self:GetOrderId() ~= 1 then stageInfo.Unlock = false end
    stageInfo.Passed = false
end
return XExpeditionStage