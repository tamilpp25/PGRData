XHomeSceneManager = XHomeSceneManager or {}

HomeSceneViewType = {
    OverView = 0, --总览
    RoomView = 1, --房间视角
    DeviceView = 2, --设备视角
}

HomeSceneLayerMask = {
    Room = "Room",
    Device = "Device",
    HomeSurface = "HomeSurface",
    Block = "Block",
    HomeCharacter = "HomeCharacter",
}

local CurrentScene = nil
local CurrentView = HomeSceneViewType.OverView

function XHomeSceneManager.Init()
    --TODO
end

function XHomeSceneManager.EnterScene(sceneName, sceneAssetUrl,onLoadCompleteCb, onLeaveCb)
    if CurrentScene and CurrentScene.Name == sceneName then
        return
    end

    local scene = XHomeScene.New(sceneName, sceneAssetUrl, onLoadCompleteCb, onLeaveCb)

    XLuaUiManager.Open("UiLoading", LoadingType.Dormitory)
    CS.UnityEngine.Resources.UnloadUnusedAssets()
    XHomeSceneManager.LeaveScene()
    CurrentScene = scene
    CurrentScene:OnEnterScene()
    CurrentView = HomeSceneViewType.OverView
end

function XHomeSceneManager.LeaveScene()
    if CurrentScene then
        CurrentScene:OnLeaveScene()
        -- 清除宿舍本地图片缓存
        XDataCenter.DormManager.ClearLocalCaptureCache()
        CurrentScene = nil
    end
end

function XHomeSceneManager.GetCurrentScene()
    return CurrentScene
end

function XHomeSceneManager.GetSceneCamera()
    if CurrentScene then
        return CurrentScene:GetCamera()
    end
    return nil
end

function XHomeSceneManager.GetSceneCameraController()
    if CurrentScene then
        return CurrentScene:GetCameraController()
    end
    return nil
end

function XHomeSceneManager.ChangeAngleYAndYAxis(angleY, isAllowYAxis)
    local cameraController = XHomeSceneManager.GetSceneCameraController()
    if not XTool.UObjIsNil(cameraController) then
        if angleY > 0 then
            cameraController.TargetAngleY = angleY
        end
        cameraController.AllowYAxis = isAllowYAxis
    end
end

function XHomeSceneManager.EnterShare(homeRoomData)
    if not homeRoomData then
        return
    end

    local cameraController = XHomeSceneManager.GetSceneCameraController()
    if not XTool.UObjIsNil(cameraController) then
        local imgName = tostring(XPlayer.Id) .. tostring(homeRoomData:GetShareId()) .. XDormConfig.ShareName
        local texture = cameraController:CaptureCamera(imgName, true)
        XDataCenter.DormManager.SetLocalCaptureCache(imgName, texture)
        XLuaUiManager.Open("UiDormTemplateShare", homeRoomData, texture)
    end
end

function XHomeSceneManager.CaptureCamera(imgName, isBig)
    if not imgName then
        return nil
    end

    local texture = nil
    local cameraController = XHomeSceneManager.GetSceneCameraController()
    if not XTool.UObjIsNil(cameraController) then
        local captrueAngleX = XDormConfig.CaptureAngleX
        local captrueAngleY = XDormConfig.CaptureAngleY
        local captrueDistance = XDormConfig.CaptureDistance

        local oldIsTweenCamera = cameraController.IsTweenCamera
        local oldTargetAngleX = cameraController.TargetAngleX
        local oldTargetAngleY = cameraController.TargetAngleY
        local oldDistance = cameraController.Distance

        local minDistance = cameraController.MinDistance
        local maxDistance = cameraController.MaxDistance

        -- 设置摄像机参数
        cameraController.IsTweenCamera = false
        if captrueDistance > maxDistance then
            cameraController.MaxDistance = captrueDistance
        end
        if captrueDistance < minDistance then
            cameraController.MinDistance = captrueDistance
        end
        cameraController.TargetAngleX = captrueAngleX
        cameraController.TargetAngleY = captrueAngleY
        cameraController.Distance = captrueDistance

        -- 截屏
        texture = cameraController:CaptureCamera(imgName, isBig)
        XDataCenter.DormManager.SetLocalCaptureCache(imgName, texture)

        XScheduleManager.ScheduleOnce(function()
            --还原摄像机参数
            cameraController.MaxDistance = maxDistance
            cameraController.MinDistance = minDistance
            cameraController.TargetAngleX = oldTargetAngleX
            cameraController.TargetAngleY = oldTargetAngleY
            cameraController.Distance = oldDistance
            cameraController.IsTweenCamera = oldIsTweenCamera
        end, 500)

        return texture
    end

    return texture
end

function XHomeSceneManager.ChangeView(viewType)
    CurrentView = viewType
    local mask = XHomeSceneManager.GetLayerMask()
    if CurrentScene then
        CurrentScene:SetRaycasterMask(mask)
    end
end

function XHomeSceneManager.GetCurrentView()
    return CurrentView
end

function XHomeSceneManager.GetLayerMask()
    if (CurrentView == HomeSceneViewType.OverView) then
        return CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.Room)
    elseif (CurrentView == HomeSceneViewType.RoomView) then
        return CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.Device) | CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.HomeCharacter)
    else
        return nil
    end
end

function XHomeSceneManager.ChangeBackToOverView()
    if CurrentView == HomeSceneViewType.OverView then
        return false
    end
    CurrentScene:ChangeCameraToScene(function()
        XHomeSceneManager.ChangeView(HomeSceneViewType.OverView)
    end)
    return true
end

function XHomeSceneManager.ChangeSceneView(sceneId, cb)
    CurrentScene:ChangeCameraToSceneById(sceneId, cb)
    XHomeSceneManager.SetGlobalIllumSO(CS.XGame.ClientConfig:GetString("HomeSceneSoAssetUrl"))
end

function XHomeSceneManager.IsInHomeScene()
    return CurrentScene ~= nil
end

----------------------------光照信息接口 start-----------------------------
-- 设置场景光照信息
--function XHomeSceneManager.SetSceneType(sceneType)
--    XLog.Error(sceneType)
--    if CurrentScene then
--        CurrentScene:SetSceneType(sceneType)
--    end
--end
--
-- 重置为当前光照场景类型
--function XHomeSceneManager.ResetToCurrentSceneType()
--    if CurrentScene then
--        CurrentScene:ResetToCurrentSceneType()
--    end
--end

-- 设置全局光照
function XHomeSceneManager.SetGlobalIllumSO(soPath)
    if CurrentScene then
        CurrentScene:SetGlobalIllumSO(soPath)
    end
end

-- 重置为当前场景全局光
function XHomeSceneManager.ResetToCurrentGlobalIllumination()
    if CurrentScene then
        CurrentScene:ResetToCurrentGlobalIllumination()
    end
end
----------------------------光照信息接口 end-----------------------------