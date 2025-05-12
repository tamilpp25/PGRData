---@class XUiSkyGardenShoppingStreetBuffDetailGrid : XUiNode
---@field TxtNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetBuffDetailGrid = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuffDetailGrid")
local XUiSkyGardenShoppingStreetBuffGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuffGrid")

--region 生命周期
function XUiSkyGardenShoppingStreetBuffDetailGrid:OnStart(...)
    self.GridBuffBubbleBuffDetailUI = XUiSkyGardenShoppingStreetBuffGrid.New(self.GridBuffBubbleBuffDetail, self)
    self.GridBuffBubbleBuffDetailUI:Close()
end

function XUiSkyGardenShoppingStreetBuffDetailGrid:OnDisable()
    self.GridBuffBubbleBuffDetailUI:Close()
end

function XUiSkyGardenShoppingStreetBuffDetailGrid:Update(data, i)
    local buffId = 0
    if data.BuffId then
        buffId = data.BuffId
    else
        buffId = data.Id
    end
    self.TxtDetail.text = self._Control:ParseBuffDescById(buffId)
    self.GridBuffBubbleBuffDetailUI:Update(data, i)
    self.GridBuffBubbleBuffDetailUI:Open()
end

function XUiSkyGardenShoppingStreetBuffDetailGrid:SetClickCallback(cb)
    self.GridBuffBubbleBuffDetailUI:SetClickCallback(cb)
end
--endregion

return XUiSkyGardenShoppingStreetBuffDetailGrid
