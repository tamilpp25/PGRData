---@class Level.Common.XTaskScheduler @任务计划器
---@field protected _tasks table<number, Level.Common.XTaskScheduler.XTask>
local XTaskScheduler = XClass(nil, "XTaskScheduler")

---@class Level.Common.XTaskScheduler.XTask
---@field public id number
---@field public delayTime number
---@field public countTime number
---@field public complete boolean
---@field public object table
---@field public func function
---@field public funcParam any
local XTask

function XTaskScheduler:Ctor()
    self._tasks = {}
    self._pool = {}
    self._incId = 0
end

function XTaskScheduler:Update(dt)
    for _, task in pairs(self._tasks) do
        task.countTime = task.countTime + dt
        if task.countTime >= task.delayTime then
            if task.func ~= nil then
                XLog.Debug("执行延时任务" .. tostring(task.id) .. "  param" .. tostring(task.funcParam))
                task.func(task.object, task.funcParam)
            end
            task.complete = true
        end
    end

    --清除已完成的任务（倒序遍历，避免迭代器错误
    for i = #self._tasks, 1, -1 do
        local task = self._tasks[i]
        if task.complete then
            self:_ReleaseTask(task)
            table.remove(self._tasks, i)
        end
    end
end

---@param delayTime number
---@param object table
---@param func function
---@param funcParam any
function XTaskScheduler:Schedule(delayTime, object, func, funcParam)
    local task = self:_GetCachedTask()
    task.id = self._incId + 1
    task.delayTime = delayTime
    task.countTime = 0
    task.complete = false
    task.object = object
    task.func = func
    task.funcParam = funcParam

    self._tasks[#self._tasks + 1] = task
    self._incId = task.id
    return task.id
end

function XTaskScheduler:Cancel(taskId)
    local index = 0
    for i = 1, #self._tasks do
        local task = self._tasks[i]
        if task.id == taskId then
            index = i
            break
        end
    end

    if index > 0 then
        local task = self._tasks[index]
        self:_ReleaseTask(task)
        table.remove(self._tasks, index)
    end
end

---获取一个缓存的任务
function XTaskScheduler:_GetCachedTask()
    local task

    if #self._pool > 0 then
        task = self._pool[#self._pool]
        table.remove(self._pool, #self._pool)
    else
        task = {}
        task.id = 0
        task.delayTime = 0
        task.countTime = 0
        task.complete = false
        task.object = nil
        task.func = nil
        task.funcParam = nil
    end

    return task
end

---释放任务对象，加入缓存池，供后续重复利用。
function XTaskScheduler:_ReleaseTask(task)
    task.id = 0
    task.delayTime = 0
    task.countTime = 0
    task.complete = false
    task.object = nil
    task.func = nil
    task.funcParam = nil

    self._pool[#self._pool + 1] = task
end

return XTaskScheduler