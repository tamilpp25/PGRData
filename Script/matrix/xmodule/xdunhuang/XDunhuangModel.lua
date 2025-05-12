local XDunhuangConfigModel = require("XModule/XDunhuang/XDunhuangConfigModel")

---@class XDunhuangModel : XDunhuangConfigModel
local XDunhuangModel = XClass(XDunhuangConfigModel, "XDunhuangModel")
function XDunhuangModel:OnInit()
    XDunhuangConfigModel.OnInit(self)
    self._ActivityId = false
    self._ServerData = false

    ---@type XDunhuangPainting[]
    self._Painting = {}

    ---@type XDunhuangPainting[]
    self._AllPainting = false

    self._PaintingFrameWidth = 0
    self._PaintingFrameHeight = 0

    self._IsDebug = false
    --self:DebugSetActivityId()
end

function XDunhuangModel:DebugSetActivityId()
    if CS.XApplication.Debug then
        if rawget(_G, "TestFile") then
            self._IsDebug = true
            self._ActivityId = 1
        end
    end
end

function XDunhuangModel:ClearPrivate()
    self._Painting = {}
    self._AllPainting = false
end

function XDunhuangModel:ResetAll()
    self._ActivityId = false
    self._ServerData = false
    --self:DebugSetActivityId()
end

function XDunhuangModel:CheckInTime()
    local activityId = self._ActivityId
    if not activityId then
        return false
    end
    local timeId = self:GetConfigActivityTimeId(activityId)
    local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
    return isInTime
end

function XDunhuangModel:GetActivityRemainTime()
    local activityId = self._ActivityId
    local timeId = self:GetConfigActivityTimeId(activityId)
    local currentTime = XTime.GetServerNowTimestamp()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local remainTime = endTime - currentTime
    return remainTime
end

function XDunhuangModel:GetActivityTasks()
    local taskIds = self:GetConfigActivityTaskIds(self._ActivityId)
    if taskIds then

        local tasks = {}
        for _, id in pairs(taskIds) do
            table.insert(tasks, XDataCenter.TaskManager.GetTaskDataById(id))
        end
        XDataCenter.TaskManager.SortTaskList(tasks)
        --return tasks

        -- 添加一键领取
        local allAchieveTasks = {}
        for _, v in pairs(tasks) do
            if v.State == XDataCenter.TaskManager.TaskState.Achieved then
                table.insert(allAchieveTasks, v.Id)
            end
        end

        local finalResultTaskDataList = {}
        if allAchieveTasks and next(allAchieveTasks) then
            finalResultTaskDataList[1] = { ReceiveAll = true, AllAchieveTaskDatas = allAchieveTasks }

            for i = 1, #tasks do
                table.insert(finalResultTaskDataList, tasks[i])
            end
        else
            finalResultTaskDataList = tasks
        end

        return finalResultTaskDataList
    end
    return {}
end

function XDunhuangModel:GetFirstReward()
    local rewardId = self:GetConfigActivityFirstRewardId(self._ActivityId)
    if not rewardId then
        return {}
    end
    local rewardList = XRewardManager.GetRewardList(rewardId)
    local reward = rewardList[1]
    return reward
end

function XDunhuangModel:SetServerData(serverData)
    if not serverData then
        return
    end
    if not serverData.MuralShareDb then
        return
    end
    self._ActivityId = serverData.MuralShareDb.ActivityId
    self._ServerData = serverData.MuralShareDb
end
--+    // 活动Id
--+    public int ActivityId;
--+
--+    //已解锁画卷
--+    public HashSet<int> Paintings = new HashSet<int>();
--+
--+    //解锁画卷数奖励领取记录
--+    public HashSet<int> Rewards = new HashSet<int>();
--+
--+    //分享奖励领取状态
--+    public bool ShareReward;

function XDunhuangModel:GetFinishPaintingAmount()
    local paints = self:GetServerPaintings()
    local amount = 0
    for i, painting in pairs(paints) do
        amount = amount + 1
    end
    return amount
end

function XDunhuangModel:GetMaxPaintingAmount()
    local configs = self:GetConfigsPainting()
    return #configs
end

function XDunhuangModel:IsDebug()
    return self._IsDebug
end

function XDunhuangModel:GetUnlockPainting()
    local paintings = self:GetServerPaintings()
    local list = {}
    for i, paintingId in pairs(paintings) do
        list[#list + 1] = paintingId
    end
    return list
end

function XDunhuangModel:GetUnlockPaintingAmount()
    local paintings = self:GetServerPaintings()
    local amount = 0
    for i, paintingId in pairs(paintings) do
        amount = amount + 1
    end
    return amount
end

function XDunhuangModel:GetPainting(paintingId)
    local painting = self._Painting[paintingId]
    if not painting then
        painting = require("XModule/XDunhuang/Data/XDunhuangPainting").New()
        self._Painting[paintingId] = painting

        local config = self:GetConfigPainting(paintingId)
        painting:SetDataFromConfig(config, self._PaintingFrameWidth, self._PaintingFrameHeight)
    end
    return painting
end

function XDunhuangModel:GetAllPainting()
    if self._AllPainting then
        return self._AllPainting
    end
    local configs = self:GetConfigPaintings()
    local list = {}
    for i, config in pairs(configs) do
        local id = config.Id
        local painting = self:GetPainting(id)
        list[#list + 1] = painting
    end
    self._AllPainting = list
    return list
end

---@param painting XDunhuangPainting
function XDunhuangModel:IsHasPainting(painting)
    local paintings = self:GetServerPaintings()
    for i, paintingId in pairs(paintings) do
        local paintingOwned = self:GetPainting(paintingId)
        if painting:Equals(paintingOwned) then
            return true
        end
    end
    return false
end

---@param painting XDunhuangPainting
function XDunhuangModel:SetPaintingOwned(painting)
    local paintings = self:GetServerPaintings()
    paintings[#paintings + 1] = painting:GetId()
    XEventManager.DispatchEvent(XEventId.EVENT_DUNHUANG_UPDATE_OWN_PAINTING)
end

function XDunhuangModel:GetServerPaintings()
    if not self._ServerData then
        return {}
    end
    if not self._ServerData.Paintings then
        return {}
    end
    return self._ServerData.Paintings
end

function XDunhuangModel:SetPaintingCombination(paintingCombination)
    if not self._ServerData then
        self._ServerData = {}
    end
    self._ServerData.PaintingCombination = paintingCombination
end

---@return XDunhuangPaintingSaveData[]
function XDunhuangModel:GetPaintingsDraw()
    if not self._ServerData then
        return {}
    end
    return self._ServerData.PaintingCombination or {}
end

function XDunhuangModel:IsFirstShare()
    if not self._ServerData then
        return false
    end
    return self._ServerData.ShareReward == false
end

function XDunhuangModel:SetNotFirstShare()
    if not self._ServerData then
        self._ServerData = {}
    end
    self._ServerData.ShareReward = true
    XEventManager.DispatchEvent(XEventId.EVENT_DUNHUANG_UPDATE_SHARE_REWARD)
end

function XDunhuangModel:IsRewardReceived(id)
    local serverData = self._ServerData
    if not serverData then
        return false
    end
    local rewards = serverData.Rewards
    for i = 1, #rewards do
        local rewardId = rewards[i]
        if rewardId == id then
            return true
        end
    end
    return false
end

function XDunhuangModel:SetRewardReceived(rewardId)
    local serverData = self._ServerData
    if not serverData then
        self._ServerData = {}
    end
    self._ServerData.Rewards[#self._ServerData.Rewards + 1] = rewardId
    XEventManager.DispatchEvent(XEventId.EVENT_DUNHUANG_UPDATE_REWARD)
end

function XDunhuangModel:SetPaintingFrameSize(width, height)
    self._PaintingFrameWidth = width
    self._PaintingFrameHeight = height

    for i, painting in pairs(self._Painting) do
        painting:SetFrameSize(width, height)
    end
    if self._AllPainting then
        for i, painting in pairs(self._AllPainting) do
            painting:SetFrameSize(width, height)
        end
    end
end

function XDunhuangModel:GetActivityId()
    return self._ActivityId
end

function XDunhuangModel:GetFirstTimeEnterKey()
    return "DunhuangFirstEnter" .. XPlayer.Id .. self:GetActivityId()
end

function XDunhuangModel:GetIsFirstTimeEnter()
    if not self._ActivityId then
        return false
    end
    local key = self:GetFirstTimeEnterKey()
    return XSaveTool.GetData(key) == nil
end

function XDunhuangModel:IsTaskCanAchieved()
    local tasks = self:GetActivityTasks()
    for i = 1, #tasks do
        local task = tasks[i]
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
    return false
end

function XDunhuangModel:IsPaintingAfford()
    local paintings = self:GetAllPainting()
    for i = 1, #paintings do
        local painting = paintings[i]
        if not self:IsHasPainting(painting) and painting:IsAfford() then
            return true
        end
    end
    return false
end

return XDunhuangModel
