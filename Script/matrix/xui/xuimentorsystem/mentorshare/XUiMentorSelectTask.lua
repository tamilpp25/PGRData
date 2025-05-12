local XUiMentorSelectTask = XLuaUiManager.Register(XLuaUi, "UiMentorSelectTask")
local XUiGridSelectTask = require("XUi/XUiMentorSystem/MentorShare/XUiGridSelectTask")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiMentorSelectTask:OnStart(IsTeacher, oldTaskId, student)
    self:SetButtonCallBack()
    self.IsTeacher = IsTeacher
    self.Student = student
    self.OldTaskId = oldTaskId
    self:InitPanel()
end

function XUiMentorSelectTask:OnDestroy()

end

function XUiMentorSelectTask:OnEnable()
    self:UpdatePanel()
end

function XUiMentorSelectTask:OnDisable()

end

function XUiMentorSelectTask:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiMentorSelectTask:OnBtnCloseClick()
    self:Close()
end

function XUiMentorSelectTask:InitPanel()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local studentId = self.Student and self.Student.PlayerId

    local taskCount = 0
    if self.IsTeacher then
        taskCount = XMentorSystemConfigs.GetMentorSystemData("MentorChangeTaskDisplayCount")
    else
        taskCount = XMentorSystemConfigs.GetMentorSystemData("SysReleaseTaskCount")
    end

    self.GridTask.gameObject:SetActiveEx(false)
    self.TaskGridList = {}

    for i = 1, taskCount, 1 do
        local taskObj = CS.UnityEngine.Object.Instantiate(self.GridTask)
        taskObj.transform:SetParent(self.PanelCombinationContent, false)
        self.TaskGridList[i] = XUiGridSelectTask.New(taskObj, self, self.OldTaskId, studentId)
    end
end

function XUiMentorSelectTask:UpdatePanel()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local taskList = {}

    if self.IsTeacher then
        taskList = XDataCenter.MentorSystemManager.GetTeacherChangeTaskList()
        local maxCount = XMentorSystemConfigs.GetMentorSystemData("ChangeTaskCount")
        local curCount = mentorData:GetDailyChangeTaskCount()
        self.CanGetText.text = CSTextManagerGetText("MentorTeacherDayCanChangeTask")
        self.CanGetCount.text = string.format("%d/%d", maxCount - curCount, maxCount)
    else
        taskList = self.Student.SystemTask
        table.sort(taskList, function(a, b)
            if a.HasChange == b.HasChange then
                return false
            else
                return a.HasChange
            end
        end)
        local maxCount = XMentorSystemConfigs.GetMentorSystemData("GetTaskCount")
        local curCount = mentorData:GetStudentSystemTaskCountByIndex(XMentorSystemConfigs.MySelfIndex)
        self.CanGetText.text = CSTextManagerGetText("MentorStudentDayCanGetTask")
        self.CanGetCount.text = string.format("%d/%d", maxCount - curCount, maxCount)
    end

    local taskCount = XMentorSystemConfigs.GetMentorSystemData("MentorChangeTaskDisplayCount")

    for i = 1, taskCount, 1 do
        local grid = self.TaskGridList[i]
        if grid then
            local task = taskList[i]
            if task then
                grid:UpdateGrid(task, self.IsTeacher)
                grid.GameObject:SetActiveEx(true)
            else
                grid.GameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiMentorSelectTask:OnBtnBackClick()
    self:Close()
end