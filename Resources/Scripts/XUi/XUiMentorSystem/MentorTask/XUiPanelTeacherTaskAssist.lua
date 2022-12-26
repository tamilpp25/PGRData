local XUiPanelTeacherTaskAssist = XClass(nil, "XUiPanelTeacherTaskAssist")
local XUiGridTaskAssist = require("XUi/XUiMentorSystem/MentorTask/XUiGridTaskAssist")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelTeacherTaskAssist:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)

    self:SetButtonCallBack()
    self.GridTask.gameObject:SetActiveEx(false)
    self.GridTaskList = {}
end

function XUiPanelTeacherTaskAssist:SetButtonCallBack()
    
end

function XUiPanelTeacherTaskAssist:UpdatePanel(taskList, student)
    self.Student = student
    if taskList then
        for i = 1, #taskList ,1 do
            local grid = self.GridTaskList[i]
            if not grid then
                local taskObj = CS.UnityEngine.Object.Instantiate(self.GridTask)
                taskObj.transform:SetParent(self.PanelTask, false)
                grid = XUiGridTaskAssist.New(taskObj, self.Root)
                self.GridTaskList[i] = grid
            end
            grid:UpdateGrid(taskList[i], self.Student)
            grid.GameObject:SetActiveEx(true)
        end
        for i = #taskList + 1, #self.GridTaskList, 1 do
            self.GridTaskList[i].GameObject:SetActiveEx(false)
        end
    end
    
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local maxCount = XMentorSystemConfigs.GetMentorSystemData("ChangeTaskCount")
    local curCount = mentorData:GetDailyChangeTaskCount()
    self.TextTitle.text = CSTextManagerGetText("MentorTeacherDayCanChangeTask")
    self.TextCount.text = string.format("%d/%d",maxCount - curCount , maxCount)
    self.TxtHint.text = CSTextManagerGetText("MentorTeacherChangeTaskHint")
end

return XUiPanelTeacherTaskAssist