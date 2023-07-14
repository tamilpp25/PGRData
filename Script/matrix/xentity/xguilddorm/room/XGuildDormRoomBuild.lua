local XGuildDormFuniture = require("XEntity/XGuildDorm/Furniture/XGuildDormFurniture")
local XRoomMap = require("XEntity/XGuildDorm/Room/XGuildRoomMapData")
--=============
--公会宿舍房间建筑，家具构成控件
--=============
local XGuildDormRoomBuild = XClass(nil, "XGuildDormRoomBuild")
local ROOM_DEFAULT_SO_PATH = CS.XGame.ClientConfig:GetString("RoomDefaultSoPath")
local WallNum = 4
local ROOM_FAR_CLIP_PLANE = 25
function XGuildDormRoomBuild:Ctor(roomData)
    self.Data = roomData
    self.SurfaceRoot = nil
    self.CharacterRoot = nil
    self.FurnitureRoot = nil
    self.Ground = nil
    self.Wall = nil
    self.Ceiling = nil
    self.WallFurnitureList = {}
    self.GroundFurnitureList = {}
end

function XGuildDormRoomBuild:OnLoadComplete(roomTransform)
    self.GameObject = roomTransform.gameObject
    self.Transform = roomTransform.transform
    self.SurfaceRoot = self.Transform:Find("@Surface")
    self.CharacterRoot = self.Transform:Find("@Character")
    self.FurnitureRoot = self.Transform:Find("@Furniture")
    self.SurfaceRoot.gameObject:SetActiveEx(false)
    self.FurnitureRoot.gameObject:SetActiveEx(false)
    self.CharacterRoot.gameObject:SetActiveEx(false)
    self.GoInputHandler = self.GameObject:GetComponent(typeof(CS.XGoInputHandler))
    if not self.GoInputHandler then
        self.GoInputHandler = self.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
end
-- 加载家具
function XGuildDormRoomBuild:InitFurnitures()
    local furnitureList = XGuildDormConfig.GetAllConfigs(XGuildDormConfig.TableKey.DefaultFurniture)
    for _, cfg in pairs(furnitureList) do
        if cfg.RoomId ~= self.Data.Id then goto nextCfg end
        local furnitureCfg = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.Furniture, cfg.FurnitureId)
        if not furnitureCfg then goto nextCfg end
        --若该家具不需要动态加载(直接做在场景中)
        if furnitureCfg.IsNeedLoad == 0 then
            local name = furnitureCfg.PrefabName
            local gameObject = self.FurnitureRoot.gameObject:FindTransform(name)
            if gameObject then
                local furniture = XGuildDormFuniture.New(cfg.Id)
                furniture:SetGameObject(gameObject)
                self.Data:AddFurniture(furniture)
            end
        else
            --[[ TODO 动态加载家具
            ]]
        end
        :: nextCfg ::
    end
    --XLog.Debug("房间信息列表: ", self.Data)
end
--====================
--生成地图信息(第一期暂时不需要网格)
--====================
function XGuildDormRoomBuild:GenerateRoomMap()
    if not self.Ground then
        return
    end
    --房间动态地图信息
    self.RoomMap = XRoomMap.New(self.Data)
    --第一期没有关于摆放方面的需求，地图网格
    --先将HomeDormManager节点转到对应房间里再计算网格点里的数据，不然会有误差
    XDataCenter.GuildDormManager.MapGridManager.AttachMapGridToRoom(self.Data.Id)
    --往房间地图信息设置家具信息
    if self.GroundFurnitureList then
        for _, furniture in pairs(self.GroundFurnitureList) do
            if furniture.Cfg then
                local x, y, rotate = furniture:GetData()
                -- 设置家具信息
                self.RoomMap:SetFurnitureInfo(x, y, furniture.Cfg.Width, furniture.Cfg.Height, rotate)
            end
        end
    end
    --等上面处理完后隐藏地图网格
    XDataCenter.GuildDormManager.MapGridManager.HideMapGrid()
end
--===========
-- 创建家具
--===========
function XGuildDormRoomBuild:CreateFurniture(roomId, furnitureData, gridPos, rotate)
    --[[TODO

    ]]
end

function XGuildDormRoomBuild:OnEnter()
    self:Show()
end

function XGuildDormRoomBuild:OnLeave()
    self:Hide()
end

function XGuildDormRoomBuild:Show()
    self.SurfaceRoot.gameObject:SetActiveEx(true)
    self.CharacterRoot.gameObject:SetActiveEx(true)
    self.FurnitureRoot.gameObject:SetActiveEx(true)
end

function XGuildDormRoomBuild:Hide()
    self.SurfaceRoot.gameObject:SetActiveEx(false)
    self.CharacterRoot.gameObject:SetActiveEx(false)
    self.FurnitureRoot.gameObject:SetActiveEx(false)
end
--============
--处置房间资源
--============
function XGuildDormRoomBuild:Dispose()
    if self.WallFurnitureList then
        for k, v in pairs(self.WallFurnitureList) do
            for _, furniture in pairs(v) do
                furniture:Dispose()
            end
        end
    end
    if self.GroundFurnitureList then
        for k, furniture in pairs(self.GroundFurnitureList) do
            furniture:Dispose()
        end
    end
    if self.Ceiling then
        self.Ceiling:Dispose()
    end
    if self.Wall then
        self.Wall:Dispose()
    end
    if self.Ground then
        self.Ground:Dispose()
    end
    if self.Data then
        self.Data:Dispose()
    end
end

function XGuildDormRoomBuild:ResetNavmeshObstacle()
    local allFurniture = self.Data:GetAllFurnitures()
    for _, furniture in pairs(allFurniture or {}) do
        furniture:ResetNavmeshObstacle()
    end
end

return XGuildDormRoomBuild