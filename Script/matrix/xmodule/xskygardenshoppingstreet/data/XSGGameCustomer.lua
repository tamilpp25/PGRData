---@class XSGGameCustomer 客户数据
local XSGGameCustomer = XClass(nil, "XSGGameCustomer")
XSGGameCustomer.InitCount = 0

function XSGGameCustomer:Ctor()
    -- 构造函数，初始化计数器
    XSGGameCustomer.InitCount = XSGGameCustomer.InitCount + 1
    -- 设置当前实例的ID
    self._Id = XSGGameCustomer.InitCount
    self._TimerCount = 0
end

--[[
public class XSgStreetCustomerData
{
    public int Id;
    public int CustomerId;
    public List<XSgStreetCustomerTaskData> TaskDatas = new List<XSgStreetCustomerTaskData>();
}
public class XSgStreetCustomerTaskData
{
    public int Id;
    public int TargetId;
    public int Type;
}
]]
function XSGGameCustomer:SetCustomerData(data)
    -- 设置客户数据
    self._Data = data
end

function XSGGameCustomer:IsFinishAllTask()
    -- 判断是否完成所有任务
    return self._RunFinish
end

function XSGGameCustomer:GetCurrentTask()
    -- 获取当前任务
    if self._RunFinish then return end
    return self._Data.CommandDatas[self._RunTaskIndex]
end

function XSGGameCustomer:FinishCurrentTask()
    -- 完成当前任务
    self._RunTaskIndex = self._RunTaskIndex + 1
    -- 更新任务完成状态
    self._RunFinish = #self._Data.CommandDatas < self._RunTaskIndex
end

-- 设置定时器回调
function XSGGameCustomer:SetWaitTime(waiTime, waitFinishCallback)
    -- 设置等待时间和回调函数
    if not waitFinishCallback then return end
    self._TimerCount = self._TimerCount + 1
    -- 将等待时间和回调函数添加到待添加列表中
    table.insert(self._AddWaitInfo, {
        WaitTime = waiTime,
        WaitFinishCallback = waitFinishCallback,
        Id = self._TimerCount,
    })
    -- 设置标志位，表示有等待时间
    self._HasWaitTime = true
    return self._TimerCount
end

-- 移除定时器
function XSGGameCustomer:RemoveWaitTime(timerId)
    for waitIndex, waitInfo in ipairs(self._WaitTimeList) do
        if waitInfo.Id == timerId then
            waitInfo.IsFinish = true
            table.insert(self._RemoveWaitInfo, waitIndex)
        end
    end
end

-- 定时器更新
function XSGGameCustomer:UpdateRunTime(runTime)
    -- 更新运行时间
    if not self._HasWaitTime then return end

    -- 增加任务
    if next(self._AddWaitInfo) then
        for _, waitInfo in ipairs(self._AddWaitInfo) do
            -- 将待添加列表中的任务添加到等待时间列表中
            table.insert(self._WaitTimeList, waitInfo)
        end
        -- 清空待添加列表
        self._AddWaitInfo = {}
    end

    -- 移除任务
    if next(self._RemoveWaitInfo) then
        local removeCount = #self._RemoveWaitInfo
        for i = removeCount, 1, -1 do
            -- 从等待时间列表中移除指定任务
            local index = self._RemoveWaitInfo[i]
            table.remove(self._WaitTimeList, index)
        end
        -- 清空待移除列表
        self._RemoveWaitInfo = {}
        -- 更新标志位，表示是否还有等待时间
        self._HasWaitTime = #self._WaitTimeList > 0
    end

    -- 执行任务
    for waitIndex, waitInfo in ipairs(self._WaitTimeList) do
        -- 更新等待时间
        waitInfo.WaitTime = waitInfo.WaitTime - runTime
        -- 如果任务未完成且等待时间小于等于0，则执行回调函数
        if not waitInfo.IsFinish and waitInfo.WaitTime <= 0 then
            -- 执行回调函数
            local success, err = pcall(waitInfo.WaitFinishCallback, self._NpcId)
            if not success then
                XLog.Warning("Error in callback:", err)
            end
            -- 设置任务完成标志位
            waitInfo.IsFinish = true
            -- 将已完成的任务添加到待移除列表中
            table.insert(self._RemoveWaitInfo, waitIndex)
        end
    end
end

function XSGGameCustomer:IsRunning()
    -- 判断 NPC 是否在运行中
    return self._IsRunning
end

function XSGGameCustomer:RemoveRunning()
    -- 移除运行状态
    self._IsRunning = false
    self._CacheTransform = nil
end

function XSGGameCustomer:SetX3CNpcId(npcId)
    -- 设置 X3C NPC ID
    self._X3CNpcId = npcId
end

function XSGGameCustomer:GetX3CNpcId()
    -- 获取 X3C NPC ID
    return self._X3CNpcId
end

function XSGGameCustomer:CacheTransform(tr)
    -- 缓存变换
    self._CacheTransform = tr
end

function XSGGameCustomer:GetCacheTransform()
    -- 获取缓存的变换
    return self._CacheTransform
end

function XSGGameCustomer:ResetRunData(npcId, waitFinishCallback)
    -- 重置运行数据
    self._RunTaskIndex = 1
    self._RunFinish = false
    self._NpcId = npcId
    self._IsRunning = true
    self._CacheTransform = nil
    self._X3CNpcId = nil
    self._TimerCount = 0

    -- 等待时间
    self._HasWaitTime = false
    self._WaitTimeList = {}
    self._AddWaitInfo = {}
    self._RemoveWaitInfo = {}
end

return XSGGameCustomer
