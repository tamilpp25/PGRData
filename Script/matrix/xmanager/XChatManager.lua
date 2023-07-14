local tableInsert = table.insert
local ipairs = ipairs
local ChatChannelType = ChatChannelType
local CSTime = CS.UnityEngine.Time

XChatManagerCreator = function()
    local XChatManager = {}

    local CLIENT_WORLD_CHAT_MAX_SIZE = 0
    local CLIENT_ROOM_CHAT_MAX_SIZE = 0
    local REMOVE_CHAT_RECORD_OF_DAY = 0
    local CHAT_INTERVAL_TIME = 0
    local TodayResetTime = 0
    local WORLD_CHAT_MAX_COUNT = 0
    local MENTOR_CHAT_MAX_COUNT = 0
    -- 一天的秒数
    local ONE_DAY_SECONDS = 60 * 60 * 24

    local WorldChatList = {}    --保存世界聊天记录
    local PrivateChatMap = {}   --保存私聊的聊天纪录
    local GuildChatList = {}    --保存公会聊天纪录
    local RoomChatList = {}     --保存房间聊天记录
    local MentorChatList = {}   --师徒聊天记录
    local ChatList = {}         --各类聊天记录
    local EmojiDatasDic = {}
    local EffectInfo = {}       -- 关键字屏幕特效
    local EffectTriggerType = {
        Me = 1,
        Other = 2,
        All = 3,
    }
    local LastChatCoolTime = 0
    local LastEffectCoolTime = 0

    local MessageId = -1        --离线消息
    local OfflineMessageTag = "OfflineRecordMessage_"

    local LastRequestChannelTime = 0
    local CurrentChatChannelId = 0
    local LastReadChatTime = {}
    local ChatChannelInfos
    local GuildChatContent = ""
    local GuildSaveCount = 0
    local MentorChatContent = ""
    local MentorSaveCount = 0
    local SubManager = {}
    --协议处理
    local MethodName = {
        SendChat = "SendChatRequest",
        GetGift = "GetGiftsRequest",
        GetAllGiftsRequest = "GetAllGiftsRequest",
        GetOfflineMessageRequest = "OfflineMessageRequest",
        SelectChatChannelRequest = "SelectChatChannelRequest",
        EnterWorldChatRequest = "EnterWorldChatRequest",
        GetWorldChannelInfoRequest = "GetWorldChannelInfoRequest",
        CatchRepeatChat = "ReportBanChatRequest", --重复发言检测
    }

    function XChatManager.Init()
        REMOVE_CHAT_RECORD_OF_DAY = CS.XGame.ClientConfig:GetInt("RemoveChatRecordOfDay")
        CLIENT_WORLD_CHAT_MAX_SIZE = CS.XGame.ClientConfig:GetInt("WorldChatMaxSize")
        CLIENT_ROOM_CHAT_MAX_SIZE = CS.XGame.ClientConfig:GetInt("RoomChatMaxSize")
        CHAT_INTERVAL_TIME = CS.XGame.Config:GetInt("ChatIntervalTime")
        WORLD_CHAT_MAX_COUNT = CS.XGame.Config:GetInt("WorldChatMaxCount")
        MENTOR_CHAT_MAX_COUNT = XMentorSystemConfigs.GetMentorSystemData("MentorChatMaxCount")

        ChatList[ChatChannelType.World] = WorldChatList
        ChatList[ChatChannelType.Guild] = GuildChatList
        ChatList[ChatChannelType.Room] = RoomChatList
        ChatList[ChatChannelType.Mentor] = MentorChatList

        for _, type in pairs(ChatChannelType) do
            local key = string.format("%s%d" ,XChatConfigs.KEY_LAST_READ_CHAT_TIME, type)
            LastReadChatTime[type] = XSaveTool.GetData(key) or XMath.IntMax()
        end

        XEventManager.AddEventListener(XEventId.EVENT_ROOM_LEAVE_ROOM, function()
            RoomChatList = {}
            ChatList[ChatChannelType.Room] = RoomChatList
        end)
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, function()
            XChatManager.InitChatChannel()
            -- 登录完成后直接获取所有频道信息
            XChatManager.GetWorldChannelInfos()
        end)

        -- 聊天播放特效功能
        local effectTemplates = XChatConfigs.GetEffectTemplates()
        local nowTime = XTime.GetServerNowTimestamp()
        for _, template in pairs(effectTemplates) do
            local endTime = XTime.ParseToTimestamp(template.EndTimeStr)
            if nowTime < endTime then
                local data = XTool.Clone(template)
                data.BeginTime = XTime.ParseToTimestamp(data.BeginTimeStr)
                data.EndTime = endTime
                tableInsert(EffectInfo, data)
            end
        end

        XChatManager.SetMetaTable()
        XChatManager.InitSubManager()
    end

    function XChatManager.SetMetaTable()
        local _mTable = {__index = function(baseTable, key)
                for _, manager in pairs(SubManager) do
                    if manager and manager[key] then
                        local v = manager[key]
                        baseTable[key] = v
                        return v
                    end
                end
                return nil
            end}
        setmetatable(XChatManager, _mTable)
    end
    
    function XChatManager.InitSubManager()
        local InitManager = function(managerName)
            local manager = require("XEntity/XChat/XChat" .. managerName .. "Manager")
            if manager then
                manager.Init(XChatManager)
                table.insert(SubManager, manager)
            end
        end
        InitManager("EmojiPack")
    end
    
    function XChatManager.GetLastRequestChannelTime()
        return LastRequestChannelTime
    end

    function XChatManager.SetLastRequestChannelTime(time)
        LastRequestChannelTime = time
    end

    function XChatManager.GetWorldChatMaxCount()
        return WORLD_CHAT_MAX_COUNT
    end
    
    function XChatManager.GetMentorChatMaxCount()
        return MENTOR_CHAT_MAX_COUNT
    end

    -- 初始化世界聊天数据
    function XChatManager.InitWorldChatData(worldChatDataList)
        WorldChatList = {}
        ChatList[ChatChannelType.World] = WorldChatList
        local WorldChatLoop = function(item)
            if item ~= nil then
                XChatManager.ProcessExtraContent(item)
                tableInsert(WorldChatList, 1, item)
            end
        end
        XTool.LoopCollection(worldChatDataList, WorldChatLoop)
    end

    --加载私聊信息
    function XChatManager.InitFriendPrivateChatData()
        PrivateChatMap = {}
        local cb = function()
            for _, friendId in pairs(XDataCenter.SocialManager.GetFriendIds()) do
                XChatManager.ReadSpecifyFriendsChatContent(friendId)
            end
            XChatManager.GetOfflineMessageRequest(XChatManager.GetLocalOfflineRecord())
        end
        XDataCenter.SocialManager.GetFriendsInfo(cb)
    end

    --处理系统消息
    local function HandleSystemChat()
        --TODO Handle System Chat
    end

    --处理世界消息
    local function HandleWorldChat(chatData, isNotify)
        --黑名单的聊天数据不加入
        if XDataCenter.SocialManager.GetBlackData(chatData.SenderId) then
            return
        end

        if #WorldChatList >= CLIENT_WORLD_CHAT_MAX_SIZE then
            table.remove(WorldChatList, #WorldChatList)
        end
        tableInsert(WorldChatList, 1, chatData)

        if isNotify then
            XEventManager.DispatchEvent(XEventId.EVENT_CHAT_RECEIVE_WORLD_MSG, chatData)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_RECEIVE_WORLD_MSG, chatData)
        end
    end

    --处理公会消息
    local function HandleGuildChat(chatData, isNotify)
        if XDataCenter.SocialManager.GetBlackData(chatData.SenderId) then
            return
        end

        tableInsert(GuildChatList, 1, chatData)
        if isNotify then
            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_RECEIVE_CHAT, chatData)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_RECEIVE_CHAT, chatData)
        end
    end
    
    --处理师徒消息
    local function HandleMentorChat(chatData, isNotify)
        if XDataCenter.SocialManager.GetBlackData(chatData.SenderId) then
            return
        end

        if #MentorChatList >= MENTOR_CHAT_MAX_COUNT then
            table.remove(MentorChatList, #MentorChatList)
        end
        tableInsert(MentorChatList, 1, chatData)

        if isNotify then
            XEventManager.DispatchEvent(XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG, chatData)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG, chatData)
        end
    end

    --处理私聊消息
    local function HandlePrivateChat(chatData, ignoreNotify)
        if XDataCenter.SocialManager.GetBlackData(chatData.SenderId) then
            return
        end

        if (not chatData) then
            return
        end
        if chatData.SenderId == XPlayer.Id or
            chatData.MsgType == ChatMsgType.Gift or
            chatData.MsgType == ChatMsgType.Tips then
            chatData.IsRead = true
        end
        if chatData.SenderId ~= XPlayer.Id then
            XChatManager.UpdateLocalOfflineRecord(chatData.MessageId or 0)
        end
        local targetId = chatData:GetChatTargetId()

        XChatManager.AddPrivateChatData(targetId, chatData, false, ignoreNotify)

        --保存消息
        XChatManager.SaveSpecifyFriendsChatContent(targetId)
    end

    --处理房间消息
    local function HandleRoomChat(chatData)
        if XDataCenter.SocialManager.GetBlackData(chatData.SenderId) then
            return
        end

        if #RoomChatList >= CLIENT_ROOM_CHAT_MAX_SIZE then
            table.remove(RoomChatList, #RoomChatList)
        end
        tableInsert(RoomChatList, 1, chatData)

        XEventManager.DispatchEvent(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, chatData)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, chatData)
    end

    -- 清除房间聊天
    function XChatManager.ResetRoomChat()
        RoomChatList = {}
        ChatList[ChatChannelType.Room] = RoomChatList
    end

    function XChatManager.OnSynChat(chatMsg, ignoreNotify)
        local chatData = XChatData.New(chatMsg)
        if chatMsg.ChannelType == ChatChannelType.System then
            HandleSystemChat(chatData)
        elseif chatMsg.ChannelType == ChatChannelType.World then
            HandleWorldChat(chatData, true)
        elseif chatMsg.ChannelType == ChatChannelType.Private then
            HandlePrivateChat(chatData, ignoreNotify)
        elseif chatMsg.ChannelType == ChatChannelType.Room then
            HandleRoomChat(chatData)
        elseif chatMsg.ChannelType == ChatChannelType.Guild then
            HandleGuildChat(chatData, true)
            XChatManager.SaveGuildChatContent()
        elseif chatMsg.ChannelType == ChatChannelType.Mentor then
            HandleMentorChat(chatData, true)
        end

        --接收到礼物时增加一条tip提示
        if chatMsg.MsgType == ChatMsgType.Gift then
            chatMsg.MsgType = ChatMsgType.Tips
            chatMsg.CreateTime = chatMsg.CreateTime
            chatMsg.GiftId = chatMsg.GiftId
            XChatManager.OnSynChat(chatMsg, true)
        end
    end



    ---------------------------------public function-----------------------------------
    function XChatManager.GetRemoveChatRecordOfDays()
        return REMOVE_CHAT_RECORD_OF_DAY
    end

    function XChatManager.GetWorldChatMaxSize()
        return CLIENT_WORLD_CHAT_MAX_SIZE
    end

    --=== Emoji ===
    function XChatManager.GetEmojiIcon(emojiId)
        return XChatConfigs.GetEmojiIcon(emojiId)
    end

    function XChatManager.GetEmojiQuality()
        return XChatConfigs.GetEmojiQuality()
    end

    function XChatManager.GetEmojiName(emojiId)
        return XChatConfigs.GetEmojiName(emojiId)
    end

    function XChatManager.GetEmojiDescription(emojiId)
        return XChatConfigs.GetEmojiDescription(emojiId)
    end

    function XChatManager.GetEmojiWorldDesc(emojiId)
        return XChatConfigs.GetEmojiWorldDesc(emojiId)
    end

    function XChatManager.GetEmojiBigIcon(emojiId)
        return XChatConfigs.GetEmojiBigIcon(emojiId)
    end

    function XChatManager.GetEmojiTemplates()
        local templates = {}

        for _, emojiData in pairs(EmojiDatasDic) do
            tableInsert(templates, emojiData)
        end
        table.sort(templates, function(l, r) return l:GetEmojiOrder() < r:GetEmojiOrder() end)
        return templates
    end

    function XChatManager.GetEmojiDatasDic()
        return EmojiDatasDic
    end

    function XChatManager.IsEmojiValid(emojiId)
        for _, v in pairs(EmojiDatasDic) do
            if v:IsEmojiValid(emojiId) then
                return true
            end
        end

        return false
    end

    --=== Any Chat ===
    function XChatManager.GetChatList(type)
        return ChatList[type]
    end

    --=== World Chat ===
    function XChatManager.GetWorldChatList()
        return WorldChatList
    end

    --=== Guild Chat ===
    function XChatManager.GetGuildChatList()
        return GuildChatList
    end

    --=== Mentor Chat ===
    function XChatManager.GetMentorChatList()
        return MentorChatList
    end
    
    --=== Room Chat ===
    function XChatManager.GetRoomChatList()
        table.sort(RoomChatList, function(a, b)
            if a.CreateTime ~= b.CreateTime then
                return a.CreateTime > b.CreateTime
            end
        end)
        return RoomChatList
    end

    --=== Private Chat ===
    -- 获取私聊聊天数据
    function XChatManager.GetPrivateDynamicList(friendId)
        local msgData = XChatManager.GetPrivateChatsByFriendId(friendId)
        local sortFunc = function(a, b)
            if a.CreateTime ~= b.CreateTime then
                return a.CreateTime > b.CreateTime
            else
                if a.MsgType == ChatMsgType.Tips then
                    if b.MsgType == ChatMsgType.Tips then
                        return a.GiftStatus > b.GiftStatus
                    end
                    return true
                end
            end
        end
        table.sort(msgData, sortFunc)
        return msgData
    end

    -- 获取私聊好友id列表
    function XChatManager.GetPrivateChatGroupData(nowID)
        --初始化数据
        local chatFriendIdList = XChatManager.GetHaveChatDataFriendIds()
        local targetInList = false
        for _, id in ipairs(chatFriendIdList) do
            if id == nowID then
                targetInList = true
                break
            end
        end
        if not targetInList then
            tableInsert(chatFriendIdList, 1, nowID)
        end

        local dynamicListData = {}
        for _, v in ipairs(chatFriendIdList) do
            local friendInfo = XDataCenter.SocialManager.GetFriendInfo(v)
            tableInsert(dynamicListData, friendInfo)
        end
        return dynamicListData
    end


    --新增私聊消息
    function XChatManager.AddPrivateChatData(friendId, chatData, isInit, ignoreNotify)
        if XDataCenter.SocialManager.GetBlackData(friendId) then
            return
        end

        --好友聊天数据结构
        local friendChats = PrivateChatMap[friendId]
        if not friendChats then
            friendChats = {}
            friendChats.ChatMap = {}
            friendChats.LastChat = nil
            PrivateChatMap[friendId] = friendChats
        end

        friendChats.LastChat = chatData

        friendChats.ChatMap = friendChats.ChatMap or {}
        tableInsert(friendChats.ChatMap, chatData)

        if not isInit or not chatData.IsRead then
            if not ignoreNotify then
                XEventManager.DispatchEvent(XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT, chatData)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT, chatData)
            end
        end
    end

    --获取已聊天过的好友id列表
    function XChatManager.GetHaveChatDataFriendIds()
        local list = {}

        for friendId, chatInfo in pairs(PrivateChatMap) do
            if chatInfo and chatInfo.ChatMap then
                for _, _ in pairs(chatInfo.ChatMap) do
                    tableInsert(list, friendId)
                    break
                end
            end
        end

        if #list >= 2 then
            local sortByCreateTime = function(l, r)
                local lchat = XChatManager.GetLastPrivateChatByFriendId(l)
                local rchat = XChatManager.GetLastPrivateChatByFriendId(r)
                if lchat.CreateTime > rchat.CreateTime then
                    return true
                else
                    return false
                end
            end
            table.sort(list, sortByCreateTime)
        end

        return list
    end

    --更新礼物信息
    function XChatManager.UpdateGiftData(friendId, giftId, status, giftCount)
        local friendChats = PrivateChatMap[friendId]
        if not friendChats or not friendChats.ChatMap then
            return
        end

        for _, v in pairs(friendChats.ChatMap) do
            if (v.MsgType == ChatMsgType.Gift or v.MsgType == ChatMsgType.Tips) and v.GiftId == giftId and v.SenderId == friendId then
                friendChats.LastChat = v
                v.GiftStatus = status
                if giftCount and giftCount > 0 then
                    v.GiftCount = giftCount
                end
            end
        end
        --保存消息
        XChatManager.SaveSpecifyFriendsChatContent(friendId)
    end

    --获取指定好友聊天列表
    function XChatManager.GetPrivateChatsByFriendId(friendId)
        local list = {}
        if (PrivateChatMap[friendId] and PrivateChatMap[friendId].ChatMap) then
            for _, chat in pairs(PrivateChatMap[friendId].ChatMap) do
                tableInsert(list, chat)
            end
        end
        return list
    end

    --获取好友最后一条聊天
    function XChatManager.GetLastPrivateChatByFriendId(friendId)
        local lastChat = nil
        local info = PrivateChatMap[friendId]
        if (info) then
            lastChat = info.LastChat
        end
        return lastChat
    end

    --获取好友未读聊天数量
    function XChatManager.GetPrivateUnreadChatCountByFriendId(friendId)
        local count = 0
        local info = PrivateChatMap[friendId]
        if (info and info.ChatMap) then
            for _, chat in pairs(info.ChatMap) do
                if (not chat.IsRead) then
                    count = count + 1
                end
            end
        end
        return count
    end

    --设置指定好友全部聊天为已读
    function XChatManager.SetPrivateChatReadByFriendId(friendId)
        local friendChat = PrivateChatMap[friendId]
        local count = 0
        if friendChat and friendChat.ChatMap then
            for _, chat in pairs(friendChat.ChatMap) do
                if not chat.IsRead then
                    chat.IsRead = true
                    count = count + 1
                end
            end
        end

        --保存消息
        XChatManager.SaveSpecifyFriendsChatContent(friendId)

        if count > 0 then
            XEventManager.DispatchEvent(XEventId.EVENT_FRIEND_READ_PRIVATE_MSG)
        end
    end

    --检测好友是否有自己可以领取的礼物
    function XChatManager.CheckDoesHaveGiftByFriendId(friendId)
        local friendChats = PrivateChatMap[friendId]
        if not friendChats or not friendChats.ChatMap then
            return false
        end
        for _, v in pairs(friendChats.ChatMap) do
            if v:CheckHaveGift() then
                return true
            end
        end
        return false
    end

    ---------------------------------Chat Record-----------------------------------
    local ChatRecordTag = "ChatRecord_%d_%d"  --标识 + 好友id + 自己id

    --读取指定好友的聊天内容
    function XChatManager.ReadSpecifyFriendsChatContent(friendId)
        local key = string.format(ChatRecordTag, friendId, XPlayer.Id)
        if CS.UnityEngine.PlayerPrefs.HasKey(key) then
            local chatRecord = CS.UnityEngine.PlayerPrefs.GetString(key)
            local msgTab = string.Split(chatRecord, '\n')
            if msgTab ~= nil and #msgTab > 0 then
                for index = 1, #msgTab do
                    local content = msgTab[index]
                    if (not string.IsNilOrEmpty(content)) then
                        local tab = string.Split(content, '\t')
                        if tab ~= nil then
                            if XChatManager.CheckIsRemove(tonumber(tab[3])) then
                                local chatData = XChatData.New()
                                chatData.ChannelType = ChatChannelType.Private

                                chatData.SenderId = tonumber(tab[1])
                                chatData.TargetId = tonumber(tab[2])
                                chatData.CreateTime = tonumber(tab[3])
                                chatData.Content = tab[4]
                                chatData.MsgType = tonumber(tab[5])
                                chatData.GiftId = tonumber(tab[6])
                                chatData.GiftCount = tonumber(tab[7])
                                chatData.GiftStatus = tonumber(tab[8])
                                chatData.IsRead = tonumber(tab[9]) == 1
                                chatData.CustomContent = tab[10]

                                if XPlayer.Id == chatData.SenderId then
                                    chatData.Icon = XPlayer.CurrHeadPortraitId
                                    chatData.NickName = XPlayer.Name
                                    chatData.HeadFrameId = XPlayer.CurrHeadFrameId
                                else
                                    local friendInfo = XDataCenter.SocialManager.GetFriendInfo(friendId)
                                    if friendInfo then
                                        chatData.Icon = friendInfo.Icon
                                        chatData.NickName = friendInfo.NickName
                                        chatData.HeadFrameId = friendInfo.HeadFrameId
                                    end
                                end
                                XChatManager.ProcessExtraContent(chatData)
                                XChatManager.AddPrivateChatData(friendId, chatData, true)
                            end
                        end
                    end
                end
            end
        end
    end

    --检测该消息是否是七天前的
    function XChatManager.CheckIsRemove(time)
        if time == nil then
            return false
        end
        local curTime = XTime.GetServerNowTimestamp()
        return curTime - time <= REMOVE_CHAT_RECORD_OF_DAY * 24 * 60 * 60
    end

    function XChatManager.DeleteGuildChat(guildId)
        GuildChatList = {}
        ChatList[ChatChannelType.Guild] = GuildChatList
        local key = XDataCenter.GuildManager.GetGuildChannelKey(guildId)
        if CS.UnityEngine.PlayerPrefs.HasKey(key) then
            CS.UnityEngine.PlayerPrefs.DeleteKey(key)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    -- 登录初始化公会聊天内容
    function XChatManager.InitLocalCacheGuildChatContent()
        if not XDataCenter.GuildManager.IsJoinGuild() then return end
        local guildId = XDataCenter.GuildManager.GetGuildId()
        local key = XDataCenter.GuildManager.GetGuildChannelKey(guildId)
        if CS.UnityEngine.PlayerPrefs.HasKey(key) then
            GuildChatList = {}
            ChatList[ChatChannelType.Guild] = GuildChatList
            local chatRecord = CS.UnityEngine.PlayerPrefs.GetString(key)
            local allLines = string.Split(chatRecord, '\n')
            if allLines ~= nil and #allLines > 0 then
                for i = 1, #allLines do
                    local content = allLines[i]
                    if (not string.IsNilOrEmpty(content)) then
                        local tab = string.Split(content, '\t')
                        if tab ~= nil then
                            local chatData = XChatData.New()
                            chatData.SenderId = tonumber(tab[1])
                            chatData.TargetId = tonumber(tab[2])
                            chatData.CreateTime = tonumber(tab[3])
                            chatData.Content = tab[4]
                            chatData.MsgType = tonumber(tab[5])
                            chatData.IsRead = tonumber(tab[6])
                            chatData.MessageId = tonumber(tab[7])
                            chatData.Icon = tonumber(tab[8])
                            chatData.CustomContent = tab[9]
                            chatData.NickName = tab[10]
                            chatData.GuildRankLevel = tonumber(tab[11])
                            chatData.ChannelType = tonumber(tab[12])
                            chatData.HeadFrameId = tonumber(tab[13])
                            chatData.CollectWordId = tonumber(tab[14])
                            chatData.NameplateId = tonumber(tab[15]) or 0
                            tableInsert(GuildChatList, chatData)
                        end
                    end
                end
            end
        end
    end

    -- 合并客户端，服务端公会聊天
    function XChatManager.MergeClientAndServerGuildChat(serverChat)

        if #serverChat <= 0 then return end
        if #GuildChatList <= 0 then
            if #serverChat > 0 then
                for _, chatData in pairs(serverChat) do
                    tableInsert(GuildChatList, chatData)
                end
                return
            end
        end

        local clientTailIndex = 1
        local clientTailCreateTime = GuildChatList[clientTailIndex].CreateTime

        local serverTailIndex = #serverChat
        local serverTailCreateTime = serverChat[serverTailIndex].CreateTime

        local serverHeadIndex = 1
        local serverHeadCreateTime = serverChat[serverHeadIndex].CreateTime

        -- 服务端缓存与客户端缓存完全重叠
        if clientTailCreateTime > serverHeadCreateTime then
            return
        end

        -- 服务端缓存与客户端缓存部分重叠
        local beginIndex = 0
        if serverTailCreateTime <= clientTailCreateTime and clientTailCreateTime <= serverHeadCreateTime then
            local clientHeadChat = GuildChatList[clientTailIndex]
            for i = #serverChat, 1, -1 do
                local curServerChat = serverChat[i]

                if clientHeadChat.CreateTime == curServerChat.CreateTime and
                clientHeadChat.SenderId == curServerChat.SenderId and
                clientHeadChat.Content == curServerChat.Content then

                    beginIndex = i - 1
                    break
                end

                if clientHeadChat.CreateTime < curServerChat.CreateTime then
                    beginIndex = i
                    break
                end
            end

            if beginIndex > 0 and beginIndex <= #serverChat then
                for i = beginIndex, 1, -1 do
                    tableInsert(GuildChatList, 1, serverChat[i])
                end
            end
            XChatManager.SaveGuildChatContent()
            return
        end

        -- 服务端缓存与客户端缓存完成不重叠
        if clientTailCreateTime < serverTailCreateTime then
            for i = #serverChat, 1, -1 do
                tableInsert(GuildChatList, 1, serverChat[i])
            end
        end
        XChatManager.SaveGuildChatContent()
    end

    -- 存储公会聊天内容
    function XChatManager.SaveGuildChatContent()
        if not XDataCenter.GuildManager.IsJoinGuild() then return end
        local splitMark = "\n"
        for i = #GuildChatList-GuildSaveCount, 1, -1 do
            local chat = GuildChatList[i]
            local list = {}
            if chat ~= nil and type(chat) == 'table' and i <= XGuildConfig.GuildChatCacheCount then
                tableInsert(list, chat.SenderId)
                tableInsert(list, chat.TargetId)
                tableInsert(list, chat.CreateTime)
                tableInsert(list, chat.Content)
                tableInsert(list, chat.MsgType)
                tableInsert(list, (chat.IsRead and "1" or "0"))
                tableInsert(list, chat.MessageId)
                tableInsert(list, chat.Icon)
                tableInsert(list, (chat.CustomContent or ""))
                tableInsert(list, (chat.NickName or ""))
                tableInsert(list, (chat.GuildRankLevel or "0"))
                tableInsert(list, (chat.ChannelType or "0"))
                tableInsert(list, (chat.HeadFrameId or "0"))
                tableInsert(list, (chat.CollectWordId or "0"))
                tableInsert(list, (chat.NameplateId or "0"))
            end
            GuildSaveCount = GuildSaveCount + 1
            local chatStr = table.concat(list, "\t")
            GuildChatContent = string.format("%s%s%s", chatStr, splitMark, GuildChatContent)
        end
        if GuildChatContent ~= nil and GuildChatContent ~= '' then
            local guildId = XDataCenter.GuildManager.GetGuildId()
            local key = XDataCenter.GuildManager.GetGuildChannelKey(guildId)
            CS.UnityEngine.PlayerPrefs.SetString(key, GuildChatContent)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    -- 关键字匹配
    function XChatManager.KeywordMatch(channelType, chatData)
        local nowTime = XTime.GetServerNowTimestamp()
        local firstMatchIndex = nil
        local minMatchPos = XMath.IntMax()
        for index, info in ipairs(EffectInfo) do
            local isMatch = true
            isMatch = isMatch and nowTime > info.BeginTime and nowTime < info.EndTime
            isMatch = isMatch and nowTime > LastEffectCoolTime + info.CoolTime
            isMatch = isMatch and chatData.MsgType == ChatMsgType.Normal or chatData.MsgType == ChatMsgType.RoomMsg
            if not isMatch then goto CONTINUE end
            
            if info.TriggerType == EffectTriggerType.Me then
                isMatch = isMatch and chatData.SenderId == XPlayer.Id
            elseif info.TriggerType == EffectTriggerType.Other then
                isMatch = isMatch and chatData.SenderId ~= XPlayer.Id
            end

            if info.Channel and next(info.Channel) then
                local isPartMatch = false
                for _,channel in ipairs(info.Channel) do
                    isPartMatch = isPartMatch or channel == channelType
                end
                isMatch = isMatch and isPartMatch
            end
            
            if not isMatch then goto CONTINUE end
            
            -- 开始匹配具体内容
            if info.Keyword and next(info.Keyword) then
                for _,pattern in ipairs(info.Keyword) do
                    local matchPos = string.find(chatData.Content, pattern)
                    if matchPos and matchPos < minMatchPos then
                        firstMatchIndex = index
                        minMatchPos = matchPos
                    end
                end

            end
            :: CONTINUE ::
        end
        if firstMatchIndex then
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_MATCH_EFFECT, EffectInfo[firstMatchIndex])
            return
        end
    end

    -- 设置特效播放完毕的时间
    function XChatManager.SetEffectEnd(time)
        LastEffectCoolTime = time or XTime.GetServerNowTimestamp()
    end
    
    -- 设置最后一次读消息的时间
    function XChatManager.SetChatRead(type)
        local key = string.format("%s%d" ,XChatConfigs.KEY_LAST_READ_CHAT_TIME, type)
        if next(ChatList[type]) then 
            LastReadChatTime[type] = ChatList[type][1].CreateTime
        else
            local nowTime = XTime.GetServerNowTimestamp()
            LastReadChatTime[type] = nowTime
            -- XLog.Warning("nowTime",XTime.TimestampToLocalDateTimeString(nowTime),type)
        end
        XSaveTool.SaveData(key, LastReadChatTime[type])
    end

    -- 获取未读信息数量
    function XChatManager.GetUnreadChatCount(type)
        local count = 0
        local chatList = XChatManager.GetChatList(type)
        if not (chatList and next(chatList)) then 
            return count 
        end
        for i = 1, #chatList do
            local chat = chatList[i]
            if chat.CreateTime > LastReadChatTime[type] then
                count = count + 1
            end
        end
        return count
    end

    function XChatManager.CheckRedPointByType(type)
        -- return XChatManager.GetUnreadChatCount(type) > 0
        local chatList = XChatManager.GetChatList(type)
        if not (chatList and next(chatList)) then
            return false
        end
        -- 除了好友消息，其他类型都是将最新消息插入到表头
        -- XLog.Warning(chatList)
        -- XLog.Warning(type, chatList[1].CreateTime > LastReadChatTime[type], chatList[1].CreateTime, XTime.TimestampToLocalDateTimeString(LastReadChatTime[type]),XTime.TimestampToLocalDateTimeString(chatList[1].CreateTime))
        return chatList[1].CreateTime > LastReadChatTime[type]
    end

    function XChatManager.GetLatestChatData(type)
        if type then
            return ChatList[type][1]
        else
            -- 默认返回最后一次公会或者世界聊天内容
            local worldMsg = ChatList[ChatChannelType.World][1]
            local guildMsg = ChatList[ChatChannelType.Guild][1]
            local latestMsg
            local latestTime = 0
            if guildMsg then 
                latestMsg = guildMsg
                latestTime = guildMsg.CreateTime
            end
            if worldMsg and worldMsg.CreateTime > latestTime then
                latestMsg = worldMsg
                latestTime = worldMsg.CreateTime
            end
            return latestMsg
        end
    end

    -- 删除上一个公会的聊天缓存
    function XChatManager.DeleteLastGuildChatContent(lastGuildId)
        if XDataCenter.GuideManager.IsJoinGuild() then
            local guildId = XDataCenter.GuildManager.GetGuildId()
            if guildId == lastGuildId then return end
        end
        local lastGuildKey = XDataCenter.GuildManager.GetGuildChannelKey(lastGuildId)
        if CS.UnityEngine.PlayerPrefs.HasKey(lastGuildKey) then
            CS.UnityEngine.PlayerPrefs.DeleteKey(lastGuildKey)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    --存储指定好友的聊天内容
    function XChatManager.SaveSpecifyFriendsChatContent(friendId)
        local chatList = XChatManager.GetPrivateDynamicList(friendId)
        if chatList == nil or #chatList == 0 then
            return
        end
        local saveContent = ''
        for index = 1, #chatList do
            local chat = chatList[index]
            if chat ~= nil and type(chat) == 'table' then
                saveContent = saveContent .. chat.SenderId .. '\t'
                saveContent = saveContent .. chat.TargetId .. '\t'
                saveContent = saveContent .. chat.CreateTime .. '\t'
                saveContent = saveContent .. chat.Content .. '\t'
                saveContent = saveContent .. chat.MsgType .. "\t"
                saveContent = saveContent .. tostring(chat.GiftId) .. "\t"
                saveContent = saveContent .. tostring(chat.GiftCount) .. "\t"
                saveContent = saveContent .. tostring(chat.GiftStatus) .. "\t"
                saveContent = saveContent .. (chat.IsRead and "1" or "0") .. "\t"
                saveContent = saveContent .. (chat.CustomContent or "") .. "\n"
            end
        end
        if saveContent ~= nil and saveContent ~= '' then
            local key = string.format(ChatRecordTag, friendId, XPlayer.Id)
            CS.UnityEngine.PlayerPrefs.SetString(key, saveContent)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    --清除指定好友的聊天内容
    function XChatManager.ClearFriendChatContent(friendId)
        local key = string.format(ChatRecordTag, friendId, XPlayer.Id)
        PrivateChatMap[friendId] = nil
        if CS.UnityEngine.PlayerPrefs.HasKey(key) then
            CS.UnityEngine.PlayerPrefs.DeleteKey(key)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    --获取所有私聊信息
    function XChatManager.GetAllPrivateChatMsgCount()

        if not PrivateChatMap then
            return 0
        end
        local count = 0
        for _, v in pairs(PrivateChatMap) do
            local info = v
            if (info and info.ChatMap) then
                for _, chat in pairs(info.ChatMap) do
                    if (not chat.IsRead) then
                        count = count + 1
                    end
                end
            end
        end
        return count
    end

    function XChatManager.CheckCd()
        if LastChatCoolTime > 0 and LastChatCoolTime + CHAT_INTERVAL_TIME > XTime.GetServerNowTimestamp() then
            XUiManager.TipCode(XCode.ChatManagerRefreshTimeCooling)
            return false
        end

        return true
    end

    --发送聊天
    function XChatManager.SendChat(chatData, cb)
        XNetwork.Call(MethodName.SendChat, { ChatData = chatData, TargetIdList = chatData.TargetIds }, function(response)
            LastChatCoolTime = response.RefreshTime
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)

                if chatData.ChannelType == ChatChannelType.World then
                    if cb then
                        cb(CHAT_INTERVAL_TIME + LastChatCoolTime - XTime.GetServerNowTimestamp(), response.ChatData)
                    end
                end
                return
            end

            if cb then
                cb(CHAT_INTERVAL_TIME + LastChatCoolTime - XTime.GetServerNowTimestamp(), response.ChatData)
            end
            XDataCenter.ChatManager.CheckChat(chatData.Content)
        end)
    end
----------------------------------------重复聊天发言检测-----------------------------------
    local CheckChatTimer
    local CheckChatList = {}
    local CheckChatId = 1
    local WaitDelectChatList = {}
    local CheckContent = {}

    function XChatManager.CheckChat(content)
        if not content then return end
        --先检测是否是过滤内容
        local filters = XChatConfigs.GetRepeatChatForbidStringFilter()
        if filters then
            for _, filterStr in pairs(filters) do
                if content == filterStr then
                    return
                end
            end
        end
        --提取字符串中的英文+汉字
        local pureStr = XTool.GetPureStr(content)
        if not pureStr then return end
        local chatData = {
                Id = CheckChatId,
                Time = 0,
                Content = pureStr,
                RepeatCount = 0
            }

        CheckChatList[CheckChatId] = chatData
        CheckChatId = CheckChatId + 1
        CheckContent[pureStr] = true
        if not CheckChatTimer then XChatManager.StartCheckChatTimer() end        
    end
    
    function XChatManager.StartCheckChatTimer()
        CheckChatTimer = XScheduleManager.ScheduleForever(function()
                    --是否进行了检测(检查列表是否空列)
                    local haveCheck = false
                    for _, chat in pairs(CheckChatList) do
                        haveCheck = true
                        chat.Time = chat.Time + CSTime.deltaTime
                        if CheckContent[chat.Content] then
                            chat.RepeatCount = chat.RepeatCount + 1
                            if chat.RepeatCount >= XChatConfigs.GetRepeatChatForbidRepeatCount() then
                                XChatManager.CatchRepeatChat(chat.RepeatCount)
                            end
                        end
                        if chat.Time >= XChatConfigs.GetRepeatChatForbidCalculateTime() then
                            table.insert(WaitDelectChatList, chat.Id)
                        end
                    end
                    for _, delectChatId in pairs(WaitDelectChatList) do
                        if CheckChatList[delectChatId] then
                            CheckChatList[delectChatId] = nil
                        end
                    end
                    if not haveCheck then
                        XScheduleManager.UnSchedule(CheckChatTimer)
                        CheckChatTimer = nil
                        return
                    end
                    WaitDelectChatList = {}
                    CheckContent = {}
                end, 0)
    end
    
    function XChatManager.CatchRepeatChat(repeatCount)
        XNetwork.Call(MethodName.CatchRepeatChat, { Times = repeatCount }, function(response)
                if response.Code ~= XCode.Success then
                    local text = CS.XTextManager.GetCodeText(response.Code)
                    XLog.Error(text)
                    return
                end
                XLog.Debug("捕捉到10秒内的第" .. repeatCount .. "次重复发言！已发送成功！")
            end)
    end
    ----------------------------------------重复聊天发言检测 end-----------------------------------
    --收取单个礼物
    function XChatManager.GetGift(giftId, callback)
        callback = callback or function() end

        XNetwork.Call(MethodName.GetGift, { GiftId = giftId or 0 }, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
            callback(response.RewardGoodsList)
        end)
    end

    --群收礼物
    function XChatManager.GetAllGiftsRequest(callback)
        if not XChatManager.CheckHasGift() then
            XUiManager.TipError(CS.XTextManager.GetText("ChatManagerGetGiftNotGift"))
            return
        end
        XNetwork.Call(MethodName.GetAllGiftsRequest, nil, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
            if #response.RewardGoodsList <= 0 then
                XUiManager.TipError(CS.XTextManager.GetText("ChatManagerGetGiftNotGift"))
                return
            end
            if callback then
                callback(response.GiftInfoList, response.RewardGoodsList)
            end
        end)
    end

    -- 离线消息
    function XChatManager.GetOfflineMessageRequest(msgId, cb)
        XNetwork.Call(MethodName.GetOfflineMessageRequest, { MessageId = msgId }, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
            -- 处理离线的消息
            XChatManager.HandleOfflineMessage(response.Messages)
            if cb then
                cb()
            end
        end)
    end

    function XChatManager.HandleOfflineMessage(offlineMessages)
        if not offlineMessages then return end

        local lastChatData = nil
        local earliestChatTime = XMath.IntMax()
        for _, chatData in pairs(offlineMessages) do
            XChatManager.ProcessExtraContent(chatData)
            XChatManager.OnSynChat(chatData, true)
            if earliestChatTime < chatData.CreateTime then
                earliestChatTime = chatData.CreateTime
            end
            lastChatData = chatData
        end
        
        for _, type in ipairs(ChatChannelType) do
            if earliestChatTime < LastReadChatTime[type] then
                LastReadChatTime[type] = earliestChatTime
                local key = string.format("%s%d" ,XChatConfigs.KEY_LAST_READ_CHAT_TIME, type)
                XSaveTool.SaveData(key, LastReadChatTime[type])
            end
        end

        -- 只在最后检查一次红点
        if lastChatData then
            local data = XChatData.New(lastChatData)
            XEventManager.DispatchEvent(XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT, data)
        end
    end

    function XChatManager.UpdateLocalOfflineRecord(messageId)
        if messageId > MessageId then
            MessageId = messageId
            local key = string.format("%s%s", OfflineMessageTag, tostring(XPlayer.Id))
            CS.UnityEngine.PlayerPrefs.SetInt(key, MessageId)
            CS.UnityEngine.PlayerPrefs.Save()
        end

    end

    function XChatManager.GetLocalOfflineRecord()
        local key = string.format("%s%s", OfflineMessageTag, tostring(XPlayer.Id))
        if CS.UnityEngine.PlayerPrefs.HasKey(key) then
            MessageId = CS.UnityEngine.PlayerPrefs.GetInt(key, MessageId)
        end
        return MessageId
    end

    -- 【聊天分频道】
    function XChatManager.GetCurrentChatChannelId()
        return CurrentChatChannelId
    end

    -- 切换聊天频道
    function XChatManager.SelectChatChannel(channelId, succeedCb, failedCb)
        if channelId == CurrentChatChannelId then return end

        XNetwork.Call(MethodName.SelectChatChannelRequest, { ChannelId = channelId - 1 }, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                if failedCb then 
                    failedCb() 
                end
                return
            end
            CurrentChatChannelId = channelId
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_CHANNEL_CHANGED)
            if succeedCb then
                succeedCb()
            end
        end)
    end

    -- 登录初始化聊天频道
    function XChatManager.InitChatChannel()
        XNetwork.Call(MethodName.EnterWorldChatRequest, {}, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
            CurrentChatChannelId = response.ChannelId + 1
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_CHANNEL_CHANGED)
        end)
    end
    local RecruitChannelId = -1
    -- 获取频道消息
    function XChatManager.GetWorldChannelInfos(cb)
        XNetwork.Call(MethodName.GetWorldChannelInfoRequest, {}, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end

            ChatChannelInfos = response.ChannelInfos
            local lastIndex = #ChatChannelInfos
            for index, v in pairs(ChatChannelInfos) do
                v.ChannelId = v.ChannelId + 1
                if index == lastIndex then v.IsRecruitChannel = true end
            end
            --收到市网信办举报特殊处理 频道5移除，所有后续频道顺延显示 + 1
            RecruitChannelId = lastIndex + 1
            if cb then
                cb(ChatChannelInfos)
            end
        end)
    end
    
    function XChatManager.GetRecruitChannelId()
        return RecruitChannelId
    end

    function XChatManager.GetAllChannelInfos()
        return ChatChannelInfos
    end

    function XChatManager.OnChatChannelChanged(notifyData)
        if not notifyData then return end
        local notifyChannelId = notifyData.ChannelId + 1
        if CurrentChatChannelId ~= notifyChannelId then
            CurrentChatChannelId = notifyChannelId
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_SERVER_CHANNEL_CHANGED, notifyChannelId)
        end
    end

    function XChatManager.UpdateGiftResetTime(resetTime)
        TodayResetTime = resetTime
    end

    function XChatManager.CheckHasGift()
        for _, chatInfo in pairs(PrivateChatMap) do
            for _, chat in pairs(chatInfo.ChatMap) do
                if chat.MsgType == ChatMsgType.Gift and chat.GiftStatus == ChatGiftState.WaitReceive and chat.SenderId ~= XPlayer.Id then
                    return true
                end
            end
        end

        return false
    end

    function XChatManager.UpdateGiftStatus()
        for _, chatInfo in pairs(PrivateChatMap) do
            for _, chat in pairs(chatInfo.ChatMap) do
                if TodayResetTime > 0
                and chat.MsgType == ChatMsgType.Gift
                and chat.GiftStatus == ChatGiftState.WaitReceive
                and chat.CreateTime < (TodayResetTime - ONE_DAY_SECONDS) then
                    chat.GiftStatus = ChatGiftState.Fetched
                end
            end
        end
    end

    -- 创建礼物文本
    function XChatManager.CreateGiftTips(chatData)
        if not chatData then
            return ""
        end

        -- 发礼物提示
        if chatData.GiftStatus == ChatGiftState.WaitReceive then
            if chatData.SenderId == XPlayer.Id then
                local friend = XDataCenter.SocialManager.GetFriendInfo(chatData.TargetId)
                if friend then
                    local name = XDataCenter.SocialManager.GetPlayerRemark(chatData.TargetId, chatData.NickName)
                    return CS.XTextManager.GetText("GiftMoneySendNotReceive", name, chatData.GiftCount)
                end
            else
                local name = XDataCenter.SocialManager.GetPlayerRemark(chatData.SenderId, chatData.NickName)
                return CS.XTextManager.GetText("GiftMoneyReceiveNotReceive", name, chatData.GiftCount)
            end
            -- 领礼物提示
        elseif chatData.GiftStatus == ChatGiftState.Received then
            -- 自己领礼物
            if chatData.SenderId ~= XPlayer.Id then
                local friend = XDataCenter.SocialManager.GetFriendInfo(chatData.SenderId)
                local name = XDataCenter.SocialManager.GetPlayerRemark(chatData.SenderId, chatData.NickName)
                if friend then
                    return CS.XTextManager.GetText("GiftMoneyReceiveHaveReceive", name, chatData.GiftCount)
                else
                    return CS.XTextManager.GetText("GiftMoneyReceiveHaveReceive", "", chatData.GiftCount)
                end
            else
                -- 别人领礼物
                local friend = XDataCenter.SocialManager.GetFriendInfo(chatData.TargetId)
                local name = XDataCenter.SocialManager.GetPlayerRemark(chatData.TargetId, chatData.NickName)
                if friend then
                    return CS.XTextManager.GetText("GiftMoneySendHaveReceive", name, chatData.GiftCount)
                end
            end
        end
        return ""
    end

    -- 检查是否有新的表情包
    function XChatManager.CheckIsNewEmoji()
        local isRed = nil
        local allPacks = XChatManager.GetAllEmojiPacksWithAutoSort()
        for k, v in pairs(allPacks) do
            for k2, v2 in pairs(v:GetEmojiList()) do
                if v2:GetIsNew() then
                    isRed = true
                    break
                end            
            end
        end
        return isRed
    end

    function XChatManager.ProcessExtraContent(chatData)
        if not chatData then
            return
        end

        local customContent = XMessagePack.Decode(chatData.CustomContent)
        if not customContent then
            return
        end

        if string.find(chatData.Content, "room") then
            chatData.Content = string.gsub(chatData.Content, "room", customContent)
        end
    end

    function XChatManager.NotifyChatMessage(chatData)
        XChatManager.ProcessExtraContent(chatData)
        XChatManager.OnSynChat(chatData)

        XEventManager.DispatchEvent(XEventId.EVENT_CHAT_MSG_SYNC)
    end

    function XChatManager.NotifyPrivateChat(chatData)
        if not chatData or not chatData.ChatMessages then
            return
        end

        if XDataCenter.SocialManager.GetBlackData(chatData.SenderId) then
            return
        end

        local lastChatMsg
        for _, chatMsg in ipairs(chatData.ChatMessages) do
            lastChatMsg = XChatData.New(chatMsg)
            XChatManager.ProcessExtraContent(chatMsg)
            XChatManager.OnSynChat(chatMsg, true)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_CHAT_MSG_SYNC)

        if lastChatMsg then
            XEventManager.DispatchEvent(XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT, lastChatMsg)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT, lastChatMsg)
        end
    end

    function XChatManager.NotifyWorldChat(chatData)
        if not chatData or not chatData.ChatMessages then
            return
        end
        local lastChatMsg
        for _, chatMsg in ipairs(chatData.ChatMessages) do
            if not XDataCenter.SocialManager.GetBlackData(chatMsg.SenderId) then
                XChatManager.ProcessExtraContent(chatMsg)
                lastChatMsg = XChatData.New(chatMsg)
                HandleWorldChat(lastChatMsg)
            end
        end

        if lastChatMsg then
            XEventManager.DispatchEvent(XEventId.EVENT_CHAT_RECEIVE_WORLD_MSG, lastChatMsg)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_RECEIVE_WORLD_MSG, lastChatMsg)
        end
    end

    function XChatManager.NotifyMentorChat(chatData)
        if not chatData or not chatData.ChatMessages then
            return
        end
        local lastChatMsg
        for _, chatMsg in ipairs(chatData.ChatMessages) do
            XChatManager.ProcessExtraContent(chatMsg)
            lastChatMsg = XChatData.New(chatMsg)
            HandleMentorChat(lastChatMsg)
        end

        if lastChatMsg then
            XEventManager.DispatchEvent(XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG, lastChatMsg)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG, lastChatMsg)
        end
    end

    function XChatManager.NotifyChatEmoji(emojiData)
        if not emojiData.Emoji then
            return
        end

        EmojiDatasDic[emojiData.Emoji.Id] = XChatEmoji.New(emojiData.Emoji)
    end

    function XChatManager.NotifyChatLoginData(loginData)
        TodayResetTime = loginData.RefreshTime

        for __, v in pairs(loginData.UnlockEmojis) do
            EmojiDatasDic[v.Id] = XChatEmoji.New(v)
        end
    end

    XChatManager.Init()
    return XChatManager
end

--同步聊天
XRpc.NotifyChatMessage = function(chatData)
    XDataCenter.ChatManager.NotifyChatMessage(chatData)
end

XRpc.NotifyPrivateChat = function(chatData)
    XDataCenter.ChatManager.NotifyPrivateChat(chatData)
end

XRpc.NotifyTodayGiftResetTime = function(notifyData)
    XDataCenter.ChatManager.UpdateGiftResetTime(notifyData.ResetTime)
end

XRpc.NotifyWorldChat = function(chatData)
    XDataCenter.ChatManager.NotifyWorldChat(chatData)
end

XRpc.NotifyMentorChat = function(chatData)
    XDataCenter.ChatManager.NotifyMentorChat(chatData)
end

-- 聊天频道切换
XRpc.NotifyChatChannelChange = function(notifyData)
    XDataCenter.ChatManager.OnChatChannelChanged(notifyData)
end

XRpc.NotifyChatLoginData = function(loginData)
    XDataCenter.ChatManager.NotifyChatLoginData(loginData)
end

XRpc.NotifyChatEmoji = function(emojiData)
    XDataCenter.ChatManager.NotifyChatEmoji(emojiData)
end