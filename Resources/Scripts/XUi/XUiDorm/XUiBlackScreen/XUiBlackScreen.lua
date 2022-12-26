-- 镜头黑幕界面
local XUiBlackScreen = XLuaUiManager.Register(XLuaUi, "UiBlackScreen")

local ADJUST_DISTANCE = 0.2
local FADE_TIME = 0.1
local DURATION_TIME = 0.25

function XUiBlackScreen:OnStart(targetTrans, isTweenCanmera, paramName, cb)
    local distance
    local cameraController = XHomeSceneManager.GetSceneCameraController()

    self.ImgBackground:DOFade(1, FADE_TIME):OnComplete(function()
        if not XTool.UObjIsNil(cameraController) then
            cameraController.IsTweenCamera = false
            if paramName and string.len(paramName) > 0 then
                cameraController:SetParam(paramName)
                distance = cameraController.Distance
            end
            XCameraHelper.SetCameraTarget(cameraController, targetTrans, distance * (ADJUST_DISTANCE + 1))
        end

        if cb then
            cb()
        end

        local isCalled = false
        self.ImgBackground:DOFade(0, FADE_TIME):SetDelay(DURATION_TIME):OnUpdate(function()
            if not isCalled then
                if not XTool.UObjIsNil(cameraController) then
                    cameraController.IsTweenCamera = isTweenCanmera
                    XCameraHelper.SetCameraTarget(cameraController, targetTrans, distance)
                end
                isCalled = true
            end
        end):OnComplete(function()
            self:Close()
        end)
    end)
end