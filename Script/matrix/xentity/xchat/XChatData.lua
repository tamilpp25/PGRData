--从服务器接收的格式
---@class XChatData 聊天数据
XChatData = XClass(nil, "XChatData")

local Default = {
    MessageId = 0,
    ChannelType = 0,
    MsgType = 0,
    SenderId = 0,
    Icon = 0,
    NickName = "",
    TargetId = 0,
    CreateTime = 0,
    Content = 0,
    GiftId = 0,
    GiftCount = 0,
    GiftStatus = 0,
    IsRead = false,
    CurrMedalId = 0,
    BabelTowerLevel = 0,
    BabelTowerTitleId = 0,
    GuildRankLevel = 0,
    GuildName = "",
    CollectWordId = 0,
    NameplateId = 0,
}

function XChatData:Ctor(chatData)
    for key in pairs(Default) do
        self[key] = Default[key]
    end

    if chatData == nil then
        return
    end

    self.MessageId = chatData.MessageId
    self.ChannelType = chatData.ChannelType
    self.MsgType = chatData.MsgType
    self.SenderId = chatData.SenderId
    self.Icon = chatData.Icon
    self.HeadFrameId = chatData.HeadFrameId
    self.NickName = chatData.NickName
    self.TargetId = chatData.TargetId
    self.CreateTime = chatData.CreateTime
    self.Content = chatData.Content
    self.GiftId = chatData.GiftId
    self.GiftCount = chatData.GiftCount
    self.GiftStatus = chatData.GiftStatus
    self.CurrMedalId = chatData.CurrMedalId
    self.BabelTowerLevel = chatData.BabelTowerTitleInfo and chatData.BabelTowerTitleInfo.Score or 0
    self.BabelTowerTitleId = chatData.BabelTowerTitleInfo and chatData.BabelTowerTitleInfo.Id or nil
    self.CustomContent = chatData.CustomContent
    self.GuildRankLevel = chatData.GuildRankLevel
    self.GuildName = chatData.GuildName
    self.CollectWordId = chatData.CollectWordId
    self.IsRead = false
    self.NameplateId = chatData.NameplateId or 0
end

function XChatData:GetSendTime()
    local time = XTime.TimestampToGameDateTimeString(self.CreateTime, "HH:mm:ss")
    return time
end

function XChatData.EncodeRoomMsg(...)
    local content = ""

    for _, v in ipairs { ... } do
        content = content .. v .. "|"
    end

    return content
end

function XChatData.DecodeRoomMsg(content)
    return content:Split("|")
end

function XChatData:GetRoomMsgContent()
    if self.Content:IsNilOrEmpty() then
        return ""
    end

    local contentData = XChatData.DecodeRoomMsg(self.Content)
    if not contentData then
        return ""
    end

    local contentId = tonumber(contentData[1])
    local playerId = tonumber(contentData[2])
    local stageId = tonumber(contentData[3])
    local roomId = contentData[4]
    local roomType = tonumber(contentData[5])
    local stageLevel = tonumber(contentData[6])

    if contentId == RoomMsgContentId.FrinedInvite then
        -- 普通联机
        if MultipleRoomType.Normal == roomType or MultipleRoomType.ArenaOnline == roomType or MultipleRoomType.FubenPhoto == roomType then
            local playerName
            if playerId == XPlayer.Id then
                playerName = XPlayer.Name
            else
                playerName = XDataCenter.SocialManager.GetPlayerRemark(playerId, "")
            end
            
            local stageName = ""
            if MultipleRoomType.ArenaOnline == roomType then
                local tempStageId = XDataCenter.ArenaOnlineManager.GetStageIdByIdAndLevel(stageId, stageLevel)
                if tempStageId then
                    stageName = XDataCenter.FubenManager.GetStageCfg(tempStageId).Name
                end
            else
                stageName = XDataCenter.FubenManager.GetStageCfg(stageId).Name
            end

            local inviteWords = CS.XTextManager.GetText("OnlineInviteLink", string.format("%s|%s|%s|%s", roomId, tostring(stageId), tostring(roomType), tostring(stageLevel)))
            return CS.XTextManager.GetText("OnlineInviteFriend", playerName, stageName, inviteWords)
        end
        -- 狙击战联机
        if MultipleRoomType.UnionKill == roomType then
            local playerName
            if playerId == XPlayer.Id then
                playerName = XPlayer.Name
            else
                playerName = XDataCenter.SocialManager.GetPlayerRemark(playerId, "")
            end

            local unionInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
            local activityName
            if not unionInfo then
                activityName = ""
            else
                local currentUnionActivityConfig = XFubenUnionKillConfigs.GetUnionActivityConfigById(unionInfo.Id)
                activityName = currentUnionActivityConfig.Name
            end

            local inviteWords = CS.XTextManager.GetText("OnlineInviteLink", string.format("%s|%s|%s|%s", roomId, tostring(stageId), tostring(roomType), tostring(stageLevel)))
            return CS.XTextManager.GetText("OnlineInviteFriend", playerName, activityName, inviteWords)
        end
        -- Dlc
        if MultipleRoomType.DlcHunt == roomType then
            local worldId = stageId
            local playerName
            if playerId == XPlayer.Id then
                playerName = XPlayer.Name
            else
                playerName = XDataCenter.SocialManager.GetPlayerRemark(playerId, "")
            end
            local stageName = XDlcHuntWorldConfig.GetWorldName(worldId)
            local inviteWords = CS.XTextManager.GetText("OnlineInviteLink", string.format("%s|%s|%s|%s", roomId, tostring(worldId), tostring(roomType), tostring(stageLevel)))
            return CS.XTextManager.GetText("OnlineInviteFriend", playerName, stageName, inviteWords)
        end
    end

    return ""
end

--检测是否自己发送的
function XChatData:CheckIsSelfChat()
    return self.SenderId == XPlayer.Id
end

function XChatData:GetChatTargetId()--获取聊天对象的id
    if (self:CheckIsSelfChat()) then
        return self.TargetId
    else
        return self.SenderId
    end
end

--该礼物消息属于送礼还是收礼
function XChatData:GetGiftChatType()
    if self.CreateTime == self.GiftCreateTime then
        return GiftChatType.Send
    else
        return GiftChatType.Receive
    end
end

--是否有自己可领取的礼物
function XChatData:CheckHaveGift()
    if (not self:CheckIsSelfChat() and
        self.MsgType == ChatMsgType.Gift and
        self.GiftStatus == ChatGiftState.WaitReceive) then
        return true
    else
        return false
    end
end

--发送或者接收的消息的类型
ChatChannelType = {
    System = 1, --系统
    World = 2, --世界
    Private = 3, --私聊
    Room = 4, --房间
    Battle = 5, --战斗
    Guild = 6, --公会
    Mentor = 7,--师徒
}

ChatMsgType = {
    Normal = 1, --普通消息
    Emoji = 2, --表情消息
    Gift = 3, --礼物消息
    Tips = 4, --提示消息
    RoomMsg = 5, -- 联机房间消息
    System = 6, --公会系统消息
    SpringFestival = 7, --春节集字活动消息
}

-- PrivateChatPrefabType = {
--     SelfChatBox = 1,
--     SelfChatEmojiBox = 2,
--     OtherChatBox = 3,
--     OtherChatEmojiBox = 4,
--     SelfGiftBox = 5,
--     OtherGiftBox = 6
-- }

ChatGiftState = {
    None = 0,
    WaitReceive = 1, --等待接收状态
    Received = 2, --已领取
    Fetched = 3, --不能领取
}

GiftChatType = {
    Send = 1,
    Receive = 2,
}

RoomMsgContentId = {
    FrinedInvite = 1,
}

MultipleRoomType = {
    Normal = 1,
    UnionKill = 2,
    ArenaOnline = 3,
    MultiDimOnline = 4,
    DlcHunt = 5,
    FubenPhoto=6,
}