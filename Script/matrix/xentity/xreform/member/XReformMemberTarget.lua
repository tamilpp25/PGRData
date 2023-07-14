local XRobot = require("XEntity/XRobot/XRobot")
local XReformMemberTarget = XClass(nil, "XReformMemberTarget")

-- config : XReformConfigs.MemberTargetConfig
function XReformMemberTarget:Ctor(config)
    self.Config = config
    self.SourceId = nil
    -- XRobot
    self.Robot = nil
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

function XReformMemberTarget:GetShowAwarenessViewModelInfos()
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


function XReformMemberTarget:GetCharacterViewModel()
    return self:GetRobot():GetCharacterViewModel()
end

return XReformMemberTarget