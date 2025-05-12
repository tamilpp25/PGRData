---@class XUiPokerGuessing2PopupSettlement : XLuaUi
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2PopupSettlement = XLuaUiManager.Register(XLuaUi, "UiPokerGuessing2PopupSettlement")

function XUiPokerGuessing2PopupSettlement:OnAwake()
    self._Rewards = {}
    self:BindExitBtns()
    XUiHelper.RegisterClickEvent(self, self.BtnLeave1, self.OnClickLeave, nil , true)
    XUiHelper.RegisterClickEvent(self, self.BtnAgain1, self.OnClickRestart, nil , true)
    XUiHelper.RegisterClickEvent(self, self.BtnLeave2, self.OnClickLeave, nil , true)
    XUiHelper.RegisterClickEvent(self, self.BtnLeave3, self.OnClickLeave, nil , true)
    XUiHelper.RegisterClickEvent(self, self.BtnAgain2, self.OnClickRestart, nil , true)
    self.PanelWin.gameObject:SetActiveEx(false)
    self.PanelLost.gameObject:SetActiveEx(false)
    if self.PanelDraw then
        self.PanelDraw.gameObject:SetActiveEx(false)
    end
end

function XUiPokerGuessing2PopupSettlement:OnStart()

end

function XUiPokerGuessing2PopupSettlement:OnEnable()
    self:Update()
end

function XUiPokerGuessing2PopupSettlement:OnDisable()

end

function XUiPokerGuessing2PopupSettlement:Update()
    local settlement = self._Control:GetSettlement()
    if settlement.IsWin then
        self.PanelWin.gameObject:SetActiveEx(true)
        self.SFX_SettleWin.gameObject:SetActiveEx(true)
    else
        self.PanelLost.gameObject:SetActiveEx(true)
        self.SFX_SettleLose.gameObject:SetActiveEx(true)
    end
    self.TxtRoundNum.text = settlement.Round
    if #settlement.Rewards > 0 then
        self.PanelReward.gameObject:SetActiveEx(true)
        XTool.UpdateDynamicGridCommon(self._Rewards, settlement.Rewards, self.Grid256New, self)
    else
        self.PanelReward.gameObject:SetActiveEx(false)
    end
end

function XUiPokerGuessing2PopupSettlement:OnClickLeave()
    self:Close()
    XLuaUiManager.Close("UiPokerGuessing2Game")
end

function XUiPokerGuessing2PopupSettlement:OnClickRestart()
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_RESTART)
end

return XUiPokerGuessing2PopupSettlement