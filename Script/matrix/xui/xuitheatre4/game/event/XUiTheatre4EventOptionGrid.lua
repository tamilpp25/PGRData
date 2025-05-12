---@class XUiTheatre4EventOptionGrid : XUiNode
---@field _Control XTheatre4Control
---@field BtnOption XUiComponent.XUiButton
local XUiTheatre4EventOptionGrid = XClass(XUiNode, "XUiTheatre4EventOptionGrid")

function XUiTheatre4EventOptionGrid:GetOptionId()
    return self.OptionId
end

function XUiTheatre4EventOptionGrid:Refresh(optionId)
    self.OptionId = optionId
    -- 按钮文本
    local content = self._Control:GetEventOptionDesc(optionId)
    self.BtnOption:SetNameByGroup(0, content)
    -- 道具 只有一个道具
    self.PanelItem.gameObject:SetActiveEx(false)
    local itemType = self._Control:GetEventOptionItemType(optionId)
    if XTool.IsNumberValid(itemType) then
        local itemId = self._Control:GetEventOptionItemId(optionId)
        local itemCount = self._Control:GetEventOptionItemCount(optionId)
        self:UpdateItemPanel(itemType, itemId, itemCount)
        return
    end
    local assetType, assetId, changeCount = self._Control.EffectSubControl:GetChangeAssetCountByEventOptionId(optionId)
    if XTool.IsNumberValid(assetType) then
        self:UpdateItemPanel(assetType, assetId, changeCount)
        return
    end
end

function XUiTheatre4EventOptionGrid:UpdateItemPanel(itemType, itemId, itemCount)
    self.PanelItem.gameObject:SetActiveEx(true)
    local typeIcon = self._Control.AssetSubControl:GetAssetIcon(itemType, itemId)
    local gridUi = XTool.InitUiObjectByUi({}, self.GridIcon)
    if typeIcon then
        gridUi.Icon:SetRawImage(typeIcon)
    end
    gridUi.Text.text = itemCount
end

return XUiTheatre4EventOptionGrid
