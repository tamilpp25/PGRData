local XUiPanelBottom = XClass(nil, "XUiPanelBottom")
local CSTextManagerGetText = CS.XTextManager.GetText
local MAX_CHAT_WIDTH = 470
local CHAT_SUB_LENGTH = 30
local Normal = CS.UiButtonState.Normal
local Select = CS.UiButtonState.Select
function XUiPanelBottom:Ctor(ui, base, battleManager)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.BattleManager = battleManager
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.IsMenuOn = false
end

function XUiPanelBottom:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_RECEIVE_CHAT, self.UpdateChart, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.CheckRedDot, self)
end

function XUiPanelBottom:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_RECEIVE_CHAT, self.UpdateChart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.CheckRedDot, self)
end

function XUiPanelBottom:SetButtonCallBack()
    self.BtnTask.CallBack = function()
        self:OnBtnTaskClick()
    end
    self.BtnRole.CallBack = function()
        self:OnBtnRoleClick()
    end
    self.BtnReport.CallBack = function()
        self:OnBtnReportClick()
    end
    self.BtnMap.CallBack = function()
        self:OnBtnMapClick()
    end
    self.BtnMenu.CallBack = function()
        self:OnBtnMenuClick()
    end
    self.BtnChat.CallBack = function()
        self:OnBtnChatClick()
    end
    self.BtnMe.CallBack = function()
        self:OnBtnMeClick()
    end
    self.BtnInformation.CallBack = function()
        self:OnBtnInformationClick()
    end
end

function XUiPanelBottom:UpdatePanel()
    self:UpdateChart()
    self:UpdateMenu()
    local GuildLeader = XDataCenter.GuildManager.IsGuildLeader()
    self.BtnMap.gameObject:SetActiveEx(GuildLeader)
end

function XUiPanelBottom:UpdateMenu()
    self.BtnMenu:SetButtonState(self.IsMenuOn and Normal or Select)

    if self.IsMenuOn then
        self.PanelBtn.gameObject:SetActiveEx(true)
        self.Base:PlayAnimationWithMask("ButtonEnable")
    else
        self.Base:PlayAnimationWithMask("ButtonDisable", function ()
                self.PanelBtn.gameObject:SetActiveEx(false)
            end)
    end
    self:CheckRedDot()
end

--更新聊天
function XUiPanelBottom:UpdateChart()
    local chatList = XDataCenter.ChatManager.GetGuildChatList()
    if not chatList then return end
    local lastChat = chatList[1]
    if not lastChat then
        self.TxtMessage.text = ""
        return
    end

    local nameRemark = XDataCenter.SocialManager.GetPlayerRemark(lastChat.SenderId, lastChat.NickName)
    local content = lastChat.Content
    if lastChat.MsgType == ChatMsgType.System then
        content = string.format("%s：%s", CS.XTextManager.GetText("GuildChannelTypeAll"), lastChat.Content)
        self.TxtMessage.text = content
    else
        content = lastChat.Content
        if lastChat.MsgType == ChatMsgType.Emoji then
            content = CS.XTextManager.GetText("GuildEmojiReplace")
        end
        self.TxtMessage.text = string.format("%s：%s", nameRemark, content)
    end

    if XUiHelper.CalcTextWidth(self.TxtMessage) > MAX_CHAT_WIDTH then
        self.TxtMessage.text = string.Utf8Sub(self.TxtMessage.text, 1, CHAT_SUB_LENGTH) .. [[...]]
    end
end

function XUiPanelBottom:OnBtnTaskClick()
    XLuaUiManager.Open("UiGuildWarTask")
end

function XUiPanelBottom:OnBtnRoleClick()
    XLuaUiManager.Open("UiGuildWarUpCharacter")
end

function XUiPanelBottom:OnBtnReportClick()
    XLuaUiManager.Open("UiGuildWarRank")
end

function XUiPanelBottom:OnBtnMapClick()
    if not XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        XUiManager.TipText("GuildWarNoInRound")
        return
    end
    self.Base:PathEdit()
end

function XUiPanelBottom:OnBtnMenuClick()
    self.IsMenuOn = not self.IsMenuOn
    self:UpdateMenu()
end

function XUiPanelBottom:OnBtnChatClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialChat) then
        return
    end
    
    XUiHelper.OpenUiChatServeMain(false, ChatChannelType.Guild, ChatChannelType.World)
end

function XUiPanelBottom:OnBtnMeClick()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_LOOKAT_ME)
end

function XUiPanelBottom:OnBtnInformationClick()
    XLuaUiManager.Open("UiGuildWarInformation")
end

function XUiPanelBottom:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelBottom:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelBottom:CheckRedDot()
    local IsHasAchievedTask = XDataCenter.GuildWarManager.CheckTaskAchieved()
    self.BtnMenu:ShowReddot(not self.IsMenuOn and IsHasAchievedTask)
    self.BtnTask:ShowReddot(self.IsMenuOn and IsHasAchievedTask)
end



return XUiPanelBottom