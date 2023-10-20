---@class XRogueSimTech
local XRogueSimTech = XClass(nil, "XRogueSimTech")

function XRogueSimTech:Ctor()
    -- 层级数据（按等级连续）
    ---@type XRogueSimTechLevel[]
    self.LevelData = {}
    -- 已解锁普通科技
    ---@type number[]
    self.NormalTechs = {}
end

function XRogueSimTech:UpdateTechData(data)
    self.LevelData = {}
    self:UpdateLevelData(data.LevelDatas)
    self.NormalTechs = data.NormalTechs or {}
end

function XRogueSimTech:UpdateLevelData(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddLevelData(v)
    end
end

function XRogueSimTech:AddLevelData(data)
    if not data then
        return
    end
    local level = self.LevelData[data.Level]
    if not level then
        level = require("XModule/XRogueSim/XEntity/XRogueSimTechLevel").New()
        self.LevelData[data.Level] = level
    end
    level:UpdateTechLevelData(data)
end

return XRogueSimTech
