local XUiSkyGardenShoppingStreetNewsMsgGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetNewsMsgGrid")

---@class XUiSkyGardenShoppingStreetNewsListGrid : XUiNode
local XUiSkyGardenShoppingStreetNewsListGrid = XClass(XUiNode, "XUiSkyGardenShoppingStreetNewsListGrid")

--region 生命周期
function XUiSkyGardenShoppingStreetNewsListGrid:OnStart(...)
    self._LogList = {}
end

function XUiSkyGardenShoppingStreetNewsListGrid:Refresh(i, data)
    self.TxtTime.text = XMVCA.XBigWorldService:GetText("SG_SS_RoundText", data.Turn)
    XTool.UpdateDynamicItem(self._LogList, data.Msgs, self.PanelNews, XUiSkyGardenShoppingStreetNewsMsgGrid, self.Parent)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Transform)
end
--endregion

return XUiSkyGardenShoppingStreetNewsListGrid
