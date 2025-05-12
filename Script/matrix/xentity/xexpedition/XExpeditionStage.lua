-- 虚像地平线关卡对象
local XExpeditionStage = XClass(nil, "XExpeditionStage")

--================
--构造函数
--@param eStageId:虚像地平线关卡ID
--================
function XExpeditionStage:Ctor(eStageId)
    self:Init(eStageId)
end
--================
--初始化
--@param eStageId:虚像地平线关卡ID
--================
function XExpeditionStage:Init(eStageId)
    self.EStageCfg = XExpeditionConfig.GetEStageCfg(eStageId)
    self.IsPass = false
    self.FirstPass = false
    self.PassTeamData = {}
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.EStageCfg.StageId)
end

function XExpeditionStage:RefreshStageInfo(stageData)
    self.PassTeamData = stageData.FightCharacters
    self.IsPass = stageData.Pass
    self.FirstPass = true --只要后端有推送本关数据则表示首通过了，Pass只是现在的通关状态
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
    return self:GetStageType() == XExpeditionConfig.StageType.Infinity
end
--================
--获取故事ID
--================
function XExpeditionStage:GetBeginStoryId()
    return self.StageCfg and XMVCA.XFuben:GetBeginStoryId(self.StageCfg.StageId)
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
    return CS.XTextManager.GetText("ExpeditionRecruitTimes", self:GetDrawTimesReward())
end
--================
--获取刷关卡奖励招募次数
--================
function XExpeditionStage:GetPassDrawTimesReward()
    return self.EStageCfg and self.EStageCfg.PassDrawTimesReward or 0
end
--================
--获取复刷关卡奖励招募次数字符串
--================
function XExpeditionStage:GetPassDrawTimesRewardStr()
    return CS.XTextManager.GetText("ExpeditionRecruitTimes", self:GetPassDrawTimesReward())
end
--================
--获取关卡首通奖励ID
--================
function XExpeditionStage:GetFirstRewardId()
    return self.StageCfg and self.StageCfg.FirstRewardId
end
--================
--获取关卡是否通过
--================
function XExpeditionStage:GetIsPass()
    return self.IsPass
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
    return self.StageCfg and self.StageCfg.Name
end
--================
--获取关卡封面
--================
function XExpeditionStage:GetStageCover()
    local cfgCover = self.EStageCfg and self.EStageCfg.BossStageCover
    if cfgCover then
        return cfgCover
    end
    local stageType = self:GetStageType()
    if stageType == XExpeditionConfig.StageType.Story then
        return CS.XGame.ClientConfig:GetString("ExpeditionDefaultStoryCover")
    else
        return CS.XGame.ClientConfig:GetString("ExpeditionDefaultBattleCover")
    end
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
--获取关卡预制体
--================
function XExpeditionStage:GetStagePrefab()
    return self.EStageCfg and self.EStageCfg.StagePrefab or ""
end
--================
--获取关卡简述
--================
function XExpeditionStage:GetStageDes()
    return self.EStageCfg and self.EStageCfg.StageDes or ""
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
--获取已通关队伍的角色ECharacterId
--================
function XExpeditionStage:GetPassTeamData()
    return self.PassTeamData or {}
end
--================
--获取这个关卡所属的关卡层是否已经首通
--================
function XExpeditionStage:GetFirstPass()
    return self.FirstPass
end
--================
--设置关卡通关(应用于剧情关)
--================
function XExpeditionStage:SetPass()
    self.IsPass = true
end
--================
--重置关卡通过状态
--================
function XExpeditionStage:Reset()
    self.PassTeamData = nil
    self.IsPass = false
end

function XExpeditionStage:GetStageIsShow()
    local isShow = self:CheckPreStageIsPassed(self.EStageCfg.PreStageType)
    return isShow
end

function XExpeditionStage:CheckPreStageIsPassed(preStageType)
    if not XTool.IsNumberValid(preStageType) then
        return true
    end
    
    local isAnd = preStageType == XExpeditionConfig.PreStageCheckType.And
    local preStageIds = self.EStageCfg.PreStageIds
    if XTool.IsTableEmpty(preStageIds) then
        return true
    end
    
    local isShow = isAnd
    for _, stageId in pairs(preStageIds) do
        local passed = XDataCenter.ExpeditionManager.CheckPassedByStageId(stageId)
        if isAnd then
            if not passed then
                isShow = false
                break
            end
        else
            if passed then
                isShow = true
                break
            end
        end
    end
    
    return isShow
end

return XExpeditionStage