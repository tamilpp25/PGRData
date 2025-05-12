---@class XTheatre4CharacterData
local XTheatre4CharacterData = XClass(nil, "XTheatre4CharacterData")

function XTheatre4CharacterData:Ctor()
    -- 招募到的玩法角色配置id
    self.CharacterId = 0
    -- 星级
    self.Star = 0
    -- 颜色等级
    self.ColorLevelAdds = {}
end

-- 服务端通知
function XTheatre4CharacterData:NotifyCharacterData(data)
    self.CharacterId = data.CharacterId or 0
    self.Star = data.Star or 0
    self.ColorLevelAdds = data.ColorLevelAdds or {}
end

-- 获取角色配置id
function XTheatre4CharacterData:GetCharacterId()
    return self.CharacterId
end

-- 获取星级
function XTheatre4CharacterData:GetStar()
    return self.Star
end

-- 获取颜色等级
function XTheatre4CharacterData:GetColorLevelAdds()
    return self.ColorLevelAdds
end

return XTheatre4CharacterData
