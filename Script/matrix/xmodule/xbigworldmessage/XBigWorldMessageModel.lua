local XBigWorldMessageConfigModel = require("XModule/XBigWorldMessage/XBigWorldMessageConfigModel")
local XBWMessageData = require("XModule/XBigWorldMessage/XData/XBWMessageData")

---@class XBigWorldMessageModel : XBigWorldMessageConfigModel
local XBigWorldMessageModel = XClass(XBigWorldMessageConfigModel, "XBigWorldMessageModel")

function XBigWorldMessageModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    ---@type XBWMessageData[]
    self._UnReadMessageList = {}
    ---@type table<number, XBWMessageData>
    self._MessageMap = {}

    ---@type XQueue
    self._ForceMessageQueue = XQueue.New()

    self:_InitTableKey()
end

function XBigWorldMessageModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldMessageModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

---@type XBWMessageData[]
function XBigWorldMessageModel:GetUnReadMessageList()
    return self._UnReadMessageList
end

---@type table<number, XBWMessageData>
function XBigWorldMessageModel:GetMessageMap()
    return self._MessageMap
end

function XBigWorldMessageModel:CheckMessageStepFinish(messageId, stepId)
    if self._MessageMap[messageId] then
        return self._MessageMap[messageId].StepIdMap[stepId]
    end

    return false
end

function XBigWorldMessageModel:CheckMessageStepIdEnd(stepId)
    local nextStepIds = self:GetBigWorldMessageStepNextStepById(stepId)

    return XTool.IsTableEmpty(nextStepIds)
end

function XBigWorldMessageModel:CheckFirstStepId(messageId, stepId)
    local firstStepId = self:GetBigWorldMessageFirstStepIdById(messageId)

    return stepId == firstStepId
end

function XBigWorldMessageModel:CheckMessageFinish(messageId)
    if self._MessageMap[messageId] then
        return self._MessageMap[messageId].State == XEnumConst.BWMessage.MessageState.Finish
    end

    return false
end

function XBigWorldMessageModel:AddReadMessageStep(messageId, stepId, isFinish)
    if self._MessageMap[messageId] then
        self._MessageMap[messageId]:AddStepId(stepId)
        self._MessageMap[messageId]:UpdateFinishState(isFinish)
    end
    if isFinish then
        for i, messageData in pairs(self._UnReadMessageList) do
            if messageData.MessageId == messageId then
                table.remove(self._UnReadMessageList, i)
                return
            end
        end
    end
end

function XBigWorldMessageModel:AddUnReadMessage(data)
    ---@type XBWMessageData
    local messageData = XBWMessageData.New(data)

    messageData:UpdateCreateTime()
    if not self:CheckFirstStepId(data.MessageId, data.StepId) then
        messageData:AddStepId(data.StepId)
    end

    if not self._MessageMap[messageData.MessageId] then
        table.insert(self._UnReadMessageList, messageData)
        self._MessageMap[messageData.MessageId] = messageData
    else
        XLog.Error("[短信][NotifyBigWorldNotReadMessage] : " .. "Repeat Notify Message => MessageId = "
                       .. messageData.MessageId)
    end
end

function XBigWorldMessageModel:AddForceMessage(data)
    ---@type XBWMessageData
    local messageData = XBWMessageData.New(data)

    messageData:UpdateCreateTime()
    if not self:CheckFirstStepId(data.MessageId, data.StepId) then
        messageData:AddStepId(data.StepId)
    end

    if not self._MessageMap[messageData.MessageId] then
        self._ForceMessageQueue:Enqueue(messageData)
        self._MessageMap[messageData.MessageId] = messageData
        table.insert(self._UnReadMessageList, messageData)
    else
        XLog.Error("[短信][NotifyBigWorldNotReadMessage] : " .. "Repeat Notify Message => MessageId = "
                       .. messageData.MessageId)
    end
end

function XBigWorldMessageModel:UpdateMessageData(messageId, stepId, isFinish)
    if not self._MessageMap[messageId] then
        self._MessageMap[messageId] = XBWMessageData.New({
            MessageId = messageId,
            CreateTime = XTime.GetServerNowTimestamp(),
        })
    end

    self._MessageMap[messageId]:UpdateFinishState(isFinish)
    self._MessageMap[messageId]:AddStepId(stepId)
end

function XBigWorldMessageModel:UpdateAllMessageData(messages)
    self._MessageMap = {}
    self._UnReadMessageList = {}
    self._ForceMessageQueue:Clear()

    if not XTool.IsTableEmpty(messages) then
        for messageId, message in pairs(messages) do
            if not self._MessageMap[messageId] then
                local stepIdList = message.StepIdList

                if not XTool.IsTableEmpty(stepIdList) then
                    local completeStepIds = {}
                    local firstStepId = self:GetBigWorldMessageFirstStepIdById(messageId)
                    ---@type XStack
                    local resultStack = XStack.New()

                    for _, stepId in pairs(stepIdList) do
                        resultStack:Clear()
                        _, firstStepId = self:__PopulateCompleteStepIdList(firstStepId, stepId, resultStack)

                        if not resultStack:IsEmpty() then
                            while not resultStack:IsEmpty() do
                                table.insert(completeStepIds, resultStack:Pop())
                            end
                        end
                        if not firstStepId then
                            break
                        end
                    end

                    table.insert(completeStepIds, firstStepId)
                    message.StepIdList = completeStepIds
                end

                ---@type XBWMessageData
                local messageData = XBWMessageData.New(message)

                self._MessageMap[messageId] = messageData

                if messageData.State ~= XEnumConst.BWMessage.MessageState.Finish then
                    local messageType = self:GetBigWorldMessageTypeById(messageId)

                    if messageType == XEnumConst.BWMessage.MessageType.ForcePlay then
                        self._ForceMessageQueue:Enqueue(messageData)
                    end

                    table.insert(self._UnReadMessageList, messageData)
                end
            else
                XLog.Error("[短信]Repeat Notify Message => MessageId = " .. messageId)
            end
        end
    end
end

function XBigWorldMessageModel:TryRemoveUnReadMessageData(messageId)
    if not XTool.IsTableEmpty(self._UnReadMessageList) then
        for i, messageData in pairs(self._UnReadMessageList) do
            if messageData.MessageId == messageId then
                table.remove(self._UnReadMessageList, i)
                return
            end
        end
    end
end

---@return XBWMessageData
function XBigWorldMessageModel:GetForceMessageData(isUnDequeue)
    if isUnDequeue then
        return self._ForceMessageQueue:Peek()
    end

    return self._ForceMessageQueue:Dequeue()
end

function XBigWorldMessageModel:HasForceMessageData()
    return not self._ForceMessageQueue:IsEmpty()
end

function XBigWorldMessageModel:GetMessageCreateTime(messageId)
    local messageMap = self:GetMessageMap()

    if messageMap[messageId] then
        return messageMap[messageId].CreateTime
    end

    return 0
end

---@param stepStack XStack
function XBigWorldMessageModel:__PopulateCompleteStepIdList(firstStepId, stepId, stepStack)
    if not XTool.IsNumberValid(firstStepId) then
        return false
    end
    if firstStepId == stepId then
        return true, firstStepId
    end

    stepStack:Push(firstStepId)

    if not self:CheckMessageStepIdEnd(firstStepId) then
        local nextStepIds = self:GetBigWorldMessageStepNextStepById(firstStepId)

        if not XTool.IsTableEmpty(nextStepIds) then
            for _, nextStepId in pairs(nextStepIds) do
                local isSuccess, lastStepId = self:__PopulateCompleteStepIdList(nextStepId, stepId, stepStack)

                if isSuccess then
                    return true, lastStepId
                end
            end
        end
    end

    stepStack:Pop()

    return false
end

return XBigWorldMessageModel
