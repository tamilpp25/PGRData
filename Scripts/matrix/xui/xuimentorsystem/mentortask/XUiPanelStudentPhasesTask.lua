local XUiPanelStudentPhasesTask = XClass(nil, "XUiPanelStudentPhasesTask")
local XUiGridPhasesTask = require("XUi/XUiMentorSystem/MentorTask/XUiGridPhasesTask")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelStudentPhasesTask:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)

end

function XUiPanelStudentPhasesTask:InitPhasesTaskGrid()
    self.PhasesTaskGrids = {}
    self.PhasesTaskGridRects = {}
    self.GridActive.gameObject:SetActiveEx(false)
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local taskList = mentorData:GetStudentWeeklyRewardList()
    local taskCount = #taskList
    for i = 1,taskCount do
        local grid = self.PhasesTaskGrids[i]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridActive)
            obj.gameObject:SetActiveEx(true)
            obj.transform:SetParent(self.PanelContent, false)
            grid = XUiGridPhasesTask.New(obj, self)
            self.PhasesTaskGrids[i] = grid
            self.PhasesTaskGridRects[i] = grid.Transform:GetComponent("RectTransform")
        end
    end
end

function XUiPanelStudentPhasesTask:UpdatePanelPhasesTask()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self.ImgDaylyActiveProgress.fillAmount = mentorData:GetStudentWeeklyRewardTotalPercent()
    self.TxtDailyActive.text = mentorData:GetWeeklyTaskCompleteCount()
    self.TextMax.text = string.format("/%d",mentorData:GetLastStudentWeeklyRewardCount())
    self.TextActive.text = CSTextManagerGetText("MentorTeacherPhasesTaskText")
    
    local taskList = mentorData:GetStudentWeeklyRewardList()
    local taskCount = #taskList
    for i = 1, taskCount do
        self.PhasesTaskGrids[i]:UpdateData(taskList[i])
    end

    -- 自适应
    local activeProgressRectSize = self.ImgDaylyActiveProgress.transform.rect.size
    for i = 1, #self.PhasesTaskGrids do
        local task = taskList[i]
        local valOffset = mentorData:GetStudentWeeklyRewardPercentByCount(task.Count)
        local adjustPosition = CS.UnityEngine.Vector3(activeProgressRectSize.x * valOffset, 0, 0)
        self.PhasesTaskGridRects[i].anchoredPosition3D = adjustPosition
    end
end
return XUiPanelStudentPhasesTask