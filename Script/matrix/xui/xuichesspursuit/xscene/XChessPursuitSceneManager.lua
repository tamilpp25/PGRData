local XChessPursuitSceneManager = {}
local XChessPursuitScene = require("XUi/XUiChessPursuit/XScene/XChessPursuitScene")
local CurrentScene = nil

--返回值：是否重新加载
function XChessPursuitSceneManager.EnterScene(mapId, onLoadCompleteCb, onLeaveCb)
    if CurrentScene then
        local oldConfig = XChessPursuitConfig.GetChessPursuitMapTemplate(CurrentScene.MapId)
        local newConfig = XChessPursuitConfig.GetChessPursuitMapTemplate(mapId)

        if oldConfig.Perfab == newConfig.Perfab then
            CurrentScene:SetOnLeaveCb(onLeaveCb)
            return false
        else
            XChessPursuitSceneManager.LeaveScene()
        end
    end

    local scene = XChessPursuitScene.New(mapId, onLoadCompleteCb, onLeaveCb)

    CurrentScene = scene
    CurrentScene:OnEnterScene()

    return true
end

function XChessPursuitSceneManager.LeaveScene()
    if CurrentScene then
        CurrentScene:OnLeaveScene()
        CurrentScene = nil
    end
end

function XChessPursuitSceneManager.GetCurrentScene()
    return CurrentScene
end

function XChessPursuitSceneManager.SetActive(isShow)
    if CurrentScene then
        CurrentScene.GameObject:SetActiveEx(isShow)
    end
end

return XChessPursuitSceneManager