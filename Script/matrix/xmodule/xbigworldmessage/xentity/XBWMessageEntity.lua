local XBWMessageContentEntity = require("XModule/XBigWorldMessage/XEntity/XBWMessageContentEntity")

---@class XBWMessageEntity : XEntity
---@field _Model XBigWorldMessageModel
---@field _OwnControl XBigWorldMessageControl
local XBWMessageEntity = XClass(XEntity, "XBWMessageEntity")

function XBWMessageEntity:OnInit(id)
    self:SetMessageId(id)
end

function XBWMessageEntity:SetMessageId(id)
    self._MessageId = id or 0
    self:__InitMessageContent()
end

function XBWMessageEntity:GetMessageId()
    return self._MessageId
end

function XBWMessageEntity:IsNil()
    return not XTool.IsNumberValid(self:GetMessageId())
end

function XBWMessageEntity:IsComplete()
    return self._Model:CheckMessageFinish(self:GetMessageId())
end

function XBWMessageEntity:IsQuest()
    return XTool.IsNumberValid(self._Model:GetBigWorldMessageQuestIdById(self:GetMessageId()))
end

function XBWMessageEntity:IsQuestFinish()
    if self:IsQuest() then
        local questId = self._Model:GetBigWorldMessageQuestIdById(self:GetMessageId())
        local questData = XMVCA.XBigWorldQuest:GetQuestData(questId)

        return questData and questData:IsFinish() or false
    end

    return false
end

function XBWMessageEntity:IsMultiple()
    return self._Model:GetBigWorldMessageIsMultipleById(self:GetMessageId())
end

function XBWMessageEntity:GetContactsId()
    if not self:IsNil() then
        return self._Model:GetBigWorldMessageContactsIdById(self:GetMessageId())
    end

    return 0
end

function XBWMessageEntity:GetFirstStepId()
    return self._FirstStepId
end

function XBWMessageEntity:GetFirstStepText()
    local firstStepId = self:GetFirstStepId()
    local content = self:GetContentByStepId(firstStepId)

    return content:GetText()
end

function XBWMessageEntity:GetContentByStepId(stepId)
    return self._ContentMap[stepId]
end

function XBWMessageEntity:GetCurrentText()
    if not self:IsNil() then
        local content = self:GetContentByStepId(self._FirstStepId)

        while content and not content:IsEnd() do
            if not content:IsComplete() then
                if content:IsOptions() then
                    return XMVCA.XBigWorldService:GetText("MessageOptionsText")
                elseif content:IsMemes() then
                    return XMVCA.XBigWorldService:GetText("MessageMemesText")
                else
                    return content:GetText()
                end
            else
                content = self:GetContentByStepId(content:GetNextStepId())
            end
        end

        if content then
            if content:IsOptions() then
                return XMVCA.XBigWorldService:GetText("MessageOptionsText")
            elseif content:IsMemes() then
                return XMVCA.XBigWorldService:GetText("MessageMemesText")
            elseif content:IsSystem() then
                return XMVCA.XBigWorldService:GetText("MessageSystemText")
            else
                return content:GetText()
            end
        end
    end

    return ""
end

function XBWMessageEntity:GetCurrentPreviewText()
    local text = self:GetCurrentText()
    local length = self._OwnControl:GetMessageTextPreviewLength()

    return XUiHelper.DeleteOverlengthStringSupportRichFormat(text, length, "...")
end

function XBWMessageEntity:GetQuestIcon()
    if self:IsQuest() then
        local questId = self._Model:GetBigWorldMessageQuestIdById(self:GetMessageId())

        return XMVCA.XBigWorldQuest:GetQuestIcon(questId)
    end

    return ""
end

function XBWMessageEntity:__InitMessageContent()
    ---@type table<number, XBWMessageContentEntity>
    self._ContentMap = {}
    self._IsComplete = false

    if not self:IsNil() then
        local firstStepId = self._Model:GetBigWorldMessageFirstStepIdById(self:GetMessageId())

        self._FirstStepId = firstStepId
        self:__AddStep(firstStepId)
    end
end

---@return XBWMessageContentEntity[]
function XBWMessageEntity:__AddStep(stepId)
    ---@type XBWMessageContentEntity
    local entity = self:AddChildEntity(XBWMessageContentEntity, stepId)

    self._ContentMap[stepId] = entity

    return entity
end

return XBWMessageEntity
