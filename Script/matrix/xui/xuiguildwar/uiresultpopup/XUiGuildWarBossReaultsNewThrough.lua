--- Boss击破新周目开启弹窗
local XUiGuildWarBossReaultsNewThrough = XLuaUiManager.Register(XLuaUi, "UiGuildWarBossReaultsNewThrough")

function XUiGuildWarBossReaultsNewThrough:OnAwake()
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.BattleManager = self.GuildWarManager.GetBattleManager()
    self.CloseCallBack = nil
    self:RegisterUiEvents()
end

function XUiGuildWarBossReaultsNewThrough:OnStart(closeCallBack)
    self.CloseCallBack = closeCallBack
end

function XUiGuildWarBossReaultsNewThrough:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiGuildWarBossReaultsNewThrough:Close()
    XUiGuildWarBossReaultsNewThrough.Super.Close(self)
    XMVCA.XGuildWar.DragonRageCom:SetIsNewGameThroughActionWaitToPlay(nil)
    if self.CloseCallBack then
        self.CloseCallBack()
    end
end

return XUiGuildWarBossReaultsNewThrough