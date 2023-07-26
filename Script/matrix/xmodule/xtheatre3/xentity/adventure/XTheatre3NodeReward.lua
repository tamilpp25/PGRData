---@class XTheatre3NodeReward
local XTheatre3NodeReward = XClass(nil, "XTheatre3NodeReward")

function XTheatre3NodeReward:Ctor()
    self.Uid = 0
    ---@type number XEnumConst.THEATRE3.NodeRewardType
    self.RewardType = 0
    ---Theatre3ItemBox表的ID
    self.ConfigId = 0
    self.Count = 0
    self.Received = false
    ---是否显示在节点界面
    self.IsShow = false
    self.IsHard = false
end

function XTheatre3NodeReward:SetIsHard(value)
    self.IsHard = value
end

--region Getter
function XTheatre3NodeReward:GetUid()
    return self.Uid
end

function XTheatre3NodeReward:GetConfigId()
    return self.ConfigId
end

function XTheatre3NodeReward:GetCount()
    return self.Count
end

function XTheatre3NodeReward:GetType()
    return self.RewardType
end

function XTheatre3NodeReward:GetEventStepType()
    local itemType = XEnumConst.THEATRE3.EventStepItemType.OutSideItem
    if self:CheckType(XEnumConst.THEATRE3.NodeRewardType.EquipBox) then
        itemType = XEnumConst.THEATRE3.EventStepItemType.EquipBox
    elseif self:CheckType(XEnumConst.THEATRE3.NodeRewardType.ItemBox) then
        itemType = XEnumConst.THEATRE3.EventStepItemType.ItemBox
    end
    return itemType
end

function XTheatre3NodeReward:GetEventStepTemplateId()
    if self:CheckType(XEnumConst.THEATRE3.NodeRewardType.Gold) then
        return XEnumConst.THEATRE3.Theatre3InnerCoin
    end
    return self:GetConfigId()
end

function XTheatre3NodeReward:GetIsHard()
    return self.IsHard
end
--endregion

--region Checker
function XTheatre3NodeReward:CheckIsReceived()
    return self.Received
end

function XTheatre3NodeReward:CheckIsShow()
    return self.IsShow
end

---@param type number XEnumConst.THEATRE3.NodeRewardType
function XTheatre3NodeReward:CheckType(type)
    return self.RewardType == type
end
--endregion

function XTheatre3NodeReward:NotifyData(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    self.Uid = data.Uid
    self.RewardType = data.RewardType
    self.ConfigId = data.ConfigId
    self.Count = data.Count
    self.Received = XTool.IsNumberValid(data.Received)
    self.IsShow = XTool.IsNumberValid(data.IsShow)
end

return XTheatre3NodeReward