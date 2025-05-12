local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")
---@class XUiTheatre4EventReward : XUiNode
---@field _Control XTheatre4Control
---@field Parent XUiTheatre4Event
---@field BtnSure XUiComponent.XUiButton
local XUiTheatre4EventReward = XClass(XUiNode, "XUiTheatre4EventReward")

function XUiTheatre4EventReward:OnStart()
    self._Control:RegisterClickEvent(self, self.BtnSure, self.OnBtnSureClick)
    self.GridProp.gameObject:SetActiveEx(false)
    ---@type XUiGridTheatre4Prop[]
    self.GridPropList = {}
end

function XUiTheatre4EventReward:Refresh(eventId)
    self.EventId = eventId
    -- 描述
    self.TxtContent.text = self._Control:GetEventDesc(eventId)
    -- 按钮文本
    local confirmContent = self._Control:GetEventConfirmContent(eventId)
    self.BtnSure:SetNameByGroup(0, confirmContent)
    -- 奖励
    local rewardIds = self._Control:GetEventRewardIds(eventId)
    if XTool.IsTableEmpty(rewardIds) then
        self.PanelIcon.gameObject:SetActiveEx(false)
        return
    end
    self.PanelIcon.gameObject:SetActiveEx(true)
    local index = 0
    for i, rewardId in ipairs(rewardIds) do
        local itemData = self:GetItemData(rewardId)
        local isValid = true
        if itemData.Type == XEnumConst.Theatre4.AssetType.ColorCostPoint
                or itemData.Type == XEnumConst.Theatre4.AssetType.AwakeningPoint then
            if not self._Control.EffectSubControl:GetEffectAwakeAvailable() then
                isValid = false
            end
        end
        if isValid then
            index = index + 1
            local item = self.GridPropList[index]
            if not item then
                local go = XUiHelper.Instantiate(self.GridProp, self.PanelIcon)
                item = XUiGridTheatre4Prop.New(go, self)
                self.GridPropList[index] = item
            end
            item:Open()
            item:Refresh(itemData)
        end
    end
    if index == 0 then
        self.PanelIcon.gameObject:SetActiveEx(false)
        return
    end
    for i = #rewardIds + 1, #self.GridPropList do
        self.GridPropList[i]:Close()
    end
end

function XUiTheatre4EventReward:GetItemData(rewardId)
    return {
        Id = self._Control:GetRewardElementId(rewardId),
        Type = self._Control:GetRewardElementType(rewardId),
        Count = self._Control:GetRewardElementCount(rewardId),
    }
end

function XUiTheatre4EventReward:OnBtnSureClick()
    self.Parent:HandleEvent()
end

return XUiTheatre4EventReward
