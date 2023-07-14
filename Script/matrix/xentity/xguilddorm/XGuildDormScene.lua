--=============
--公会宿舍场景对象
--一个场景包含多个房间
--=============
local XGuildDormScene = XClass(nil, "XGuildDormScene")
local SCENE_FAR_CLIP_PLANE = 350
--==================Get/Set方法===================
--===========
--根据房间配置表Id获取房间
--XGuildDormRoom的Id
--===========
function XGuildDormScene:GetRoomById(roomId)
    return self.Rooms[roomId]
end
--===========
--获取当前房间
--===========
function XGuildDormScene:GetCurrentRoom()
    return self.CurrentRoom
end
--===========
--获取场景相机
--===========
function XGuildDormScene:GetCamera()
    return self.Camera
end
--===========
--获取场景相机控制器
--===========
function XGuildDormScene:GetCameraController()
    return self.CameraController
end
--===========
--设置射线层级
--===========
function XGuildDormScene:SetRaycasterMask(mask)
    self.PhysicsRaycaster:SetEventMask(mask)
end
--===========
--获取场景的天空盒
--===========
function XGuildDormScene:GetSkyBox()
    return self.SkyBox
end
--==============
--设置全局光照
--==============
function XGuildDormScene:SetGlobalIllumSO(soPath)
    if not soPath or string.len(soPath) <= 0 then
        soPath = CS.XGame.ClientConfig:GetString("HomeSceneSoAssetUrl")
    end
    self.CurrentGlobalIllumSoPath = soPath
    local resource = self.GlobalIllumSOResourceMap[soPath]
    if not resource then
        resource = CS.XResourceManager.Load(soPath)
        self.GlobalIllumSOResourceMap[soPath] = resource
    end
    CS.XGlobalIllumination.SetGlobalIllumSO(resource.Asset)
end
--=================================================

--=================
--构造函数
--sceneName: 场景名称，对应Room表的SceneName
--=================
function XGuildDormScene:Ctor(sceneName, sceneAssetUrl, roomId, onLoadCompleteCb, onLeaveCb)
    self.OnLoadCompleteCb = onLoadCompleteCb
    self.OnLeaveCb = onLeaveCb
    self.Name = sceneName
    self.SceneAssetUrl = sceneAssetUrl
    --初始化场景下的房间信息
    self:InitRooms(roomId)
    self.Camera = nil
    self.CameraController = nil
    self.PhysicsRaycaster = nil
    -- 光照信息相关变量
    self.CurrentGlobalIllumSoPath = nil
    self.GlobalIllumSOResourceMap = {}
end

--===================================场景操作相关方法 Start==================================
--=============
--初始化场景
--=============
function XGuildDormScene:InitScene(datas, dormDataType)
    CS.XGridManager.Instance:Init()
    self.RoomRoot = self.GameObject.transform:FindGameObject("@Room")
    if not XTool.UObjIsNil(self.RoomRoot) then
        self:LoadRooms(datas, dormDataType)
    end
    self.SkyBox = self.GameObject.transform:FindGameObject("XSkybox")
    --(第一期暂时不需要网格)
    --XDataCenter.GuildDormManager.MapGridManager.GetMapGridManager():SetCamera(self.Camera)
end
--=============
--场景资源加载完时
--=============
local function OnLoadComplete(scene, onFinishLoadScene)
    scene:InitCamera()
    scene.GameObject:SetActiveEx(true)
    --XLuaUiManager.Open("UiBlackScreen", scene.CurCameraFollowTarget, false, scene.CurName, function()
    scene:InitScene(XDataCenter.GuildDormManager.GetSceneName2RoomDataDic(scene.Name), XDormConfig.DormDataType.Self)
    XCameraHelper.SetCameraTarget(scene.CameraController, scene.CurCameraFollowTarget)
    scene:EnterRoom(scene.CurrentRoomIndex)
    scene:SetRaycasterMask(HomeSceneViewType.RoomView)
    if scene.OnLoadCompleteCb then
        scene.OnLoadCompleteCb(scene.GameObject)
        XLuaUiManager.Close("UiLoading")
        XLuaUiManager.OpenWithCallback("UiGuildDormMain", function()
                if onFinishLoadScene then
                    onFinishLoadScene()
                end
            end)
        XLuaUiManager.Open("UiGuildDormCommon")
    end
    --   end)
end
--================
--进入场景
--================
function XGuildDormScene:OnEnterScene()
    --异步加载场景
    self.Resource = CS.XResourceManager.LoadAsync(self.SceneAssetUrl)
    CS.XTool.WaitCoroutine(self.Resource, function()
            if not self.Resource.Asset then
                XLog.Error("XGuildDormScene LoadScene error, instantiate error, name: " .. self.SceneAssetUrl)
                return
            end
            self.GameObject = CS.UnityEngine.Object.Instantiate(self.Resource.Asset)
            OnLoadComplete(self)
        end)
end
--=============
--退出场景
--=============
function XGuildDormScene:OnExitScene()
    if self.OnLeaveCb then
        self.OnLeaveCb()
    end
    self:Collect()
end
--=============
--场景回收
--=============
local function ClearGlobalIllumSOResourceMap(scene)
    for _, v in pairs(scene.GlobalIllumSOResourceMap) do
        if v then
            v:Release()
        end
    end
    scene.GlobalIllumSOResourceMap = nil
end
function XGuildDormScene:Collect()
    for _, room in pairs(self.Rooms or {}) do
        room:Dispose()
    end
    CS.UnityEngine.GameObject.Destroy(self.GameObject)
    self.GameObject = nil
    self.CurrentGlobalIllumSoPath = nil
    ClearGlobalIllumSOResourceMap(self)
    if self.Resource then
        self.Resource:Release()
    end
end
--=============
--重置天空盒
--=============
function XGuildDormScene:ResetSkyBox()
    if not self.SkyBox then return end
    self.SkyBox.gameObject:SetActiveEx(false)
    self.SkyBox.gameObject:SetActiveEx(true)
end
--===================================场景操作相关方法 End==================================




--===================================房间操作 Start========================================
--=================
--初始化房间相关
--=================
function XGuildDormScene:InitRooms(roomIndex)
    --所有房间的配置
    local rooms = XGuildDormConfig.GetAllConfigs(XGuildDormConfig.TableKey.Room)
    self.RoomId2Cfg = {} --RoomId -> 房间Cfg
    self.RoomIndex2Id = {} --房间场景内序号Cfg.Index -> RoomId
    self.Rooms = {}
    for id, roomCfg in pairs(rooms or {}) do
        --判断是否本场景的房间
        if roomCfg.SceneName == self.Name then
            self.RoomId2Cfg[id] = roomCfg
            self.RoomIndex2Id[roomCfg.Index] = id
            if roomIndex and roomCfg.Index == roomIndex then
                self.CurName = roomCfg.PrefabName
                self.CurrentRoomIndex = roomIndex
            end
        end
    end
    --如果没有指定进入房间则默认为序号1的房间
    if not self.CurName and self.RoomIndex2Id[1] then
        self.CurName = self.RoomId2Cfg[self.RoomIndex2Id[1]].PrefabName
        self.CurrentRoomIndex = 1
    end
end
--=================
--读取房间
--=================
function XGuildDormScene:LoadRooms(datas, loadtype)
    if datas == nil then
        return
    end
    local XRoom = require("XEntity/XGuildDorm/Room/XGuildDormRoom")
    for _, data in pairs(datas or {}) do
        local room = self.Rooms[data.Id]
        if not room then
            local room_trans = self.RoomRoot:FindGameObject("@Room_" .. data.Id)
            local room_trans_Putup = room_trans:FindGameObject("@Hud")
            if not XTool.UObjIsNil(room_trans) then
                room = XRoom.New(data)
                self.Rooms[data.Id] = room
                room:SetGameObject(room_trans.gameObject, loadtype)
                room:SetData(data, loadtype)
            end
        else
            room:SetData(data, loadtype)
        end
    end
end
--==============
--进入房间
--==============
function XGuildDormScene:EnterRoom(roomIndex)
    if self.CurrentRoom and self.CurrentRoomIndex == roomIndex then return end
    local roomId = self.RoomIndex2Id[roomIndex]
    if not roomId then return end
    local room = self.Rooms[roomId]
    if not room then return end
    if self.CurrentRoom then
        self.CurrentRoom:OnLeaveRoom()
    end
    self.CurrentRoom = room
    self.CurrentRoomIndex = roomIndex
    self:ChangeCameraToRoom(roomId, function()

        end)
    self.CurrentRoom:OnEnterRoom()
end
--=======================房间操作 End============================



--=======================照相机操作 Start========================
function XGuildDormScene:InitCamera()
    self.Camera = self.GameObject.transform:Find("Camera"):GetComponent("Camera")
    self.PhysicsRaycaster = self.Camera.gameObject:AddComponent(typeof(CS.UnityEngine.EventSystems.PhysicsRaycaster))

    CS.XGraphicManager.BindCamera(self.Camera)
    local cameraTargetIndex = 1
    local cameraTarget = CS.UnityEngine.GameObject.Find("@Room_" .. cameraTargetIndex)
    while cameraTarget ~= nil do
        self["CameraFollowTarget" .. cameraTargetIndex] = cameraTarget.transform
        --默认初始化选择第一个镜头跟随目标
        if cameraTargetIndex == 1 then
            self.CurCameraFollowTarget = cameraTarget.transform
        end
        cameraTargetIndex = cameraTargetIndex + 1
        cameraTarget = CS.UnityEngine.GameObject.Find("@Room_" .. cameraTargetIndex)
    end
    self.CameraController = self.Camera.gameObject:GetComponent(typeof(CS.XCameraController))
end

function XGuildDormScene:ChangeCameraToRoom(roomId, cb)
    local roomCfg = self.RoomId2Cfg[roomId]
    if not roomCfg then
        roomCfg = self.RoomId2Cfg[1]
    end
    if not roomCfg then
        XLog.Error("找不到房间Id，场景名：" .. self.Name .. " 房间Id：" .. tostring(roomId))
        return
    end
    self.CurCameraFollowTarget = self["CameraFollowTarget" .. roomCfg.Index]
    self.CurName = roomCfg.PrefabName

    XLuaUiManager.Open("UiBlackScreen", self.CurCameraFollowTarget, false, self.CurName, function()
            if cb then cb() end
        end)
end
--=======================照相机操作 End========================
return XGuildDormScene