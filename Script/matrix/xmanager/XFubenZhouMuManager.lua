--- 一个主线或外篇章节对应一个周目(ZhouMuId)，把周目（ZhouMuId）当成一个模式，第几周目对应周目的第几个周目章节(ZhouMuChapterId)

XFubenZhouMuManagerCreator = function()
    local XFubenZhouMuManager = {}

    ---
    --- 实现FubenManager中的接口，初始化StageInfo
    function XFubenZhouMuManager.InitStageInfo()
        local zhouMuChapterCfg = XFubenZhouMuConfigs.GetAllZhouMuChapterCfg()
        for _, data in pairs(zhouMuChapterCfg) do
            for i,stageId in ipairs(data.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                stageInfo.Type = XDataCenter.FubenManager.StageType.ZhouMu
                stageInfo.OrderId = i
            end
        end
    end

    ---
    --- 根据'zhouMuId'检查当前章节处于第几周目
    --- 如果没有解锁或没有配置周目挑战则返回 0
    ---@param zhouMuId number
    ---@return number
    function XFubenZhouMuManager.GetZhouMuNumber(zhouMuId)
        if zhouMuId == 0 or zhouMuId == nil then
            return 0
        end

        local zhouMuChapters = XFubenZhouMuConfigs.GetZhouMuChapters(zhouMuId)

        for i = #zhouMuChapters, 1, -1 do
            local onThis = true -- 默认处于当前周目，有任何一个条件不满足时改为false

            -- 检查解锁条件
            local conditions = XFubenZhouMuConfigs.GetZhouMuChapterCondition(zhouMuChapters[i])
            for _, v in pairs(conditions) do
                if not XConditionManager.CheckCondition(v) then
                    onThis = false
                end
            end

            if onThis then
                return i
            end
        end

        return 0
    end

    ---
    --- 获取‘zhouMuId’周目完成的挑战任务数与总数
    ---@param zhouMuId number
    ---@return number
    ---@return number
    function XFubenZhouMuManager.GetZhouMuTaskProgress(zhouMuId)
        local taskIds = XFubenZhouMuConfigs.GetZhouMuTasks(zhouMuId)
        local totalTaskNum = #taskIds
        local zhouMuNum = 0

        local taskList = XDataCenter.TaskManager.GetZhouMuFullTaskList(XDataCenter.TaskManager.TaskType.ZhouMu)
        if taskList == nil or next(taskList) == nil then
            return zhouMuNum, totalTaskNum
        end

        local taskDic = {}
        for _,v in pairs(taskList) do
            taskDic[v.Id] = v
        end

        for _, id in pairs(taskIds) do
            if taskDic[id].State == XDataCenter.TaskManager.TaskState.Achieved
                    or taskDic[id].State == XDataCenter.TaskManager.TaskState.Finish then
                zhouMuNum = zhouMuNum + 1
            end
        end

        return zhouMuNum, totalTaskNum
    end

    ---
    --- 检查‘zhouMuId’周目的挑战任务是否全部领取奖励
    ---@param zhouMuId number
    ---@return boolean
    function XFubenZhouMuManager.ZhouMuTaskIsAllFinish(zhouMuId)
        local result = true
        local taskIds = XFubenZhouMuConfigs.GetZhouMuTasks(zhouMuId)

        local taskList = XDataCenter.TaskManager.GetZhouMuFullTaskList(XDataCenter.TaskManager.TaskType.ZhouMu)
        if taskList == nil or next(taskList) == nil then
            result = false
            return result
        end

        local taskDic = {}
        for _,v in pairs(taskList) do
            taskDic[v.Id] = v
        end

        for _, id in pairs(taskIds) do
            if taskDic[id].State ~= XDataCenter.TaskManager.TaskState.Finish then
                result = false
            end
        end

        return result
    end

    ---
    --- 检查'zhouMuId'周目是否有奖励可以领取
    ---@param zhouMuId number
    ---@return boolean
    function XFubenZhouMuManager.HasTaskReward(zhouMuId)
        local haveTask = false
        if zhouMuId == nil then
            return haveTask
        end

        local taskIds = XFubenZhouMuConfigs.GetZhouMuTasks(zhouMuId)
        local taskList = XDataCenter.TaskManager.GetZhouMuFullTaskList(XDataCenter.TaskManager.TaskType.ZhouMu)
        if taskList == nil or next(taskList) == nil then
            return haveTask
        end

        local taskDic = {}
        for _,v in pairs(taskList) do
            taskDic[v.Id] = v
        end

        for _, id in pairs(taskIds) do
            if taskDic[id].State == XDataCenter.TaskManager.TaskState.Achieved then
                haveTask = true
            end
        end

        return haveTask
    end

    ---
    --- 根据'zhouMuId'获取周目的当前周目章节Id
    ---@param zhouMuId number
    ---@return number
    function XFubenZhouMuManager.GetZhouMuChapterIdByZhouMuId(zhouMuId)
        -- 当前周目所在的周目章节数
        local zhouMuNumber = XFubenZhouMuManager.GetZhouMuNumber(zhouMuId)
        if zhouMuNumber == 0 then
            return {}
        end

        -- 用周目Id得到所有周目章节Id
        local zhouMuChapters = XFubenZhouMuConfigs.GetZhouMuChapters(zhouMuId)

        return zhouMuChapters[zhouMuNumber]
    end

    ---
    --- 根据'ChapterMainId'获取周目的当前周目章节数据
    --- 'isExtra'true为外篇，false为主线
    ---@param ChapterMainId number
    ---@param isExtra boolean
    ---@return table
    function XFubenZhouMuManager.GetZhouMuChapterData(chapterMainId, isExtra)
        -- 得到该章节的周目Id
        local zhouMuId
        if isExtra then
            zhouMuId = XFubenExtraChapterConfigs.GetZhouMuId(chapterMainId)
        else
            zhouMuId = XFubenMainLineConfigs.GetZhouMuId(chapterMainId)
        end

        -- 当前周目所在的周目章节数
        local zhouMuNumber = XFubenZhouMuManager.GetZhouMuNumber(zhouMuId)
        if zhouMuNumber == 0 then
            return {}
        end

        -- 用周目Id得到所有周目章节Id
        local zhouMuChapters = XFubenZhouMuConfigs.GetZhouMuChapters(zhouMuId)

        -- 用当前周目章节的Id得到章节数据
        local config = XFubenZhouMuConfigs.GetZhouMuChapterCfg(zhouMuChapters[zhouMuNumber])

        return config
    end

    ---
    --- 判断是否需要播放弹窗动画，以及要播放怎样的弹窗动画
    --- 'zhouMuId'为当前的周目Id
    --- 'zhouMuChapterId'为当前的周目章节Id
    --- 'oriLastStageIsPass'是一开始保存的当前章节最后一关是否通关的标志
    --- 如果在开启界面的时候对比发现最后一关的通关状态与'oriLastStageIsPass'不同，则说明第一次通关了最后一关
    ---@param zhouMuId number
    ---@param zhouMuChapterId number
    ---@param oriLastStageIsPass boolean
    ---@return number
    function XFubenZhouMuManager.CheckPlayTipAnima(zhouMuId, zhouMuChapterId, oriLastStageIsPass)
        if oriLastStageIsPass then
            -- 之前通关过当前周目章节的最后一关，不播放动画
            return XFubenZhouMuConfigs.EnumZhouMuTipAnima.None
        else
            local zhouMuHadIn = XSaveTool.GetData(string.format("%s%s", "ZhouMuHadIn", XPlayer.Id))
            if not zhouMuHadIn  then
                -- 第一次进入周目模式
                XSaveTool.SaveData(string.format("%s%s", "ZhouMuHadIn", XPlayer.Id), true)
                return XFubenZhouMuConfigs.EnumZhouMuTipAnima.PlayStart
            end

            local lastStage = XFubenZhouMuConfigs.GetZhouMuChapterLastStage(zhouMuChapterId)
            local isPassLastStage = XDataCenter.FubenManager.CheckStageIsPass(lastStage)

            if  isPassLastStage then
                -- 通关了最后一关
                local isLastZhouMuChapter
                local lastZhouMuChapter = XFubenZhouMuConfigs.GetZhouMuLastChapter(zhouMuId)
                isLastZhouMuChapter = (lastZhouMuChapter == zhouMuChapterId)

                if isLastZhouMuChapter then
                    -- 最后一个周目章节，只播放结束动画
                    return XFubenZhouMuConfigs.EnumZhouMuTipAnima.PlayEnd
                else
                    -- 不是最后的周目章节，先播放结束动画，然后播放开启新周目章节的动画
                    return XFubenZhouMuConfigs.EnumZhouMuTipAnima.PlayEndStart
                end
            else
                return XFubenZhouMuConfigs.EnumZhouMuTipAnima.None
            end
        end
    end

    return XFubenZhouMuManager

end