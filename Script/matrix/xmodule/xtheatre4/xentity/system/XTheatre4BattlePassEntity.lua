local XTheatre4EntityBase = require("XModule/XTheatre4/XEntity/System/XTheatre4EntityBase")

---@class XTheatre4BattlePassEntity : XTheatre4EntityBase
---@field _Model XTheatre4Model
---@field _Control XTheatre4SystemSubControl
local XTheatre4BattlePassEntity = XClass(XTheatre4EntityBase, "XTheatre4BattlePassEntity")

function XTheatre4BattlePassEntity:Ctor()
    self._CurrentExp = 0
    self._IsReceived = false
    self._IsInitial = false
    self._Index = 1
end

function XTheatre4BattlePassEntity:SetIsInitial(value)
    self._IsInitial = value
end

function XTheatre4BattlePassEntity:SetCurrentExp(value)
    self._CurrentExp = value
end

function XTheatre4BattlePassEntity:GetCurrentExp()
    return self._CurrentExp
end

function XTheatre4BattlePassEntity:SetIndex(value)
    self._Index = value
end

function XTheatre4BattlePassEntity:GetIndex()
    return self._Index
end

function XTheatre4BattlePassEntity:GetCurrentTotalExp()
    return self._Control:GetCurrentBattlePassTotalExp()
end

function XTheatre4BattlePassEntity:GetItemId()
    local reward = self:GetReward()

    return reward and reward.TemplateId or 0
end

function XTheatre4BattlePassEntity:GetReward()
    local config = self:GetConfig()
    local rewardId = config:GetRewardId()
    local rewardList = XRewardManager.GetRewardList(rewardId)

    if not XTool.IsTableEmpty(rewardList) then
        return rewardList[1]
    end

    return nil
end

function XTheatre4BattlePassEntity:IsReceived()
    ---@type XTheatre4BattlePassConfig
    local config = self:GetConfig()
    local receiveIds = self._Model:GetBattlePassRewardIdMap()

    if receiveIds and config then
        return receiveIds[config:GetLevel()]
    end

    return false
end

function XTheatre4BattlePassEntity:IsCanReceive()
    return not self:IsReceived() and self:GetCurrentTotalExp() >= self:GetCurrentExp()
end

function XTheatre4BattlePassEntity:IsInitial()
    return self._IsInitial
end

return XTheatre4BattlePassEntity
