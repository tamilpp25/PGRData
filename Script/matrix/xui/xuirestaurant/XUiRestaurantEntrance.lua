local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@class XUiRestaurantEntrance : XLuaUi
---@field _Control XRestaurantControl
local XUiRestaurantEntrance = XLuaUiManager.Register(XLuaUi, "UiRestaurantEntrance")

function XUiRestaurantEntrance:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantEntrance:OnStart()
    local business = self._Control:GetBusiness()
    local isInBusiness = business:IsInBusiness()
    local endTime = isInBusiness and self._Control:GetActivityEndTime() or self._Control:GetShopEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    if self.TxtTime then
        self.TxtTime.text = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.PIVOT_COMBAT)
    end

    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose or not XMVCA.XRestaurant:IsOpen() then
            self._Control:OnActivityEnd()
            return
        end
        self.TxtTime.text = XUiHelper.GetTime(endTime - XTime.GetServerNowTimestamp(), XUiHelper.TimeFormatType.PIVOT_COMBAT)
    end)
    
    self._Control:SubscribeEvent(XMVCA.XRestaurant.EventId.OnShopUiClose, function() 
        self:RefreshComplete()
    end)
    self._Control:UpdateOfflineRecord()
end

function XUiRestaurantEntrance:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateView()
    self:RefreshRedPoint()
end

function XUiRestaurantEntrance:OnRelease()
    self._Control:ExitRoom()
    self.Super.OnRelease(self)
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
    self.PanelItem.gameObject:SetActiveEx(false)
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

    self.BtnLv.CallBack = function()
        self:OnBtnLvClick()
    end
end

function XUiRestaurantEntrance:UpdateView()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XMVCA.XRestaurant.ItemId.RestaurantShopCoin, 
            XMVCA.XRestaurant.ItemId.RestaurantUpgradeCoin)
    
    local business = self._Control:GetBusiness()
    local isInBusiness = business:IsInBusiness()
    
    business:BindViewModelPropertyToObj(self.Name, business.Property.MenuRedPointMarkCount, function()
        if XTool.UObjIsNil(self.BtnMenu) then
            return
        end
        self.BtnMenu:ShowReddot(self._Control:CheckMenuRedPoint())
    end)
    self.BtnRight:SetDisable(not isInBusiness)
    self.ImgOpenMask.gameObject:SetActiveEx(isInBusiness)
    self.ImgCloseMask.gameObject:SetActiveEx(not isInBusiness)
    self.BtnTask.gameObject:SetActiveEx(isInBusiness)
    self:RefreshComplete()
    self:RefreshRestaurantInfo()
end

function XUiRestaurantEntrance:OnEntryRestaurant(isOpenLevelUp)
    local business = self._Control:GetBusiness()
    local isInBusiness = business:IsInBusiness()
    if not isInBusiness then
        XUiManager.TipMsg(self._Control:GetRestaurantNotInBusinessText())
        return
    end
    XMVCA.XRestaurant:Burying(XMVCA.XRestaurant.BuryingButton.BtnGo, self.Name)
    XLuaUiManager.Open("UiRestaurantMain")
end

function XUiRestaurantEntrance:OnBtnShopClick()
    XMVCA.XRestaurant:Burying(XMVCA.XRestaurant.BuryingButton.BtnShop, self.Name)
    self._Control:OpenShop()
end

function XUiRestaurantEntrance:OnBtnTaskClick()
    XMVCA.XRestaurant:Burying(XMVCA.XRestaurant.BuryingButton.BtnTask, self.Name)
    local business = self._Control:GetBusiness()
    local isInBusiness = business:IsInBusiness()
    self._Control:OpenTask(not isInBusiness)
end

function XUiRestaurantEntrance:OnBtnMenuClick()
    XMVCA.XRestaurant:Burying(XMVCA.XRestaurant.BuryingButton.BtnMenu, self.Name)
    self._Control:OpenMenu()
end

function XUiRestaurantEntrance:RefreshRedPoint()
    --任务红点
    self.BtnTask:ShowReddot(self._Control:CheckTaskRedPoint())
    self.BtnMenu:ShowReddot(self._Control:CheckMenuRedPoint())
    self.BtnLv:ShowReddot(self._Control:CheckRestaurantUpgradeRedPoint())
end

function XUiRestaurantEntrance:RefreshShopReward(isComplete)
    self.PanelItem.gameObject:SetActiveEx(not isComplete)
    if isComplete then
        return
    end
    if not self.Rewards then
        self.Rewards = {}
    end
    local rewardId = self._Control:GetShopRewardId()
    local rewardList = XRewardManager.GetRewardList(rewardId)
    for index, reward in ipairs(rewardList) do
        local grid = self.Rewards[index]
        if not grid then
            local ui = index == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelItem)
            grid = XUiGridCommon.New(self, ui)
            self.Rewards[index] = grid
        end
        grid:Refresh(reward)
    end
end

function XUiRestaurantEntrance:RefreshRestaurantInfo()
    local level = self._Control:GetRestaurantLv()
    self.TxtTitle.text = string.format("%s%s", self._Control:GetRestaurantInfoText(1), level)
    
    local itemId = XMVCA.XRestaurant.ItemId.RestaurantUpgradeCoin
    local count = XDataCenter.ItemManager.GetCount(itemId)
    self.BtnLv:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
    local needCount = 0
    local consumeId, consumeCount = self._Control:GetUpgradeConsume()
    for index, id in ipairs(consumeId) do
        if itemId == id then
            needCount = consumeCount[index] or 0
            break
        end
    end
    local subCount = math.max(0, needCount - count)
    local isMax = XMVCA.XRestaurant:IsMaxLevel()
    local tip = isMax and "" or string.format(self._Control:GetRestaurantInfoText(2), subCount)
    self.BtnLv:SetNameByGroup(0, tip)
    self.BtnLv:SetNameByGroup(1, count)
    self.BtnLv:ShowTag(isMax)
    self.ImgLevelUpBar.fillAmount = math.min(1, count / needCount)
end

function XUiRestaurantEntrance:OnBtnLvClick()
    self:OnEntryRestaurant(true)
end

function XUiRestaurantEntrance:RefreshComplete()
    XMVCA.XRestaurant:CheckShopComplete(function(complete) 
        self.BtnShop:ShowTag(complete)
        self:RefreshShopReward(complete)
    end)
    
    self.BtnTask:ShowTag(self._Control:IsAllTaskFinished())
    self.BtnMenu:ShowTag(self._Control:IsAllLogCollect())
end