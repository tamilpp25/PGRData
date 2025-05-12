
---@class XUiGridBenchProduct : XUiNode
---@field _Control XRestaurantControl
local XUiGridBenchProduct = XClass(XUiNode, "XUiGridBenchProduct")

function XUiGridBenchProduct:OnStart(onClick)
    self.OnClick = onClick
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
    self:SetSelect(false)
end

--- 格子刷新
---@param product XRestaurantProductVM
---@return void
--------------------------
function XUiGridBenchProduct:Refresh(product, areaType, selectId, isUrgent)
    if not product then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.Product = product
    local unlock = product:IsUnlock()
    self.PanelDisable.gameObject:SetActiveEx(not unlock)
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    self.TxtName.text = product:GetName()
    
    local isHot = product:IsHotSale()
    
    self.PanelHot.gameObject:SetActiveEx(isHot and not isUrgent)
    self.PanelUrgent.gameObject:SetActiveEx(isUrgent)
    
    self.TxtInventory.text = product:GetCountDesc(1)
    self.ImgFull.gameObject:SetActiveEx(product:IsFull())
    
    local isIngredientArea = self._Control:IsIngredientArea(areaType)
    self.TxtExpenditure.gameObject:SetActiveEx(not isIngredientArea)
    if not isIngredientArea then
        self.RImgCurrency.gameObject:SetActiveEx(true)
        self.TxtExpenditure.text = product:GetSellPrice()
        local icon = XDataCenter.ItemManager.GetItemIcon(XMVCA.XRestaurant.ItemId.RestaurantUpgradeCoin)
        self.RImgCurrency:SetRawImage(icon)
    end
    local productId = product:GetProductId()
    self.ImgQualityBg:SetSprite(product:GetQualityIcon(false))
    self:SetSelect(productId == selectId)
end

function XUiGridBenchProduct:SetSelect(select)
    self.IsSelect = select
    self.ImgNormal.gameObject:SetActiveEx(not select)
    self.ImgSelect.gameObject:SetActiveEx(select)
end

function XUiGridBenchProduct:OnBtnClick()
    if not self.Product or self.IsSelect then
        return
    end
    local unlock = self.Product:IsUnlock()
    if not unlock then
        XUiManager.TipText("NotUnlock")
        return
    end
 
    self:SetSelect(true)
    if self.OnClick then self.OnClick(self) end
end

return XUiGridBenchProduct