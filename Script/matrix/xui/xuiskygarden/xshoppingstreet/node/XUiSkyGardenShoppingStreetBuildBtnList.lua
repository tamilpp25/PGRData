local XUiSkyGardenShoppingStreetBuildBtn = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetBuildBtn")

---@class XUiSkyGardenShoppingStreetBuildBtnList : XUiNode
---@field ImgAttribute UnityEngine.UI.Image
---@field TxtDetailNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetBuildBtnList = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuildBtnList")

function XUiSkyGardenShoppingStreetBuildBtnList:OnStart()
    self._BuildingBtn = {}
end

function XUiSkyGardenShoppingStreetBuildBtnList:GetBtns()
    return self._BuildingBtn
end

function XUiSkyGardenShoppingStreetBuildBtnList:OnGridBuildClick(...)
    if self.Parent.SelectBuilding then
        self.Parent:SelectBuilding(...)
    end
end

function XUiSkyGardenShoppingStreetBuildBtnList:Update(data)
    if #data.ShopConfigs <= 0 then
        self:Close()
        return
    end
    local resCfgs = self._Control:GetStageResConfigs()
    local resCfg = resCfgs[data.SortType + XMVCA.XSkyGardenShoppingStreet.XShopBuildShowTypeBase]
    self.TxtTag.text = resCfg.Name
    self.ListBuild.color = XUiHelper.Hexcolor2Color(resCfg.IconColor)
    self.ImgBg.color = XUiHelper.Hexcolor2Color(resCfg.IconColor)
    XTool.UpdateDynamicItem(self._BuildingBtn, data.ShopConfigs, self.GridBuild, XUiSkyGardenShoppingStreetBuildBtn, self)
end

return XUiSkyGardenShoppingStreetBuildBtnList
