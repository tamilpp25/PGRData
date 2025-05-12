local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--######################## XUiSignInItem ########################
local XUiSignInItem = XClass(nil, "XUiSignInItem")

function XUiSignInItem:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.Data = nil
    self.SignInManager = XDataCenter.NewRegressionManager.GetSignInManager()
end

function XUiSignInItem:SetData(data, index)
    local assetGo = self.Transform:LoadPrefab(data.AssetPath)
    local uiObject = assetGo.transform:GetComponent("UiObject")
    XTool.InitUiObjectByInstance(uiObject, self)
    self.Data = data
    -- 天数
    self.TxtNumber.text = data.Days
    self:Refresh()
end

function XUiSignInItem:Refresh()
    -- 奖励状态
    local canGetReward = self.SignInManager:CheckCanGetReward(self.Data.Id)
    local finishReward = self.SignInManager:GetIsFinishReward(self.Data.Id)
    self.ImgAvailable.gameObject:SetActiveEx(canGetReward)
    self.ImgReceived.gameObject:SetActiveEx(finishReward)
    self.ImgTime.gameObject:SetActiveEx(not canGetReward and not finishReward)
    local endTime = XTime.GetTimeDayFreshTime(self.SignInManager:GetEndTime(self.Data.Days - 1))
    self.TxtTime.text = XUiHelper.GetText("NewRegressionSigninTimeTip3", self.Data.Days)
end

--######################## XUiSignInPanel ########################
local XUiSignInPanel = XClass(XSignalData, "XUiSignInPanel")

function XUiSignInPanel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.NewRegressionManager = XDataCenter.NewRegressionManager
    self.SignInManager = XDataCenter.NewRegressionManager.GetSignInManager()
    -- 签到动态列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiSignInItem)
    self.DynamicTable:SetDelegate(self)
    self.PanelItem.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiSignInPanel:SetData()
    self.TxtTotalTime.text = XUiHelper.GetText("NewRegressionSignInTimeTip", self.SignInManager:GetContinueDay())
    self:RefreshLeaveTime()
    self:RefreshSignInItems()
end

function XUiSignInPanel:UpdateWithSecond(isClose)
    self:RefreshLeaveTime()
    self:RefreshGridsStatus()
end

--######################## 私有方法 ########################

function XUiSignInPanel:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnStory, self.OnBtnStoryClicked)
end

function XUiSignInPanel:OnBtnStoryClicked()
    XDataCenter.MovieManager.PlayMovie(self.NewRegressionManager.GetStoryId())
end

-- 刷新倒计时
function XUiSignInPanel:RefreshLeaveTime()
    local leaveTimeStr = XDataCenter.NewRegressionManager.GetLeaveTimeStr(nil, XNewRegressionConfigs.ActivityState.InRegression)
    self.TxtRefreshTime.text = XUiHelper.GetText("NewRegressionSignInTimeTip2", leaveTimeStr)
end

function XUiSignInPanel:RefreshGridsStatus()
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:Refresh()
    end
end

function XUiSignInPanel:RefreshSignInItems()
    self.DynamicTable:SetDataSource(self.SignInManager:GetSignInDatas())
    self.DynamicTable:ReloadDataSync(1)
end

function XUiSignInPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.DynamicTable.DataSource[index], index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnSignInItemClicked(index)
    end
end

function XUiSignInPanel:OnSignInItemClicked(index)
    local signInId = self.DynamicTable.DataSource[index].Id
    self.SignInManager:RequestGetReward(signInId, function()
        self:RefreshSignInItems()
        self:EmitSignal("RefreshRedPoint")
    end)
end

return XUiSignInPanel
