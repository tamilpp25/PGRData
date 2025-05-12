local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XUiNewYearLuckMain = XLuaUiManager.Register(XLuaUi, "UiNewYearLuckMain")
local XUiGridNewYearLuckTicket = require("XUi/XUiNewYearLuck/XUiGridNewYearLuckTicket")

function XUiNewYearLuckMain:OnStart()
    self:RegisterButtonClick()
    self.ActivityEndTime = XDataCenter.NewYearLuckManager.GetActivityEndTime()
    self.DrawTime = XDataCenter.NewYearLuckManager.GetDrawTime()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    self.UseItemId = XDataCenter.NewYearLuckManager.GetUseItemId()
    self.BtnRule:ShowReddot(XDataCenter.NewYearLuckManager.IsFirstInActivity())
    XDataCenter.ItemManager.AddCountUpdateListener(self.UseItemId, function()
        self.AssetActivityPanel:Refresh({ self.UseItemId })
    end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh({ self.UseItemId })
    self:Init()
    self:RefreshTime()
end

function XUiNewYearLuckMain:OnEnable()
    self:StartTimer()
end

function XUiNewYearLuckMain:OnDisable()
    self:StopTimer()
end

function XUiNewYearLuckMain:Refresh()
    for _, ticket in pairs(self.Tickets) do
        ticket:Refresh()
    end
end

function XUiNewYearLuckMain:Init()
    self.Tickets = {}
    local normalCount = XDataCenter.NewYearLuckManager.GetNormalCount()
    local specialCount = XDataCenter.NewYearLuckManager.GetSpecialCount()
    for i = 1, normalCount do
        local ticket = XUiGridNewYearLuckTicket.New(self["NormalLottery" .. i], XNewYearLuckConfigs.TicketType.Normal, i, self)
        table.insert(self.Tickets, ticket)
    end
    for i = 1, specialCount do
        local ticket = XUiGridNewYearLuckTicket.New(self["SpecialLottery" .. i], XNewYearLuckConfigs.TicketType.Special, i, self)
        table.insert(self.Tickets, ticket)
    end
end

function XUiNewYearLuckMain:RegisterButtonClick()
    self.BtnMainUi.CallBack = function()
        self:OnClickBtnMain()
    end
    self.BtnBack.CallBack = function()
        self:OnClickBtnBack()
    end
    self.BtnRule.CallBack = function()
        self.BtnRule:ShowReddot(false)
        self:OnClickBtnRule()
    end
    self:BindHelpBtn(self.BtnHelp, "UiNewYearLuck")
end

function XUiNewYearLuckMain:OnClickBtnMain()
    XLuaUiManager.RunMain()
end

function XUiNewYearLuckMain:OnClickBtnBack()
    self:Close()
end

function XUiNewYearLuckMain:OnClickBtnRule()
    XSaveTool.SaveData(string.format("NewYearLuck%d",XPlayer.Id),1)
    XLuaUiManager.Open("UiNewYearLuckTip")
end

function XUiNewYearLuckMain:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self.Timer = XScheduleManager.ScheduleForever(handler(self, self.RefreshTime), XScheduleManager.SECOND, 0)
end

function XUiNewYearLuckMain:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiNewYearLuckMain:RefreshTime()
    local now = XTime.GetServerNowTimestamp()
    local offset = self.ActivityEndTime - now
    if offset <= 0 then
        self:StopTimer()
        XLuaUiManager.RunMain()
        return
    end
    self.TimeText.text = XUiHelper.GetTime(offset)

    local drawOffset = self.DrawTime - now
    if drawOffset <= 0 then
        self.LotteryTimeText.text = CS.XTextManager.GetText("NewYearLuckDrawTime")
        self:Refresh()
    else
        self.LotteryTimeText.text = XUiHelper.GetTime(drawOffset)
    end
end

return XUiNewYearLuckMain