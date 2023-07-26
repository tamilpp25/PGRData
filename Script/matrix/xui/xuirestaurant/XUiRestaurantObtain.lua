
---@class XUiRestaurantObtain : XLuaUi
local XUiRestaurantObtain = XLuaUiManager.Register(XLuaUi, "UiRestaurantObtain")


function XUiRestaurantObtain:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantObtain:OnStart(rewardGoodsList, title, closeCallback, sureCallback)
    if title then
        self.TxtTitle.text = title
    end
    self.GoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    self.CloseCb = closeCallback
    self.ConfirmCb = sureCallback
    self:InitView()
end

function XUiRestaurantObtain:InitUi()
    
    self.DynamicTable = XDynamicTableNormal.New(self.ScrView)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridCommon)
    
    self.GridCommon.gameObject:SetActiveEx(false)
end

function XUiRestaurantObtain:InitCb()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnSure, self.OnBtnSureClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
end

function XUiRestaurantObtain:InitView()
    self.BtnSure.gameObject:SetActiveEx(self.ConfirmCb ~= nil)
    self.BtnCancel.gameObject:SetActiveEx(self.CloseCb ~= nil)
    self:SetupDynamicTable()
end

function XUiRestaurantObtain:SetupDynamicTable()
    self.DynamicTable:SetDataSource(self.GoodsList)
    self.DynamicTable:ReloadDataSync()
end

function XUiRestaurantObtain:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.GoodsList[index])
    end
end

function XUiRestaurantObtain:OnBtnSureClick()
    self:Close()
    if self.ConfirmCb then
        self.ConfirmCb()
    end
end

function XUiRestaurantObtain:OnBtnCancelClick()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end