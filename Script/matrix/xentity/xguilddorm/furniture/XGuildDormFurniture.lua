local XRLGuildDormFurniture = require("XEntity/XGuildDorm/Furniture/XRLGuildDormFurniture")
local XBaseSceneObj = require("XEntity/XGuildDorm/Base/XGuildDormBaseSceneObj")
local XFurnitureModel = require("XEntity/XGuildDorm/Furniture/XGuildDormFurnitureModel")
local XGuildDormFurniture = XClass(XBaseSceneObj, "XGuildDormFurniture")

--================
--获取默认家具表的Id(GuildDormDefaultFurniture)
--================
function XGuildDormFurniture:GetId()
    return self.Id
end
--================
--获取家具对应的房间
--================
function XGuildDormFurniture:GetRoom()
    local roomId = self.FurnitureModel and self.FurnitureModel.RoomId
    if not roomId then return nil end
    local currentScene = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene()
    return currentScene and currentScene:GetRoomById(roomId)
end
--================
--获取家具表Id(GuildDormFurniture)
--================
function XGuildDormFurniture:GetFurnitureId()
    return self.FurnitureModel and self.FurnitureModel.FurnitureId
end
--================
--获取家具名称
--================
function XGuildDormFurniture:GetName()
    return self.FurnitureModel and self.FurnitureModel.Name
end
--================
--获取家具交互信息列表
--================
function XGuildDormFurniture:GetInteractInfoList()
    return self.FurnitureModel and self.FurnitureModel.InteractInfoList
end
--===================
-- 检测交互点是否能交互
--===================
function XGuildDormFurniture:CheckCanInteract()
    return self.FurnitureModel and self.FurnitureModel.InteractPos > 0
end
--===========
--构造函数
--@param id：默认家具表Id
--===========
function XGuildDormFurniture:Ctor(id)
    self.Id = id
    self.ServerData = nil
    -- 表现数据
    self.FurnitureModel = XFurnitureModel.New(self.Id)
end

function XGuildDormFurniture:SetGameObject(go)
    self.FurnitureModel:SetGameObject(go)
    XDataCenter.GuildDormManager.SceneManager.AddSceneObj(self.FurnitureModel.GameObject, self)
end

function XGuildDormFurniture:LoadAsset(modelPath, root)
    self.FurnitureModel:LoadAsset(modelPath, root)
end

function XGuildDormFurniture:UpdateWithServerData(data) 
    self.ServerData = data
end

function XGuildDormFurniture:ResetNavmeshObstacle()
    self.FurnitureModel:ResetNavmeshObstacle()
end

function XGuildDormFurniture:Dispose()
    self.FurnitureModel:Dispose()
end

return XGuildDormFurniture
