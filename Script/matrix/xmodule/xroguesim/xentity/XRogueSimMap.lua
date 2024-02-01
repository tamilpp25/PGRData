---@class XRogueSimMap
local XRogueSimMap = XClass(nil, "XRogueSimMap")

function XRogueSimMap:Ctor()
    ---@type number[]
    self.AreaIds = {}
    ---@type XRogueSimMapGrid[]
    self.GridDatas = {}
end

function XRogueSimMap:UpdateMapData(data)
    self.AreaIds = data.AreaIds or {}
    self.GridDatas = {}
    self:UpdateMapGridDatas(data.GridDatas)
end

function XRogueSimMap:UpdateMapGridDatas(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddMapGridData(v)
    end
end

function XRogueSimMap:AddMapGridData(data)
    if not data then
        return
    end
    local grid = self.GridDatas[data.Id]
    if not grid then
        grid = require("XModule/XRogueSim/XEntity/XRogueSimMapGrid").New()
        self.GridDatas[data.Id] = grid
    end
    grid:UpdateMapGridData(data)
end

function XRogueSimMap:GetAreaIds()
    return self.AreaIds
end

function XRogueSimMap:GetGridDataById(Id)
    return self.GridDatas[Id] or nil
end

return XRogueSimMap
