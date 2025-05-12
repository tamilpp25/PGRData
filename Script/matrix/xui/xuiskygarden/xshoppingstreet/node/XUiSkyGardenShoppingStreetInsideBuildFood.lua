local XUiSkyGardenShoppingStreetInsideBuildSet = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildSet")
local XUiSkyGardenShoppingStreetInsideBuildFoodShow = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildFoodShow")

---@class XUiSkyGardenShoppingStreetInsideBuildFood : XUiNode
---@field PanelSetA UnityEngine.RectTransform
---@field PanelSetB UnityEngine.RectTransform
---@field PanelSetC UnityEngine.RectTransform
---@field PanelSetD UnityEngine.RectTransform
---@field PanelFood UnityEngine.RectTransform
---@field BtnMinus XUiComponent.XUiButton
---@field TxtNum UnityEngine.UI.Text
---@field BtnAdd XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetInsideBuildFood = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildFood")

local FoodUiKey2Obj = {
    [1] = {
        ObjectName = "PanelSetB",
        LuaName = "PanelSetBUi",
    },
    [2] = {
        ObjectName = "PanelSetC",
        LuaName = "PanelSetCUi",
    },
    [3] = {
        ObjectName = "PanelSetD",
        LuaName = "PanelSetDUi",
    },
}

function XUiSkyGardenShoppingStreetInsideBuildFood:OnStart()
    self:_RegisterButtonClicks()
    self.PanelFoodUi = XUiSkyGardenShoppingStreetInsideBuildFoodShow.New(self.PanelFood, self)
end

function XUiSkyGardenShoppingStreetInsideBuildFood:SetBuilding(pos, isInside)
    self._BuildPos = pos
    self._IsInside = isInside
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local buildingId = shopAreaData:GetShopId()
    local foodCfg = self._Control:GetShopFoodConfigsByShopId(buildingId)
    self._MinNum = foodCfg.GoldMin
    self._MaxNum = foodCfg.GoldMax

    local foodData = shopAreaData:GetFoodData()
    local curChefId, GoodsCountList
    if foodData then
        curChefId = foodData.ChefId
        self._Price = foodData.Gold
        GoodsCountList = foodData.GoodsCountList
    else
        self._Price = XMath.Clamp(foodCfg.InitGold, self._MinNum, self._MaxNum)
        GoodsCountList = {}
    end
    self._ChefIndex = 1
    if curChefId then
        for i = 1, #foodCfg.Chef do
            local chefId = foodCfg.Chef[i]
            if curChefId == chefId then
                self._ChefIndex = i
                break
            end
        end
    end

    self._TempGoods = {}
    for i = 1, #FoodUiKey2Obj do
        local uiconfig = FoodUiKey2Obj[i]
        local goodId = foodCfg.Goods[i]
        local hasGood = goodId ~= nil
        self[uiconfig.ObjectName].gameObject:SetActive(hasGood)
        if hasGood and not self[uiconfig.LuaName] then
            self[uiconfig.LuaName] = XUiSkyGardenShoppingStreetInsideBuildSet.New(self[uiconfig.ObjectName], self)
        end
        if hasGood then
            local cfg = self._Control:GetShopFoodGoodsConfigsByGoodId(goodId)
            self.PanelFoodUi:SetImageList(i, cfg.ImgPathGroup)
            self._TempGoods[i] = GoodsCountList[i] or cfg.GoodsInit
            local luaUiNode = self[uiconfig.LuaName]
            luaUiNode:SetUpdateCallback(function(index)
                luaUiNode:SetName(index)
                self._TempGoods[i] = index
                self:_UpdateFoodShow(i, index)
            end)
            luaUiNode:SetIcon(cfg.GoodsRes)
            luaUiNode:SetTilte(cfg.GoodsName)
            luaUiNode:SetIndex(self._TempGoods[i], cfg.GoodsMin, cfg.GoodsMax)
        end
    end

    local chiefImagePaths = {}
    local chiefNum = #foodCfg.Chef
    for i = 1, chiefNum do
        local chefId = foodCfg.Chef[i]
        local chefCfg = self._Control:GetShopFoodChefConfigsByChefId(chefId)
        chiefImagePaths[i] = chefCfg.ImgPath
    end
    self.PanelFoodUi:SetImageList(4, chiefImagePaths)

    self.PanelSetAUi = XUiSkyGardenShoppingStreetInsideBuildSet.New(self.PanelSetA, self)
    self.PanelSetAUi:SetUpdateCallback(function(index)
        local chefId = foodCfg.Chef[index]
        if not chefId then return end
        local chefCfg = self._Control:GetShopFoodChefConfigsByChefId(chefId)
        if not chefCfg then return end
        self.PanelSetAUi:SetName(chefCfg.ChefName)
        self._ChefIndex = index
        self.PanelFoodUi:SetChefSelect(index)
    end)
    self.PanelSetAUi:SetIndex(self._ChefIndex, 1, chiefNum, true)
    self:_UpdatePrice()
end

function XUiSkyGardenShoppingStreetInsideBuildFood:_UpdateFoodShow(index, count)
    self.PanelFoodUi:SetFoodSelect(index, count)
end

function XUiSkyGardenShoppingStreetInsideBuildFood:_UpdatePrice()
    self.TxtNum.text = self._Price
end

function XUiSkyGardenShoppingStreetInsideBuildFood:OnBtnSaveClick()
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local shopId = shopAreaData:GetShopId()
    local foodCfg = self._Control:GetShopFoodConfigsByShopId(shopId)
    self._Control:SgStreetShopSetupFoodRequest(shopId, foodCfg.Chef[self._ChefIndex], self._TempGoods, self._Price)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetInsideBuildFood:OnBtnMinusClick()
    local newPrice = XMath.Clamp(self._Price - 1, self._MinNum, self._MaxNum)
    if self._Price == newPrice then return end
    
    self._Price = newPrice
    self:_UpdatePrice()
end

function XUiSkyGardenShoppingStreetInsideBuildFood:OnBtnAddClick()
    local newPrice = XMath.Clamp(self._Price + 1, self._MinNum, self._MaxNum)
    if self._Price == newPrice then return end
    
    self._Price = newPrice
    self:_UpdatePrice()
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetInsideBuildFood:_RegisterButtonClicks()
    self.BtnMinus.CallBack = function() self:OnBtnMinusClick() end
    self.BtnAdd.CallBack = function() self:OnBtnAddClick() end
end
--endregion

return XUiSkyGardenShoppingStreetInsideBuildFood
