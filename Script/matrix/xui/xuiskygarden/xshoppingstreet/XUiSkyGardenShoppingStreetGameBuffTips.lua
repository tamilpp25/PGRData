---@class XUiSkyGardenShoppingStreetGameBuffTips : XLuaUi
local XUiSkyGardenShoppingStreetGameBuffTips = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetGameBuffTips")
local XUiSkyGardenShoppingStreetBuffDetailGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuffDetailGrid")

--region 生命周期
function XUiSkyGardenShoppingStreetGameBuffTips:OnAwake()
    self._GridBuffDetailUi = XUiSkyGardenShoppingStreetBuffDetailGrid.New(self.GridBuffDetail, self)
end

function XUiSkyGardenShoppingStreetGameBuffTips:OnStart(buffId, pos)
    self._GridBuffDetailUi:Update({
        BuffId = buffId,
    })
    self.GridBuffDetail.transform.position = pos
    XUiManager.CreateBlankArea2Close(self.GridBuffDetail.gameObject, function ()
        self:Close()
    end)
end
--endregion

return XUiSkyGardenShoppingStreetGameBuffTips
