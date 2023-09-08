---
--- 宿舍管理器
--- 管理场景上对象
---
XHomeDormManager = XHomeDormManager or {}

local XHomeRoomObj = require("XHome/XDorm/XHomeRoomObj")
local XHomeFurnitureObj = require("XHome/XDorm/XHomeFurnitureObj")
local XHomeRoomCache = require("XHome/XDorm/XHomeRoomCache")

-- 格子颜色了类型
GridColorType = {
    Default = 1,
    Green = 2,
    Red = 3,
    Interact = 4,
    Blue = 5,
}

local GRID_COLOR_PATH = {
    Default = CS.XGame.ClientConfig:GetString("HomeGridColorDefaultAssetUrl"),
    Green = CS.XGame.ClientConfig:GetString("HomeGridColorGreenAssetUrl"),
    Red = CS.XGame.ClientConfig:GetString("HomeGridColorRedAssetUrl"),
    Interact = CS.XGame.ClientConfig:GetString("HomeGridColorInteractAssetUrl"),
    Blue = CS.XGame.ClientConfig:GetString("HomeGridColorBlueAssetUrl")
}

-- local IsSelf = false
local InDormitoryScene = false

---@type table<number, XIResource>
local GridColorSoDic = {}
local ResourceCacheDic = {}

---@type XIResource
local MapResource = nil
---@type UnityEngine.Transform
local MapTransform = nil
---@type UnityEngine.Transform
local GroundRoot = nil
---@type UnityEngine.Transform
local WallRoot = nil
---@type XHomeMapManager
local HomeMapManager = nil  --房间地图配置管理器

---@type UnityEngine.GameObject
local RoomFacade = nil  --房间外墙模板
---@type UnityEngine.GameObject
local RoomRoot = nil --房间根节点 
---@type UnityEngine.GameObject
local RoomTemplateGrid = nil --模板房间
---@type table<number,XHomeRoomObj>
local RoomDic = {}

---@type UnityEngine.GameObject
local TallBuilding = nil

---@type XHomeRoomObj
local CurSelectedRoom = nil

local IsSelectedFurniture = false
local ClickFurnitureCallback = nil
local NeedLoadFurnitureOnLoad = true --是否在进入宿舍时加载家具

---@type XHomeRoomCache
local HomeFurnitureCache

---@type UnityEngine.Material[]
local FurnitureRimMat = {}
local FurnitureRedRimMatKey

XHomeDormManager.DormBgm = {}
XHomeDormManager.FurnitureShowAttrType = -1

local FurnitureMiniorType = {
    Ground = 1,
    Wall = 2,
    Ceiling = 3,
    BigFurniture = 4,
    SmallFurniture = 5,
    DecorateFurniture = 6,
    PetFurniture = 7,
}

local RecordRoomPutup = {}

local function InitFurnitureRimMat()
    for key, template in pairs(XDormConfig.GetFurnitureRimMat()) do
        local mat = CS.XMaterialContainerHelper.CloneMaterial(CS.XGraphicManager.RenderConst.RoomRimMat)
        mat:SetColor("_HighlightColor", XUiHelper.Hexcolor2Color(template.HighlightColor))
        mat:SetFloat("_MinHighLightLevel", template.MinHighLightLevel)
        mat:SetFloat("_MaxHighLightLevel", template.MaxHighLightLevel)
        mat:SetFloat("_HighlightSpeed", template.HighlightSpeed)
        mat:SetFloat("_ColorIntensity", template.ColorIntensity)
        mat:SetFloat("_Alpha", template.Alpha)
        FurnitureRimMat[key] = mat
    end
end

--- 初始化场景
---@param go UnityEngine.GameObject 场景根物体
---@param homeDormDataMap table<number,XHomeRoomData> 场景根物体
---@param dormDataType number 加载宿舍类型XDormConfig.DormDataType
---@param onFinishLoadScene function 场景全部加载完宿舍界面打开后执行
---@param isEnterRoom boolean 是否进入房间内
--------------------------
local function InitScene(go, homeDormDataMap, dormDataType, onFinishLoadScene, isEnterRoom)

    HomeFurnitureCache = HomeFurnitureCache or XHomeRoomCache.New(XDormConfig.DormLoadCacheCount)
    InitFurnitureRimMat()
    -- 初始化格子
    CS.XGridManager.Instance:Init()

    --场景全局光照
    XHomeSceneManager.SetGlobalIllumSO(CS.XGame.ClientConfig:GetString("HomeSceneSoAssetUrl"))

    --格子颜色信息资源
    for key, path in pairs(GRID_COLOR_PATH) do
        local resource = CS.XResourceManager.Load(path)
        if resource then
            GridColorSoDic[GridColorType[key]] = resource
        end
    end

    TallBuilding = go.transform:Find("GroupBase/@TallBuilding")
    -- 房间盖
    RoomFacade = go.transform:Find("@RoomFacade")
    -- 所有房间的根节点
    RoomRoot = go.transform:Find("@Room")
    -- 默认的房间模板
    RoomTemplateGrid = go.transform:Find("@Room/@Room_Template")
    if not XTool.UObjIsNil(RoomTemplateGrid) then
        RoomTemplateGrid.gameObject:SetActiveEx(false)
    end

    if not XTool.UObjIsNil(RoomRoot) then
        -- 加载房间数据
        XHomeDormManager.LoadRooms(homeDormDataMap, dormDataType)
    end
    -- 加载收藏宿舍的入口图片
    XDataCenter.DormManager.LoadCollectTexture()

    local camera = XHomeSceneManager.GetSceneCamera()
    HomeMapManager:SetCamera(camera)

    if dormDataType == XDormConfig.DormDataType.Self then
        XLuaUiManager.OpenWithCallback("UiDormMain", function()
            -- 做了个宿舍的组件，额外组合原有宿舍的功能
            XLuaUiManager.Open("UiDormComponent")

            -- 全部加载场景回调，打开宿舍界面时传递
            if onFinishLoadScene then
                onFinishLoadScene()
            end
            if isEnterRoom then
                XLuaUiManager.Open("UiDormSecond", XDormConfig.VisitDisplaySetType.MySelf, XHomeDormManager.DormitoryId)
            end
        end)
    else
        if not XLuaUiManager.IsUiLoad("UiDormSecond") then
            local visit = XDormConfig.VisitDisplaySetType.Stranger
            if XDataCenter.SocialManager.CheckIsFriend(XHomeDormManager.TargetId) then
                visit = XDormConfig.VisitDisplaySetType.MyFriend
            end
            XLuaUiManager.OpenWithCallback("UiDormSecond", function()
                XLuaUiManager.Close("UiLoading")
            end, visit, XHomeDormManager.DormitoryId)
        end
    end
    -- 宿舍角色相关的事件监听
    XHomeCharManager.Init()
    InDormitoryScene = true
end

-- 移除场景
local function RemoveScene()
    InDormitoryScene = false
    NeedLoadFurnitureOnLoad = true
    CS.XGridManager.Instance:Clear()
    for _, v in pairs(GridColorSoDic) do
        if v then
            v:Release()
        end
    end
    GridColorSoDic = {}

    XLuaUiManager.Close("UiDormComponent")

    RoomFacade = nil
    RoomRoot = nil
    RoomTemplateGrid = nil
    for _, room in pairs(RoomDic) do
        room:Dispose()
    end
    RoomDic = {}
    HomeFurnitureCache:Clear()
    CurSelectedRoom = nil

    HomeMapManager = nil
    GroundRoot = nil
    WallRoot = nil
    if not XTool.UObjIsNil(MapTransform) then
        XUiHelper.Destroy(MapTransform.gameObject)
    end
    MapTransform = nil
    if MapResource then
        MapResource:Release()
    end
    MapResource = nil

    for _, v in pairs(ResourceCacheDic) do
        CS.XResourceManager.Unload(v)
    end
    for _, mat in pairs(FurnitureRimMat) do
        XUiHelper.Destroy(mat)
    end
    FurnitureRimMat = {}
    ResourceCacheDic = {}
end

--- 初始化地表地图
---@param model UnityEngine.GameObject
--------------------------
local function InitSurfaceMap(model)
    MapTransform = model.transform
    GroundRoot = MapTransform:Find("@GroundRoot")
    WallRoot = MapTransform:Find("@WallRoot")
    MapTransform:SetParent(nil)
    MapTransform.gameObject:SetActiveEx(false)
    HomeMapManager = model:GetComponent("XHomeMapManager")
    HomeMapManager:Init()
end

--- 进入宿舍
---@param targetId number 用户Id
---@param dormitoryId number 宿舍Id
---@param isEnterRoom boolean 是否进入房间内
---@param onFinishLoadScene function 场景全部加载完宿舍界面打开后执行
---@param onFinishEnterRoom function 宿舍Id
---@return
--------------------------
function XHomeDormManager.EnterDorm(targetId, dormitoryId, isEnterRoom, onFinishLoadScene, onFinishEnterRoom)
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    local isSelf = true
    local dormDataType = XDormConfig.DormDataType.Self
    XHomeDormManager.TargetId = targetId
    XHomeDormManager.DormitoryId = dormitoryId

    if targetId and targetId ~= XPlayer.Id then
        isSelf = false
        dormDataType = XDormConfig.DormDataType.Target
    end

    local cb = function()
        -- IsSelf = isSelf
        -- 根据房间类型获取房间数据XHomeRoomData
        local datas = XDataCenter.DormManager.GetDormitoryData(dormDataType)
        NeedLoadFurnitureOnLoad = XDormConfig.GetDormFurnitureTotal(datas) <= XDormConfig.LoadThresholdTotal

        local onLoadCompleteCb = function(go)
            go.gameObject:SetActiveEx(true)
            -- 初始化场景
            InitScene(go, datas, dormDataType, onFinishLoadScene, isEnterRoom)

            if dormitoryId and isEnterRoom then
                XHomeDormManager.SetSelectedRoom(dormitoryId, true, nil, onFinishEnterRoom)
            end
        end

        XDataCenter.DormManager.RequestDormitoryDormEnter()

        -- 加载房间管理器
        MapResource = CS.XResourceManager.Load(CS.XGame.ClientConfig:GetString("HomeMapAssetUrl"))
        local model = CS.UnityEngine.Object.Instantiate(MapResource.Asset)
        -- 初始化地表地图，获取C#XHomeMapManager脚本，找到地板、墙壁根节点
        InitSurfaceMap(model)
        -- 设置全局光照
        XUiHelper.SetSceneType(CS.XSceneType.Dormitory)
        -- 进入场景
        XHomeSceneManager.EnterScene("sushe003", CS.XGame.ClientConfig:GetString("SuShe003"), onLoadCompleteCb, RemoveScene)

    end

    if isSelf then
        cb()
    else
        local charId = XDataCenter.DormManager.GetVisitorDormitoryCharacterId()
        XDataCenter.DormManager.RequestDormitoryVisit(targetId, dormitoryId, charId, cb)
    end
end

--获取房间信息
function XHomeDormManager.GetRoom(roomId)
    if not RoomDic then
        return nil
    end

    return RoomDic[roomId]
end

--设置房间交互信息GameObject
function XHomeDormManager.SetRoomInteractInfo(roomId)
    local room = XHomeDormManager.GetRoom(roomId)
    if room then
        room:SetInteractInfoGo()
    end
end

--隐藏房间交互信息GameObject
function XHomeDormManager.HideRoomInteractInfo(roomId)
    local room = XHomeDormManager.GetRoom(roomId)
    if room then
        room:HideInteractInfoGo()
    end
end

-- 加载模板以及收藏宿舍
local function LoadTemplateRooms(datas, loadtype, isNotChangeView)
    for _, data in pairs(datas) do
        local room = RoomDic[data.Id]
        if not room then
            if not XTool.UObjIsNil(RoomTemplateGrid) then
                room = XHomeRoomObj.New(data)
                RoomDic[data.Id] = room
                room:SetModel(RoomTemplateGrid.gameObject, loadtype)
                RoomTemplateGrid.gameObject:SetActiveEx(true)
            end
        else
            room:SetData(data, loadtype)
        end
    end
    if not isNotChangeView then
        XHomeSceneManager.ChangeView(HomeSceneViewType.OverView)
    end
end

-- 加载宿舍房间
function XHomeDormManager.LoadRooms(datas, loadtype, isNotChangeView)
    if datas == nil then
        return
    end

    -- 如果是模板宿舍，比如是收藏、展示、其他玩家等，直接走LoadTemplateRooms接口
    if XDormConfig.IsTemplateRoom(loadtype) then
        LoadTemplateRooms(datas, loadtype, isNotChangeView)
        return
    end

    for _, data in pairs(datas) do
        local room = RoomDic[data.Id]
        if not room then
            local room_trans = RoomRoot:Find("@Room_" .. data.Id)
            local room_trans_Putup = room_trans:Find("@Hud")
            if not XTool.UObjIsNil(room_trans) then
                -- 创建房间obj
                room = XHomeRoomObj.New(data, RoomFacade)
                RoomDic[data.Id] = room
                room:SetModel(room_trans.gameObject, loadtype)
                RecordRoomPutup[data.Id] = room_trans_Putup
            end
        else
            -- 重新设置房间数据
            room:SetData(data, loadtype)
        end
    end

    if not isNotChangeView then
        XHomeSceneManager.ChangeView(HomeSceneViewType.OverView)
    end
end

function XHomeDormManager.GetRoomsPutup(dormId)
    return RecordRoomPutup[dormId]
end

-- 将地图网格挂到指定房间根节点
function XHomeDormManager.AttachSurfaceToRoom(roomId)
    if not roomId then
        MapTransform.gameObject:SetActiveEx(false)
    end

    local room = RoomDic[roomId]
    if room and not XTool.UObjIsNil(room.Transform) then
        local groundSurface = GroundRoot:GetComponentInChildren(typeof(CS.XHomeSurface))
        if not XTool.UObjIsNil(groundSurface) then
            groundSurface.ConfigId = room.Ground.Data.CfgId
        end

        if room.Wall == nil then
            XLog.Error("缺少墙的数据....(迷惑)")
            return
        end
        -- 4个
        local wallSurfaceArr = WallRoot:GetComponentsInChildren(typeof(CS.XHomeSurface))

        if wallSurfaceArr == nil or wallSurfaceArr.Length < 4 then
            XLog.Error("墙体数据不匹配")
        end

        for i = 0, wallSurfaceArr.Length - 1 do
            wallSurfaceArr[i].ConfigId = room.Wall.Data.CfgId
        end

        MapTransform:SetParent(room.Transform, false)
        MapTransform.localPosition = CS.UnityEngine.Vector3.zero;
        MapTransform.localRotation = CS.UnityEngine.Quaternion.identity
        MapTransform.localScale = CS.UnityEngine.Vector3.one

        MapTransform.gameObject:SetActiveEx(true)
    end
end

--锁定墙体碰撞盒
function XHomeDormManager.LockCollider(rotate)
    if XTool.UObjIsNil(HomeMapManager) then
        return
    end
    HomeMapManager:LockCollider(rotate)
end


function XHomeDormManager.OnShowBlockGrids(platType, gridOffset, rotate)
    if XTool.UObjIsNil(HomeMapManager) then
        return
    end

    local so = XHomeDormManager.GetGridColorSO(GridColorType.Red)
    HomeMapManager:OnShowBlockGrids(platType, gridOffset, so.Asset, rotate)
end

function XHomeDormManager.OnHideBlockGrids(platType, rotate)
    if XTool.UObjIsNil(HomeMapManager) then
        return
    end

    HomeMapManager:OnHideBlockGrids(platType, rotate)
end

--解锁墙体碰撞盒
function XHomeDormManager.UnlockCollider()
    if XTool.UObjIsNil(HomeMapManager) then
        return
    end
    HomeMapManager:UnlockCollider()
end

--获取家具交互点格子坐标
function XHomeDormManager.GetInteractGridPos(furnitureX, furnitureY, width, height, x, y, rotate)
    if XTool.UObjIsNil(HomeMapManager) then
        return
    end

    -- 返回（格子坐标；该坐标是否在房间地图内）
    return HomeMapManager:GetInteractGridPos(furnitureX, furnitureY, width, height, x, y, rotate)
end

-- 获取地图格子边长
function XHomeDormManager.GetCeilSize()
    if XTool.UObjIsNil(HomeMapManager) then
        return 0
    end
    return HomeMapManager.CeilSize
end

-- 获取地图宽
function XHomeDormManager.GetMapWidth()
    if XTool.UObjIsNil(HomeMapManager) then
        return 0
    end
    return HomeMapManager.MapSize.x
end

-- 获取地图高
function XHomeDormManager.GetMapHeight()
    if XTool.UObjIsNil(HomeMapManager) then
        return 0
    end
    return HomeMapManager.MapSize.y
end

-- 获取地图墙高
function XHomeDormManager.GetMapTall()
    if XTool.UObjIsNil(HomeMapManager) then
        return 0
    end
    return HomeMapManager.MapSize.z
end

-- 获取格子颜色SO
function XHomeDormManager.GetGridColorSO(gridColorType)
    return GridColorSoDic[gridColorType]
end

-- 显示地表网格
function XHomeDormManager.ShowSurface(type)
    if XTool.UObjIsNil(MapTransform) then
        return
    end

    if type == CS.XHomePlatType.Ground then
        GroundRoot.gameObject:SetActiveEx(true)
        WallRoot.gameObject:SetActiveEx(false)
    elseif type == CS.XHomePlatType.Wall then
        GroundRoot.gameObject:SetActiveEx(false)
        WallRoot.gameObject:SetActiveEx(true)
    end
end

function XHomeDormManager.ReformRoom(roomId, isBegin)
    local room = RoomDic[roomId]
    if not room then
        return
    end

    room:Reform(isBegin)
end

function XHomeDormManager.ClearFurnitureAnimation(roomId)
    local room = RoomDic[roomId]
    if not room then
        return
    end
    room:ClearFurnitureAnimation()
end

-- 收起房间全部家具
function XHomeDormManager.CleanRoom(roomId)
    local room = RoomDic[roomId]
    if not room then
        return
    end

    room:CleanRoom()
end

-- 重置房间
function XHomeDormManager.RevertRoom(roomId)
    local room = RoomDic[roomId]
    if not room then
        return
    end

    room:RevertRoom()
end

function XHomeDormManager.RevertOnWall(roomId)
    local room = RoomDic[roomId]
    if not room then
        return
    end

    room:CleanWallFurniture()
end

-- 重置当前宿舍光照
function XHomeDormManager.SetIllumination()
    if CurSelectedRoom then
        CurSelectedRoom:SetIllumination()
    end
end

-- 保存房间摆设
function XHomeDormManager.SaveRoomModification(roomId, isBehavior, cb)
    local room = RoomDic[roomId]
    if not room then
        return
    end

    XDataCenter.DormManager.RequestDecorationRoom(roomId, room, isBehavior, cb)
end

--- 创建家具
---@param roomId number 房间Id
---@param furnitureData XHomeRoomData 房间数据
---@param gridPos UnityEngine.Vector2 格子坐标
---@param rotate number 在Y轴的旋转角度
---@param isAsync boolean 是否异步
---@param onComplete function 加载完成回调
---@return XHomeFurnitureObj
--------------------------
function XHomeDormManager.CreateFurniture(roomId, furnitureData, gridPos, rotate, isAsync, onComplete)
    if not furnitureData then
        return
    end

    local room = RoomDic[roomId]
    if not room then
        return nil
    end

    local isTemplateRoom = XDormConfig.IsTemplateRoom(room.CurLoadType)
    local id = furnitureData.Id or 0
    if isTemplateRoom and id == 0 then
        id = XGlobalVar.GetIncId()
    end

    local data = {}
    data.Id = id
    data.CfgId = furnitureData.ConfigId
    data.GridX = gridPos.x
    data.GridY = gridPos.y
    data.RotateAngle = rotate

    local furniture = XHomeFurnitureObj.New(data, room, onComplete)
    local root
    if furniture.Cfg.LocateType == XFurnitureConfigs.HomeLocateType.Replace then
        root = room.SurfaceRoot
    else
        root = room.FurnitureRoot
    end

    if string.IsNilOrEmpty(furniture.Cfg.Model) then
        XLog.Warning("加载家具失败，家具模型Url为空, 家具Id = " .. furnitureData.ConfigId)
        return
    end

    if isAsync then
        furniture:LoadModelAsync(furniture.Cfg.Model, root)
    else
        furniture:LoadModel(furniture.Cfg.Model, root)
    end
    if isTemplateRoom then
        return furniture
    end

    return furniture
end

function XHomeDormManager.UpdateFurnitureData(roomId, oldIds, newIds)
    local room = RoomDic[roomId]
    if not room then
        return
    end

    room:UpdateFurnitureData(oldIds, newIds)
end

function XHomeDormManager.GetFurnitureObj(roomId, furnitureId)
    if not XTool.IsNumberValid(roomId) or not XTool.IsNumberValid(furnitureId) then
        return
    end
    local room = RoomDic[roomId]
    if not room then
        return
    end
    
    return room:GetFurnitureObjById(furnitureId)
end

function XHomeDormManager.CancelSelectRayCast(roomId)
    if not XTool.IsNumberValid(roomId) then
        return
    end
    local room = RoomDic[roomId]
    if not room then
        return
    end
    room:CancelSelectRayCast()
end

function XHomeDormManager.ReplaceFurnitureMaterial(furniture, furnitureId, dormDataType)
    local materialPath = XDataCenter.FurnitureManager.GetFurnitureMaterial(furnitureId, dormDataType)
    if not materialPath then
        return
    end
    local targetMaterial = ResourceCacheDic[materialPath]
    if not targetMaterial then
        targetMaterial = CS.XResourceManager.Load(materialPath)
        ResourceCacheDic[materialPath] = targetMaterial
    end
    CS.XMaterialContainerHelper.ReplaceDormMat(furniture.GameObject, targetMaterial.Asset)
end

function XHomeDormManager.ReplaceFurnitureFx(furniture, furnitureId, dormDataType)
    local fxPath = XDataCenter.FurnitureManager.GetFurnitureFx(furnitureId, dormDataType)
    if not fxPath then
        return
    end

    local effect = furniture.Transform:Find("Effect")
    if not effect then return end
    effect.gameObject:LoadPrefab(fxPath)
end

-- 更换基础装修
function XHomeDormManager.ReplaceSurface(roomId, furniture)
    local room = RoomDic[roomId]
    if not room then
        return nil
    end

    room:ReplaceSurface(furniture)
end

-- 检测房间中家具类型数量限制
function XHomeDormManager.CheckFurnitureCountReachLimit(roomId, furniture)
    local room = RoomDic[roomId]
    if not room then
        return true
    end
    return room:CheckFurnitureCountReachLimit(furniture)
end

-- 检测房间中家具类型数量限制
function XHomeDormManager.CheckFurnitureCountReachLimitByPutNumType(roomId, putNumType)
    local room = RoomDic[roomId]
    if not room then
        return true
    end
    return room:CheckFurnitureCountReachLimitByPutNumType(putNumType)
end

-- 往房间中加入家具
function XHomeDormManager.AddFurniture(roomId, furniture)
    local room = RoomDic[roomId]
    if not room then
        return nil
    end
    room:AddFurniture(furniture)
end

-- 从房间中移除家具
function XHomeDormManager.RemoveFurniture(roomId, furniture)
    local room = RoomDic[roomId]
    if not room then
        return nil
    end

    room:RemoveFurniture(furniture)
end

-- 选中指定房间
function XHomeDormManager.SetSelectedRoom(roomId, isSelected, isVisitor, onFinishEnterRoom)
    -- 镜面管理
    CS.XMirrorManager.Instance:SetDormLayer(isSelected, CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.Device))
    local room = RoomDic[roomId]
    if not room then
        return nil
    end
    if CurSelectedRoom then
        if CurSelectedRoom.Data.Id == room.Data.Id then
            CurSelectedRoom:SetCharacterExit()
            CurSelectedRoom:SetSelected(isSelected, true, isSelected and onFinishEnterRoom or nil)
            if isVisitor and not isSelected then
                CurSelectedRoom = nil
            end
            if not isSelected then
                XHomeSceneManager.SetGlobalIllumSO(CS.XGame.ClientConfig:GetString("HomeSceneSoAssetUrl"))
            end
            return
        end

        CurSelectedRoom:SetSelected(false)
    end

    -- 选中当前的房间，进入，创建角色
    room:SetSelected(isSelected, true, onFinishEnterRoom)
    if isSelected then
        CurSelectedRoom = room
    end
end

function XHomeDormManager.CharacterExit(roomId)
    local room = RoomDic[roomId]
    if not room then
        return
    end
    room:SetCharacterExit()
end

-- 显示或隐藏指定房间的外部景物
function XHomeDormManager.ShowOrHideOutsideRoom(baseRoomId, isShowOutside)
    -- 场景上高楼
    if not XTool.UObjIsNil(TallBuilding) then
        TallBuilding.gameObject:SetActiveEx(isShowOutside)
    end

    -- 其他房间
    for id, room in pairs(RoomDic) do
        local isTemplateRoom = XDormConfig.IsTemplateRoom(room.CurLoadType)
        if id ~= baseRoomId and not isTemplateRoom then
            room.GameObject:SetActiveEx(isShowOutside)
        end
    end
end

-- 显示构造体详情时 显示隐藏指定房间的外部景物
function XHomeDormManager.ShowOrHideBuilding(isShowOutside)
    -- 场景上高楼
    if not XTool.UObjIsNil(TallBuilding) then
        TallBuilding.gameObject:SetActiveEx(isShowOutside)
    end
end

-- 设置选中家具
function XHomeDormManager.SetSelectedFurniture(selected)
    IsSelectedFurniture = selected
end

-- 检测当前是否选中家具
function XHomeDormManager.CheckSelectedFurniture()
    return IsSelectedFurniture
end

-- 设置点击家具回调
function XHomeDormManager.SetClickFurnitureCallback(cb)
    ClickFurnitureCallback = cb
end

-- 调用点击家具回调
function XHomeDormManager.FireClickFurnitureCallback(furniture)
    if ClickFurnitureCallback then
        ClickFurnitureCallback(furniture)
    end
end

-- 检测家具是否被阻挡
function XHomeDormManager.CheckRoomFurnitureBlock(roomId, furnitureId, x, y, width, height, type, rotate)
    local room = RoomDic[roomId]
    if room then
        return room:CheckFurnitureBlock(furnitureId, x, y, width, height, type, rotate)
    end

    return true, CS.UnityEngine.Vector3.zero
end

-- 检测家具碰撞
function XHomeDormManager.CheckRoomFurnitureCollider(furniture, roomId)
    local room = RoomDic[roomId]
    return room:CheckFurnituresCollider(furniture) or false
end

-- 获取本地坐标
function XHomeDormManager.GetLocalPosByGrid(x, y, type, rotate)
    if not XTool.UObjIsNil(HomeMapManager) then
        return HomeMapManager:GetLocalPosByGrid(x, y, type, rotate)
    end
end

-- 检测地图是否有阻挡
function XHomeDormManager.CheckMultiBlock(blockCfgId, x, y, width, height, type, rotate)
    if not XTool.UObjIsNil(HomeMapManager) then
        return HomeMapManager:CheckMultiBlock(blockCfgId, x, y, width, height, type, rotate)
    end
end

-- 世界坐标转地板格子坐标
function XHomeDormManager.WorldPosToGroundGridPos(worldPos, roomTransform)
    if XTool.UObjIsNil(HomeMapManager) then
        return CS.UnityEngine.Vector2.zero, 0
    end

    local localPos = roomTransform.worldToLocalMatrix:MultiplyPoint(worldPos)
    local gridPos = HomeMapManager:GetGridPosByLocal(localPos, CS.XHomePlatType.Ground, 0, 1, 1)

    return gridPos
end

-- 检测世界坐标是否在地图边界
function XHomeDormManager.WorldPosCheckIsInBound(worldPos, roomTransform)
    if XTool.UObjIsNil(HomeMapManager) then
        return false
    end

    local localPos = roomTransform.worldToLocalMatrix:MultiplyPoint(worldPos)
    local gridPos = HomeMapManager:GetGridPosByLocal(localPos, CS.XHomePlatType.Ground, 0)
    local valid = HomeMapManager:CheckIsInBound(CS.XHomePlatType.Ground, gridPos.x, gridPos.y, 0)
    return valid
end

-- 获取格子坐标
function XHomeDormManager.GetGridPosByWorldPos(worldPos, transform, width, height)
    if XTool.UObjIsNil(HomeMapManager) then
        return CS.UnityEngine.Vector3.zero, 0
    end

    local type, rotate
    local name = transform.name
    
    if name == "@Wall01" then
        type = CS.XHomePlatType.Wall
        rotate = 0
    elseif name == "@Wall02" then
        type = CS.XHomePlatType.Wall
        rotate = 1
    elseif name == "@Wall03" then
        type = CS.XHomePlatType.Wall
        rotate = 2
    elseif name == "@Wall04" then
        type = CS.XHomePlatType.Wall
        rotate = 3
    else
        type = CS.XHomePlatType.Ground
        rotate = 0
    end

    local localPos = HomeMapManager.transform.worldToLocalMatrix:MultiplyPoint(worldPos)
    local gridPos = HomeMapManager:GetGridPosByLocal(localPos, type, rotate, width, height)

    return gridPos, rotate
end

-- 获取某个宿舍，某类型家具的数量
function XHomeDormManager.GetFurnitureNumsByRoomAndMinor(roomId, minorType)

    local room = RoomDic[roomId]
    if not room then
        return 0
    end

    local roomData = room:GetData()

    if minorType == FurnitureMiniorType.Ground then
        return 1
    elseif minorType == FurnitureMiniorType.Wall then
        return 1
    elseif minorType == FurnitureMiniorType.Ceiling then
        return 1
    end

    local furnitureList = roomData:GetFurnitureDic()
    local totalNum = 0
    for _, v in pairs(furnitureList) do
        local furnitureTemplate = XFurnitureConfigs.GetFurnitureTemplateById(v.ConfigId)
        local furnitureMinorType = XFurnitureConfigs.GetFurnitureTypeById(furnitureTemplate.TypeId)
        if minorType == furnitureMinorType.MinorType then
            totalNum = totalNum + 1
        end
    end
    return totalNum
end

-- 获取某个宿舍，某类型家具的容量
function XHomeDormManager.GetFurnitureCapacityByRoomANdMinor(roomId, minorType, roomType)
    local roomTemplate
    if XDormConfig.IsTemplateRoom(roomType) then
        roomTemplate = XDormConfig.GetDefaultDormitory()
    else
        roomTemplate = XDormConfig.GetDormitoryCfgById(roomId)
    end

    if minorType == FurnitureMiniorType.Ground or minorType == FurnitureMiniorType.Wall or minorType == FurnitureMiniorType.Ceiling then
        return 1
    elseif minorType == FurnitureMiniorType.BigFurniture then
        return roomTemplate.BigFurnitureCapacity or 0
    elseif minorType == FurnitureMiniorType.SmallFurniture then
        return roomTemplate.SmallFurnitureCapacity or 0
    elseif minorType == FurnitureMiniorType.DecorateFurniture then
        return roomTemplate.DecorateCapacity or 0
    elseif minorType == FurnitureMiniorType.PetFurniture then
        return roomTemplate.PetCapacity or 0
    else
        return 0
    end
end

function XHomeDormManager.GetFurnitureScoresByRoomData(roomData, dormDataType)
    local furnitureIdList = {}
    local totalScore = 0
    local attrList = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
    }

    if not roomData then
        return totalScore, attrList
    end

    local furnitureList = roomData:GetFurnitureDic()
    for _, v in pairs(furnitureList) do
        table.insert(furnitureIdList, {
            furnitureId = v.Id
        })

    end
    local curdormDataType = XDormConfig.DormDataType.Target
    if not dormDataType then
        curdormDataType = XDormConfig.DormDataType.Self
    end
    for _, v in pairs(furnitureIdList) do
        local redScore = XDataCenter.FurnitureManager.GetFurnitureRedScore(v.furnitureId, curdormDataType)
        local yellowScore = XDataCenter.FurnitureManager.GetFurnitureYellowScore(v.furnitureId, curdormDataType)
        local blueScore = XDataCenter.FurnitureManager.GetFurnitureBlueScore(v.furnitureId, curdormDataType)
        totalScore = totalScore + XDataCenter.FurnitureManager.GetFurnitureScore(v.furnitureId, curdormDataType)
        --totalScore = totalScore + redScore + yellowScore + blueScore
        attrList[1] = attrList[1] + redScore
        attrList[2] = attrList[2] + yellowScore
        attrList[3] = attrList[3] + blueScore
    end

    return {
        TotalScore = totalScore,
        AttrList = attrList
    }
end

function XHomeDormManager.GetFurnitureScoresByUnSaveRoom(roomId, dormDataType)
    local room = RoomDic[roomId]
    local totalScore = 0
    local attrList = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
    }
    if not room then
        return {
            TotalScore = totalScore,
            AttrList = attrList
        }
    end

    local roomData = XDataCenter.DormManager.GetRoomDataByRoomId(roomId, dormDataType)

    return XHomeDormManager.GetFurnitureScoresByRoomData(roomData, dormDataType)
end

-- 获取
function XHomeDormManager.GetFurnitureScoresByRoomId(roomId, dormDataType)
    local room = RoomDic[roomId]
    local totalScore = 0
    local attrList = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
    }
    if not room then
        return {
            TotalScore = totalScore,
            AttrList = attrList
        }
    end

    local roomData = room:GetData()

    return XHomeDormManager.GetFurnitureScoresByRoomData(roomData, dormDataType)
end

-- 获取宿舍内3D坐标 对应2D坐标
function XHomeDormManager.GetWorldToViewPoint(roomId, pos)
    local room = RoomDic[roomId]
    local camera = XHomeSceneManager.GetSceneCamera()

    if not room or not camera then
        XLog.Error("XHomeDormManager.GetWorldToViewPoint error room is null, id is " .. roomId)
        return CS.UnityEngine.Vector3.zero
    end

    local screenPos = camera:WorldToViewportPoint(pos)
    screenPos.x = screenPos.x * CsXUiManager.RealScreenWidth
    screenPos.y = screenPos.y * CsXUiManager.RealScreenHeight

    return screenPos
end

function XHomeDormManager.GetFurnitureFromList(id, furntiureList)
    if not furntiureList then
        return nil
    end
    for _, v in pairs(furntiureList) do
        if v.Id == id then
            return v
        end
    end
    return nil
end


-- 是否需要保存宿舍, 宿舍任何物品稍微有改动则需要提示玩家保存
function XHomeDormManager.IsNeedSave(roomId, roomDataType)
    local room = RoomDic[roomId]
    if not room then
        return false
    end

    local lastSaveData = XDataCenter.DormManager.GetRoomDataByRoomId(roomId, roomDataType)
    local currentData = room:GetData()

    -- 家具(数量不一致，或者位置、角度不一致，提示保存)
    local lastFurnitureList = lastSaveData:GetFurnitureDic()
    local currentFurnitureList = currentData:GetFurnitureDic()
    local isMyRoom = roomDataType == XDormConfig.DormDataType.Self

    local lastFurnitureNum = XHomeDormManager.GetFurnitureNumsByDic(lastFurnitureList)
    local currentFurnitureNum = XHomeDormManager.GetFurnitureNumsByDic(currentFurnitureList)
    if lastFurnitureNum ~= currentFurnitureNum then
        return true
    end

    for _, v in pairs(lastFurnitureList) do
        local currentFurniture = currentFurnitureList[v.Id]
        if currentFurniture == nil then
            return true
        end

        if isMyRoom then
            -- 地板，天花板，墙
            if XDataCenter.FurnitureManager.IsFurnitureMatchType(v.Id, XFurnitureConfigs.HomeSurfaceBaseType.Ground) then
                if v.Id ~= room.Ground.Data.Id then
                    return true
                end
            elseif XDataCenter.FurnitureManager.IsFurnitureMatchType(v.Id, XFurnitureConfigs.HomeSurfaceBaseType.Ceiling) then
                if v.Id ~= room.Ceiling.Data.Id then
                    return true
                end
            elseif XDataCenter.FurnitureManager.IsFurnitureMatchType(v.Id, XFurnitureConfigs.HomeSurfaceBaseType.Wall) then
                if v.Id ~= room.Wall.Data.Id then
                    return true
                end
            else
                if v.ConfigId ~= currentFurniture.ConfigId or v.GridX ~= currentFurniture.GridX or
                v.GridY ~= currentFurniture.GridY or v.RotateAngle ~= currentFurniture.RotateAngle then
                    return true
                end
            end
        else
            -- 地板，天花板，墙
            if XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(v.ConfigId, XFurnitureConfigs.HomeSurfaceBaseType.Ground) then
                if v.ConfigId ~= room.Ground.Data.CfgId then
                    return true
                end
            elseif XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(v.ConfigId, XFurnitureConfigs.HomeSurfaceBaseType.Ceiling) then
                if v.ConfigId ~= room.Ceiling.Data.CfgId then
                    return true
                end
            elseif XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(v.ConfigId, XFurnitureConfigs.HomeSurfaceBaseType.Wall) then
                if v.ConfigId ~= room.Wall.Data.CfgId then
                    return true
                end
            else
                if v.ConfigId ~= currentFurniture.ConfigId or v.GridX ~= currentFurniture.GridX or
                v.GridY ~= currentFurniture.GridY or v.RotateAngle ~= currentFurniture.RotateAngle then
                    return true
                end
            end
        end
    end

    return false
end

--- 是否需要保存模板宿舍
---@return boolean
--------------------------
function XHomeDormManager.IsNeedSaveByTemplate(roomId, roomType, targetRoomId)
    local room = RoomDic[targetRoomId]
    if not room then
        return false
    end
    --模板数据
    local templateData = XDataCenter.DormManager.GetRoomDataByRoomId(roomId, roomType)
    --目标数据
    local targetData = room:GetData()
    
    local templateList = templateData:GetFurnitureDic()
    local targetList = targetData:GetFurnitureDic()
    
    local templateCount = XHomeDormManager.GetFurnitureNumsByDic(templateList)
    local targetCount = XHomeDormManager.GetFurnitureNumsByDic(targetList)

    if targetCount ~= templateCount then
        return true
    end
    
    local furnitureObjMap = room:GetAllFurnitureObj()

    for _, furniture in pairs(templateList) do
        -- 地板，天花板，墙
        if XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(furniture.ConfigId, XFurnitureConfigs.HomeSurfaceBaseType.Ground) then
            if furniture.ConfigId ~= room.Ground.Data.CfgId then
                return true
            end
        elseif XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(furniture.ConfigId, XFurnitureConfigs.HomeSurfaceBaseType.Ceiling) then
            if furniture.ConfigId ~= room.Ceiling.Data.CfgId then
                return true
            end
        elseif XFurnitureConfigs.IsFurnitureMatchTypeByConfigId(furniture.ConfigId, XFurnitureConfigs.HomeSurfaceBaseType.Wall) then
            if furniture.ConfigId ~= room.Wall.Data.CfgId then
                return true
            end
        else
            local furnitureObj = furnitureObjMap[room:GetIdByTemplateFurnitureId(furniture.Id)]
            if not furnitureObj then
                return true
            end
            if furniture.ConfigId ~= furnitureObj.Data.CfgId or furniture.GridX ~= furnitureObj.GridX or
                    furniture.GridY ~= furnitureObj.GridY or furniture.RotateAngle ~= furnitureObj.RotateAngle then
                return true
            end
        end
    end
    
    return false
end

function XHomeDormManager.GetFurnitureNumsByDic(furnitureDic)
    local totalNum = 0
    if not furnitureDic then
        return totalNum
    end
    for _, _ in pairs(furnitureDic) do
        totalNum = totalNum + 1
    end
    return totalNum
end

-- 获取单个房间
function XHomeDormManager.GetSingleDormByRoomId(roomId)
    local room = RoomDic[roomId]
    return room
end

function XHomeDormManager.RaycastUnOwnedFurniture(currentRoomId, targetRoomId, currentRoomType, targetRoomType)
    local current = XDataCenter.DormManager.GetRoomDataByRoomId(currentRoomId, currentRoomType)
    local target = XDataCenter.DormManager.GetRoomDataByRoomId(targetRoomId, targetRoomType)

    if not current or not target then
        return
    end

    local room = RoomDic[currentRoomId]
    if not room then
        return
    end
    
    local currentFurniture = current:GetFurnitureConfigDic()
    local targetFurniture = target:GetFurnitureConfigDic()
    local bagFurniture = XDataCenter.FurnitureManager.GetUnUseFurniture()
    
    local unOwn = {}

    for configId, furnitureIds in pairs(currentFurniture) do
        local needCount = #furnitureIds
        local targetCount = #(targetFurniture[configId] or {})
        local bagCount = #(bagFurniture[configId] or {})
        local ownCount = targetCount + bagCount
        if needCount > ownCount then
            for i = ownCount + 1, needCount do
                table.insert(unOwn, furnitureIds[i])
            end
        end
    end
    
    local dict = room:GetAllFurnitureObj()
    for _, furnitureId in pairs(unOwn) do
        local obj = dict[furnitureId]
        if obj and obj.RayCastNotOwn then
            obj:RayCastNotOwn(true)
        end
    end
end

function XHomeDormManager.DormistoryGetFarestWall(dormitoryId)
    local room = XHomeDormManager.GetSingleDormByRoomId(dormitoryId)
    local totalWallNums = 4
    local wallPositions = {}

    for i = 1, totalWallNums do
        wallPositions[i] = room.Transform:Find(string.format("HomeMapManager(Clone)/@WallRoot/@Wall0%d", i)).position
    end

    local camera = XHomeSceneManager.GetSceneCamera()
    if not camera then
        return 1
    end

    local cameraPosition = camera.transform.position
    local maxWallIndex = 1
    local maxWallDistance = 0

    for k, wallPos in pairs(wallPositions) do
        local distance = CS.UnityEngine.Vector3.Distance(cameraPosition, wallPos)
        if distance > maxWallDistance then
            maxWallIndex = k
            maxWallDistance = distance
        end
    end

    return maxWallIndex
end

-- 是否在宿舍场景里
function XHomeDormManager.InDormScene()
    return InDormitoryScene
end

-- 是否在宿舍某个房间里
function XHomeDormManager.InAnyRoom()
    return CurSelectedRoom ~= nil and CurSelectedRoom.IsSelected
end

-- 获取当前在宿舍某个房间的id
function XHomeDormManager.GetCurrentRoomId()
    if CurSelectedRoom and CurSelectedRoom.IsSelected then
        return CurSelectedRoom.Data.Id
    end
    return nil
end

-- 获取当前在宿舍某个房间家具数据
function XHomeDormManager.GetCurrentRoomFurnitures()
    if CurSelectedRoom and CurSelectedRoom.IsSelected then
        return CurSelectedRoom.Data:GetFurnitureDic()
    end
    return nil
end

-- 是否在宿舍某个房间里(房间id为roomId)
function XHomeDormManager.IsInRoom(roomId)
    if CurSelectedRoom == nil then return false end
    if roomId and CurSelectedRoom.Data and CurSelectedRoom.Data.Id == roomId then
        return CurSelectedRoom.IsSelected
    end
    return false
end

--是否在进入宿舍时加载家具
function XHomeDormManager.CheckLoadFurnitureOnEnter()
    return NeedLoadFurnitureOnLoad
end

--将网格的坐标显示到UI上 仅用于编辑器模式
function XHomeDormManager.ShowGridPosInUi(type)
    if not XTool.UObjIsNil(HomeMapManager) then
        return HomeMapManager:ShowGridPosInUi(type)
    end
end

function XHomeDormManager.Test()
    local root = CS.UnityEngine.GameObject.Find("sushe003(Clone)").transform
    local base = root:Find("@Room/@Room_21001")
    local extra = {"@Room/@Room_21001","@Room/@Room_21003", "@Room/@Room_21005"}
    local curPos = base.localPosition
    for i = 1, #extra do
        local room = root:Find(extra[i])
        room.gameObject:SetActiveEx(true)
        curPos.z = curPos.z + 12
        room.localPosition = curPos
        local facade = room:Find("@RoomFacade(Clone)")
        facade.gameObject:SetActiveEx(false)
        local furniture = room:Find("@Furniture")
        furniture.gameObject:SetActiveEx(true)
        local surface = room:Find("@Surface")
        surface.gameObject:SetActiveEx(true)
        local chars = room:Find("@Character")
        chars.gameObject:SetActiveEx(true)
    end
    root:Find("@Room/@Room_21001/@Surface/Teahousewall001(Clone)/0").gameObject:SetActiveEx(false)
    root:Find("@Room/@Room_21003/@Surface/Teahousewall001(Clone)/0").gameObject:SetActiveEx(false)
    root:Find("@Room/@Room_21003/@Surface/Teahousewall001(Clone)/2").gameObject:SetActiveEx(false)
    root:Find("@Room/@Room_21005/@Surface/Teahousewall001(Clone)/2").gameObject:SetActiveEx(false)
    root:Find("Camera"):GetComponent("Camera").farClipPlane = 50
    for _, room in pairs(RoomDic) do
        room:ResetCharacterList()
    end
end

--- 更新缓存
---@param roomObj XHomeRoomObj
--------------------------
function XHomeDormManager.UpdateRoomCache(roomObj)
    -- 未达到阈值，不采用缓存机制
    if XHomeDormManager.CheckLoadFurnitureOnEnter() then
        return
    end
    HomeFurnitureCache:Enqueue(roomObj)
end

function XHomeDormManager.GetFurnitureRedRimMat()
    if not FurnitureRedRimMatKey then
        FurnitureRedRimMatKey = "UnOwnRed"
    end
    return FurnitureRimMat[FurnitureRedRimMatKey]
end