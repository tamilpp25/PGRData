--==============
--聊天表情包管理器
--模块负责：吕天元
--==============
local XChatEmojiPackManager = {}
--==========
--表情包Id -> 表情包字典
--Key : EmojiPack表的Id
--Value : 表情包对象
--==========
local PackDicById --Key : PackId , Value : XPack
--==========
--全部表情包列表
--==========
local AllPacks
--==========
--所有有时限的表情列表
--==========
local TimeLimitEmojis
--==========
--表情包列表排序标记
--true表示已排序 false表示需要排序
--==========
local PackSortFlag
--==========
--表情包对象类
--==========
local XPack
--==========
--自定义排序
--==========
local GetCustomOrderFlag
--==========
--协议名
--==========
local METHOD_NAME = {
    GetOrder = "GetEmojiPackageIdRequest", --获取表情包排序
    SaveOrder = "SaveEmojiPackageIdRequest" --保存表情包排序
}
--==========
--初始化
--==========
function XChatEmojiPackManager.Init(chatManager)
    AllPacks = {}
    PackDicById = {}
    TimeLimitEmojis = {}
    PackSortFlag = false
    GetCustomOrderFlag = false
    XPack = require("XEntity/XChat/XChatEmojiPack")
end

function XChatEmojiPackManager.CreatePackById(packId)
    if PackDicById[packId] then return PackDicById[packId] end
    local newPack = XPack.New(packId)
    PackDicById[packId] = newPack
    table.insert(AllPacks, newPack)
    PackSortFlag = false
end

function XChatEmojiPackManager.GetEmojiPackById(packId)
    if not packId or (packId == 0) then --缺省或0表示默认表情包
        packId = 0
    end
    if not PackDicById[packId] then
        XChatEmojiPackManager.CreatePackById(packId)
    end
    return PackDicById[packId]
end

function XChatEmojiPackManager.RegisterEmoji(emoji)
    local pack = XChatEmojiPackManager.GetEmojiPackById(emoji:GetPackId())
    pack:AddEmoji(emoji)
    if emoji:IsLimitEmoji() then
        table.insert(TimeLimitEmojis, emoji)
    end
end

function XChatEmojiPackManager.CheckTimeLimitEmoji()
    local timeNow = XTime.GetServerNowTimestamp()
    local removeIndex = {}
    for index, emoji in pairs(TimeLimitEmojis) do
        if emoji:GetEmojiEndTime() <= timeNow then
            local packId = emoji:GetPackId()
            local pack = XChatEmojiPackManager.GetEmojiPackById(packId)
            if pack then
                pack:RemoveEmoji(emoji)
                table.insert(removeIndex, 1, index)
            end
        end
    end
    for _, index in pairs(removeIndex) do
        table.remove(TimeLimitEmojis, index)
    end
end

function XChatEmojiPackManager.GetAllEmojiPacksWithAutoSort()
    XChatEmojiPackManager.CheckTimeLimitEmoji()
    if not PackSortFlag then
        table.sort(AllPacks, function(emojiPackA, emojiPackB)
                local orderA = emojiPackA:GetOrder()
                if orderA == 0 then
                    return true
                end
                local orderB = emojiPackB:GetOrder()
                if orderB == 0 then
                    return false
                end
                return emojiPackA:GetOrder() < emojiPackB:GetOrder()
            end)
        PackSortFlag = true
    end
    return AllPacks
end

function XChatEmojiPackManager.GetAllEmojiPacksWithOutDefault()
    local allPacks = XChatEmojiPackManager.GetAllEmojiPacksWithAutoSort()
    --去除默认表情包
    local result = {}
    for _, pack in pairs(allPacks) do
        if pack:GetOrder() > 0 then
            table.insert(result, pack)
        end
    end
    return result
end

function XChatEmojiPackManager.SetCustomPackOrder(orderList)
    for order, packId in pairs(orderList or {}) do
        local pack = XChatEmojiPackManager.GetEmojiPackById(packId)
        if pack then
            pack:SetCustomOrder(order)
            PackSortFlag = false
        end
    end
end

function XChatEmojiPackManager.GetEmojiPackOrder(cb)
    if GetCustomOrderFlag then
        if cb then
            cb()
        end
        return
    end
    XNetwork.Call(METHOD_NAME.GetOrder, { }, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
            XChatEmojiPackManager.SetCustomPackOrder(response.OrderEmojiPackageIds)
            if cb then
                cb()
            end
            GetCustomOrderFlag = true
        end)
end

function XChatEmojiPackManager.SaveEmojiPackOrder(packIdList, cb)
    XNetwork.Call(METHOD_NAME.SaveOrder, { OrderEmojiPackageIds = packIdList }, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
            if cb then
                cb()
            end
        end)
end

function XChatEmojiPackManager.DestroyPack(pack)
    local packId = pack:GetId()
    if PackDicById[packId] then
        PackDicById[packId] = nil
    end
    local removeIndex = 0
    for index, pack in pairs(AllPacks) do
        if pack:GetId() == packId then
            removeIndex = index
            break
        end
    end
    if removeIndex > 0 then
        table.remove(AllPacks, removeIndex)
    end
    --表情包出现修改，需要重新排序
    PackSortFlag = false
end

return XChatEmojiPackManager