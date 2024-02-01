---@class Level.Common.XTaskScheduler @任务计划器
---@field protected _tasks table<number, Level.Common.XTaskScheduler.XTask>
local XTaskScheduler = XClass(nil, "XTaskScheduler")

---@class Level.Common.XTaskScheduler.XTask
---@field public Id number
---@field public DelayTime number
---@field public CountTime number
---@field public Complete boolean
---@field public Object table
---@field public Func function
---@field public FuncParam any
local XTask

function XTaskScheduler:Ctor()
    self._tasks = {}
    self._pool = {}
    self._incId = 0
end

function XTaskScheduler:Update(dt)
    for _, task in pairs(self._tasks) do
        task.CountTime = task.CountTime + dt
        if task.CountTime >= task.DelayTime then
            if task.Func ~= nil then
                --XLog.Debug("执行延时任务:" .. tostring(task.Id) .. "  param:" .. tostring(task.FuncParam))
                task.Func(task.Object, task.FuncParam)
            end
            task.Complete = true
        end
    end

    --清除已完成的任务（倒序遍历，避免迭代器错误
    for i = #self._tasks, 1, -1 do
        local task = self._tasks[i]
        if task.Complete then
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
    task.Id = self._incId + 1
    task.DelayTime = delayTime
    task.CountTime = 0
    task.Complete = false
    task.Object = object
    task.Func = func
    task.FuncParam = funcParam

    self._tasks[#self._tasks + 1] = task
    self._incId = task.Id
    return task.Id
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
---@return Level.Common.XTaskScheduler.XTask
function XTaskScheduler:_GetCachedTask()
    local task---@type Level.Common.XTaskScheduler.XTask

    if #self._pool > 0 then
        task = self._pool[#self._pool]
        table.remove(self._pool, #self._pool)
    else
        task = {}
        task.Id = 0
        task.DelayTime = 0
        task.CountTime = 0
        task.Complete = false
        task.Object = nil
        task.Func = nil
        task.FuncParam = nil
    end

    return task
end

---释放任务对象，加入缓存池，供后续重复利用。
---@param task Level.Common.XTaskScheduler.XTask
function XTaskScheduler:_ReleaseTask(task)
    task.Id = 0
    task.DelayTime = 0
    task.CountTime = 0
    task.Complete = false
    task.Object = nil
    task.Func = nil
    task.FuncParam = nil

    self._pool[#self._pool + 1] = task
end

return XTaskScheduler