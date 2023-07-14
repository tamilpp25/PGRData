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
    self.Id = self.Config.Id
end

function XReformMemberSource:GetReformType()
    return XReformConfigs.EvolvableGroupType.Member
end

function XReformMemberSource:GetId()
    return self.Config.Id
end

function XReformMemberSource:GetScore()
    return self.Config.AddScore
end

function XReformMemberSource:GetMaxTargetScore()
    if self.__MaxTagerScore == nil then
        self.__MaxTagerScore = 0
        for _, target in ipairs(self.Targets) do
            self.__MaxTagerScore = math.max( self.__MaxTagerScore, target:GetScore() )
        end
        self.__MaxTagerScore = self.__MaxTagerScore + self:GetScore()
    end
    return self.__MaxTagerScore
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

--[[
    return : [{
        value : {
            count : 这个套装里有多少件意识
            showViewModel : 这个套装向外部显示的数据
        }
        key : 套装id
    }, ...]
]]
function XReformMemberSource:GetShowAwarenessViewModelInfos()
    local robot = self:GetRobot()
    local viewModelDic = robot:GetAwarenessViewModelDic()
    -- 拿到所有套装ids
    local suitIdDic = {}
    local suitId, viewModel
    -- 找到所有套装数据
    for pos = 1, XEquipConfig.MAX_SUIT_COUNT do
        viewModel = viewModelDic[pos]
        if viewModel then
            suitId = viewModel:GetSuitId()
            suitIdDic[suitId] = suitIdDic[suitId] or { count = 0, showViewModel = viewModel }
            suitIdDic[suitId].count = suitIdDic[suitId].count + 1
        end
    end
    -- 排序
    local result = table.dicToArray(suitIdDic)
    table.sort(result, function(dataA, dataB)
        return dataA.value.count > dataB.value.count
    end)
    return result
end

function XReformMemberSource:GetCharacterId()
    return self:GetCharacterViewModel():GetId()
end

function XReformMemberSource:GetCharacterViewModel()
    return self:GetRobot():GetCharacterViewModel()
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