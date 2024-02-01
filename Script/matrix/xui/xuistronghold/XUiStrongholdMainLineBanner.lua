local XUiGridStrongholdBanner = require("XUi/XUiStronghold/XUiGridStrongholdBanner")

local BtnTabIndex = {
    QZZZ = 1, --驱逐作战
    WHZZ = 2, --维护作战
}

local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdMainLineBanner = XLuaUiManager.Register(XLuaUi, "UiStrongholdMainLineBanner")

function XUiStrongholdMainLineBanner:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    local itemId = XDataCenter.StrongholdManager.GetMineralItemId()
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
        self.AssetActivityPanel:Refresh({ itemId })
    end, self.AssetActivityPanel)

    
    self.BtnQzzz:SetButtonState(CS.UiButtonState.Normal)
    self.BtnWhzz:SetButtonState(CS.UiButtonState.Normal)

    self.PanelTabBtns:Init({
        self.BtnQzzz,
        self.BtnWhzz,
    }, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)

    self.GridChapterDz.gameObject:SetActiveEx(false)

    self.BgQZZZ = self:FindTransform("BgCommonBai")
    self.BgWHZZ = self:FindTransform("Bg2")

    self.BgQZZZ.gameObject:SetActiveEx(false)
    self.BgWHZZ.gameObject:SetActiveEx(false)
end

function XUiStrongholdMainLineBanner:OnStart(selectHard)
    if selectHard then
        self.DefaultSelectIndex = BtnTabIndex.WHZZ
    else
        self.DefaultSelectIndex = BtnTabIndex.QZZZ
    end
end

function XUiStrongholdMainLineBanner:OnEnable()
    if self.IsEnd then return end

    if XDataCenter.StrongholdManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self.AssetActivityPanel:Refresh({ XDataCenter.StrongholdManager.GetMineralItemId() })
    self:UpdateEndurance()
    self:UpdateChapterBtns()

    XDataCenter.StrongholdManager.CheckHardChapterFirstOpen()
end

function XUiStrongholdMainLineBanner:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE,
        XEventId.EVENT_STRONGHOLD_ENDURANCE_CHANGE,
        XEventId.EVENT_STRONGHOLD_ACTIVITY_END,
    }
end

function XUiStrongholdMainLineBanner:OnNotify(evt, ...)
    if self.IsEnd then return end

    if evt == XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE then
        self:UpdateChapters()
    elseif evt == XEventId.EVENT_STRONGHOLD_ENDURANCE_CHANGE then
        self:UpdateEndurance()
    elseif evt == XEventId.EVENT_STRONGHOLD_ACTIVITY_END then
        if XDataCenter.StrongholdManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiStrongholdMainLineBanner:OnReleaseInst()
    return self.SelectIndex
end

function XUiStrongholdMainLineBanner:OnResume(tabIndex)
    self.SelectIndex = tabIndex
end

function XUiStrongholdMainLineBanner:OnClickTabCallBack(tabIndex)
    self.SelectIndex = tabIndex
    self:UpdateChapters()
    self:PlayAnimationWithMask("QieHuan")
end

function XUiStrongholdMainLineBanner:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChapterDz)
    self.DynamicTable:SetProxy(XUiGridStrongholdBanner)
    self.DynamicTable:SetDelegate(self)
end

function XUiStrongholdMainLineBanner:UpdateEndurance()
    local curEndurance = XDataCenter.StrongholdManager.GetCurEndurance()
    self.TxtEndurance.text = curEndurance
end

function XUiStrongholdMainLineBanner:UpdateChapterBtns()
    local showHard = XDataCenter.StrongholdManager.IsChapterHardCanShow()
    self.BtnWhzz.gameObject:SetActiveEx(showHard)

    local showHardRed = XDataCenter.StrongholdManager.CheckHardChapterCanFight()
    self.BtnQzzz:ShowReddot(false)
    self.BtnWhzz:ShowReddot(showHardRed)

    self.PanelTabBtns:SelectIndex(self.SelectIndex or self.DefaultSelectIndex)
end

function XUiStrongholdMainLineBanner:UpdateChapters()
    if self.SelectIndex == BtnTabIndex.QZZZ then
        self.TxtTitle.text = CsXTextManagerGetText("StrongholdActivityNameFightNormal")
        self.ChapterIds = XStrongholdConfigs.GetAllChapterIds(XStrongholdConfigs.ChapterType.Normal)

        self.BgQZZZ.gameObject:SetActiveEx(true)
        self.BgWHZZ.gameObject:SetActiveEx(false)
    elseif self.SelectIndex == BtnTabIndex.WHZZ then
        self.TxtTitle.text = CsXTextManagerGetText("StrongholdActivityNameFightHard")
        self.ChapterIds = XStrongholdConfigs.GetAllChapterIds(XStrongholdConfigs.ChapterType.Hard)

        self.BgQZZZ.gameObject:SetActiveEx(false)
        self.BgWHZZ.gameObject:SetActiveEx(true)

        XDataCenter.StrongholdManager.SetCookieChapterHard()
    end

    self.DynamicTable:SetDataSource(self.ChapterIds)
    self.DynamicTable:ReloadDataASync()
end

function XUiStrongholdMainLineBanner:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local chapterId = self.ChapterIds[index]
        grid:Refresh(chapterId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local chapterId = self.ChapterIds[index]

        local isUnlock, conditionDes = XDataCenter.StrongholdManager.CheckChapterUnlock(chapterId)
        if not isUnlock then
            XUiManager.TipMsg(conditionDes)
            return
        end

        local openFunc= function()
            XLuaUiManager.Open("UiStrongholdFightMain", chapterId)
        end
        if XStrongholdConfigs.IsChapterLendCharacterBanned(chapterId) then
            local title = CSXTextManagerGetText("StrongholdEnterChapterConfirmTitle")
            local content = CSXTextManagerGetText("StrongholdEnterChapterConfirmContent")
            XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, openFunc)
        else
            openFunc()
        end
    end
end

function XUiStrongholdMainLineBanner:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self:BindHelpBtn(self.BtnHelp, "StrongholdFight")
end

function XUiStrongholdMainLineBanner:OnClickBtnBack()
    self:Close()
end

function XUiStrongholdMainLineBanner:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end