--============
--表情包对象
--============
local XChatEmojiPack = XClass(nil, "XChatEmojiPack")

function XChatEmojiPack:Ctor(packId)
    self.Id = packId
    self.EmojiList = {}
    self.EmojiIdDic = {} --表情Id字典
end

function XChatEmojiPack:GetCfg()
    return XChatConfigs.GetEmojiPackCfgById(self:GetId())
end

function XChatEmojiPack:GetId()
    return self.Id or 0
end

function XChatEmojiPack:GetOrder()
    if self.CustomOrder then return self.CustomOrder end
    local cfg = self:GetCfg()
    return cfg and cfg.Order or 0
end

function XChatEmojiPack:SetCustomOrder(order)
    self.CustomOrder = order
end

function XChatEmojiPack:GetName()
    local cfg = self:GetCfg()
    return cfg and cfg.Name or "UnNamed"
end

function XChatEmojiPack:GetDescription()
    local cfg = self:GetCfg()
    return cfg and cfg.Description or "NoText"
end

function XChatEmojiPack:GetIcon()
    local cfg = self:GetCfg()
    return cfg and cfg.Icon
end

function XChatEmojiPack:GetPath()
    local cfg = self:GetCfg()
    return cfg and cfg.Path
end

function XChatEmojiPack:AddEmoji(emoji)
    if not emoji then return end
    local id = emoji:GetEmojiId()
    if self.EmojiIdDic[id] then return end --已经追加过的表情不追加
    table.insert(self.EmojiList, emoji)
    self.EmojiIdDic[id] = true
    self.EmojiSortFlag = false --新增表情后已排序标记变为未排序
end

function XChatEmojiPack:RemoveEmoji(emojiObj)
    if not emojiObj then return end
    local id = emojiObj:GetEmojiId()
    if not self.EmojiIdDic[id] then return end
    self.EmojiIdDic[id] = nil
    local removeIndex = 0
    for index, emoji in pairs(self.EmojiList) do
        if emoji:GetEmojiId() == id then
            removeIndex = index
            break
        end
    end
    if removeIndex > 0 then
        table.remove(self.EmojiList, removeIndex)
    end
    self:CheckEmpty()
end

function XChatEmojiPack:CheckEmpty()
    if (not self.EmojiList) or (not next(self.EmojiIdDic)) then
        XDataCenter.ChatManager.DestroyPack(self)
    end
end

function XChatEmojiPack:GetEmojiList()
    if not self.EmojiSortFlag then --若标记为未排序，则排序
        table.sort(self.EmojiList, function(emojiA, emojiB)
                return emojiA:GetEmojiOrder() < emojiB:GetEmojiOrder()
            end)
        self.EmojiSortFlag = true
    end
    return self.EmojiList
end

return XChatEmojiPack