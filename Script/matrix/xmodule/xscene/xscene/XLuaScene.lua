local SceneBindControl = require("XModule/XScene/XScene/XLuaSceneDefine").SceneBindControl
local CsGraphicManager = CS.XGraphicManager

---@class XLuaScene lua场景基类
---@field protected _GameObject UnityEngine.GameObject
---@field protected _Transform UnityEngine.Transform
---@field protected _Name string
---@field protected _SceneId number 场景Id
---@field protected _Control XControl
---@field protected _LoadId number 子节点Id
---@field protected _LoadMap table<number, table> 子节点Id -> 加载的节点信息
---@field protected _EventMap table<string, table<fun, boolean>> 事件管理
local XLuaScene = XClass(nil, "XLuaScene")

function XLuaScene:Ctor(sceneId, ...)
    --用于绑定Control的引用
    --避免跟UI的冲突，使用同一个自增Id
    self._UUID = XLuaUiManager.GenUIUid()
    self._Control = nil
    self._SceneId = sceneId
    self._EventMap = {}
    self._LoadMap = {}
    self._LoadId = 0
    self:ChangeName(XMVCA.XScene:GetSceneName(sceneId))
    self:_BindControl()
    self:OnInit(...)
end

--region 子类重写接口

--- 类创建时初始化，此时还未设置GameObject
---@vararg any 任意参数
--------------------------
function XLuaScene:OnInit(...)
end

function XLuaScene:OnEnter()
end

function XLuaScene:OnExit()
end

function XLuaScene:OnDestroy()
end

---@return UnityEngine.Camera
function XLuaScene:GetCamera()
    --由于场景中的相机情况比较复杂（单个，多个，虚拟相机等）
    --具体的逻辑可由子类实现，这里提供一个统一的接口
    --可以根据传参处理对应逻辑
    XLog.Error("请实现" .. self.__cname .. ":GetCamera!!!")
end

--endregion 子类重写接口

function XLuaScene:Enter()
    if XTool.UObjIsNil(self._GameObject) then
        XLog.Error("No gameObject set in the scene = " .. tostring(self._SceneId))
        return
    end
    self._GameObject:SetActiveEx(true)
    self:_StopDestroyTimer()
    self:OnEnter()
end

function XLuaScene:Exit()
    self:OnExit()
    
    if self:IsActiveInHierarchy() then
        self._GameObject:SetActiveEx(false)
    end
    self:_StartDestroyTimer()
end

function XLuaScene:Destroy()
    self:ReleaseAllChild()
    self:ReleaseGlobalSO()
    
    if not XTool.UObjIsNil(self._GameObject) then
        XUiHelper.Destroy(self._GameObject)
    end
    XMVCA.XScene:_TryRemoveScene(self._SceneId)
    self:_StopDestroyTimer()
    self:ReleaseAllEvent()
    self:_UnBindControl()
    
    self._Transform = nil
    self._GameObject = nil
    self:OnDestroy()
end

function XLuaScene:_BindControl()
    local moduleId = SceneBindControl[self.__cname]
    if not moduleId then
        return
    end
    self._Control = XMVCA:_GetOrRegisterControl(moduleId)
    self._Control:AddViewRef(self._UUID)
end

function XLuaScene:_UnBindControl()
    if not self._Control then
        return
    end
    if self._Control:GetIsRelease() then
        return
    end
    
    self._Control:SubViewRef(self._UUID)
    XMVCA:CheckReleaseControl(self._Control:GetId())
    
    self._Control = nil
end

function XLuaScene:LoadGlobalSO()
    local globalSo = XMVCA.XScene:GetGlobalSO(self._SceneId)
    if string.IsNilOrEmpty(globalSo) then
        return
    end
    local loader = XMVCA.XScene:GetLoader()
    loader:LoadAsync(globalSo, function(asset)
        if not asset then
            XLog.Error("load global so error: url = " .. globalSo)
            return
        end

        self._SOUrl = globalSo
        --设置全局光照
        CS.XGlobalIllumination.SetGlobalIllumSO(asset)
    end)
end

function XLuaScene:ReleaseGlobalSO()
    if not self._SOUrl then
        return
    end
    XMVCA.XScene:GetLoader():Unload(self._SOUrl)
    self._SOUrl = nil
end

--- 设置场景物体
---@param obj UnityEngine.GameObject | UnityEngine.Transform  
--------------------------
function XLuaScene:SetGameObject(obj)
    if not obj then
        XLog.Error("设置场景对象出错!!!")
        return
    end
    self._GameObject = obj.gameObject
    self._Transform = obj.transform

    if not string.IsNilOrEmpty(self._Name) then
        self._GameObject.name = self._Name
    end

    self:LoadGlobalSO()
end

--- 是否在场景中显示
---@return boolean
--------------------------
function XLuaScene:IsActiveInHierarchy()
    return (not XTool.UObjIsNil(self._GameObject)) and self._GameObject.activeInHierarchy
end

--- 等待销毁中
---@return boolean
--------------------------
function XLuaScene:IsWaitForDestroy()
    if XTool.UObjIsNil(self._GameObject) then
        return false
    end
    if not self._DestroyTimer then
        return false
    end
    
    return true
end

--- 修改场景节点名
---@param name string 场景名  
--------------------------
function XLuaScene:ChangeName(name)
    self._Name = name
    if XTool.UObjIsNil(self._GameObject) then
        return
    end
    
    self._GameObject.name = name
end

--- 开始销毁倒计时
--------------------------
function XLuaScene:_StartDestroyTimer()
    self:_StopDestroyTimer()
    local cacheTime = XMVCA.XScene:GetSceneCacheTime(self._SceneId)
    if cacheTime <= 0 then
        self:Destroy()
        return
    end
    
    self._DestroyTimer = XScheduleManager.ScheduleOnce(function() 
        self:Destroy()
    end, cacheTime)
end

--- 停止倒计时
--------------------------
function XLuaScene:_StopDestroyTimer()
    if not self._DestroyTimer then
        return
    end
    XScheduleManager.UnSchedule(self._DestroyTimer)
    self._DestroyTimer = nil
end

--- 绑定相机到后处理脚本
---@param camera UnityEngine.Camera 需要处理的相机，不填，默认为场景的上的相机 
--------------------------
function XLuaScene:BindCamera(camera)
    if not camera then
        camera = self:GetCamera()
    end

    if not camera then
        return
    end

    CsGraphicManager.BindCamera(camera)
end

--- 查找子节点
---@param name string 子节点名称  
---@return UnityEngine.Transform
--------------------------
function XLuaScene:FindTransform(name)
    if XTool.UObjIsNil(self._Transform) then
        return nil
    end
    return self._Transform:FindTransform(name)
end

--- 查找子节点
---@param relativePath string 子节点相对路径 
---@return UnityEngine.Transform
--------------------------
function XLuaScene:Find(relativePath)
    if XTool.UObjIsNil(self._Transform) then
        return nil
    end
    return self._Transform:Find(relativePath)
end

--region Event

--- 监听事件
---@param eventId string 事件Id  
---@param action fun() 事件回调
function XLuaScene:AddEvent(eventId, action)
    if not eventId or not action then
        return
    end
    if not self._EventMap[eventId] then
        self._EventMap[eventId] = {}
    end
    self._EventMap[eventId][action] = true
    XEventManager.AddEventListener(eventId, action, self)
end

--- 移除事件
---@param eventId string 事件Id  
---@param action fun() 事件回调
--------------------------
function XLuaScene:RemoveEvent(eventId, action)
    if not eventId or not action then
        return
    end
    local dict = self._EventMap[eventId]
    if dict then
        dict[action] = nil
    end
    if XTool.IsTableEmpty(dict) then
        self._EventMap[eventId] = nil
    end
    XEventManager.RemoveEventListener(eventId, action, self)
end

--- 释放所有事件
--------------------------
function XLuaScene:ReleaseAllEvent()
    if XTool.IsTableEmpty(self._EventMap) then
        return
    end
    for eventId, dict in pairs(self._EventMap) do
        for action, _ in pairs(dict) do
            XEventManager.RemoveEventListener(eventId, action, self)
        end
    end
    self._EventMap = nil
end

--endregion Event

--- 绑定场景设置
---@param sceneSetting XSceneSetting  
--------------------------
function XLuaScene:BindSetting(sceneSetting)
    if not sceneSetting then
        return
    end

    CsGraphicManager.BindScene(sceneSetting)
end

--- 获取场景设定
---@return XSceneSetting
--------------------------
function XLuaScene:GetSceneSetting()
    if XTool.UObjIsNil(self._Transform) then
        return
    end
    return self._Transform:GetComponent("XSceneSetting")
end

--- 动态烘培导航寻路
---@param colliderRoot UnityEngine.GameObject 碰撞体根节点，这个节点下所有子节点的碰撞体都会被计算成阻挡
---@param floor UnityEngine.GameObject 行走的区域
--------------------------
function XLuaScene:BakeNavMesh(colliderRoot, floor)
    if XTool.UObjIsNil(floor) then
        XLog.Error("bake navmesh error: floor is empty")
        return
    end

    local utility = CS.XNavMeshUtility
    if not XTool.UObjIsNil(colliderRoot) then
        utility.AddNavMeshObstacleSizeByCollider(colliderRoot.gameObject)
    end
    utility.SetNavMeshSurfaceAndBuild(floor.gameObject)
end

--region Load Child

function XLuaScene:_GetLoadId()
    self._LoadId = self._LoadId + 1
    return self._LoadId
end

function XLuaScene:_LoadComplete(root, asset, url)
    root = root or self._Transform
    local obj = XUiHelper.Instantiate(asset, root.transform)
    local loadId = self:_GetLoadId()

    self._LoadMap[loadId] = {
        GameObject = obj,
        Asset = asset,
        Url = url,
    }
    
    return loadId, obj
end

--- 加载子节点(同步)
---@param root UnityEngine.Transform 父节点
---@param url string 资源路径
---@return number, UnityEngine.GameObject
--------------------------
function XLuaScene:LoadChildSync(root, url)
    if XTool.UObjIsNil(self._Transform) then
        return
    end
    if string.IsNilOrEmpty(url) then 
        XLog.Warning("load asset url is empty!!!")
        return
    end
    local asset = XMVCA.XScene:GetLoader():Load(url)
    if not asset then
        XLog.Error("load asset error: url = " .. url)
        return
    end
    
    return self:_LoadComplete(root, asset, url)
end

--- 加载子节点(异步)
---@param root UnityEngine.Transform 父节点
---@param url string 资源路径
---@param completeCb fun(loadId:number, obj:UnityEngine.GameObject) 资源路径
--------------------------
function XLuaScene:LoadChildAsync(root, url, completeCb)
    if XTool.UObjIsNil(self._Transform) then
        return
    end
    if string.IsNilOrEmpty(url) then
        XLog.Warning("load asset url is empty!!!")
        return
    end
    XMVCA.XScene:GetLoader():LoadAsync(url, function(asset)
        if not asset then
            XLog.Error("load asset error: url = " .. url)
            return
        end
        local loadId, obj = self:_LoadComplete(root, asset, url)
        
        if completeCb then
            completeCb(loadId, obj)
        end
    end)
end

--- 销毁释放子物体
---@param loadId number  
--------------------------
function XLuaScene:ReleaseChild(loadId)
    local info = self._LoadMap[loadId]
    if not info then
        return
    end
    
    local obj, url = info.GameObject, info.Url
    if not XTool.UObjIsNil(obj) then
        XUiHelper.Destroy(obj)
    end

    if not string.IsNilOrEmpty(url) then
        XMVCA.XScene:GetLoader():Unload(url)
    end
    
    self._LoadMap[loadId] = nil
end

function XLuaScene:ReleaseAllChild()
    if XTool.IsTableEmpty(self._LoadMap) then
        return
    end

    for _, info in pairs(self._LoadMap) do
        local obj, url = info.GameObject, info.Url
        if not XTool.UObjIsNil(obj) then
            XUiHelper.Destroy(obj)
        end

        if not string.IsNilOrEmpty(url) then
            XMVCA.XScene:GetLoader():Unload(url)
        end
    end

    self._LoadMap = nil
end

--endregion Load Child

return XLuaScene
