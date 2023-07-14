--工会boss击败boss弹窗
local UiGuildBossTip = XLuaUiManager.Register(XLuaUi, "UiGuildBossTip")

function UiGuildBossTip:OnAwake()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.BtnGo.CallBack = function()
        self:Close()
        XDataCenter.GuildBossManager.OpenGuildBossHall()
    end
end

function UiGuildBossTip:OnEnable()
    self:RefreshView()
end

function UiGuildBossTip:OnDestroy()
    XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
end

function UiGuildBossTip:OnStart()
    self.TxtTitle.text = CS.XTextManager.GetText("GuildBossTipTitle")
    self.TxtDesc.text = CS.XTextManager.GetText("GuildBossTipDesc") 
end

function UiGuildBossTip:RefreshView()
    self.TxtBossLv.text = "Lv." .. XDataCenter.GuildBossManager.GetKilledBossLv()
end