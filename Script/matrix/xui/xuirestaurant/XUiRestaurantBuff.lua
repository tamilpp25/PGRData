local XUiGridBuffRole = XClass(nil, "XUiGridBuffRole")

function XUiGridBuffRole:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

---@param character XRestaurantStaff
function XUiGridBuffRole:Refresh(character, isEffect)
    self.RImgRole:SetRawImage(character:GetIcon())
    self.ImgBuffIcon.gameObject:SetActiveEx(isEffect)
    self.GameObject:SetActiveEx(true)
end



local XUiPanelAreaBuff = XClass(nil, "XUiPanelAreaBuff")

function XUiPanelAreaBuff:Ctor(ui, areaType)
    XTool.InitUiObjectByUi(self, ui)
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
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local buffId = viewModel:GetAreaBuffId(self.AreaType)
    self.TxtTitle.text = XRestaurantConfigs.GetCameraAuxiliaryAreaName(self.AreaType)
    local isSelect = XTool.IsNumberValid(buffId)
    local unlock = viewModel:CheckAreaBuffUnlock(self.AreaType)
    self.PanelSelect.gameObject:SetActiveEx(unlock)
    self.PanelLock.gameObject:SetActiveEx(not unlock)
    self.PanelNoSelect.gameObject:SetActiveEx(not unlock or not isSelect)
    if not unlock then
        self.TxtLock.text = XRestaurantConfigs.GetBuffAreaUnlockTip(self.AreaType)
        return
    elseif not isSelect then
        return
    end
    self.Buff = viewModel:GetBuff(buffId)
    self.BtnChange:SetNameByGroup(0, self.Buff:GetProperty("_Name"))
    self.DataList = viewModel:GetWorkingStaff(self.AreaType)
    self:SetupDynamicTable()
end

function XUiPanelAreaBuff:SetupDynamicTable()
    for _, grid in pairs(self.GridRoles) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid.GameObject:SetActiveEx(false)
        end
    end

    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    for i, data in ipairs(self.DataList) do
        local grid = self.GridRoles[i]
        if not grid then
            local ui = i == 1 and self.GridBuffRole or XUiHelper.Instantiate(self.GridBuffRole, self.PanelBuff)
            grid = XUiGridBuffRole.New(ui)
            self.GridRoles[i] = grid
        end
        
        local workBenchId = data:GetProperty("_WorkBenchId")
        local workBench = viewModel:GetWorkBenchViewModel(self.AreaType, workBenchId, true)
        local productId = workBench:GetProperty("_ProductId")
        local isEffect = self.Buff:CheckBenchEffect(self.AreaType, data:GetProperty("_Id"), productId)
        grid:Refresh(data, isEffect)
    end
end

function XUiPanelAreaBuff:RefreshRedPoint()
    self.BtnChange:ShowReddot(XDataCenter.RestaurantManager.CheckBuffRedPoint(self.AreaType))
end

function XUiPanelAreaBuff:OnBtnSelectClick()
    XLuaUiManager.Open("UiRestaurantBuffChange", self.Buff:GetProperty("_Id"))
end

function XUiPanelAreaBuff:OnBtnChangeClick()
    XLuaUiManager.Open("UiRestaurantBuffChange", self.Buff:GetProperty("_Id"))
end


---@class XUiRestaurantBuff : XLuaUi
local XUiRestaurantBuff = XLuaUiManager.Register(XLuaUi, "UiRestaurantBuff")

function XUiRestaurantBuff:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantBuff:OnStart()
    self:InitView()
end

function XUiRestaurantBuff:InitUi()
    self.IngredientBuff = XUiPanelAreaBuff.New(self.PanelIngredient, XRestaurantConfigs.AreaType.IngredientArea)
    self.FoodBuff = XUiPanelAreaBuff.New(self.PanelFood, XRestaurantConfigs.AreaType.FoodArea)
    self.SaleBuff = XUiPanelAreaBuff.New(self.PanelSale, XRestaurantConfigs.AreaType.SaleArea)
end

function XUiRestaurantBuff:InitCb()
    local close = handler(self, self.Close)
    
    self.BtnClose.CallBack = close
    self.BtnWndClose.CallBack = close
end

function XUiRestaurantBuff:InitView()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    self:BindViewModelPropertyToObj(viewModel, function()
        self.IngredientBuff:Refresh()
        self.FoodBuff:Refresh()
        self.SaleBuff:Refresh()
    end, "_AreaTypeBuff")
    
    self:BindViewModelPropertyToObj(viewModel, function()
        self.IngredientBuff:RefreshRedPoint()
        self.FoodBuff:RefreshRedPoint()
        self.SaleBuff:RefreshRedPoint()
    end, "_BuffRedPointMarkCount")
    
end