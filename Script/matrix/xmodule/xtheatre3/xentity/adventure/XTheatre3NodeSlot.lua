local XTheatre3NodeReward = require("XModule/XTheatre3/XEntity/Adventure/XTheatre3NodeReward")
local XTheatre3NodeShopItem = require("XModule/XTheatre3/XEntity/Adventure/XTheatre3NodeShopItem")

---@class XTheatre3NodeSlot
local XTheatre3NodeSlot = XClass(nil, "XTheatre3NodeSlot")

function XTheatre3NodeSlot:Ctor()
    ---@type number XEnumConst.THEATRE3.NodeSlotType
    self.SlotType = 0
    self.SlotId = 0
    self.IsSelected = false
    self.IsShopEndBuy = false

    -- 战斗与事件节点公用,事件节点可能有战斗
    self.FightId = 0
    self.FightTemplateId = 0
    
    -- 战斗节点
    self.LinkGroupId = 0
    ---@type number[]
    self.PassedStageIds = {}
    ---节点随机奖励, 只是作为展示用
    ---@type XTheatre3NodeReward[]
    self.NodeRewards = {}
    
    -- 事件节点
    self.EventId = 0
    self.CurStepId = 0
    ---@type number[]
    self.PassedStepId = {}
    
    -- 商店节点
    self.ShopId = 0
    ---@type XTheatre3NodeShopItem[]
    self.ShopItems = {}
end

--region DataUpdate
function XTheatre3NodeSlot:UpdatePassedStageIds(data)
    self.PassedStageIds = {}
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, id in ipairs(data) do
        self.PassedStageIds[#self.PassedStageIds + 1] = id
    end
end

function XTheatre3NodeSlot:UpdateNodeRewards(data)
    self.NodeRewards = {}
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, rewardData in ipairs(data) do
        ---@type XTheatre3NodeShopItem
        local reward = XTheatre3NodeReward.New()
        reward:NotifyData(rewardData)
        self.NodeRewards[#self.NodeRewards + 1] = reward
    end
end

function XTheatre3NodeSlot:UpdatePassedStepId(data)
    self.PassedStepId = {}
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, id in ipairs(data) do
        self.PassedStepId[#self.PassedStepId + 1] = id
    end
end

function XTheatre3NodeSlot:UpdateShopItems(data)
    self.ShopItems = {}
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, shopItem in ipairs(data) do
        ---@type XTheatre3NodeShopItem
        local item = XTheatre3NodeShopItem.New()
        item:NotifyData(shopItem)
        self.ShopItems[#self.ShopItems + 1] = item
    end
end

function XTheatre3NodeSlot:AddPassedStepId(stepId)
    if table.indexof(self.PassedStepId, stepId) then
        return
    end
    table.insert(self.PassedStepId, stepId)
end

function XTheatre3NodeSlot:AddPassedStageId(stageId)
    if table.indexof(self.PassedStageIds, stageId) then
        return
    end
    table.insert(self.PassedStageIds, stageId)
end

function XTheatre3NodeSlot:SetCurStepId(curStepId)
    self.CurStepId = curStepId
end

function XTheatre3NodeSlot:SetFightTemplateId(fightTemplateId)
    self.FightTemplateId = fightTemplateId
end

function XTheatre3NodeSlot:SetSelect()
    self.IsSelected = true
end

function XTheatre3NodeSlot:SetShopEndBuy()
    self.IsShopEndBuy = true
end
--endregion

--region Getter
function XTheatre3NodeSlot:GetSlotId()
    return self.SlotId
end

function XTheatre3NodeSlot:GetEventId()
    return self.EventId
end

function XTheatre3NodeSlot:GetCurStepId()
    return self.CurStepId
end

function XTheatre3NodeSlot:GetFightTemplateId()
    if XTool.IsNumberValid(self.EventId) and XTool.IsNumberValid(self.CurStepId) then
        local event = XMVCA.XTheatre3:GetEventStepType(self.EventId, self.CurStepId)
        return event.Type == XEnumConst.THEATRE3.EventStepType.Fight and self.FightTemplateId or 0
    end
    -- 通过AddStep添加的纯战斗节点
    return self.FightTemplateId
end

function XTheatre3NodeSlot:GetFightId()
    return self.FightId
end

function XTheatre3NodeSlot:GetShopId()
    return self.ShopId
end

---@return XTheatre3NodeReward[]
function XTheatre3NodeSlot:GetNodeRewards()
    return self.NodeRewards
end

---@return XTheatre3NodeShopItem[]
function XTheatre3NodeSlot:GetShopItems()
    return self.ShopItems
end
--endregion

--region Checker
function XTheatre3NodeSlot:CheckIsSelected()
    return self.IsSelected
end

function XTheatre3NodeSlot:CheckIsFight()
    return XTool.IsNumberValid(self:GetFightTemplateId())
end

function XTheatre3NodeSlot:CheckStageIsPass(stageId)
    return table.indexof(self.PassedStageIds, stageId)
end

function XTheatre3NodeSlot:CheckStepIsPass(stepId)
    return table.indexof(self.PassedStepId, stepId)
end

function XTheatre3NodeSlot:CheckIsShopEndBuy()
    if not self:CheckType(XEnumConst.THEATRE3.NodeSlotType.Shop) then
        return false
    end
    return self.IsShopEndBuy
end

---@param type number XEnumConst.THEATRE3.NodeSlotType
function XTheatre3NodeSlot:CheckType(type)
    return self.SlotType == type
end
--endregion

function XTheatre3NodeSlot:NotifyData(data)
    self.SlotType = data.SlotType
    self.SlotId = data.SlotId
    self.IsSelected = XTool.IsNumberValid(data.Selected)
    self.FightId = data.FightId
    self.FightTemplateId = data.FightTemplateId
    self.LinkGroupId = data.LinkGroupId
    self.EventId = data.EventId
    self.CurStepId = data.CurStepId
    self.ShopId = data.ShopId

    self:UpdatePassedStageIds(data.PassedStageIds)
    self:UpdateNodeRewards(data.NodeRewards)
    self:UpdatePassedStepId(data.PassedStepId)
    self:UpdateShopItems(data.ShopItems)
end

return XTheatre3NodeSlot