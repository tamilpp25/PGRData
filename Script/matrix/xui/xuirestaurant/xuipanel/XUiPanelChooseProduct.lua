local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiPanelWorkBase = require("XUi/XUiRestaurant/XUiPanel/XUiPanelWorkBase")
local XUiGridBenchProduct = require("XUi/XUiRestaurant/XUiGrid/XUiGridBenchProduct")
local XUiGridConsume = require("XUi/XUiRestaurant/XUiGrid/XUiGridConsume")
local XUiPanelWorkBuff = require("XUi/XUiRestaurant/XUiPanel/XUiPanelWorkBuff")

---@class XUiPanelChooseProduct : XUiPanelWorkBase
---@field DataList XRestaurantProductVM[]
---@field Product XRestaurantProductVM
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
    self.DynamicTable:SetProxy(XUiGridBenchProduct, self.Parent, handler(self, self.OnSelect))
    self.GridFoods.gameObject:SetActiveEx(false)
end

function XUiPanelChooseProduct:InitCb()
    self.BtnConfirm.CallBack = function() 
        self:OnBtnConfirmClick()
    end
end

function XUiPanelChooseProduct:RefreshView()
    self:RefreshBuff()
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
    local benchModel = self._Control:GetWorkbench(self.AreaType, self.Index)
    local list = benchModel:SortProduct()
    local empty = XTool.IsTableEmpty(list)
    self.ImgEmpty.gameObject:SetActiveEx(empty)
    local startIndex = 1
    if benchModel:IsRunning() then
        self.Product = benchModel:GetProduct()
        if not empty then
            for index, product in ipairs(list) do
                if product:Equal(self.Product) then
                    startIndex = index
                    break
                end
            end
        end
    end
    self.DataList = list
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataSync(startIndex)
end

function XUiPanelChooseProduct:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local product = self.DataList[index]
        local selectId = self.Product and self.Product:GetProductId() or 0
        local isUrgent =  self._Control:IsUrgentProduct(self.AreaType, product:GetProductId())
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
    if self._Control:IsSaleArea(self.AreaType) then
        local speed = self.Product:GetSellSpeed()
        productionRate = self._Control:GetProduceSpeedDesc(2, speed)
    else
        local speed = self.Product:GetSpeed()
        productionRate = self._Control:GetProduceSpeedDesc(1, speed)
    end
    
    self.TxtProductionRate.text = productionRate
    self.TxtProductName.text = self.Product:GetName()
    
    self.RImgIcon:SetRawImage(self.Product:GetProductIcon())
    
    if self._Control:IsCookArea(self.AreaType) then
        local list = self.Product:GetIngredients()
        self.PanelNeed.gameObject:SetActiveEx((not XTool.IsTableEmpty(list)))
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

    if not self._Control:IsCookArea(self.AreaType) or not self.Product then
        self.PanelNeed.gameObject:SetActiveEx(false)
        return
    end
    
    self.TxtNeed.text = string.format(self._Control:GetProduceDesc(5), self.Product:GetName())
    local consumeList = self.Product:GetIngredients()
    local areaType = XMVCA.XRestaurant.AreaType.IngredientArea
    for idx, consume in pairs(consumeList or {}) do
        local grid = self.GridNeeds[idx]
        if not grid then
            local ui = idx == 1 and self.GridNeed or XUiHelper.Instantiate(self.GridNeed, self.PanelNeedGroup)
            grid = XUiGridConsume.New(ui, self.Parent)
            self.GridNeeds[idx] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(areaType, consume.Id, consume.Count)
    end
    self.PanelNeed.gameObject:SetActiveEx(true)
end

function XUiPanelChooseProduct:RefreshBuff()
    if not self.PanelWorkBuff then
        self.PanelWorkBuff = XUiPanelWorkBuff.New(self.UiRestaurantBtnBuff, self.Parent, self.AreaType, false)
    end
    if self._Control:CheckAreaBuffUnlock(self.AreaType) then
        self.PanelWorkBuff:Open()
    else
        self.PanelWorkBuff:Close()
    end
end

function XUiPanelChooseProduct:OnBtnConfirmClick()
    if not self.Product then
        return
    end
    local benchModel = self._Control:GetWorkbench(self.AreaType, self.Index)
    if benchModel:IsRunning() then
        --当前工作台的产品
        local oldProductId = benchModel:GetProductId()
        --需要更换的产品Id
        local newProductId = self.Product:GetProductId()
        --当前工作台的员工
        local characterId = benchModel:GetCharacterId()
        self._Control:RequestAssignWork(self.AreaType, characterId, self.Index, newProductId, function() 
            benchModel:SwitchStaffOrProduct(nil, characterId, oldProductId, newProductId)
        end)
        return
    end
    benchModel:AddProduct(self.Product:GetProductId())
end

return XUiPanelChooseProduct