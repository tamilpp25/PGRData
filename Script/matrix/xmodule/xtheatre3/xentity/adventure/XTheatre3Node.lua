local XTheatre3NodeSlot = require("XModule/XTheatre3/XEntity/Adventure/XTheatre3NodeSlot")

---@class XTheatre3Node
local XTheatre3Node = XClass(nil, "XTheatre3Node")

function XTheatre3Node:Ctor()
    self.NodeId = 0
    ---@type XTheatre3NodeSlot[]
    self.Slots = {}
    self.IsSelect = false
end

--region DataUpdate
function XTheatre3Node:UpdateSlot(slotList)
    self.Slots = {}
    if XTool.IsTableEmpty(slotList) then
        return
    end
    for _, slot in ipairs(slotList) do
        ---@type XTheatre3NodeSlot
        local nodeSlot = XTheatre3NodeSlot.New()
        nodeSlot:NotifyData(slot)
        if nodeSlot.IsSelected then
            self.IsSelect = true
        end
        self.Slots[#self.Slots + 1] = nodeSlot
    end
end

---@param slot XTheatre3NodeSlot
function XTheatre3Node:SetSelect(slot)
    for _, nodeSlot in ipairs(self.Slots) do
        if nodeSlot:GetSlotId() == slot:GetSlotId() then
            nodeSlot:SetSelect()
            self.IsSelect = true
        end
    end
end
--endregion

--region Getter
---@return XTheatre3NodeSlot[]
function XTheatre3Node:GetNodeSlots()
    return self.Slots
end

function XTheatre3Node:GetNodeId()
    return self.NodeId
end
--endregion

--region Checker
function XTheatre3Node:CheckIsSelect()
    return self.IsSelect
end
--endregion

function XTheatre3Node:NotifyData(data)
    self.NodeId = data.NodeId
    self:UpdateSlot(data.Slots)
end

return XTheatre3Node