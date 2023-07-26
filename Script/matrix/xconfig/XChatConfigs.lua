local tableInsert = table.insert
local tableSort = table.sort

XChatConfigs = XChatConfigs or {}

local TABLE_EMOJI_CONFIG_PATH = "Share/Chat/Emoji.tab"
local TABLE_EMOJI_PACK_PATH = "Share/Chat/EmojiPack.tab"
local TABLE_EFFECT_CONFIG_PATH = "Client/Chat/KeywordEffect.tab"
local TABLE_REPEAT_CHAT_FORBID_PATH = "Client/Chat/RepeatChatForbid.tab"

local EmojiTemplates = {}
local EmojiPackTemplates = {}
local EffectTemplates = {}
local RepeatChatForbidCfg = {}
XChatConfigs.KEY_LAST_READ_CHAT_TIME = "KEY_LAST_READ_CHAT_TIME_"

function XChatConfigs:Init()
    EmojiTemplates = XTableManager.ReadByIntKey(TABLE_EMOJI_CONFIG_PATH, XTable.XTableEmoji, "Id")
    EmojiPackTemplates = XTableManager.ReadByIntKey(TABLE_EMOJI_PACK_PATH, XTable.XTableEmojiPack, "Id")
    EffectTemplates = XTableManager.ReadByIntKey(TABLE_EFFECT_CONFIG_PATH, XTable.XTableChatEffect, "Id")
    RepeatChatForbidCfg = XTableManager.ReadByIntKey(TABLE_REPEAT_CHAT_FORBID_PATH, XTable.XTableRepeatChatForbid, "Id")
end

--这里这里用于传出完整配置条目，外部谨允许局部域生命周期内使用，不允许持有！！！！
function XChatConfigs.GetEmojiConfigById(emojiId)
    if not EmojiTemplates[emojiId] then
        XLog.Error("没有找到相关配置，请检查配置表：>>>>", TABLE_EMOJI_CONFIG_PATH)
        return {}
    end
    return EmojiTemplates[emojiId]
end

function XChatConfigs.GetEmojiIcon(emojiId)
    emojiId = tonumber(emojiId)
    emojiId = emojiId or 0
    local cfg = EmojiTemplates[emojiId]
    if cfg == nil then
        return nil
    end
    return cfg.Path
end

function XChatConfigs.GetEmojiQuality()
    return 1
end

function XChatConfigs.GetEmojiName(emojiId)
    if not EmojiTemplates[emojiId] then
        return ""
    end

    return EmojiTemplates[emojiId].Name
end

function XChatConfigs.GetEmojiDescription(emojiId)
    if not EmojiTemplates[emojiId] then
        return ""
    end

    return EmojiTemplates[emojiId].Description
end

function XChatConfigs.GetEmojiWorldDesc(emojiId)
    if not EmojiTemplates[emojiId] then
        return ""
    end

    return EmojiTemplates[emojiId].WorldDesc
end

function XChatConfigs.GetEmojiBigIcon(emojiId)
    if not EmojiTemplates[emojiId] then
        return ""
    end

    return EmojiTemplates[emojiId].BigIcon
end

function XChatConfigs.GetEmojiPackId(emojiId)
    if not EmojiTemplates[emojiId] then
        return 0
    end

    return EmojiTemplates[emojiId].PackageId or 0
end

function XChatConfigs.GetEffectTemplates()
    return EffectTemplates
end

function XChatConfigs.GetRepeatChatForbidCalculateTime()
    return RepeatChatForbidCfg[1].CalculateTime
end

function XChatConfigs.GetRepeatChatForbidRepeatCount()
    return RepeatChatForbidCfg[1].RepeatCount
end

function XChatConfigs.GetRepeatChatForbidStringFilter()
    return RepeatChatForbidCfg[1].StringFilter or {}
end

function XChatConfigs.GetEmojiPackConfigs()
    return EmojiPackTemplates
end

function XChatConfigs.GetEmojiPackCfgById(packId, noTips)
    local cfg = EmojiPackTemplates[packId]
    if not cfg then
        if not noTips then
            XLog.ErrorTableDataNotFound(
                "GetEmojiPackCfgById",
                "表情包",
                TABLE_EMOJI_PACK_PATH,
                "Id",
                tostring(packId)
            )
        end
        return nil
    end
    return EmojiPackTemplates[packId]
end