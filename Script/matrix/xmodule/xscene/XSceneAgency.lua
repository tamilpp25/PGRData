local XLuaScene
local SceneRegistry

local SceneClass = {}

local CsNoneSceneType = CS.XSceneType.None:GetHashCode()

---@class XSceneAgency : XAgency
---@field private _Model XSceneModel
---@field private _SceneDict table<number, XLuaScene>
local XSceneAgency = XClass(XAgency, "XSceneAgency")
function XSceneAgency:OnInit()
    self._SceneDict = {}
    self._Loader = false

    XLuaScene = require("XModule/XScene/XScene/XLuaScene")
    SceneRegistry = require("XModule/XScene/XScene/XLuaSceneDefine").SceneRegistry
end

function XSceneAgency:InitRpc()
end

function XSceneAgency:InitEvent()
end

function XSceneAgency:ResetAll()
    self:ReleaseAllScene()
end

function XSceneAgency:OnRelease()
    self:ReleaseAllScene()
end

--- 注册一个场景类型
---@param parent XLuaScene|nil 父类，不填时，默认为XLuaScene
---@param name string 场景名，Scene.tab中的Name
--------------------------
function XSceneAgency:Register(parent, name)
    if XMain.IsEditorDebug then
        if parent and not CheckClassSuper(parent, XLuaScene) then
            XLog.Error("父类必须继承自XLuaScene, SceneName = " .. name)
            parent = XLuaScene
        end
    end
    if not parent then
        parent = XLuaScene
    end
    local scene = XClass(parent, name)
    SceneClass[name] = scene
    
    return scene
end

--- 释放所有场景
--------------------------
function XSceneAgency:ReleaseAllScene()
    if XTool.IsTableEmpty(self._SceneDict) then
        return
    end
    for _, scene in pairs(self._SceneDict) do
        scene:Destroy()
    end
    self._SceneDict = {}
end

---@return XLoaderUtil
function XSceneAgency:GetLoader()
    if not self._Loader then
        self._Loader = CS.XLoaderUtil.GetModuleLoader(self._Id)
    end
    return self._Loader
end

function XSceneAgency:UnloadSceneRes(url)
    if not self._Loader then
        XLog.Error(string.format("XSceneAgency:UnloadSceneRes: Loader is nil, url: %s", url))
        return
    end

    self._Loader:Unload(url)
    if self._Loader:GetResCount() == 0 then
        CS.XLoaderUtil.ClearModuleLoader(self._Id)
        self._Loader = nil
    end
end

--- 加载场景
---@param sceneId number 场景Id  
---@param isAsync boolean 是否为异步加载  
---@param loadCompleteCb fun(scene:XLuaScene) 加载完成回调 
---@param caller any 回调执行对象
---@vararg any 初始化参数
function XSceneAgency:LoadScene(sceneId, isAsync, loadCompleteCb, caller, ...)
    local scene = self._SceneDict[sceneId]
    if scene and scene:IsWaitForDestroy() then
        scene:Enter()
        return
    end

    local class = self:GetOrRequireSceneClass(sceneId)
    if not class then
        return
    end
    ---@type XLuaScene
    scene = class.New(sceneId, ...)
    self._SceneDict[sceneId] = scene
    
    if isAsync then
        self:_DoLoadAsync(sceneId, loadCompleteCb, caller)
    else
        self:_DoLoadSync(sceneId, loadCompleteCb, caller)
    end
end

function XSceneAgency:_DoLoadSync(sceneId, loadCompleteCb, caller)
    local url = self:GetSceneUrl(sceneId)
    if string.IsNilOrEmpty(url) then
        XLog.Error("load scene error: scene url is empty, sceneId = " .. sceneId)
        return
    end
    local loader = self:GetLoader()
    local asset = loader:Load(url)
    self:_OnLoadComplete(sceneId, asset, loadCompleteCb, caller)
end

function XSceneAgency:_DoLoadAsync(sceneId, loadCompleteCb, caller)
    local url = self:GetSceneUrl(sceneId)
    if string.IsNilOrEmpty(url) then
        XLog.Error("load scene error: scene url is empty, sceneId = " .. sceneId)
        return
    end
    
    local loader = self:GetLoader()
    loader:LoadAsync(url, function(asset)
        self:_OnLoadComplete(sceneId, asset, loadCompleteCb, caller)
    end)
end

function XSceneAgency:_OnLoadComplete(sceneId, asset, loadCompleteCb, caller)
    ---@type XLuaScene
    local scene = self:GetScene(sceneId)
    ---@type UnityEngine.GameObject
    local obj = XUiHelper.Instantiate(asset)
    scene:SetGameObject(obj)
    local sceneType = self:GetSceneType(sceneId)
    if sceneType ~= CsNoneSceneType then
        self:SetSceneType(sceneType)
    end
    -- 进入场景
    scene:Enter()
    
    if loadCompleteCb then
        loadCompleteCb(caller, scene)
    end
end

function XSceneAgency:GetOrRequireSceneClass(sceneId)
    local sceneName = self:GetSceneName(sceneId)
    local class = SceneClass[sceneName]
    if not class then
        self:TryRequire(sceneName)
    end
    if not class then
        XLog.Error(string.format("场景:%s require异常，请检查配置。", sceneName))
    end
    return class
end

--- 尝试移除场景
---@param sceneId number 场景Id   
--------------------------
function XSceneAgency:_TryRemoveScene(sceneId)
    if not self._SceneDict then
        return
    end
    self._SceneDict[sceneId] = nil
    self:UnloadSceneRes(self:GetSceneUrl(sceneId))
end

--- 退出场景
---@param sceneId number 场景Id  
--------------------------
function XSceneAgency:ExitScene(sceneId)
    local scene = self._SceneDict[sceneId]
    if not scene then
        return
    end
    scene:Exit()
end

--- 强制移除场景
---@param sceneId number 场景Id
--------------------------
function XSceneAgency:RemoveScene(sceneId)
    local scene = self._SceneDict[sceneId]
    if not scene then
        return
    end
    scene:Exit()
    scene:Destroy()
end

--- 获取场景
---@param sceneId number  
---@return XLuaScene
--------------------------
function XSceneAgency:GetScene(sceneId)
    return self._SceneDict[sceneId]
end

--region Common

function XSceneAgency:SetSceneType(sceneType)
    if not sceneType then
        return
    end
    
    CS.XGlobalIllumination.SetSceneType(sceneType)
end

function XSceneAgency:TryRequire(sceneName)
    local path = SceneRegistry[sceneName]
    if not path then
        XLog.Error("lua scene script not register! scene name = " .. sceneName)
        return
    end
    require(path)
end

--endregion Common

--region Scene Config

function XSceneAgency:GetSceneName(sceneId)
    local template = self._Model:GetSceneTemplate(sceneId)
    return template and template.Name or "Default"
end

function XSceneAgency:GetSceneCacheTime(sceneId)
    local template = self._Model:GetSceneTemplate(sceneId)
    return template and template.CacheTime or 0
end

function XSceneAgency:GetSceneUrl(sceneId)
    local template = self._Model:GetSceneTemplate(sceneId)
    return template and template.SceneUrl or ""
end

function XSceneAgency:GetSceneType(sceneId)
    local template = self._Model:GetSceneTemplate(sceneId)
    return template and template.SceneType or 0
end

function XSceneAgency:GetGlobalSO(sceneId)
    local template = self._Model:GetSceneTemplate(sceneId)
    return template and template.GlobalIllumination or ""
end

--endregion Scene Config

return XSceneAgency