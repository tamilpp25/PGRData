local XUiPanelStudentTask = XClass(nil, "XUiPanelStudentTask")
local XUiGridStudentWeeklyTask = require("XUi/XUiMentorSystem/MentorTask/XUiGridStudentWeeklyTask")
local XUiPanelStudentPhasesTask = require("XUi/XUiMentorSystem/MentorTask/XUiPanelStudentPhasesTask")

local CSTextManagerGetText = CS.XTextManager.GetText
local DefaultIndex = 1

function XUiPanelStudentTask:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:InitPanelTask()
    self:InitPhasesTask()
end

function XUiPanelStudentTask:SetButtonCallBack()
    
end

function XUiPanelStudentTask:InitPanelTask()
    local maxGetedCount = XMentorSystemConfigs.GetMentorSystemData("CompleteTaskCount")
    self.GridTask.gameObject:SetActiveEx(false)
    self.TaskGridList = {}
    for i = 1, maxGetedCount, 1 do
        local obj = CS.UnityEngine.Object.Instantiate(self.GridTask)
        obj.gameObject:SetActiveEx(true)
        obj.transform:SetParent(self.TaskContent, false)
        self.TaskGridList[i] = XUiGridStudentWeeklyTask.New(obj, self.Root)
    end
end

function XUiPanelStudentTask:InitPhasesTask()
    self.PhasesTask = XUiPanelStudentPhasesTask.New(self.PanelReward)
    self.PhasesTask:InitPhasesTaskGrid()
end

function XUiPanelStudentTask:UpdatePanelTask()
    local maxGetedCount = XMentorSystemConfigs.GetMentorSystemData("CompleteTaskCount")
    for i = 1, maxGetedCount, 1 do
        self.TaskGridList[i]:UpdateGrid(i)
    end
end

function XUiPanelStudentTask:UpdatePanel()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local curGetedCount = mentorData:GetStudentWeeklyTaskCountByIndex(XMentorSystemConfigs.MySelfIndex)
    local maxGetedCount = XMentorSystemConfigs.GetMentorSystemData("CompleteTaskCount")
    local maxDaliyCount = XMentorSystemConfigs.GetMentorSystemData("GetTaskCount")
    local curDaliyCount = mentorData:GetStudentSystemTaskCountByIndex(XMentorSystemConfigs.MySelfIndex)
    
    self.TextGetTask:GetObject("TextGetTask").text = CSTextManagerGetText("MentorStudentWeekCanGetTask")
    self.TextGetTask:GetObject("TaskCount").text = string.format("%d/%d", maxGetedCount - curGetedCount, maxGetedCount)
    self.TextDaliyTask:GetObject("TextDaliyTask").text = CSTextManagerGetText("MentorStudentDayCanGetTask")
    self.TextDaliyTask:GetObject("TaskCount").text = string.format("%d/%d", maxDaliyCount - curDaliyCount, maxDaliyCount)
    
    self.PhasesTask:UpdatePanelPhasesTask()
    self:UpdatePanelTask()
end

return XUiPanelStudentTask






