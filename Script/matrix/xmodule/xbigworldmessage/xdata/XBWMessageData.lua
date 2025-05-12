---@class XBWMessageData
local XBWMessageData = XClass(nil, "XBWMessageData")

function XBWMessageData:Ctor(data)
    self.MessageId = data.MessageId or 0
    self.State = data.State or XEnumConst.BWMessage.MessageState.NotFinish
    self.CreateTime = data.CreateTime or 0

    self:UpdateStepId(data.StepIdList)
end

function XBWMessageData:IsEmpty()
    return XTool.IsNumberValid(self.MessageId)
end

function XBWMessageData:AddStepId(stepId)
    if XTool.IsNumberValid(stepId) then
        if not self.StepIdMap[stepId] then
            table.insert(self.StepIds, stepId)
            self.StepIdMap[stepId] = true
        end
    end
end

function XBWMessageData:UpdateStepId(stepIds)
    self.StepIds = {}
    self.StepIdMap = {}

    if not XTool.IsTableEmpty(stepIds) then
        for _, stepId in pairs(stepIds) do
            self:AddStepId(stepId)
        end
    end
end

function XBWMessageData:UpdateFinishState(isFinish)
    if isFinish then
        self.State = XEnumConst.BWMessage.MessageState.Finish
    else
        self.State = XEnumConst.BWMessage.MessageState.NotFinish
    end
end

function XBWMessageData:UpdateCreateTime()
    self.CreateTime = XTime.GetServerNowTimestamp()
end

return XBWMessageData
