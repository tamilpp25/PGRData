---@class XHomeScene 宿舍场景
---@field Camera UnityEngine.Camera
XHomeScene = XClass(nil, "XHomeScene")

local SCENE_FAR_CLIP_PLANE = 350

function XHomeScene:Ctor(sceneName, sceneAssetUrl, onLoadCompleteCb, onLeaveCb)
    self.OnLoadCompleteCb = onLoadCompleteCb
    self.OnLeaveCb = onLeaveCb
    
    for _, v in pairs(XDormConfig.SceneType) do
        self["Name"..v] = "sushe003_"..v
    end
    self.CurName = self["Name"..XDormConfig.SceneType.One]
    self.Name = sceneName
    self.SceneAssetUrl = sceneAssetUrl
    self.Resource = nil
    self.GameObject = nil

    self.CameraFollowTarget1 = nil
    self.CameraFollowTarget2 = nil
    self.CurCameraFollowTarget = nil
    self.Camera = nil
    self.CameraController = nil
    self.PhysicsRaycaster = nil

    -- 光照信息相关变量
    self.CurrentGlobalIllumSoPath = nil
    self.GlobalIllumSOResourceMap = {}
    self.CurrentPointLightPath = nil
    self.CurrentPintLightParent = nil
    self.GlobalPointLightMap = {}
end

function XHomeScene:OnEnterScene()
    --XSceneResourceManager.InitPool()
    self.Resource = CS.XResourceManager.LoadAsync(self.SceneAssetUrl)
    CS.XTool.WaitCoroutine(self.Resource, function()
        if not self.Resource.Asset then
            XLog.Error("XHomeScene LoadScene error, instantiate error, name: " .. self.SceneAssetUrl)
            return
        end

        self.GameObject = CS.UnityEngine.Object.Instantiate(self.Resource.Asset)
        self:OnLoadComplete()
    end)
end

function XHomeScene:OnLeaveScene()
    if self.OnLeaveCb then
        self.OnLeaveCb()
    end

    CS.UnityEngine.GameObject.Destroy(self.GameObject)
    self.GameObject = nil

    self.CurrentGlobalIllumSoPath = nil
    for _, v in pairs(self.GlobalIllumSOResourceMap) do
        if v then
            v:Release()
        end
    end
    self.GlobalIllumSOResourceMap = nil

    self.CurrentPointLightPath = nil
    self.CurrentPintLightParent = nil
    for _, v in pairs(self.GlobalPointLightMap) do
        if v.Resource then
            v.Resource:Release()
        end

        if not XTool.UObjIsNil(v.SoTrans) then
            CS.UnityEngine.GameObject.Destroy(v.SoTrans.gameObject)
        end
    end
    self.GlobalPointLightMap = nil

    XUiHelper.SetSceneType(CS.XSceneType.Ui)

    if self.Resource then
        self.Resource:Release()
    end
end

function XHomeScene:OnLoadComplete()
    self:InitCamera()

    if self.OnLoadCompleteCb then
        self.OnLoadCompleteCb(self.GameObject)
    end
end

function XHomeScene:InitCamera()
    self.Camera = self.GameObject.transform:Find("Camera"):GetComponent("Camera")
    self.PhysicsRaycaster = self.Camera.gameObject:AddComponent(typeof(CS.UnityEngine.EventSystems.PhysicsRaycaster))

    CS.XGraphicManager.BindCamera(self.Camera)
    for _, v in pairs(XDormConfig.SceneType) do
        local target = CS.UnityEngine.GameObject.Find("@Target_" .. v)
        if not XTool.UObjIsNil(target) then
            self["CameraFollowTarget"..v] = target.transform
        end
    end  
    self.CurCameraFollowTarget = self["CameraFollowTarget"..XDormConfig.SceneType.One]
    self.CameraController = self.Camera.gameObject:GetComponent(typeof(CS.XCameraController))

    self.CameraController:SetParam(self.CurName)
    XCameraHelper.SetCameraTarget(self.CameraController, self.CurCameraFollowTarget)
    self.DefaultCameraDistance = self.CameraController.Distance
end

function XHomeScene:ChangeCameraToScene(cb)
    XHomeSceneManager.SafeOpenBlack(self.CurCameraFollowTarget, false, self.CurName, cb)
    local camera = self:GetCamera()
    if not XTool.UObjIsNil(camera) then
        camera.farClipPlane = SCENE_FAR_CLIP_PLANE
    end
end

function XHomeScene:ChangeCameraToSceneById(sceneId, cb)
    self.CurCameraFollowTarget = self["CameraFollowTarget" .. sceneId]
    self.CurName = self["Name" .. sceneId]

    XHomeSceneManager.SafeOpenBlack(self.CurCameraFollowTarget, false, self.CurName, function()
        XCameraHelper.SetCameraTarget(self.CameraController, self.CurCameraFollowTarget)
        if cb then cb() end
    end )
end

function XHomeScene:GetCamera()
    return self.Camera
end

function XHomeScene:GetCameraController()
    return self.CameraController
end

function XHomeScene:SetRaycasterMask(mask)
    self.PhysicsRaycaster:SetEventMask(mask)
end

----------------------------光照信息接口 start-----------------------------
-- 设置全局光照
function XHomeScene:SetGlobalIllumSO(soPath)
    if not soPath or string.len(soPath) <= 0 then
        return
    end

    self.CurrentGlobalIllumSoPath = soPath

    local resource = self.GlobalIllumSOResourceMap[soPath]
    if not resource then
        resource = CS.XResourceManager.Load(soPath)
        self.GlobalIllumSOResourceMap[soPath] = resource
    end

    CS.XGlobalIllumination.SetGlobalIllumSO(resource.Asset)
end

-- 重置为当前场景全局光
function XHomeScene:ResetToCurrentGlobalIllumination()
    local resource = self.GlobalIllumSOResourceMap[self.CurrentGlobalIllumSoPath]
    if resource then
        CS.XGlobalIllumination.SetGlobalIllumSO(resource.Asset)
    end
end
----------------------------光照信息接口 end-----------------------------