--=================
--公会宿舍资源管理
--负责人：吕天元
--=================
local XGuildDormResourceManager = {}

local MAIN_MAP_GRID_PATH = CS.XGame.ClientConfig:GetString("GuildDormMapGridAssetUrl")
--=============
--初始化
--=============
local function Init()
    XLog.Debug("GuildDormResourceManager Initial Completed. 公会宿舍资源管理器初始化完成。")
end
--==============
--生成资源
--==============
local function Instantiate(path)
    local prefab = CS.XResourceManager.Load(path)
    local go = CS.UnityEngine.Object.Instantiate(prefab.Asset)
    return go
end
--==============
--生成地图网格
--==============
function XGuildDormResourceManager.InstantiateMapGrid()
    return Instantiate(MAIN_MAP_GRID_PATH)
end
--==============
--生成资源
--@params path: 资源路径
--==============
function XGuildDormResourceManager.InstantiateObj(path)
    return Instantiate(path)
end
--================TEST=================
function XGuildDormResourceManager.TestResourceManagerFunc()
    XLog.Debug("TestResourceManagerFunc Success.")
end
--require时运行初始化
Init()

return XGuildDormResourceManager