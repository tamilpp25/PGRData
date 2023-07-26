-- 虚像地平线关卡层对象
local XExpeditionStageTier = XClass(nil, "XExpeditionStageTier")
local XStage = require("XEntity/XExpedition/XExpeditionStage")
function XExpeditionStageTier:Ctor(tierId, chapter)
    self.Chapter = chapter
    self:InitConfig(tierId)
    self:InitStages()
end

function XExpeditionStageTier:InitConfig(tierId)
    self.TierConfig = XExpeditionConfig.GetStageTierConfigByTierId(tierId)
end
--=====================
--初始化关卡信息
--=====================
function XExpeditionStageTier:InitStageInfos()
    for _, stage in pairs(self.Stages) do
        stage:InitStageInfo()
    end
end

function XExpeditionStageTier:InitStages()
    self.Stages = {}
    self.StageId2EStageDic = {}
    local stageIds = self:GetStageIds()
    for _, stageId in pairs(stageIds) do
        local eStage = XStage.New(stageId, self)
        table.insert(self.Stages, eStage)
        self.StageId2EStageDic[eStage:GetStageId()] = eStage
    end
end

function XExpeditionStageTier:GetEStageByStageId(stageId)
    return self.StageId2EStageDic and self.StageId2EStageDic[stageId]
end

function XExpeditionStageTier:GetStages()
    return self.Stages
end

function XExpeditionStageTier:GetId()
    return self.TierConfig and self.TierConfig.Id
end

function XExpeditionStageTier:GetChapterId()
    return self.TierConfig and self.TierConfig.ChapterId or 0
end

function XExpeditionStageTier:GetStageIds()
    if self.StageIds then return self.StageIds end
    self.StageIds = XExpeditionConfig.GetEStageIdsByTierId(self:GetId())
    return self.StageIds
    --return self.TierConfig and self.TierConfig.StageIds
end

function XExpeditionStageTier:GetOrderId()
    return self.TierConfig and self.TierConfig.OrderId
end

function XExpeditionStageTier:GetDifficulty()
    return self.TierConfig and self.TierConfig.Difficulty
end

function XExpeditionStageTier:GetName()
    return self.TierConfig and self.TierConfig.Name
end

function XExpeditionStageTier:GetDifficultyName()
    return XExpeditionConfig.DifficultyName[self:GetDifficulty()]
end

function XExpeditionStageTier:CheckDifficulty(difficulty)
    return self:GetDifficulty() == difficulty
end

function XExpeditionStageTier:GetBgCoverPath()
    return self.TierConfig and self.TierConfig.CoverPath
end

function XExpeditionStageTier:GetIsPass()
    for _, stage in pairs(self.Stages) do
        if not stage:GetIsPass() then
            return false
        end
    end
    return true
end
--=====================
--检查关卡层是否有任意小关通关
--=====================
function XExpeditionStageTier:CheckHasStagePass()
    for _, stage in pairs(self.Stages) do
        if stage:GetIsPass() then
            return true
        end
    end
    return false
end
--=====================
--获取关卡层是否解锁
--=====================
function XExpeditionStageTier:GetIsUnlock()
    if self:GetOrderId() == 1 and self:CheckDifficulty(XExpeditionConfig.StageDifficulty.Normal) then
        return true --普通关卡序号1的关卡层没有前置挑战条件
    elseif self:GetOrderId() == 1 and self:CheckDifficulty(XExpeditionConfig.StageDifficulty.NightMare) then
        return self.Chapter:GetIsClearByDifficulty(XExpeditionConfig.StageDifficulty.Normal)
    else
        local currentIndex = self.Chapter:GetCurrentIndexByDifficulty(self:GetDifficulty())
        return self:GetOrderId() <= currentIndex
    end
end
--=====================
--获取本层关卡角色被使用列表
--=====================
function XExpeditionStageTier:GetMemberUsed()
    local result = {}
    for _, stage in pairs(self.Stages) do
        local datas = stage:GetPassTeamData()
        for __, data in pairs(datas) do
            result[data.BaseId] = true
        end
    end
    return result
end
--=====================
--获取层类型
--=====================
function XExpeditionStageTier:GetTierType()
    return self.TierConfig and self.TierConfig.TierType or XExpeditionConfig.TierType.Normal
end
--=====================
--检查是否是无尽层
--=====================
function XExpeditionStageTier:CheckIsInfiTier()
    return self:GetTierType() == XExpeditionConfig.TierType.Infinity
end
--=====================
--获取无尽关卡(无尽层仅包含且只有一个无尽关)
--若不是无尽层，返回空值。
--返回无尽关卡对象。
--=====================
function XExpeditionStageTier:GetInfiStage()
    if not self:CheckIsInfiTier() then return end
    return self.Stages[1]
end
--=====================
--根据角色ID获取是否被此层使用
--=====================
function XExpeditionStageTier:CheckMemberIsUsed(baseId)
    return not self:GetIsPass() and self:GetMemberUsed()[baseId] or false
end
--=====================
--检查此层是否有关卡被首通过
--=====================
function XExpeditionStageTier:CheckHasFirstPassStage()
    for _, stage in pairs(self.Stages) do
        if stage:GetFirstPass() then
            return true
        end
    end
    return false
end
--=====================
--重置关卡层
--=====================
function XExpeditionStageTier:Reset()
    for _, stage in pairs(self.Stages) do
        stage:Reset()
    end
end

return XExpeditionStageTier