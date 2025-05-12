local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")
local CHAT_TYPE = XTemple2Enum.CHAT_TYPE

---@class XTemple2Chat
local XTemple2Chat = XClass(nil, "XTemple2Chat")

--[[
    游戏界面的右下角，角色会自动说话：
        1。每段对话的触发时间为5秒
        2。当遇到以下事件时，触发事件文本，同5秒，顺序通过配置控制：
            1.寻路失败时；
            2.放置地块失败时；
            3.如果放下一个地块后，获得超过一定分数的时候；
        3.编辑阶段显示对应地块的desc文本
        4.常驻文本轮询播放:
            4.地图得分超过一定分数后；
            5.当玩家持有舞台地块，未使用时；
            6.当地图存在任务地块(801,901), 播放不同文本;
            7.当存在喜好的地块，但未放置时，不同npc的不一样；
        5.平时不说话
--]]
function XTemple2Chat:Ctor()
    ---@type XTemple2ChatData[]
    self._ChatQueue = {}

    ---@type XTemple2ChatData[]
    self._ChatFromEvent = {}

    ---@type XTemple2ChatData
    self._CurrentChat = false

    self._Time = 0
    self._TimeDuration = 5

    self._IsInit = false
end

function XTemple2Chat:_CreateChat(config)
    ---@class XTemple2ChatData
    local chat = {
        Id = config.Id,
        Type = config.Type,
        Duration = config.Duration,
        NpcId = config.NpcId,
        Params = config.Params,
        Text = config.Text,
        IsActive = true
    }
    return chat
end

---@param model XTemple2Model
---@param game XTemple2Game
function XTemple2Chat:Init(model, game)
    self:Clear()
    self._IsInit = true
    local npcId = game:GetNpcId()

    ---@type XTable.XTableTemple2Chat[]
    local allChat = model:GetAllChat()
    for id, chatConfig in pairs(allChat) do
        if chatConfig.NpcId == 0 or chatConfig.NpcId == npcId then
            -- 这些是靠事件触发的
            if chatConfig.Type == CHAT_TYPE.PATH_FAIL
                    or chatConfig.Type == CHAT_TYPE.PUT_DOWN_BLOCK_FAIL
                    or chatConfig.Type == CHAT_TYPE.PUT_DOWN_BLOCK_AND_SCORE
            then
                self._ChatFromEvent[chatConfig.Type] = self:_CreateChat(chatConfig)

                -- 这些是常驻轮询的
            elseif chatConfig.Type == CHAT_TYPE.ANY_BLOCK_UNUSED then
                local blockName = chatConfig.Params[1]
                if game:FindBlock(blockName) then
                    self._ChatQueue[#self._ChatQueue + 1] = self:_CreateChat(chatConfig)
                end

            elseif chatConfig.Type == CHAT_TYPE.ANY_BLOCK_WITH_RULE
                    or chatConfig.Type == CHAT_TYPE.FAVOURITE_BLOCK_UNUSED
                    or chatConfig.Type == CHAT_TYPE.GAME_SCORE
            then
                self._ChatQueue[#self._ChatQueue + 1] = self:_CreateChat(chatConfig)

            elseif chatConfig.Type == CHAT_TYPE.RULE then
                local ruleId = tonumber(chatConfig.Params[1])
                if game:IsRuleExist(ruleId) then
                    self._ChatQueue[#self._ChatQueue + 1] = self:_CreateChat(chatConfig)

                end
            end
        end
    end
    
    self:SortChatList()
end

---@param game XTemple2Game
function XTemple2Chat:CheckCondition(game)
    for i = #self._ChatQueue, 1, -1 do
        local chat = self._ChatQueue[i]
        -- 5.当玩家持有舞台地块，未使用时；
        if chat.Type == CHAT_TYPE.ANY_BLOCK_UNUSED then
            local isUsed = false
            local blockName = chat.Params[1]
            if game:FindBlock(blockName) then
                local operations = game:GetOperations()
                for j = 1, #operations do
                    local operation = operations[j]
                    local blockId = operation.BlockId
                    local block = game:GetBlock(blockId)
                    if block:GetName() == blockName then
                        isUsed = true
                        break
                    end
                end
                if not isUsed then
                    chat.IsActive = true
                else
                    chat.IsActive = false
                end
            end

            --6.当地图存在任务地块(801,901), 播放不同文本;
        elseif chat.Type == CHAT_TYPE.ANY_BLOCK_WITH_RULE then
            local isExist = false
            local params = chat.Params
            for i = 1, #params do
                local ruleId = tonumber(params[i])
                if game:IsRuleExist(ruleId) then
                    isExist = true
                    break
                end
            end
            if isExist then
                chat.IsActive = true
            else
                chat.IsActive = false
            end

            --7.当存在喜好的地块，但未放置时，不同npc的不一样；
        elseif chat.Type == CHAT_TYPE.FAVOURITE_BLOCK_UNUSED then
            local block = game:GetOneFavouriteBlock()
            if block then
                local favouriteBlock = game:GetFavouriteGrid()
                if not favouriteBlock then
                    chat.IsActive = true
                else
                    chat.IsActive = false
                end
            else
                chat.IsActive = false
            end

            --4.地图得分超过一定分数后；
        elseif chat.Type == CHAT_TYPE.GAME_SCORE then
            local score = game:GetScore(XTemple2Enum.SCORE_TYPE.TOTAL_SCORE)
            local needScore = tonumber(chat.Params[1])
            if score >= needScore then
                chat.IsActive = true
            else
                chat.IsActive = false
            end
        end
    end
end

function XTemple2Chat:SetChat(chat)
    self._CurrentChat = chat
    self._Time = 0
end

function XTemple2Chat:CheckEvent(eventId, params1, params2)
    local chat = self._ChatFromEvent[eventId]
    if chat then
        -- 3.如果放下一个地块后，该地块获得超过一定分数；
        if eventId == CHAT_TYPE.PUT_DOWN_BLOCK_AND_SCORE then
            local needScore = tonumber(chat.Params[1])
            if needScore <= params1 then
                self:SetChat(chat)
            end

            --    --4.地图得分超过一定分数后；
            --elseif eventId == CHAT_TYPE.GAME_SCORE then
            --    local needScore = tonumber(chat.Params[1])
            --    local currentScore = params1
            --    local lastScore = params2
            --    if needScore <= currentScore and needScore > lastScore then
            --        self:SetChat(chat)
            --    end
            --else
            self:SetChat(chat)
        end
    end
end

function XTemple2Chat:Update()
    if self._CurrentChat then
        local deltaTime = CS.UnityEngine.Time.deltaTime
        self._Time = self._Time + deltaTime
        if self._Time > self._CurrentChat.Duration then
            self:Next()
            return
        end
    else
        self:Next()
    end
end

function XTemple2Chat:GetChat()
    local currentChat = self._CurrentChat
    if currentChat then
        return currentChat.Text
    end
    return false
end

function XTemple2Chat:Next()
    if #self._ChatQueue == 0 then
        self:SetChat(false)
        return
    end
    local chat
    for i = 1, #self._ChatQueue do
        if self._ChatQueue[i].IsActive then
            chat = table.remove(self._ChatQueue, i)
            break
        end
    end
    if chat then
        self._ChatQueue[#self._ChatQueue + 1] = chat
        self:SetChat(chat)
    else
        self:SetChat(false)
    end
end

function XTemple2Chat:SortChatList()
    table.sort(self._ChatQueue, function(a, b)
        return a.Id < b.Id
    end)
end

function XTemple2Chat:Clear()
    if self._IsInit then
        self._ChatQueue = {}
        self._ChatFromEvent = {}
        self._CurrentChat = false
        self._Time = 0
        self._IsInit = false
    end
end

return XTemple2Chat