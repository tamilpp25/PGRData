local XExFubenCollegeStudyManager = require("XEntity/XFuben/XExFubenCollegeStudyManager")
local XCourseData = require("XEntity/XCourse/XCourseData")

XCourseManagerCreator = function()
    local CourseData = XCourseData.New()
    -- 请求协议
    local RequesetHandle = {
        -- 获得奖励
        CourseGetReward = "CourseGetRewardRequest",
        -- 结算绩点/放弃当前进度
        CourseSaveResult = "CourseSaveResultRequest",
    }

    local XCourseManager = XExFubenCollegeStudyManager.New(XFubenConfigs.ChapterType.Course)

    -- 获取红点缓存键值
    local GetReddotKey = function(chapterId)
        return string.format("CourseChapterReddotData_%s_%s", XPlayer.Id, chapterId)
    end

    function XCourseManager.GetCourseData()
        return CourseData
    end

    -- 由于绩点是itemId但数值不存在item里，因此手动调用刷新数据
    function XCourseManager.GetTipShowItemData()
        if XTool.IsTableEmpty(CourseData) then
            return XCourseConfig.GetPointItemId()
        end
        local itemId = XCourseConfig.GetPointItemId()
        local item = XDataCenter.ItemManager.GetItem(itemId)
        local data = {
            Id = itemId,
            Count = item ~= nil and tostring(item.Count) or "0"
        }
        data = XTool.Clone(XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId))
        data.IsTempItemData = true
        data.Count = CourseData:GetTotalPointByStageType(XCourseConfig.SystemType.Lesson)
        data.Description = XGoodsCommonManager.GetGoodsDescription(itemId)
        data.WorldDesc = XGoodsCommonManager.GetGoodsWorldDesc(itemId)
        return data
    end

    function XCourseManager.FinishFight(settleData)
        if settleData.IsWin then
            XLuaUiManager.Open("UiCourseSettlement", settleData)
        else
            XDataCenter.FubenManager.ChallengeLose(settleData)
        end
    end

    --==============================系统相关==============================
    -- TimeId判断是否开启-和策划商量后暂时不用
    function XCourseManager.IsOpen()
        return XCourseManager.CheckIsOpen(XCourseConfig.SystemType.Lesson) or XCourseManager.CheckIsOpen(XCourseConfig.SystemType.Exam)
    end

    -- TimeId判断是否开启-和策划商量后暂时不用
    function XCourseManager.CheckIsOpen(stageType)
        local timeId = XCourseConfig.GetActivityTimeId(stageType)
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    function XCourseManager.OpenMain()
        XLuaUiManager.Open("UiCourseMain")
    end

    -- 初始化副本关卡类型
    function XCourseManager.InitStageInfo()
        local configs = XCourseConfig.GetCourseStage()
        local stageInfo = nil
        for _, config in pairs(configs) do
            stageInfo = XDataCenter.FubenManager.GetStageInfo(config.StageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.Course
            else
                XLog.Error("考级系统找不到配置的关卡id：", config.StageId)
            end
        end
    end
    --===================================================================

    --==============================章节组相关============================
    -- 判断章节组是否解锁
    function XCourseManager.CheckChapterGroupIsOpen(chapterGroupId)
        local prevChapterIds = XCourseConfig.GetChapterGroupPrevChapterIds(chapterGroupId)
        for index, chapterId in ipairs(prevChapterIds) do
            if not XCourseManager.CheckChapterIsOpen(chapterId) then
                return false
            end
        end
        
        return XPlayer.GetLevel() >= XCourseConfig.GetChapterGroupUnlockLv(chapterGroupId)
    end
    --===================================================================


    --==============================章节相关==============================
    -- 读取章节最高进度值，Lesson: 绩点 Exam: 星级
    function XCourseManager.GetChapterMaxPoint(chapterId)
        local stageIds = XCourseConfig.GetCourseChapterStageIdsById(chapterId)
        local point = 0
        for _, stageId in ipairs(stageIds) do
            point = point + XCourseManager.GetStageMaxPoint(stageId)
        end
        return point
    end

    -- 获得课程或执照已获得的总星星数
    function XCourseManager.GetTotalStarCount(stageType)
        local chapterIdList = XCourseConfig.GetChapterIdListByStageType(stageType)
        local totalStar = 0
        for index, chapterId in ipairs(chapterIdList) do
            totalStar = totalStar + self:GetChapterCurStarCount(chapterId)
        end
        return totalStar
    end

    -- 读取某课程已获得绩点
    function XCourseManager.GetChapterCurPoint(chapterId)
        return CourseData:GetChapterTotalPoint(chapterId)
    end

    -- 获得章节已获得的星星数
    function XCourseManager.GetChapterCurStarCount(chapterId)
        local stageIds = XCourseConfig.GetCourseChapterStageIdsById(chapterId)
        local totalCount = 0
        for index, stageId in ipairs(stageIds) do
            totalCount = totalCount + XCourseManager.GetStageStarsCount(stageId)
        end
        return totalCount
    end

    -- 是否满足某章节解锁需要的总课程绩点
    function XCourseManager.IsChapterUnlockPoint(chapterId)
        local maxPoint = XCourseManager.GetMaxTotalLessonPoint()
        local unlockLessonPoint = XCourseConfig.GetCourseChapterUnlockLessonPoint(chapterId)
        return maxPoint >= unlockLessonPoint
    end

    -- 是否满足某章节解锁需要的前置章节
    function XCourseManager.IsChapterUnlockPrevChapter(chapterId, index)
        local prevChapterIds = XCourseConfig.GetCourseChapterPrevChapterId(chapterId)
        if not index then
            for index, chapterId in ipairs(prevChapterIds) do
                if not XCourseManager.CheckChapterIsComplete(chapterId) then
                    return false
                end
            end
            return true
        end

        local chapterId = prevChapterIds[index]
        return XCourseManager.CheckChapterIsComplete(chapterId)
    end
    
    -- 判断章节是否解锁
    function XCourseManager.CheckChapterIsOpen(chapterId)
        return XCourseManager.IsChapterUnlockPrevChapter(chapterId) and
            XCourseManager.IsChapterUnlockPoint(chapterId) and
            XPlayer.GetLevel() >= XCourseConfig.GetCourseChapterUnlockLv(chapterId)
    end

    -- 判断章节是否满进度通关
    function XCourseManager.CheckChapterIsMaxPointClear(chapterId)
        return XCourseManager.GetChapterCurPoint(chapterId) >= XCourseManager.GetChapterMaxPoint(chapterId)
    end

    -- 判断章节是否通关
    function XCourseManager.CheckChapterIsComplete(chapterId)
        return CourseData:CheckChapterIsClear(chapterId)
    end
    
    -- 判断章节是否满星通关
    function XCourseManager.CheckChapterIsFullStar(chapterId)
        return CourseData:CheckChapterIsFullStar(chapterId)
    end

    -- 判断是否为新章节，章节开启但没有数据则为新章节，课程和考级通用
    function XCourseManager.CheckIsNewChapter(chapterId)
        local chapterData = CourseData:GetChapterData(chapterId)
        return XCourseManager.CheckChapterIsOpen(chapterId) and XTool.IsTableEmpty(chapterData)
    end

    -- 章节是否进行中
    function XCourseManager.IsChapterStarting(chapterId)
        local chapterData = CourseData:GetChapterData(chapterId)
        return not XTool.IsTableEmpty(chapterData)
    end

    -- 获得下一个解锁的章节Id
    function XCourseManager.GetNextUnlockChapterId(curChapterId)
        local config = XCourseConfig.GetCourseChapter()
        local prevChapterIds
        for chapterId in pairs(config) do
            prevChapterIds = XCourseConfig.GetCourseChapterPrevChapterId(chapterId)
            for _, prevChapterId in ipairs(prevChapterIds) do
                if curChapterId == prevChapterId then
                    return chapterId
                end
            end
        end
    end

    -- 读取总课程绩点
    function XCourseManager.GetTotalLessonPoint()
        return CourseData:GetTotalLessonPoint()
    end
    
    -- 历史总课程最高分
    function XCourseManager.GetMaxTotalLessonPoint()
        return CourseData:GetMaxTotalLessonPoint()
    end

    ---- 课程绩点结算奖励弹窗 begin -----
    local finishCourseChapterId
    local SetFinishCourseChapterId = function(chapterId)
        finishCourseChapterId = chapterId
    end

    function XCourseManager.CheckOpenFinishCourse(closeCb)
        if not XTool.IsNumberValid(finishCourseChapterId) then
            return
        end
        local chapterId = finishCourseChapterId
        SetFinishCourseChapterId()
        XLuaUiManager.Open("UiCourseFinishCourse", chapterId, closeCb)
    end
    ---- 课程绩点结算奖励弹窗 end -----

    ---- 执照章节通关后弹窗 begin -----
    local finishExamChapterId
    local SetFinishExamChapterId = function(chapterId)
        finishExamChapterId = chapterId
    end

    function XCourseManager.CheckOpenLiveWell(closeCb)
        if not XTool.IsNumberValid(finishExamChapterId) then
            return
        end
        local chapterId = finishExamChapterId
        SetFinishExamChapterId()
        --XLuaUiManager.Open("UiCourseLiveWell", chapterId, closeCb)
        XLuaUiManager.Open("UiCourseFinishCourse", chapterId, closeCb)
    end
    ---- 执照章节通关后弹窗 end -----
    --===================================================================




    --==============================关卡相关==============================
    -- 读取关卡最高进度值
    function XCourseManager.GetStageMaxPoint(stageId)
        local point = 0
        for _, value in ipairs(XCourseConfig.GetCourseStageStarPointById(stageId)) do
            point = point + value
        end
        return point
    end

    -- 读取关卡当前进度值
    function XCourseManager.GetStageCurPoint(stageId)
        local point = 0
        for index, flag in ipairs(XCourseManager.GetStageStarsFlagMap(stageId)) do
            if flag then point = point + XCourseConfig.GetCourseStageStarPointById(stageId)[index] end
        end
        return point
    end

    -- 读取关卡当前星级标记
    function XCourseManager.GetStageStarsFlagMap(stageId)
        -- 按位标记
        local flag = CourseData:GetStageStarsFlag(stageId)
        local _, starsFlag = XTool.GetStageStarsFlag(flag)
        return starsFlag
    end

    -- 读取关卡当前通关星级数
    function XCourseManager.GetStageStarsCount(stageId)
        -- 按位标记
        local flag = CourseData:GetStageStarsFlag(stageId)
        local count, _ = XTool.GetStageStarsFlag(flag)
        return count
    end

    -- 判断关卡是否解锁
    function XCourseManager.CheckStageIsOpen(stageId)
        local prevStageIds = XCourseConfig.GetCourseStagePrevStageIdById(stageId)
        for _, stageId in ipairs(prevStageIds) do
            if not XCourseManager.CheckStageIsComplete(stageId) then
                return false
            end
        end
        return true
    end

    -- 判断关卡是否过关
    function XCourseManager.CheckStageIsComplete(stageId)
        return CourseData:CheckStageIsComplete(stageId)
    end
    
    -- 判断关卡是否满星过关
    function XCourseManager.CheckStageIsFullStarComplete(stageId)
        return CourseData:CheckStageIsFullStarComplete(stageId)
    end
    --===================================================================




    --========================Reward判断相关===========================
    -- 判断奖励是否已领取
    function XCourseManager.CheckRewardIsDraw(courseRewardId)
        return CourseData:CheckRewardIsDraw(courseRewardId)
    end

    -- 奖励是否可领取
    function XCourseManager.CheckRewardCanDraw(courseRewardId, chapterId)
        local rewardPoint = XCourseConfig.GetRewardPoint(courseRewardId)
        local chapterData = CourseData:GetChapterData(chapterId)
        local totalPoint = chapterData and chapterData:GetTotalPoint() or 0
        return totalPoint >= rewardPoint
    end

    -- 某个类型的奖励是否可领取
    function XCourseManager.CheckRewardCanDrawByStageType(stageType)
        local courseRewardIdList = XCourseConfig.GetCourseRewardIdList(stageType)
        local chapterId
        for index, courseRewardId in ipairs(courseRewardIdList) do
            chapterId = XCourseConfig.GetRewardChapterId(courseRewardId)
            if XCourseManager.CheckRewardCanDraw(courseRewardId, chapterId) then
                return true
            end
        end
        return false
    end

    -- 某个章节是否有奖励可领取
    function XCourseManager.CheckRewardCanDrawByChapterId(chapterId)
        local courseRewardIdList = XCourseConfig.GetRewardIdListByChapterId(chapterId)
        for index, courseRewardId in ipairs(courseRewardIdList) do
            if XCourseManager.CheckRewardCanDraw(courseRewardId, chapterId) 
                    and not XCourseManager.CheckRewardIsDraw(courseRewardId) then
                return true
            end
        end
        return false
    end

    -- 某个章节的奖励是否全领取过了
    function XCourseManager.CheckRewardAllDraw(chapterId)
        local courseRewardIdList = XCourseConfig.GetRewardIdListByChapterId(chapterId)
        for index, courseRewardId in ipairs(courseRewardIdList) do
            if not XCourseManager.CheckRewardIsDraw(courseRewardId) then
                return false
            end
        end
        return true
    end
    
    -- 某个章节的奖励是否全部可以领取/或者已经领取过了
    function XCourseManager.CheckRewardAllCanDraw(chapterId)
        local courseRewardIdList = XCourseConfig.GetRewardIdListByChapterId(chapterId)
        for _, courseRewardId in ipairs(courseRewardIdList or {}) do
            if not XCourseManager.CheckRewardCanDraw(courseRewardId, chapterId) then
                return false
            end
        end
        return true
    end
    --===================================================================




    --==============================红点相关==============================
    -- 课程页签红点
    function XCourseManager.CheckCourseLessonReddot()
        for _, chapterId in pairs(XCourseConfig.GetChapterIdListByStageType(XCourseConfig.SystemType.Lesson)) do
            if XCourseManager.CheckCourseChapterReddot(chapterId) then return true end
        end
        return false
    end

    -- 考级页签红点
    function XCourseManager.CheckCourseExamReddot()
        for _, chapterId in pairs(XCourseConfig.GetChapterIdListByStageType(XCourseConfig.SystemType.Exam)) do
            if XCourseManager.CheckCourseChapterReddot(chapterId) then return true end
        end
        return false
    end

    function XCourseManager.CheckCourseChapterReddot(chapterId)
        return (not XCourseManager.GetCatchReddotData(chapterId) 
                and XCourseManager.CheckIsNewChapter(chapterId))
                or  XCourseManager.CheckChapterRewardReddot(chapterId)
    end
    
    function XCourseManager.CheckChapterRewardReddot(chapterId)
        local isAllDraw = XDataCenter.CourseManager.CheckRewardAllDraw(chapterId)
        local isCanDraw = XDataCenter.CourseManager.CheckRewardCanDrawByChapterId(chapterId)
        return isCanDraw and not isAllDraw
    end

    -- 缓存红点数据
    function XCourseManager.SetCatchReddotData(chapterId)
        local key = GetReddotKey(chapterId)
        XSaveTool.SaveData(key, true)
    end

    -- 读取红点缓存的数据
    function XCourseManager.GetCatchReddotData(chapterId)
        local key = GetReddotKey(chapterId)
        return XSaveTool.GetData(key)
    end
    
    -- 入口红点
    function XCourseManager.ExCheckIsShowRedPoint()
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Course) then
            return false
        end
        return XCourseManager.CheckCourseLessonReddot() or XCourseManager.CheckCourseExamReddot()
    end
    --===================================================================




    --==============================事件相关==============================
    -- 考级系统数据监听
    -- @cb: 事件回调
    -- @ui: ui节点
    -- @obj: UI对象，可为空
    function XCourseManager.AddDataUpdataListener(cb, ui, obj)
        XEventManager.BindEvent(ui, XEventId.EVENT_COURSE_DATA_NOTIFY, cb, obj)
    end
    --===================================================================



    --============================Protocol相关==============================
    -- 数据推送
    function XCourseManager.NotifyCourseData(data)
        CourseData:UpdateData(data["Data"])
        XEventManager.DispatchEvent(XEventId.EVENT_COURSE_DATA_NOTIFY)
    end

    -- 获得奖励
    function XCourseManager.RequestCourseGetReward(rewardIds, successCallback, failCallback)
        for _, rewardId in ipairs(rewardIds or {}) do
            if CourseData:CheckRewardIsDraw(rewardId) then
                XUiManager.TipMsg(XCourseConfig.GetRewardTips(1))
                return
            end
        end
        local requestBody = {
            RewardIds = rewardIds
        }
        XNetwork.Call(RequesetHandle.CourseGetReward, requestBody, function(res)
            if res.Code ~= XCode.Success then
                if failCallback then failCallback() end
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.OpenUiObtain(res.RewardGoodsList or {})
            CourseData:UpdateRewardIds(res.SuccessRewardIds or {})
            if successCallback then successCallback() end
            XEventManager.DispatchEvent(XEventId.EVENT_COURSE_DATA_NOTIFY)
        end)
    end

    -- 绩点章节/放弃当前进度
    function XCourseManager.RequestCourseSaveResult(successCallback, failCallback, chapterId)
        XNetwork.Call(RequesetHandle.CourseSaveResult, nil, function(res)
            if res.Code ~= XCode.Success then
                if failCallback then failCallback() end
                XUiManager.TipCode(res.Code)
                return
            end

            local curIsClear = XCourseManager.CheckChapterIsComplete(chapterId)

            CourseData:UpdateChapterDataList({res.ChapterData})
            CourseData:UpdateStageDataDict({res.StageData})
            CourseData:SetTotalLessonPoint(res.TotalLessonPoint)
            CourseData:SetMaxTotalLessonPoint(res.MaxTotalLessonPoint)

            if curIsClear ~= XCourseManager.CheckChapterIsComplete(chapterId) then
                local stageType = XCourseConfig.GetChapterStageType(chapterId)
                if stageType == XCourseConfig.SystemType.Lesson then
                    SetFinishCourseChapterId(chapterId)
                else
                    SetFinishExamChapterId(chapterId)
                end
            end

            if successCallback then successCallback() end
        end)
    end
    --===================================================================

    --============================副本入口扩展==============================
    function XCourseManager:ExOpenMainUi()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Course) then
            XCourseManager.OpenMain()
        end
    end
    --===================================================================

    return XCourseManager
end

XRpc.NotifyCourseData = function(data)
    XDataCenter.CourseManager.NotifyCourseData(data)
end