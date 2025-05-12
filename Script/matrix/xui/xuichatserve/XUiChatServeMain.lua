local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiChatServeMain = XLuaUiManager.Register(XLuaUi, "UiChatServeMain")
local XUiPanelChatContent = require('XUi/XUiChatServe/XUiPanelChatContent')

local ToggleName = {
    CS.XTextManager.GetText("World"),
    CS.XTextManager.GetText("Team"),
    CS.XTextManager.GetText("Guild"),
    CS.XTextManager.GetText("Mentor"),
    -- CS.XTextManager.GetText("System"),
}

local ToggleType = {
    ChatChannelType.World,
    ChatChannelType.Room,
    ChatChannelType.Guild,
    ChatChannelType.Mentor,
    -- ChatChannelType.System,
}

local DefaultType = ChatChannelType.World
local ChannelRefreshTime = CS.XGame.ClientConfig:GetInt("ChannelInfoRefreshMin")
local FadeTime = CS.XGame.ClientConfig:GetInt("ChannelChangeFadeTime")
local XUiGridChatChannelItem = require("XUi/XUiChatServe/Item/XUiGridChatChannelItem")

local ChatRoomChannelNotOpen = CS.XTextManager.GetText("ChatRoomChannelNotOpen")
local IsMessageTipShow = false
function XUiChatServeMain:OnAwake()
    self:InitAutoScript()
    self.BtnRoom.CallBack = function() self:OnBtnRoomClick() end
    self.BtnChannelSure.CallBack = function() self:OnBtnChannelSureClick() end
    self.BtnChannelMask.CallBack = function() self:OnBtnChannelMaskClick() end

    self.DynamicTableChannels = XDynamicTableNormal.New(self.ChannelList.gameObject)
    self.DynamicTableChannels:SetProxy(XUiGridChatChannelItem)
    self.DynamicTableChannels:SetDelegate(self)

    self:SetBtnReportActive(false)

    if self.BtnSettings then
        self.BtnSettings.CallBack = function() XLuaUiManager.Open('UiPlayerPersonalizedSetting', XHeadPortraitConfigs.HeadType.ChatBoard) end
        self.BtnSettings:ShowReddot(XDataCenter.ChatManager.CheckHasNewChatBoard())
    end
end

function XUiChatServeMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local curChannelData = self.ChannelInfos[index]
        if curChannelData then
            grid:SetItemData(curChannelData)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnChannelInfoClick(index)
    end
end

function XUiChatServeMain:OnStart(isMain, ...)
    local args = { ... }
    self.Inited = true
    self.InputField.characterLimit = XDataCenter.ChatManager.GetWorldChatMaxCount()
    self:CreateObject()
    self.timerId = -1

    self.ChannelSet = {}
    for _, v in pairs(args) do
        self.ChannelSet[v] = true
    end

    self.ChannelSet[ChatChannelType.World] = XDataCenter.ChatManager.CheckChatChannelOpenByType(ChatChannelType.World)
    self.ChannelSet[ChatChannelType.Guild] = XDataCenter.ChatManager.CheckChatChannelOpenByType(ChatChannelType.Guild)
    self.ChannelSet[ChatChannelType.Mentor] = XDataCenter.ChatManager.CheckChatChannelOpenByType(ChatChannelType.Mentor)
    if self.ChannelSet[ChatChannelType.Guild] then
        XDataCenter.GuildManager.RequestGuildData()
    end

    local firstUnLockType = DefaultType
    for _, toggleType in ipairs(ToggleType) do
        if self.ChannelSet[toggleType] then
            firstUnLockType = toggleType
            break
        end
    end
    self.SelType = args[1] or firstUnLockType
    
    self.CurrentSelectedChannel = XDataCenter.ChatManager.GetCurrentChatChannelId()

    if isMain then
        self.ImgBgMain:SetActive(true)
        self.ImgBgCommon:SetActive(false)
    else
        self.ImgBgMain:SetActive(false)
        self.ImgBgCommon:SetActive(true)
    end
    self:AddRedPointEvent(self.Content, self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_RECIEVE_CHAT }, nil, false)
end

function XUiChatServeMain:OnEnable()
    self:Refresh()
end

function XUiChatServeMain:OnDisable()
    self:StopChannelTimer()
    self:StopMsgTipsTimer()
    self:RemoveTimer()
    self.UiPanelEmoji:OnDisable()
    self.UiPanelEmojiSetting:OnDisable()
end

function XUiChatServeMain:OnDestroy()
    self:StopChannelTimer()
    self:StopMsgTipsTimer()
    self:RemoveTimer()
    self.UiPanelEmoji:OnDestroy()
    self.UiPanelEmojiSetting:OnDestroy()
    -- 重置特效冷却时间
    XDataCenter.ChatManager.SetEffectEnd(0)
end

function XUiChatServeMain:CreateObject()
    self.UiPanelChatContent = XUiPanelChatContent.New(self.PanelChatContent, self, self)
    local XUiPanelEmojiEx = require("XUi/XUiChatServe/ChatModel/EmojiModel/XUiPanelEmojiEx")
    self.UiPanelEmoji = XUiPanelEmojiEx.New(self, self.PanelEmoji, self)
    local clickCallBack = function(content)
        self.UiPanelEmoji:Hide()
        self:OnClickEmoji(content)
    end
    self.UiPanelEmoji:SetClickCallBack(clickCallBack)
    self.UiPanelEmoji:Hide()
    local XUiPanelEmojiSetting = require("XUi/XUiChatServe/ChatModel/EmojiModel/XUiPanelEmojiPackSetting")
    self.UiPanelEmojiSetting = XUiPanelEmojiSetting.New(self, self.PanelEmojiSetup)
    self.UiPanelEmojiSetting:Hide()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiChatServeMain:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiChatServeMain:AutoInitUi()
    self.PanelChatServe = self.Transform:Find("SafeAreaContentPane/PanelChatServe")
    self.ImgBgleft = self.Transform:Find("SafeAreaContentPane/PanelChatServe/ImgBg/ImgBgleft")
    self.PanelChatContent = self.Transform:Find("SafeAreaContentPane/PanelChatServe/PanelChatContent")
    self.GridChatItem = self.Transform:Find("SafeAreaContentPane/PanelChatServe/PanelLeftToggle/Viewport/Content/GridChatItem")
    self.PanelMsgTips = self.Transform:Find("SafeAreaContentPane/PanelChatServe/PanelMsgTips")
    self.BtnPanelMsgTips = self.Transform:Find("SafeAreaContentPane/PanelChatServe/PanelMsgTips/BtnImgBg"):GetComponent("Button")
    self.TxtMsgCount = self.Transform:Find("SafeAreaContentPane/PanelChatServe/PanelMsgTips/TxtMsgCount"):GetComponent("Text")
    self.BtnSend = self.Transform:Find("SafeAreaContentPane/PanelChatServe/BtnContent/BtnSend"):GetComponent("Button")
    -- self.BtnAdd = self.Transform:Find("SafeAreaContentPane/PanelChatServe/BtnContent/BtnAdd"):GetComponent("Button")
    self.InputField = self.Transform:Find("SafeAreaContentPane/PanelChatServe/BtnContent/InF_Content"):GetComponent("InputField")
    self.TxtEnter = self.Transform:Find("SafeAreaContentPane/PanelChatServe/BtnContent/InF_Content/TxtEnter"):GetComponent("Text")
    self.PanelEmoji = self.Transform:Find("SafeAreaContentPane/PanelChatServe/BtnContent/PanelEmoji")
    self.BtnBack = self.Transform:Find("SafeAreaContentPane/PanelChatServe/BtnContent/BtnBack"):GetComponent("Button")
    self.BtnChat = self.Transform:Find("SafeAreaContentPane/PanelChatServe/BtnChat"):GetComponent("Button")
    self.ImgBgMain = self.Transform:Find("SafeAreaContentPane/PanelChatServe/ImgBg/ImgBgMain").gameObject
    self.ImgBgCommon = self.Transform:Find("SafeAreaContentPane/PanelChatServe/ImgBg/ImgBgCommon").gameObject
end

function XUiChatServeMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnPanelMsgTips, self.OnBtnPanelMsgTipsClick)
    self:RegisterClickEvent(self.BtnSend, self.OnBtnSendClick)
    self:RegisterClickEvent(self.BtnAdd, self.OnBtnAddClick)
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnChat, self.OnBtnChatClick)
    if self.BtnReport then
        self:RegisterClickEvent(self.BtnReport, self.OnBtnReportClick)
    end
end
-- auto
-------------------------------Event beg-------------------------------
function XUiChatServeMain:OnGetEvents()
    return { XEventId.EVENT_CHAT_RECEIVE_WORLD_MSG, XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG,
             XEventId.EVENT_PULL_SCROLLVIEW_END, XEventId.EVENT_CHAT_CHANNEL_CHANGED,
             XEventId.EVENT_CHAT_SERVER_CHANNEL_CHANGED, XEventId.EVENT_GUILD_RECEIVE_CHAT,
             XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG, XEventId.EVENT_CHAT_MATCH_EFFECT, XEventId.EVENT_CHAT_EMOJI_REFRESH_RED, XEventId.EVENT_CHAT_BOARD_REFRESH_RED }
end

function XUiChatServeMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_CHAT_RECEIVE_WORLD_MSG then
        self.UiPanelChatContent:ReceiveChatHandler(...)
    elseif evt == XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG then
        self.UiPanelChatContent:ReceiveChatHandler(...)
    elseif evt == XEventId.EVENT_GUILD_RECEIVE_CHAT then
        self.UiPanelChatContent:ReceiveChatHandler(...)
    elseif evt == XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG then
        self.UiPanelChatContent:ReceiveChatHandler(...)
    elseif evt == XEventId.EVENT_PULL_SCROLLVIEW_END then
        self:ShowUnreadMsgCount(...)
    elseif evt == XEventId.EVENT_CHAT_CHANNEL_CHANGED then
        self:UpdateCurrentChannel()
    elseif evt == XEventId.EVENT_CHAT_SERVER_CHANNEL_CHANGED then
        -- 服务端分配聊天渠道
        if self.SelType == ChatChannelType.World then
            local args = { ... }
            local currentChannelId = args[1]
            self:ShowChangeChatChannel(currentChannelId)
            self:UpdateCurrentChannel()

            self:OnBtnChannelMaskClick()
        end
    elseif evt == XEventId.EVENT_CHAT_MATCH_EFFECT then
        self:ShowKeywordEffect(...)
    elseif evt == XEventId.EVENT_CHAT_EMOJI_REFRESH_RED then
        self:RefreshRedPoint()
    elseif evt == XEventId.EVENT_CHAT_BOARD_REFRESH_RED then
        self.BtnSettings:ShowReddot(XDataCenter.ChatManager.CheckHasNewChatBoard())
    end
end
-------------------------------Event end-------------------------------
--------------------------------Btn Event beg-----------------------------------
function XUiChatServeMain:OnBtnPanelMsgTipsClick()
    self.UiPanelChatContent.UnreadMsgCount = 0
    if IsMessageTipShow then
        self.UiPanelChatContent:RefreshChatList(self.SelType)
    end
end

function XUiChatServeMain:OnBtnAddClick()
    self.UiPanelEmoji:OpenOrClosePanel()
end

function XUiChatServeMain:OnBtnChatClick(eventData)
    self:Close(eventData)
end

function XUiChatServeMain:OnBtnSendClick()
    if self.SelType == ChatChannelType.World and not XDataCenter.ChatManager.CheckCd() then
        return
    end

    if self.SelType == ChatChannelType.Guild and XDataCenter.GuildManager.IsJoinGuild() then
        if XDataCenter.GuildManager.IsGuildTourist() then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildTourstAccess"))
            return
        end
    end

    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if self.SelType == ChatChannelType.Mentor then
        if not mentorData:CheckCanUseChat(true) then
            return
        end
    end
    local content = self.InputField.text
    if string.IsNilOrEmpty(content) then
        self.InputField.text = ''
        -- 内容为空, 则选中它
        self.InputField:ActivateInputField()
        return
    end

    local sendChat = {}
    sendChat.ChannelType = self.SelType
    sendChat.MsgType = ChatMsgType.Normal
    sendChat.Content = content
    sendChat.TargetIds = { XPlayer.Id }
    self.InputField.text = ''

    self:SendChat(sendChat)
end

function XUiChatServeMain:OnClickEmoji(content)
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if self.SelType == ChatChannelType.Mentor then
        if not mentorData:CheckCanUseChat(true) then
            return
        end
    end

    local sendChat = {}
    sendChat.ChannelType = self.SelType
    sendChat.MsgType = ChatMsgType.Emoji
    sendChat.Content = content
    sendChat.TargetIds = { XPlayer.Id }
    XDataCenter.ChatManager.SendChat(sendChat)

    self:RefreshRedPoint()
end

function XUiChatServeMain:SendChat(sendChat)
    if not sendChat then
        return
    end

    --发送聊天信息
    local callBack = function(refreshCoolingTime)
        self:RefreshCoolTime(refreshCoolingTime)
    end
    XDataCenter.ChatManager.SendChat(sendChat, callBack, true)
end

function XUiChatServeMain:Close()
    if self.InputField.isFocused then
        return
    end
    --关闭聊天
    self:PlayAnimationWithMask("AnimChatOut", function()
        self.Super.Close(self)
        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
    end)

    XEventManager.DispatchEvent(XEventId.EVENT_CHAT_CLOSE_NAMEPLATE)
    XEventManager.DispatchEvent(XEventId.EVENT_CHAT_CLOSE)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_CLOSE)
end
--------------------------------Btn Event end-----------------------------------
function XUiChatServeMain:Refresh()
    self:InitializationView()
    self:InitTabBtnGroup()
    self:RefreshMsgPanel()
    self:UpdateCurrentChannel()
    self:RefreshRedPoint()
end

function XUiChatServeMain:RefreshRedPoint()
    local isRed = XDataCenter.ChatManager.CheckIsNewEmoji()
    self.BtnAdd:ShowReddot(isRed)
end

function XUiChatServeMain:InitializationView()
    --初始化界面
    self.PanelMsgTips.gameObject:SetActive(false)

    XLuaUiManager.SetMask(true)
    self:PlayAnimation("AnimChatEnter", function()
        XLuaUiManager.SetMask(false)

        if self.SelType == ChatChannelType.World then
            self:ShowChangeChatChannel(self.CurrentSelectedChannel)
        end
    end)
    XEventManager.DispatchEvent(XEventId.EVENT_CHAT_OPEN)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_OPEN)
end

function XUiChatServeMain:InitTabBtnGroup()
    if self.TabGroup then
        return
    end

    self.TabGroup = {}
    for i = 1, #ToggleType do
        local uiButton
        if i == 1 then
            uiButton = self.BtnTabMatch
        else
            local itemGo = CS.UnityEngine.Object.Instantiate(self.BtnTabMatch.gameObject)
            itemGo.transform:SetParent(self.ContentRT, false)
            uiButton = itemGo.transform:GetComponent("XUiButton")
        end

        local title = ToggleName[i]
        local type = ToggleType[i]
        local unlock = self.ChannelSet[type]
        uiButton:SetName(title)
        uiButton:SetDisable(not unlock)
        -- 如果其他频道需要红点显示，更换判断条件即可
        if (type == ChatChannelType.Guild or type == ChatChannelType.Mentor) then
            local needRedPoint = XDataCenter.ChatManager.CheckRedPointByType(type)
            if type == ChatChannelType.Mentor then
                local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
                needRedPoint = needRedPoint and mentorData:CheckCanUseChat(false)
            end
            uiButton:ShowReddot(needRedPoint)
        end
        table.insert(self.TabGroup, uiButton)
    end

    self.Content:Init(self.TabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    self.Content:SelectIndex(self:TypeToTabIndex(self.SelType))
end

function XUiChatServeMain:TypeToTabIndex(type)
    for i = 1, #ToggleType do
        if ToggleType[i] == type then
            return i
        end
    end
    return 0
end

function XUiChatServeMain:OnClickTabCallBack(tabIndex)
    local type = ToggleType[tabIndex]
    if not type or not self.ChannelSet[type] then
        if type == ChatChannelType.Room then
            XUiManager.TipText("ChatRoomChannelNotOpen")
        else
            local _, tipsKey = XDataCenter.ChatManager.CheckChatChannelOpenByType(type, true)
            if not string.IsNilOrEmpty(tipsKey) then
                XUiManager.TipText(tipsKey)
            end
        end

        return
    end
    -- 如果其他频道需要红点显示，更换判断条件即可
    if (type == ChatChannelType.Guild or type == ChatChannelType.Mentor) then
        XDataCenter.ChatManager.SetChatRead(type)
        local needRedPoint = XDataCenter.ChatManager.CheckRedPointByType(type)
        self.TabGroup[tabIndex]:ShowReddot(needRedPoint)
    end
    self.SelType = type
    self.UiPanelChatContent:RefreshChatList(type)
    self.PanelChannelLabel.gameObject:SetActiveEx(self.SelType == ChatChannelType.World)
    -- 部队频道清除cd
    if self.SelType == ChatChannelType.Room then
        self:SetInputFieldText()
        self:SetInputInteractable(true)
        self:RemoveTimer()
    end
end

function XUiChatServeMain:RefreshMsgPanel()
    self.UiPanelChatContent:RefreshChatList(self.SelType)
end

function XUiChatServeMain:RefreshCoolTime(refreshCoolingTime)
    if refreshCoolingTime <= 0 then
        return
    end

    -- 部队不走冷却时间逻辑
    if self.SelType == ChatChannelType.Room then return end

    self:SetInputInteractable(false)
    self:SetInputFieldText(CS.XTextManager.GetText("CountDownTips", refreshCoolingTime))

    self:RemoveTimer()

    local refresh = function()
        refreshCoolingTime = refreshCoolingTime - 1
        local stop = refreshCoolingTime <= 0 or XTool.UObjIsNil(self.InputField)
        if stop then
            self:SetInputFieldText()
            self:SetInputInteractable(true)
            self:RemoveTimer()
        else
            self:SetInputFieldText(CS.XTextManager.GetText("CountDownTips", refreshCoolingTime))
        end
    end
    self.timerId = XScheduleManager.ScheduleForever(refresh, XScheduleManager.SECOND)
end

function XUiChatServeMain:SetInputInteractable(flag)
    self.InputField.interactable = flag
    self.BtnSend.interactable = flag
    self.BtnAdd.interactable = flag
end

function XUiChatServeMain:SetInputFieldText(text)
    if not XTool.UObjIsNil(self.InputField) then
        self.InputField.text = text or ""
    end
end

function XUiChatServeMain:RemoveTimer()
    if self.timerId ~= -1 then
        XScheduleManager.UnSchedule(self.timerId)
        self.timerId = -1
    end
end

function XUiChatServeMain:ShowUnreadMsgCount(count)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    if count <= 0 then
        -- 如果计时器开着，直接return
        self.UiPanelChatContent.UnreadMsgCount = 0
        if self.showMsgTimer and self.showMsgTimer ~= -1 then return end
        self.PanelMsgTips.gameObject:SetActive(false)
    else
        -- 关计时器如果有
        self:StopMsgTipsTimer()
        self.PanelMsgTips.gameObject:SetActive(true)
        self.TxtMsgCount.text = CS.XTextManager.GetText("ChatWorldNewMsg", count)
        IsMessageTipShow = true
    end
end

function XUiChatServeMain:ShowKeywordEffect(effectInfo)
    local index = XTool.RandomSelectByWeightArray(effectInfo.Weight)
    local path = effectInfo.Path[index]
    self.BgEffect.gameObject:SetActiveEx(false)
    if not string.IsNilOrEmpty(path) then
        self.BgEffect.gameObject:SetActiveEx(true)
        self.BgEffect.gameObject:LoadUiEffect(path)
    end
    -- 播放完特效后调用
    XDataCenter.ChatManager.SetEffectEnd()
end

function XUiChatServeMain:ShowChangeChatChannel(channelId)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    self.PanelMsgTips.gameObject:SetActive(true)

    local currentChannelId = XDataCenter.ChatManager.GetCurrentChatChannelId()
    currentChannelId = currentChannelId >= 5 and (currentChannelId + 1) or currentChannelId

    self.TxtMsgCount.text = CS.XTextManager.GetText("ChannelChanged", currentChannelId ~= XDataCenter.ChatManager.GetRecruitChannelId() and tostring(currentChannelId) or CS.XTextManager.GetText("ChannelRecruitIdStr"))
    -- 开计时器关闭
    self:StartMsgTipsTimer()
end

-- 只刷新tog红点不刷新界面
function XUiChatServeMain:OnCheckRedPoint()
    for index, uiButton in ipairs(self.TabGroup) do
        local type = ToggleType[index]
        -- 如果其他频道需要红点显示，更换判断条件即可
        if self.SelType ~= type and (type == ChatChannelType.Guild or type == ChatChannelType.Mentor) then
            local needRedPoint = XDataCenter.ChatManager.CheckRedPointByType(type)
            uiButton:ShowReddot(needRedPoint)
        end
    end
end

function XUiChatServeMain:StartMsgTipsTimer()
    self:StopMsgTipsTimer()
    self.showMsgTimer = XScheduleManager.ScheduleOnce(function()
        self.PanelMsgTips.gameObject:SetActive(false)
        IsMessageTipShow = false
    end, FadeTime * 1000)
end

function XUiChatServeMain:StopMsgTipsTimer()
    if self.showMsgTimer and self.showMsgTimer ~= -1 then
        XScheduleManager.UnSchedule(self.showMsgTimer)
        self.showMsgTimer = -1
    end
end

function XUiChatServeMain:SetChannelData()
    XDataCenter.ChatManager.GetWorldChannelInfos(function(channelInfos)
        -- 加载频道数据
        self.ChannelInfos = channelInfos
        self:InitChannelInfos(self.ChannelInfos)
        self.DynamicTableChannels:SetDataSource(self.ChannelInfos)
        self.DynamicTableChannels:ReloadDataASync()
        self:UpdateChannelTotalCount()
    end)
end

function XUiChatServeMain:InitChannelInfos(channelInfos)
    local currentChannelId = XDataCenter.ChatManager.GetCurrentChatChannelId()
    for _, info in pairs(channelInfos) do
        info.IsSelected = currentChannelId == info.ChannelId
    end
end

function XUiChatServeMain:OnChannelInfoClick(index)
    if self.ChannelInfos[index] then
        self.CurrentSelectedChannel = self.ChannelInfos[index].ChannelId
    end
    for i = 1, #self.ChannelInfos do
        local grid = self.DynamicTableChannels:GetGridByIndex(i)
        local info = self.ChannelInfos[i]
        info.IsSelected = i == index
        if grid then
            grid:SetChannelSelected(i == index)
        end
    end
end

function XUiChatServeMain:OnBtnRoomClick()
    self.PanelChannel.gameObject:SetActive(true)

    -- 1分钟之内不重复请求
    local now = XTime.GetServerNowTimestamp()
    if now - XDataCenter.ChatManager.GetLastRequestChannelTime() <= 60 then
        self.ChannelInfos = XDataCenter.ChatManager.GetAllChannelInfos()
        self:InitChannelInfos(self.ChannelInfos)
        self.DynamicTableChannels:SetDataSource(self.ChannelInfos)
        self.DynamicTableChannels:ReloadDataASync()
        self:UpdateChannelTotalCount()
    else
        self:SetChannelData()
        XDataCenter.ChatManager.SetLastRequestChannelTime(now)
    end

    self:StartChannelTimer()
end

function XUiChatServeMain:StartChannelTimer()
    self:StopChannelTimer()
    self.channelTimer = XScheduleManager.ScheduleForever(function()
        self:SetChannelData()
    end, ChannelRefreshTime * 60 * 1000)
end

function XUiChatServeMain:StopChannelTimer()
    if self.channelTimer and self.channelTimer ~= -1 then
        XScheduleManager.UnSchedule(self.channelTimer)
        self.channelTimer = -1
    end
end

-- 切换窗口
function XUiChatServeMain:OnBtnChannelMaskClick()
    self:StopChannelTimer()
    self.PanelChannel.gameObject:SetActive(false)

end

function XUiChatServeMain:OnBtnChannelSureClick()
    self:StopChannelTimer()
    self.PanelChannel.gameObject:SetActive(false)

    if self.CurrentSelectedChannel then
        XDataCenter.ChatManager.SelectChatChannel(self.CurrentSelectedChannel, function()
            self:ShowChangeChatChannel(self.CurrentSelectedChannel)
            self:UpdateCurrentChannel()
        end, function()
            -- 发生服务端房间数量变化（例如当前房间不存在了）重新请求
            self:SetChannelData()
        end)
    end
end

function XUiChatServeMain:UpdateCurrentChannel()
    local currentChannelId = XDataCenter.ChatManager.GetCurrentChatChannelId()
    currentChannelId = currentChannelId >= 5 and (currentChannelId + 1) or currentChannelId
    self.TxtRoomNumber.text = XDataCenter.ChatManager.GetRecruitChannelId() ~= currentChannelId and currentChannelId or CS.XTextManager.GetText("ChannelRecruitIdStr")
end

function XUiChatServeMain:UpdateChannelTotalCount()
    self.TextTotalCount.text = #XDataCenter.ChatManager.GetAllChannelInfos()
end

-------------------举报聊天的按钮相关 begin---------------
function XUiChatServeMain:OnBtnReportClick()
    self:SetBtnReportActive(false)
    local playerId = self.MsgItem and self.MsgItem:GetPlayerId()
    if not playerId then
        return
    end

    if XDataCenter.RoomManager.RoomData and playerId == XPlayer.Id then
        --在房间中不能在聊天打开自己详情面板
        return
    end

    local chatContent = self.MsgItem:GetChatContent()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(playerId, nil, nil, nil, function(data)
        local dataTemp = { Id = data.Id, TitleName = data.Name, PlayerLevel = data.Level, PlayerIntroduction = data.Sign }
        XLuaUiManager.Open("UiReport", dataTemp, chatContent, nil, XReportConfigs.EnterType.Chat, nil, self.SelType)
    end)
end

--长按聊天内容回调，XUiPanelChatContent调用
function XUiChatServeMain:LongClickMsgItem(msgItem)
    self.MsgItem = msgItem
    local offsetY = 2
    local content = msgItem:GetContent()
    if XTool.UObjIsNil(content) then
        XLog.Error("检查当前长按的msgItem上是否有Content的引用")
        return
    end

    local contentPosition = content.transform.localPosition
    local height = content.rect.height
    local width = content.rect.width
    local localPositionX = contentPosition.x + width * 0.9
    local localPositionY = contentPosition.y - height - offsetY
    self.BtnReport.transform.position = content.transform:TransformPoint(CS.UnityEngine.Vector3(localPositionX, localPositionY, 0))
    self:SetBtnReportActive(true)
end

function XUiChatServeMain:SetBtnReportActive(isActive)
    if self.BtnReport then
        self.BtnReport.gameObject:SetActiveEx(isActive)
    end
end

function XUiChatServeMain:IsBtnReportActive()
    return self.BtnReport.gameObject.activeSelf
end

function XUiChatServeMain:OpenPanelEmojiSetup()
    self.UiPanelEmojiSetting:Show()
end

function XUiChatServeMain:OpenPanelEmoji()
    self.UiPanelEmoji:Show()
end
-------------------举报聊天的按钮相关 end---------------

return XUiChatServeMain