local XUiGuildInformation = XLuaUiManager.Register(XLuaUi, "UiGuildInformation")
local CsXTextManagerGetText = CS.XTextManager.GetText

function XUiGuildInformation:OnAwake()
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnSignSure.CallBack = function() self:OnBtnSignSureClick() end
    self.BtnSignCancel.CallBack = function() self:OnBtnSignCancelClick() end
end

function XUiGuildInformation:OnStart(type)
    self.InfoType = type
    self:SetText()
end

function XUiGuildInformation:OnGetEvents()
    return {
        XEventId.EVENT_GUILD_FILTER_FINISH,
    }
end

function XUiGuildInformation:OnNotify(evt, ...)
    if evt == XEventId.EVENT_GUILD_FILTER_FINISH  then
        self:OnGuildFilterFinish(...)
    end
end

function XUiGuildInformation:OnGuildFilterFinish(text)
    self.InFContent.text = text
end

function XUiGuildInformation:SetText()
    -- 指挥局公告
    if self.InfoType == XGuildConfig.InformationType.Announcement then
        self.typeText = CsXTextManagerGetText("GuildAnnouncementTitle")
        self.wordMaxCount = XGuildConfig.AnnouncementWordMaxCount
        self.InFContent.placeholder.text =  CsXTextManagerGetText("GuildAnnouncementDes")
        self.oldContent = XDataCenter.GuildManager.GetGuildDeclaration()
    -- 内部通讯
    elseif self.InfoType == XGuildConfig.InformationType.InternalCommunication then
        self.typeText = CsXTextManagerGetText("GuildInterComTitle")
        self.wordMaxCount = XGuildConfig.InterComWordMaxCount
        self.InFContent.placeholder.text =  CsXTextManagerGetText("GuildInterComDes")
        self.oldContent = XDataCenter.GuildManager.GetGuildInterCom()
    end
    self.InFContent.text = self.oldContent
    self.TxtTitle.text = self.typeText
    self.TxtNum.text = CsXTextManagerGetText("GuildInfoTextRange", self.wordMaxCount)
end

function XUiGuildInformation:OnBtnCloseClick()
    self:Close()
end

function XUiGuildInformation:OnBtnSignSureClick()
    -- 权限判断
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildInformationLimited", self.typeText))
        return
    end

    local newContent = self.InFContent.text
    if string.len(newContent) > 0 then
        if newContent == self.oldContent then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildChangeInformationIsSame", self.typeText))
            return
        end
        local utf8Count = self.InFContent.textComponent.cachedTextGenerator.characterCount - 1
        if utf8Count > self.wordMaxCount then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildInformationOverCount", self.wordMaxCount, self.typeText))
            return
        end
        if string.match(newContent,"%s") then
            XUiManager.TipText("GuildDeclarationSpecialTips",XUiManager.UiTipType.Wrong)
            return
        end
        if self.InfoType == XGuildConfig.InformationType.Announcement then
            XDataCenter.GuildManager.GuildChangeDeclaration(newContent, function()
                self:Close()
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_DECLARATION_CHANGED)
            end)
        else
            XDataCenter.GuildManager.GuildChangeNotice(newContent, function()
                self:Close()
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_INTERCOM_CHANGED)
            end)
        end
    else
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildInformationNotEmpty", self.typeText))
    end
end

function XUiGuildInformation:OnBtnSignCancelClick()
    self:Close()
end