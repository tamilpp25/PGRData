
---@class XUiRestaurantEntrance : XLuaUi
local XUiRestaurantEntrance = XLuaUiManager.Register(XLuaUi, "UiRestaurantEntrance")

function XUiRestaurantEntrance:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantEntrance:OnStart()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local endTime = viewModel:GetShopEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    if self.TxtTime then
        self.TxtTime.text = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.PIVOT_COMBAT)
    end

    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose or not XDataCenter.RestaurantManager.IsOpen() then
            XDataCenter.RestaurantManager.OnActivityEnd(true)
            return
        end
        self.TxtTime.text = XUiHelper.GetTime(endTime - XTime.GetServerNowTimestamp(), XUiHelper.TimeFormatType.PIVOT_COMBAT)
    end)
end

function XUiRestaurantEntrance:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateView()
    self:RefreshRedPoint()
end

function XUiRestaurantEntrance:Close()
    self.Super.Close(self)
    XDataCenter.RestaurantManager.OnLeave()
    local isInBusiness = false
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    if viewModel then
        isInBusiness = viewModel:IsInBusiness()
    end
    if isInBusiness then
        XDataCenter.RestaurantManager.RequestExitRoom()
    end
end

function XUiRestaurantEntrance:OnRelease()
    XDataCenter.RestaurantManager.OnLeave()
end

function XUiRestaurantEntrance:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK or evt == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
    end
end

function XUiRestaurantEntrance:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK, XEventId.EVENT_TASK_SYNC }
end

function XUiRestaurantEntrance:InitUi()

end

function XUiRestaurantEntrance:InitCb()
    self:BindExitBtns()
    self:BindHelpBtn(self.BtnHelp, "UiRestaurantMain")
    
    self.BtnRight.CallBack = function() 
        self:OnEntryRestaurant()
    end
    
    self.BtnShop.CallBack = function() 
        self:OnBtnShopClick()
    end
    
    self.BtnTask.CallBack = function() 
        self:OnBtnTaskClick()
    end

    self.BtnMenu.CallBack = function()
        self:OnBtnMenuClick()
    end
end

function XUiRestaurantEntrance:UpdateView()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XRestaurantConfigs.ItemId.RestaurantShopCoin, XRestaurantConfigs.ItemId.RestaurantUpgradeCoin)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local isInBusiness = false
    if viewModel then
        isInBusiness = viewModel:IsInBusiness()

        self:BindViewModelPropertyToObj(viewModel, function()
            if XTool.UObjIsNil(self.BtnMenu) then
                return
            end
            self.BtnMenu:ShowReddot(XDataCenter.RestaurantManager.CheckMenuRedPoint())
        end, "_MenuRedPointMarkCount")
    end
    
    self.BtnRight:SetDisable(not isInBusiness)
    self.ImgOpenMask.gameObject:SetActiveEx(isInBusiness)
    self.ImgCloseMask.gameObject:SetActiveEx(not isInBusiness)
    self.BtnTask.gameObject:SetActiveEx(isInBusiness)
end

function XUiRestaurantEntrance:OnEntryRestaurant()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    if not viewModel or not viewModel:IsInBusiness() then
        XUiManager.TipMsg(XRestaurantConfigs.GetRestaurantNotInBusinessText())
        return
    end
    XRestaurantConfigs.Burying(XRestaurantConfigs.BuryingButton.BtnGo, self.Name)
    XLuaUiManager.Open("UiRestaurantMain")
end

function XUiRestaurantEntrance:OnBtnShopClick()
    XRestaurantConfigs.Burying(XRestaurantConfigs.BuryingButton.BtnShop, self.Name)
    XDataCenter.RestaurantManager.OpenShop()
end

function XUiRestaurantEntrance:OnBtnTaskClick()
    XRestaurantConfigs.Burying(XRestaurantConfigs.BuryingButton.BtnTask, self.Name)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local isInBusiness = false
    if viewModel then
        isInBusiness = viewModel:IsInBusiness()
    end
    XDataCenter.RestaurantManager.OpenTask(not isInBusiness)
end

function XUiRestaurantEntrance:OnBtnMenuClick()
    XRestaurantConfigs.Burying(XRestaurantConfigs.BuryingButton.BtnMenu, self.Name)
    XDataCenter.RestaurantManager.OpenMenu()
end

function XUiRestaurantEntrance:RefreshRedPoint()
    --任务红点
    self.BtnTask:ShowReddot(XDataCenter.RestaurantManager.CheckTaskRedPoint())
    self.BtnMenu:ShowReddot(XDataCenter.RestaurantManager.CheckMenuRedPoint())
end