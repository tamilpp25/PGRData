local XUiPanelWorldChatMyMsgEmoji = XClass(XUiNode, "XUiPanelWorldChatMyMsgEmoji")
local XUiPanelNameplate = require("XUi/XUiNameplate/XUiPanelNameplate")

function XUiPanelWorldChatMyMsgEmoji:OnStart()
    self:InitAutoScript()

    local prefab = self.PanelMsg:Find("PanelName"):LoadPrefab(XMedalConfigs.XNameplatePanelPath)
    self.UiPanelNameplate = XUiPanelNameplate.New(prefab, self)
    -- self.UiPanelNameplate = XUiPanelNameplate.New(self.PanelNameplate, self)
    if self.PanelBg then
        self._PanelChatBoard = require('XUi/XUiChatServe/XUiChatBoard').New(self.PanelBg, self)
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelWorldChatMyMsgEmoji:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelWorldChatMyMsgEmoji:GetAutoKey(uiNode, eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelWorldChatMyMsgEmoji:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelWorldChatMyMsgEmoji:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelWorldChatMyMsgEmoji:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnView, self.OnBtnViewClick)
end
-- auto
function XUiPanelWorldChatMyMsgEmoji:OnBtnViewClick()
    if XDataCenter.RoomManager.RoomData and self.playerId == XPlayer.Id then
        --在房间中不能在聊天打开自己详情面板
        return
    end
    if XMVCA.XDlcRoom:IsInRoom() and self.playerId == XPlayer.Id then
        --在房间中不能在聊天打开自己详情面板
        return
    end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.playerId)
end

function XUiPanelWorldChatMyMsgEmoji:RefreshBabelTowerLevel(chatData)
    local babelTowerIcon = XDataCenter.MedalManager.GetScoreTitleIconById(chatData.BabelTowerTitleId)
    local babelTowerLevel = chatData.BabelTowerLevel

    if babelTowerIcon then
        self.ImgBabelTowerLv:SetRawImage(babelTowerIcon)
        self.TxtBabelTowerLv.text = babelTowerLevel
        self.ImgBabelTowerLv.gameObject:SetActiveEx(true)
    else
        self.ImgBabelTowerLv.gameObject:SetActiveEx(false)
    end

end

function XUiPanelWorldChatMyMsgEmoji:RefreshGuildRankLevel(chatData)
    local rankLevel = chatData.GuildRankLevel
    local isJoin = XDataCenter.GuildManager.IsJoinGuild()
    
    if isJoin and chatData.ChannelType == ChatChannelType.Guild and rankLevel > 0 then
        self.TxtGuildPosition.text = XDataCenter.GuildManager.GetRankNameByLevel(rankLevel)
        self.RImgGuildPosition.gameObject:SetActiveEx(true)
        -- self.RImgGuildPosition:SetRawImage(XGuildConfig.GUildRankIcon[rankLevel])
    else
        self.RImgGuildPosition.gameObject:SetActiveEx(false)
    end
    local guildName = chatData.GuildName
    if chatData.ChannelType ~= ChatChannelType.Guild and guildName and guildName ~= "" then
        self.TxtNameGuild.gameObject:SetActiveEx(true)
        self.TxtNameGuild.text = string.format("[%s]", guildName)
    else
        self.TxtNameGuild.gameObject:SetActiveEx(false)
    end
end

function XUiPanelWorldChatMyMsgEmoji:Refresh(chatData)
    self.playerId = chatData.SenderId
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(chatData.SenderId, chatData.NickName)
    XUiPlayerHead.InitPortrait(chatData.Icon, chatData.HeadFrameId, self.Head)

    self:RefreshBabelTowerLevel(chatData)
    self:RefreshGuildRankLevel(chatData)

    local icon = XDataCenter.ChatManager.GetEmojiIcon(chatData.Content)
    local medalConfig = XMedalConfigs.GetMeadalConfigById(chatData.CurrMedalId)
    local medalIcon = nil

    if medalConfig then
        medalIcon = medalConfig.MedalIcon
    end

    if icon ~= nil then
        self.RImgEmoji:SetRawImage(icon)
    end
    if medalIcon ~= nil then
        self.ImgMedalIcon:SetRawImage(medalIcon)
        self.ImgMedalIcon.gameObject:SetActiveEx(true)
    else
        self.ImgMedalIcon.gameObject:SetActiveEx(false)
    end

    if XTool.IsNumberValid(chatData.NameplateId) then
        self.UiPanelNameplate:UpdateDataById(chatData.NameplateId)
        self.UiPanelNameplate.GameObject:SetActiveEx(true)
    else
        self.UiPanelNameplate.GameObject:SetActiveEx(false)
    end
    
    if self._PanelChatBoard then
        -- 设置聊天框
        self._PanelChatBoard:Refresh(chatData.ChatBoardId, chatData.SenderId == XPlayer.Id)
        --表情Ui翻转
        self.RImgEmoji.transform.localScale = self._PanelChatBoard._IsMirror and Vector3(-1, 1, 1) or Vector3(1, 1, 1)
    end
end

return XUiPanelWorldChatMyMsgEmoji