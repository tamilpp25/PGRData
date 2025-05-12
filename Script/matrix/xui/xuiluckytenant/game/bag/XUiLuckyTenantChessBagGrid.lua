---@class XUiLuckyTenantChessBagGrid : XUiNode
---@field _Control XLuckyTenantControl
local XUiLuckyTenantChessBagGrid = XClass(XUiNode, "XUiLuckyTenantChessBagGrid")

function XUiLuckyTenantChessBagGrid:OnStart()
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.Button, self._OnClick, nil, true)
end

---@param data XUiLuckyTenantChessBagGridData
function XUiLuckyTenantChessBagGrid:Update(data)
    self._Data = data
    if data.IsDirty then
        self.TxtName.text = data.Name
        self.ImgQuality:SetSprite(data.Quality)
        self.RImgIcon:SetRawImage(data.Icon)
        self.TxtCost.text = data.Value
        if data.Round then
            self.TxtRound.text = data.Round
            self.PanelRound.gameObject:SetActive(true)
        else
            self.PanelRound.gameObject:SetActive(false)
        end
    end
    self.Select.gameObject:SetActiveEx(data.IsSelected)
end

function XUiLuckyTenantChessBagGrid:_OnClick()
    self._Control:SelectBagPiece(self._Data)
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT_UPDATE_BAG)
end

return XUiLuckyTenantChessBagGrid