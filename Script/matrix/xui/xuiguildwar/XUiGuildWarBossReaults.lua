local XUiGuildWarBossReaults = XLuaUiManager.Register(XLuaUi, "UiGuildWarBossReaults")

function XUiGuildWarBossReaults:OnAwake()
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.BattleManager = self.GuildWarManager.GetBattleManager()
    self.CloseCallBack = nil
    self:RegisterUiEvents()
end

function XUiGuildWarBossReaults:OnStart(closeCallBack)
    self.CloseCallBack = closeCallBack
    --self.TxtDesc.text = XUiHelper.GetText("GuildWarBossSettleTip", self.GuildWarManager.GetDifficultyName(
    --    self.BattleManager:GetDifficultyId()))
    self.TxtDesc.text = XUiHelper.GetText("GuildWarBossSettleTip")
end

function XUiGuildWarBossReaults:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiGuildWarBossReaults:Close()
    if self.CloseCallBack then
        self.CloseCallBack()
    end
    XUiGuildWarBossReaults.Super.Close(self)
end

return XUiGuildWarBossReaults