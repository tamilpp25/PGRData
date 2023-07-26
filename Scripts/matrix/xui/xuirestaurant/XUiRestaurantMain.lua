
---@class XUiRestaurantMain : XLuaUi
local XUiRestaurantMain = XLuaUiManager.Register(XLuaUi, "UiRestaurantMain")

local XUiPanelStorage = require("XUi/XUiRestaurant/XUiPanel/XUiPanelStorage")

local TipShowTime = 2

function XUiRestaurantMain:OnAwake()
    self.Room = XDataCenter.RestaurantManager.GetRoom()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantMain:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XRestaurantConfigs.ItemId.RestaurantShopCoin, XRestaurantConfigs.ItemId.RestaurantUpgradeCoin)

    self.AssetPanel:RegisterJumpCallList({
        function()
            self:OnJumpToUiTip(XRestaurantConfigs.ItemId.RestaurantShopCoin)
        end,
        function()
            self:OnJumpToUiTip(XRestaurantConfigs.ItemId.RestaurantUpgradeCoin)
        end,
    })
    
    self:InitView()

    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_SHOW_ASSIGN_WORK, self.ShowTips, self)
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XRestaurantConfigs.ItemId.RestaurantUpgradeCoin, self.OnCoinChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XRestaurantConfigs.ItemId.RestaurantShopCoin, self.OnCoinChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_WORK_BENCH_CHANGE_STAFF, self.RefreshArrowBtnRedPoint, self)
end

function XUiRestaurantMain:OnEnable()
    self.Super.OnEnable(self)
end

function XUiRestaurantMain:OnDestroy()
    self.PanelTips.gameObject:SetActiveEx(false)
    if self.TipTimer then
        XScheduleManager.UnSchedule(self.TipTimer)
        self.TipTimer = nil
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_SHOW_ASSIGN_WORK, self.ShowTips, self)

    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XRestaurantConfigs.ItemId.RestaurantUpgradeCoin, self.OnCoinChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XRestaurantConfigs.ItemId.RestaurantShopCoin, self.OnCoinChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_WORK_BENCH_CHANGE_STAFF, self.RefreshArrowBtnRedPoint, self)
end

function XUiRestaurantMain:OnRelease()
    if self.IsLevelUp then
        XDataCenter.RestaurantManager.OnLeave(self.IsLevelUp)
    else
        XDataCenter.RestaurantManager.StopBusiness()
    end
    
    self.Super.OnRelease(self)
    --避免界面非正常关闭时，资源未被销毁
    XLuaUiManager.Remove("UiRestaurantCommon")
    XLuaUiManager.Remove("UiRestaurantMain")
end

function XUiRestaurantMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK or evt == XEventId.EVENT_TASK_SYNC then
        self:RefreshTaskRedPoint()
        XDataCenter.RestaurantManager.PopRecipeTaskTip()
    end
end

function XUiRestaurantMain:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK, XEventId.EVENT_TASK_SYNC }
end

function XUiRestaurantMain:Close()
    XLuaUiManager.Close("UiRestaurantCommon")
    self.Super.Close(self)
    if self.IsLevelUp then
        XDataCenter.RestaurantManager.OnLeave(self.IsLevelUp)
    else
        XDataCenter.RestaurantManager.StopBusiness()
    end
    --XDataCenter.RestaurantManager.OnLeave(self.IsLevelUp)
    --XDataCenter.RestaurantManager.RequestExitRoom()
end

function XUiRestaurantMain:InitUi()
    self.PanelTips.gameObject:SetActiveEx(false)
    ---@type table<number, XUiPanelStorage>
    self.PanelStorageMap = {
        [XRestaurantConfigs.AreaType.IngredientArea] = XUiPanelStorage.New(self.PanelIngredient, self),
        [XRestaurantConfigs.AreaType.FoodArea] = XUiPanelStorage.New(self.PanelFood, self),
        [XRestaurantConfigs.AreaType.SaleArea] = XUiPanelStorage.New(self.PanelSale, self),
    }

    XLuaUiManager.Open("UiRestaurantCommon")
end 

function XUiRestaurantMain:InitCb()
    self:BindExitBtns()
    self:BindHelpBtn()
    
    self.BtnLeft.CallBack = function()
        local camera = self.Room:GetCameraModel()
        self:OnBtnArrowClick(camera:GetLastAreaInfo())
    end

    self.BtnRight.CallBack = function()
        local camera = self.Room:GetCameraModel()
        self:OnBtnArrowClick(camera:GetNextAreaInfo())
    end
    
    self.BtnHot.CallBack = function() 
        self:OnBtnHotClick()
    end

    self.BtnShop.CallBack = function()
        self:OnBtnShopClick()
    end

    self.BtnTask.CallBack = function()
        self:OnBtnTaskClick()
    end

    self.BtnRestaurant.CallBack = function()
        self:OnBtnRestaurantClick()
    end

    self.BtnWorker.CallBack = function()
        self:OnBtnWorkerClick()
    end
    
    self.BtnStatistics.CallBack = function() 
        self:OnBtnStatisticsClick()
    end
    
    self.BtnBuff.CallBack = function() 
        self:OnBtnBuffClick()
    end
    
    self.BtnStop.CallBack = function() 
        self:OnBtnStopClick()
    end
    
    self.Room:AddBeginDragCb(function() 
        self:SetUiState(false)
    end)
    
    self.Room:AddEndDragCb(function() 
        local endCb = function() 
            self:SetUiState(true)
            self:OnAreaTypeChange()
        end
        self.Room:OnStopMoveCamera(nil, endCb)
    end)
    
    self.TipFunc = asynTask(function(msg, cb) 
        XUiManager.TipMsg(msg, nil, cb)
    end)
end

function XUiRestaurantMain:InitView()
    
    XDataCenter.RestaurantManager.StartBusiness()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    ---@type UnityEngine.Canvas
    local canvas = self.Transform:GetComponent("Canvas")
    if canvas then
        viewModel:SetProperty("_UiMainSorting", canvas.sortingOrder)
    end
    self:OnAreaTypeChange()
    
    local endTime = viewModel:GetBusinessEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    if self.TxtTime then
        self.TxtTime.text = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.PIVOT_COMBAT)
    end
    
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose or not XDataCenter.RestaurantManager.IsOpen() then
            self.Room:ClearAllCustomer()
            XLuaUiManager.RunMain()
            XUiManager.TipText("CommonActivityEnd")
            return
        end
    end)
    
    --备菜台
    self:BindViewModelPropertyToObj(viewModel, function(map)
        self:TryWorking(map)
    end, "_IngredientWorkBenches")
    --烹饪台
    self:BindViewModelPropertyToObj(viewModel, function(map)
        self:TryWorking(map)
    end, "_CookingWorkBenches")
    --售卖台
    self:BindViewModelPropertyToObj(viewModel, function(map)
       self:TryWorking(map)
    end, "_SalesWorkBenches")
    
    --升级
    self:BindViewModelPropertyToObj(viewModel, function(isLevelUp)
        if not isLevelUp then
            return
        end
        self.IsLevelUp = true
        self:Close()
        XDataCenter.RestaurantManager.EnterUiMain(self.IsLevelUp)
    end, "_IsLevelUp")
    
    --按钮状态
    self:BindViewModelPropertyToObj(viewModel, function(level)
        local minLevel = XRestaurantConfigs.GetBuffUnlockMinLevel()
        self.BtnBuff:SetDisable(level < minLevel)
    end, "_Level")
    
    --热销红点
    self:BindViewModelPropertyToObj(viewModel, function(curDay) 
        self.BtnHot:ShowReddot(XDataCenter.RestaurantManager.CheckHotSaleRedPoint())
    end, "_CurDay")
    
    --餐厅升级/空闲工作台红点
    self:BindViewModelPropertyToObj(viewModel, function() 
        self.BtnRestaurant:ShowReddot(XDataCenter.RestaurantManager.CheckRestaurantUpgradeRedPoint())
        self:RefreshArrowBtnRedPoint()
    end, "_EventLevelConditionChange")
    
    --buff红点
    self:BindViewModelPropertyToObj(viewModel, function() 
        self.BtnBuff:ShowReddot(XDataCenter.RestaurantManager.CheckBuffRedPoint())
    end, "_BuffRedPointMarkCount")

    self:RefreshTaskRedPoint()
end

function XUiRestaurantMain:ShowTips(tips)
    self.TxtTips.text = tips
    self.PanelTips.gameObject:SetActiveEx(true)
    XLuaUiManager.SetMask(true)
    self.TipTimer = XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.SetMask(false)
        if XTool.UObjIsNil(self.PanelTips.gameObject) then
            return
        end
        self.PanelTips.gameObject:SetActiveEx(false)
    end, XScheduleManager.SECOND * TipShowTime)
end

function XUiRestaurantMain:RefreshTaskRedPoint()
    --商店红点
    self.BtnTask:ShowReddot(XDataCenter.RestaurantManager.CheckTaskRedPoint())
end

--- 场景切换
---@param direction XAreaInfoNode
---@return void
--------------------------
function XUiRestaurantMain:OnBtnArrowClick(direction)
    if not direction then
        return
    end
    local camera = self.Room:GetCameraModel()
    camera:MoveTo(direction.Type, function() 
        self:SetUiState(false)
    end, function()
        self:SetUiState(true)
        self:OnAreaTypeChange()
    end)
end

function XUiRestaurantMain:OnBtnHotClick()
    XRestaurantConfigs.Burying(XRestaurantConfigs.BuryingButton.BtnHot, self.Name)
    XDataCenter.RestaurantManager.MarkHotSaleRedPoint()
    self.BtnHot:ShowReddot(false)
    XLuaUiManager.Open("UiRestaurantRecommend")
end

function XUiRestaurantMain:OnBtnShopClick()
    XRestaurantConfigs.Burying(XRestaurantConfigs.BuryingButton.BtnShop, self.Name)
    XDataCenter.RestaurantManager.OpenShop()
end

function XUiRestaurantMain:OnBtnTaskClick()
    XRestaurantConfigs.Burying(XRestaurantConfigs.BuryingButton.BtnTask, self.Name)
    XDataCenter.RestaurantManager.OpenTask()
end

function XUiRestaurantMain:OnBtnRestaurantClick()
    XLuaUiManager.Open("UiRestaurantHire")
end

function XUiRestaurantMain:OnBtnWorkerClick()
    XLuaUiManager.Open("UiRestaurantCook")
end

function XUiRestaurantMain:OnBtnStatisticsClick()
    XRestaurantConfigs.Burying(XRestaurantConfigs.BuryingButton.BtnStatistics, self.Name)
    local camera = self.Room:GetCameraModel()
    local areaType = camera:GetAreaType()
    areaType = XRestaurantConfigs.CheckIsIngredientArea(areaType)
            and XRestaurantConfigs.AreaType.IngredientArea or XRestaurantConfigs.AreaType.FoodArea
    XDataCenter.RestaurantManager.OpenStatistics(areaType)
end

function XUiRestaurantMain:OnBtnBuffClick()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local level = viewModel:GetProperty("_Level")
    local minLevel = XRestaurantConfigs.GetBuffUnlockMinLevel()
    if minLevel > level then
        XUiManager.TipMsg(string.format(XRestaurantConfigs.GetCommonUnlockText(2), minLevel))
        return
    end
    XLuaUiManager.Open("UiRestaurantBuff")
end

function XUiRestaurantMain:OnBtnStopClick()
    local workingCount = XDataCenter.RestaurantManager.GetViewModel():GetOnBenchStaffCount()
    if workingCount <= 0 then
        XUiManager.TipMsg(XRestaurantConfigs.GetNoStaffWorkText())
        return
    end
    local title, content = XRestaurantConfigs.GetStopAllProductText()
    XDataCenter.RestaurantManager.OpenPopup(title, content, nil, nil, function() 
        XDataCenter.RestaurantManager.RequestStopAll()
    end)
end

function XUiRestaurantMain:SetUiState(state)
    local animName = state and "UiEnable" or "UiDisable"
    self:PlayAnimation(animName)

    if not state then
        for _, panel in pairs(self.PanelStorageMap) do
            panel:Hide()
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_SHOW_MAIN_UI, state)
end

function XUiRestaurantMain:OnAreaTypeChange()
    local camera = self.Room:GetCameraModel()
    local last = camera:GetLastAreaInfo()
    local next = camera:GetNextAreaInfo()
    self.BtnLeft.gameObject:SetActiveEx(false)
    self.BtnRight.gameObject:SetActiveEx(false)
    if last then
        self.BtnLeft.gameObject:SetActiveEx(true)
        self.BtnLeft:SetNameByGroup(0, XRestaurantConfigs.GetCameraAuxiliaryAreaName(last.Type))
    end
    if next then
        self.BtnRight.gameObject:SetActiveEx(true)
        self.BtnRight:SetNameByGroup(0, XRestaurantConfigs.GetCameraAuxiliaryAreaName(next.Type))
    end
    
    self:RefreshArrowBtnRedPoint()
    local areaType = camera:GetAreaType()
    for _, panel in pairs(self.PanelStorageMap) do
        panel:Hide()
    end
    
    local panel = self.PanelStorageMap[areaType]
    if panel then
        panel:Show(areaType, nil, "_Count")
    end
end

function XUiRestaurantMain:RefreshArrowBtnRedPoint()
    local camera = self.Room:GetCameraModel()
    local last = camera:GetLastAreaInfo()
    local next = camera:GetNextAreaInfo()
    local cashierRedPoint, nextAreaPoint, lastAreaPoint = false, false, false
    if next then
        cashierRedPoint = XRestaurantConfigs.CheckIsSaleArea(next.Type) and XDataCenter.RestaurantManager.CheckCashierLimitRedPoint()
        nextAreaPoint = XDataCenter.RestaurantManager.CheckWorkBenchRedPoint(next.Type)
    end

    if last then
        lastAreaPoint = XDataCenter.RestaurantManager.CheckWorkBenchRedPoint(last.Type)
    end

    self.BtnRight:ShowReddot(cashierRedPoint or nextAreaPoint)
    self.BtnLeft:ShowReddot(lastAreaPoint)
end

function XUiRestaurantMain:TryWorking(benchMap)
    if XTool.IsTableEmpty(benchMap) then
        return
    end
    for _, bench in pairs(benchMap) do
        bench:TryWorking()
    end
end

function XUiRestaurantMain:OnJumpToUiTip(itemId)
    XLuaUiManager.Open("UiTip", itemId)
end 

function XUiRestaurantMain:OnCoinChanged(id, count)
    self.BtnRestaurant:ShowReddot(XDataCenter.RestaurantManager.CheckRestaurantUpgradeRedPoint())
end 