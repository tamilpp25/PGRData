---@class XRogueSimTechLevel
local XRogueSimTechLevel = XClass(nil, "XRogueSimTechLevel")

function XRogueSimTechLevel:Ctor()
    -- 层级
    self.Level = 0
    -- 已解锁关键科技
    ---@type number[]
    self.KeyTechs = {}
end

function XRogueSimTechLevel:UpdateTechLevelData(data)
    self.Level = data.Level or 0
    self.KeyTechs = data.KeyTechs or {}
end

return XRogueSimTechLevel
