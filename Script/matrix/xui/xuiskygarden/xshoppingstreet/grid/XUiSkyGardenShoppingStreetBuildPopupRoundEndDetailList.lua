local XUiSkyGardenShoppingStreetBuildPopupRoundEndDetail = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuildPopupRoundEndDetail")

---@class XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList : XUiNode
local XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList")

function XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList:OnStart()
    self._BuildingBtn = {}
end

function XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList:Update(data)
    XTool.UpdateDynamicItem(self._BuildingBtn, data, self.GridDetail, XUiSkyGardenShoppingStreetBuildPopupRoundEndDetail, self)
end

return XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList
