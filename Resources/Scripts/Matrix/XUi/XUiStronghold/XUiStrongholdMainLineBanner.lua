local XUiGridStrongholdBanner = require("XUi/XUiStronghold/XUiGridStrongholdBanner")

local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdMainLineBanner = XLuaUiManager.Register(XLuaUi, "UiStrongholdMainLineBanner")

function XUiStrongholdMainLineBanner:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    local itemId = XDataCenter.StrongholdManager.GetMineralItemId()
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
        self.AssetActivityPanel:Refresh({ itemId })
    end, self.AssetActivityPanel)

    self.GridChapterDz.gameObject:SetActiveEx(false)
end

function XUiStrongholdMainLineBanner:OnStart()
    self:InitView()
end

function XUiStrongholdMainLineBanner:OnEnable()
    if self.IsEnd then return end

    if XDataCenter.StrongholdManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self.AssetActivityPanel:Refresh({ XDataCenter.StrongholdManager.GetMineralItemId() })
    self:UpdateEndurance()
    self:UpdateChapters()
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

function XUiStrongholdMainLineBanner:InitView()
    self.TxtTitle.text = CsXTextManagerGetText("StrongholdActivityNameFight")
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

function XUiStrongholdMainLineBanner:UpdateChapters()
    self.ChapterIds = XStrongholdConfigs.GetAllChapterIds()
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

        XLuaUiManager.Open("UiStrongholdFightMain", chapterId)
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