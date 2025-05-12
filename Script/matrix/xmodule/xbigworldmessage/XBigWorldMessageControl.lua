local XBWMessageEntity = require("XModule/XBigWorldMessage/XEntity/XBWMessageEntity")

---@class XBigWorldMessageControl : XEntityControl
---@field private _Model XBigWorldMessageModel
local XBigWorldMessageControl = XClass(XEntityControl, "XBigWorldMessageControl")

function XBigWorldMessageControl:OnInit()
    -- 初始化内部变量
    ---@type XBWMessageEntity[]
    self._MessageList = false
    ---@type XBWMessageEntity[]
    self._UnreadMessageList = false
end

function XBigWorldMessageControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldMessageControl:RemoveAgencyEvent()

end

function XBigWorldMessageControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

function XBigWorldMessageControl:GetContactsName(contactsId)
    return self._Model:GetBigWorldMessageContactsNameById(contactsId)
end

function XBigWorldMessageControl:GetContactsIcon(contactsId)
    return self._Model:GetBigWorldMessageContactsIconById(contactsId)
end

function XBigWorldMessageControl:GetContactsIconByMessageId(messageId)
    local contactsId = self._Model:GetBigWorldMessageContactsIdById(messageId)

    return self:GetContactsIcon(contactsId)
end

function XBigWorldMessageControl:GetContactsText(contactsId)
    return self._Model:GetBigWorldMessageContactsTextById(contactsId)
end

function XBigWorldMessageControl:GetMessageQuestId(messageId)
    return self._Model:GetBigWorldMessageQuestIdById(messageId)
end

function XBigWorldMessageControl:GetMessageTipShowTime()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetFloat("MessageTipShowTime")
end

function XBigWorldMessageControl:GetMessageTextPreviewLength()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("MessageTextPreviewLength")
end

function XBigWorldMessageControl:OpenUnreadMessagePopup()
    XMVCA.XBigWorldUI:Open("UiBigWorldPopupMessage")
end

---@return XBWMessageEntity[]
function XBigWorldMessageControl:GetUnreadMessageList()
    if not self._UnreadMessageList then
        local messageDatas = self._Model:GetUnReadMessageList()

        self._UnreadMessageList = {}
        for _, messageData in pairs(messageDatas) do
            local messageId = messageData.MessageId
            local entity = self:AddEntity(XBWMessageEntity, messageId)

            table.insert(self._UnreadMessageList, entity)
        end
    else
        local messageDatas = self._Model:GetUnReadMessageList()
        local messageMap = {}
        local unreadList = {}

        for i, messageData in pairs(messageDatas) do
            messageMap[messageData.MessageId] = messageData
        end
        for i, message in pairs(self._UnreadMessageList) do
            if messageMap[message:GetMessageId()] then
                table.insert(unreadList, message)
            end
        end

        self._UnreadMessageList = unreadList
    end

    return self._UnreadMessageList
end

---@return XBWMessageEntity[]
function XBigWorldMessageControl:GetMessageList()
    if not self._MessageList then
        local messageDatas = self._Model:GetMessageMap()

        self._MessageList = {}
        for _, messageData in pairs(messageDatas) do
            local messageId = messageData.MessageId
            local entity = self:AddEntity(XBWMessageEntity, messageId)

            table.insert(self._MessageList, entity)
        end
    end

    return self._MessageList
end

---@return XBWMessageEntity[][]
function XBigWorldMessageControl:GetContactsMessageList()
    local messageList = self:GetMessageList()
    local contactsList = {}

    for _, message in pairs(messageList) do
        local contactsId = message:GetContactsId()

        if XTool.IsNumberValid(contactsId) then
            if not contactsList[contactsId] then
                contactsList[contactsId] = {}
            end

            table.insert(contactsList[contactsId], message)
        end
    end
    for _, messages in pairs(contactsList) do
        if not XTool.IsTableEmpty(messages) then
            table.sort(messages, Handler(self, self._SortMessageHandle))
        end
    end

    table.sort(contactsList, Handler(self, self._SortContactsHandle))

    return contactsList
end

---@return XBWMessageEntity
function XBigWorldMessageControl:GetForceMessageByMessageId(messageId)
    self._Model:TryRemoveUnReadMessageData(messageId)
    return self:AddEntity(XBWMessageEntity, messageId)
end

---@return XBWMessageData
function XBigWorldMessageControl:GetForceMessageData()
    return self._Model:GetForceMessageData()
end

function XBigWorldMessageControl:CheckMessageIsForcePlay(messageId)
    return self._Model:GetBigWorldMessageTypeById(messageId) == XEnumConst.BWMessage.MessageType.ForcePlay
end

function XBigWorldMessageControl:SendMessageComplete(messageId)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_BIG_WORLD_MESSAGE_COMPLETE, {
        MessageId = messageId,
    })
end

---@param messageA XBWMessageEntity
---@param messageB XBWMessageEntity
function XBigWorldMessageControl:_SortMessageHandle(messageA, messageB)
    if messageA:IsComplete() and not messageB:IsComplete() then
        return false
    end
    if not messageA:IsComplete() and messageB:IsComplete() then
        return true
    end

    local messageAId = messageA:GetMessageId()
    local messageBId = messageB:GetMessageId()
    local createTimeA = self._Model:GetMessageCreateTime(messageAId)
    local createTimeB = self._Model:GetMessageCreateTime(messageBId)
    local messageAPriority = self._Model:GetBigWorldMessagePriorityById(messageAId)
    local messageBPriority = self._Model:GetBigWorldMessagePriorityById(messageBId)

    if createTimeA > createTimeB then
        return true
    end

    if messageA:IsQuest() and not messageB:IsQuest() then
        return true
    end
    if messageB:IsQuest() and not messageA:IsQuest() then
        return false
    end
    if messageB:IsQuest() and messageA:IsQuest() then
        local questAId = self:GetMessageQuestId(messageAId)
        local questAData = XMVCA.XBigWorldQuest:GetQuestData(questAId)
        local questBId = self:GetMessageQuestId(messageBId)
        local questBData = XMVCA.XBigWorldQuest:GetQuestData(questBId)

        if questAData and questBData then
            if questAData:IsFinish() and not questBData:IsFinish() then
                return false
            elseif not questAData:IsFinish() and questBData:IsFinish() then
                return true
            end
        end
    end
    if messageAPriority == messageBPriority then
        return messageAId > messageBId
    end

    return messageAPriority > messageBPriority
end

---@param messageListA XBWMessageEntity[]
---@param messageListB XBWMessageEntity[]
function XBigWorldMessageControl:_SortContactsHandle(messageListA, messageListB)
    local isCompleteA = self:_CheckMessageListHasNonComplete(messageListA)
    local isCompleteB = self:_CheckMessageListHasNonComplete(messageListB)

    if isCompleteA ~= isCompleteB then
        return not isCompleteA
    end

    local createTimeA = self:_GetRecentCreateTimeFromMessageList(messageListA)
    local createTimeB = self:_GetRecentCreateTimeFromMessageList(messageListB)

    return createTimeA > createTimeB
end

---@param messageList XBWMessageEntity[]
function XBigWorldMessageControl:_GetRecentCreateTimeFromMessageList(messageList)
    local createTime = 0
    
    if not XTool.IsTableEmpty(messageList) then
        for _, message in ipairs(messageList) do
            local targetCreateTime = self._Model:GetMessageCreateTime(message:GetMessageId())
            
            createTime = math.max(createTime, targetCreateTime)
        end
    end
    
    return createTime
end

---@param messageList XBWMessageEntity[]
function XBigWorldMessageControl:_CheckMessageListHasNonComplete(messageList)
    if not XTool.IsTableEmpty(messageList) then
        for _, message in ipairs(messageList) do
            if not message:IsComplete() then
                return true
            end
        end
    end

    return false
end

return XBigWorldMessageControl
