local XUiSkyGardenShoppingStreetInsideBuildFood = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildFood")
local XUiSkyGardenShoppingStreetInsideBuildGoods = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildGoods")
local XUiSkyGardenShoppingStreetInsideBuildDessert = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildDessert")
---@class XUiSkyGardenShoppingStreetInsideBuildStrategy : XUiNode
---@field PanelFood UnityEngine.RectTransform
---@field PanelGoods UnityEngine.RectTransform
---@field PanelDessert UnityEngine.RectTransform
---@field TxtTips UnityEngine.UI.Text
---@field BtnSave XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetInsideBuildStrategy = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildStrategy")

function XUiSkyGardenShoppingStreetInsideBuildStrategy:Ctor()
    ---@type XUiSkyGardenShoppingStreetInsideBuildFood
    self.PanelFoodUi = nil
    ---@type XUiSkyGardenShoppingStreetInsideBuildGoods
    self.PanelGoodsUi = nil
    ---@type XUiSkyGardenShoppingStreetInsideBuildDessert
    self.PanelDessertUi = nil
end

--region 生命周期
function XUiSkyGardenShoppingStreetInsideBuildStrategy:OnStart(...)
    self:_RegisterButtonClicks()
end
--endregion
function XUiSkyGardenShoppingStreetInsideBuildStrategy:SetBuilding(pos, isInside)
    self._BuildPos = pos
    self._IsInside = isInside

    if self.PanelUi then self.PanelUi:Close() end
    
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local buildingConfig = self._Control:GetShopConfigById(shopAreaData:GetShopId(), self._IsInside)
    local shopType = XMVCA.XSkyGardenShoppingStreet.XSgStreetShopFuncType

    self.PanelFood.gameObject:SetActive(buildingConfig.FuncType == shopType.Food)
    self.PanelGoods.gameObject:SetActive(buildingConfig.FuncType == shopType.Grocery)
    self.PanelDessert.gameObject:SetActive(buildingConfig.FuncType == shopType.Dessert)

    if buildingConfig.FuncType == shopType.Food then
        self.PanelUi = XUiSkyGardenShoppingStreetInsideBuildFood.New(self.PanelFood, self)
    elseif buildingConfig.FuncType == shopType.Grocery then
        self.PanelUi = XUiSkyGardenShoppingStreetInsideBuildGoods.New(self.PanelGoods, self)
    elseif buildingConfig.FuncType == shopType.Dessert then
        self.PanelUi = XUiSkyGardenShoppingStreetInsideBuildDessert.New(self.PanelDessert, self)
    end

    self.PanelUi:SetBuilding(self._BuildPos, self._IsInside)
    self.TxtTips.text = buildingConfig.StrategyDesc
end

--region 按钮事件
function XUiSkyGardenShoppingStreetInsideBuildStrategy:OnBtnSaveClick()
    self.PanelUi:OnBtnSaveClick()
    self.Parent:Close()
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetInsideBuildStrategy:_RegisterButtonClicks()
    --在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnSave, self.OnBtnSaveClick, true)
end
--endregion

return XUiSkyGardenShoppingStreetInsideBuildStrategy
