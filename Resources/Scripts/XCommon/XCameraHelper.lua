XCameraHelper = XCameraHelper or {}

function XCameraHelper.SetCameraTarget(cameraCtrl, targetTrans, distance)
    if cameraCtrl and cameraCtrl:Exist() then
        distance = distance or 0
        cameraCtrl:SetLookAt(targetTrans, distance)
    end
end

XCameraHelper.SCREEN_SHOT_WIDTH = 1920;
XCameraHelper.SCREEN_SHOT_HEIGHT = 1080;
XCameraHelper.DefaultRect = CS.UnityEngine.Rect(0, 0, XCameraHelper.SCREEN_SHOT_WIDTH, XCameraHelper.SCREEN_SHOT_HEIGHT);
XCameraHelper.ScreenRect = CS.UnityEngine.Rect(0, 0, CS.UnityEngine.Screen.width, CS.UnityEngine.Screen.height)
   
function XCameraHelper.ScreenShot(image, beginCb, cb)
    if beginCb then
        beginCb()
    end
    CS.XTool.WaitForEndOfFrame(function()
        local screenShot = XCameraHelper.DoScreenShot(image)
        if cb then
            cb(screenShot)
        end
    end)
end

-- 截取屏幕画面到image中 （注意内存开销，需使用后及时释放）
-- image  Image组件
-- cameraFar Camera组件
-- cameraNear Camera组件（可选）
function XCameraHelper.DoScreenShot(image)
    if XTool.UObjIsNil(image) then
        XLog.Error("ScreenShot image is nil")
        return
    end

    -- if XTool.UObjIsNil(cameraFar) then
    --     XLog.Error("ScreenShot cameraFar is nil")
    --     return
    -- end

    local rect = XCameraHelper.ScreenRect
    -- -- 创建一个rt对象
    -- local rt = CS.UnityEngine.RenderTexture(rect.width, rect.height, 24)
    -- rt.antiAliasing = 8

    -- cameraFar.targetTexture = rt;
    -- if not XTool.UObjIsNil(cameraNear) then
    --     cameraNear.targetTexture = rt
    -- end

    -- cameraFar:Render();
    -- if not XTool.UObjIsNil(cameraNear) then
    --     cameraNear:Render()
    -- end

    -- local currentRT = CS.UnityEngine.RenderTexture.active 
    -- -- 激活rt 读取像素
    -- CS.UnityEngine.RenderTexture.active = rt;
    local screenShot = CS.UnityEngine.Texture2D(rect.width, rect.height, CS.UnityEngine.TextureFormat.RGB24, false);
    screenShot:ReadPixels(rect, 0, 0);
    screenShot:Apply();

    -- 重置相关参数
    -- cameraFar.targetTexture = nil;
    -- if not XTool.UObjIsNil(cameraNear) then
    --     cameraNear.targetTexture = nil;
    -- end

    -- CS.UnityEngine.RenderTexture.active = currentRT;
    -- CS.UnityEngine.Object.Destroy(rt);

    local sprite = CS.UnityEngine.Sprite.Create(screenShot, rect, CS.UnityEngine.Vector2.zero);
    image.sprite = sprite

    return screenShot
end

-- 调用该接口，由ScreenCaptureWithCallBack回调函数传出的Texture用完后必须销毁
function XCameraHelper.ScreenShotNew(image, camera, cb, beginCb)
    if not image then
        XLog.Error("ScreenShot Call invalid parameter:image is nil")
        return
    end

    if not camera then
        XLog.Error("ScreenShot Call invalid parameter:camera is nil")
        return
    end

    if not cb then
        XLog.Error("The ScreenShot API Must Need CallBack")
        return
    end
    
    -- if not XTool.UObjIsNil(image.mainTexture) and image.mainTexture.name ~= "UnityWhite" then -- 销毁texture2d (UnityWhite为默认的texture2d)
    --     CS.UnityEngine.Object.Destroy(image.mainTexture)
    -- end

    if beginCb then
        beginCb()
    end
    CS.XScreenCapture.ScreenCaptureWithCallBack(camera,function(texture)
        local rect = CS.UnityEngine.Rect(0, 0, texture.width, texture.height)
        local sprite = CS.UnityEngine.Sprite.Create(texture, rect, CS.UnityEngine.Vector2.zero);
        image.sprite = sprite
        if cb then
            cb(texture)
        end
    end)
end