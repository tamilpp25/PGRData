
--- 标题下标
local WorkTitleIndex = {
    --烹饪
    Food        = 1,
    --食材
    Ingredient  = 2,
    --角色
    Role        = 3,
    --售卖
    Sale        = 4
}

---@class XUiRestaurantWork : XLuaUi
local XUiRestaurantWork = XLuaUiManager.Register(XLuaUi, "UiRestaurantWork")

local XUiPanelChooseProduct = require("XUi/XUiRestaurant/XUiPanel/XUiPanelChooseProduct")
local XUiPanelChooseRole = require("XUi/XUiRestaurant/XUiPanel/XUiPanelChooseRole")
local XUiPanelWorkDetail = require("XUi/XUiRestaurant/XUiPanel/XUiPanelWorkDetail")
local XUiPanelStorage = require("XUi/XUiRestaurant/XUiPanel/XUiPanelStorage")

function XUiRestaurantWork:OnAwake()
    self:InitUi()
    self:InitCb()
end 

--- 
---@param areaType number
---@param index number
---@return
--------------------------
function XUiRestaurantWork:OnStart(areaType, index)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    self.BenchViewModel = viewModel:GetWorkBenchViewModel(areaType, index)
    self:InitView()
end

function XUiRestaurantWork:OnEnable()
    
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_SHOW_ASSIGN_WORK, self.Close, self)
end

function XUiRestaurantWork:OnDisable()

    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_SHOW_ASSIGN_WORK, self.Close, self)
end

function XUiRestaurantWork:InitUi()
    self.PanelRole.gameObject:SetActiveEx(false)
    self.PanelBaseFood.gameObject:SetActiveEx(false)
    self.PanelRoleYield.gameObject:SetActiveEx(false)
    self.PanelChoseFoodMaterial.gameObject:SetActiveEx(false)
    self.PanelChoseDish.gameObject:SetActiveEx(false)
    
    ---@type XUiPanelChooseRole
    self.PanelChooseRole = XUiPanelChooseRole.New(self.PanelRole)
    ---@type XUiPanelWorkDetail
    self.PanelWorkDetail = XUiPanelWorkDetail.New(self.PanelRoleYield)
    ---@type XUiPanelStorage
    self.PanelStorage = XUiPanelStorage.New(self.PanelBaseFood, self)
end 

function XUiRestaurantWork:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end

    self.BtnWndClose.CallBack = function()
        self:Close()
    end
end 

function XUiRestaurantWork:InitView()
    local viewModel = self.BenchViewModel
    
    local areaType = viewModel:GetProperty("_AreaType")
    local id = viewModel:GetProperty("_Id")

    local ui = XRestaurantConfigs.CheckIsIngredientArea(areaType)
            and self.PanelChoseFoodMaterial or self.PanelChoseDish
    self:RefreshTitleByAreaType(areaType)
    ---@type XUiPanelChooseProduct
    self.PanelChooseProduct = XUiPanelChooseProduct.New(ui)
    
    self:BindViewModelPropertiesToObj(viewModel, function(productId, characterId)
        self.PanelChooseRole:Hide()
        self.PanelWorkDetail:Hide()
        self:RefreshIngredient(false, areaType)
        if not XTool.IsNumberValid(productId) then
            self.PanelChooseProduct:Show(areaType, id)
            self:RefreshIngredient(true, areaType)
            return
        else
            self.PanelChooseProduct:Hide()
        end

        if not XTool.IsNumberValid(characterId) then
            self.PanelChooseRole:Show(areaType, id)
            self:RefreshTitle(WorkTitleIndex.Role)
            return
        else
            self.PanelChooseRole:Hide()
        end
        
        self.PanelWorkDetail:Show(areaType, id)
        self:RefreshTitleByAreaType(areaType)
    end, "_ProductId", "_CharacterId")
end

function XUiRestaurantWork:RefreshTitleByAreaType(areaType)
    local index = WorkTitleIndex.Ingredient
    if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
        index = WorkTitleIndex.Ingredient
    elseif XRestaurantConfigs.CheckIsFoodArea(areaType) then
        index = WorkTitleIndex.Food
    elseif XRestaurantConfigs.CheckIsSaleArea(areaType) then
        index = WorkTitleIndex.Sale
    end
    self:RefreshTitle(index)
end

function XUiRestaurantWork:RefreshTitle(index)
    local titlePath = XRestaurantConfigs.GetClientConfig("WorkRImgTitle", index)
    if not titlePath then
        XLog.Error("not found title path, index = " .. tostring(index))
        return
    end
    self.RImgTittle:SetRawImage(titlePath)
end 

function XUiRestaurantWork:RefreshIngredient(show, areaType)
    local showView = XRestaurantConfigs.CheckIsFoodArea(areaType)
    if not (showView and show) then
        self.PanelStorage:Hide()
        return
    end
    self.PanelStorage:Show(XRestaurantConfigs.AreaType.IngredientArea, nil, "_Count")
end

function XUiRestaurantWork:Close()
    self.Super.Close(self)
    local state = self.BenchViewModel:GetProperty("_State")
    if state == XRestaurantConfigs.WorkState.Free then
        --local characterId = self.BenchViewModel:GetProperty("_CharacterId")
        --local viewModel = XDataCenter.RestaurantManager.GetViewModel()
        self.BenchViewModel:DelProduct()
        self.BenchViewModel:DelStaff()
    end
end