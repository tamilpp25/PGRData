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
    self.ItemIds = {}
    self.SelectedItemId = 0

    -- 装备箱数据
    self._EquipBoxId = 0
    self._EquipBoxType = 0
    self.EquipIds = {}
    self.SelectedEquipId = 0

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
    ---@type XTheatre3Node
    self._ConnectNodeData = false
    
    -- 天选角色
    self._LuckCharacterIdList = {}
end

function XTheatre3Step:SetIsOver()
    self.IsOver = true
end

function XTheatre3Step:GetUid()
    return self.Uid
end

function XTheatre3Step:GetRootUid()
    return self.RootUid
end

--region Step - ItemBox
function XTheatre3Step:UpdateItemIds(data)
    self.ItemIds = {}
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, id in ipairs(data) do
        self.ItemIds[#self.ItemIds + 1] = id
    end
end

function XTheatre3Step:UpdateItemSelectId(itemSelectId)
    self.SelectedItemId = itemSelectId
end

function XTheatre3Step:GetItemIds()
    return self.ItemIds
end

function XTheatre3Step:GetSelectItemId()
    return self.SelectedItemId
end
--endregion

--region Step - EquipBox
function XTheatre3Step:UpdateEquipIds(data)
    self.EquipIds = {}
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, id in ipairs(data) do
        self.EquipIds[#self.EquipIds + 1] = id
    end
end

function XTheatre3Step:UpdateEquipBox(boxId, type)
    self._EquipBoxId = boxId
    self._EquipBoxType = type
end

function XTheatre3Step:UpdateEquipSelectId(equipSelectId)
    self.SelectedEquipId = equipSelectId
end

function XTheatre3Step:GetEquipIds()
    return self.EquipIds
end

function XTheatre3Step:GetSelectEquipId()
    return self.SelectedEquipId
end
--endregion

--region Step - FightReward
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

---@return XTheatre3NodeReward[]
function XTheatre3Step:GetFightRewards()
    return self.FightRewards
end
--endregion

--region Step - NodeSelect
function XTheatre3Step:UpdateNodeData(data)
    self.NodeData = false
    if XTool.IsTableEmpty(data) then
        return
    end
    self.NodeData = XTheatre3Node.New()
    self.NodeData:NotifyData(data)
end

function XTheatre3Step:UpdateConnectNodeData(data)
    self._ConnectNodeData = false
    if XTool.IsTableEmpty(data) then
        return
    end
    self._ConnectNodeData = XTheatre3Node.New()
    self._ConnectNodeData:NotifyData(data)
end

function XTheatre3Step:GetCurNodeData(curChapterId)
    if self.NodeData and self.NodeData:GetChapterId() == curChapterId then
        return self.NodeData
    end
    if self._ConnectNodeData and self._ConnectNodeData:GetChapterId() == curChapterId then
        return self._ConnectNodeData
    end
    return self.NodeData
end

function XTheatre3Step:GetCurOtherNodeData(curChapterId)
    if self.NodeData and self.NodeData:GetChapterId() ~= curChapterId then
        return self.NodeData
    end
    if self._ConnectNodeData and self._ConnectNodeData:GetChapterId() ~= curChapterId then
        return self._ConnectNodeData
    end
    return self.NodeData
end

function XTheatre3Step:GetSelectNodeId()
    if not self.NodeData and not self._ConnectNodeData then
        return 0
    end
    if self.NodeData:CheckIsSelect() then
        return self.NodeData:GetNodeId()
    end
    if self._ConnectNodeData:CheckIsSelect() then
        return self._ConnectNodeData:GetNodeId()
    end
    return 0
end

function XTheatre3Step:GetSelectNodeData()
    if self.NodeData and self.NodeData:CheckIsSelect() then
        return self.NodeData
    end
    if self._ConnectNodeData and self._ConnectNodeData:CheckIsSelect() then
        return self._ConnectNodeData
    end
    return self.NodeData
end

---@return XTheatre3NodeSlot
function XTheatre3Step:GetLastNodeSlot()
    local nodeData = self:GetSelectNodeData()
    if not nodeData then
        return
    end
    for _, slot in ipairs(nodeData:GetNodeSlots()) do
        if slot:CheckIsSelected() then
            return slot
        end
    end
end
--endregion

--region Step - WorkShop
function XTheatre3Step:UpdateWorkShopTimes(times)
    self.WorkShopCurCount = times
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_UPDATE_WORKSHOP_TIMES)
end
--endregion

--region Step - LuckCharacter
function XTheatre3Step:UpdateLuckCharacterIdList(data)
    self._LuckCharacterIdList = data
end

function XTheatre3Step:GetLuckCharacterIdList()
    return self._LuckCharacterIdList
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

---@param equipBoxType number XEnumConst.THEATRE3.EquipBoxType
function XTheatre3Step:CheckEquipBoxType(equipBoxType)
    return self._EquipBoxType == equipBoxType
end

function XTheatre3Step:CheckIsOver()
    return self.IsOver
end

function XTheatre3Step:CheckStepIsPass(eventStepId)
    if self.NodeData then
        for _, nodeSlot in pairs(self.NodeData:GetNodeSlots()) do
            if nodeSlot:CheckStepIsPass(eventStepId) then
                return true
            end
        end
    end
    if self._ConnectNodeData then
        for _, nodeSlot in pairs(self._ConnectNodeData:GetNodeSlots()) do
            if nodeSlot:CheckStepIsPass(eventStepId) then
                return true
            end
        end
    end
    return false
end

function XTheatre3Step:CheckIsHaveOtherChapter(curChapterId)
    if self.NodeData and self.NodeData:GetChapterId() ~= curChapterId then
        return self.NodeData:CheckIsHaveSlot()
    end
    if self._ConnectNodeData and self._ConnectNodeData:GetChapterId() ~= curChapterId then
        return self._ConnectNodeData:CheckIsHaveSlot()
    end
    return false
end

function XTheatre3Step:CheckIsSelected()
    if self.NodeData and self.NodeData:CheckIsSelect() then
        return true
    end
    if self._ConnectNodeData and self._ConnectNodeData:CheckIsSelect() then
        return true
    end
    return false
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
    self:UpdateEquipBox(data.EquipBoxId, data.EquipBoxType)
    -- 战斗结束数据
    self:UpdateFightRewards(data.FightRewards)
    -- 装备工坊数据
    self.WorkShopId = data.WorkShopId
    self.WorkShopType = data.WorkShopType
    self.WorkShopTotalCount = data.WorkShopTotalCount
    self:UpdateWorkShopTimes(data.WorkShopCurCount)
    -- 下一步节点数据
    self:UpdateNodeData(data.NodeData)
    -- 并行路线
    self:UpdateConnectNodeData(data.ConnectNodeData)
    -- 天选角色
    self:UpdateLuckCharacterIdList(data.DestinyCharacterIds)
end

return XTheatre3Step