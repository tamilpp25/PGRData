local XUiGuildWarInformation = XLuaUiManager.Register(XLuaUi, "UiGuildWarInformation")
local XUiGridLog = require("XUi/XUiGuildWar/Map/XUiGridLog")
local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiGuildWarInformation:OnStart()
    self.BattleManager = XDataCenter.GuildWarManager.GetBattleManager()
    self:SetButtonCallBack()
    self.GridLogList = {}
    self.GridLog.gameObject:SetActiveEx(false)
    self:UpdatePanel()
end

function XUiGuildWarInformation:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnClose()
    end
end

function XUiGuildWarInformation:UpdatePanel()
    local count = XGuildWarConfig.GetClientConfigValues("LogCount", "Int")[1]
    local refreshTime = XGuildWarConfig.GetClientConfigValues("HourRefreshTime", "Int")[1]
    local logList = self.BattleManager:GetBattleLogs(count)
    
    for index,log in pairs(logList or {}) do
        local grid = self.GridLogList[index]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridLog, self.Content)
            grid = XUiGridLog.New(obj, self)
            self.GridLogList[index] = grid
        end
        
        grid:UpdateGrid(log)
        grid.GameObject:SetActiveEx(true)
    end
    
    self.TxtTimeRefresh.text = CSXTextManagerGetText("GuildWarLogRefreshTimeText", refreshTime)
    self.TxtLogCount.text = CSXTextManagerGetText("GuildWarLogCount", count)
end

function XUiGuildWarInformation:OnBtnClose()
    self:Close()
end

