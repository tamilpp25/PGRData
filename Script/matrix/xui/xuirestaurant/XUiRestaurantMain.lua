local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")

---@class XUiRestaurantMain : XLuaUi
---@field _Control XRestaurantControl
---@field OrderExclamation XUiPanelExclamation
---@field PerformExclamation XUiPanelExclamation
local XUiRestaurantMain = XLuaUiManager.Register(XLuaUi, "UiRestaurantMain")

local XUiPanelStorage = require("XUi/XUiRestaurant/XUiPanel/XUiPanelStorage")
local XUiPanelExclamation = require("XUi/XUiRestaurant/XUiPanel/XUiPanelExclamation")

local TipShowTime = 2
local DoEnable = false

function XUiRestaurantMain:OnAwake()
    self.Room = self._Control:GetRoom()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantMain:OnStart(isOpenLevelUp)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XMVCA.XRestaurant.ItemId.RestaurantShopCoin, XMVCA.XRestaurant
            .ItemId.RestaurantUpgradeCoin)

    self.AssetPanel:RegisterJumpCallList({
        function()
            self:OnJumpToUiTip(XMVCA.XRestaurant.ItemId.RestaurantShopCoin)
        end,
        function()
            self:OnJumpToUiTip(XMVCA.XRestaurant.ItemId.RestaurantUpgradeCoin)
        end,
    })
    DoEnable = false
    self:InitView(isOpenLevelUp)

    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_SHOW_ASSIGN_WORK, self.ShowTips, self)
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XMVCA.XRestaurant.ItemId.RestaurantUpgradeCoin, self.OnCoinChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XMVCA.XRestaurant.ItemId.RestaurantShopCoin, self.OnCoinChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_WORK_BENCH_CHANGE_STAFF, self.RefreshArrowBtnRedPoint, self)
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_PERFORM_STATE_CHANGE, self.RefreshExclamation, self)
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_CHANGE_MAIN_VIEW_CAMERA_AREA_TYPE, self.DoChangeArea, self)
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_EMPLOY_STAFF, self.RefreshEmploy, self)
end

function XUiRestaurantMain:OnEnable()
    self.Super.OnEnable(self)

    self.Room:AddBeginDragCb(self._OnBeginDragCb)
    self.Room:AddEndDragCb(self._OnEndDragCb)
    
    self:UpdateView()

    DoEnable = true
end

function XUiRestaurantMain:OnDisable()
    self.Room:DelBeginDragCb(self._OnBeginDragCb)
    self.Room:DelEndDragCb(self._OnEndDragCb)
    if not self.CanvasGroup then
        local panel = self.Transform:Find("SafeAreaContentPane")
        if panel then
            self.CanvasGroup = panel.transform:GetComponent("CanvasGroup")
        end
    end

    -- 避免动画被打断，界面透明了
    if self.CanvasGroup then
        self.CanvasGroup.alpha = 1
    end
end

function XUiRestaurantMain:OnDestroy()
    self.PanelTips.gameObject:SetActiveEx(false)
    self:StopTipTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_SHOW_ASSIGN_WORK, self.ShowTips, self)

    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XMVCA.XRestaurant.ItemId.RestaurantUpgradeCoin, self.OnCoinChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XMVCA.XRestaurant.ItemId.RestaurantShopCoin, self.OnCoinChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_WORK_BENCH_CHANGE_STAFF, self.RefreshArrowBtnRedPoint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_PERFORM_STATE_CHANGE, self.RefreshExclamation, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_CHANGE_MAIN_VIEW_CAMERA_AREA_TYPE, self.DoChangeArea, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_EMPLOY_STAFF, self.RefreshEmploy, self)
end

function XUiRestaurantMain:OnRelease()
    self._Control:StopBusiness()
    self._Control:GetBusiness():ClearBind(self:GetHashCode())
    self.Super.OnRelease(self)
    --避免界面非正常关闭时，资源未被销毁
    XLuaUiManager.Remove("UiRestaurantCommon")
    XLuaUiManager.Remove("UiRestaurantMain")
end

function XUiRestaurantMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK or evt == XEventId.EVENT_TASK_SYNC then
        self:RefreshTaskRedPoint()
        self._Control:PopRecipeTaskTip()
    end
end

function XUiRestaurantMain:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK, XEventId.EVENT_TASK_SYNC }
end

function XUiRestaurantMain:Close()
    XLuaUiManager.Close("UiRestaurantCommon")
    self.Super.Close(self)
end

function XUiRestaurantMain:InitUi()
    self._Control:StartBusiness()
    
    self.PanelTips.gameObject:SetActiveEx(false)
    ---@type table<number, XUiPanelStorage>
    self.PanelStorageMap = {
        [XMVCA.XRestaurant.AreaType.IngredientArea] = XUiPanelStorage.New(self.PanelIngredient, self),
        [XMVCA.XRestaurant.AreaType.FoodArea] = XUiPanelStorage.New(self.PanelFood, self),
        [XMVCA.XRestaurant.AreaType.SaleArea] = XUiPanelStorage.New(self.PanelSale, self),
    }

    XLuaUiManager.Open("UiRestaurantCommon")
    
    --订单提示
    self.PanelIndent.gameObject:SetActiveEx(false)
    self.OrderExclamation = XUiPanelExclamation.New(self.PanelIndent, self, true)
    --剧情提示
    self.PanelStory.gameObject:SetActiveEx(false)
    self.PerformExclamation = XUiPanelExclamation.New(self.PanelStory, self, false)
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
    
    self.BtnPhoto.CallBack = function() 
        self:OnBtnPhotoClick()
    end
    
    self._OnBeginDragCb = function()
        self:SetUiState(false)
    end
    
    
    self._OnEndDragCb = function()
        local endCb = function()
            self:SetUiState(true)
            self:OnAreaTypeChange()
        end
        self.Room:OnStopMoveCamera(nil, endCb)
    end
    
    self.TipFunc = asynTask(function(msg, cb) 
        XUiManager.TipMsg(msg, nil, cb)
    end)
end

function XUiRestaurantMain:InitView(isOpenLevelUp)
    ---@type UnityEngine.Canvas
    local canvas = self.Transform:GetComponent("Canvas")
    if canvas then
        self._Control:SetMainSortingOrder(canvas.sortingOrder)
    end
    self:OnAreaTypeChange()
    
    local endTime = self._Control:GetActivityEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    if self.TxtTime then
        self.TxtTime.text = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.PIVOT_COMBAT)
    end
    
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose or not XMVCA.XRestaurant:IsOpen() then
            self.Room:ClearAllCustomer()
            XLuaUiManager.RunMain()
            XUiManager.TipText("CommonActivityEnd")
            return
        end
    end)
    
    local business = self._Control:GetBusiness()
    local hashCode = self:GetHashCode()
    --升级
    business:BindViewModelPropertyToObj(hashCode, business.Property.IsLevelUp, function(isLevelUp)
        self.IsLevelUp = isLevelUp
    end)
    --按钮状态
    business:BindViewModelPropertyToObj(hashCode, business.Property.RestaurantLv, function(level)
        local minLevel = self._Control:GetBuffUnlockMinLevel()
        self.BtnBuff:SetDisable(level < minLevel)
        self.BtnRestaurant:SetNameByGroup(0, "LV." .. level)
    end)
    --热销红点
    business:BindViewModelPropertyToObj(hashCode, business.Property.CurDay, function(curDay)
        self.BtnHot:ShowReddot(self._Control:CheckHotSaleRedPoint())
    end)
    --餐厅升级/空闲工作台红点
    business:BindViewModelPropertyToObj(hashCode, business.Property.LevelConditionChange, function()
        self.BtnRestaurant:ShowReddot(self._Control:CheckRestaurantUpgradeRedPoint())
        self:RefreshArrowBtnRedPoint()
    end)
    business:BindViewModelPropertyToObj(hashCode, business.Property.BuffRedPointMarkCount, function()
        self.BtnBuff:ShowReddot(self._Control:CheckBuffRedPoint())
        self:RefreshBuff()
    end)
    self:RefreshTaskRedPoint()

    if isOpenLevelUp then
        self:OnBtnRestaurantClick()
    end
    
    self:RefreshEmploy()
end

function XUiRestaurantMain:UpdateView()
    if DoEnable then
        self:OnAreaTypeChange()
    end
end

function XUiRestaurantMain:ShowTips(tips)
    self:StopTipTimer()
    self.TxtTips.text = tips
    self.PanelTips.gameObject:SetActiveEx(true)
    
    XLuaUiManager.SetMask(true)
    self.TipTimer = XScheduleManager.ScheduleOnce(function()
        self:StopTipTimer()
        XLuaUiManager.SetMask(false)
        if XTool.UObjIsNil(self.PanelTips.gameObject) then
            return
        end
        self.PanelTips.gameObject:SetActiveEx(false)
    end, XScheduleManager.SECOND * TipShowTime)
end

function XUiRestaurantMain:StopTipTimer()
    if not self.TipTimer then
        return
    end
    XScheduleManager.UnSchedule(self.TipTimer)
    self.TipTimer = nil
end

function XUiRestaurantMain:RefreshTaskRedPoint()
    --商店红点
    self.BtnTask:ShowReddot(self._Control:CheckTaskRedPoint())
end

function XUiRestaurantMain:RefreshPhotoRedPoint()
    self.BtnPhoto:ShowReddot(self._Control:CheckPhotoRedPoint())
end

--- 场景切换
---@param direction XAreaInfoNode
---@return void
--------------------------
function XUiRestaurantMain:OnBtnArrowClick(direction)
    if not direction then
        return
    end
    self:DoChangeArea(direction.Type)
end

function XUiRestaurantMain:DoChangeArea(areaType)
    local camera = self.Room:GetCameraModel()
    camera:MoveTo(areaType, function()
        self:SetUiState(false)
    end, function()
        self:SetUiState(true)
        self:OnAreaTypeChange()
    end)
end

function XUiRestaurantMain:OnBtnHotClick()
    XMVCA.XRestaurant:Burying(XMVCA.XRestaurant.BuryingButton.BtnHot, self.Name)
    self._Control:MarkHotSaleRedPoint()
    self.BtnHot:ShowReddot(false)
    XLuaUiManager.Open("UiRestaurantRecommend")
end

function XUiRestaurantMain:OnBtnShopClick()
    XMVCA.XRestaurant:Burying(XMVCA.XRestaurant.BuryingButton.BtnShop, self.Name)
    self._Control:OpenShop()
end

function XUiRestaurantMain:OnBtnTaskClick()
    XMVCA.XRestaurant:Burying(XMVCA.XRestaurant.BuryingButton.BtnTask, self.Name)
    self._Control:OpenTask()
end

function XUiRestaurantMain:OnBtnRestaurantClick()
    XLuaUiManager.Open("UiRestaurantHire")
end

function XUiRestaurantMain:OnBtnWorkerClick()
    XLuaUiManager.Open("UiRestaurantCook")
end

function XUiRestaurantMain:OnBtnStatisticsClick()
    XMVCA.XRestaurant:Burying(XMVCA.XRestaurant.BuryingButton.BtnStatistics, self.Name)
    local camera = self.Room:GetCameraModel()
    local areaType = camera:GetAreaType()
    areaType = self._Control:IsSaleArea(areaType)
            and XMVCA.XRestaurant.AreaType.IngredientArea or XMVCA.XRestaurant.AreaType.FoodArea
    self._Control:OpenStatistics(areaType)
end

function XUiRestaurantMain:OnBtnBuffClick()
    self._Control:OpenBuff(true)
end

function XUiRestaurantMain:OnBtnStopClick()
    local areaType = self.Room:GetCameraModel():GetAreaType()
    local workingCount = self._Control:GetWorkingCharacterCount(areaType)
    if workingCount <= 0 then
        XUiManager.TipMsg(self._Control:GetNoStaffWorkText())
        return
    end
    local title, content = self._Control:GetStopAllProductText()
    content = string.format(content, self._Control:GetAreaTypeName(areaType))
    self._Control:OpenPopup(title, content, nil, nil, function() 
        self._Control:RequestStopAllByArea(areaType)
    end)
end

function XUiRestaurantMain:OnBtnPhotoClick()
    XLuaUiManager.Open("UiRestaurantTakePhoto")
end

function XUiRestaurantMain:SetUiState(state)
    local animName = state and "UiEnable" or "UiDisable"
    self:PlayAnimation(animName)

    if not state then
        for _, panel in pairs(self.PanelStorageMap) do
            panel:Hide()
        end
    end
    self.OrderExclamation:Close()
    self.PerformExclamation:Close()
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
        self.BtnLeft:SetNameByGroup(0, self._Control:GetAreaTypeName(last.Type))
    end
    if next then
        self.BtnRight.gameObject:SetActiveEx(true)
        self.BtnRight:SetNameByGroup(0, self._Control:GetAreaTypeName(next.Type))
    end
    
    self:RefreshArrowBtnRedPoint()
    local areaType = camera:GetAreaType()
    for _, panel in pairs(self.PanelStorageMap) do
        panel:Hide()
    end
    
    local panel = self.PanelStorageMap[areaType]
    if panel then
        panel:Show(areaType)
    end
    
    self:RefreshExclamation()
end

function XUiRestaurantMain:RefreshArrowBtnRedPoint()
    local camera = self.Room:GetCameraModel()
    local last = camera:GetLastAreaInfo()
    local next = camera:GetNextAreaInfo()
    local cashierRedPoint, nextAreaPoint, lastAreaPoint = false, false, false
    if next then
        cashierRedPoint = self._Control:IsSaleArea(next.Type) and self._Control:CheckCashierLimitRedPoint()
        nextAreaPoint = self._Control:CheckWorkBenchRedPoint(next.Type)
    end

    if last then
        lastAreaPoint = self._Control:CheckWorkBenchRedPoint(last.Type)
    end

    self.BtnRight:ShowReddot(cashierRedPoint or nextAreaPoint)
    self.BtnLeft:ShowReddot(lastAreaPoint)
end

function XUiRestaurantMain:RefreshExclamation()
    if not self.GameObject.activeInHierarchy then
        return
    end
    self:RefreshPhotoRedPoint()
    local camera = self.Room:GetCameraModel()
    local areaType = camera:GetAreaType()
    if self._Control:IsSaleArea(areaType) then
        self.OrderExclamation:Close()
        self.PerformExclamation:Close()
        return
    end
    
    if not self._Control:CheckRunningIndentFinish() then
        self.OrderExclamation:Close()
    else
        self.OrderExclamation:Open()
    end

    if not self._Control:CheckRunningPerformFinish() then
        self.PerformExclamation:Close()
    else
        self.PerformExclamation:Open()
    end
end

function XUiRestaurantMain:RefreshEmploy()
    local limit = self._Control:GetCharacterLimit()
    local desc = string.format("%s/%s", self._Control:GetRecruitCharacterCount(), limit)
    self.BtnWorker:SetNameByGroup(0, desc)
end

function XUiRestaurantMain:RefreshBuff()
    local unlock, total = self._Control:GetBuffCount()
    local desc = string.format("%s/%s", unlock, total)
    self.BtnBuff:SetNameByGroup(0, desc)
end

---@param benchMap table<number, XBenchViewModel>
function XUiRestaurantMain:TryWorking(benchMap)
    if XTool.IsTableEmpty(benchMap) then
        return
    end
    for _, bench in pairs(benchMap) do
        bench:TryDoWork()
    end
end

function XUiRestaurantMain:OnJumpToUiTip(itemId)
    XLuaUiManager.Open("UiTip", itemId)
end 

function XUiRestaurantMain:OnCoinChanged(id, count)
    self.BtnRestaurant:ShowReddot(self._Control:CheckRestaurantUpgradeRedPoint())
end 

function XUiRestaurantMain:GetHashCode()
    return self.GameObject:GetHashCode()
end