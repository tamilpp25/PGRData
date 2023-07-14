local XLaunchUiModule = {}
local LAUNCH_UI = "XLaunchUi/XLaunchUi"
local LAUNCH_UI_PREFAB = "Assets/Launch/Ui/Prefab/UiLaunch.prefab"
local hot_ui_ctor = require(LAUNCH_UI)

function XLaunchUiModule.RegisterLaunchUi()
    local success = CS.XUiManager.Instance:Register("UiLaunch", CS.XUiType.Normal, CS.XUiResType.Bundle, true, LAUNCH_UI_PREFAB, nil, nil, 0, false, false)
    if not success then
        CS.XLog.Error("注册UI: UiLaunch 失败!!")
    end
    return success
end

function XLaunchUiModule.NewLaunchUi(uiName, uiProxy)
    if uiName == "UiLaunch" then
        local ui = hot_ui_ctor()
        ui:Ctor(uiName, uiProxy)
        return ui
    end

    return nil
end

return XLaunchUiModule