---@class XRogueSimMapGrid
local XRogueSimMapGrid = XClass(nil, "XRogueSimMapGrid")

function XRogueSimMapGrid:Ctor()
    self.Id = 0
    self.LandformId = 0
    self.ParentId = 0
end

function XRogueSimMapGrid:UpdateMapGridData(data)
    self.Id = data.Id or 0
    self.LandformId = data.LandformId or 0
    self.ParentId = data.ParentId or 0
end

return XRogueSimMapGrid
