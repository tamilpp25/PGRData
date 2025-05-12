---@class XRestaurantTaskData 演出任务数据
local XRestaurantTaskData = XClass(nil, "XRestaurantTaskData")

function XRestaurantTaskData:Ctor(taskId)
    self.TaskId = taskId
    self.Schedules = {}
end

function XRestaurantTaskData:UpdateData(schedules)
    if not schedules then
        return
    end
    for _, schedule in ipairs(schedules) do
        self.Schedules[schedule.ConditionId] = schedule.Value
    end
end

function XRestaurantTaskData:GetScheduleValue(conditionId)
    return self.Schedules[conditionId] or 0
end

function XRestaurantTaskData:Exist(conditionId)
    return self.Schedules[conditionId] ~= nil
end

function XRestaurantTaskData:GetSchedules()
    return self.Schedules
end

function XRestaurantTaskData:GenerateId(areaType, productId)
    return areaType * 10000 + productId
end

--- 更新需要制作的产品任务数据
--------------------------
function XRestaurantTaskData:UpdateProductAdd(conditionId, paramPId, paramCId, areaType, productId, characterId, count)
    if not self:Exist(conditionId) then
        return
    end
    if paramCId ~= characterId and XTool.IsNumberValid(paramCId) then
        return
    end
    local newId = self:GenerateId(areaType, productId)
    if newId ~= paramPId then
        return
    end
    local oldCount = self:GetScheduleValue(conditionId)
    count = math.max(0, count)
    oldCount = oldCount + count
    
    self.Schedules[conditionId] = oldCount
end

--- 更新需要制作的产品任务数据, 消耗时，count是负数
--------------------------
function XRestaurantTaskData:UpdateProductConsume(conditionId, paramId, paramCId, areaType, productId, characterId, 
                                                  count)
    if not self:Exist(conditionId) then
        return
    end

    if paramCId ~= characterId and XTool.IsNumberValid(paramCId) then
        return
    end

    local newId = self:GenerateId(areaType, productId)
    if newId ~= paramId then
        return
    end
    local oldCount = self:GetScheduleValue(conditionId)
    count = math.min(0, count)
    oldCount = oldCount - count
    
    self.Schedules[conditionId] = oldCount
end

--- 更新需要制作N个当日热销菜品
--------------------------
function XRestaurantTaskData:UpdateHotSaleProductAdd(conditionId, isHot, count)
    if not self:Exist(conditionId) then
        return
    end

    if not isHot then
        return
    end
    
    local oldCount = self:GetScheduleValue(conditionId)
    count = math.max(0, count)
    oldCount = oldCount + count
    
    self.Schedules[conditionId] = oldCount
end

--- 更新需要制作N个当日热销菜品, 消耗时，count是负数
--------------------------
function XRestaurantTaskData:UpdateHotSaleProductConsume(conditionId, isHot, count)
    if not self:Exist(conditionId) then
        return
    end

    if not isHot then
        return
    end
    
    local oldCount = self:GetScheduleValue(conditionId)
    count = math.min(0, count)
    oldCount = oldCount - count
    
    self.Schedules[conditionId] = oldCount
end

function XRestaurantTaskData:UpdateSubmitProduct(conditionId, paramId, areaType, productId, total)
    if not self:Exist(conditionId) then
        return
    end
    local newId = self:GenerateId(areaType, productId)
    if newId ~= paramId then
        return
    end
    self.Schedules[conditionId] = total
end


local XRestaurantData = require("XModule/XRestaurant/XData/XRestaurantData")

local RestaurantPerformPhotoKey = "RESTAURANT_PERFORM_PHOTO_KEY"

---@class XRestaurantPerformProperty
local Properties = {
    Id = "Id",
    Type = "Type",
    State = "State",
    TaskInfos = "TaskInfos",
    UpdateTime = "UpdateTime",
    PhotoFileName = "PhotoFileName",
    PerformStoryInfo = "PerformStoryInfo",
}

---@class XRestaurantPerformData : XRestaurantData
---@field ViewModel XRestaurantPerformVM
local XRestaurantPerformData = XClass(XRestaurantData, "XRestaurantPerformData")

function XRestaurantPerformData:InitData(id)
    local key
    if XMVCA.XRestaurant and XMVCA.XRestaurant.GetCookiesKey then
        key = XMVCA.XRestaurant:GetCookiesKey(RestaurantPerformPhotoKey)
    end
    self.Data = {
        Id = id,
        Type = 0,--XMVCA.XRestaurant.PerformType.Indent,
        State = 0,--XMVCA.XRestaurant.PerformState.NotStart,
        TaskInfos = {},
        PerformStoryInfo = {},
        UpdateTime = 0,
        PhotoFileName = (key and XSaveTool.GetData(key)) or "",
    }
end

function XRestaurantPerformData:GetPropertyNameDict()
    return Properties
end

function XRestaurantPerformData:UpdateData(perform)
    self:SetProperty(Properties.Id, perform.PerformId)
    self:SetProperty(Properties.Type, perform.Type)
    self:SetProperty(Properties.UpdateTime, perform.UpdateTime)
    self:SetProperty(Properties.PerformStoryInfo, perform.PerformStoryInfo)
    self:SetTaskInfos(perform.TaskInfos)
    self:SetState(perform.State)

    if self.ViewModel then
        self.ViewModel:UpdateViewModel()
    end
end

function XRestaurantPerformData:SetTaskInfos(taskInfos)
    local taskDict = self:GetProperty(Properties.TaskInfos)
    if not taskDict then
        taskDict = {}
    end
    for _, taskInfo in ipairs(taskInfos) do
        local id = taskInfo.TaskId
        local task = taskDict[id]
        if not task then
            task = XRestaurantTaskData.New(id)
            taskDict[id] = task
        end
        task:UpdateData(taskInfo.ConditionSchedules)
    end
    
    self:SetProperty(Properties.TaskInfos, taskDict)
end

---@return XRestaurantTaskData
function XRestaurantPerformData:GetTaskInfo(taskId)
    local taskDict = self:GetProperty(Properties.TaskInfos)
    local data = taskDict[taskId]
    if not data then
        data = XRestaurantTaskData.New(taskId)
        taskDict[taskId] = data
    end
    return data
end

function XRestaurantPerformData:UpdateTaskInfo(taskId, schedules)
    local data = self:GetTaskInfo(taskId)
    if not data then
        return
    end
    data:UpdateData(schedules)
end

function XRestaurantPerformData:SetPhotoName(value)
    self:SetProperty(Properties.PhotoFileName, value)
    local key = XMVCA.XRestaurant:GetCookiesKey(RestaurantPerformPhotoKey)
    XSaveTool.SaveData(key, value)
end

function XRestaurantPerformData:GetPhotoName()
    return self:GetProperty(Properties.PhotoFileName)
end

function XRestaurantPerformData:GetPerformId()
    return self:GetProperty(Properties.Id)
end

function XRestaurantPerformData:GetState()
    return self:GetProperty(Properties.State)
end

function XRestaurantPerformData:GetType()
    return self:GetProperty(Properties.Type)
end

function XRestaurantPerformData:GetUpdateTime()
    return self:GetProperty(Properties.UpdateTime)
end

function XRestaurantPerformData:SetState(state)
    self:SetProperty(Properties.State, state)
end

function XRestaurantPerformData:IsFinish()
    return self:GetState() == XMVCA.XRestaurant.PerformState.Finish
end

function XRestaurantPerformData:IsNotStart()
    return self:GetState() == XMVCA.XRestaurant.PerformState.NotStart
end

function XRestaurantPerformData:IsOnGoing()
    return self:GetState() == XMVCA.XRestaurant.PerformState.OnGoing
end

function XRestaurantPerformData:GetStoryInfo()
    return self:GetProperty(Properties.PerformStoryInfo)
end

---@class XRestaurantPerformMgt 演出管理
---@field _PerformDict table<number, XRestaurantPerformData>
local XRestaurantPerformMgt = XClass(nil, "XRestaurantPerformMgt")

function XRestaurantPerformMgt:Ctor()
    self._PerformDict = {}
end

function XRestaurantPerformMgt:UpdateData(performs, notifyCb)
    if not performs then
        return
    end

    local notStartPId, notStartIId = 0, 0
    local runningPId, runningId = 0, 0
    local PerformType = XMVCA.XRestaurant.PerformType
    for _, perform in ipairs(performs) do
        local id = perform.PerformId
        local data = self:TryGetPerform(id)
        data:UpdateData(perform)
        if data:IsNotStart() then
            local type = data:GetType()
            if type == PerformType.Indent then
                notStartIId = id
            elseif type == PerformType.Perform then
                notStartPId = id
            end
        elseif data:IsOnGoing() then
            local type = data:GetType()
            if type == PerformType.Indent then
                runningId = id
            elseif type == PerformType.Perform then
                runningPId = id
            end
        end
    end

    notifyCb(notStartIId, runningId, notStartPId, runningPId)
end

function XRestaurantPerformMgt:GetUnlockCount(checkType)
    if not self._PerformDict then
        return 0
    end
    local count = 0
    checkType = checkType or XMVCA.XRestaurant.PerformType.Indent
    for _, data in pairs(self._PerformDict) do
        if (not data:IsNotStart()) and data:GetType() == checkType then
            count = count + 1
        end
    end
    return count
end

--- 获取演出数据
---@param performId number
---@return XRestaurantPerformData
--------------------------
function XRestaurantPerformMgt:TryGetPerform(performId)
    if not self._PerformDict then
        self._PerformDict = {}
    end

    if self._PerformDict[performId] then
        return self._PerformDict[performId]
    end
    
    local data = XRestaurantPerformData.New(performId)

    self._PerformDict[performId] = data
    
    return data
end

return XRestaurantPerformMgt

