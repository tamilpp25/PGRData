local XUiPanelArea = require("XUi/XUiMission/XUiPanelArea")
---@class XUiGridBuffRole : XUiNode
---@field _Control XRestaurantControl
local XUiGridBuffRole = XClass(XUiNode, "XUiGridBuffRole")


---@param character XRestaurantStaffVM
function XUiGridBuffRole:Refresh(character, isEffect)
    self.RImgRole:SetRawImage(character:GetIcon())
    self.ImgBuffIcon.gameObject:SetActiveEx(isEffect)
    self.GameObject:SetActiveEx(true)
end



---@class XUiPanelAreaBuff : XUiNode
---@field _Control XRestaurantControl
---@field DataList XRestaurantStaffVM[]
local XUiPanelAreaBuff = XClass(XUiNode, "XUiPanelAreaBuff")


function XUiPanelAreaBuff:OnStart(areaType)
    self.AreaType = areaType
    self.GridRoles = {}
    self.BtnSelect.CallBack = function()
        self:OnBtnSelectClick()
    end

    self.BtnChange.CallBack = function()
        self:OnBtnChangeClick()
    end

    self.GridBuffRole.gameObject:SetActiveEx(false)

    self.SelectBuff = self.PanelNoSelect.transform:FindTransform("PanelBuff")

    if self.SelectBuff then
        self.SelectBuff.gameObject:SetActiveEx(false)
    end
end

function XUiPanelAreaBuff:Refresh()
    local buffId = self._Control:GetAreaBuffId(self.AreaType)
    self.TxtTitle.text = self._Control:GetAreaTypeName(self.AreaType)
    local isSelect = XTool.IsNumberValid(buffId)
    local unlock =  self._Control:CheckAreaBuffUnlock(self.AreaType)
    self.PanelSelect.gameObject:SetActiveEx(unlock)
    self.PanelLock.gameObject:SetActiveEx(not unlock)
    self.PanelNoSelect.gameObject:SetActiveEx(not unlock or not isSelect)
    if not unlock then
        self.TxtLock.text = self._Control:GetBuffAreaUnlockTip(self.AreaType)
        return
    elseif not isSelect then
        return
    end
    self.Buff = self._Control:GetBuff(buffId)
    self.BtnChange:SetNameByGroup(0, self.Buff:GetName())
    self.DataList = self._Control:GetCharactersWithAreaType(self.AreaType)
    self:SetupDynamicTable()
end

function XUiPanelAreaBuff:SetupDynamicTable()
    for _, grid in pairs(self.GridRoles) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid.GameObject:SetActiveEx(false)
        end
    end
    
    for i, data in ipairs(self.DataList) do
        local grid = self.GridRoles[i]
        if not grid then
            local ui = i == 1 and self.GridBuffRole or XUiHelper.Instantiate(self.GridBuffRole, self.PanelBuff)
            grid = XUiGridBuffRole.New(ui, self.Parent)
            self.GridRoles[i] = grid
        end
        
        local workBenchId = data:GetWorkBenchId()
        local workBench = self._Control:GetWorkbench(self.AreaType, workBenchId)
        local productId = workBench:GetProductId()
        local isEffect = self.Buff:CheckBenchEffect(self.AreaType, data:GetCharacterId(), productId)
        grid:Refresh(data, isEffect)
    end
end

function XUiPanelAreaBuff:RefreshRedPoint()
    self.BtnChange:ShowReddot(self._Control:CheckBuffRedPoint(self.AreaType))
end

function XUiPanelAreaBuff:OnBtnSelectClick()
    self._Control:OpenBuff(false, self.Buff:GetBuffId())
end

function XUiPanelAreaBuff:OnBtnChangeClick()
    self._Control:OpenBuff(false, self.Buff:GetBuffId())
end


---@class XUiRestaurantBuff : XLuaUi
---@field _Control XRestaurantControl
local XUiRestaurantBuff = XLuaUiManager.Register(XLuaUi, "UiRestaurantBuff")

function XUiRestaurantBuff:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantBuff:OnStart()
    self:InitView()
end

function XUiRestaurantBuff:OnDestroy()
    self._Control:GetBusiness():ClearBind(self.GameObject:GetHashCode())
end

function XUiRestaurantBuff:InitUi()
    self.IngredientBuff = XUiPanelAreaBuff.New(self.PanelIngredient, self, XMVCA.XRestaurant.AreaType.IngredientArea)
    self.FoodBuff = XUiPanelAreaBuff.New(self.PanelFood, self, XMVCA.XRestaurant.AreaType.FoodArea)
    self.SaleBuff = XUiPanelAreaBuff.New(self.PanelSale, self, XMVCA.XRestaurant.AreaType.SaleArea)
end

function XUiRestaurantBuff:InitCb()
    local close = handler(self, self.Close)
    
    self.BtnClose.CallBack = close
    self.BtnWndClose.CallBack = close
end

function XUiRestaurantBuff:InitView()
    local business = self._Control:GetBusiness()
    business:BindViewModelPropertyToObj(self.GameObject:GetHashCode(), business.Property.BuffRedPointMarkCount, function()
        self.IngredientBuff:Refresh()
        self.FoodBuff:Refresh()
        self.SaleBuff:Refresh()

        self.IngredientBuff:RefreshRedPoint()
        self.FoodBuff:RefreshRedPoint()
        self.SaleBuff:RefreshRedPoint()
    end)
end