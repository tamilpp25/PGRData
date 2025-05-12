
---@class XUiGuildDormCommon : XLuaUi
---@field _Control XRestaurantControl
local XUiRestaurantCommon = XLuaUiManager.Register(XLuaUi, "UiRestaurantCommon")

local XUiGrid3DCashier   = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DCashier")
local XUiGrid3DWorkBench = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DWorkBench")
local XUiGrid3DDialog    = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DDialog")
local XUiGrid3DOrder     = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DOrder")
local XUiGrid3DPerform     = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DPerform")
local XUiGrid3DHandBook  = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DHandBook")
--local XUiGrid3DBase         = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DBase")
--local XUiGrid3DRedPaper     = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DRedPaper")

local DoEnable = false

function XUiRestaurantCommon:OnAwake()
    self.Room = self._Control:GetRoom()
    self._OnOnShowPerformTipCb = handler(self, self.OnShowPerformTip)
    self:InitUi()
end

function XUiRestaurantCommon:OnStart()
    DoEnable = false
    self:InitView()
    --标记外部收银台已读
    self._Control:MarkCashierLimitRedPoint()
end

function XUiRestaurantCommon:OnGetLuaEvents()
    return {
        XEventId.EVENT_RESTAURANT_SHOW_3D_DIALOG,
        XEventId.EVENT_RESTAURANT_HIDE_3D_DIALOG,
        XEventId.EVENT_RESTAURANT_SHOW_MAIN_UI,
        XEventId.EVENT_RESTAURANT_PERFORM_STATE_CHANGE,
        XEventId.EVENT_RESTAURANT_WORK_BENCH_CHANGE_STAFF,
        XEventId.EVENT_RESTAURANT_INDENT_NPC_STATE_CHANGED,
    }
end

function XUiRestaurantCommon:OnNotify(evt, ...)
    if not self._Control then
        return
    end
    if evt == XEventId.EVENT_RESTAURANT_SHOW_3D_DIALOG then
        self:ShowDialog(...)
    elseif evt == XEventId.EVENT_RESTAURANT_HIDE_3D_DIALOG then
        self:RecycleDialog(...)
    elseif evt == XEventId.EVENT_RESTAURANT_SHOW_MAIN_UI then
        self:Refresh3DGridShow(...)
    elseif evt == XEventId.EVENT_RESTAURANT_PERFORM_STATE_CHANGE then
        self:RefreshIndentGrid()
        self:RefreshPerformGrid()
    elseif evt == XEventId.EVENT_RESTAURANT_WORK_BENCH_CHANGE_STAFF then
        self:RefreshWorkBenchRedPoint(...)
    elseif evt == XEventId.EVENT_RESTAURANT_INDENT_NPC_STATE_CHANGED then
        self:OnIndentNpcStateChanged(...)
    end
end

function XUiRestaurantCommon:OnEnable()
    self:UpdateView()
    self:Update()
    self.Timer = XScheduleManager.ScheduleForever(function() 
        self:Update()
    end, 0, 0)
    self._Control:SubscribeEvent(XMVCA.XRestaurant.EventId.OnShowPerformTip, self._OnOnShowPerformTipCb)
    DoEnable = true
end

function XUiRestaurantCommon:OnDisable()
    self:ClearTimer()
    self._Control:UnsubscribeEvent(XMVCA.XRestaurant.EventId.OnShowPerformTip)
    local hashCode = self:GetHashCode()
    self._Control:GetBusiness():ClearBind(hashCode)
    self._Control:GetCashier():ClearBind(hashCode)
end

function XUiRestaurantCommon:OnDestroy()
    self:ClearTimer()
    self.DialogPool:Clear()
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

    self.GirdProduct.gameObject:SetActiveEx(false)
    self.GridDialogBox.gameObject:SetActiveEx(false)
    self.PanelRedPaper.gameObject:SetActiveEx(false)
    self.BtnIndent.gameObject:SetActiveEx(false)
    self.BtnPerform.gameObject:SetActiveEx(false)
    self.BtnMenu.gameObject:SetActiveEx(false)

    local model = self.Room:GetCashierModel()
    local cashierOffset = self._Control:Get3DGridOffset(1)
    ---@type XUiGrid3DCashier
    self.GridCashier = XUiGrid3DCashier.New(self.PanelCashier, self, nil, cashierOffset)
    self.GridCashier:SetTarget(model.transform)
    self.GridCashier:Show()
    
    local handBookOffset = self._Control:Get3DGridOffset(3)
    self.GridHandBook = XUiGrid3DHandBook.New(self.BtnMenu, self, nil, handBookOffset)
    self.GridHandBook:SetTarget(self.Room:GetBlackBoardModel())
    self.GridHandBook:Show()
end

function XUiRestaurantCommon:CreateGrid3DWorkBench(areaType, unlockCount, mapGrid, name)
    for i = 1, unlockCount do
        local grid = mapGrid[i]
        if not grid then
            local benchData = self._Control:GetWorkbenchPosInfo(areaType, i)
            local ui = XUiHelper.Instantiate(self.GirdProduct)
            ui.gameObject:SetActiveEx(true)
            grid = XUiGrid3DWorkBench.New(ui, self, self.ProductContainer, benchData.IconOffset)
            grid:SetName(name .. i)
            grid:SetTarget(self.Room:GetWorkBenchModel(areaType, i))
            mapGrid[i] = grid
        end
        local workBench = self._Control:GetWorkbench(areaType, i)
        grid:Show(workBench)
    end
end

function XUiRestaurantCommon:ShowDialog(id, content, emoji, target, offset)
    if XTool.UObjIsNil(self.GridDialogBox) then
        return
    end

    if XTool.UObjIsNil(target) then
        return
    end
    local dialog = self.GridDialog[id]
    if not dialog then
        local count = self.DialogPool:Count()
        if count > 0 then
            dialog = self.DialogPool:Pop()
        else
            local ui = XUiHelper.Instantiate(self.GridDialogBox, self.DialogContainer)
            dialog = XUiGrid3DDialog.New(ui, self, self.DialogContainer, offset)
        end
    end
    dialog:SetTarget(target)
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
    self.UiCanvas.sortingOrder = self._Control:GetMainSortingOrder() -1 

    --3DUi
    local ingredientCount, foodCount, saleCount = self._Control:GetWorkbenchCount()
    self:CreateGrid3DWorkBench(XMVCA.XRestaurant.AreaType.IngredientArea, ingredientCount, self.GridIngredient, "Ingredient")
    self:CreateGrid3DWorkBench(XMVCA.XRestaurant.AreaType.FoodArea, foodCount, self.GridFood, "Food")
    self:CreateGrid3DWorkBench(XMVCA.XRestaurant.AreaType.SaleArea, saleCount, self.GridSale, "Sale")
    
    self:ShowBillView()
    self.GridHandBook:Show()
    
    self:OnSceneLoad()
end

function XUiRestaurantCommon:UpdateView()
    local business = self._Control:GetBusiness()
    local hashCode = self:GetHashCode()
    local cashier = self._Control:GetCashier()
    --收银台3DUI
    cashier:BindViewModelPropertyToObj(hashCode, cashier.Property.Count, function(count)
        if not self.GridCashier then
            return
        end
        self.GridCashier:Show(count)
        for _, grid in pairs(self.GridSale) do
            grid:OnRefresh()
        end
    end)
    --签到小人
    business:BindViewModelPropertyToObj(hashCode, business.Property.IsGetSignReward, function(isReceive)
        if not isReceive then
            return
        end
        if not self.GridRedPaper then
            return
        end
        self.GridRedPaper:Hide()
    end)
    --签到红包
    business:BindViewModelPropertyToObj(hashCode, business.Property.CurDay, function()
        self:RefreshSign()
    end)
    --图鉴红点
    business:BindViewModelPropertyToObj(hashCode, business.Property.MenuRedPointMarkCount, function()
        if not self.GridHandBook then
            return
        end
        self.GridHandBook:RefreshRedPoint()
    end)
    --招募员工
    business:BindViewModelPropertyToObj(hashCode, business.Property.LevelConditionChange, function()
        self:RefreshWorkBenchRedPoint()
    end)
    --演出
    business:BindViewModelPropertiesToObj(hashCode,{
        business.Property.NotStartPerformId,
        business.Property.RunningPerformId,
    }, function(notStartId, runningId)
        self:RefreshPerformGrid()
    end)
    --订单
    self:TryLoadIndent()
    business:BindViewModelPropertyToObj(hashCode, business.Property.NotStartIndentId, function(indentId)
        --首次进入，不通过此接口
        if not DoEnable then
            return
        end
        -- 前一个订单还未执行完毕
        if self.GridOrder and self.GridOrder:IsShow() then
            return
        end
        
        local indentMd = self.Room:GetOrderNpcModel()
        --前一个角色的模型还在场景中
        if indentMd and indentMd.gameObject.activeInHierarchy then
            return
        end

        self.Room:TryLoadIndent()
    end)
    
    self:Refresh3DGridShow(true)
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

    if self.GridPerform then
        self.GridPerform:UpdateTransform(room)
    end
end 

function XUiRestaurantCommon:Refresh3DGridShow(state)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    local animName = state and "UiEnable" or "UiDisable"
    self:PlayAnimation(animName)
    if not state then
        self.GridCashier:Close()
        for _, grid in pairs(self.GridIngredient) do
            grid:Close()
        end
        for _, grid in pairs(self.GridFood) do
            grid:Close()
        end
        for _, grid in pairs(self.GridSale) do
            grid:Close()
        end
        return
    end
    local camera = self.Room:GetCameraModel()
    local areaType = camera:GetAreaType()
    local inIngredient = self._Control:IsIngredientArea(areaType)
    local inFood = self._Control:IsCookArea(areaType)
    local inSale = self._Control:IsSaleArea(areaType)
    if inSale then
        self.GridCashier:Open()
        self.GridHandBook:Open()
    else
        self.GridCashier:Close()
        self.GridHandBook:Close()
    end

    for _, grid in pairs(self.GridIngredient) do
        if inIngredient then
            grid:Open()
        else
            grid:Close()
        end
    end
    for _, grid in pairs(self.GridFood) do
        if inFood then
            grid:Open()
        else
            grid:Close()
        end
    end
    for _, grid in pairs(self.GridSale) do
        if inSale then
            grid:Open()
        else
            grid:Close()
        end
    end
end

function XUiRestaurantCommon:ShowBillView()
    if not self._Control:IsShowOfflineBill() then
        return
    end
    XLuaUiManager.Open("UiRestaurantBill")
end

function XUiRestaurantCommon:ClearTimer()
    if not self.Timer then
        return
    end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end 

function XUiRestaurantCommon:RefreshSign()
    local business = self._Control:GetBusiness()
    if not business:IsSignOpen() then
        return
    end
    if business:IsGetSignReward() or self.Room:SignNpcExist() then
        return
    end
    local signDay = business:GetSignCurDay()
    self.Room:LoadSignNpc(signDay)
end

function XUiRestaurantCommon:OnIndentNpcStateChanged(isValid, performId)
    if not isValid then
        if self.GridOrder then
            self.GridOrder:Hide()
        end
    else
        if not self.GridOrder then
            local offset = self._Control:Get3DGridOffset(2)
            self.GridOrder = XUiGrid3DOrder.New(self.BtnIndent, self, nil, offset)
        end
        self.GridOrder:SetTarget(self.Room:GetOrderNpcModel())
        self.GridOrder:Show(performId)
    end
end

function XUiRestaurantCommon:RefreshIndentGrid()
    if not self.GridOrder then
        return
    end
    if not self.GridOrder:IsShow() then
        return
    end
    local performId = self.GridOrder:GetPerformId()
    if not XTool.IsNumberValid(performId) then
        self.GridOrder:Hide()
        return
    end
    self.GridOrder:Show(performId)
end

function XUiRestaurantCommon:OnSceneLoad()
    RunAsyn(function()

        asynWaitSecond(0.2)
        --等待场景加载完毕
        while true do
            if self.Room:Exist() then
                break
            end

            asynWaitSecond(0.2)
        end

        self.Room:TryWorking()
        self:TryLoadIndent()
    end)
end

function XUiRestaurantCommon:TryLoadIndent()
    local running = self._Control:GetRunningIndent()
    if not running or running:IsFinish() then
        return
    end
    --第一次由OnStart执行
    if not DoEnable then
        return
    end
    self.Room:TryLoadIndent()
end

function XUiRestaurantCommon:RefreshPerformGrid()
    local perform = self._Control:GetRunningPerform()
    if not perform or perform:IsFinish() then
        if self.GridPerform then
            self.GridPerform:Hide()
        end
        return
    end
    local performMd = self._Control:GetRoom():GetPerform()
    if not performMd or not performMd:IsValid() then
        if self.GridPerform then
            self.GridPerform:Hide()
        end
        return
    end
    if not self.GridPerform then
        local offset = self._Control:Get3DGridOffset(4)
        self.GridPerform = XUiGrid3DPerform.New(self.BtnPerform, self, nil, offset)
    end
    self.GridPerform:SetTarget(self.Room:GetPerformStageModel())
    
    self.GridPerform:Show()
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

function XUiRestaurantCommon:GetHashCode()
    return self.GameObject:GetHashCode()
end

function XUiRestaurantCommon:OnShowPerformTip(performId)
    local perform = self._Control:GetPerform(performId)
    local grid = perform:IsIndent() and self.GridOrder or self.GridPerform
    if not grid then
        return
    end
    grid:ShowTip()
end