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
    CS.XScreenCapture.ScreenCaptureWithCallBack(camera, function(texture)
        local rect = CS.UnityEngine.Rect(0, 0, texture.width, texture.height)
        local sprite = CS.UnityEngine.Sprite.Create(texture, rect, CS.UnityEngine.Vector2.zero);
        image.sprite = sprite
        if cb then
            cb(texture)
        end
    end)
end

function XCameraHelper.GetBlendTime(cameraBrain, index)
    return cameraBrain.m_CustomBlends.m_CustomBlends[index].m_Blend.m_Time
end

function XCameraHelper.CaptureCustomShotAsTexture(x, y, width, height, image, callback, beginCallback)
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    if beginCallback then
        beginCallback()
    end
    CS.XTool.CaptureCustomShotAsTexture(image, callback, x, y, width, height)
end

function XCameraHelper.CutPixelsFromTexture(x, y, width, height, texture2D, image)
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    return CS.XTool.CutPixelsFromTexture(x, y, width, height, texture2D, image)
end

-- 调用该接口，由ScreenCaptureWithCallBack回调函数传出的Texture用完后必须销毁
function XCameraHelper.ScreenShotNewNoImage(camera, cb, beginCb)
    if not camera then
        XLog.Error("ScreenShot Call invalid parameter:camera is nil")
        return
    end

    if not cb then
        XLog.Error("The ScreenShot API Must Need CallBack")
        return
    end

    if beginCb then
        beginCb()
    end
    CS.XScreenCapture.ScreenCaptureWithCallBack(camera, function(texture)
        if cb then
            cb(texture)
        end
    end)
end

---------------------------------------------------------------------------------------------------------------------------------------
-- 将1920*1080的UI合成一张图 （以后有需要可以修改为自定义比例）
function XCameraHelper.PhotographWithFixedRatio(image, cb, beginCb, showPanelPrefabPath, refreshFun, ui)
    local photographNodePrefabPath = CS.XGame.ClientConfig:GetString("PhotographNodePrefabPath")
    if string.IsNilOrEmpty(photographNodePrefabPath) then
        return
    end

    local resourceLoader = ui.GameObject:GetLoader()

    local photographNodeRes = resourceLoader:Load(photographNodePrefabPath)
    if photographNodeRes == nil then
        return
    end

    local photographNode = CS.UnityEngine.Object.Instantiate(photographNodeRes, CS.XUiManager.Instance:GetUiRoot())
    if photographNode == nil then
        return
    end

    photographNode.transform.localPosition = Vector3(5000, 5000, -5000)
    local uiPhotographNode = {}
    XUiHelper.InitUiClass(uiPhotographNode, photographNode)

    -- 调整相机视口
    if (XCameraHelper.ScreenRect.width / XCameraHelper.ScreenRect.height) < (XCameraHelper.DefaultRect.width / XCameraHelper.DefaultRect.height) then
        local ratio = (XCameraHelper.ScreenRect.width * XCameraHelper.DefaultRect.height) / (XCameraHelper.DefaultRect.width * XCameraHelper.ScreenRect.height)
        uiPhotographNode.Camera.rect = CS.UnityEngine.Rect(0, 0, 1, ratio)
    else
        local ratio = (XCameraHelper.DefaultRect.width * XCameraHelper.ScreenRect.height) / (XCameraHelper.ScreenRect.width * XCameraHelper.DefaultRect.height)
        uiPhotographNode.Camera.rect = CS.UnityEngine.Rect(0, 0, ratio, 1)
    end

    -- 加载面版资源
    if string.IsNilOrEmpty(showPanelPrefabPath) then
        return
    end
    local showPanelPrefabRes = resourceLoader:Load(showPanelPrefabPath)
    if showPanelPrefabRes == nil then
        uiPhotographNode = nil
        CS.UnityEngine.Object.Destroy(photographNode)
        return
    end

    local showPanelPrefab = CS.UnityEngine.Object.Instantiate(showPanelPrefabRes, uiPhotographNode.Canvas)
    if showPanelPrefab == nil then
        uiPhotographNode = nil
        CS.UnityEngine.Object.Destroy(photographNode)
        return
    end
    showPanelPrefab.transform.localPosition = Vector3.zero

    local uiShowPanel = {}
    XUiHelper.InitUiClass(uiShowPanel, showPanelPrefab)

    if refreshFun then
        refreshFun(uiShowPanel)
    end

    -- 截图
    XCameraHelper.ScreenShotNew(image, uiPhotographNode.Camera, function(renderTexture)
        uiPhotographNode = nil
        CS.UnityEngine.Object.Destroy(photographNode)
        if cb then
            cb(renderTexture)
        end
    end, beginCb)
end