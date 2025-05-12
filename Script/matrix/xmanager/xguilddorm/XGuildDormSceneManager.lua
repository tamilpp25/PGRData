--=================
--公会宿舍场景管理
--负责人：吕天元
--=================
---@class XGuildDormSceneManager
local XGuildDormSceneManager = {}

local XGuildDormScene = require("XEntity/XGuildDorm/XGuildDormScene")
--=============
--当前场景
--获取/设置当前场景
--=============
---@type XGuildDormScene
local CurrentScene
function XGuildDormSceneManager.GetCurrentScene()
    return CurrentScene
end
local function SetCurrentScene(scene)
    CurrentScene = scene
end
--=============
--当前场景视角
--获取/设置当前场景视角
--=============
local CurrentView
function XGuildDormSceneManager.GetCurrentView()
    return CurrentView
end
function XGuildDormSceneManager.SetCurrentView(viewType)
    CurrentView = viewType
end
--=============
--碰撞盒子 -> 对象字典
--Key:Collider的InstanceId
--Value:Collider对应的主体的InstanceId
--一个主体可能有多个碰撞盒子
--=============
local Collider2IdKeyMap
--=============
--场景对象字典
--Key:GameObject的InstanceId
--Value:GameObject对应的对象实体
--=============
local SceneObjsMap
--=============
--初始化
--=============
local function Init()
    CurrentScene = nil
    CurrentView = XGuildDormConfig.SceneViewType.OverView
    Collider2IdKeyMap = {}
    SceneObjsMap = {}
    XLog.Debug("GuildDormSceneManager Initial Completed. 公会宿舍场景管理器初始化完成。")
end
--=============
--获取主体InstanceId
--=============
local function GetMainInstanceByGo(go)
    if XTool.UObjIsNil(go.gameObject) then return end
    local instanceId = go.gameObject:GetInstanceID()
    return Collider2IdKeyMap[instanceId] or instanceId
end
--=============
--离开当前场景
--=============
local function LeaveCurrentScene()
    local scene = XGuildDormSceneManager.GetCurrentScene()
    if scene then
        scene:OnExitScene()
        SetCurrentScene(nil)
    end
end
--==============
--进入，切换场景
--==============
function XGuildDormSceneManager.EnterScene(sceneName, scenePrefabPath, roomId, onLoadCompleteCb, onExitCb, onLoadingStart)
    local canEnter, tips = XDataCenter.GuildDormManager.CheckCanEnterGuildDorm()
    if not canEnter then
        XUiManager.TipMsg(tips)
        return
    end
    --要打开的场景的场景名跟当前场景名相同则返回
    if CurrentScene and CurrentScene.Name == sceneName then
        return
    end
    --调整全局光照模式
    XUiHelper.SetSceneType(CS.XSceneType.Dormitory)
    local scene = XGuildDormScene.New(sceneName, scenePrefabPath, roomId, onLoadCompleteCb, onExitCb)
    XLuaUiManager.Open("UiLoading", LoadingType.GuildDorm)
    if onLoadingStart then
        onLoadingStart()
    end
    CS.UnityEngine.Resources.UnloadUnusedAssets()
    --进入新场景处理旧场景离开
    LeaveCurrentScene()
    SetCurrentScene(scene)
    CurrentScene:OnEnterScene()
    --默认房间视角
    CurrentView = XGuildDormConfig.SceneViewType.RoomView
end
--============
--移除公会宿舍
--============
function XGuildDormSceneManager.ExitGuildDorm()
    LeaveCurrentScene()
    XUiHelper.SetSceneType(CS.XSceneType.Ui)
    XGuildDormSceneManager.ClearSceneObjsMaps()
end
--============
--添加场景物件
--若物件的GameObject下有多个Collider，会将其全部记入Map中用于检索
--============
function XGuildDormSceneManager.AddSceneObj(gameObject, entity)
    if not gameObject then return end
    --获取主体唯一Id
    local objInstanceId = gameObject:GetInstanceID()
    --获取主体下所有碰撞盒子
    local colliderList = gameObject:GetComponentsInChildren(typeof(CS.UnityEngine.Collider))
    for i = 0, colliderList.Length - 1 do
        local instanceId = colliderList[i].gameObject:GetInstanceID()
        Collider2IdKeyMap[instanceId] = objInstanceId
    end
    SceneObjsMap[objInstanceId] = entity
end
--============
--移除场景物件
--传入对象子部位的gameObject时，会搜索其主体移除
--============
function XGuildDormSceneManager.RemoveObj(go)
    if not go then return end
    local mainInstanceId = GetMainInstanceByGo(go)
    if not mainInstanceId then return end
    SceneObjsMap[mainInstanceId] = nil
end
--============
--清除场景实体Map数据
--============
function XGuildDormSceneManager.ClearSceneObjsMaps()
    Collider2IdKeyMap = {}
    SceneObjsMap = {}
end
--============
--根据给定GameObject获取场景实体
--============
function XGuildDormSceneManager.GetSceneObjByGameObject(go)
    if XTool.UObjIsNil(go) then return end
    local mainInstanceId = GetMainInstanceByGo(go)
    if not mainInstanceId then return end
    local mainInstanceId = Collider2IdKeyMap[mainInstanceId] or mainInstanceId
    return SceneObjsMap[mainInstanceId]
end
--============
--检查场景对象是否是家具
--============
function XGuildDormSceneManager.CheckSceneObjIsFurniture(go)
    if not go then return false end
    local entity = XGuildDormSceneManager.GetSceneObjByGameObject(go)
    if not entity then return false end
    return XGuildDormSceneManager.CheckEntityIsFurniture(entity)
end
--============
--检查实体是否是家具
--============
function XGuildDormSceneManager.CheckEntityIsFurniture(entity)
    return entity and entity.__cname == "XGuildDormFurnitureModel"
end
--============
--检查场景对象是否是可交互的家具
--============
function XGuildDormSceneManager.CheckSceneObjIsCanInteractiveFurniture(go)
    if not go then return false end
    local entity = XGuildDormSceneManager.GetSceneObjByGameObject(go)
    if not entity then return false end
    return XGuildDormSceneManager.CheckEntityIsCanInteractiveFurniture(entity)
end
--============
--检查实体是否是可交互的家具
--============
function XGuildDormSceneManager.CheckEntityIsCanInteractiveFurniture(entity)
    local isFurniture = XGuildDormSceneManager.CheckEntityIsFurniture(entity)
    if not isFurniture then return false end
    return entity.CanInteract
end
--================TEST=================
function XGuildDormSceneManager.TestSceneManagerFunc()
    XLog.Debug("TestSceneManagerFunc Success.")
end
function XGuildDormSceneManager.TestGetSceneObjsMap()
    return SceneObjsMap
end
--require时运行初始化
Init()

return XGuildDormSceneManager