local XUiLoadingOption = XLuaUiManager.Register(XLuaUi, "UiLoadingOption")
local XUiLoadingSelection = require("XUi/UiLoading/ChildView/XUiLoadingSelection")
local XUiGridCG = require("XUi/UiLoading/ChildItem/XUiGridCG")

function XUiLoadingOption:OnStart()
    self.SelectionDic = {}
    self.SelectCount = 0
    self.LoadingList = XDataCenter.LoadingManager.GetCustomLoadingList()

    for i, v in ipairs(self.LoadingList) do
        self.SelectCount = self.SelectCount + 1
        self.SelectionDic[v] = i
    end

    self.StepCount = #self.LoadingList + 1
    self.MaxSize = XLoadingConfig.GetCustomMaxSize()
    self:InitUi()
end

function XUiLoadingOption:OnEnable()

end

function XUiLoadingOption:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridCG)
    self.DynamicTable:SetDelegate(self)
    self.GridCGItem.gameObject:SetActiveEx(false)

    self:InitTypeButton()

    self.SelectionView = XUiLoadingSelection.New(self, self.PanelSelectedList)
    self.SelectionView:Refresh(self.SelectionDic)
    self:ShowSelectInfo()

    self.BtnBack.CallBack = handler(self, self.OnBtnBackClick)
    self.BtnMainUi.CallBack = handler(self, self.OnBtnMainUiClick)
    self.BtnConfirm.CallBack = handler(self, self.OnBtnConfirmClick)
end

function XUiLoadingOption:SetupDynamicTable(type)
    self.EntityList = XMVCA.XArchive:GetArchiveCGDetailList(type)
    self.DynamicTable:SetDataSource(self.EntityList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiLoadingOption:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateCg(self.EntityList[index])
        local id = self.EntityList[index].Id
        grid:SetSelect(self.SelectionDic[id])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if not grid:CheckSelectable() then return end
        self:OnGridClick(self.EntityList[index].Id, grid)
    end
end

function XUiLoadingOption:OnGridClick(id, grid)
    local updateState = function()
        self.ChangedFlag = true
        if grid then
            grid:SetSelect(self.SelectionDic[id])
        else
            self.DynamicTable:ReloadDataSync()
        end
        self:ShowSelectInfo()
        self.SelectionView:Refresh(self.SelectionDic)
    end

    if self.SelectionDic[id] then
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("CustomLoadingRemoveTip"),
                XUiManager.DialogType.Normal, nil, function()
                    self.SelectionDic[id] = nil
                    self.SelectCount = self.SelectCount - 1
                    updateState()
                end)
    elseif self.SelectCount >= self.MaxSize then
        XUiManager.TipText("CustomLoadingMaxTip")
    else
        self.SelectionDic[id] = self.StepCount
        self.SelectCount = self.SelectCount + 1
        self.StepCount = self.StepCount + 1
        updateState()
    end
end

function XUiLoadingOption:InitTypeButton()
    self.GroupList = XMVCA.XArchive:GetArchiveCGGroupList(true)
    self.CurType = 1
    self.CGGroupBtn = {}
    for _, v in pairs(self.GroupList) do
        local btn = CS.UnityEngine.Object.Instantiate(self.BtnTabShortNew)
        btn.gameObject:SetActive(true)
        btn.transform:SetParent(self.TabBtnContent.transform, false)
        local btncs = btn:GetComponent("XUiButton")
        local name = v.Name
        btncs:SetName(name or "")

        table.insert(self.CGGroupBtn, btncs)
    end
    self.TabBtnContent:Init(self.CGGroupBtn, function(index) self:SelectType(index) end)
    self.BtnTabShortNew.gameObject:SetActiveEx(false)
    self.TabBtnContent:SelectIndex(self.CurType)
end

function XUiLoadingOption:SelectType(index)
    self.CurType = index
    self:SetupDynamicTable(self.GroupList[index].Id)
    self:PlayAnimation("QieHuan")
end

function XUiLoadingOption:OnBtnBackClick()
    if self.ChangedFlag then
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("SettingCheckSave"),
                XUiManager.DialogType.Normal, handler(self, self.Close), handler(self, self.OnBtnConfirmClick))
    else
        self:Close()
    end
end

function XUiLoadingOption:OnBtnMainUiClick()
    if self.ChangedFlag then
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("SettingCheckSave"),
                XUiManager.DialogType.Normal, XLuaUiManager.RunMain, handler(self, self.OnBtnConfirmClick))
    else
        XLuaUiManager.RunMain()
    end
end

function XUiLoadingOption:OnBtnConfirmClick()
    if self.ChangedFlag then
        local list = {}
        for i in pairs(self.SelectionDic) do
            table.insert(list, i)
        end

        table.sort(list, function(a, b)
            return self.SelectionDic[a] < self.SelectionDic[b]
        end)

        XDataCenter.LoadingManager.SaveCustomLoading(list)
        self.ChangedFlag = false
    end

    -- 打开自定义加载开关
    XDataCenter.LoadingManager.SetCustomLoadingState(XSetConfigs.LoadingType.Custom)
    XUiManager.TipText("SetAppearanceSuccess")
end

function XUiLoadingOption:ShowSelectInfo()
    self.SelectNum.text = string.format("%d/%d", self.SelectCount, self.MaxSize)
end