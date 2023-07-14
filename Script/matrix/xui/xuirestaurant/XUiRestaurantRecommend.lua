local XUiGridHotSale = XClass(nil, "XUiGridHotSale")

function XUiGridHotSale:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridHotSale:Refresh(data)
    local id, addition = data.Id, data.Addition
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local additionByLv = XRestaurantConfigs.GetHotSaleAdditionByRestaurantLevel(viewModel:GetProperty("_Level"))
    addition = addition + additionByLv
    self.TxtName.text = XRestaurantConfigs.GetFoodName(id)
    self.RImgIcon:SetRawImage(XRestaurantConfigs.GetFoodIcon(id))
    local isShowSaleRate = addition ~= 0
    self.PanelLabel.gameObject:SetActiveEx(isShowSaleRate)
    if isShowSaleRate then
        addition = addition > 0 and string.format("+%s%%", addition) or string.format("%s%%", addition)
        self.TxtSaleRate.text = addition
    end
    self.RImgCoinIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XRestaurantConfigs.ItemId.RestaurantUpgradeCoin))
    local food = XDataCenter.RestaurantManager.GetViewModel():GetProduct(XRestaurantConfigs.AreaType.FoodArea, id)
    self.TxtPrice.text = food:GetFinalPrice()
end

---@class XUiRestaurantRecommend : XLuaUi
local XUiRestaurantRecommend = XLuaUiManager.Register(XLuaUi, "UiRestaurantRecommend")

function XUiRestaurantRecommend:OnAwake()
    self:InitCb()
    self:InitUi()
end

function XUiRestaurantRecommend:OnStart()
    self:InitView()
end

function XUiRestaurantRecommend:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelShopList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridHotSale)
    self.GridItem.gameObject:SetActiveEx(false)
end 

function XUiRestaurantRecommend:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end
end 

function XUiRestaurantRecommend:InitView()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    
    self:BindViewModelPropertyToObj(viewModel, function(day)
        self:SetupDynamicTable(day)
    end, "_CurDay")
end 

function XUiRestaurantRecommend:SetupDynamicTable(day)
    local list = XRestaurantConfigs.GetHotSaleDataList(day)
    self.DataList = self:SortHotSaleList(list)
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
    local tempList = {}
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    for _, data in ipairs(list) do
        local product = viewModel:GetProduct(XRestaurantConfigs.AreaType.FoodArea, data.Id)
        if product and product:IsUnlock() then
            table.insert(tempList, data)
        end
    end
    table.sort(tempList, function(a, b) 
        --local unLockA = viewModel:CheckFoodUnlock(a.Id)
        --local unLockB = viewModel:CheckFoodUnlock(b.Id)
        --if unLockA ~= unLockB then
        --    return unLockA
        --end
        local priceA = XRestaurantConfigs.GetFoodBasePrice(a.Id)
        local priceB = XRestaurantConfigs.GetFoodBasePrice(b.Id)

        if priceA ~= priceB then
            return priceA > priceB
        end
        return a.Id < b.Id
    end)
    
    return tempList
end 