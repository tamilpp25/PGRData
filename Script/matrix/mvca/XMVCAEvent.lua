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
end

function XMVCAEvent:Clear()
    self._ListenersMap = {}
    self._DelayRemoveMap = {}
end

function XMVCAEvent:AddEventListener(eventId, func, obj)
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
        self._DelayRemoveMap[eventId] = self._DelayRemoveMap[eventId] or {}
        self._DelayRemoveMap[eventId][func] = self._DelayRemoveMap[eventId][func] or {}
        self._DelayRemoveMap[eventId][func][obj] = true
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
    local tempList = {}
    for f,listener in pairs(listenerList) do
        tempList[f] = {}
        for _,obj in pairs(listener) do
            tempList[f][obj] = obj
        end
    end
    for f, listener in pairs(tempList) do
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
end