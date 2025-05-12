XUiQueueManagerCreator = function()
    ---@class XUiQueueManager
    local XUiQueueManager = {}

    ---@type XQueue
    local _Queue = XQueue.New()
    -- local _TimerTimeOut = nil
    -- local _TimeOut = 300000 -- 5分钟 5*60*1000 = 300000

    function XUiQueueManager.Debug()
        XLog.Error(_Queue)
        -- XLog.Error(_TimerTimeOut)
    end

    function XUiQueueManager.CallFunc(uiName, func, ...)
        if _Queue:IsEmpty() then
            func(...)
            local element = {
                UiName = uiName,
                Func = func,
                IsOpened = true,
            }
            _Queue:Enqueue(element)
            XUiQueueManager._StartListen()
            return
        end

        local element = {
            UiName = uiName,
            Func = func,
            PackData = table.pack(...),
            IsOpened = false,
        }
        _Queue:Enqueue(element)
        XUiQueueManager._StartListen()
    end

    function XUiQueueManager.Open(uiName, ...)
        if _Queue:IsEmpty() then
            XLuaUiManager.Open(uiName, ...)
            local element = {
                UiName = uiName,
                IsOpened = true,
            }
            _Queue:Enqueue(element)
            XUiQueueManager._StartListen()
            return
        end

        ---@class XUiQueueElement
        local element = {
            UiName = uiName,
            PackData = table.pack(...),
            IsOpened = false,
        }
        _Queue:Enqueue(element)
        XUiQueueManager._StartListen()
    end

    function XUiQueueManager._CheckNextUi()
        local CSUiManager = CS.XUiManager.Instance
        -- 关闭中
        if CSUiManager.ClosingAll then
            _Queue:Clear()
            XUiQueueManager._StopListen()
            XLog.Warning("[XUiQueueManager] Clear Queue")
            return
        end
        if CSUiManager.PoppingAll then
            return
        end
        if _Queue:IsEmpty() then
            XUiQueueManager._StopListen()
            return
        end
        ---@type XUiQueueElement
        local nextElement = _Queue:Peek()
        if nextElement.IsOpened then
            return
        end
        nextElement.IsOpened = true
        if nextElement.Func then
            nextElement.Func(table.unpack(nextElement.PackData))
            nextElement.Func = nil
        else
            if nextElement.PackData then
                XLuaUiManager.Open(nextElement.UiName, table.unpack(nextElement.PackData))
            else
                XLuaUiManager.Open(nextElement.UiName)
            end
        end
    end

    function XUiQueueManager._OnUiChanged()
        ---@type XUiQueueElement
        local element = _Queue:Peek()
        if element and not XLuaUiManager.IsUiLoad(element.UiName) then
            _Queue:Dequeue()
        end
        XUiQueueManager._CheckNextUi()
    end

    -- function XUiQueueManager._OnTimeOut()
    --     _Queue:Dequeue()
    --     if _Queue:IsEmpty() then
    --         XUiQueueManager._StopListen()
    --     end
    -- end

    function XUiQueueManager._OnMainUiEnable()
        XUiQueueManager._CheckNextUi()
    end

    function XUiQueueManager._StartListen()
        -- if not _TimerTimeOut then
        --     _TimerTimeOut = XScheduleManager.ScheduleForever(XUiQueueManager._OnTimeOut, _TimeOut)
        -- end
        CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_ENABLE, XUiQueueManager._OnUiChanged)
        XEventManager.AddEventListener(XEventId.EVENT_UI_DESTROY, XUiQueueManager._OnUiChanged)
        XEventManager.AddEventListener(XEventId.EVENT_MAINUI_ENABLE, XUiQueueManager._OnMainUiEnable)
    end

    function XUiQueueManager._StopListen()
        -- if _TimerTimeOut then
        --     XScheduleManager.UnSchedule(_TimerTimeOut)
        --     _TimerTimeOut = nil
        -- end
        CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_ENABLE, XUiQueueManager._OnUiChanged)
        XEventManager.RemoveEventListener(XEventId.EVENT_UI_DESTROY, XUiQueueManager._OnUiChanged)
        XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_ENABLE, XUiQueueManager._OnMainUiEnable)
    end

    return XUiQueueManager
end