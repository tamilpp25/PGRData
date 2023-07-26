XMentorSystemManagerCreator = function()
    local XMentorDataEntity = require("XEntity/XMentorSystem/XMentorDataEntity")

    local XMentorSystemManager = {}
    local CSTextManagerGetText = CS.XTextManager.GetText
    local CSXGameClientConfig = CS.XGame.ClientConfig

    local MentorData = {}
    local ApplyPlayerList = {}
    local SpecifyPlayer = {}
    local IsApplyListChange = true
    local RecommendPlayerList = nil
    local ApplyedIdList = {}
    local TeacherChangeTaskList = {}
    local MentorShipNameList = {}
    local IsMentorShipComplete = false
    local IsFirstShowTaskGetRedDot = true

    local DefaultIndex = 1
    local DefaultLenth = 1
    
    local GraduateRewardList = {}

    local SYNC_TASKREQUEST_SECOND = 10
    local LastSyncTaskRequestTime = 0

    local SYNC_NAMELISTEQUEST_SECOND = 10
    local SYNC_MESSAGE_SECOND = 1
    local LastSyncNameListRequestTime = 0
    local LastSyncMessageRequestTime = 0

    local METHOD_NAME = {
        GetMentorPlayerInfoListRequest = "GetMentorPlayerInfoListRequest",--获取玩家详情
        GetMentorSpecifyPlayerInfoRequest = "GetMentorSpecifyPlayerInfoRequest",--搜索玩家
        PublishAnnouncementRequest = "PublishAnnouncementRequest",--发布宣言
        OperationApplyMentorRequest = "OperationApplyMentorRequest",--处理申请，同意或者拒绝
        GetMentorRecommendPlayerListRequest = "GetMentorRecommendPlayerListRequest",--获取推荐导师/徒弟
        ApplyMentorRequest = "ApplyMentorRequest",--向师傅/徒弟申请
        TickMentorRequest = "TickMentorRequest",--向师傅/徒弟退出
        MentorGraduateRequest = "MentorGraduateRequest",--徒弟出师
        MentorGetChallengeRewardRequest = "MentorGetChallengeRewardRequest",--师傅领取徒弟的毕业挑战奖励
        MentorGetStageRewardRequest = "MentorGetStageRewardRequest",--师傅领取出师进度奖励
        MentorRefreshGraduateTaskRequest = "MentorRefreshGraduateTaskRequest",--师傅刷新徒弟的毕业任务
        StudentGetTaskProgressRewardRequest = "StudentGetTaskProgressRewardRequest",--徒弟领取每周进度奖励
        StudentReceiveDailyTaskRequest = "StudentReceiveDailyTaskRequest",--徒弟领取每周任务
        StudentDeleteDailyTaskRequest = "StudentDeleteDailyTaskRequest",--徒弟删除每周任务
        MentorGetChangeDailyTaskRequest = "MentorGetChangeDailyTaskRequest",--师傅获取需要更换的任务
        MentorChangeDailyTaskRequest = "MentorChangeDailyTaskRequest",--师傅更换徒弟的任务
        MentorGiveEquipRequest = "MentorGiveEquipRequest",--师傅赠送礼物
        StudentReceiveEquipRequest = "StudentReceiveEquipRequest",--徒弟领取意识
        MentorGetWeeklyTaskRewardRequest = "MentorGetWeeklyTaskRewardRequest",--师傅领取每周任务奖励
        MentorGetNameListRequest = "MentorGetNameListRequest",--获取家族系谱
        MentorPublishMessageBoardRequest = "MentorPublishMessageBoardRequest",--师傅发布留言
        MentorStudentSendRewardRequest = "MentorStudentSendRewardRequest",--徒弟送礼物给师傅
    }

    function XMentorSystemManager.Init()
        ApplyPlayerList = {}
        SpecifyPlayer = {}
        IsApplyListChange = true
        RecommendPlayerList = nil
        ApplyedIdList = {}
        TeacherChangeTaskList = {}
        MentorShipNameList = {}
        IsMentorShipComplete = false
        IsFirstShowTaskGetRedDot = true
        GraduateRewardList = {}
        MentorData = XMentorDataEntity.New()
    end

    function XMentorSystemManager.GetMentorData()
        return MentorData
    end

    function XMentorSystemManager.GetMentorChannelKey()
        return string.format("MentorChannelKey_%s", tostring(XPlayer.Id))
    end

    function XMentorSystemManager.GetRecommendPlayerList()
        local list = {}
        local studentList = MentorData:GetStudentDataList()
        local teacher = MentorData:GetTeacherData()
        for _,player in pairs(RecommendPlayerList or {}) do
            if not XDataCenter.SocialManager.GetBlackData(player.PlayerId) then
                local IsNotIn = true
                for _,student in pairs(studentList) do
                    if player.PlayerId == student.PlayerId then
                        IsNotIn = false
                    end
                end
                if player.PlayerId == teacher.PlayerId then
                    IsNotIn = false
                end
                if IsNotIn then
                    table.insert(list,player)
                end
            end
        end
        
        return list
    end

    function XMentorSystemManager.GetSpecifyPlayer()
        return SpecifyPlayer
    end

    function XMentorSystemManager.GetApplyPlayerList()
        if XTool.IsTableEmpty(ApplyPlayerList) then
            return ApplyPlayerList
        end

        local applyPlayerList = {}
        for _, v in ipairs(ApplyPlayerList) do
            if not XDataCenter.SocialManager.GetBlackData(v.PlayerId) then
                table.insert(applyPlayerList, v)
            end
        end

        return applyPlayerList
    end

    function XMentorSystemManager.GetTeacherChangeTaskList()
        return TeacherChangeTaskList
    end

    function XMentorSystemManager.GetMentorShipNameList()
        return MentorShipNameList
    end

    function XMentorSystemManager.IsApplyed(id)
        return ApplyedIdList[id] or false
    end

    function XMentorSystemManager.SyncMentorData(data)
        MentorData:UpdateData(data)
        IsApplyListChange = true
    end

    function XMentorSystemManager.SetMentorShipNameList(data)
        MentorShipNameList = data
    end

    function XMentorSystemManager.SetApplyPlayerList(data)
        ApplyPlayerList = data
    end

    function XMentorSystemManager.SetSpecifyPlayer(data)
        SpecifyPlayer = data
    end

    function XMentorSystemManager.SetRecommendPlayerList(data)
        RecommendPlayerList = data or {}
    end

    function XMentorSystemManager.ClearRecommendPlayerList()
        RecommendPlayerList = nil
    end

    function XMentorSystemManager.SetTeacherChangeTaskList(data)
        TeacherChangeTaskList = data or {}
    end

    function XMentorSystemManager.MarkFirstShowTaskGetRedDot()
        IsFirstShowTaskGetRedDot = false
    end
    
    function XMentorSystemManager.SetMentorShipComplete(IsTeacher)
        if MentorData:IsTeacher() ~= IsTeacher then
            IsMentorShipComplete = true
        end
    end
    
    function XMentorSystemManager.ShowMentorShipComplete()
        local InMainUi = XLuaUiManager.IsUiShow("UiMain")
        local InUiMentorMainUi = XLuaUiManager.IsUiShow("UiMentorMain")
        local InUiMentorApplicationUi = XLuaUiManager.IsUiShow("UiMentorApplication")
        local InUiMentorRecommendationUi = XLuaUiManager.IsUiShow("UiMentorRecommendation")
        local InUiMentorRewardUi = XLuaUiManager.IsUiShow("UiMentorReward")
        local InUiMentorTaskUi = XLuaUiManager.IsUiShow("UiMentorTask")
        local IsCanDo = InMainUi or InUiMentorMainUi or InUiMentorApplicationUi or InUiMentorRecommendationUi or InUiMentorRewardUi or InUiMentorTaskUi
        if IsCanDo and IsMentorShipComplete then
            XUiManager.TipText("MentorShipComplete")
            IsMentorShipComplete = false
        end
    end
    
    function XMentorSystemManager.AddMentorApply(applyData)
        if MentorData:AddApplyId(applyData) then
            IsApplyListChange = true
        end
    end

    function XMentorSystemManager.AddApplyedIdList(ids)
        for _,id in pairs(ids) do
            ApplyedIdList[id] = true
        end
    end

    function XMentorSystemManager.ClearApplyedIdList()
        ApplyedIdList = {}
    end

    function XMentorSystemManager.ClearManifesto()
        MentorData:InitManifesto()
    end

    function XMentorSystemManager.AddWeeklyTaskReward(count)
        MentorData:AddWeeklyTaskReward(count)
    end

    function XMentorSystemManager.AddStageReward(count)
        MentorData:AddStageReward(count)
    end

    function XMentorSystemManager.AddTeacher(data)
        MentorData:AddTeacher(data.Teacher, data.Students, data.Message)
    end

    function XMentorSystemManager.RemoveTeacher()
        MentorData:RemoveTeacher()
    end

    function XMentorSystemManager.AddStudent(data)
        MentorData:AddStudent(data.Student)
    end

    function XMentorSystemManager.RemoveStudent(data)
        MentorData:RemoveStudent(data.Student)
    end

    function XMentorSystemManager.GraduateStudent(data)
        MentorData:GraduateStudent(data.Student)
    end

    function XMentorSystemManager.UpdateMentorData(Data)
        if Data then
            MentorData:UpdateData(Data)
        end
    end

    function XMentorSystemManager.UpdateStudentSystemTaskById(systemTask, id)
        MentorData:UpdateStudentSystemTaskById(systemTask, id)
    end

    function XMentorSystemManager.UpdateStudentWeeklyTaskById(weeklyTask, id)
        MentorData:UpdateStudentWeeklyTaskById(weeklyTask, id)
    end
    
    function XMentorSystemManager.UpdateMemberLevelById(level, id)
        MentorData:UpdateMemberLevelById(level, id)
    end
    
    function XMentorSystemManager.UpdateMemberOnLineState(IsOnLine, lastLoginTime, id)
        MentorData:UpdateMemberOnLineState(IsOnLine, lastLoginTime, id)
    end
    
    function XMentorSystemManager.UpdateStudentSendGiftCount(id)
        MentorData:UpdateStudentSendGiftCount(id)
    end
    
    function XMentorSystemManager.WeekReset()
        MentorData:WeekReset()
    end
    
    function XMentorSystemManager.DayReset()
        MentorData:DayReset()
    end
    
    function XMentorSystemManager.ClearApplyList()
        MentorData:ClearApplyIdList()
        ApplyPlayerList = {}
    end

    function XMentorSystemManager.RemoveApplyList(Id)
        MentorData:RemoveApplyId(Id)
        for index = #ApplyPlayerList, 1, -1 do
            if ApplyPlayerList[index].PlayerId == Id then
                table.remove(ApplyPlayerList,index)
            end
        end
    end
    
    function XMentorSystemManager.SetGraduateReward(rewardList)
        GraduateRewardList = rewardList
    end
    
    function XMentorSystemManager.RemoveGraduateReward()
        GraduateRewardList = nil
    end
    
    function XMentorSystemManager.GetGraduateReward()
        return GraduateRewardList
    end
    
    function XMentorSystemManager.CheckHaveGraduateReward()
        local IsHave = false
        if GraduateRewardList and next(GraduateRewardList) then
            XLuaUiManager.Open("UiMentorGraduation", GraduateRewardList, function ()
                    XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
                end)
            XMentorSystemManager.RemoveGraduateReward()
            IsHave = true
        end
        return IsHave
    end
    
    function XMentorSystemManager.AutoGraduateRunMain()
        local InUiMentorMainUi = XLuaUiManager.IsUiShow("UiMentorMain")
        local InUiMentorApplicationUi = XLuaUiManager.IsUiShow("UiMentorApplication")
        local InUiMentorRecommendationUi = XLuaUiManager.IsUiShow("UiMentorRecommendation")
        local InUiMentorRewardUi = XLuaUiManager.IsUiShow("UiMentorReward")
        local InUiMentorTaskUi = XLuaUiManager.IsUiShow("UiMentorTask")
        local InUiMentorDeclarationUi = XLuaUiManager.IsUiShow("UiMentorDeclaration")
        local InUiMentorSelectTaskUi = XLuaUiManager.IsUiShow("UiMentorSelectTask")
        local InUiMentorFileUi = XLuaUiManager.IsUiShow("UiMentorFile")   
        
        local IsCanDo = InUiMentorMainUi or InUiMentorApplicationUi or InUiMentorRecommendationUi or InUiMentorRewardUi or InUiMentorTaskUi or InUiMentorDeclarationUi or InUiMentorSelectTaskUi or InUiMentorFileUi
        if IsCanDo then
            XLuaUiManager.RunMain()
        end
    end
    ---------------------------------------------------------------------------------------------------学生用红点检测
    function XMentorSystemManager.CheckStudentCanGraduate()
        local graduateLv = XMentorSystemConfigs.GetMentorSystemData("GraduateLv")
        return XPlayer.Level >= graduateLv
    end

    function XMentorSystemManager.CheckStudentCanSendGift()
        return MentorData:CheckStudentCanSendGiftByIndex(XMentorSystemConfigs.MySelfIndex)
    end
    
    function XMentorSystemManager.CheckStudentCanGetTask()
        local curGetedCount = MentorData:GetStudentWeeklyTaskCountByIndex(XMentorSystemConfigs.MySelfIndex)
        local maxWeeklyCount = XMentorSystemConfigs.GetMentorSystemData("CompleteTaskCount")
        local curDaliyCount = MentorData:GetStudentSystemTaskCountByIndex(XMentorSystemConfigs.MySelfIndex)
        local maxDaliyCount = XMentorSystemConfigs.GetMentorSystemData("GetTaskCount")
        return curGetedCount < maxWeeklyCount and curDaliyCount < maxDaliyCount and IsFirstShowTaskGetRedDot
    end

    function XMentorSystemManager.CheckStudentCanGetWeeklyReward()
        local rewardList = MentorData:GetStudentWeeklyRewardList()

        for _,reward in pairs(rewardList or {}) do
            local IsCanGet = MentorData:CheckStudentWeeklyRewardCanGetByCount(reward.Count)
            local IsGeted = MentorData:CheckStudentWeeklyRewardGetedByCount(reward.Count)
            if IsCanGet and not IsGeted then
                return true
            end
        end
        return false
    end

    function XMentorSystemManager.CheckStudentCanGetTeacherGift()
        local studentData = MentorData:GetNotGraduateStudentDataByIndex(XMentorSystemConfigs.MySelfIndex)
        if studentData then
            for _,task in pairs(studentData.WeeklyTask or {}) do
                if task.Status == XMentorSystemConfigs.TaskStatus.GiveEquip then
                    return true
                end
            end
        end
        return false
    end
    
    function XMentorSystemManager.JudgeFailPassTime(lastLoginTime)
        local failPassTime = XMentorSystemConfigs.GetMentorSystemData("JudgeFailPassTime")
        local nowTime = XTime.GetServerNowTimestamp()
        return nowTime - lastLoginTime > failPassTime * 60
    end

    ---------------------------------------------------------------------------------------------------老师用红点检测
    function XMentorSystemManager.CheckTeacherCanGetStudentTaskReward()
        for _,student in pairs(MentorData:GetStudentDataList() or {}) do
            if XMentorSystemManager.CheckTeacherCanGetStudentTaskRewardByStudent(student) then
                return true
            end
        end
        return false
    end

    function XMentorSystemManager.CheckTeacherCanGetStudentTaskRewardByStudent(student)
        if student and student.IsGraduate then
            for _,task in pairs(student.StudentTask or {}) do
                if task.State == XDataCenter.TaskManager.TaskState.Achieved then
                    return true
                end
            end
        end
        return false
    end

    function XMentorSystemManager.CheckTeacherCanGetGraduateReward()
        local rewardList = MentorData:GetTeacherStageRewardList()

        for _,reward in pairs(rewardList or {}) do
            local IsCanGet = MentorData:CheckTeacherStageRewardCanGetByCount(reward.Count)
            local IsGeted = MentorData:CheckTeacherStageRewardGetedByCount(reward.Count)
            if IsCanGet and not IsGeted then
                return true
            end
        end
        return false
    end

    function XMentorSystemManager.CheckTeacherCanGetStudentWeeklyReward()
        for _,student in pairs(MentorData:GetNotGraduateStudentDataList() or {}) do
            if XMentorSystemManager.CheckTeacherCanGetStudentWeeklyRewardByStudent(student) then
                return true
            end
        end
        return false
    end

    function XMentorSystemManager.CheckTeacherCanGetStudentWeeklyRewardByStudent(student)
        local taskList = student and student.WeeklyTask or {}
        for _,task in pairs(taskList) do
            if task.Status == XMentorSystemConfigs.TaskStatus.Completed then
                return true
            end
        end
        return false
    end
    ----------------------------------------------------------------------------------------------Message
    function XMentorSystemManager.CheckHasNewMessage(messageTime)
        local exTime = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "MentorMessage"))
        if not exTime  or (exTime and exTime < messageTime)then
            XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "MentorMessage"),messageTime)
            return messageTime > 0
        end
        return false
    end
    ----------------------------------------------------------------------------------------------TeacherGift
    function XMentorSystemManager.SaveTeacherGiftData(itemId, count)
        local teacherGiftData = XMentorSystemManager.GetTeacherGift()
        if itemId and count then
            if teacherGiftData then
                teacherGiftData.Count = teacherGiftData.Count + count
                XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "MentorTeacherGift"),teacherGiftData)
            else
                local monday = 1
                local tmpData = {}
                tmpData.ItemId = itemId
                tmpData.Count = count
                tmpData.ResetTime = XTime.GetSeverNextWeekOfDayRefreshTime(monday)
                XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "MentorTeacherGift"),tmpData)
            end
        end
    end
    
    function XMentorSystemManager.GetTeacherGift()
        local teacherGiftData = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "MentorTeacherGift"))
        local nowTime = XTime.GetServerNowTimestamp()
        if teacherGiftData and teacherGiftData.ResetTime then
            if nowTime >= teacherGiftData.ResetTime then
                XSaveTool.RemoveData(string.format("%d%s", XPlayer.Id, "MentorTeacherGift"))
            else
                return teacherGiftData
            end
        end
        return nil
    end
    
    function XMentorSystemManager.ShowTeacherGift()
        local teacherGiftData = XMentorSystemManager.GetTeacherGift()
        if teacherGiftData then
            XSaveTool.RemoveData(string.format("%d%s", XPlayer.Id, "MentorTeacherGift"))
        end
        return teacherGiftData
    end
    ----------------------------------------------------------------------------------------------
    function XMentorSystemManager.GetMentorPlayerInfoListRequest(Ids, cb)--获取玩家详情
        if not IsApplyListChange or not( Ids and next(Ids)) then
            if cb then cb() end
            return
        end
        XNetwork.Call(METHOD_NAME.GetMentorPlayerInfoListRequest, {Ids = Ids}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XMentorSystemManager.SetApplyPlayerList(res.PlayerInfoList)
                IsApplyListChange = false
                if cb then cb() end
            end)
    end

    function XMentorSystemManager.GetMentorRecommendPlayerListRequest(cb)--获取推荐导师/徒弟
        if RecommendPlayerList then
            if cb then cb() end
            return
        end
        XNetwork.Call(METHOD_NAME.GetMentorRecommendPlayerListRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    XMentorSystemManager.SetRecommendPlayerList()
                    if cb then cb() end
                    return
                end
                XMentorSystemManager.ClearApplyedIdList()
                XMentorSystemManager.SetRecommendPlayerList(res.RecommendList)
                if cb then cb() end
            end)
    end

    function XMentorSystemManager.GetMentorSpecifyPlayerInfoRequest(Id, cb)--搜索玩家
        if not Id then
            XUiManager.TipText("MentorPlayerIdErrorText")
            return
        end
        XNetwork.Call(METHOD_NAME.GetMentorSpecifyPlayerInfoRequest, {Id = Id}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XMentorSystemManager.SetSpecifyPlayer(res.PlayerInfo)
                if cb then cb() end
            end)
    end

    function XMentorSystemManager.PublishAnnouncementRequest(tags, onlineTags, announcement, cb)--发布宣言
        XNetwork.Call(METHOD_NAME.PublishAnnouncementRequest, {Tags = tags, OnlineTags = onlineTags, Announcement = announcement}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local tmpData = {}
                tmpData.Tag = tags
                tmpData.OnlineTag = onlineTags
                tmpData.Announcement = announcement
                MentorData:UpdateData(tmpData)
                if cb then cb() end
            end)
    end

    function XMentorSystemManager.OperationApplyMentorRequest(targetPlayerIds, IsAccept, IsAll, cb)--处理申请，同意或者拒绝(可同时多个)
        if not (targetPlayerIds and next(targetPlayerIds)) then
            return
        end
        XNetwork.Call(METHOD_NAME.OperationApplyMentorRequest, {TargetPlayerId = targetPlayerIds, IsAccept = IsAccept}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)--此处失败也会执行下方逻辑
                end

                if IsAll then
                    XMentorSystemManager.ClearApplyList()
                else
                    XMentorSystemManager.RemoveApplyList(targetPlayerIds[DefaultIndex])
                end
                XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_OPERATION_APPLY)
                if cb then cb() end
            end)
    end

    function XMentorSystemManager.ApplyMentorRequest(targetPlayerIds, cb)--向师傅/徒弟申请(可同时多个)
        if not (targetPlayerIds and next(targetPlayerIds)) then
            return
        end
        XNetwork.Call(METHOD_NAME.ApplyMentorRequest, {TargetPlayerId = targetPlayerIds}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XMentorSystemManager.AddApplyedIdList(targetPlayerIds)
                if cb then cb() end
            end)
    end

    function XMentorSystemManager.TickMentorRequest(targetPlayerId, cb)--向师傅/徒弟退出
        XNetwork.Call(METHOD_NAME.TickMentorRequest, {TargetPlayerId = targetPlayerId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then cb() end
            end)
    end

    function XMentorSystemManager.MentorGetChallengeRewardRequest(studentId, taskId, cb)--师傅领取徒弟的毕业挑战奖励
        XNetwork.Call(METHOD_NAME.MentorGetChallengeRewardRequest, {StudentId = studentId, TaskId = taskId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XMentorSystemManager.MentorRefreshGraduateTaskRequest(function ()
                        if cb then cb(res.RewardGoodsList) end
                        XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_GETREWARD)
                end,true)
            end)
    end

    function XMentorSystemManager.MentorGetStageRewardRequest(count, cb)--师傅领取出师进度奖励
        XNetwork.Call(METHOD_NAME.MentorGetStageRewardRequest, {Index = count}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XMentorSystemManager.AddStageReward(count)
                if cb then cb(res.RewardGoodsList) end
                XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_GETREWARD)
            end)
    end

    function XMentorSystemManager.StudentGetTaskProgressRewardRequest(count, cb)--徒弟领取每周进度奖励
        XNetwork.Call(METHOD_NAME.StudentGetTaskProgressRewardRequest, {Index = count}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XMentorSystemManager.AddWeeklyTaskReward(count)
                if cb then cb(res.RewardGoodsList) end
                XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_GETREWARD)
            end)
    end

    function XMentorSystemManager.MentorRefreshGraduateTaskRequest(cb,IsNotCD)--师傅刷新徒弟的毕业进度
        local now = XTime.GetServerNowTimestamp()
        local syscTime = LastSyncTaskRequestTime
        if syscTime and now - syscTime < SYNC_TASKREQUEST_SECOND and not IsNotCD then
            if cb then cb() end
            return
        end
        XNetwork.Call(METHOD_NAME.MentorRefreshGraduateTaskRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local tmpData = {}
                tmpData.Students = res.Students
                MentorData:UpdateData(tmpData)
                LastSyncTaskRequestTime = XTime.GetServerNowTimestamp()
                if cb then cb() end
            end)
    end

    function XMentorSystemManager.MentorGraduateRequest(cb)--徒弟毕业
        XNetwork.Call(METHOD_NAME.MentorGraduateRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then cb(res.RewardGoodsList) end
            end)
    end

    function XMentorSystemManager.MentorGetChangeDailyTaskRequest(studentId, cb)--师傅获取需要更换的任务
        XNetwork.Call(METHOD_NAME.MentorGetChangeDailyTaskRequest, {StudentId = studentId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XMentorSystemManager.SetTeacherChangeTaskList(res.TaskIds)
                if cb then cb() end
            end)
    end

    function XMentorSystemManager.MentorGetWeeklyTaskRewardRequest(studentId, taskId, cb)--师傅领取每周任务奖励
        XNetwork.Call(METHOD_NAME.MentorGetWeeklyTaskRewardRequest, {StudentId = studentId, TaskId = taskId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then cb(res.RewardGoodsList) end
                XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_GETREWARD)
            end)
    end

    function XMentorSystemManager.StudentDeleteDailyTaskRequest(taskId, cb)--徒弟删除每周任务
        XNetwork.Call(METHOD_NAME.StudentDeleteDailyTaskRequest, {TaskId = taskId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then cb() end
            end)
    end

    function XMentorSystemManager.MentorChangeDailyTaskRequest(oldTaskId, newTaskId, studentId, cb)--师傅更换徒弟的任务
        XNetwork.Call(METHOD_NAME.MentorChangeDailyTaskRequest, {OldTaskId = oldTaskId, NewTaskId = newTaskId, StudentId = studentId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then cb() end
                XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_TEACHER_CHANGECOUNT_PLUS)
            end)
    end

    function XMentorSystemManager.StudentReceiveDailyTaskRequest(taskId, cb)--徒弟领取每周任务
        XNetwork.Call(METHOD_NAME.StudentReceiveDailyTaskRequest, {TaskId = taskId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then cb() end
            end)
    end

    function XMentorSystemManager.MentorGiveRewardRequest(studentId, taskId, cb, errorCb)--师傅赠送礼物
        XNetwork.Call(METHOD_NAME.MentorGiveEquipRequest, {StudentId = studentId, TaskId = taskId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if errorCb then errorCb() end
                    return
                end
                if cb then cb() end
            end)
    end

    function XMentorSystemManager.StudentReceiveRewardRequest(taskId, cb)--徒弟领取礼物
        XNetwork.Call(METHOD_NAME.StudentReceiveEquipRequest, {TaskId = taskId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if cb then cb(res.RewardGoodsList) end
                XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_GETREWARD)
            end)
    end

    function XMentorSystemManager.MentorGetNameListRequest(cb)--获取师承关系表
        local now = XTime.GetServerNowTimestamp()
        local syscTime = LastSyncNameListRequestTime
        if syscTime and now - syscTime < SYNC_NAMELISTEQUEST_SECOND then
            if cb then cb() end
            return
        end
        XNetwork.Call(METHOD_NAME.MentorGetNameListRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XMentorSystemManager.SetMentorShipNameList(res.StudentNameList)
                LastSyncNameListRequestTime = XTime.GetServerNowTimestamp()
                if cb then cb() end
            end)
    end
    
    function XMentorSystemManager.MentorPublishMessageBoardRequest(message, cb)--师傅发布留言
        local now = XTime.GetServerNowTimestamp()
        local syscTime = LastSyncMessageRequestTime
        if syscTime and now - syscTime < SYNC_MESSAGE_SECOND then
            XUiManager.TipText("RegressionAcceptInvitationUseCodeFrequently")
            return
        end
        XNetwork.Call(METHOD_NAME.MentorPublishMessageBoardRequest, {Message = message}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                LastSyncMessageRequestTime = XTime.GetServerNowTimestamp()
                if cb then cb() end
            end)
    end
    
    function XMentorSystemManager.MentorStudentSendRewardRequest(teacherId, cb)--徒弟送礼物给师傅
        XNetwork.Call(METHOD_NAME.MentorStudentSendRewardRequest, {MentorId = teacherId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XDataCenter.MentorSystemManager.UpdateStudentSendGiftCount(XPlayer.Id)
                if cb then cb() end
            end)
    end

    XMentorSystemManager.Init()
    return XMentorSystemManager
end

----------------------------------通用---------------------------------------->>>>>
XRpc.NotifyMentorData = function(data)--师徒信息(登录时)
    XDataCenter.MentorSystemManager.SyncMentorData(data)
end

XRpc.NotifyAddMentorApply = function(data)--收到申请消息
    XDataCenter.MentorSystemManager.AddMentorApply(data)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_GET_APPLY, true)
    XLog.Debug("MentorSystem-AddMentorApply")
end

XRpc.NotifyAddStudent = function(data)--增加一个学生
    XDataCenter.MentorSystemManager.AddStudent(data)
    XDataCenter.MentorSystemManager.SetMentorShipComplete(false)
    XDataCenter.MentorSystemManager.ShowMentorShipComplete()
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_GET_STUDENT)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_TEACHERORSTUDENT_CHANGE)
    XLog.Debug("MentorSystem-AddStudent")
end

XRpc.NotifyDeleteStudent = function(data)--减少一个学生
    XDataCenter.MentorSystemManager.RemoveStudent(data)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_LOSE_STUDENT)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_TEACHERORSTUDENT_CHANGE)
    XLog.Debug("MentorSystem-RemoveStudent")
end

XRpc.NotifyMentorChangeData = function(data)--身份改变
    XDataCenter.MentorSystemManager.ClearManifesto()
    XDataCenter.MentorSystemManager.ClearRecommendPlayerList()
    XDataCenter.MentorSystemManager.ClearApplyList()
    XDataCenter.MentorSystemManager.SyncMentorData(data)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_SHIPCHANGE)
    XLog.Debug("MentorSystem-MentorShipChange")
end

XRpc.NotifyStudentGraduate = function(data)--有学生毕业
    XDataCenter.MentorSystemManager.GraduateStudent(data)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_GRADUATE_STUDENT)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_TEACHERORSTUDENT_CHANGE)
    XLog.Debug("MentorSystem-GraduateStudent")
end

XRpc.NotifyMentorMemberWeeklyReset = function(data)--通知老师和学生每周重置
    XDataCenter.MentorSystemManager.WeekReset()
    XDataCenter.MentorSystemManager.UpdateMentorData({WeeklyLevel = data.WeeklyLevel})
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_WEEK_RESET)
    XLog.Debug("MentorSystem-WeekReset")
end

XRpc.NotifyMemberLevelChange = function(data)--通知成员等级改变
    XDataCenter.MentorSystemManager.UpdateMemberLevelById(data.Level, data.MemberId)

    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_MEMBERLEVEL_CHANGE)
    XLog.Debug("MentorSystem-MemberLevelChange")
end

XRpc.NotifyMentorMemberMessageUpdate = function(data)--通知所有人留言改变
    XDataCenter.MentorSystemManager.UpdateMentorData({Message = data.Message})
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_MESSAGE_UPDATE)
    XLog.Debug("MentorSystem-MessageUpdate")
end

XRpc.NotifyMemberOnlineStatusChange = function(data)--通知成员在线状态改变
    XDataCenter.MentorSystemManager.UpdateMemberOnLineState(data.Online, data.LastLoginTime, data.MemberId)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_ONLINE_UPDATE)
    XLog.Debug("MentorSystem-OnlineStatusChange")
end
----------------------------------通用---------------------------------------<<<<<

----------------------------------学生专用---------------------------------------->>>>>
XRpc.NotifyAddTeacher = function(data)--得到老师
    XDataCenter.MentorSystemManager.AddTeacher(data)
    XDataCenter.MentorSystemManager.SetMentorShipComplete(true)
    XDataCenter.MentorSystemManager.ShowMentorShipComplete()
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_GET_TEACHER)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_TEACHERORSTUDENT_CHANGE)
    XLog.Debug("MentorSystem-AddTeacher")
end

XRpc.NotifyDoTickMentor = function(data)--失去老师
    XDataCenter.MentorSystemManager.RemoveTeacher(data)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_LOSE_TEACHER)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_TEACHERORSTUDENT_CHANGE)
    XLog.Debug("MentorSystem-RemoveTeacher")
end

XRpc.NotifyStudentDailyTaskChange = function(data)--师傅替换了任务(当自己是学生时)
    XDataCenter.MentorSystemManager.UpdateStudentSystemTaskById(data.SystemTask, XPlayer.Id)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_STUDENT_SYSTEMTASK_CHANGE)
    XLog.Debug("MentorSystem-SelfSystemTaskChange")
end

XRpc.NotifyStudentWeeklyTaskChange = function(data)--通知学生已领取的每周任务有修改，师傅领取奖励，师傅赠送了意识(当自己是学生时)
    XDataCenter.MentorSystemManager.UpdateStudentWeeklyTaskById(data.WeeklyTask, XPlayer.Id)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_STUDENT_WEEKLYTASK_CHANGE)
    XLog.Debug("MentorSystem-SelfWeeklyTaskChange")
end

XRpc.NotifyStudentWeeklyTaskProgress = function(data)--通知学生有每周任务完成(当自己是学生时)
    XDataCenter.MentorSystemManager.UpdateMentorData({WeeklyTaskCompleteCount = data.WeeklyTaskCompleteCount})
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_STUDENT_TASKCOUNT_CHANGE)
    XLog.Debug("MentorSystem-WeeklyTaskComplete")
end

XRpc.NotifyStudentDailyReset = function(data)--通知学生每日重置
    XDataCenter.MentorSystemManager.DayReset()
    XDataCenter.MentorSystemManager.UpdateStudentSystemTaskById(data.SystemTask, XPlayer.Id)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_DAY_RESET)
    XLog.Debug("MentorSystem-DayReset")
end

XRpc.NotifyIGraduate = function(data)--通知学生到达等级后自动毕业
    XDataCenter.MentorSystemManager.AutoGraduateRunMain()
    XDataCenter.MentorSystemManager.SetGraduateReward(data.RewardGoodsList)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_AUTO_GRADUATE)
    XLog.Debug("MentorSystem-DayReset")
end
----------------------------------学生专用---------------------------------------<<<<<

----------------------------------老师专用---------------------------------------->>>>>
XRpc.NotifyMentorStudentDailyTaskChange = function(data)--通知老师，有新接的任务(当自己是老师时)
    XDataCenter.MentorSystemManager.UpdateStudentSystemTaskById(data.SystemTask, data.StudentId )
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_TEACHER_STUDENTSYSTEMTASK_CHANGE)
    XLog.Debug("MentorSystem-StudentSystemTaskChange")
end

XRpc.NotifyMentorStudentWeeklyTaskChange = function(data)--通知老师，任务进度更新，任务状态跟新，有新接的任务(当自己是老师时)
    XDataCenter.MentorSystemManager.UpdateStudentWeeklyTaskById(data.WeeklyTask, data.StudentId )
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_TEACHER_STUDENTWEEKLYTASK_CHANGE)
    XLog.Debug("MentorSystem-StudentWeeklyTaskChange")
end

XRpc.NotifyTeacherDailyReset = function(data)--通知老师每日重置
    XDataCenter.MentorSystemManager.DayReset()
    for _,taskdata in pairs(data.StudentMentorTasks) do
        XDataCenter.MentorSystemManager.UpdateStudentSystemTaskById(taskdata.MentorTask, taskdata.StudentId )
    end
    
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_DAY_RESET)
    XLog.Debug("MentorSystem-DayReset")
end

XRpc.NotifyMentorStudentMonthlyCountUpdate = function(data)--通知老师本月已招募学员数改变
    XDataCenter.MentorSystemManager.UpdateMentorData({MonthlyStudentCount = data.Count})
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_TEACHER_MONTHLYSTUDENTCOUNT_UPDATE)
    XLog.Debug("MentorSystem-MonthlyCountUpdate")
end

XRpc.NotifyMentorActivationReward = function(data)--通知老师获得活跃度礼物
    XDataCenter.MentorSystemManager.SaveTeacherGiftData(data.ItemId, data.Count)
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_TEACHER_ACTIVATION_UPDATE)
    XLog.Debug("MentorSystem-ActivationReward")
end

----------------------------------老师专用---------------------------------------<<<<<