local XTheatre3Step = require("XModule/XTheatre3/XEntity/Adventure/XTheatre3Step")

---@class XTheatre3Chapter
local XTheatre3Chapter = XClass(nil, "XTheatre3Chapter")

function XTheatre3Chapter:Ctor()
    --- 章节ID
    self.ChapterId = 0
    self.ConnectChapterId = 0
    
    --- 当前步骤数据
    ---@type XTheatre3Step[]
    self.Steps = {}
    --- 当前章节是否已通关
    self.PassChapter = 0
    --- 已通关节点数
    self.PassNodeCount = 0
    --- 完成战斗节点数
    self.PassFightCount = 0
    --- 完成商店次数
    self.PassShopCount = 0
    --- 完成事件次数
    self.PassEventCount = 0
    --- 通过的节点
    self.PassNodeIds = {}
end

--region DataUpdate
function XTheatre3Chapter:UpdateChapterId(chapterId)
    self.ChapterId = chapterId
end

function XTheatre3Chapter:UpdateConnectChapterId(chapterId)
    self.ConnectChapterId = chapterId
end

function XTheatre3Chapter:UpdateStep(stepData)
    self.Steps = {}
    if XTool.IsTableEmpty(stepData) then
        return
    end
    for _, data in ipairs(stepData) do
        ---@type XTheatre3Step
        local step = XTheatre3Step.New()
        step:NotifyData(data)
        self.Steps[#self.Steps + 1] = step
    end
end

function XTheatre3Chapter:SetFightNodeSlotAddPassStageId(stageId)
    if XTool.IsTableEmpty(self.Steps) then
        return
    end
    local stepCount = #self.Steps
    for i = stepCount, 1, -1 do
        if not self.Steps[i]:CheckIsOver() then
            local lastNodeSlot = self.Steps[i]:GetLastNodeSlot()
            if lastNodeSlot and lastNodeSlot:CheckIsFight() then
                lastNodeSlot:AddPassedStageId(stageId)
                self:AddFightPassCount()
                return
            end
        end
    end
end

function XTheatre3Chapter:AddFightPassCount()
    self.PassFightCount = self.PassFightCount + 1
end

function XTheatre3Chapter:AddPassNode(nodeId)
    if XTool.IsNumberValid(nodeId) then
        return
    end
    if table.indexof(self.PassNodeIds, nodeId) then
        return
    end
    self.PassNodeCount = self.PassNodeCount + 1
    table.insert(self.PassNodeIds, nodeId)
end
--endregion

--region Getter
function XTheatre3Chapter:GetOtherChapterId(curChapterId)
    if self.ChapterId == curChapterId then
        return self.ConnectChapterId
    else
        return self.ChapterId
    end
end

function XTheatre3Chapter:GetCurChapterProgress()
    return 69 .. "%"
end

function XTheatre3Chapter:GetStepByUid(uid)
    if XTool.IsTableEmpty(self.Steps) then
        return false
    end
    local stepCount = #self.Steps
    for i = stepCount, 1, -1 do
        if self.Steps[i]:GetUid() == uid then
            return self.Steps[i]
        end
    end
    return false
end

---@return XTheatre3Step
function XTheatre3Chapter:GetLastStep(type)
    if XTool.IsTableEmpty(self.Steps) then
        return false
    end
    local stepCount = #self.Steps
    for i = stepCount, 1, -1 do
        if not self.Steps[i]:CheckIsOver() and (not type or type == self.Steps[i].StepType) then
            return self.Steps[i]
        end
    end
    return false
end

---@return XTheatre3NodeSlot, XTheatre3Step
function XTheatre3Chapter:GetLastNodeSlot()
    if XTool.IsTableEmpty(self.Steps) then
        return false
    end
    local stepCount = #self.Steps
    for i = stepCount, 1, -1 do
        local lastNodeSlot = self.Steps[i]:GetLastNodeSlot()
        if not self.Steps[i]:CheckIsOver() and lastNodeSlot then
            return lastNodeSlot, self.Steps[i]
        end
    end
    return false
end
--endregion

--region Checker
function XTheatre3Chapter:CheckIsPassEventStep(eventStepId)
    if XTool.IsTableEmpty(self.Steps) then
        return false
    end
    for _, step in ipairs(self.Steps) do
        if step:CheckStepType(XEnumConst.THEATRE3.StepType.Node) then
            if step:CheckStepIsPass(eventStepId) then
                return true
            end
        end
    end
    return false
end

function XTheatre3Chapter:CheckIsPassNodeId(nodeId)
    return table.indexof(self.PassNodeIds, nodeId)
end

function XTheatre3Chapter:CheckIsCanSwitchChapter(curChapterId)
    local step = self:GetLastStep()
    if not step:CheckStepType(XEnumConst.THEATRE3.StepType.Node) then
        return false
    end
    if not XTool.IsNumberValid(curChapterId) then
        return false
    end
    if not step:CheckIsHaveOtherChapter(curChapterId) then
        return false
    end
    if step:CheckIsSelected() then
        return false
    end
    return true
end
--endregion

function XTheatre3Chapter:NotifyTheatre3Chapter(data)
    self:UpdateChapterId(data.ChapterId)
    self:UpdateConnectChapterId(data.ConnectChapterId)
    self.PassChapter = data.PassChapter
    self.PassNodeCount = data.PassNodeCount
    self.PassFightCount = data.PassFightCount
    self.PassShopCount = data.PassShopCount
    self.PassEventCount = data.PassEventCount
    self.PassNodeIds = data.PassNodeIds
    self:UpdateStep(data.Steps)
end

function XTheatre3Chapter:NotifyAddStep(data, curChapterId)
    if self.ChapterId == curChapterId then
        if self.ChapterId ~= data.ChapterId then
            self.ChapterId = data.ChapterId
        end
    elseif self.ConnectChapterId == curChapterId then
        if self.ConnectChapterId ~= data.ChapterId then
            self.ConnectChapterId = data.ChapterId
        end
    end

    if XTool.IsTableEmpty(self.Steps) then
        self.Steps = {}
    end
    for _, step in pairs(self.Steps) do
        -- 重复则退出
        if step:GetUid() == data.Step.Uid then
            return
        end
    end
    ---@type XTheatre3Step
    local newStep = XTheatre3Step.New()
    newStep:NotifyData(data.Step)
    self.Steps[#self.Steps + 1] = newStep
end

return XTheatre3Chapter