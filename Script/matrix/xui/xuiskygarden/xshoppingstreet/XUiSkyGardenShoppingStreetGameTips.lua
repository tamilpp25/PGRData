---@class XUiSkyGardenShoppingStreetGameTips : XLuaUi
local XUiSkyGardenShoppingStreetGameTips = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetGameTips")

--region 生命周期
function XUiSkyGardenShoppingStreetGameTips:OnStart(text, pos)
    self.TxtDetail.text = text
    self.GridBuffDetail.transform.position = pos
    XUiManager.CreateBlankArea2Close(self.GridBuffDetail.gameObject, function ()
        self:Close()
    end)
end
--endregion

return XUiSkyGardenShoppingStreetGameTips
