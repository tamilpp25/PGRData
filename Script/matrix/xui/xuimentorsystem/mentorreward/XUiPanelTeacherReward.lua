local XUiPanelTeacherReward = XClass(nil, "XUiPanelTeacherReward")
local XUiGridTeacherTask = require("XUi/XUiMentorSystem/MentorReward/XUiGridTeacherTask")
local XUiPanelTeacherPhasesReward = require("XUi/XUiMentorSystem/MentorReward/XUiPanelTeacherPhasesReward")
local CSTextManagerGetText = CS.XTextManager.GetText
local DefaultIndex = 1
local tableSort = table.sort
function XUiPanelTeacherReward:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    
    self.BtnStudent.gameObject:SetActiveEx(false)
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:InitStudentGroup()
    self:InitPhasesReward()
end

function XUiPanelTeacherReward:InitPhasesReward()
    self.PhasesReward = XUiPanelTeacherPhasesReward.New(self.PanelReward, self.Base)
    self.PhasesReward:InitPhasesRewardGrid()
end

function XUiPanelTeacherReward:InitStudentGroup()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local studentList = mentorData:GetStudentDataList()
    self.PanelNoneStudent.gameObject:SetActiveEx(not next(studentList))
    self.PanelDaily.gameObject:SetActiveEx(next(studentList))
    if not(studentList and next(studentList)) then
       return 
    end
    self.StudentBtnList = self.StudentBtnList or {}
    for index,student in pairs(studentList or {}) do
        local btncs = self.StudentBtnList[index]
        if not btncs then
            local btn = CS.UnityEngine.Object.Instantiate(self.BtnStudent)
            btn.transform:SetParent(self.PanelStudentContainer, false)
            btncs = btn:GetComponent("XUiButton")
            table.insert(self.StudentBtnList, btncs)
        end
        btncs.gameObject:SetActiveEx(true)
        btncs:SetName(student.PlayerName or "")
        btncs:ShowTag(student.IsGraduate)
        local btnUiObj = btncs.transform:GetComponent("UiObject")
        XUiPLayerHead.InitPortrait(student.HeadPortraitId, student.HeadFrameId, btnUiObj:GetObject("NormalHead"))
        XUiPlayerLevel.UpdateLevel(student.Level, btnUiObj:GetObject("NormalLevel"))
        XUiPLayerHead.InitPortrait(student.HeadPortraitId, student.HeadFrameId, btnUiObj:GetObject("SelectHead"))
        XUiPlayerLevel.UpdateLevel(student.Level, btnUiObj:GetObject("SelectLevel"))
    end
    self.PanelStudentGroup:Init(self.StudentBtnList, function(index) self:SelectStudent(index) end)
    self.PanelStudentGroup:SelectIndex(DefaultIndex)
    self.CurStudentIndex = DefaultIndex
end

function XUiPanelTeacherReward:SelectStudent(index)
    self.CurStudentIndex = index
    self:SetupDynamicTable()
    self.Base:PlayAnimation("PanelDailyRefresh")
end

function XUiPanelTeacherReward:SetButtonCallBack()
   
end

function XUiPanelTeacherReward:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(XUiGridTeacherTask)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiPanelTeacherReward:SetupDynamicTable()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self.CurStudent = mentorData:GetStudentDataByIndex(self.CurStudentIndex)
    self.PageDatas = self.CurStudent and self:TaskSort(self.CurStudent.StudentTask) or {}
    self.PanelNoneDailyTask.gameObject:SetActiveEx(not next(self.PageDatas))
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelTeacherReward:TaskSort(tasks)
    local taskTemplate = XTaskConfig.GetTaskTemplate()
    local list = {}
    for _,task in pairs(tasks or {}) do
        table.insert(list,task)
    end
    tableSort(list, function(a, b)
            local pa, pb = taskTemplate[a.TaskId].Priority, taskTemplate[b.TaskId].Priority
            if a.State == b.State then
                if pa ~= pb then
                    return pa > pb
                else
                    return a.TaskId > b.TaskId
                end
            else
                if a.State < XDataCenter.TaskManager.TaskState.Finish and b.State < XDataCenter.TaskManager.TaskState.Finish then
                    return a.State > b.State
                else
                    return b.State == XDataCenter.TaskManager.TaskState.Finish
                end
            end
        end)
    return list
end

function XUiPanelTeacherReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid.RootUi = self.Base
        grid:ResetData(self.PageDatas[index], self.CurStudent)
    end
end

function XUiPanelTeacherReward:UpdatePanel()
    self.PhasesReward:UpdatePanelPhasesReward()
    self:SetupDynamicTable()
    self:CheckRedDotAndTag()
end

function XUiPanelTeacherReward:CheckRedDotAndTag()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local studentList = mentorData:GetStudentDataList()
    for index,student in pairs(studentList or {}) do
        local IsShowRed = XDataCenter.MentorSystemManager.CheckTeacherCanGetStudentTaskRewardByStudent(student)
        self.StudentBtnList[index]:ShowReddot(IsShowRed)
        self.StudentBtnList[index]:ShowTag(student.IsGraduate)
    end
end

return XUiPanelTeacherReward