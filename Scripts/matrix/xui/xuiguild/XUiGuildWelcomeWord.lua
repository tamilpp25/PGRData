local XUiGuildWelcomeWord = XLuaUiManager.Register(XLuaUi, "UiGuildWelcomeWord")
local XUiGuildWelcomeWordItem = require("XUi/XUiGuild/XUiChildItem/XUiGuildWelcomeWordItem")

function XUiGuildWelcomeWord:OnAwake()
    self:InitFun()
    self.WelcomeWords = {}
    for i = 1, XGuildConfig.GuildDefaultWelcomeWord do
        self.WelcomeWords[i] = XUiGuildWelcomeWordItem.New(self["WelcomeWord"..i],self)
    end
end

function XUiGuildWelcomeWord:InitFun()
    self.BtnCancel.CallBack = function() self:OnBtnCancelClick() end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCancelClick() end
end

function XUiGuildWelcomeWord:OnEnable()
    self:OnRefresh()
end

function XUiGuildWelcomeWord:OnDisable()
end

function XUiGuildWelcomeWord:OnBtnConfirmClick()
    local scripts = {}
    local selects = {}
    for _, item in pairs(self.WelcomeWords) do
        local text = self:trim(item:GetInitPutText())
        table.insert(scripts, text)
        table.insert(selects, item:GetSelect())
    end

    self.DisableFun = self.BtnReportType:GetToggleState()
    for index, data in pairs(scripts) do
        if data == "" and selects[index] == true then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildNoneWelcomeWord"))
            return
        end
        if string.Utf8Len(data) > CS.XGame.Config:GetInt("GuildScriptLength") then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildChangeScriptErrorLength"))
            return
        end
    end
    XDataCenter.GuildManager.GuildChangeScriptRequest(scripts, selects, not self.DisableFun, function ()
        self:Close()
    end)
end

function XUiGuildWelcomeWord:trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function XUiGuildWelcomeWord:OnBtnCancelClick()
    self:Close()
end

-- 更新数据
function XUiGuildWelcomeWord:OnRefresh()
    local datas = XDataCenter.GuildManager.GetGuildScriptDatas() or {}
    for index, v in pairs(datas)do
        local item = self.WelcomeWords[index]
        if item then
            item:OnRefresh(v)
        end
    end

    self.DisableFun = not XDataCenter.GuildManager.GetGuildScriptAutoChat()
    self.BtnReportType:SetButtonState(self.DisableFun and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end