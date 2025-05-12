---@class XUiSkyGardenShoppingStreetInsideBuildBase : XUiNode
---@field TxtNum UnityEngine.UI.Text
---@field TxtTips UnityEngine.UI.Text
---@field GridAttribute UnityEngine.RectTransform
---@field ImgBar UnityEngine.UI.Image
---@field TxtScore UnityEngine.UI.Text
---@field BtnDetele XUiComponent.XUiButton
---@field BtnUpgrade XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetInsideBuildBase = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildBase")

local XUiSkyGardenShoppingStreetBuildGridAttribute = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuildGridAttribute")

--region 生命周期
function XUiSkyGardenShoppingStreetInsideBuildBase:OnStart()
    self:_RegisterButtonClicks()
    self._BuildingAttrs = {}
end

--endregion
function XUiSkyGardenShoppingStreetInsideBuildBase:SetBuilding(pos, isInside)
    self._ShopUiPos = pos
    self._IsInside = isInside

    local shopAreaData = self._Control:GetShopAreaByUiPos(pos, isInside)
    local shopId = shopAreaData:GetShopId()
    local config = self._Control:GetShopConfigById(shopId, isInside)

    local lv = shopAreaData:GetShopLevel()
    self.TxtNum.text = lv
    self.TxtTitle.text = config.Name
    self.TxtTips.text = config.AccountDesc

    local isShowScore = config.SortType == 1
    self.PanelScore.gameObject:SetActive(isShowScore)
    if isShowScore then
        local maxShopScore = tonumber(self._Control:GetGlobalConfigByKey("MaxShopScore"))
        local score = shopAreaData:GetShopScore()
        self.TxtScore.text = XTool.MathGetRoundingValueStandard(score, 1)
        self.ImgBar.fillAmount = score / maxShopScore
    end

    local attrData = self._Control:GetShopAttributes(shopId, 1, self._IsInside)
    XTool.UpdateDynamicItem(self._BuildingAttrs, attrData, self.GridAttribute, XUiSkyGardenShoppingStreetBuildGridAttribute, self)

    self.BtnDetele.gameObject:SetActive(self._IsInside and not shopAreaData:IsBuildByInit())

    local isMaxLv = self._Control:GetShopMaxLevel(shopId) <= lv
    self.BtnUpgrade.gameObject:SetActive(not isMaxLv)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetInsideBuildBase:OnBtnDeteleClick()
    self._Control:DestroyShop(self._ShopUiPos, self._IsInside, function (areaId)
        self.Parent:OnDestroyShop(areaId)
    end)
end

function XUiSkyGardenShoppingStreetInsideBuildBase:OnBtnUpgradeClick()
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetUpgrade", self._ShopUiPos, self._IsInside)
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetInsideBuildBase:_RegisterButtonClicks()
    --在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnDetele, self.OnBtnDeteleClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnUpgrade, self.OnBtnUpgradeClick, true)
end

--endregion

return XUiSkyGardenShoppingStreetInsideBuildBase
