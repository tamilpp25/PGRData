
local XUiRegressionActivity = XLuaUiManager.Register(XLuaUi, "UiRegressionActivity")

local Type2ModulePath = {
    [XRegression3rdConfigs.ActivityType.Main]       = "XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionMain",
    [XRegression3rdConfigs.ActivityType.Sign]       = "XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionSign",
    [XRegression3rdConfigs.ActivityType.Passport]   = "XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionPassport",
    [XRegression3rdConfigs.ActivityType.Task]       = "XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionTask",
    [XRegression3rdConfigs.ActivityType.Shop]       = "XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionShop",
    [XRegression3rdConfigs.ActivityType.Activity]   = "XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionActivity",
}

local ScheduleMinute = XScheduleManager.SECOND * 60

local DefaultSelectIndex = 1

function XUiRegressionActivity:OnAwake()
    self.ViewModel = XDataCenter.Regression3rdManager.GetViewModel()
    self.PanelDict = {}
    self:InitUi()
    self:InitCb()
end

function XUiRegressionActivity:OnStart()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XRegression3rdConfigs.Regression3rdCoinId }, self.PanelSpecialTool, self)

    self:InitView()
end

function XUiRegressionActivity:OnEnable()
    self.Super.OnEnable(self)
    if XTool.IsNumberValid(self.TabIndex) then
        self:RefreshView()
    else
        self.PanelBtnTab:SelectIndex(DefaultSelectIndex)
    end
    if not self.Timer then
        self.Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, ScheduleMinute)
    end
end

function XUiRegressionActivity:OnDisable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiRegressionActivity:InitUi()
    self:InitTab()

    self.BtnTabPrefab.gameObject:SetActiveEx(false)
end

function XUiRegressionActivity:InitCb()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    local helpKey = self.ViewModel:GetHelpKey()
    self:BindHelpBtn(self.BtnHelp, helpKey)
end

function XUiRegressionActivity:InitTab()
    local tabDataList = self.ViewModel:GetActivityOverViewList()
    self.TabBtn = {}
    for idx, tabData in ipairs(tabDataList or {}) do
        local open, _ = self.ViewModel:CheckOpenByActivityType(tabData.ActivityType)
        if tabData.ActivityType == XRegression3rdConfigs.ActivityType.Activity and not open then
            goto continue
        end
        local ui = XUiHelper.Instantiate(self.BtnTabPrefab, self.PanelBtnTab.transform)
        local btn = ui:GetComponent("XUiButton")
        btn:SetDisable(not open)
        btn:SetNameByGroup(0, tabData.Name)
        btn.gameObject:SetActiveEx(true)
        table.insert(self.TabBtn, btn)

        if tabData.RedPointEvent then
            self["RedPoint"..idx] = XRedPointManager.AddRedPointEvent(btn, function(_, count) self:CheckRedPoint(idx, count) end, self, { tabData.RedPointEvent })
        end

        ::continue::
    end

    self.TabData = tabDataList
    self.PanelBtnTab:Init(self.TabBtn, function(index) self:OnSelectTab(index) end)
end

function XUiRegressionActivity:InitView()
    local viewModel = self.ViewModel

    self:BindViewModelPropertyToObj(viewModel, function(rewardList)
        if XTool.IsTableEmpty(rewardList) then
            return
        end
        XUiManager.OpenUiObtain(rewardList)
        viewModel:ClearAutoRewardList()
    end, "_AutoRewardList")

    local endTime = viewModel:GetProperty("_ActivityEndTime")
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose or not XDataCenter.Regression3rdManager.IsOpen() then
            XDataCenter.Regression3rdManager.OnActivityEnd()
        end
    end)
end

function XUiRegressionActivity:OnSelectTab(index)
    if self.TabIndex == index then
        return
    end

    local viewData = self.TabData[index]

    local open, desc
    if viewData then
        open, desc = self.ViewModel:CheckOpenByActivityType(viewData.ActivityType)
    end

    if not open then
        XUiManager.TipMsg(desc)
        return
    end
    self.TabIndex = index
    self:RefreshView()
end

function XUiRegressionActivity:RefreshView()
    self:HideAllPanel()
    local panel = self:GetSubPanel()
    if not panel then
        return
    end
    self:PlayAnimationWithMask("QieHuan")
    local viewData = self.TabData[self.TabIndex]
    self.PanelSpine.gameObject:SetActiveEx(viewData.ActivityType == XRegression3rdConfigs.ActivityType.Main)
    panel:Show()
    self:RefreshRedPoint()
end

function XUiRegressionActivity:HideAllPanel()
    for _, panel in pairs(self.PanelDict) do
        if panel and not XTool.UObjIsNil(panel.GameObject) then
            panel:Hide()
        end
    end
end

function XUiRegressionActivity:UpdateTime()
    local panel = self:GetSubPanel()
    if not panel then
        return
    end
    panel:UpdateTime()
end

function XUiRegressionActivity:GetSubPanel()
    local viewData = self.TabData[self.TabIndex]
    if not viewData then
        XLog.Error("select invalid tab index: " .. self.TabIndex .. "tab config: ", self.TabData)
        return
    end

    local prefabPath = viewData.PrefabPath
    local panel = self.PanelDict[prefabPath]
    if not panel then
        local resource = CS.XResourceManager.Load(prefabPath)
        if not resource or not resource.Asset then
            XLog.Error("XUiRegressionActivity:GetSubPanel: load prefab error! asset path = " .. prefabPath)
            return {}
        end
        local ui = XUiHelper.Instantiate(resource.Asset, self.PanelContainer)
        CS.XResourceManager.AutoUnload(ui.gameObject, resource)
        local modulePath = Type2ModulePath[viewData.ActivityType]
        if string.IsNilOrEmpty(modulePath) then
            XLog.Error("init panel error: module path is empty! activity type = " .. viewData.ActivityType .. "activity overview id = " .. viewData.Id)
            return
        end
        panel = require(modulePath).New(ui, self)
        self.PanelDict[prefabPath] = panel
    end
    return panel
end

function XUiRegressionActivity:CheckRedPoint(index, count)
    self.TabBtn[index]:ShowReddot(count >= 0)
end

function XUiRegressionActivity:RefreshRedPoint()
    for idx, _ in ipairs(self.TabData or {}) do
        local redPointId = self["RedPoint"..idx]
        if XTool.IsNumberValid(redPointId) then
            XRedPointManager.Check(redPointId)
        end
    end
end