--公会战难度选择界面
local XUiGuildWarSelect = XClass(nil, "XUiGuildWarSelect")

function XUiGuildWarSelect:Ctor(uiPrefab, page, rootUi)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitPanelTitle()
    self:InitDifficultDTable()
    self.BtnRank.CallBack = function() self:OnClickBtnRanking() end
end

function XUiGuildWarSelect:InitPanelTitle()
    local Script = require("XUi/XUiGuildWar/DifficultSelect/XUiGWSelectPanelTitle")
    self.TitlePanel = Script.New(self.PanelTitle)
end

function XUiGuildWarSelect:InitDifficultDTable()
    local Script = require("XUi/XUiGuildWar/DifficultSelect/XUiGWSelectDifficultDTable")
    self.DTable = Script.New(self.PanelLevelList)
end

function XUiGuildWarSelect:OnRepeatOpen()
    self.BtnRank:ShowReddot(not XDataCenter.GuildWarManager.CheckReadCurrentRanking())
end

function XUiGuildWarSelect:ShowPanel()
    self.GameObject:SetActiveEx(true)
    self.TitlePanel:StartTimeCount()
    self.BtnRank:ShowReddot(not XDataCenter.GuildWarManager.CheckReadCurrentRanking())
end

function XUiGuildWarSelect:HidePanel()
    self.GameObject:SetActiveEx(false)
    self.TitlePanel:EndTimeCount()
end

function XUiGuildWarSelect:OnDestroy()
    self.TitlePanel:EndTimeCount()
end

function XUiGuildWarSelect:OnClickBtnRanking()
    if not XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        XUiManager.TipText("GuildWarNoInRound")
        return
    end
    XLuaUiManager.Open("UiGuildWarRank")
end

return XUiGuildWarSelect