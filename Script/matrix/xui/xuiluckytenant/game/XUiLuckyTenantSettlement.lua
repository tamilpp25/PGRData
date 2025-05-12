---@class XUiLuckyTenantSettlement : XLuaUi
---@field _Control XLuckyTenantControl
local XUiLuckyTenantSettlement = XLuaUiManager.Register(XLuaUi, "UiLuckyTenantSettlement")

function XUiLuckyTenantSettlement:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnAgain, self.OnClickRestart, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnQuit, self.OnClickQuit, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnClickQuit, nil, true)
end

function XUiLuckyTenantSettlement:OnEnable()
    self:Update()
end

function XUiLuckyTenantSettlement:Update()
    self._Control:UpdateSettlement()
    local settlementData = self._Control:GetUiData().Settlement
    self.TxtScore.text = settlementData.Score
    self.TagNew.gameObject:SetActiveEx(settlementData.IsNewRecord)
    self.TxtRound.text = settlementData.Round
    self.TxtTask.text = settlementData.QuestCompletedAmount .. "/" .. settlementData.QuestTotalAmount

    if self.TxtDoc then
        self.TxtDoc.text = XUiHelper.GetText("LuckyTenantSettlementDesc")
    end
    if settlementData.IsPerfectClear then
        self.TxtTitle.text = XUiHelper.GetText("LuckyTenantPerfectClear")
        self.TxtDoc.text = XUiHelper.GetText("LuckyTenantPerfectClearDesc")
        self.FxPerfect.gameObject:SetActiveEx(true)

    elseif settlementData.IsNormalClear then
        self.TxtTitle.text = XUiHelper.GetText("LuckyTenantNormalClear")
        self.TxtDoc.text = XUiHelper.GetText("LuckyTenantNormalClearDesc")
        self.FxComplete.gameObject:SetActiveEx(true)

    elseif settlementData.IsFail then
        self.TxtTitle.text = XUiHelper.GetText("LuckyTenantFail")
        self.TxtDoc.text = XUiHelper.GetText("LuckyTenantFailDesc")
        if self.Fail then
            self.Fail.gameObject:SetActiveEx(true)
        end
    end
end

function XUiLuckyTenantSettlement:OnClickRestart()
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT_RESTART)
    self:Close()
end

function XUiLuckyTenantSettlement:OnClickQuit()
    self:Close()
    XLuaUiManager.Close("UiLuckyTenantGame")
end

return XUiLuckyTenantSettlement