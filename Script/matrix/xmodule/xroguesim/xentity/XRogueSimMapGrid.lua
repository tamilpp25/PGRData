---@class XRogueSimMapGrid
local XRogueSimMapGrid = XClass(nil, "XRogueSimMapGrid")

function XRogueSimMapGrid:Ctor(data)
    self.Id = data.Id
    self.TerrainId = data.TerrainId or -1
    self.LandformId = data.LandformId
    self.ParentId = data.ParentId
    -- 地形id, 客户端用
    self.TerrainId = data.TerrainId
end

function XRogueSimMapGrid:UpdateMapGridData(data)
    self.TerrainId = data.TerrainId or -1
    self.LandformId = data.LandformId or 0
    self.ParentId = data.ParentId or 0
    self.TerrainId = data.TerrainId or 0
end

return XRogueSimMapGrid
