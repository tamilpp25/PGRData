local MapGridType = enum(
    {
        None = 0, --空位置
        Interact = 1 << 0, --交互点位置
        Furniture = 1 << 1, --家具
        Blocked = 1 << 2, --障碍物
    }
)
--===============
--房间地图数据
--===============
local XGuildRoomMapData = XClass(nil, "XGuildRoomMapData")
--===============
--roomWidth : 房间宽
--roomLength : 房间长
--roomHeight : 房间高
--===============
function XGuildRoomMapData:Ctor(roomWidth, roomLength, roomHeight)
    self.Width = roomWidth
    self.Length = roomLength
    self.Height = roomHeight
    self.MapData = {} --(三维坐标系)MapData [坐标x(横)][坐标y(竖)][坐标z(高)] = gridData
end
--===================
--gridData : 格子信息
--checkTypes : MapGridType数组，检查是否格子跟检查的类型重合
--===================
function XGuildRoomMapData:GetMapGridMask(gridData, maskTypes)
    local gridType = 0
    for _, maskType in pairs(maskTypes or {}) do
        gridType = gridType | maskType
    end
    return gridData.GridTType & gridType
end
--===================
--gridData : 格子信息
--checkTypes : MapGridType数组，检查是否格子跟检查的类型重合
--===================
function XGuildRoomMapData:SetFurnitureInfo(x, y, furnitureWidth, furnitureHeight, rotate)
    local rotateState = rotate % 2
    local w, h
    if rotateState == XGuildDormConfig.FurnitureRotateState.Horizontal then
        w = furnitureWidth - 1
        h = furnitureHeight - 1
    elseif rotateState == XGuildDormConfig.FurnitureRotateState.Vertical then
        w = furnitureHeight - 1
        h = furnitureWidth - 1
        local MapGridManager = XDataCenter.GuildDormManager.MapGridManager.GetMapGridManager()
        for i = 0, i <= w do
            for j = 0, j <= h do
                local m = x + i
                local n = y + j
                if ((m > MapGridManager.MapSize.x or n > MapGridManager.MapSize.y or m < 0 or n < 0)) then
                    goto continue
                end
                local mapGrid = self.Map[x][y][0]
                if not mapGrid then
                    goto continue
                end
                mapGrid.GridType = mapGrid.GridType | MapGridType.Furniture
            end
            :: continue ::
        end
    end
end

return XGuildRoomMapData