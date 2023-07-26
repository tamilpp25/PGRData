---@class XViewModelTransfiniteAchievement
local XViewModelTransfiniteAchievement = XClass(nil, "XViewModelTransfiniteAchievement")

local Pairs = pairs
local TableSort = table.sort

local function TaskSortFunc(taskIdA, taskIdB)
    return taskIdA < taskIdB
end

function XViewModelTransfiniteAchievement:Ctor()
    self._NormalStageGroup = nil
    self._NormalAchievementIdList = nil
    self._SeniorAchievementIdList = nil
    self._SeniorStageGroup = nil
    self._FinishTaskIdList = nil
    self._AchievementInformation = {
        NormalTitle = false, --初级组名称
        NormalIconLv = false, --初级组图标
        SeniorTitle = false, --高级组名称
        SeniorLv = false, --高级组等级范围
        SeniorIconLv = false, --高级组图标
        IsUnlock = false, --是否解锁高级组
    }

    self._IsJustOpen = true

    self._DataScoreTitle = {
        Title = false,

        NormalTitle = false,
        NormalIcon = false,
        NormalIsUnlock = false,
        NormalLvText = false,

        SeniorTitle = false,
        SeniorLvText = false,
        SeniorIconLv = false,
        SeniorIsUnlock = false,
    }
end

---@param stageGroup XTransfiniteStageGroup
function XViewModelTransfiniteAchievement:SetStageGroup(stageGroup)
    self._NormalStageGroup = stageGroup
    self:Init()
    self:InitAchievementInformation()
end

function XViewModelTransfiniteAchievement:Init()
    local stageGroupId = self._NormalStageGroup:GetId()
    local achievementIdList = XTransfiniteConfigs.GetAchievementListByStageGroupId(stageGroupId)
    local normalAchievementIdList = {}
    local seniorAchievementIdList = {}

    if not achievementIdList then
        self._NormalAchievementIdList = normalAchievementIdList
        self._SeniorAchievementIdList = seniorAchievementIdList
        self._SeniorStageGroup = self._NormalStageGroup

        XLog.Error("当前StageGroupId未配置成就TaskGroupId！StageGroupId:" .. stageGroupId)

        return
    end

    for id, config in Pairs(achievementIdList) do
        if not self._SeniorStageGroup then
            local stageGroupIdList = config.StageGroupId

            for _, stageGroupId in Pairs(stageGroupIdList) do
                if stageGroupId ~= self._NormalStageGroup:GetId() then
                    self._SeniorStageGroup = XDataCenter.TransfiniteManager.GetStageGroup(stageGroupId)
                end
            end
        end

        if config.Type == XTransfiniteConfigs.TaskTypeEnum.Normal then
            local taskIds = XTransfiniteConfigs.GetTaskTaskIds(id)

            for _, taskId in Pairs(taskIds) do
                normalAchievementIdList[#normalAchievementIdList + 1] = taskId
            end
        elseif config.Type == XTransfiniteConfigs.TaskTypeEnum.Senior then
            local taskIds = XTransfiniteConfigs.GetTaskTaskIds(id)

            for _, taskId in Pairs(taskIds) do
                seniorAchievementIdList[#seniorAchievementIdList + 1] = taskId
            end
        end
    end

    TableSort(normalAchievementIdList, TaskSortFunc)
    TableSort(seniorAchievementIdList, TaskSortFunc)

    self._NormalAchievementIdList = normalAchievementIdList
    self._SeniorAchievementIdList = seniorAchievementIdList
end

function XViewModelTransfiniteAchievement:InitAchievementInformation()
    local minLv = XTransfiniteConfigs.GetRegionMinLv(XTransfiniteConfigs.RegionType.Senior)
    local maxLv = XTransfiniteConfigs.GetRegionMaxLv(XTransfiniteConfigs.RegionType.Senior)
    local region = XDataCenter.TransfiniteManager.GetRegion()

    local regionList = XDataCenter.TransfiniteManager.GetAllRegion()
    local region1 = regionList[1]
    local region2 = regionList[2]

    self._AchievementInformation.NormalTitle = region1:GetName()
    self._AchievementInformation.NormalIconLv = XTransfiniteConfigs.GetRegionIconLv(XTransfiniteConfigs.RegionType.Normal)
    self._AchievementInformation.SeniorTitle = region2:GetName()
    self._AchievementInformation.SeniorLv = "Lv" .. minLv .. "~" .. maxLv
    self._AchievementInformation.SeniorIconLv = XTransfiniteConfigs.GetRegionIconLv(XTransfiniteConfigs.RegionType.Senior)
    self._AchievementInformation.IsUnlock = region:GetIsSeniorRegion()
end

---@alias XTransfiniteAchievementInformation { NormalTitle:string, NormalIconLv:string, SeniorTitle:string, SeniorLv:string, SeniorIconLv:string, IsUnlock:boolean }
---@return XTransfiniteAchievementInformation
function XViewModelTransfiniteAchievement:GetAchievementInformation()
    return self._AchievementInformation
end

---@alias XTransfiniteAchievementData { NormalTaskId:number, NormalTaskId:number, Desc:string, Title:string, NormalReward:table, SeniorReward:table, NormalTaskState:number, SeniorTaskState:number, :boolean }
---@return XTransfiniteAchievementData[], number
function XViewModelTransfiniteAchievement:GetAchievementDataListAndStartIndex()
    local normalTaskDataList = XDataCenter.TaskManager.GetTaskIdListData(self._NormalAchievementIdList, false)
    local seniorTaskDataList = XDataCenter.TaskManager.GetTaskIdListData(self._SeniorAchievementIdList, false)
    local length = #normalTaskDataList <= #seniorTaskDataList and #normalTaskDataList or #seniorTaskDataList
    local achievementDataList = {}
    local startIndex = false

    self._FinishTaskIdList = {}

    for i = 1, length do
        local taskConfig = XTaskConfig.GetTaskCfgById(self._NormalAchievementIdList[i])
        local achievementData = {
            NormalTaskId = self._NormalAchievementIdList[i], --初级组成就任务Id
            SeniorTaskId = self._SeniorAchievementIdList[i], --高级组成就任务Id
            Desc = taskConfig.Desc, --任务描述
            Title = taskConfig.Title, --任务名称
            NormalReward = XDataCenter.TransfiniteManager.GetRewardByTaskId(normalTaskDataList[i].Id, 1), --初级组任务奖励
            SeniorReward = XDataCenter.TransfiniteManager.GetRewardByTaskId(seniorTaskDataList[i].Id, 1), --高级组任务奖励
            NormalTaskState = normalTaskDataList[i].State, --初级组任务状态
            SeniorTaskState = seniorTaskDataList[i].State, --高级组任务状态
            IsUnlock = self._AchievementInformation.IsUnlock, --是否解锁高级组
        }
        if achievementData.NormalTaskState == XDataCenter.TaskManager.TaskState.Achieved then
            self._FinishTaskIdList[#self._FinishTaskIdList + 1] = achievementData.NormalTaskId
        end
        if achievementData.IsUnlock and achievementData.SeniorTaskState == XDataCenter.TaskManager.TaskState.Achieved then
            self._FinishTaskIdList[#self._FinishTaskIdList + 1] = achievementData.SeniorTaskId
        end

        achievementDataList[i] = achievementData
    end

    -- 第一次OnEnable自动选index
    if not self._IsJustOpen then
        startIndex = false
    else
        self._IsJustOpen = false

        for i = 1, #achievementDataList do
            local achievementData = achievementDataList[i]
            if achievementData.NormalTaskState == XDataCenter.TaskManager.TaskState.Achieved
                    or achievementData.SeniorTaskState == XDataCenter.TaskManager.TaskState.Achieved
            then
                startIndex = i
                break
            end
        end

        if not startIndex then
            for i = 1, #achievementDataList do
                local achievementData = achievementDataList[i]
                if achievementData.NormalTaskState == XDataCenter.TaskManager.TaskState.Active
                        or achievementData.NormalTaskState == XDataCenter.TaskManager.TaskState.Accepted
                        or achievementData.SeniorTaskState == XDataCenter.TaskManager.TaskState.Active
                        or achievementData.SeniorTaskState == XDataCenter.TaskManager.TaskState.Accepted
                then
                    startIndex = i
                    break
                end
            end
        end

        if not startIndex then
            startIndex = #achievementDataList
        end
    end

    return achievementDataList, startIndex
end

function XViewModelTransfiniteAchievement:GetFinishTaskIdList()
    return self._FinishTaskIdList
end

function XViewModelTransfiniteAchievement:UpdateScoreTitle()
    local data = self._DataScoreTitle

    local region = XDataCenter.TransfiniteManager.GetRegion()
    data.NormalTitle = XTransfiniteConfigs.GetRegionRegionName(XTransfiniteConfigs.RegionType.Normal)
    data.NormalIcon = XTransfiniteConfigs.GetRegionIconLv(XTransfiniteConfigs.RegionType.Normal)
    if region:GetIsSeniorRegion() then
        local minLv = XTransfiniteConfigs.GetRegionMinLv(XTransfiniteConfigs.RegionType.Normal)
        local maxLv = XTransfiniteConfigs.GetRegionMaxLv(XTransfiniteConfigs.RegionType.Normal)
        data.NormalLvText = "Lv" .. minLv .. "~" .. maxLv
        --data.SeniorLvText = XUiHelper.GetText("FavorabilityCurrSelected")
        data.SeniorLvText = false
    else
        local minLv = XTransfiniteConfigs.GetRegionMinLv(XTransfiniteConfigs.RegionType.Senior)
        local maxLv = XTransfiniteConfigs.GetRegionMaxLv(XTransfiniteConfigs.RegionType.Senior)
        data.SeniorLvText = "Lv" .. minLv .. "~" .. maxLv
        --data.NormalLvText = XUiHelper.GetText("FavorabilityCurrSelected")
        data.NormalLvText = false
    end
    data.SeniorTitle = XTransfiniteConfigs.GetRegionRegionName(XTransfiniteConfigs.RegionType.Senior)
    data.SeniorIconLv = XTransfiniteConfigs.GetRegionIconLv(XTransfiniteConfigs.RegionType.Senior)
    data.SeniorIsUnlock = region:GetIsSeniorRegion()
    local stageGroup = XDataCenter.TransfiniteManager.GetStageGroup()
    data.Title = stageGroup:GetName()
end

function XViewModelTransfiniteAchievement:GetDataScoreTitle()
    return self._DataScoreTitle
end

return XViewModelTransfiniteAchievement