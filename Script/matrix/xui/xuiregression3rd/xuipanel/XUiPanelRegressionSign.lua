
local XUiPanelRegressionBase = require("XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionBase")
local XUiGridRegressionTask = require("XUi/XUiRegression3rd/XUiGrid/XUiGridRegressionTask")

local XUiPanelRegressionSign = XClass(XUiPanelRegressionBase, "XUiPanelRegressionSign")

--region   ------------------重写父类方法 start-------------------

function XUiPanelRegressionSign:Show()
    self:RefreshView()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelRegressionSign:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelRegressionSign:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(XUiGridRegressionTask, self.RootUi)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiPanelRegressionSign:InitCb()
    self.BtnPreview.CallBack = function()
        local rewardId = tonumber(XRegression3rdConfigs.GetClientConfigValue("SignPreviewRewardId", 1))
        if not XTool.IsNumberValid(rewardId) then
            return
        end
        XUiManager.OpenUiTipRewardByRewardId(rewardId)
    end
end

function XUiPanelRegressionSign:UpdateTime()
    self.TxtTime.text = self.ViewModel:GetLeftTimeDesc()
end

--endregion------------------重写父类方法 finish------------------

function XUiPanelRegressionSign:RefreshView()
    if not XDataCenter.Regression3rdManager.CheckSignLocalRedPointData() then
        XDataCenter.Regression3rdManager.MarkSignLocalRedPointData()
    end
    local signViewModel = self.ViewModel:GetSignViewModel()
    
    self.RootUi:BindViewModelPropertyToObj(signViewModel, function(signDay)
        self.TxtCumulative.text = string.format(XRegression3rdConfigs.GetClientConfigValue("SignDaysDesc", 1), signDay)
    end, "_SignDay")
    
    self:SetupDynamicTable()
    
    self:UpdateTime()
end

function XUiPanelRegressionSign:SetupDynamicTable()
    local signViewModel = self.ViewModel:GetSignViewModel()
    self.SignList = signViewModel:GetSignInfos()
    
    self.DynamicTable:SetDataSource(self.SignList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelRegressionSign:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshSign(self.SignList[index])
    end
end


return XUiPanelRegressionSign