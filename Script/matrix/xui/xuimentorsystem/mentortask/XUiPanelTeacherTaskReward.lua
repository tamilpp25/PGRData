local XUiPanelTeacherTaskReward = XClass(nil, "XUiPanelTeacherTaskReward")
local XUiGridTaskReward = require("XUi/XUiMentorSystem/MentorTask/XUiGridTaskReward")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelTeacherTaskReward:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)

    self:SetButtonCallBack()
    self.GridTask.gameObject:SetActiveEx(false)
    self.GridTaskList = {}
end

function XUiPanelTeacherTaskReward:SetButtonCallBack()

end

function XUiPanelTeacherTaskReward:UpdatePanel(taskList, student)
    self.Student = student
    if taskList then
        for i = 1, #taskList ,1 do
            local grid = self.GridTaskList[i]
            if not grid then
                local taskObj = CS.UnityEngine.Object.Instantiate(self.GridTask)
                taskObj.transform:SetParent(self.PanelTask, false)
                grid = XUiGridTaskReward.New(taskObj, self.Root)
                self.GridTaskList[i] = grid
            end
            grid:UpdateGrid(taskList[i], self.Student)
            grid.GameObject:SetActiveEx(true)
        end
        for i = #taskList + 1, #self.GridTaskList, 1 do
            self.GridTaskList[i].GameObject:SetActiveEx(false)
        end
    end
    self.PanelNoneDailyTask.gameObject:SetActiveEx(not (taskList and next(taskList)))
end

return XUiPanelTeacherTaskReward