---@class XUiLuckyTenantMainDetailGrid : XUiNode
---@field _Control XLuckyTenantControl
local XUiLuckyTenantMainDetailGrid = XClass(XUiNode, "XUiLuckyTenantMainDetailGrid")

function XUiLuckyTenantMainDetailGrid:OnStart()
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.Button, self._OnClick, nil, true)
end

---@param data XUiLuckyTenantChessGridData
function XUiLuckyTenantMainDetailGrid:Update(data)
    self._Data = data
    if data.IsDirty then
        self.TxtName.text = data.Name
        self.ImgQuality:SetSprite(data.Quality)
        self.RImgIcon:SetRawImage(data.Icon)
        self.TxtCost.text = data.Value
    end
    if self.TxtAmount then
        self.TxtAmount.text = "x" .. data.Amount
    end
end

function XUiLuckyTenantMainDetailGrid:_OnClick()
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT_OPEN_DETAIL, self._Data)
end

return XUiLuckyTenantMainDetailGrid