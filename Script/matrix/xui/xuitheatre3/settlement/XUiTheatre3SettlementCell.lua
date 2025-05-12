---@class XUiTheatre3SettlementCell : XUiNode 套装展示子UI
---@field _Control XTheatre3Control
local XUiTheatre3SettlementCell = XClass(XUiNode, "XUiTheatre3SettlementCell")

function XUiTheatre3SettlementCell:OnStart()
    self.ItemGrid.CallBack = handler(self, self.OnClick)
end

function XUiTheatre3SettlementCell:SetData(itemId)
    self._ItemId = itemId
    self._ItemConfig = self._Control:GetItemConfigById(itemId)
    if self.RawImage then
        self.RawImage.gameObject:SetActiveEx(true)
        self.RawImage:SetRawImage(self._Control:GetItemBgUrlById(itemId))
        self.ImageRed.gameObject:SetActiveEx(false)
    end
    XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, self._ItemConfig.Quality)
    self.RImgIcon:SetRawImage(self._ItemConfig.Icon)
end

function XUiTheatre3SettlementCell:SetState(state)
    self.ItemGrid:SetButtonState(state)
end

function XUiTheatre3SettlementCell:OnClick()
    self._Control:OpenAdventureTips(self._ItemId, XEnumConst.THEATRE3.EventStepItemType.InnerItem)
end

return XUiTheatre3SettlementCell