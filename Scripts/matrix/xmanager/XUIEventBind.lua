XUIEventBind = XUIEventBind or {}

local ListenersMap = {}
local DelayRemoveMap = {}
local IsRunning = false

function XUIEventBind.AddEventListener(eventId, func, obj)
    local listenerList = ListenersMap[eventId]
    if (not listenerList) then
        listenerList = {}
    end

    local funcList = listenerList[func]
    if (obj) then
        if (not funcList) then
            funcList = {}
        end
        funcList[obj] = obj
        listenerList[func] = funcList
    else
        listenerList[func] = func
    end

    ListenersMap[eventId] = listenerList
    return { eventId, func, obj }
end

function XUIEventBind.RemoveEventListener(eventId, func, obj)
    if IsRunning then
        DelayRemoveMap[eventId] = DelayRemoveMap[eventId] or {}
        DelayRemoveMap[eventId][func] = DelayRemoveMap[eventId][func] or {}
        if obj then
            DelayRemoveMap[eventId][func][obj] = true
        else
            DelayRemoveMap[eventId][func][func] = true
        end
        return
    end
    local listenerList = ListenersMap[eventId]
    if (not listenerList) then
        return
    end

    local funcList = listenerList[func]
    if (obj) then
        if (not funcList) then
            return
        end
        funcList[obj] = nil
        if XTool.IsTableEmpty(funcList) then
            listenerList[func] = nil
        end
    else
        listenerList[func] = nil
    end

    if XTool.IsTableEmpty(listenerList) then
        ListenersMap[eventId] = nil
    end
end

function XUIEventBind.RemoveAllListener()
    ListenersMap = {}
end

function XUIEventBind.DispatchEvent(eventId, ...)
    local listenerList = ListenersMap[eventId]
    if (not listenerList) then
        return
    end
    IsRunning = true
    local tempList = {}
    for f,listener in pairs(listenerList) do
        tempList[f] = {}
        if (type(listener) == "table") then
            for _,obj in pairs(listener) do
                tempList[f][obj] = obj
            end
        else
            tempList[f] = f
        end
    end
    for f, listener in pairs(tempList) do
        if (type(listener) == "table") then
            for _, obj in pairs(listener) do
                if not DelayRemoveMap[eventId] or not DelayRemoveMap[eventId][f] or not DelayRemoveMap[eventId][f][obj]
                or not DelayRemoveMap[eventId][f][f] then
                    f(obj, eventId, ...)
                end
            end
        else
            if not DelayRemoveMap[eventId] or not DelayRemoveMap[eventId][f] or not DelayRemoveMap[eventId][f][f] then
                f(eventId, ...)
            end
        end
    end
    IsRunning = false
    if next(DelayRemoveMap) then
        for rmId, rmEventList in pairs(DelayRemoveMap) do
            for rmF, rmFunclist in pairs(rmEventList) do
                for obj, _ in pairs(rmFunclist) do
                    if obj == rmF then
                        XUIEventBind.RemoveEventListener(rmId, rmF)
                    else
                        XUIEventBind.RemoveEventListener(rmId, rmF, obj)
                    end
                end
            end
        end
        DelayRemoveMap = {}
    end
end