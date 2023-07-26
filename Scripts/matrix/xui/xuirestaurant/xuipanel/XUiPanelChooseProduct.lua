
local XUiPanelWorkBase = require("XUi/XUiRestaurant/XUiPanel/XUiPanelWorkBase")
local XUiGridBenchProduct = require("XUi/XUiRestaurant/XUiGrid/XUiGridBenchProduct")
local XUiGridConsume = require("XUi/XUiRestaurant/XUiGrid/XUiGridConsume")

---@class XUiPanelChooseProduct : XUiPanelWorkBase
local XUiPanelChooseProduct = XClass(XUiPanelWorkBase, "XUiPanelChooseProduct")

function XUiPanelChooseProduct:InitUi()
    self:InitDynamicTable()
    self.GridNeeds = {}

    if not XTool.UObjIsNil(self.GridNeed) then
        self.GridNeed.gameObject:SetActiveEx(false)
    end
end

function XUiPanelChooseProduct:InitDynamicTable()
    if XTool.UObjIsNil(self.PanelFoodList) then
        return
    end
    self.PanelFoodList.gameObject:SetActiveEx(true)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelFoodList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridBenchProduct, handler(self, self.OnSelect))
    self.GridFoods.gameObject:SetActiveEx(false)
end

function XUiPanelChooseProduct:InitCb()
    self.BtnConfirm.CallBack = function() 
        self:OnBtnConfirmClick()
    end
end

function XUiPanelChooseProduct:RefreshView()
    self:RefreshChoose()
    self:SetupDynamicTable()
end

function XUiPanelChooseProduct:ClearCache()
    self.LastGrid = nil
end

function XUiPanelChooseProduct:SetupDynamicTable()
    if not self.DynamicTable then
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel():GetWorkBenchViewModel(self.AreaType, self.Index)
    local list = viewModel:SortProduct()
    local empty = XTool.IsTableEmpty(list)
    self.ImgEmpty.gameObject:SetActiveEx(empty)
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataASync()
    self.DataList = list
end

function XUiPanelChooseProduct:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local product = self.DataList[index]
        local selectId = self.Product and self.Product:GetProperty("_Id") or 0
        local isUrgent = XDataCenter.RestaurantManager.GetViewModel():IsUrgentProduct(self.AreaType, product:GetProperty("_Id"))
        grid:Refresh(product, self.AreaType, selectId, isUrgent)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not self.Product then
            return
        end
        local grids = self.DynamicTable:GetGrids()
        for _, item in pairs(grids or {}) do
            if item and item.Product
                    and self.Product:Equal(item.Product) then
                item:SetSelect(false)
                item:OnBtnClick()
                break
            end
        end
    end
end

--- 点选Item
---@param grid XUiGridBenchProduct
---@return void
--------------------------
function XUiPanelChooseProduct:OnSelect(grid)
    if self.LastGrid then
        self.LastGrid:SetSelect(false)
    end
    self.LastGrid = grid
    self.Product = grid.Product
    self:RefreshChoose()
end

function XUiPanelChooseProduct:RefreshChoose()
    if not self.Product then
        self.PanelChoose.gameObject:SetActiveEx(false)
        self.PanelNoChoose.gameObject:SetActiveEx(true)
        self.BtnConfirm:SetDisable(true, false)
        return
    end
    self.BtnConfirm:SetDisable(false, true)
    self.PanelChoose.gameObject:SetActiveEx(true)
    self.PanelNoChoose.gameObject:SetActiveEx(false)

    local productionRate
    if XRestaurantConfigs.CheckIsSaleArea(self.AreaType) then
        local speed = self.Product:GetProperty("_SellSpeed")
        productionRate = string.format(XRestaurantConfigs.GetClientConfig("ProduceSpeedDesc", 2), XRestaurantConfigs.TransProduceTime(speed))
    else
        local speed = self.Product:GetProperty("_Speed")
        productionRate = string.format(XRestaurantConfigs.GetClientConfig("ProduceSpeedDesc", 1), XRestaurantConfigs.TransProduceTime(speed))
    end
    
    self.TxtProductionRate.text = productionRate
    self.TxtProductName.text = self.Product:GetProperty("_Name")
    
    self.RImgIcon:SetRawImage(self.Product:GetProductIcon())
    
    local consumeList = self.Product:GetProperty("_Ingredients")
    if XRestaurantConfigs.CheckIsFoodArea(self.AreaType) 
            and not XTool.IsTableEmpty(consumeList) then
        self.PanelNeed.gameObject:SetActiveEx(true)
    end
    
    self:RefreshIngredient()
end

--刷新食材
function XUiPanelChooseProduct:RefreshIngredient()
    for _, grid in pairs(self.GridNeeds) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid.GameObject:SetActiveEx(false)
        end
    end
    if XTool.UObjIsNil(self.PanelNeed) then
        return
    end

    if  self.AreaType ~= XRestaurantConfigs.AreaType.FoodArea
            or not self.Product then
        self.PanelNeed.gameObject:SetActiveEx(false)
        return
    end
    
    local desc = XRestaurantConfigs.GetClientConfig("ProduceDesc", 5)
    desc = string.format(desc, self.Product:GetProperty("_Name"))
    self.TxtNeed.text = desc
    ---@type XConsumeIngredient[]
    local consumeList = self.Product:GetProperty("_Ingredients")
    local areaType = XRestaurantConfigs.AreaType.IngredientArea
    for idx, consume in pairs(consumeList or {}) do
        local grid = self.GridNeeds[idx]
        if not grid then
            local ui = idx == 1 and self.GridNeed or XUiHelper.Instantiate(self.GridNeed, self.PanelNeedGroup)
            grid = XUiGridConsume.New(ui)
            self.GridNeeds[idx] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(areaType, consume:GetId(), consume:GetCount())
    end
    self.PanelNeed.gameObject:SetActiveEx(true)
end

function XUiPanelChooseProduct:OnBtnConfirmClick()
    if not self.Product then
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel():GetWorkBenchViewModel(self.AreaType, self.Index)
    viewModel:AddProduct(self.Product:GetProperty("_Id"))
end

return XUiPanelChooseProduct