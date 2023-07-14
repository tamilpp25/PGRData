local XTheatre3NodeReward = require("XModule/XTheatre3/XEntity/Adventure/XTheatre3NodeReward")
local XTheatre3Node = require("XModule/XTheatre3/XEntity/Adventure/XTheatre3Node")

---@class XTheatre3Step
local XTheatre3Step = XClass(nil, "XTheatre3Step")

function XTheatre3Step:Ctor()
    self.Uid = 0
    self.RootUid = 0
    ---@type number XEnumConst.THEATRE3.StepType
    self.StepType = 0
    -- 是否选择过
    self.IsOver = false

    -- 道具箱选择数据
    self.SelectedItemId = 0
    self.ItemIds = {}

    -- 装备箱数据
    self.SelectedEquipId = 0
    self.EquipIds = {}

    -- 战斗结束数据
    ---@type XTheatre3NodeReward[]
    self.FightRewards = {}

    -- 装备工坊数据
    self.WorkShopId = 0
    ---@type number XEnumConst.THEATRE3.WorkShopType
    self.WorkShopType = 0
    self.WorkShopTotalCount = 0
    self.WorkShopCurCount = 0

    -- 节点数据
    ---@type XTheatre3Node
    self.NodeData = false
end

--region DataUpdate
function XTheatre3Step:UpdateItemIds(data)
    self.ItemIds = {}
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, id in ipairs(data) do
        self.ItemIds[#self.ItemIds + 1] = id
    end
end

function XTheatre3Step:UpdateEquipIds(data)
    self.EquipIds = {}
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, id in ipairs(data) do
        self.EquipIds[#self.EquipIds + 1] = id
    end
end

function XTheatre3Step:UpdateFightRewards(data)
    self.FightRewards = {}
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, reward in ipairs(data) do
        ---@type XTheatre3NodeReward
        local rewardData = XTheatre3NodeReward.New()
        rewardData:NotifyData(reward)
        self.FightRewards[#self.FightRewards + 1] = rewardData
    end
end

function XTheatre3Step:UpdateNodeData(data)
    self.NodeData = false
    if XTool.IsTableEmpty(data) then
        return
    end
    self.NodeData = XTheatre3Node.New()
    self.NodeData:NotifyData(data)
end

function XTheatre3Step:UpdateItemSelectId(itemSelectId)
    self.SelectedItemId = itemSelectId
end

function XTheatre3Step:UpdateEquipSelectId(equipSelectId)
    self.SelectedEquipId = equipSelectId
end

function XTheatre3Step:UpdateWorkShopTimes(times)
    self.WorkShopCurCount = times
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_THEATRE3_UPDATE_WORKSHOP_TIMES)
end

function XTheatre3Step:SetIsOver()
    self.IsOver = true
end

--endregion

--region Getter
function XTheatre3Step:GetUid()
    return self.Uid
end

function XTheatre3Step:GetEquipIds()
    return self.EquipIds
end

---@return XTheatre3Node
function XTheatre3Step:GetNodeData()
    return self.NodeData
end

---@return XTheatre3NodeSlot
function XTheatre3Step:GetLastNodeSlot()
    if not self.NodeData then
        return
    end
    for _, slot in ipairs(self.NodeData:GetNodeSlots()) do
        if slot:CheckIsSelected() then
            return slot
        end
    end
end

function XTheatre3Step:GetEquipIds()
    return self.EquipIds
end

function XTheatre3Step:GetSelectEquipId()
    return self.SelectedEquipId
end

function XTheatre3Step:GetItemIds()
    return self.ItemIds
end

function XTheatre3Step:GetSelectItemId()
    return self.SelectedItemId
end

---@return XTheatre3NodeReward[]
function XTheatre3Step:GetFightRewards()
    return self.FightRewards
end

function XTheatre3Step:GetSelectNodeId()
    if not self.NodeData then
        return 0
    end
    if self.NodeData:CheckIsSelect() then
        return self.NodeData:GetNodeId()
    end
    return 0
end
--endregion

--region Checker
---@param stepType number XEnumConst.THEATRE3.StepType
function XTheatre3Step:CheckStepType(stepType)
    return self.StepType == stepType
end

---@param workShopType number XEnumConst.THEATRE3.WorkShopType
function XTheatre3Step:CheckWorkShopType(workShopType)
    return self.WorkShopType == workShopType
end

function XTheatre3Step:CheckIsOver()
    return self.IsOver
end
--endregion

function XTheatre3Step:NotifyData(data)
    self.Uid = data.Uid
    self.RootUid = data.RootUid
    self.StepType = data.StepType
    self.IsOver = XTool.IsNumberValid(data.Overdue)
    -- 道具箱选择数据
    self:UpdateItemSelectId(data.SelectedItemId)
    self:UpdateItemIds(data.ItemIds)
    -- 装备箱
    self:UpdateEquipSelectId(data.SelectedEquipId)
    self:UpdateEquipIds(data.EquipIds)
    -- 战斗结束数据
    self:UpdateFightRewards(data.FightRewards)
    -- 装备工坊数据
    self.WorkShopId = data.WorkShopId
    self.WorkShopType = data.WorkShopType
    self.WorkShopTotalCount = data.WorkShopTotalCount
    self:UpdateWorkShopTimes(data.WorkShopCurCount)
    -- 下一步节点数据
    self:UpdateNodeData(data.NodeData)
end

return XTheatre3Step