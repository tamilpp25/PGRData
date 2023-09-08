local XUiPanelAd = require("XUi/XUiMain/XUiChildView/XUiPanelAd")
local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")
local XUiMainLeftBottom = XClass(XUiMainPanelBase, "XUiMainLeftBottom")
local CSXTextManagerGetText = CS.XTextManager.GetText
local MAX_CHAT_WIDTH = 395

local MailMaxCount = CS.XGame.Config:GetInt("MailCountLimit")
local MailWillFullCount = CS.XGame.ClientConfig:GetInt("MailWillFullCount") --邮箱将满

--主界面会频繁打开，采用常量缓存
local RedPointConditionGroup = {
    --指导
    Mentor = {
        XRedPointConditions.Types.CONDITION_MENTOR_APPLY_RED,
        XRedPointConditions.Types.CONDITION_MENTOR_REWARD_RED,
        XRedPointConditions.Types.CONDITION_MENTOR_TASK_RED,
    },
    --福利
    Welfare = {
        XRedPointConditions.Types.CONDITION_PURCHASE_GET_RERARGE,
        XRedPointConditions.Types.CONDITION_PURCHASE_GET_CARD,
        XRedPointConditions.Types.CONDITION_WEEK_CHALLENGE,
        XRedPointConditions.Types.CONDITION_ACTIVITY_NEW_ACTIVITIES,
        XRedPointConditions.Types.CONDITION_ACTIVITY_SCLASS_GOT,
    },
    --首次充值
    FirstRecharge = {
        XRedPointConditions.Types.CONDITION_PURCHASE_GET_RERARGE
    },
    --公告
    Notice = {
        XRedPointConditions.Types.CONDITION_MAIN_NOTICE
    },
    --邮件
    Mail = {
        XRedPointConditions.Types.CONDITION_MAIN_MAIL
    },
}

-- local CHAT_SUB_LENGTH = 18
function XUiMainLeftBottom:OnStart(rootUi)
    -- self.Transform = rootUi.PanelLeftBottom.gameObject.transform
    -- XTool.InitUiObject(self)
    --ClickEvent
    self.BtnNotice.CallBack = function() self:OnBtnNotice() end
    self.BtnMentor.CallBack = function() self:OnBtnMentor() end
    self.BtnWelfare.CallBack = function() self:OnBtnWelfare() end
    self.BtnChat.CallBack = function() self:OnBtnChat() end
    self.BtnMail.CallBack = function() self:OnBtnMail() end
    --RedPoint
    
    self:AddRedPointEvent(self.BtnMentor.ReddotObj, self.OnCheckMentorNews, self, RedPointConditionGroup.Mentor)
    self.RedPoinWelfareId = self:AddRedPointEvent(self.BtnWelfare.ReddotObj, self.OnCheckWalfarelNews, self, RedPointConditionGroup.Welfare)
    self.RedPoinFirstRechargeId = self:AddRedPointEvent(self.BtnWelfare.TagObj, self.OnCheckFirstRecharge, self, RedPointConditionGroup.FirstRecharge)
    self:AddRedPointEvent(self.BtnNotice.ReddotObj, self.OnCheckNoticeNews, self, RedPointConditionGroup.Notice)
    self:AddRedPointEvent(self.BtnMail, self.OnCheckMailNews, self, RedPointConditionGroup.Mail)
    self:InitChatMsg()

    --Filter
    self:CheckFilterFunctions()
end

function XUiMainLeftBottom:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_WORLD_MSG, self.RefreshChatMsg, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_RECEIVE_CHAT, self.RefreshChatMsg, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG, self.RefreshChatMsg, self)
    XEventManager.AddEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.OnRefreshWalfareId, self)
    XEventManager.AddEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.OnRefreshFirstRechargeId, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_EMOJI_REFRESH_RED, self.RefreshEmojiRed, self)
    self:UpdatePanelAd()
    self:OnRefreshWalfareId()
    self:OnRefreshFirstRechargeId()
    self:OnCheckMailWillFull()
    self:RefreshEmojiRed()

    --self.BtnWelfare:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Welfare))

    -- 每次进入主界面，满足条件后可以获取邀请码信息，用来刷新活动公告按钮的红点状态
    XDataCenter.RegressionManager.HandleGetInvitationCodeInfoRequest()
    self:RefreshChatMsg(XDataCenter.ChatManager.GetLatestChatData())

    XDataCenter.MentorSystemManager.ShowMentorShipComplete()--进入主界面时检测有无新师徒关系建立
end

function XUiMainLeftBottom:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_WORLD_MSG, self.RefreshChatMsg, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_RECEIVE_CHAT, self.RefreshChatMsg, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG, self.RefreshChatMsg, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.OnRefreshWalfareId, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.OnRefreshFirstRechargeId, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_EMOJI_REFRESH_RED, self.RefreshEmojiRed, self)
end

function XUiMainLeftBottom:OnDestroy()
    if self.PanelAdObj then
        self.PanelAdObj:OnDestroy()
    end
end

function XUiMainLeftBottom:OnNotify(evt)
    if evt == XEventId.EVENT_NOTICE_PIC_CHANGE then
        self:UpdatePanelAd()
    elseif evt == XAgencyEventId.EVENT_MAIL_COUNT_CHANGE then
        self:OnCheckMailWillFull()
    end
end

function XUiMainLeftBottom:CheckFilterFunctions()
    self.PanelAd.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.BtnNotice.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.BtnMentor.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.MentorSystem) and not XUiManager.IsHideFunc)
    self.BtnWelfare.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.BtnChat.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.SocialChat) and not XUiManager.IsHideFunc)
    self.BtnMail.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Mail))
end

--公告入口
function XUiMainLeftBottom:OnBtnNotice()
    --XLuaUiManager.OpenWithCallback("UiActivityBase", function()
    --    if XLuaUiManager.IsUiLoad("UiDialog") or XLuaUiManager.IsUiLoad("UiBuyAsset") or XLuaUiManager.IsUiLoad("UiSystemDialog") or XLuaUiManager.IsUiLoad("UiUsePackage") then
    --        XLuaUiManager.Close("UiActivityBase")
    --    end
    --end)
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnNotice)
    local noticeType = XDataCenter.NoticeManager.GameNoticeType.Game
    if XDataCenter.NoticeManager.CheckInGameNoticeRedPoint(XDataCenter.NoticeManager.GameNoticeType.Activity) then
        noticeType = XDataCenter.NoticeManager.GameNoticeType.Activity
    end
    XDataCenter.NoticeManager.OpenGameNotice(noticeType)
end

--福利入口
function XUiMainLeftBottom:OnBtnWelfare()
    --if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Welfare) then
    --    return
    --end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnWelfare)
    --XLuaUiManager.Open("UiSign")
    XLuaUiManager.Open("UiWelfare")
end

--师徒入口
function XUiMainLeftBottom:OnBtnMentor()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MentorSystem) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnMentor)
    XLuaUiManager.Open("UiMentorMain")
end

--聊天入口
function XUiMainLeftBottom:OnBtnChat()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialChat) then
        self.BtnWelfare:ShowTag(false)
        local dict = {}
        dict["ui_first_button"] = XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnChat
        dict["role_level"] = XPlayer.GetLevel()
        CS.XRecord.Record(dict, "200004", "UiOpen")
        XUiHelper.OpenUiChatServeMain(true, ChatChannelType.World)
    end
end

--邮件入口
function XUiMainLeftBottom:OnBtnMail()
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnMail)
    XLuaUiManager.Open("UiMail")
end

-- 设置福利按钮特效可见性
function XUiMainLeftBottom:SetBtnWelfareTagActive(active)
    self.BtnWelfare:ShowTag(active)
end

--更新聊天
function XUiMainLeftBottom:RefreshChatMsg(chatDataLua)
    if not chatDataLua then return end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SocialChat) then
        return
    end

    if chatDataLua.ChannelType == ChatChannelType.World then
        self.TxtMessageType.text = CSXTextManagerGetText("ChatWorldMsg")
    elseif chatDataLua.ChannelType == ChatChannelType.Private then
        self.TxtMessageType.text = CSXTextManagerGetText("ChatPrivateMsg")
    elseif chatDataLua.ChannelType == ChatChannelType.System then
        self.TxtMessageType.text = CSXTextManagerGetText("ChatSystemMsg")
    elseif chatDataLua.ChannelType == ChatChannelType.Guild then
        self.TxtMessageType.text = CSXTextManagerGetText("ChatGuildMsg")
    elseif chatDataLua.ChannelType == ChatChannelType.Mentor then
        self.TxtMessageType.text = CSXTextManagerGetText("ChatMentorMsg")
    end

    local name = XDataCenter.SocialManager.GetPlayerRemark(chatDataLua.SenderId, chatDataLua.NickName)
    if chatDataLua.MsgType == ChatMsgType.Emoji then
        self.TxtMessageContent.text = string.format("%s:%s", name, CSXTextManagerGetText("EmojiText"))
    elseif chatDataLua.MsgType == ChatMsgType.System and chatDataLua.ChannelType == ChatChannelType.Guild then
        local content = string.format("%s：%s", CSXTextManagerGetText("GuildChannelTypeAll"), chatDataLua.Content)
        self.TxtMessageContent.text = content
    else
        self.TxtMessageContent.text = string.format("%s:%s", name, chatDataLua.Content)
    end
    self.TxtMessageLabel.gameObject:SetActiveEx(XUiHelper.CalcTextWidth(self.TxtMessageContent) > MAX_CHAT_WIDTH)
end

function XUiMainLeftBottom:InitChatMsg()
    self.TxtMessageType.text = ""
    self.TxtMessageContent.text = ""
end

-- 更新新获得的表情包红点
function XUiMainLeftBottom:RefreshEmojiRed()
    local isRed = XDataCenter.ChatManager.CheckIsNewEmoji()
    self.BtnChat:ShowReddot(isRed)
end

--更新福利红点
function XUiMainLeftBottom:OnRefreshWalfareId()
    if self.RedPoinWelfareId then
        XRedPointManager.Check(self.RedPoinWelfareId)
    end
end

--更新首充特效
function XUiMainLeftBottom:OnRefreshFirstRechargeId()
    if XLoginManager.IsFirstOpenMainUi() then
        return
    end

    if self.RedPoinFirstRechargeId then
        XRedPointManager.Check(self.RedPoinFirstRechargeId)
    end
end

--更新滚动广告
function XUiMainLeftBottom:UpdatePanelAd()
    if XUiManager.IsHideFunc then return end
    if self.PanelAdObj then
        self.PanelAdObj:UpdateAdList()
    else
        self.PanelAdObj = XUiPanelAd.New(self, self.PanelAd)
    end
end

--师徒红点
function XUiMainLeftBottom:OnCheckMentorNews(count)
    self.BtnMentor:ShowReddot(count >= 0 and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.MentorSystem))
end

--福利红点
function XUiMainLeftBottom:OnCheckWalfarelNews(count)
    self.BtnWelfare:ShowReddot(count >= 0)
end

--首充特效
function XUiMainLeftBottom:OnCheckFirstRecharge(count)
    self.BtnWelfare:ShowTag(count >= 0)
end

--公告红点
function XUiMainLeftBottom:OnCheckNoticeNews(count)
    self.BtnNotice:ShowReddot(count >= 0)
end

--邮件红点
function XUiMainLeftBottom:OnCheckMailNews(count)
    self.BtnMail:ShowReddot(count >= 0)
end

--邮件将满
function XUiMainLeftBottom:OnCheckMailWillFull()
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    local count = mailAgency:GetMailListCount()
    self.BtnMail:ShowTag(count >= MailWillFullCount)
    if count >= MailMaxCount then
        self.TxtMailWillFull.text = CSXTextManagerGetText("MailIsFull")
    else
        self.TxtMailWillFull.text = CSXTextManagerGetText("MailWillFull")
    end
end

return XUiMainLeftBottom