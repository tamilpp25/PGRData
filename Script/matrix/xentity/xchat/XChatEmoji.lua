XChatEmoji = XClass(nil, "XChatEmoji")

function XChatEmoji:Ctor(data)
    self:InitChatEmoji(data)
    XDataCenter.ChatManager.RegisterEmoji(self)
    XEventManager.DispatchEvent(XEventId.EVENT_CHAT_EMOJI_REFRESH_RED)
end

function XChatEmoji:InitChatEmoji(data)
    self.Id = data.Id or 0
    self.EndTime = data.EndTime or 0
end

function XChatEmoji:GetEmojiId()
    return self.Id
end

function XChatEmoji:GetEmojiEndTime()
    return self.EndTime
end

function XChatEmoji:IsLimitEmoji()
    return self.EndTime > 0
end

function XChatEmoji:IsEmojiValid(emojiId)
    return self.Id == emojiId
end

function XChatEmoji:GetEmojiOrder()
    return XChatConfigs.GetEmojiConfigById(self.Id).Order
end

function XChatEmoji:GetEmojiIcon()
    return XChatConfigs.GetEmojiIcon(self.Id)
end

function XChatEmoji:GetPackId()
    return XChatConfigs.GetEmojiPackId(self.Id)
end

-- 判断是不是刚刚获得的，通过本地缓存记录
function XChatEmoji:GetIsNew()
    local key = self.Id.."EmojiId"
    local isRed = XSaveTool.GetData(key) == nil
    return isRed
end

-- 判断是不是刚刚活动的，通过本地缓存记录
function XChatEmoji:SetNotNew()
    local key = self.Id.."EmojiId"
    XSaveTool.SaveData(key, 1)
end