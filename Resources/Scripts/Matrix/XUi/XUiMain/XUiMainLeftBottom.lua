local XUiPanelAd = require("XUi/XUiMain/XUiChildView/XUiPanelAd")
XUiMainLeftBottom = XClass(nil, "XUiMainLeftBottom")
local CSXTextManagerGetText = CS.XTextManager.GetText
local MAX_CHAT_WIDTH = 395
-- local CHAT_SUB_LENGTH = 18

function XUiMainLeftBottom:Ctor(rootUi)
    self.Transform = rootUi.PanelLeftBottom.gameObject.transform
    XTool.InitUiObject(self)
    --ClickEvent
    self.BtnNotice.CallBack = function() self:OnBtnNotice() end
    self.BtnSocial.CallBack = function() self:OnBtnSocial() end
    self.BtnMentor.CallBack = function() self:OnBtnMentor() end
    self.BtnWelfare.CallBack = function() self:OnBtnWelfare() end
    self.BtnChat.CallBack = function() self:OnBtnChat() end
    self.BtnWelfare:ShowTag(false) -- 海外修改
    --RedPoint
    XRedPointManager.AddRedPointEvent(self.BtnSocial.ReddotObj, self.OnCheckSocialNews, self, { XRedPointConditions.Types.CONDITION_MAIN_FRIEND })
    XRedPointManager.AddRedPointEvent(self.BtnMentor.ReddotObj, self.OnCheckMentorNews, self, { XRedPointConditions.Types.CONDITION_MENTOR_APPLY_RED, XRedPointConditions.Types.CONDITION_MENTOR_REWARD_RED, XRedPointConditions.Types.CONDITION_MENTOR_TASK_RED})
    self.RedPoinWelfareId = XRedPointManager.AddRedPointEvent(self.BtnWelfare.ReddotObj, self.OnCheckWalfarelNews, self, { XRedPointConditions.Types.CONDITION_PURCHASE_GET_RERARGE, XRedPointConditions.Types.CONDITION_PURCHASE_GET_CARD, XRedPointConditions.Types.CONDITION_NEWYEARDIVINING_NOTGET, XRedPointConditions.Types.CONDITION_FIREWORKS_AVAILABLE})
    self.RedPoinFirstRechargeId = XRedPointManager.AddRedPointEvent(self.BtnWelfare.TagObj, self.OnCheckFirstRecharge, self, { XRedPointConditions.Types.CONDITION_PURCHASE_GET_RERARGE })
    self.BtnNoticeRedId = XRedPointManager.AddRedPointEvent(self.BtnNotice.ReddotObj, self.OnCheckNoticeNews, self, { XRedPointConditions.Types.CONDITION_MAIN_NOTICE })
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
    self:UpdatePanelAd()
    self:OnRefreshNoticeId()
    self:OnRefreshWalfareId()
    self:OnRefreshFirstRechargeId()

    self.BtnWelfare:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Welfare))

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
end

function XUiMainLeftBottom:OnDestroy()
    if self.PanelAdObj then
        self.PanelAdObj:OnDestroy()
    end
end

function XUiMainLeftBottom:OnNotify(evt)
    if evt == XEventId.EVENT_NOTICE_PIC_CHANGE then
        self:UpdatePanelAd()
    end
end

function XUiMainLeftBottom:CheckFilterFunctions()
    self.PanelAd.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.BtnNotice.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.BtnSocial.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.SocialFriend))
    self.BtnMentor.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.MentorSystem))
    self.BtnWelfare.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Welfare))
    self.BtnChat.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.SocialChat))
end

--公告入口
function XUiMainLeftBottom:OnBtnNotice()
    XLuaUiManager.OpenWithCallback("UiActivityBase", function ()
        if XLuaUiManager.IsUiLoad("UiDialog") or XLuaUiManager.IsUiLoad("UiBuyAsset") or XLuaUiManager.IsUiLoad("UiSystemDialog") or XLuaUiManager.IsUiLoad("UiUsePackage") then
            XLuaUiManager.Close("UiActivityBase")
        end
    end)
end

--好友入口
function XUiMainLeftBottom:OnBtnSocial()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialFriend) then
        return
    end
    XLuaUiManager.Open("UiSocial")
end

--福利入口
function XUiMainLeftBottom:OnBtnWelfare()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Welfare) then
        return
    end
    self:OnRefreshWalfareId()
    CS.XHeroBdcAgent.BdcWelfareClick()--新增打点记录
    XLuaUiManager.Open("UiSign")
end

--师徒入口
function XUiMainLeftBottom:OnBtnMentor()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MentorSystem) then
        return
    end
    XLuaUiManager.Open("UiMentorMain")
end

--聊天入口
function XUiMainLeftBottom:OnBtnChat()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialChat) then
        self.BtnWelfare:ShowTag(false)
        XLuaUiManager.Open("UiChatServeMain", true, ChatChannelType.World)
    end
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

--更新福利红点
function XUiMainLeftBottom:OnRefreshWalfareId()
    if self.RedPoinWelfareId then
        XRedPointManager.Check(self.RedPoinWelfareId)
    end
end

function XUiMainLeftBottom:OnRefreshNoticeId()
    if self.BtnNoticeRedId then
        XRedPointManager.Check(self.BtnNoticeRedId)
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

--好友红点
function XUiMainLeftBottom:OnCheckSocialNews(count)
    self.BtnSocial:ShowReddot(count >= 0 and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SocialFriend))
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
function XUiMainLeftBottom:OnCheckFirstRecharge(count) -- 海外修改
    local showTag = count >= 0
    if showTag then
        CS.XScheduleManager.ScheduleOnce(function()
            self.BtnWelfare:ShowTag(showTag)
        end, 1)
    else
        self.BtnWelfare:ShowTag(showTag)
    end
    if XLuaUiManager.IsUiShow("UiChatServeMain") then --防止聊天时点击头像跳转指挥官界面再返回出现特效覆盖在聊天界面上问题
        self.BtnWelfare:ShowTag(false)
    end
end

--公告红点
function XUiMainLeftBottom:OnCheckNoticeNews(count)
    self.BtnNotice:ShowReddot(count >= 0)
end