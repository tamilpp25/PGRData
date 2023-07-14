local XRobot = require("XEntity/XRobot/XRobot")
local XReformMemberTarget = XClass(nil, "XReformMemberTarget")

-- config : XReformConfigs.MemberTargetConfig
function XReformMemberTarget:Ctor(config)
    self.Config = config
    self.SourceId = nil
    -- XRobot
    self.Robot = nil
    -- XCharacterViewModel
    self.CharacterViewModel = nil
    self.Id = self.Config.Id
end

function XReformMemberTarget:GetId()
    return self.Config.Id
end

function XReformMemberTarget:GetSourceId()
    return self.SourceId
end

function XReformMemberTarget:GetIsActive()
    return self.SourceId ~= nil and self.SourceId ~= 0
end

function XReformMemberTarget:GetName()
    return self:GetCharacterViewModel():GetName()
end

function XReformMemberTarget:GetLogName()
    return self:GetCharacterViewModel():GetLogName()
end

function XReformMemberTarget:GetStarLevel()
    return self.Config.StarLevel
end

function XReformMemberTarget:GetScore()
    return self.Config.SubScore
end

function XReformMemberTarget:GetSmallHeadIcon()
    return self:GetCharacterViewModel():GetSmallHeadIcon()
end

function XReformMemberTarget:GetLevel()
    return self:GetCharacterViewModel():GetLevel()
end

function XReformMemberTarget:GetBigHeadIcon()
    return self:GetCharacterViewModel():GetBigHeadIcon()
end

function XReformMemberTarget:UpdateSourceId(id)
    self.SourceId = id
end

function XReformMemberTarget:GetRobotId()
    return self.Config.RobotId
end

function XReformMemberTarget:GetRobot()
    if self.Robot == nil then
        self.Robot = XRobot.New(self.Config.RobotId)
    end
    return self.Robot
end

function XReformMemberTarget:GetCharacterViewModel()
    if self.CharacterViewModel == nil then
        self.CharacterViewModel = self:GetRobot():GetCharacterViewModel()
    end
    return self.CharacterViewModel
end

return XReformMemberTarget