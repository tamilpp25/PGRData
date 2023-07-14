local XRobot = require("XEntity/XRobot/XRobot")
local XReformMemberTarget = require("XEntity/XReform/Member/XReformMemberTarget")
local XReformMemberSource = XClass(nil, "XReformMemberSource")

-- config : XReformConfigs.MemberSourceConfig
function XReformMemberSource:Ctor(config)
    self.Config = config
    -- XReformMemberTarget
    self.Targets = {}
    -- key : id value : XReformMemberTarget
    self.TargetDic = {}
    self:InitTargets()
    self.TargetId = nil
    -- XRobot
    self.Robot = nil
    -- XCharacterViewModel
    self.CharacterViewModel = nil
    self.Id = self.Config.Id
end

function XReformMemberSource:GetReformType()
    return XReformConfigs.EvolvableGroupType.Member
end

function XReformMemberSource:GetId()
    return self.Config.Id
end

function XReformMemberSource:GetScore()
    return self.Config.SubScore
end

function XReformMemberSource:GetStarLevel()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetStarLevel()
    end
    return self.Config.StarLevel
end

function XReformMemberSource:GetRobotId()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetRobotId()
    end
    return self.Config.RobotId
end

function XReformMemberSource:GetRobot()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetRobot()
    end
    if self.Robot == nil then
        self.Robot = XRobot.New(self.Config.RobotId)
    end
    return self.Robot
end

function XReformMemberSource:GetCharacterViewModel()
    if self.CharacterViewModel == nil then
        self.CharacterViewModel = self:GetRobot():GetCharacterViewModel()
    end
    return self.CharacterViewModel
end

function XReformMemberSource:GetName()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetName()
    end
    return self:GetCharacterViewModel():GetName()
end

function XReformMemberSource:GetLogName()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetLogName()
    end
    return self:GetCharacterViewModel():GetLogName()
end

function XReformMemberSource:GetLevel()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetLevel()
    end
    return self:GetCharacterViewModel():GetLevel()
end

function XReformMemberSource:GetIsActive()
    return self.TargetId ~= nil
end

function XReformMemberSource:GetIcon()
    return self:GetSmallHeadIcon()
end

function XReformMemberSource:GetBigHeadIcon()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetBigHeadIcon()
    end
    return self:GetCharacterViewModel():GetBigHeadIcon()
end

function XReformMemberSource:GetSmallHeadIcon()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetSmallHeadIcon()
    end
    return self:GetCharacterViewModel():GetSmallHeadIcon()
end


function XReformMemberSource:GetTargets()
    return self.Targets
end

function XReformMemberSource:GetEntityType()
    if self.Config.RobotId == 0 then
        return XReformConfigs.EntityType.Add
    end
    return XReformConfigs.EntityType.Entity
end

function XReformMemberSource:GetTargetId()
    return self.TargetId
end

function XReformMemberSource:UpdateTargetId(targetId)
    if targetId == 0 then targetId = nil end
    local memberTarget = self:GetTargetById(self.TargetId) 
    if memberTarget then
        memberTarget:UpdateSourceId(nil)
    end
    self.TargetId = targetId
    if self.TargetId ~= nil then
        memberTarget = self:GetTargetById(self.TargetId)
        memberTarget:UpdateSourceId(self:GetId())
    end
end

function XReformMemberSource:GetTargetById(id)
    if id == nil then return nil end
    return self.TargetDic[id]
end

function XReformMemberSource:GetTargetById(id)
    if id == nil then return nil end
    return self.TargetDic[id]
end

function XReformMemberSource:GetCurrentTarget()
    return self:GetTargetById(self.TargetId)
end

function XReformMemberSource:GetTargetScore()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetScore()
    end
    return 0
end

--######################## 私有方法 ########################

function XReformMemberSource:InitTargets()
    local config = nil
    local data = nil
    for _, targetId in ipairs(self.Config.TargetId) do
        config = XReformConfigs.GetMemberTargetConfig(targetId)
        if config then
            data = XReformMemberTarget.New(config)
            table.insert(self.Targets, data)
            self.TargetDic[data:GetId()] = data
        end
    end
end

return XReformMemberSource