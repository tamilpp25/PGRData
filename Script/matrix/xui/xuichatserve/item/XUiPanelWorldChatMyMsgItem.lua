XUiPanelWorldChatMyMsgItem = XClass(nil, "XUiPanelWorldChatMyMsgItem")
local XUiPanelNameplate = require("XUi/XUiNameplate/XUiPanelNameplate")
function XUiPanelWorldChatMyMsgItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitAutoScript()

    local prefab = self.PanelMsg:Find("PanelName"):LoadPrefab(XMedalConfigs.XNameplatePanelPath)
    self.UiPanelNameplate = XUiPanelNameplate.New(prefab, self)
    -- self.UiPanelNameplate = XUiPanelNameplate.New(self.PanelNameplate, self)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelWorldChatMyMsgItem:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelWorldChatMyMsgItem:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelWorldChatMyMsgItem:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelWorldChatMyMsgItem:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelWorldChatMyMsgItem:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnView, self.OnBtnViewClick)
    self:RegisterListener(self.TxtWord, "onHrefClick", self.OnBtnHrefClick)

    -- 添加长按事件
    if self.BtnClickPointer then
        XUiButtonLongClick.New(self.BtnClickPointer, XScheduleManager.SECOND, self, nil, self.OnBtnLongClick, nil, true)
    end
end

function XUiPanelWorldChatMyMsgItem:OnBtnLongClick()
    if self.LongClickCallBack then
        self.LongClickCallBack(self)
    end
end

-- auto
function XUiPanelWorldChatMyMsgItem:OnBtnViewClick()
    if XDataCenter.RoomManager.RoomData and self.playerId == XPlayer.Id then
        --在房间中不能在聊天打开自己详情面板
        return
    end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.playerId, nil, nil, self.ChatContent)
end

function XUiPanelWorldChatMyMsgItem:OnBtnHrefClick(param)
    XDataCenter.RoomManager.ClickEnterRoomHref(param, self.CreateTime)
end

function XUiPanelWorldChatMyMsgItem:RefreshBabelTowerLevel(chatData)
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

function XUiPanelWorldChatMyMsgItem:RefreshGuildRankLevel(chatData)
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

function XUiPanelWorldChatMyMsgItem:Refresh(chatData, longClickCb)
    self.LongClickCallBack = longClickCb
    self.CreateTime = chatData.CreateTime
    self.playerId = chatData.SenderId
    self.ChatContent = chatData.Content
    local playerName = XDataCenter.SocialManager.GetPlayerRemark(chatData.SenderId, chatData.NickName)
    self.TxtName.text = playerName
    
    self:RefreshBabelTowerLevel(chatData)
    self:RefreshGuildRankLevel(chatData)
    self.TxtWord.text = chatData.Content

    if not string.IsNilOrEmpty(chatData.CustomContent) then
        self.TxtWord.supportRichText = true
    else
        self.TxtWord.supportRichText = false
    end

    local medalConfig = XMedalConfigs.GetMeadalConfigById(chatData.CurrMedalId)
    local medalIcon = nil

    if medalConfig then
        medalIcon = medalConfig.MedalIcon
    end
    
    XUiPLayerHead.InitPortrait(chatData.Icon, chatData.HeadFrameId, self.Head)

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
end

function XUiPanelWorldChatMyMsgItem:GetPlayerId()
    return self.playerId
end

function XUiPanelWorldChatMyMsgItem:GetContent()
    return self.Content
end

function XUiPanelWorldChatMyMsgItem:GetChatContent()
    return self.ChatContent
end