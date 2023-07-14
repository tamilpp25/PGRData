
---@class XUiGuildDormCommon : XLuaUi
local XUiRestaurantCommon = XLuaUiManager.Register(XLuaUi, "UiRestaurantCommon")

local XUiGrid3DCashier   = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DCashier")
local XUiGrid3DWorkBench = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DWorkBench")
local XUiGrid3DDialog    = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DDialog")
local XUiGrid3DOrder     = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DOrder")
local XUiGrid3DHandBook  = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DHandBook")
--local XUiGrid3DBase         = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DBase")
--local XUiGrid3DRedPaper     = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DRedPaper")

function XUiRestaurantCommon:OnAwake()
    self.Room = XDataCenter.RestaurantManager.GetRoom()
    self:InitUi()
end

function XUiRestaurantCommon:OnStart()
    self:InitView()
    --标记外部收银台已读
    XDataCenter.RestaurantManager.MarkCashierLimitRedPoint()
    
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_SHOW_3D_DIALOG, self.ShowDialog, self)
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_HIDE_3D_DIALOG, self.RecycleDialog, self)
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_SHOW_MAIN_UI, self.Refresh3DGridShow, self)
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_ORDER_STATE_CHANGE, self.OnRefreshOrderCb, self)
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_WORK_BENCH_CHANGE_STAFF, self.RefreshWorkBenchRedPoint, self)
end

function XUiRestaurantCommon:OnEnable()
    self:Update()
    self.Timer = XScheduleManager.ScheduleForever(function() 
        self:Update()
    end, 0, 0)
end

function XUiRestaurantCommon:OnDestroy()
    self.DialogPool:Clear()
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_SHOW_3D_DIALOG, self.ShowDialog, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_HIDE_3D_DIALOG, self.RecycleDialog, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_SHOW_MAIN_UI, self.Refresh3DGridShow, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_ORDER_STATE_CHANGE, self.OnRefreshOrderCb, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_WORK_BENCH_CHANGE_STAFF, self.RefreshWorkBenchRedPoint, self)
end

function XUiRestaurantCommon:Update()
    if not self.Room:Exist() then
        self:ClearTimer()
        return
    end
    self:UpdateTransform()
end

function XUiRestaurantCommon:InitUi()
    ---@type table<number, XUiGrid3DWorkBench>
    self.GridFood = {}
    ---@type table<number, XUiGrid3DWorkBench>
    self.GridIngredient = {}
    ---@type table<number, XUiGrid3DWorkBench>
    self.GridSale = {}
    ---@type XStack
    self.DialogPool = XStack.New()
    ---@type table<number, XUiGrid3DDialog>
    self.GridDialog = {}
    
    local model = self.Room:GetCashierModel()
    local cashierOffset = XRestaurantConfigs.StrPos2Vector3(XRestaurantConfigs.GetClientConfig("Ui3DOffset", 1))
    ---@type XUiGrid3DCashier
    self.GridCashier = XUiGrid3DCashier.New(self.PanelCashier)
    self.GridCashier:Bind(nil, model.transform, cashierOffset)
    
    self.GridHandBook = XUiGrid3DHandBook.New(self.BtnMenu)
    local handBookOffset = XRestaurantConfigs.StrPos2Vector3(XRestaurantConfigs.GetClientConfig("Ui3DOffset", 3))
    self.GridHandBook:Bind(nil, self.Room:GetBlackBoardModel(), handBookOffset)

    self.GirdProduct.gameObject:SetActiveEx(false)
    self.GridDialogBox.gameObject:SetActiveEx(false)
    self.PanelRedPaper.gameObject:SetActiveEx(false)
    self.BtnIndent.gameObject:SetActiveEx(false)
    self.BtnMenu.gameObject:SetActiveEx(false)
    
    self.OnRefreshOrderCb = function()
        if not self.GridOrder then
            return
        end
        self.GridOrder:Show()
    end
end

function XUiRestaurantCommon:CreateGrid3DWorkBench(areaType, unlockCount, mapGrid, name)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    for i = 1, unlockCount do
        local grid = mapGrid[i]
        if not grid then
            local benchData = XRestaurantConfigs.GetWorkBenchData(areaType, i)
            local ui = XUiHelper.Instantiate(self.GirdProduct)
            grid = XUiGrid3DWorkBench.New(ui)
            grid:Bind(self.ProductContainer, self.Room:GetWorkBenchModel(areaType, i), benchData.IconOffset)
            grid:SetName(name .. i)
            mapGrid[i] = grid
        end
        local workBench = viewModel:GetWorkBenchViewModel(areaType, i)
        grid:Show(self, workBench, "_State", "_CharacterId", "_ProductId", "_Count", "_Progress")
    end
end

function XUiRestaurantCommon:ShowDialog(id, content, emoji, target, offset)
    if XTool.UObjIsNil(self.GridDialogBox) then
        return
    end
    local count = self.DialogPool:Count()
    local dialog
    if count > 0 then
        dialog = self.DialogPool:Pop()
    else
        local ui = XUiHelper.Instantiate(self.GridDialogBox, self.DialogContainer)
        dialog = XUiGrid3DDialog.New(ui)
    end
    dialog:Bind(self.DialogContainer, target, offset)
    dialog:Show(id, content, emoji)
    self.GridDialog[id] = dialog
end

--- 回收dialog
---@param id number
---@return void
--------------------------
function XUiRestaurantCommon:RecycleDialog(id)
    local dialog = self.GridDialog[id]
    if not dialog then
        return
    end
    dialog:Hide()
    self.DialogPool:Push(dialog)
    self.GridDialog[id] = nil
end

function XUiRestaurantCommon:InitView()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    --Ui层级
    self:BindViewModelPropertyToObj(viewModel, function(sortingOrder)
        if sortingOrder < 0 then
            return
        end
        self.UiCanvas.sortingOrder = sortingOrder - 1
    end, "_UiMainSorting")

    --3DUi
    local level = viewModel:GetProperty("_Level")

    local ingredientCount = XRestaurantConfigs.GetIngredientCounterNum(level)
    local foodCount = XRestaurantConfigs.GetFoodCounterNum(level)
    local saleCount = XRestaurantConfigs.GetSaleCounterNum(level)

    self:CreateGrid3DWorkBench(XRestaurantConfigs.AreaType.IngredientArea, ingredientCount, self.GridIngredient, "Ingredient")
    self:CreateGrid3DWorkBench(XRestaurantConfigs.AreaType.FoodArea, foodCount, self.GridFood, "Food")
    self:CreateGrid3DWorkBench(XRestaurantConfigs.AreaType.SaleArea, saleCount, self.GridSale, "Sale")

    self:BindViewModelPropertyToObj(viewModel, function(isLevelUp)
        if not isLevelUp then
            return
        end
        self:ClearTimer()
        self:Close()
    end, "_IsLevelUp")
    
    --收银台3DUI
    local cashier = viewModel:GetProperty("_Cashier")
    self:BindViewModelPropertyToObj(cashier, function(count)
        if not self.GridCashier then
            return
        end
        self.GridCashier:Show(count)
        for _, grid in pairs(self.GridSale) do
            grid:OnRefresh()
        end
    end, "_Count")
    
    self:BindViewModelPropertiesToObj(viewModel, function(isReceive)
        if not isReceive then
            return
        end
        if not self.GridRedPaper then
            return
        end
        self.GridRedPaper:Hide()
    end, "_IsGetSignReward")
    
    --签到红包
    self:BindViewModelPropertiesToObj(viewModel, function() 
        self:RefreshSign()
        self:RefreshOrder()
    end, "_CurDay")
    
    --图鉴红点
    self:BindViewModelPropertyToObj(viewModel, function()
        self.GridHandBook:RefreshRedPoint()
    end, "_MenuRedPointMarkCount")
    
    --招募员工
    self:BindViewModelPropertyToObj(viewModel, function() 
        self:RefreshWorkBenchRedPoint()
    end, "_EventLevelConditionChange")
    self:ShowBillView()
    self.GridHandBook:Show()
end

function XUiRestaurantCommon:UpdateTransform()
    if XTool.UObjIsNil(self.GameObject) then
        self:ClearTimer()
        return
    end
    local room = self.Room
    self.GridCashier:UpdateTransform(room)
    self.GridHandBook:UpdateTransform(room)
    for _, grid in pairs(self.GridIngredient) do
        grid:UpdateTransform(room)
    end

    for _, grid in pairs(self.GridFood) do
        grid:UpdateTransform(room)
    end

    for _, grid in pairs(self.GridSale) do
        grid:UpdateTransform(room)
    end

    if self.GridRedPaper then
        self.GridRedPaper:UpdateTransform(room)
    end

    for _, grid in pairs(self.GridDialog) do
        grid:UpdateTransform(room)
    end

    if self.GridOrder then
        self.GridOrder:UpdateTransform(room)
    end
end 

function XUiRestaurantCommon:Refresh3DGridShow(state)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    if not state then
        self.GridCashier.GameObject:SetActiveEx(true)
        for _, grid in pairs(self.GridIngredient) do
            grid.GameObject:SetActiveEx(true)
        end
        for _, grid in pairs(self.GridFood) do
            grid.GameObject:SetActiveEx(true)
        end
        for _, grid in pairs(self.GridSale) do
            grid.GameObject:SetActiveEx(true)
        end
        return
    end
    local camera = self.Room:GetCameraModel()
    local areaType = camera:GetAreaType()
    local inIngredient = XRestaurantConfigs.CheckIsIngredientArea(areaType)
    local inFood = XRestaurantConfigs.CheckIsFoodArea(areaType)
    local inSale = XRestaurantConfigs.CheckIsSaleArea(areaType)
    self.GridCashier.GameObject:SetActiveEx(inSale)

    for _, grid in pairs(self.GridIngredient) do
        grid.GameObject:SetActiveEx(inIngredient)
    end
    for _, grid in pairs(self.GridFood) do
        grid.GameObject:SetActiveEx(inFood)
    end
    for _, grid in pairs(self.GridSale) do
        grid.GameObject:SetActiveEx(inSale)
    end
end

function XUiRestaurantCommon:ShowBillView()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    if not viewModel:IsShowOfflineBill() then
        return
    end
    XLuaUiManager.Open("UiRestaurantBill")
end

function XUiRestaurantCommon:ClearTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end 

function XUiRestaurantCommon:RefreshSign()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    if not viewModel:CheckSignActivityInTime(false) then
        return
    end
    if viewModel:GetIsGetSignReward() or self.Room:SignNpcExist() then
        return
    end
    local signDay = viewModel:GetSignCurDay()
    self.Room:LoadSignNpc(signDay)
end 

function XUiRestaurantCommon:RefreshOrder()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local orderInfo = viewModel:GetTodayOrderInfo()
    --今天没有订单信息/今日订单已经完成
    if not orderInfo then
        return
    end
    local npcId = XRestaurantConfigs.GetOrderNpcId(orderInfo:GetId())
    self.Room:LoadOrderNpc(npcId, function()
        self:CreateOrderGrid(orderInfo)
    end)
end

function XUiRestaurantCommon:CreateOrderGrid(orderInfo)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    self.GridOrder = XUiGrid3DOrder.New(self.BtnIndent)
    local offset = XRestaurantConfigs.StrPos2Vector3(XRestaurantConfigs.GetClientConfig("Ui3DOffset", 2))
    self.GridOrder:Bind(nil, self.Room:GetOrderNpcModel(), offset)

    local infoList = XRestaurantConfigs.GetOrderFoodInfos(orderInfo:GetId())

    for _, info in ipairs(infoList or {}) do
        local product = viewModel:GetProduct(XRestaurantConfigs.AreaType.FoodArea, info.Id)
        if product then
            self:BindViewModelPropertyToObj(product, self.OnRefreshOrderCb, "_Count")
        end
    end
end

function XUiRestaurantCommon:RefreshWorkBenchRedPoint()
    for _, grid in pairs(self.GridIngredient) do
        grid:RefreshRedPoint()
    end

    for _, grid in pairs(self.GridFood) do
        grid:RefreshRedPoint()
    end

    for _, grid in pairs(self.GridSale) do
        grid:RefreshRedPoint()
    end
end