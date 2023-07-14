--==============
--公会宿舍网格管理
--==============
local XGuildDormMapGridManager = {}
--=============
--地图网格数据
--=============
local MapGridData
function XGuildDormMapGridManager.GetMapGridData()
    if not MapGridData then
        MapGridData = {}
    end
    return MapGridData
end
function XGuildDormMapGridManager.SetMapGridData(data)
    MapGridData = data
end
--=============
--获取地图网格管理器
--=============
function XGuildDormMapGridManager.GetMapGridManager()
    local data = XGuildDormMapGridManager.GetMapGridData()
    return data and data.MapGridManager
end
--=============
--获取地图网格TF
--=============
function XGuildDormMapGridManager.GetMapGridTransform()
    local data = XGuildDormMapGridManager.GetMapGridData()
    return data and data.Transform
end

local function GetGroundRoot()
    local data = XGuildDormMapGridManager.GetMapGridData()
    return data and data.GroundRoot
end

local function GetWallRoot()
    local data = XGuildDormMapGridManager.GetMapGridData()
    return data and data.WallRoot
end
local MapTransform = XGuildDormMapGridManager.GetMapGridTransform()
local GroundRoot = GetGroundRoot()
local WallRoot = GetWallRoot()
--=============
--初始化主场景
--=============
local function InitMapGrid(model)
    local data = XGuildDormMapGridManager.GetMapGridData()
    data.Transform = model.transform
    data.GroundRoot = data.Transform:Find("@GroundRoot")
    data.WallRoot = data.Transform:Find("@WallRoot")
    data.Transform:SetParent(nil)
    data.Transform.gameObject:SetActiveEx(false)
    --TODO 复用了宿舍的网格脚本，跑通后应逐步替换
    data.MapGridManager = model:GetComponent("XHomeMapManager")
    data.MapGridManager:Init()
end
--=============
--初始化地图网格
--=============
function XGuildDormMapGridManager.InitMapGrid()
    local mapGridPrefab = XDataCenter.GuildDormManager.ResourceManager.InstantiateMapGrid()
    if not mapGridPrefab then return end
    InitMapGrid(mapGridPrefab)
end

function XGuildDormMapGridManager.HideMapGrid()
    MapTransform.gameObject:SetActiveEx(false)
end

--=============
--将地图网格挂到指定房间根节点
--=============
function XGuildDormMapGridManager.AttachMapGridToRoom(roomId)
    if not roomId then
        XGuildDormMapGridManager.HideMapGrid()
        return
    end
    local currentScene = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene()

    local room = currentScene:GetRoomById(roomId)
    if room and not XTool.UObjIsNil(room.Transform) then
        local groundSurface = GroundRoot:GetComponentInChildren(typeof(CS.XHomeSurface))
        if not XTool.UObjIsNil(groundSurface) then
            groundSurface.ConfigId = room.Ground.Data.CfgId
        end

        -- 4个
        local wallSurface = WallRoot:GetComponentInChildren(typeof(CS.XHomeSurface))
        if not XTool.UObjIsNil(wallSurface) then
            if room.Wall == nil then
                XLog.Error("缺少墙的数据....(迷惑)")
            else
                wallSurface.ConfigId = room.Wall.Data.CfgId
            end
        end
        MapTransform:SetParent(room.Transform, false)
        MapTransform.localPosition = CS.UnityEngine.Vector3.zero;
        MapTransform.localRotation = CS.UnityEngine.Quaternion.identity
        MapTransform.localScale = CS.UnityEngine.Vector3.one
        MapTransform.gameObject:SetActiveEx(true)
    end
end

function XGuildDormMapGridManager.CollectMapGrid()
    local mapGrid = XGuildDormMapGridManager.GetMapGridManager()
    if mapGrid then
        CS.UnityEngine.GameObject.Destroy(mapGrid.gameObject)
    end
    XGuildDormMapGridManager.SetMapGridData(nil)
end

return XGuildDormMapGridManager