--- 标题下标
local WorkTitleIndex = {
    --烹饪
    Food = 1,
    --食材
    Ingredient = 2,
    --角色
    Role = 3,
    --售卖
    Sale = 4
}

local SubPanelType = {
    Product = 1,
    Staff = 2,
    Details = 3,
}

---@class XUiRestaurantWork : XLuaUi
---@field _Control XRestaurantControl
---@field SubPanelDict table<number, XUiPanelWorkBase>
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
    self.BenchViewModel = self._Control:GetWorkbench(areaType, index)
    self:InitView()
end

function XUiRestaurantWork:OnEnable()

    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_SHOW_ASSIGN_WORK, self.Close, self)
end

function XUiRestaurantWork:OnDisable()

    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_SHOW_ASSIGN_WORK, self.Close, self)
end

function XUiRestaurantWork:OnDestroy()
    if self.BenchViewModel then
        self.BenchViewModel:ClearBind(self.GameObject:GetHashCode())
    end
end

function XUiRestaurantWork:InitUi()
    self.PanelRole.gameObject:SetActiveEx(false)
    self.PanelBaseFood.gameObject:SetActiveEx(false)
    self.PanelRoleYield.gameObject:SetActiveEx(false)
    self.PanelChoseFoodMaterial.gameObject:SetActiveEx(false)
    self.PanelChoseDish.gameObject:SetActiveEx(false)
    
    ---@type XUiPanelStorage
    self.PanelStorage = XUiPanelStorage.New(self.PanelBaseFood, self)
end

function XUiRestaurantWork:InitCb()
    self.BtnClose.CallBack = function()
        self:CloseByState()
    end

    self.BtnWndClose.CallBack = function()
        self:CloseByState()
    end
end

function XUiRestaurantWork:InitView()
    
    local viewModel = self.BenchViewModel

    local areaType = viewModel:GetAreaType()
    local benchId = viewModel:GetWorkbenchId()

    local ui = self._Control:IsIngredientArea(areaType)
            and self.PanelChoseFoodMaterial or self.PanelChoseDish
    self.SubPanelDict = {
        [SubPanelType.Product] = XUiPanelChooseProduct.New(ui, self),
        [SubPanelType.Staff] = XUiPanelChooseRole.New(self.PanelRole, self),
        [SubPanelType.Details] = XUiPanelWorkDetail.New(self.PanelRoleYield, self),
    }

    viewModel:BindViewModelPropertiesToObj(self.GameObject:GetHashCode(), {
        viewModel.Property.ProductId,
        viewModel.Property.CharacterId,
    }, function(productId, characterId)
        local subType
        if not XTool.IsNumberValid(productId) then
            subType = SubPanelType.Product
        elseif not XTool.IsNumberValid(characterId) then
            subType = SubPanelType.Staff
        else
            subType = SubPanelType.Details
        end
        self:RefreshSubPanel(subType, areaType, benchId)
    end)
end

function XUiRestaurantWork:RefreshSubPanel(subType, areaType, index)
    for type, view in pairs(self.SubPanelDict) do
        if subType == type then
            view:Show(areaType, index)
        else
            view:Hide()
        end
    end

    local show = subType == SubPanelType.Product
    self:RefreshIngredient(show, areaType)
    if subType == SubPanelType.Staff then
        self:RefreshTitle(WorkTitleIndex.Role)
    else
        self:RefreshTitleByAreaType(areaType)
    end
end

function XUiRestaurantWork:RefreshTitleByAreaType(areaType)
    local index = WorkTitleIndex.Ingredient
    if self._Control:IsIngredientArea(areaType) then
        index = WorkTitleIndex.Ingredient
    elseif self._Control:IsCookArea(areaType) then
        index = WorkTitleIndex.Food
    elseif self._Control:IsSaleArea(areaType) then
        index = WorkTitleIndex.Sale
    end
    self:RefreshTitle(index)
end

function XUiRestaurantWork:RefreshTitle(index)
    local titlePath = self._Control:GetWorkRImgTitle(index)
    if not titlePath then
        XLog.Error("not found title path, index = " .. tostring(index))
        return
    end
    if self.RImgTittle then
        self.RImgTittle:SetRawImage(titlePath)
    elseif self.ImgTitle then
        self.ImgTitle:SetSprite(titlePath)
    end
end

function XUiRestaurantWork:RefreshIngredient(show, areaType)
    local showView = self._Control:IsCookArea(areaType)
    if not (showView and show) then
        self.PanelStorage:Hide()
        return
    end
    self.PanelStorage:Show(XMVCA.XRestaurant.AreaType.IngredientArea)
end

function XUiRestaurantWork:ShowProductPanel(areaType, index)
    self:RefreshSubPanel(SubPanelType.Product, areaType, index)
end

function XUiRestaurantWork:ShowStaffPanel(areaType, index)
    self:RefreshSubPanel(SubPanelType.Staff, areaType, index)
end

function XUiRestaurantWork:ShowDetailPanel(areaType, index)
    self:RefreshSubPanel(SubPanelType.Details, areaType, index)
end

function XUiRestaurantWork:Close()
    self.Super.Close(self)
    local state = self.BenchViewModel:GetClientState()
    if state == XMVCA.XRestaurant.WorkState.Free then
        self.BenchViewModel:DelProduct()
        self.BenchViewModel:DelStaff()
    end
end

function XUiRestaurantWork:CloseByState()
    if not self.BenchViewModel or self.BenchViewModel:IsRunning() then
        self:Close()
        return
    end
    local productId, characterId = self.BenchViewModel:GetProductId(), self.BenchViewModel:GetCharacterId()
    local validP, validC = XTool.IsNumberValid(productId), XTool.IsNumberValid(characterId)
    
    if not validC and validP then
        self.BenchViewModel:DelProduct()
        self:RefreshSubPanel(SubPanelType.Product, self.BenchViewModel:GetAreaType(), self.BenchViewModel:GetWorkbenchId())
        return
    end
    
    --if not validP and validC then
    --    self.BenchViewModel:DelStaff()
    --    self:RefreshSubPanel(SubPanelType.Staff, self.BenchViewModel:GetAreaType(), self.BenchViewModel:GetWorkbenchId())
    --    return
    --end
    self:Close()
end