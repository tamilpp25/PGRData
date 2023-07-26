local XUiGridRecord = require("XUi/XUiStronghold/XUiStrongholdJournal/XUiGridRecord")

local CsXTextManagerGetText = CsXTextManagerGetText

local CONDITION_COLOR_FOR_TEXT = {
    [true] = XUiHelper.Hexcolor2Color("ff3f3f"),
    [false] = XUiHelper.Hexcolor2Color("000000"),
}

local XUiStrongholdJournal = XLuaUiManager.Register(XLuaUi, "UiStrongholdJournal")

function XUiStrongholdJournal:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.GridRecord.gameObject:SetActiveEx(false)
end

function XUiStrongholdJournal:OnEnable()
    self:UpdatePauseDays()
    self:UpdateView()
end

function XUiStrongholdJournal:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_MINERAL_RECORD_CHANGE,
        XEventId.EVENT_STRONGHOLD_PAUSE_DAY_CHANGE,
    }
end

function XUiStrongholdJournal:OnNotify(evt, ...)
    if evt == XEventId.EVENT_STRONGHOLD_MINERAL_RECORD_CHANGE then
        self:UpdateView()
    elseif evt == XEventId.EVENT_STRONGHOLD_PAUSE_DAY_CHANGE then
        self:UpdatePauseDays()
    end
end

function XUiStrongholdJournal:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SView)
    self.DynamicTable:SetProxy(XUiGridRecord)
    self.DynamicTable:SetDelegate(self)
end

function XUiStrongholdJournal:UpdatePauseDays()
    local isPaused = XDataCenter.StrongholdManager.IsDayPaused()
    if isPaused then
        local countTime = XDataCenter.StrongholdManager.GetDelayCountTimeStr()
        self.TxtTips.text = CsXTextManagerGetText("StrongholdJournalTipsDelay", countTime)
    else
        local countTime = XDataCenter.StrongholdManager.GetCountTimeStr()
        self.TxtTips.text = CsXTextManagerGetText("StrongholdJournalTips", countTime)
    end
    self.TxtTips.color = CONDITION_COLOR_FOR_TEXT[isPaused]
end

function XUiStrongholdJournal:UpdateView()
    self.Records = XDataCenter.StrongholdManager.GetMineRecordsForShow()
    self.DynamicTable:SetDataSource(self.Records)
    self.DynamicTable:ReloadDataASync()
end

function XUiStrongholdJournal:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local record = self.Records[index]
        grid:Refresh(record)
    end
end

function XUiStrongholdJournal:AutoAddListener()
    self.BtnClose.CallBack = function() self:Close() end
end