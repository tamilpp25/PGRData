local XUiFubenExperiment = XLuaUiManager.Register(XLuaUi, "UiFubenExperiment")
local ParseToTimestamp = XTime.ParseToTimestamp
local XUiFubenExperimentBanner = require("XUi/XUiFubenExperiment/XUiFubenExperimentBanner")

function XUiFubenExperiment:OnAwake()
    self:AddListener()
end

function XUiFubenExperiment:OnStart(selectIdx)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
    XDataCenter.ItemManager.ItemId.FreeGem,
    XDataCenter.ItemManager.ItemId.ActionPoint,
    XDataCenter.ItemManager.ItemId.Coin)
    self.TrialGroup = XDataCenter.FubenExperimentManager.GetShowTrialGroup(function(a, b)
        return a.Order < b.Order
    end)
    self.BtnTabGoList = {}
    self.CurSelectIndex = 1
    self.BannerList = {}
    self:InitDynamicTable()
    self:InitTab(selectIdx)
    XEventManager.AddEventListener(XEventId.EVENT_UPDATE_EXPERIMENT, self.UpdateCurBannerState, self)
end

function XUiFubenExperiment:OnEnable()
    self:UpdateLeftTabGroup()
    self:UpdateCurBannerState()
    self:UpdateToggleRedPoint()
end

function XUiFubenExperiment:OnDestroy()
    XCountDown.RemoveTimer(self.GameObject.name)
    XEventManager.RemoveEventListener(XEventId.EVENT_UPDATE_EXPERIMENT, self.UpdateCurBannerState, self)
end

function XUiFubenExperiment:InitTab(selectIdx)
    --CreateGameObject
    for i = 1, #self.TrialGroup do
        if not self.BtnTabGoList[i] then
            local tempBtnTab
            if self.TrialGroup[i].SubIndex > 0 then
                tempBtnTab = CS.UnityEngine.Object.Instantiate(self.Obj:GetPrefab("BtnTab2"))
            else
                tempBtnTab = CS.UnityEngine.Object.Instantiate(self.Obj:GetPrefab("BtnTab1"))
            end
            tempBtnTab.transform:SetParent(self.TabBtnContent, false)
            local uiButton = tempBtnTab:GetComponent("XUiButton")
            uiButton.SubGroupIndex = self.TrialGroup[i].SubIndex
            table.insert(self.BtnTabGoList, uiButton)
        end
        self.BtnTabGoList[i]:SetName(self.TrialGroup[i].Name)
        self.BtnTabGoList[i].gameObject:SetActiveEx(self:CheckTime(i))
    end

    --防止配置的subIndex因为有按钮隐藏指向错误的button，所以重新计算一遍
    local subIndex = 0
    for i = 1, #self.BtnTabGoList do
        if self.BtnTabGoList[i].SubGroupIndex > 0 then
            self.BtnTabGoList[i].SubGroupIndex = subIndex
        else
            subIndex = i
        end

    end

    for i = #self.BtnTabGoList, #self.TrialGroup + 1, -1 do
        CS.UnityEngine.Object.Destroy(self.BtnTabGoList[i].gameObject)
        table.remove(self.BtnTabGoList, i)
    end
    --BtnGroup
    self.TabBtnGroup:Init(self.BtnTabGoList, function(index) self:OnSelectedTog(index) end)
    --刷新Toggle红点
    self:UpdateToggleRedPoint()
    --default select
    self.LeftTabScroll.verticalNormalizedPosition = 1
    self.TabBtnGroup:SelectIndex(selectIdx or 1);
end

function XUiFubenExperiment:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(XUiFubenExperimentBanner)
    self.DynamicTable:SetDelegate(self)
    self.FubenTriallBanner.gameObject:SetActiveEx(false)
end

function XUiFubenExperiment:SetupDynamicTable(id, IsTimeIn)
    if IsTimeIn then
        self.PageDatas = XDataCenter.FubenExperimentManager.GetTrialLevelByGroupID(id)
    else
        self.PageDatas = {}
    end

    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiFubenExperiment:CheckTime(id)
    local endTime = XDataCenter.FubenExperimentManager.GetEndTime(id)
    if not endTime then
        return false
    end
    if endTime > 0 then
        if (endTime == nil) or (endTime - XTime.GetServerNowTimestamp() <= 0) then
            return false
        end
    end
    local startTime = XDataCenter.FubenExperimentManager.GetStartTime(id)
    if not startTime then
        return false
    end
    if startTime > 0 then
        if (startTime == nil) or (startTime - XTime.GetServerNowTimestamp() > 0) then
            return false
        end
    end
    return true
end

function XUiFubenExperiment:SetTime(timestamp)
    if not timestamp then return end
    local leftTime = timestamp - XTime.GetServerNowTimestamp()
    XCountDown.CreateTimer(self.GameObject.name, leftTime)
    XCountDown.BindTimer(self.GameObject, self.GameObject.name, function(v)
        self.TxtTime.text = CS.XTextManager.GetText("DrawResetTimeShort", XUiHelper.GetTime(v, XUiHelper.TimeFormatType.DRAW))
    end)
end

function XUiFubenExperiment:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(index, function(idx, curType)
            self:OnBannerClick(idx, curType)
        end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateBanner(self.PageDatas[index])
    end
end

function XUiFubenExperiment:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnActDesc, self.OnBtnActDescClick)
end

function XUiFubenExperiment:OnBtnActDescClick()
    XUiManager.UiFubenDialogTip("", self.TrialGroup[self.CurSelectIndex].Description or "")
end

function XUiFubenExperiment:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenExperiment:OnBtnBackClick()
    self:Close()
end

function XUiFubenExperiment:OnBannerClick(index, curType)
    if curType == XDataCenter.FubenExperimentManager.TrialLevelType.SkinTrial then
        XLuaUiManager.Open("UiFubenExperimentSkinTrialDetail", self.PageDatas[index], curType)
    else
        XLuaUiManager.Open("UiFubenExperimentDetail", self.PageDatas[index], curType)
    end

end

function XUiFubenExperiment:OnSelectedTog(index)
    local endTime = XDataCenter.FubenExperimentManager.GetEndTime(self.TrialGroup[index].Id)
    local isTimeIn = false
    self.CurSelectIndex = index

    for i = 1, #self.BtnTabGoList do
        local tmp = self:CheckTime(i)
        if not tmp then self.BtnTabGoList[i].gameObject:SetActiveEx(tmp) end
        if i == index then isTimeIn = tmp end
    end

    self.PanelTime.gameObject:SetActiveEx(isTimeIn)
    if endTime and endTime > 0 then
        self:SetTime(endTime)
    else
        self.PanelTime.gameObject:SetActiveEx(false)
    end

    if self.TrialGroup[index].TimeId and self.TrialGroup[index].TimeId > 0 and not XDataCenter.FubenExperimentManager.CheckGroupHasInTimeTask(self.TrialGroup[index].Id) then
        self:UpdateLeftTabGroup()
        XUiManager.TipText("ActivityBranchNotOpen")
        return
    end

    self:SetupDynamicTable(self.TrialGroup[index].Id, isTimeIn)
    self.TxtModeExplain.text = self.TrialGroup[index].ModeExplainText
end

function XUiFubenExperiment:UpdateCurBannerState()
    self:OnSelectedTog(self.CurSelectIndex)
end

function XUiFubenExperiment:UpdateToggleRedPoint()
    local firstNeedShowRedIndexDic = {}
    for index, xBtn in ipairs(self.BtnTabGoList) do -- 先遍历二级toggle
        local isShowRed = false
        if xBtn.SubGroupIndex and xBtn.SubGroupIndex > 0 then
            if XDataCenter.FubenExperimentManager.CheckExperimentGroupHaveRedPoint(self.TrialGroup[index].Id) then
                isShowRed = true
                firstNeedShowRedIndexDic[xBtn.SubGroupIndex] = true
            else
                isShowRed = false
            end
        end
        xBtn:ShowReddot(isShowRed)
    end

    for index, xBtn in ipairs(self.BtnTabGoList) do -- 一级toggle红点
        if not xBtn.SubGroupIndex or xBtn.SubGroupIndex == 0 then
            if firstNeedShowRedIndexDic[index] then
                xBtn:ShowReddot(true)
            else
                xBtn:ShowReddot(XDataCenter.FubenExperimentManager.CheckExperimentGroupHaveRedPoint(self.TrialGroup[index].Id)) --只有一级toggle带关卡也需要检查红点
            end
        end
    end
end

function XUiFubenExperiment:UpdateLeftTabGroup()
    --返回到试玩区时，如果有时间到的活动隐藏
    for i = 1, #self.TrialGroup do
        if self.TrialGroup[i].TimeId and self.TrialGroup[i].TimeId > 0 and not XDataCenter.FubenExperimentManager.CheckGroupHasInTimeTask(self.TrialGroup[i].Id) then
            self.BtnTabGoList[i].gameObject:SetActiveEx(false)
            if self.CurSelectIndex == i then
                self.TabBtnGroup:SelectIndex(self.CurSelectIndex + 1);
            end
        end
    end
end