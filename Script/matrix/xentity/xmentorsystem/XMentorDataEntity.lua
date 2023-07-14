local XMentorDataEntity = XClass(nil, "XMentorDataEntity")

function XMentorDataEntity:Ctor()
    self.PlayerType = XMentorSystemConfigs.IdentityType.None --玩家类型0无，1老师，2学生
    self:InitManifesto()
end

function XMentorDataEntity:InitManifesto()
    self.Teacher = {}--师傅信息
    self.Students = {}--徒弟信息
    self.ApplyList = {}--申请信息
    self.Tag = {}--个性标签
    self.OnlineTag = {}--在线时段标签
    self.Announcement = ""--宣言
    self.GraduateStudentCount = 0--自己是师父时毕业徒弟数量
    self.StageReward = {}--已领取的出师阶段奖励
    self.WeeklyTaskReward = {}--徒弟每周进度奖励
    self.DailyChangeTaskCount = 0--师傅今天更换了几个任务
    self.WeeklyTaskCompleteCount = 0--徒弟本周已完成几个每周任务
    self.WeeklyLevel = 0
    self.MonthlyStudentCount = 0--本月收徒数量
    self.Message = {MessageText = "", PublishTime = 0}
end

function XMentorDataEntity:UpdateData(Data)
    for key, value in pairs(Data) do
        self[key] = value
    end
end

function XMentorDataEntity:GetIdentity()
    return self.PlayerType
end

function XMentorDataEntity:GetTeacherData()
    return self.Teacher
end

function XMentorDataEntity:GetTag()
    return self.Tag
end

function XMentorDataEntity:GetOnlineTag()
    return self.OnlineTag
end

function XMentorDataEntity:GetAnnouncement()
    return self.Announcement
end

function XMentorDataEntity:GetGraduateStudentCount()
    return self.GraduateStudentCount
end

function XMentorDataEntity:GetWeeklyTaskCompleteCount()
    return self.WeeklyTaskCompleteCount
end

function XMentorDataEntity:GetStageReward()
    return self.StageReward
end

function XMentorDataEntity:GetWeeklyTaskReward()
    return self.WeeklyTaskReward
end

function XMentorDataEntity:GetDailyChangeTaskCount()
    return self.DailyChangeTaskCount
end

function XMentorDataEntity:GetWeeklyLevel()
    return self.WeeklyLevel
end

function XMentorDataEntity:GetMonthlyStudentCount()
    return self.MonthlyStudentCount
end

function XMentorDataEntity:GetMessageData()
    return self.Message
end

function XMentorDataEntity:GetWeeklyActivation()
    return self.WeeklyActivation
end

function XMentorDataEntity:GetTeacherGift()
    local itemId = XMentorSystemConfigs.GetMentorSystemData("ActivationItemId")
    local count = XDataCenter.ItemManager.GetCount(itemId)
    return {Id = itemId,Count = count}
end

function XMentorDataEntity:PlusDailyChangeTaskCount()
    self.DailyChangeTaskCount = self.DailyChangeTaskCount +1
end

function XMentorDataEntity:AddWeeklyTaskReward(count)
    table.insert(self.WeeklyTaskReward,count)
end

function XMentorDataEntity:AddStageReward(count)
    table.insert(self.StageReward,count)
end

function XMentorDataEntity:WeekReset()
    self.WeeklyTaskCompleteCount = 0
    self.WeeklyTaskReward = {}
    for _,student in pairs(self.Students or {}) do
        student.WeeklyTask = {}
    end
end

function XMentorDataEntity:DayReset()
    self.DailyChangeTaskCount = 0
end

function XMentorDataEntity:GetLeftStudentCount()
    local maxStudentCount = XMentorSystemConfigs.GetMentorSystemData("MaxStudentCount")
    return maxStudentCount - self:GetStudentCount()
end

function XMentorDataEntity:GetStudentDataList()
    table.sort(self.Students, function(a, b)
            if a.PlayerId == XPlayer.Id or b.PlayerId == XPlayer.Id then
                return a.PlayerId == XPlayer.Id
            else
                if a.IsGraduate ~= b.IsGraduate then
                    return a.IsGraduate
                else
                    if a.Level ~= b.Level then
                        return a.Level > b.Level
                    else
                        return a.PlayerId > b.PlayerId
                    end
                end
            end
        end)
    return self.Students
end

function XMentorDataEntity:GetNotGraduateStudentDataList()
    local list = {}
    for _,student in pairs(self.Students or {}) do
        if not student.IsGraduate then
            table.insert(list, student)
        end
    end
    table.sort(list, function(a, b)
            if a.PlayerId == XPlayer.Id or b.PlayerId == XPlayer.Id then
                return a.PlayerId == XPlayer.Id
            else
                if a.Level ~= b.Level then
                    return a.Level > b.Level
                else
                    return a.PlayerId > b.PlayerId
                end
            end
        end)
    return list
end

function XMentorDataEntity:CheckStudentSystemTaskIsEnmtyByIndex(index)
    local student = self:GetNotGraduateStudentDataByIndex(index)
    if student and student.SystemTask and next(student.SystemTask) then
        return true
    else
        return false
    end
end

function XMentorDataEntity:CheckStudentCanSendGiftByIndex(index)
    local student = self:GetNotGraduateStudentDataByIndex(index)
    if student and student.SendGiftCount == 0 then
        return true
    else
        return false
    end
end

function XMentorDataEntity:GetStudentDataByIndex(index)
    return self:GetStudentDataList()[index]
end

function XMentorDataEntity:GetNotGraduateStudentDataByIndex(index)
    return self:GetNotGraduateStudentDataList()[index]
end

function XMentorDataEntity:GetStudentCount()
    local count = 0
    for _,student in pairs(self.Students or {}) do
        if not student.IsGraduate then
            count = count + 1
        end
    end
    return count
end

function XMentorDataEntity:GetStudentSystemTaskCountByIndex(index)--本日接受的任务
    local studentData = self:GetNotGraduateStudentDataByIndex(index)
    local count = 0
    if studentData then
        local taskList = studentData.SystemTask
        for _,task in pairs(taskList or {})do
            if task.Status > XMentorSystemConfigs.TaskStatus.Init then
                count = count + 1
            end
        end
    end
    return count
end

function XMentorDataEntity:GetStudentWeeklyTaskCountByIndex(index)--本周接受的任务
    local studentData = self:GetNotGraduateStudentDataByIndex(index)
    local count = 0
    if studentData then
        count = #studentData.WeeklyTask
    end
    return count
end

function XMentorDataEntity:GetStudentWeeklyTaskCompleteCountByIndex(index)--本周的任务完成数
    local studentData = self:GetNotGraduateStudentDataByIndex(index)
    local count = 0
    if studentData then
        local taskList = studentData.WeeklyTask
        for _,task in pairs(taskList or {})do
            if task.Status ~= XMentorSystemConfigs.TaskStatus.Init and
                task.Status ~= XMentorSystemConfigs.TaskStatus.Received then
                count = count + 1
            end
        end
    end
    return count
end

function XMentorDataEntity:GetTeacherStageRewardList()
    local stageRewards = XMentorSystemConfigs.GetMasterStageRewards()
    local list = {}
    for _,reward in pairs(stageRewards or {}) do
        table.insert(list,reward)
    end
    table.sort(list, function(a, b)
            return a.Count < b.Count
        end)
    return list
end

function XMentorDataEntity:GetLastTeacherStageRewardCount()
    local list = self:GetTeacherStageRewardList()
    return list[#list].Count
end

function XMentorDataEntity:GetTeacherStageRewardNum()
    local list = self:GetTeacherStageRewardList()
    return #list
end

function XMentorDataEntity:GetTeacherStageRewardTotalPercent()
    local maxCount = self:GetLastTeacherStageRewardCount()
    local percent = self.GraduateStudentCount / maxCount
    return percent <= 1 and percent or 1
end

function XMentorDataEntity:GetTeacherStageRewardAVGTotalPercent()
    local dataList = self:GetTeacherStageRewardList()
    local curBai = 0
    local curTotal = self:GetLastTeacherStageRewardCount()
    for index,data in pairs(dataList or {}) do
        if self.GraduateStudentCount > data.Count then
            curBai = index
        else
            curTotal = data.Count
            break
        end
    end

    local percent = (curBai + (self.GraduateStudentCount / curTotal)) / #dataList
    return percent <= 1 and percent or 1
end

function XMentorDataEntity:GetTeacherStageRewardPercentByCount(count)
    local maxCount = self:GetLastTeacherStageRewardCount()
    local percent = count / maxCount
    return percent <= 1 and percent or 1
end

function XMentorDataEntity:GetTeacherStageRewardPercentByIndex(index)
    local maxNum = self:GetTeacherStageRewardNum()
    local percent = maxNum > 0 and index / maxNum or 0
    return percent <= 1 and percent or 1
end


function XMentorDataEntity:CheckTeacherStageRewardCanGetByCount(count)
    return self.GraduateStudentCount >= count
end

function XMentorDataEntity:CheckTeacherStageRewardGetedByCount(count)
    local IsGeted = false
    for _,tmpCount in pairs(self.StageReward or {}) do
        if tmpCount == count then
            IsGeted = true
            break
        end
    end
    return IsGeted
end

function XMentorDataEntity:GetStudentWeeklyRewardList()
    local weeklyRewards = XMentorSystemConfigs.GetStudentWeeklyRewards()
    local list = {}
    local curLevel = 0
    for _,reward in pairs(weeklyRewards or {}) do
        list[reward.Level] = list[reward.Level] or {}
        table.insert(list[reward.Level],reward)
    end
    for level,group in pairs(list or {}) do
        if self.WeeklyLevel >= level and level > curLevel then
            curLevel = level
        end
        table.sort(group, function(a, b)
                return a.Count < b.Count
            end)
    end

    return list[curLevel]
end

function XMentorDataEntity:GetLastStudentWeeklyRewardCount()
    local list = self:GetStudentWeeklyRewardList()
    return list[#list].Count
end

function XMentorDataEntity:GetStudentWeeklyRewardTotalPercent()
    local maxCount = self:GetLastStudentWeeklyRewardCount()
    local percent = self.WeeklyTaskCompleteCount / maxCount
    return percent <= 1 and percent or 1
end

function XMentorDataEntity:GetStudentWeeklyRewardPercentByCount(count)
    local maxCount = self:GetLastStudentWeeklyRewardCount()
    local percent = count / maxCount
    return percent <= 1 and percent or 1
end

function XMentorDataEntity:CheckStudentWeeklyRewardCanGetByCount(count)
    return self.WeeklyTaskCompleteCount >= count
end

function XMentorDataEntity:CheckStudentWeeklyRewardGetedByCount(count)
    local IsGeted = false
    for _,tmpCount in pairs(self.WeeklyTaskReward or {}) do
        if tmpCount == count then
            IsGeted = true
            break
        end
    end
    return IsGeted
end

function XMentorDataEntity:AddTeacher(teacher,students,message)
    self.Teacher = teacher
    self.Students = students or {}
    self.Message = message
end

function XMentorDataEntity:RemoveTeacher()
    self.Teacher = {}
    for index = #self.Students, 1, -1 do
        if self.Students[index].PlayerId ~= XPlayer.Id then
            table.remove(self.Students,index)
        end
    end
end

function XMentorDataEntity:AddStudent(student)
    table.insert(self.Students,student)
end

function XMentorDataEntity:RemoveStudent(student)
    for index = #self.Students, 1, -1 do
        if self.Students[index].PlayerId == student.PlayerId then
            table.remove(self.Students,index)
            break
        end
    end
end

function XMentorDataEntity:GraduateStudent(student)
    for index,tmpStudent in pairs(self.Students or {}) do
        if tmpStudent.PlayerId == student.PlayerId and not tmpStudent.IsGraduate then
            tmpStudent.IsGraduate = true
            self.GraduateStudentCount = self.GraduateStudentCount + 1
            break
        end
    end
end

function XMentorDataEntity:UpdateStudentSystemTaskById(systemTask, id)--新学生的系统发布任务
    for index,student in pairs(self.Students or {}) do
        if student.PlayerId == id then
            student.SystemTask = systemTask
            break
        end
    end
end

function XMentorDataEntity:UpdateStudentWeeklyTaskById(weeklyTask, id)--更新学生的已接任务
    for index,student in pairs(self.Students or {}) do
        if student.PlayerId == id then
            student.WeeklyTask = weeklyTask
            break
        end
    end
end

function XMentorDataEntity:UpdateMemberLevelById(level, id)--更新学生的等级
    if self.Teacher.PlayerId == id then
        self.Teacher.Level = level
        return
    end
    for index,student in pairs(self.Students or {}) do
        if student.PlayerId == id then
            student.Level = level
            break
        end
    end
end

function XMentorDataEntity:UpdateStudentSendGiftCount(id)--更新学生送礼数量
    for index,student in pairs(self.Students or {}) do
        if student.PlayerId == id then
            student.SendGiftCount = 1
            break
        end
    end
end

function XMentorDataEntity:UpdateMemberOnLineState(IsOnLine, lastLoginTime, id)--更新学生的在线状况
    if self.Teacher.PlayerId == id then
        self.Teacher.IsOnline = IsOnLine
        self.Teacher.LastLoginTime = lastLoginTime
        return
    end
    for index,student in pairs(self.Students or {}) do
        if student.PlayerId == id then
            student.IsOnline = IsOnLine
            student.LastLoginTime = lastLoginTime
            break
        end
    end
end

function XMentorDataEntity:GetApplyList()
    return self.ApplyList
end

function XMentorDataEntity:GetApplyIdList()
    local idList = {}
    for _,tmp in pairs(self.ApplyList or {}) do
        if not XDataCenter.SocialManager.GetBlackData(tmp.ApplyId) then
            table.insert(idList, tmp.ApplyId)
        end
    end
    return idList
end

function XMentorDataEntity:AddApplyId(apply)
    local IsNotIn = true
    for _,tmp in pairs(self.ApplyList or {}) do
        if tmp.ApplyId == apply.ApplyId then
            IsNotIn = false
            break
        end
    end
    if IsNotIn then
        table.insert(self.ApplyList,apply)
    end
    return IsNotIn
end

function XMentorDataEntity:RemoveApplyId(applyId)
    for index = #self.ApplyList, 1, -1 do
        if self.ApplyList[index].ApplyId == applyId then
            table.remove(self.ApplyList,index)
        end
    end
end

function XMentorDataEntity:ClearApplyIdList()
    self.ApplyList = {}
end

function XMentorDataEntity:IsTeacher()
    return self.PlayerType == XMentorSystemConfigs.IdentityType.Teacher
end

function XMentorDataEntity:IsStudent()
    return self.PlayerType == XMentorSystemConfigs.IdentityType.Student
end

function XMentorDataEntity:IsMyMentorShip(id)
    local IsMy = false
    local studentList = self:GetNotGraduateStudentDataList()
    for _,student in pairs(studentList or {}) do
        if student.PlayerId == id then
            IsMy = true
            break
        end
    end

    IsMy = IsMy or (self.Teacher and self.Teacher.PlayerId == id)
    return IsMy
end

function XMentorDataEntity:GetMenberLastLoginTimeById(id)
    local lastLoginTime = 0
    local IsMy = false
    local studentList = self:GetNotGraduateStudentDataList()
    for _,student in pairs(studentList or {}) do
        if student.PlayerId == id then
            lastLoginTime = student.LastLoginTime
            IsMy = true
            break
        end
    end

    if lastLoginTime == 0 and (self.Teacher and self.Teacher.PlayerId == id) then
        lastLoginTime = self.Teacher.LastLoginTime
        IsMy = true
    end

    if not IsMy then
        XLog.Error("This Player Is Not Own MentorShip")
    end

    return lastLoginTime
end

function XMentorDataEntity:IsHasApply()
    local applyIdList = self:GetApplyIdList()
    if not XTool.IsTableEmpty(applyIdList) then
        return true
    else
        return false
    end
end

function XMentorDataEntity:IsHasTeacher()
    if next(self.Teacher) and self.Teacher.PlayerId and self.Teacher.PlayerId > 0 then
        return true
    else
        return false
    end
end

function XMentorDataEntity:IsHasStudent()
    if self:GetStudentCount() > 0 then
        return true
    else
        return false
    end
end

function XMentorDataEntity:IsStudentFull()
    local maxStudentCount = XMentorSystemConfigs.GetMentorSystemData("MaxStudentCount")
    if self:GetStudentCount() >= maxStudentCount then
        return true
    else
        return false
    end
end

function XMentorDataEntity:IsCanDoApply(IsShowHint)
    if self.PlayerType == XMentorSystemConfigs.IdentityType.Teacher then
        if self:IsStudentFull() then
            if IsShowHint then
                XUiManager.TipText("MentorStudentFullText")
            end
            return false
        end
    elseif self.PlayerType == XMentorSystemConfigs.IdentityType.Student then
        if self:IsHasTeacher() then
            if IsShowHint then
                XUiManager.TipText("MentorTeacherFullText")
            end
            return false
        end
        local graduateLv = XMentorSystemConfigs.GetMentorSystemData("GraduateLv")
        if XPlayer.Level >= graduateLv  then
            if IsShowHint then
                XUiManager.TipText("MentorStudentCandApplyOfGraduationedText")
            end
            return false
        end
    elseif self.PlayerType == XMentorSystemConfigs.IdentityType.None then
        return false
    end
    return true
end

function XMentorDataEntity:CheckIdentity(IsShowHint)--检查玩家是否拥有身份
    if self.PlayerType == XMentorSystemConfigs.IdentityType.None then
        local beStudentLv = XMentorSystemConfigs.GetMentorSystemData("BeStudentLv")
        if IsShowHint then
            XUiManager.TipText("MentorSystemPreStudentHint",beStudentLv)
        end
        return false
    end
    return true
end

function XMentorDataEntity:CheckCanUseChat(IsShowHint)--检查玩家是否能使用聊天
    if self.PlayerType == XMentorSystemConfigs.IdentityType.Teacher then
        if not self:IsHasStudent() then
            if IsShowHint then
                XUiManager.TipText("MentorSystemNoStudentHint")
            end
            return false
        end
    elseif self.PlayerType == XMentorSystemConfigs.IdentityType.Student then
        if not self:IsHasTeacher() then
            if IsShowHint then
                XUiManager.TipText("MentorSystemNoMentorHint")
            end
            return false
        end
    elseif self.PlayerType == XMentorSystemConfigs.IdentityType.None then
        return false
    end
    return true
end

return XMentorDataEntity