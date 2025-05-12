---@class XUiGridRogueSimTask : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimTask = XClass(XUiNode, "XUiGridRogueSimTask")

---@param id number 任务自增Id
function XUiGridRogueSimTask:Refresh(id)
    self.Id = id
    local configId = self._Control:GetTaskConfigIdById(id)
    local isFinish = self._Control:CheckTaskIsFinished(id)
    local schedule, totalNum = self._Control:GetTaskScheduleAndTotalNum(id, configId)
    self.TxtDetail.text = self._Control:GetTaskDesc(configId)
    self.TxtNum.text = string.format("%d/%d", schedule, totalNum)
    self.TxtNum.gameObject:SetActiveEx(not isFinish)
    self.ImgComplete.gameObject:SetActiveEx(isFinish)
end

return XUiGridRogueSimTask
