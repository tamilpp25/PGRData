---@class XScoreTowerCharacterInfo
local XScoreTowerCharacterInfo = XClass(nil, "XScoreTowerCharacterInfo")

function XScoreTowerCharacterInfo:Ctor()
    self.CharacterId = 0
    self.RobotId = 0
    self.Pos = 0
end

function XScoreTowerCharacterInfo:NotifyScoreTowerCharacterInfo(data)
    self.CharacterId = data.ChatacterId or 0
    self.RobotId = data.RobotId or 0
    self.Pos = data.Pos or 0
end

--region 数据获取

function XScoreTowerCharacterInfo:GetEntityId()
    return self.CharacterId > 0 and self.CharacterId or (self.RobotId > 0 and self.RobotId or 0)
end

function XScoreTowerCharacterInfo:GetPos()
    return self.Pos
end

--endregion

return XScoreTowerCharacterInfo
