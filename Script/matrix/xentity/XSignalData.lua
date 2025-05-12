--######################## 独立事件系统，用于提供信号机制拥有独立处理事件的功能 ########################
local XEventSystem = XClass(nil, "XEventSystem")

function XEventSystem:Ctor( )
	self._handlers = {}
end

-- 注册事件
-- @params keepEvent : bool 常驻事件，不会被清除
function XEventSystem:Push( eventType, caller, callback, keepEvent, returnArgKey)
	assert(eventType and callback, "XEventSystem:Push fail. eventType or callback cannot be empty")
	local handler = self._handlers[eventType]
	if not handler then
		handler = {}
        self._handlers[eventType] = handler
    end
    table.insert(
        handler,
        1,
        {
            eventType = eventType,
            caller = caller,
            callback = callback,
            keepEvent = keepEvent,
            returnArgKey = returnArgKey
        }
    )
end

function XEventSystem:_PopWithHandler( handler, ignoreCaller, caller )
    if not handler then
        return
    end
    for i = #handler, 1, -1 do
        if ignoreCaller or handler[i].caller == caller then
            -- 判断是否常驻事件
            if not handler[i].keepEvent then
                table.remove(handler, i)
            end
        end
    end
end

function XEventSystem:PopWithEventType( eventType )
    self:_PopWithHandler(self._handlers[eventType], true)
end

function XEventSystem:PopWithCaller( caller )
	for _, handler in pairs(self._handlers) do
        self:_PopWithHandler(handler, false, caller)
    end
end

function XEventSystem:Call( eventType, ... )
    local callResult = nil
	local handler = self._handlers[eventType]
	if nil == handler then
        return callResult
    end
    local msgData
    for i=#handler, 1, -1 do
    	msgData = handler[i]
        if msgData then
            local tmpResult = msgData.callback(msgData.caller, ...)
            -- 如果被通知的事件方法有返回值并注册时显示传入返回结果的key，丢进callResult里返回调用者进行下一步处理
            if tmpResult and msgData.returnArgKey then
                if callResult == nil then callResult = {} end
                -- 小优化:可判断是否存在相同key进行报错或警告处理
                callResult[msgData.returnArgKey] = tmpResult
            end
        end
    end
    return callResult
end

function XEventSystem:ClearAll()
    for _, handler in pairs(self._handlers) do
        self:_PopWithHandler(handler, true)
    end
end

--######################## 信号数据 ########################
XSignalCode = {
    SUCCESS = 0,
    EMPTY_FROM_OBJ = 1, -- 等待信号的对象已被置为null
    RELEASE = 2, -- 信号拥有者已被释放，如果是XLuaUi被关闭时也会触发此code，因为有部分Ui代码直接判断RELEASE来获取Ui是否关闭
    EMPTY_UI = 3, -- 针对Ui，Ui信号拥有者为null。PS:这块可以统一成EMPTY_FROM_OBJ
}
---@class XSignalData
XSignalData = XClass(nil, "XSignalData")

function XSignalData:Ctor()
    self.SignalMap = {}
    self.EventSystem = XEventSystem.New()
end

function XSignalData:ConnectSignal(signalName, caller, callback, returnArgKey)
    if self.EventSystem == nil then return end
    self.EventSystem:Push(signalName, caller, callback, nil, returnArgKey)
end

function XSignalData:RemoveConnectSignalWithName(signalName)
    if self.EventSystem == nil then return end
    self.EventSystem:PopWithEventType(signalName)
end

-- 等待信号，必选放在RunAsyn方法内才会起作用
-- signalName: 等待的信号名
-- fromObj: 在等待该信号的对象
function XSignalData:AwaitSignal(signalName, fromObj)
    self.SignalMap[signalName] = self.SignalMap[signalName] or {}
    -- 获取正在运行的协程
    local running = coroutine.running()
    -- 注册正在挂起的协程
    table.insert(self.SignalMap[signalName], {
        running = running,
        fromObj = fromObj
    })
    -- 挂起协程，直到等到信号回来
    return coroutine.yield()
end

-- 检查是否有signalName信号，如果不传fromObj则不判断fromObj
function XSignalData:CheckHasSignal(signalName, fromObj)
    local signalData = self.SignalMap[signalName]
    if not signalData then return false end
    if fromObj == nil then return true end
    for _, v in ipairs(signalData) do
        if v.fromObj == fromObj then
            return true
        end
    end
    return false
end

-- 发射信号，通知已注册的事件（ConnectSignal）调用回调或解除已挂起的协程（AwaitSignal）继续往下运行
function XSignalData:EmitSignal(signalName, ...)
    local result = nil
    -- 发送事件
    result = self.EventSystem:Call(signalName, ...)
    -- 处理信号
    local signalData = self.SignalMap[signalName]  
    -- 如果没有对应的信号处理直接返回
    if XTool.IsTableEmpty(signalData) then
        return result
    end
    local tmpData, code
    for i = #signalData, 1, -1 do
        tmpData = signalData[i]
        -- 如果状态没有运行完主体函数或因错误停止的话，恢复协程
        if coroutine.status(tmpData.running) ~= "dead" then
            -- 可优化的点：如果fromObj为nil的时候直接不处理即可，但这里需要测试一下不处理后积攒了大量挂起的协程会有什么影响，目前这个写法判空是为了尽量让所有活着的协程都尽量恢复。
            code = tmpData.fromObj ~= nil and XSignalCode.SUCCESS or XSignalCode.EMPTY_FROM_OBJ
            coroutine.resume(tmpData.running, code, ...) 
        end
        table.remove(signalData, i)
    end
    signalData = nil
    -- 可能主体函数已经关闭了子界面，导致子界面的信号map被清空，这里需要判断一下
    if self.SignalMap then
        self.SignalMap[signalName] = nil
    end
    return result
end

-- function XSignalData:EmitSingleSignal(signalName, ...)
--     local signalData = self.SignalMap[signalName]  
--     if XTool.IsTableEmpty(signalData) then
--         return
--     end
--     local code
--     local tmpData = signalData[#signalData]
--     if coroutine.status(tmpData.running) ~= "dead" then
--         code = tmpData.fromObj ~= nil and XSignalCode.SUCCESS or XSignalCode.EMPTY_FROM_OBJ
--         coroutine.resume(tmpData.running, code, ...) 
--     end
--     table.remove(signalData, #signalData)
--     if #signalData <= 0 then
--         signalData = nil
--         self.SignalMap[signalName] = nil
--     end
-- end

function XSignalData:Release()
    if self.EventSystem then
        self.EventSystem:ClearAll()
        self.EventSystem = nil
    end
    if self.SignalMap == nil then
        return
    end
    -- 释放时，全部发送出去，避免挂着无效的程序，错误由收信号方处理
    for name, signalData in pairs(self.SignalMap) do
        for i = #signalData, 1, -1 do
            if coroutine.status(signalData[i].running) ~= "dead" then
                coroutine.resume(signalData[i].running, XSignalCode.RELEASE)
            end
            table.remove(signalData, i)
        end
        signalData = nil
    end
    self.SignalMap = nil
end