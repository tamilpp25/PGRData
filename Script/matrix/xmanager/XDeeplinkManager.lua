XDeeplinkManager = XDeeplinkManager or {}

local this = XDeeplinkManager

function this.InvokeDeeplink()
    if CS.XRemoteConfig.DeeplinkEnabled == false then
        return false
    end

    local isMainUi = XLuaUiManager.IsUiShow("UiMain")
    if not isMainUi then
        return false
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        return false
    end

    local deepMgr = CS.XDeeplinkManager;
    if deepMgr.HasDeeplink == false then
        return false
    end
    XFunctionManager.SkipInterface(deepMgr.DeeplinkValue)
    deepMgr.Reset()
    return true
end

function this.TryInvokeDeeplink()
    if CS.XRemoteConfig.DeeplinkEnabled == false then
        return
    end

    if not XLoginManager.IsLogin() then
        return
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    if not CS.XFight.IsOutFight then
        return
    end

    if XHomeDormManager.InDormScene() then
        return
    end

    if XDataCenter.FunctionEventManager.IsPlaying() then
        return
    end

    local deepMgr = CS.XDeeplinkManager;
    if deepMgr.HasDeeplink == false then
        return
    end
    XFunctionManager.SkipInterface(deepMgr.DeeplinkValue)
    deepMgr.Reset()
end