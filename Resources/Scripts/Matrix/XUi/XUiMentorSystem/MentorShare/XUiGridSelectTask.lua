local XUiGridSelectTask = XClass(nil, "XUiGridSelectTask")
local DefaultIndex = 1
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridSelectTask:Ctor(ui, base, oldTaskId, studentId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self.OldTaskId = oldTaskId
    self.StudentId = studentId
    self:SetButtonCallBack()
end

function XUiGridSelectTask:SetButtonCallBack()
    self.BtnSelect.CallBack = function()
        self:OnBtnSelectClick()
    end
end

function XUiGridSelectTask:OnBtnSelectClick()
    if not self.Data then return end
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    
    if self.IsTeacher then
        if not self.OldTaskId or not self.StudentId then return end
        XDataCenter.MentorSystemManager.MentorChangeDailyTaskRequest(self.OldTaskId, self.Data, self.StudentId,function ()
                mentorData:PlusDailyChangeTaskCount()
            end)
    else
        XDataCenter.MentorSystemManager.StudentReceiveDailyTaskRequest(self.Data.TaskId,function ()
                local studentData = mentorData:GetNotGraduateStudentDataByIndex(XMentorSystemConfigs.MySelfIndex)
                local weeklyTaskList = studentData and studentData.WeeklyTask
                for _,weeklyTask in pairs(weeklyTaskList or {}) do
                    if weeklyTask.TaskId == self.Data.TaskId then
                        if weeklyTask.Status == XMentorSystemConfigs.TaskStatus.Completed then
                            XUiManager.TipText("MentorTaskCompletedHint")
                        end
                        break
                    end
                end
            end)
    end
    self.Base:OnBtnCloseClick()
end

function XUiGridSelectTask:UpdateGrid(data,IsTeacher)
    self.Data = data
    self.IsTeacher = IsTeacher
    if data then
        if IsTeacher then
            local taskCfg = XDataCenter.TaskManager.GetTaskTemplate(data)
            self.TitleText.text = taskCfg.Title
            self.TextDesc.text = taskCfg.Desc

            self.TagText.gameObject:SetActiveEx(false)
            self.BtnSelect.gameObject:SetActiveEx(true)
            self.BtnSelected.gameObject:SetActiveEx(false)

            self.BtnSelect:SetName(CSTextManagerGetText("MentorTeacherChangeTaskText"))
        else
            local taskCfg = XDataCenter.TaskManager.GetTaskTemplate(data.TaskId)
            self.TitleText.text = taskCfg.Title
            self.TextDesc.text = taskCfg.Desc

            self.BtnSelect.gameObject:SetActiveEx(self:IsCanSelect())
            self.BtnSelected.gameObject:SetActiveEx(not self:IsCanSelect())
            self.TagText.gameObject:SetActiveEx(data.HasChange)

            self.BtnSelect:SetName(CSTextManagerGetText("MentorStudentSelectTaskText"))
        end

    end
end

function XUiGridSelectTask:IsCanSelect()
    return self.Data.Status == XMentorSystemConfigs.TaskStatus.Init
end

return XUiGridSelectTask