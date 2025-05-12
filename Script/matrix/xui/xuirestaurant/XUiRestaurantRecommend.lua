local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiGridHotSale : XUiNode
---@field _Control XRestaurantControl
local XUiGridHotSale = XClass(XUiNode, "XUiGridHotSale")

function XUiGridHotSale:OnStart()
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
    self.BtnClick.gameObject:SetActiveEx(true)
end

function XUiGridHotSale:Refresh(data)
    local id, addition = data.Id, data.Addition
    ---@type XRestaurantFoodVM
    local food = self._Control:GetProduct(XMVCA.XRestaurant.AreaType.FoodArea, id)
    local additionByLv = food:GetRestaurantLvAddition()
    addition = addition + additionByLv
    self.TxtName.text = food:GetName()
    self.RImgIcon:SetRawImage(food:GetProductIcon())
    local isShowSaleRate = addition ~= 0
    self.PanelLabel.gameObject:SetActiveEx(isShowSaleRate)
    if isShowSaleRate then
        addition = addition > 0 and string.format("+%s%%", addition) or string.format("%s%%", addition)
        self.TxtSaleRate.text = addition
    end
    self.RImgCoinIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XMVCA.XRestaurant.ItemId.RestaurantUpgradeCoin))
    self.TxtPrice.text = food:GetSellPrice()
    local isLock = not food:IsUnlock()
    self.PanelLock.gameObject:SetActiveEx(isLock)
    self.PanelNormal.gameObject:SetActiveEx(not isLock)
    if isLock then
        self.TxtCondition.text = food:GetLockDescription()
    end
    self.FoodId = id
end

function XUiGridHotSale:OnBtnClick()
    local foodId = self.FoodId
    if not XTool.IsNumberValid(foodId) then
        return
    end
    local product = self._Control:GetProduct(XMVCA.XRestaurant.AreaType.FoodArea, foodId)
    if product:IsUnlock() then
        return
    end
    local performId = product:GetPerformId()
    local perform = self._Control:GetPerform(performId)
    if perform:IsNotStart() then
        XUiManager.TipMsg(perform:GetUnlockText())
        return
    end
    self._Control:DoClickLockPerform(performId, function()
        self.Parent:Close()
    end)
end

---@class XUiRestaurantRecommend : XLuaUi
---@field _Control XRestaurantControl
local XUiRestaurantRecommend = XLuaUiManager.Register(XLuaUi, "UiRestaurantRecommend")

function XUiRestaurantRecommend:OnAwake()
    self:InitCb()
    self:InitUi()
end

function XUiRestaurantRecommend:OnStart()
    self:InitView()
end

function XUiRestaurantRecommend:OnDestroy()
    self._Control:GetBusiness():ClearBind(self.GameObject:GetHashCode())
end

function XUiRestaurantRecommend:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelShopList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridHotSale, self)
    self.GridItem.gameObject:SetActiveEx(false)
end 

function XUiRestaurantRecommend:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end
end 

function XUiRestaurantRecommend:InitView()
    local business = self._Control:GetBusiness()
    business:BindViewModelPropertyToObj(self.GameObject:GetHashCode(), business.Property.CurDay, function(day)
        self:SetupDynamicTable(day)
    end)
end 

function XUiRestaurantRecommend:SetupDynamicTable(day)
    local list = self._Control:GetBusiness():GetHotSaleDataList(day)
    self.DataList = self:SortHotSaleList(list)
    if self.PanelEmpty then
        self.PanelEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.DataList))
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end 

function XUiRestaurantRecommend:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    end
end 

function XUiRestaurantRecommend:SortHotSaleList(list)
    if XTool.IsTableEmpty(list) then
        return {}
    end
    ---@type XRestaurantFoodVM[]
    local tempList = {}
    local foodArea = XMVCA.XRestaurant.AreaType.FoodArea
    for _, data in ipairs(list) do
        local product = self._Control:GetProduct(foodArea, data.Id)
        if product and product:IsUnlockByLevel() then
            table.insert(tempList, data)
        end
    end
    local control = self._Control
    table.sort(tempList, function(a, b)
        local productA = control:GetProduct(foodArea, a.Id)
        local productB = control:GetProduct(foodArea, b.Id)
        local unlockA = productA:IsUnlock()
        local unlockB = productB:IsUnlock()

        if unlockA ~= unlockB then
            return unlockA
        end

        local priceA = productA:GetFoodBaseSellPrice()
        local priceB = productB:GetFoodBaseSellPrice()

        if priceA ~= priceB then
            return priceA > priceB
        end
        
        return a.Id < b.Id
    end)
    
    return tempList
end 