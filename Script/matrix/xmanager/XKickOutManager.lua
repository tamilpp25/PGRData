XKickOutManagerCreator = function()
    ---@class XKickOutManager
    local XKickOutManager = {}

    local _CurrentVersion = false
    local _IsForceKickOut = false
    local _Lock = XEnumConst.KICK_OUT.LOCK.NONE
    local _IsListening = false

    function XKickOutManager.IsLock()
        return _Lock ~= 0
    end

    function XKickOutManager.Lock(reason)
        _Lock = _Lock | reason
    end

    function XKickOutManager.Unlock(reason, triggerCheck)
        if not XKickOutManager.IsLock() then
            triggerCheck = false
        end
        _Lock = _Lock & (~reason)

        if triggerCheck then
            XKickOutManager.CheckKickOut()
        end
    end

    function XKickOutManager.IsLock()
        -- 战斗的进入和退出入口太多，直接判断
        if XFightUtil.IsFighting() then
            return true
        end
        return _Lock ~= XEnumConst.KICK_OUT.LOCK.NONE
    end

    function XKickOutManager.KickOut()
        local title = XUiHelper.GetText("TipTitle")
        local content = XUiHelper.GetText("KickOutRestart")
        local confirmCb = function()
            CS.XDriver.Exit()
            _IsForceKickOut = false
        end
        XUiManager.SystemDialogTip(title, content, XUiManager.DialogType.OnlySure, nil, confirmCb)
    end

    function XKickOutManager.CheckKickOut(event, ui)
        if not _IsForceKickOut then
            return false
        end
        XKickOutManager.StartListen()
        if XKickOutManager.IsLock() then
            return false
        end
        if XLuaUiManager.IsUiShow("UiSystemDialog") then
            return false
        end
        XKickOutManager.KickOut()
        --XKickOutManager.EndListen()
        return true
    end

    function XKickOutManager.StartListen()
        if _IsListening then
            return
        end
        _IsListening = true
        CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_DISABLE, XKickOutManager.CheckKickOut)
        CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_ENABLE, XKickOutManager.CheckKickOut)
    end

    function XKickOutManager.EndListen()
        _IsListening = false
        CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_DISABLE, XKickOutManager.CheckKickOut)
        CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_ENABLE, XKickOutManager.CheckKickOut)
    end

    function XKickOutManager.CheckVersionNew(version1, version2)
        local paris1 = string.gmatch(version1, "%d+")
        local paris2 = string.gmatch(version2, "%d+")
        for i = 1, 99 do
            local a = paris1()
            a = tonumber(a)
            if not a then
                return false
            end
            local b = paris2()
            b = tonumber(b)
            if not b then
                return true
            end
            if a ~= b then
                return a > b
            end
        end
        return false
    end

    function XKickOutManager.UpdateVersion(version, flag)
        if _CurrentVersion == version then
            return
        end
        if XKickOutManager.CheckVersionNew(version, _CurrentVersion) and flag then
            _CurrentVersion = version
            _IsForceKickOut = true
        end
    end

    function XKickOutManager.OnNotifyVersion(data)
        local version = data.Version
        local flag = data.Flag
        if version == nil or version == "" then
            return
        end
        if flag == nil or flag == "" then
            return
        end
        XKickOutManager.UpdateVersion(version, flag)
        XKickOutManager.CheckKickOut()
    end

    function XKickOutManager.RequestVersion()
        XNetwork.Call("ClientVersionRequest", {  }, function(res)
            local version = res.Version
            local flag = res.Flag
            XKickOutManager.UpdateVersion(version, flag)
            XKickOutManager.CheckKickOut()
        end)
    end

    function XKickOutManager.OnPayEnd()
        XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.RECHARGE, true)
    end

    -- 主界面强制解锁, 并提示
    function XKickOutManager.UnlockAll()
        if _Lock > 0 then
            XLog.Error("[XKickOutManager] 踢人上锁出错:", _Lock)
            _Lock = XEnumConst.KICK_OUT.LOCK.NONE
        end
    end

    function XKickOutManager.Init()
        _CurrentVersion = CS.XRemoteConfig.DocumentVersion
        _IsForceKickOut = false
        _Lock = XEnumConst.KICK_OUT.LOCK.NONE
        _IsListening = false

        XEventManager.AddEventListener(XEventId.EVNET_FAIL_PAY, XKickOutManager.OnPayEnd)
        XEventManager.AddEventListener(XEventId.EVENT_SUCCESS_PAY, XKickOutManager.OnPayEnd)
        XEventManager.AddEventListener(XEventId.EVENT_MAINUI_ENABLE, XKickOutManager.UnlockAll)
        XEventManager.AddEventListener(XEventId.EVENT_NETWORK_RECONNECT, XKickOutManager.RequestVersion)
    end
    XKickOutManager.Init()

    return XKickOutManager
end

XRpc.NotifyClientVersion = function(data)
    XDataCenter.KickOutManager.OnNotifyVersion(data)
end

