---@class XSGGameMascot 建组数据
local XSGGameMascot = XClass(nil, "XSGGameMascot")

function XSGGameMascot:Ctor()
end

function XSGGameMascot:InitByConfig(groupId, groupId2, mascotConfig)
    self._MessagesInfo = {}
    self._LikeMessagesInfo = {}
    self._RepeatId = {}
    self._LikeRepeatId = {}
    for _, messageConfig in pairs(mascotConfig) do
        if groupId == messageConfig.GroupId then
            table.insert(self._MessagesInfo, messageConfig)
        end
        if groupId2 == messageConfig.GroupId then
            table.insert(self._LikeMessagesInfo, messageConfig)
        end
    end
end

-- 检查是否有满足条件的消息
function XSGGameMascot:GetPassConditionMessageList(messageList)
    local passConditionMessageList = {}
    for _, messageConfig in pairs(messageList) do
        local conditionId = messageConfig.Condition or 0
        if conditionId == 0 or XMVCA.XBigWorldService:CheckCondition(conditionId) then
            table.insert(passConditionMessageList, messageConfig)
        end
    end
    return passConditionMessageList
end

-- 获取开始随机消息
function XSGGameMascot:GetRandomMessageConfig(messageList, repeatList)
    local count = #messageList
    if count <= 0 then return end

    local messageCfgs = self:GetPassConditionMessageList(messageList)
    local weights = {}
    for _, messageConfig in ipairs(messageCfgs) do
        if repeatList[messageConfig.Id] then
            table.insert(weights, messageConfig.RepeatWeigh)
        else
            table.insert(weights, messageConfig.Weigh)
        end
    end
    if #weights <= 0 then return end
    local weightIdx = XMath.RandByWeights(weights)
    return messageCfgs[weightIdx]
end

-- 获取开始随机消息
function XSGGameMascot:GetStartRandomMessage()
    local messageCfg = self:GetRandomMessageConfig(self._MessagesInfo, self._RepeatId)
    if not messageCfg then return "..." end

    self._RepeatId[messageCfg.Id] = true
    return messageCfg.Desc
end

-- 检测喜好变更状态
function XSGGameMascot:AddLikeMessageTag()
    self._LikeMessageTag = true
end

function XSGGameMascot:HasLikeMessageTag()
    return self._LikeMessageTag
end

-- 获取喜好消息
function XSGGameMascot:GetLikeRandomMessage()
    local messageCfg = self:GetRandomMessageConfig(self._LikeMessagesInfo, self._LikeRepeatId)
    if not messageCfg then return "..." end

    self._LikeRepeatId[messageCfg.Id] = true
    self._LikeMessageTag = false
    return messageCfg.Desc
end

-- 获取点击随机消息
function XSGGameMascot:GetRandomMessage()
    return self:GetStartRandomMessage()
end

return XSGGameMascot
