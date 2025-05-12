---@class XUiWheelChairManualPopupTarget: XLuaUi
---@field _Control XWheelchairManualControl
local XUiWheelChairManualPopupTarget = XLuaUiManager.Register(XLuaUi, 'UiWheelChairManualPopupTarget')
local XUiGridWheelChairManualTeachingTask = require('XUi/XUiWheelchairManual/UiWheelChairManualPopupTarget/XUiGridWheelChairManualTeachingTask')

function XUiWheelChairManualPopupTarget:OnStart()
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
    self.GridTask.gameObject:SetActiveEx(false)
    
    --初始化生成任务列表
    self._TaskGrids = {}
    local taskIds = self._Control:GetCurActivityTeachTaskIds()
    XUiHelper.RefreshCustomizedList(self.GridTask.transform.parent, self.GridTask, taskIds and #taskIds or 0, function(index, go)
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskIds[index])
        local grid = XUiGridWheelChairManualTeachingTask.New(go, self, taskData)
        
        table.insert(self._TaskGrids, grid)
    end)
end

function XUiWheelChairManualPopupTarget:OnEnable()
    self:Refresh()
end

function XUiWheelChairManualPopupTarget:Refresh()
    if not XTool.IsTableEmpty(self._TaskGrids) then
        local taskIds = self._Control:GetCurActivityTeachTaskIds()
        for i, v in pairs(self._TaskGrids) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskIds[i])
            v:Refresh(taskData)
        end
    end
end

return XUiWheelChairManualPopupTarget