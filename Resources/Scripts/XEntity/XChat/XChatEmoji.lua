XChatEmoji = XClass(nil, "XChatEmoji")

function XChatEmoji:Ctor(data)
    self:InitChatEmoji(data)
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