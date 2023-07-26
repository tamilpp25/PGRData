local XUiRecyclePreview = XClass(nil, "XUiRecyclePreview")
local MAX_GRADE = 5
function XUiRecyclePreview:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.SelectFurnitureIds = {}
    self.Rewards = {}
    XTool.InitUiObject(self)

    self:AutoAddListener()
    self:InitDynamicTable()

    self.GridCommonPopUp.gameObject:SetActive(false)
end

function XUiRecyclePreview:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiRecyclePreview:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiRecyclePreview:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiRecyclePreview:AutoAddListener()
    self:RegisterClickEvent(self.BtnRecycleConfirm, self.OnBtnRecycleConfirmClick)
    self:RegisterClickEvent(self.BtnRecycleCancel, self.OnBtnRecycleCancelClick)
    self:RegisterClickEvent(self.BtnSub, self.OnBtnSubClick)
    self:RegisterClickEvent(self.BtnAdd, self.OnBtnAddClick)
    self:RegisterClickEvent(self.BtnMax, self.OnBtnMaxClick)
    local index = 1
    while index <= MAX_GRADE do
        local toggle = self["TogGrade" .. index]
        if toggle then
            toggle.isOn = false
            local clickFunc = self["OnClickTogGrade" .. index]
            toggle.onValueChanged:AddListener(function(isSelect)
                    if self.pageRecord ~= XDormConfig.DORM_BAG_PANEL_INDEX.FURNITURE then return end
                    if clickFunc then clickFunc(self, isSelect) end
                end)
        end
        index = index + 1
    end
end

function XUiRecyclePreview:OnClickTogGrade1(isSelect)
    self:OnClickTogGrade(1, isSelect)
end

function XUiRecyclePreview:OnClickTogGrade2(isSelect)
    self:OnClickTogGrade(2, isSelect)
end

function XUiRecyclePreview:OnClickTogGrade3(isSelect)
    self:OnClickTogGrade(3, isSelect)
end

function XUiRecyclePreview:OnClickTogGrade4(isSelect)
    self:OnClickTogGrade(4, isSelect)
end

function XUiRecyclePreview:OnClickTogGrade5(isSelect)
    self:OnClickTogGrade(5, isSelect)
end

function XUiRecyclePreview:OnClickTogGrade(index, isSelect)
    self.RootUi:SelectRecycleLevel(index, isSelect)
end
--@region 事件处理

-- 确认回收
function XUiRecyclePreview:OnBtnRecycleConfirmClick()
    if not self.SelectFurnitureIds or #self.SelectFurnitureIds <= 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("DormFurnitureRecycelNull"), XUiManager.UiTipType.Tip)
        return
    end

    local hintText = self:GetHintText()
    local title = XUiHelper.GetText("DormRecycleConfirmTitle")
    XUiManager.DialogTip(title or "", hintText, XUiManager.DialogType.Normal, nil, function()

            self.RootUi:OnRecycleConfirm(self.SelectCount, function()
                    self:Hide()
                end)
        end)
end

function XUiRecyclePreview:GetHintText()
    local hintText
    if self.pageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT then
        hintText = CS.XTextManager.GetText("DormDraftRecycelComfirm")
    else
        if self.RootUi:CheckIsSelectItemGreaterThenA() then
            hintText = CS.XTextManager.GetText("DormDraftRecycelGreaterAComfirm")
        else
            hintText = CS.XTextManager.GetText("DormDraftRecycelComfirm")
        end
        for i = 1, #self.SelectFurnitureIds do
            local isUseing = XDataCenter.FurnitureManager.CheckFurnitureUsing(self.SelectFurnitureIds[i])
            if isUseing then
                hintText = CS.XTextManager.GetText("DormFurnitureRecycelUsingComfirm")
                break
            end
        end
    end

    return hintText
end

-- 取消回收
function XUiRecyclePreview:OnBtnRecycleCancelClick()
    self.RootUi:PlayAnimation("RecyclePreviewDisable",function ()
            self:Hide()
            self.RootUi:OnRecycleCancel()
        end)
end

function XUiRecyclePreview:OnBtnSubClick()
    if self.SelectFurnitureIds then
        self:Refresh(self.SelectFurnitureIds, self.SelectCount - 1)
    end
end

function XUiRecyclePreview:OnBtnAddClick()
    if self.SelectFurnitureIds then
        self:Refresh(self.SelectFurnitureIds, self.SelectCount + 1)
    end
end

function XUiRecyclePreview:OnBtnMaxClick()
    if self.SelectFurnitureIds then
        self:Refresh(self.SelectFurnitureIds, self:GetMaxCount())
    end
end

--@endregion

function XUiRecyclePreview:Refresh(selectFurnitureIds, count)
    self.SelectFurnitureIds = selectFurnitureIds

    self:RefreshTxtNum(count)

    self.Rewards = self:GetRewards()

    self:UpdateDynamicTable()
end

function XUiRecyclePreview:RefreshTxtNum(count)
    if count then
        self.SelectCount = count
    else
        if self.SelectFurnitureIds and next(self.SelectFurnitureIds) then
            self.SelectCount = 1
        else
            self.SelectCount = 0
        end
    end
    self.TxtNum.text = self.SelectCount

    self.BtnSub.gameObject:SetActive(self.SelectCount > 0)
    self.ImgCantSub.gameObject:SetActive(not (self.SelectCount > 0))

    self.BtnAdd.gameObject:SetActive(self.SelectCount < self:GetMaxCount())
    self.ImgCantAdd.gameObject:SetActive(not (self.SelectCount < self:GetMaxCount()))
end

function XUiRecyclePreview:GetMaxCount()
    if self.SelectFurnitureIds and next(self.SelectFurnitureIds) then
        if self.pageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT then
            return XDataCenter.ItemManager.GetCount(self.SelectFurnitureIds[1])
        end
    end

    return 0
end

function XUiRecyclePreview:GetRewards()
    if self.pageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT then
        local rewards = {}
        if next(self.SelectFurnitureIds) then
            rewards = {
                XDataCenter.ItemManager.GetSellReward(self.SelectFurnitureIds[1], self.SelectCount)
            }
        end
        return rewards
    else
        return XDataCenter.FurnitureManager.GetRecycleRewards(self.SelectFurnitureIds)
    end
end

function XUiRecyclePreview:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTablePopUp)
    self.DynamicTable:SetProxy(XUiGridCommon)
    self.DynamicTable:SetDelegate(self)
end

function XUiRecyclePreview:UpdateDynamicTable(bReload)
    self.TxtSelectNum.text = #self.SelectFurnitureIds

    self.DynamicTable:SetDataSource(self.Rewards)
    self.DynamicTable:ReloadDataASync(bReload and 1 or -1)
end

function XUiRecyclePreview:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.Rewards[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        XLuaUiManager.Open("UiTip", self.Rewards[index])
    end
end

function XUiRecyclePreview:Hide()
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
    self.GameObject:SetActive(false)
    self:ResetToggle()
end

function XUiRecyclePreview:ResetToggle()
    local index = 1
    while index <= MAX_GRADE do
        local toggle = self["TogGrade" .. index]
        if toggle then
            toggle.isOn = false
        end
        index = index + 1
    end
end

function XUiRecyclePreview:Show(pageRecord)
    self.SelectFurnitureIds = {}
    self.Rewards = {}
    self.pageRecord = pageRecord

    self.PanelNumBtn.gameObject:SetActiveEx(self.pageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT)
    self.PanelSelectNum.gameObject:SetActiveEx(self.pageRecord ~= XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT)
    self.PanelFilterGrade.gameObject:SetActiveEx(self.pageRecord == XDormConfig.DORM_BAG_PANEL_INDEX.FURNITURE)

    self:RefreshTxtNum(0)
    self:UpdateDynamicTable()

    self.GameObject:SetActive(true)
    XDataCenter.UiPcManager.OnUiEnable(self, "OnBtnRecycleCancelClick")
end

function XUiRecyclePreview:IsShow()
    return self.GameObject.activeSelf
end

return XUiRecyclePreview