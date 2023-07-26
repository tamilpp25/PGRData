local XUiMentorAnnouncement = XLuaUiManager.Register(XLuaUi, "UiMentorAnnouncement")
local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiMentorAnnouncement:OnStart(oldMessage)
    self:SetButtonCallBack()
    local maxLength = XMentorSystemConfigs.GetMentorSystemData("MessageBoardMaxLen")
    self.TxtNum.text = CSXTextManagerGetText("GuildInfoTextRange", maxLength)
    self.InFContent.text = oldMessage or ""
    self.OldMessage = oldMessage
end

function XUiMentorAnnouncement:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
    self.BtnSignCancel.CallBack = function()
        self:Close()
    end
    self.BtnSignSure.CallBack = function()
        self:OnBtnMessageSure()
    end
end

function XUiMentorAnnouncement:OnBtnMessageSure()
    local messageText = string.gsub(self.InFContent.text, "^%s*(.-)%s*$", "%1")
    local maxLength = XMentorSystemConfigs.GetMentorSystemData("MessageBoardMaxLen")
    if string.len(messageText) > 0 then
        local utf8Count = self.InFContent.textComponent.cachedTextGenerator.characterCount - 1
        if utf8Count > maxLength then
            XUiManager.TipError(CSXTextManagerGetText("MentorMessageLengthTips", maxLength))
            return
        end
        if messageText == self.OldMessage then
            XUiManager.TipText("MentorTeacherSameMessageHint")
            return
        end
        XDataCenter.MentorSystemManager.MentorPublishMessageBoardRequest(messageText, function ()
                XUiManager.TipText("MentorMessageSendCompleteHint")
                self:Close()
        end)
    else
        XUiManager.TipText("MentorMessageIsEmpty")
    end
end