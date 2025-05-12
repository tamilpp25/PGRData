---
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 12:30
---
---

---@class XMVCAEvent
XMVCAEvent = XClass(nil, "XMVCAEvent")

function XMVCAEvent:Ctor()
    self._ListenersMap = {}
    self._DelayRemoveMap = {}
    self._IsRunning = false
    
    self._DelayAdd = {}
end

function XMVCAEvent:Clear()
    self._ListenersMap = {}
    self._DelayRemoveMap = {}
    self._DelayAdd = {}
end

function XMVCAEvent:AddEventListener(eventId, func, obj)
    if self._IsRunning then
        -- 先检查延迟移除字典
        if self._DelayRemoveMap[eventId] and self._DelayRemoveMap[eventId][func] and self._DelayRemoveMap[eventId][func][obj] then
            -- 撤销延迟移除
            self._DelayRemoveMap[eventId][func][obj] = nil
            return
        end
        
        -- 否则，需要先检查是否未注册，未注册才标记为延迟注册
        if not self._ListenersMap[eventId] or not self._ListenersMap[eventId][func] or not self._ListenersMap[eventId][func][obj] then
            self._DelayAdd[eventId] = self._DelayAdd[eventId] or {}
            self._DelayAdd[eventId][func] = self._DelayAdd[eventId][func] or {}
            self._DelayAdd[eventId][func][obj] = true
        end
        return
    end
    
    local listenerList = self._ListenersMap[eventId]
    if (not listenerList) then
        listenerList = {}
    end

    local funcList = listenerList[func]
    if (not funcList) then
        funcList = {}
    end
    funcList[obj] = obj
    listenerList[func] = funcList

    self._ListenersMap[eventId] = listenerList
end

function XMVCAEvent:RemoveEventListener(eventId, func, obj)
    if self._IsRunning then
        -- 先检查延迟添加字典
        if self._DelayAdd[eventId] and self._DelayAdd[eventId][func] and self._DelayAdd[eventId][func][obj] then
            -- 撤销延迟添加
            self._DelayAdd[eventId][func][obj] = nil
            return
        end
        
        -- 否则，需要先检查是否有注册，注册了才标记为延迟移除
        if self._ListenersMap[eventId] and self._ListenersMap[eventId][func] and self._ListenersMap[eventId][func][obj] then
            self._DelayRemoveMap[eventId] = self._DelayRemoveMap[eventId] or {}
            self._DelayRemoveMap[eventId][func] = self._DelayRemoveMap[eventId][func] or {}
            self._DelayRemoveMap[eventId][func][obj] = true
        end
        return
    end
    local listenerList = self._ListenersMap[eventId]
    if (not listenerList) then
        return
    end

    local funcList = listenerList[func]
    if (not funcList) then
        return
    end
    funcList[obj] = nil
    if XTool.IsTableEmpty(funcList) then
        listenerList[func] = nil
    end

    if XTool.IsTableEmpty(listenerList) then
        self._ListenersMap[eventId] = nil
    end
end

function XMVCAEvent:DispatchEvent(eventId, ...)
    local listenerList = self._ListenersMap[eventId]
    if (not listenerList) then
        return
    end
    self._IsRunning = true
    for f, listener in pairs(listenerList) do
        for _, obj in pairs(listener) do
            if not self._DelayRemoveMap[eventId] or not self._DelayRemoveMap[eventId][f] or not self._DelayRemoveMap[eventId][f][obj]
                    or not self._DelayRemoveMap[eventId][f][f] then
                f(obj, ...)
            end
        end
    end
    self._IsRunning = false
    if next(self._DelayRemoveMap) then
        for rmId, rmEventList in pairs(self._DelayRemoveMap) do
            for rmF, rmFunclist in pairs(rmEventList) do
                for obj, _ in pairs(rmFunclist) do
                    self:RemoveEventListener(rmId, rmF, obj)
                end
            end
        end
        self._DelayRemoveMap = {}
    end

    if next(self._DelayAdd) then
        for addId, addEventList in pairs(self._DelayAdd) do
            for addF, addFunclist in pairs(addEventList) do
                for obj, _ in pairs(addFunclist) do
                    self:AddEventListener(addId, addF, obj)
                end
            end
        end
        self._DelayAdd = {}
    end
end