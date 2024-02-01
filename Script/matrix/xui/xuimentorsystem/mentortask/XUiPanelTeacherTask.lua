local XUiPanelTeacherTask = XClass(nil, "XUiPanelTeacherTask")
local XUiPanelTeacherTaskAssist = require("XUi/XUiMentorSystem/MentorTask/XUiPanelTeacherTaskAssist")
local XUiPanelTeacherTaskReward = require("XUi/XUiMentorSystem/MentorTask/XUiPanelTeacherTaskReward")
local CSTextManagerGetText = CS.XTextManager.GetText
local DefaultIndex = 1
local NameIndex = 0
local ScheduleIndex = 2
function XUiPanelTeacherTask:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)
    self.TaskTabList = {
        [1] = self.BtnTaskType1,
        [2] = self.BtnTaskType2,
    }
    self.IsHasStudent = false
    self:SetButtonCallBack()
    self:InitPanel()
    self:InitStudentGroup()
    self:InitTaskGroup()
end

function XUiPanelTeacherTask:SetButtonCallBack()
    self.PanelGift:GetObject("BtnClick").CallBack = function()
        self:OnBtnGiftClick()
    end
    
    self.PanelNoneStudent:GetObject("BtnClick").CallBack = function()
        self:OnBtnGiftClick()
    end
end

function XUiPanelTeacherTask:OnBtnGiftClick()
    XLuaUiManager.Open("UiMentorGiftTisp")
end

function XUiPanelTeacherTask:InitPanel()
    self.PanelTeacherTaskAssist = XUiPanelTeacherTaskAssist.New(self.PanelAssist, self.Root)
    self.PanelTeacherTaskReward = XUiPanelTeacherTaskReward.New(self.PanelReward, self.Root)
end

function XUiPanelTeacherTask:InitTaskGroup()
    self.CurTaskType = XMentorSystemConfigs.TeacherTaskType.Assist
    self.PanelTaskTypeGroup:Init(self.TaskTabList, function(index) self:SelectTaskType(index) end)
    self.PanelTaskTypeGroup:SelectIndex(self.CurTaskType)
end

function XUiPanelTeacherTask:InitStudentGroup()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local studentList = mentorData:GetNotGraduateStudentDataList()
    self.BtnStudent.gameObject:SetActiveEx(false)
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
        btncs:SetNameByGroup(NameIndex,student.PlayerName or "")
        local taskCount = mentorData:GetStudentWeeklyTaskCompleteCountByIndex(index)
        local maxCount = XMentorSystemConfigs.GetMentorSystemData("CompleteTaskCount")
        btncs:SetNameByGroup(ScheduleIndex,string.format("%d/%d", taskCount, maxCount))
        btncs:ShowTag(student.IsGraduate)
        local btnUiObj = btncs.transform:GetComponent("UiObject")
        XUiPLayerHead.InitPortrait(student.HeadPortraitId, student.HeadFrameId, btnUiObj:GetObject("NormalHead"))
        XUiPlayerLevel.UpdateLevel(student.Level, btnUiObj:GetObject("NormalLevel"))
        XUiPLayerHead.InitPortrait(student.HeadPortraitId, student.HeadFrameId, btnUiObj:GetObject("SelectHead"))
        XUiPlayerLevel.UpdateLevel(student.Level, btnUiObj:GetObject("SelectLevel"))
    end
    self.IsHasStudent = #self.StudentBtnList > 0
    self.PanelStudentGroup:Init(self.StudentBtnList, function(index) self:SelectStudent(index) end)
    self.PanelStudentGroup:SelectIndex(DefaultIndex)
    self.CurStudentIndex = DefaultIndex
end

function XUiPanelTeacherTask:SelectStudent(index)
    self.CurStudentIndex = index
    self:UpdatePanel()
end

function XUiPanelTeacherTask:SelectTaskType(index)
    self.CurTaskType = index
    self:UpdatePanel()
end

function XUiPanelTeacherTask:UpdatePanel()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local IsTypeAssist = self.CurTaskType == XMentorSystemConfigs.TeacherTaskType.Assist
    local IsTypeReward = self.CurTaskType == XMentorSystemConfigs.TeacherTaskType.Reward
    local student = mentorData:GetNotGraduateStudentDataByIndex(self.CurStudentIndex)
    local IsHasSystemTask = mentorData:CheckStudentSystemTaskIsEnmtyByIndex(self.CurStudentIndex)
    local IsGraduateLevel = student and student.Level >= XMentorSystemConfigs.GetMentorSystemData("GraduateLv") or false
    
    self.PanelNoneStudent.gameObject:SetActiveEx(not self.IsHasStudent)
    self.PanelTaskTypeGroup.gameObject:SetActiveEx(self.IsHasStudent)
    self.PanelStudentGroup.gameObject:SetActiveEx(self.IsHasStudent)
    self.PanelGift.gameObject:SetActiveEx(self.IsHasStudent)
    self.PanelCloseTask.gameObject:SetActiveEx(self.IsHasStudent and not IsHasSystemTask and IsGraduateLevel)
    self.PanelNoneDailyTask.gameObject:SetActiveEx(self.IsHasStudent and not IsHasSystemTask and not IsGraduateLevel)
    
    self.PanelTeacherTaskAssist.GameObject:SetActiveEx(IsTypeAssist and self.IsHasStudent and IsHasSystemTask)
    self.PanelTeacherTaskReward.GameObject:SetActiveEx(IsTypeReward and self.IsHasStudent and IsHasSystemTask)

    if IsTypeAssist then
        local taskList = student and student.SystemTask
        self.PanelTeacherTaskAssist:UpdatePanel(taskList, student)
    elseif IsTypeReward then
        local taskList = student and student.WeeklyTask
        self.PanelTeacherTaskReward:UpdatePanel(taskList, student)
    end
    
    local gift = mentorData:GetTeacherGift()
    local giftReward = XRewardManager.CreateRewardGoods(gift.Id, gift.Count)
    self:UpdateGiftPanel(giftReward)
    self:UpdateNoneStudentPanel(giftReward)
    
    self.Root:PlayAnimation("PanelMentorQieHuan")
    self:CheckStudentState()
end

function XUiPanelTeacherTask:UpdateGiftPanel(giftReward)
    local gridGift = XUiGridCommon.New(self.Root, self.PanelGift:GetObject("GridItem"))
    gridGift:Refresh(giftReward)
end

function XUiPanelTeacherTask:UpdateNoneStudentPanel(giftReward)
    local gridGift = XUiGridCommon.New(self.Root, self.PanelNoneStudent:GetObject("GridItem"))
    gridGift:Refresh(giftReward)
    self.PanelNoneStudent:GetObject("TextCount").text = giftReward.Count
end

function XUiPanelTeacherTask:CheckStudentState()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local studentList = mentorData:GetNotGraduateStudentDataList()
    if not XTool.IsTableEmpty(studentList) then
        for index,student in pairs(studentList) do
            local taskCount = mentorData:GetStudentWeeklyTaskCompleteCountByIndex(index)
            local maxCount = XMentorSystemConfigs.GetMentorSystemData("CompleteTaskCount")
            local IsShowRed = XDataCenter.MentorSystemManager.CheckTeacherCanGetStudentWeeklyRewardByStudent(student)
            if self.StudentBtnList[index] then
                self.StudentBtnList[index]:SetNameByGroup(ScheduleIndex,string.format("%d/%d", taskCount, maxCount))
                self.StudentBtnList[index]:ShowReddot(IsShowRed)
            else
                XLog.Error('out of range : 学生列表长度与UI列表长度不一致，studentListCount: '..XTool.GetTableCount(studentList)..' ; StudentBtnListCount: '..XTool.GetTableCount(self.StudentBtnList), 'index: '..index)
            end
        end
    end
    
    local student = mentorData:GetNotGraduateStudentDataByIndex(self.CurStudentIndex)
    local IsTabRedShow = XDataCenter.MentorSystemManager.CheckTeacherCanGetStudentWeeklyRewardByStudent(student)
    self.TaskTabList[XMentorSystemConfigs.TeacherTaskType.Reward]:ShowReddot(IsTabRedShow)
end

return XUiPanelTeacherTask