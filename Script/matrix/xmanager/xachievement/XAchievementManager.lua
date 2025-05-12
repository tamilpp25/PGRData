--===============
--成就系统管理器
--模块负责：吕天元
--依赖模块：XDataCenter.TaskManager
--===============
XAchievementManagerCreator = function()
    local XAchievementManager = {}
    local XAchievement = require("XEntity/XAchievement/XAchievement")
    --=============
    --成就列表
    --List<XAchievement>
    --=============
    local AchievementList
    --=============
    --成就表Id -> 成就字典
    --Key : Id -> Achievement表的Id
    --Value : XAchievement对象
    --=============
    local AchievementDicById
    --=============
    --任务Id -> 成就字典
    --Key : Id -> Task表的Id
    --Value : XAchievement对象
    --=============
    local AchievementDicByTaskId
    --=============
    --任务Id -> 成就任务字典
    --Key : Id -> Task表的Id
    --Value : { Id : TaskId State : XTaskManager.TaskState}
    --=============
    local TaskDicByTaskId
    --=============
    --成就类型Id -> 成就列表字典
    --Key : Id -> AchievementTypeInfo表的Id
    --Value : List<XAchievement>
    --=============
    local AchievementListDicByType
    --=============
    --总成就数量
    --=============
    local TotalAchievementNum
    --=============
    --完成成就数量
    --=============
    local CompleteAchievementNum
    --=============
    --初始化监听事件标记
    --=============
    local InitListenerFlag
    --=============
    --任务初始化标记
    --=============
    local TaskInitialFlag = false

    local function AddInitListener()
        if InitListenerFlag then return end
        XEventManager.AddEventListener(XEventId.EVENT_NOTICE_TASKINITFINISHED, XAchievementManager.SetTaskInitFlag)
        XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, XAchievementManager.SyncTasks)
        InitListenerFlag = true
    end

    local function RemoveInitListener()
        if not InitListenerFlag then return end
        XEventManager.RemoveEventListener(XEventId.EVENT_NOTICE_TASKINITFINISHED, XAchievementManager.SetTaskInitFlag)
        XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, XAchievementManager.SyncTasks)
        InitListenerFlag = false
    end

    --=============
    --初始化
    --等任务系统数据初始化成功后才初始化
    --=============
    function XAchievementManager.Init()
        AchievementList = {}
        AchievementDicById = {}
        AchievementDicByTaskId = {}
        TaskDicByTaskId = {}
        AchievementListDicByType = {}
        TaskInitialFlag = false
        TotalAchievementNum = 0
        CompleteAchievementNum = 0
        AddInitListener()
    end

    local function CreateAchievement(achievementId)
        local achievement
        local cfg = XAchievementConfigs.GetCfgByIdKey(
            XAchievementConfigs.TableKey.Achievement,
            achievementId
        )
        if cfg then
            achievement = XAchievement.New(achievementId)
            table.insert(AchievementList, achievement)
            AchievementDicById[achievementId] = achievement
            AchievementDicByTaskId[achievement:GetTaskId()] = achievement
        end
        return achievement
    end

    local function CreateAchievementListByType(achievementTypeId)
        AchievementListDicByType[achievementTypeId] = {}
        local allCfgs = XAchievementConfigs.GetCfgByIdKey(
            XAchievementConfigs.TableKey.Type2AchievementDic,
            achievementTypeId
        )
        for _, cfg in pairs(allCfgs or {}) do
            local id = cfg.Id
            if AchievementDicById[id] then
                goto checkNext
            end
            local achievement = CreateAchievement(id)
            if achievement then
                table.insert(AchievementListDicByType[achievementTypeId], achievement)
            end
            :: checkNext ::
        end
        return AchievementListDicByType[achievementTypeId]
    end

    local function CreateAchievementList()
        local allCfgs = XAchievementConfigs.GetAllConfigs(
            XAchievementConfigs.TableKey.AchievementType
        )
        for id, _ in pairs(allCfgs) do
            CreateAchievementListByType(id)
        end
    end

    local function GetAchievementList()
        if not AchievementList or (not next(AchievementList)) then
            CreateAchievementList()
        end
        return AchievementList
    end

    --=============
    --根据成就类型Id获取成就列表
    --=============
    function XAchievementManager.GetAchievementListByType(achievementTypeId)
        if not AchievementList or (not next(AchievementList)) then
            CreateAchievementList()
        end
        return AchievementListDicByType[achievementTypeId]
    end

    function XAchievementManager.CheckHasRewardByType(achievementTypeId)
        local list = XAchievementManager.GetAchievementListByType(achievementTypeId)
        for _, achievement in pairs(list or {}) do
            if achievement:GetTaskState() == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
        return false
    end
    
    function XAchievementManager.CheckHasRewardByBaseType(baseAchvTypeId)
        local achievementTypes = XAchievementConfigs.GetCfgByIdKey(
            XAchievementConfigs.TableKey.BaseId2AchievementTypeDic,
            baseAchvTypeId,
            true
        )
        for _, typeCfg in pairs(achievementTypes) do
            if XAchievementManager.CheckHasRewardByType(typeCfg.Id) then
                return true
            end
        end
        return false
    end

    function XAchievementManager.CheckHasReward()
        local baseCfgs = XAchievementConfigs.GetAllConfigs(
            XAchievementConfigs.TableKey.AchievementBaseType
        )
        for _, cfg in pairs(baseCfgs or {}) do
            if XAchievementManager.CheckHasRewardByBaseType(cfg.Id) then
                return true
            end
        end
        return false
    end

    function XAchievementManager.GetCanGetRewardTypeIndexByBaseType(baseAchvTypeId)
        local achievementTypes = XAchievementConfigs.GetCfgByIdKey(
            XAchievementConfigs.TableKey.BaseId2AchievementTypeDic,
            baseAchvTypeId,
            true
        )
        local index = 0
        local canGetReward = false
        for _, typeCfg in pairs(achievementTypes) do
            index = index + 1
            canGetReward = XAchievementManager.CheckHasRewardByType(typeCfg.Id)
            if canGetReward then
                break
            end
        end
        return canGetReward and index or 1
    end

    function XAchievementManager.GetAchievementCompleteCount()
        return CompleteAchievementNum or 0
    end

    function XAchievementManager.GetTotalAchievementCount()
        return TotalAchievementNum or 0
    end
    --=================
    --根据基础成就类型获取完成成就数
    --=================
    function XAchievementManager.GetAchievementCompleteCountByType(baseAchvTypeId)
        if not baseAchvTypeId then return XAchievementManager.GetAchievementCompleteCount() end
        local XTaskManager = XDataCenter.TaskManager
        local typeInfos = XAchievementConfigs.GetCfgByIdKey(
            XAchievementConfigs.TableKey.BaseId2AchievementTypeDic,
            baseAchvTypeId
        )
        local list = {}
        for _, typeInfo in pairs(typeInfos) do
            local newList = XAchievementManager.GetAchievementListByType(typeInfo.Id)
            if newList then
                list = XTool.MergeArray(list, newList)
            end
        end
        local totalCount = 0
        for _, achievement in pairs(list) do
            local task = achievement:GetTaskState()
            if task == XTaskManager.TaskState.Finish then
                totalCount = totalCount + 1
            end
        end
        return totalCount
    end

    function XAchievementManager.GetAchvCompleteQualityDic()
        local resultDic = {
            [1] = 0,
            [2] = 0,
            [3] = 0,
            [4] = 0,
            [5] = 0
        }
        local XTaskManager = XDataCenter.TaskManager
        for _, achievement in pairs(GetAchievementList() or {}) do
            local quality = achievement:GetQuality()
            local task = achievement:GetTaskState()
            if task == XTaskManager.TaskState.Finish then
                resultDic[quality] = resultDic[quality] + 1
            end
        end
        return resultDic
    end

    function XAchievementManager.GetAchvCompleteQualityDicByType(baseAchvTypeId)
        if not baseAchvTypeId then return XAchievementManager.GetAchvCompleteQualityDic() end
        local resultDic = {
            [1] = 0,
            [2] = 0,
            [3] = 0,
            [4] = 0,
            [5] = 0
        }
        local XTaskManager = XDataCenter.TaskManager
        local typeInfos = XAchievementConfigs.GetCfgByIdKey(
            XAchievementConfigs.TableKey.BaseId2AchievementTypeDic,
            baseAchvTypeId
        )
        local list = {}
        for _, typeInfo in pairs(typeInfos) do
            local newList = XAchievementManager.GetAchievementListByType(typeInfo.Id)
            if newList then
                list = XTool.MergeArray(list, newList)
            end
        end
        for _, achievement in pairs(list) do
            local quality = achievement:GetQuality()
            local task = achievement:GetTaskState()
            if task == XTaskManager.TaskState.Finish then
                resultDic[quality] = resultDic[quality] + 1
            end
        end
        return resultDic
    end
    --=============
    --根据成就Id获取成就对象
    --=============
    function XAchievementManager.GetAchievementById(achievementId)
        if not AchievementList or (not next(AchievementList)) then
            CreateAchievementList()
        end
        local achievement = AchievementDicById[achievementId]
        if achievement then
            return achievement
        end
    end

    function XAchievementManager.GetAchievementByTaskId(taskId)
        if not taskId then return end
        return AchievementDicByTaskId[taskId]
    end
    --=============
    --根据任务Id获取任务数据(TaskData)
    --=============
    function XAchievementManager.GetTaskByTaskId(taskId)
        if not taskId then return end
        return XDataCenter.TaskManager.GetTaskDataById(taskId)
    end
    --=============
    --根据任务Id获取任务状态
    --=============
    function XAchievementManager.GetTaskStateByTaskId(taskId)
        if not taskId then return XDataCenter.TaskManager.TaskState.Invalid end
        local task = XDataCenter.TaskManager.GetTaskDataById(taskId)
        return task and task.State or XDataCenter.TaskManager.TaskState.Invalid
    end

    function XAchievementManager.SetTaskInitFlag()
        TaskInitialFlag = true
    end
    --=============
    --同步成就任务状态
    --=============
    function XAchievementManager.SyncTasks()
        local achieveCount = 0
        local totalCount = 0
        local newAchieveList = {}
        local XTaskManager = XDataCenter.TaskManager
        local achvTaskData = XTaskManager.GetAchvTaskList()
        GetAchievementList()
        for _, task in pairs(achvTaskData) do
            if task ~= nil then
                if AchievementDicByTaskId[task.Id] and
                    AchievementDicByTaskId[task.Id]:GetIsHidden() and
                    (task.State ~= XTaskManager.TaskState.Finish) and
                    (task.State ~= XTaskManager.TaskState.Achieved) then
                    goto continue
                end
                totalCount = totalCount + 1
                --登陆时推送全部任务数据
                if not task then
                    if task.State == XTaskManager.TaskState.Finish then
                        table.insert(newAchieveList, task)
                    end
                else --后面同步的任务数据刷新           
                    if task.State ~= task.State and task.State == XTaskManager.TaskState.Finish then
                        table.insert(newAchieveList, task)
                    end
                end
                if task.State == XTaskManager.TaskState.Finish then
                    achieveCount = achieveCount + 1
                end
                :: continue ::
            end
        end

        --若有新达成的任务则打开新成就达成事件界面
        if TaskInitialFlag and next(newAchieveList) then
            XLuaUiManager.Open("UiAchievementTips", newAchieveList)
        end
        TotalAchievementNum = totalCount
        CompleteAchievementNum = achieveCount
        XEventManager.DispatchEvent(XEventId.EVENT_ACHIEVEMENT_SYNC_SUCCESS)
    end
    XAchievementManager.Init()
    return XAchievementManager
end