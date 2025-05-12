local XUiGridTask = require("XUi/XUiTask/XUiGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiLivWarmSoundsActivityTaskPanel = XClass(nil, "UiLivWarmSoundsActivityTaskPanel")
local XUiGridTaskLivWarmSounds = require("XUi/XUiLivWarmActivity/XUiLivWarmSoundsActivityTaskGrid")

function XUiLivWarmSoundsActivityTaskPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self:InitAutoScript()
    if not self.DynamicRewardList then
        self.DynamicRewardList = XDynamicTableNormal.New(self.SViewRewardList.gameObject)
        self.DynamicRewardList:SetProxy(XUiGridTaskLivWarmSounds)
        self.DynamicRewardList:SetDelegate(self)
    end
end

function XUiLivWarmSoundsActivityTaskPanel:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiLivWarmSoundsActivityTaskPanel:AutoInitUi()
    self.BtnMask = self.Transform:Find("BtnMask"):GetComponent("Button")
    self.PanelReward = self.Transform:Find("PanelReward")
    self.SViewRewardList = self.Transform:Find("PanelReward/SViewRewardList"):GetComponent("ScrollRect")
    self.GridCheckPointReward = self.Transform:Find("PanelReward/SViewRewardList/Viewport/GridCheckPointReward")
    self.PanelBg = self.Transform:Find("PanelReward/PanelBg")
end

function XUiLivWarmSoundsActivityTaskPanel:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiLivWarmSoundsActivityTaskPanel:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiLivWarmSoundsActivityTaskPanel:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiLivWarmSoundsActivityTaskPanel:AutoAddListener()
    self:RegisterClickEvent(self.BtnMask, self.OnBtnMaskClick)
end

function XUiLivWarmSoundsActivityTaskPanel:OnBtnMaskClick()
    self.GameObject:SetActive(false)
end

function XUiLivWarmSoundsActivityTaskPanel:UpdateRewardList(type)
    self.taskList = XDataCenter.TaskManager.GetSortTaskListByTaskType(type)
    if self.DynamicRewardList then
        self.DynamicRewardList:SetDataSource(self.taskList)
        self.DynamicRewardList:ReloadDataASync()
    end
end

function XUiLivWarmSoundsActivityTaskPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi, self)
        self.GridCheckPointReward.gameObject:SetActive(false)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.taskList[index]
        if data ~= nil then
            grid:ResetData(data)
        end
    end
end

return XUiLivWarmSoundsActivityTaskPanel