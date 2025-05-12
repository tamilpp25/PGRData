---@class XBWMessageContentEntity : XEntity
---@field _Model XBigWorldMessageModel
---@field _OwnControl XBigWorldMessageControl
---@field _ParentEntity XBWMessageEntity
local XBWMessageContentEntity = XClass(XEntity, "XBWMessageContentEntity")

function XBWMessageContentEntity:OnInit(stepId)
    self:SetStepId(stepId)
end

function XBWMessageContentEntity:SetStepId(value)
    self._StepId = value

    self:__InitNextStep()
end

function XBWMessageContentEntity:GetStepId()
    return self._StepId
end

function XBWMessageContentEntity:GetMessageId()
    return self._ParentEntity:GetMessageId()
end

function XBWMessageContentEntity:IsQuest()
    return self._ParentEntity:IsQuest()
end

function XBWMessageContentEntity:IsComplete()
    if not self:IsNil() then
        return self._Model:CheckMessageStepFinish(self:GetMessageId(), self:GetStepId())
    end

    return false
end

function XBWMessageContentEntity:IsMultiple()
    return self._ParentEntity:IsMultiple()
end

function XBWMessageContentEntity:IsNil()
    return not XTool.IsNumberValid(self:GetStepId())
end

function XBWMessageContentEntity:IsEnd()
    if not self:IsNil() then
        return self._Model:CheckMessageStepIdEnd(self:GetStepId())
    end

    return true
end

function XBWMessageContentEntity:GetType()
    if not self:IsNil() then
        return self._Model:GetBigWorldMessageStepTypeById(self:GetStepId())
    end

    return XEnumConst.BWMessage.ContentType.None
end

function XBWMessageContentEntity:GetOprionsTextByIndex(index)
    if self:IsOptions() then
        local texts = self:_GetTextList()

        return texts[index or 1] or ""
    end

    return ""
end

function XBWMessageContentEntity:GetOprionsNextStepByIndex(index)
    if self:IsOptions() then
        local nextStepIds = self._Model:GetBigWorldMessageStepNextStepById(self:GetStepId())

        if not XTool.IsTableEmpty(nextStepIds) then
            return nextStepIds[index] or 0
        end
    end

    return 0
end

function XBWMessageContentEntity:GetOprionsCount()
    if self:IsOptions() then
        return table.nums(self:_GetTextList())
    end

    return 0
end

function XBWMessageContentEntity:GetText()
    if not self:IsOptions() and not self:IsMemes() then
        return self:_GetTextList()[1] or ""
    end

    return ""
end

function XBWMessageContentEntity:GetMemes()
    if self:IsMemes() then
        return self._Model:GetBigWorldMessageStepEmojiById(self:GetStepId())
    end

    return ""
end

function XBWMessageContentEntity:GetDuration()
    if not self:IsNil() then
        return self._Model:GetBigWorldMessageStepDurationById(self:GetStepId())
    end

    return 0
end

function XBWMessageContentEntity:GetSpeakerId()
    if self:IsReceive() then
        return self._Model:GetBigWorldMessageStepSpeakerIdById(self:GetStepId())
    end

    return 0
end

function XBWMessageContentEntity:GetSpeakerName()
    if self:IsReceive() then
        local speakerId = self:GetSpeakerId()

        if XTool.IsNumberValid(speakerId) then
            return self._OwnControl:GetContactsName(speakerId)
        end
    elseif self:IsSend() then
        return XPlayer.Name
    end

    return ""
end

function XBWMessageContentEntity:GetSpeakerIcon()
    if self:IsReceive() then
        local speakerId = self:GetSpeakerId()

        if XTool.IsNumberValid(speakerId) then
            return self._OwnControl:GetContactsIcon(speakerId)
        end
    elseif self:IsSend() then
        local headPortraitInfo = XPlayerManager.GetHeadPortraitInfoById(XPlayer.CurrHeadPortraitId)

        if headPortraitInfo then
            return headPortraitInfo.ImgSrc
        end
    end

    return ""
end

function XBWMessageContentEntity:GetNextStepId()
    if not self:IsNil() and not self:IsOptions() then
        local nextStepIds = self._Model:GetBigWorldMessageStepNextStepById(self:GetStepId())

        if not XTool.IsTableEmpty(nextStepIds) then
            return nextStepIds[1] or 0
        end
    elseif self:IsOptions() and self:IsComplete() then
        local count = self:GetOprionsCount()

        for i = 1, count do
            local nextId = self:GetOprionsNextStepByIndex(i)

            if self._Model:CheckMessageStepFinish(self:GetMessageId(), nextId) then
                return self:GetOprionsNextStepByIndex(i)
            end
        end
    end

    return 0
end

function XBWMessageContentEntity:IsReceive()
    return self:IsReceiveDialog() or self:IsReceiveMemes()
end

function XBWMessageContentEntity:IsSend()
    return self:IsSendDialog() or self:IsSendMemes()
end

function XBWMessageContentEntity:IsReceiveDialog()
    return self:GetType() == XEnumConst.BWMessage.ContentType.ReceiveDialog
end

function XBWMessageContentEntity:IsSendDialog()
    return self:GetType() == XEnumConst.BWMessage.ContentType.SendDialog
end

function XBWMessageContentEntity:IsOptions()
    return self:GetType() == XEnumConst.BWMessage.ContentType.OptionsDialog
end

function XBWMessageContentEntity:IsSystem()
    return self:GetType() == XEnumConst.BWMessage.ContentType.System
end

function XBWMessageContentEntity:IsMemes()
    return self:IsReceiveMemes() or self:IsSendMemes()
end

function XBWMessageContentEntity:IsReceiveMemes()
    return self:GetType() == XEnumConst.BWMessage.ContentType.ReceiveMemes
end

function XBWMessageContentEntity:IsSendMemes()
    return self:GetType() == XEnumConst.BWMessage.ContentType.SendMemes
end

function XBWMessageContentEntity:Read()
    self._Model:AddReadMessageStep(self:GetMessageId(), self:GetStepId(), self:IsEnd())
end

function XBWMessageContentEntity:__InitNextStep()
    ---@type table<number, XBWMessageContentEntity>
    self._NextStep = {}

    if not self:IsNil() and not self:IsEnd() then
        local nextStepIds = self._Model:GetBigWorldMessageStepNextStepById(self:GetStepId())

        if not XTool.IsTableEmpty(nextStepIds) then
            for _, stepId in pairs(nextStepIds) do
                self._NextStep[stepId] = self._ParentEntity:__AddStep(stepId)
            end
        end
    end
end

function XBWMessageContentEntity:_GetTextList()
    if not self:IsNil() then
        local texts = self._Model:GetBigWorldMessageStepTextById(self:GetStepId())

        return texts or {}
    end

    return {}
end

return XBWMessageContentEntity
