local XReformMemberSource = require("XEntity/XReform/Member/XReformMemberSource")
local XReformBaseSourceGroup = require("XEntity/XReform/XReformBaseSourceGroup")
local XReformMemberGroup = XClass(XReformBaseSourceGroup, "XReformMemberGroup")

-- config : XReformConfigs.MemberGroupConfig
function XReformMemberGroup:Ctor(config)
    self:InitSources()
end

function XReformMemberGroup:UpdateReplaceIdDic(replaceIdDic, isUpdateChallengeScore)
    for _, source in ipairs(self.Sources) do
        source:UpdateTargetId(replaceIdDic[source:GetId()])
    end
    -- 更新挑战分数
    if isUpdateChallengeScore then
        local result = 0
        local memberTargetConfig = nil
        local memberSourceConfig = nil
        for sourceId, targetId in pairs(replaceIdDic) do        
            memberTargetConfig = XReformConfigs.GetMemberTargetConfig(targetId)
            if memberTargetConfig then
                memberSourceConfig = XReformConfigs.GetMemberSourceConfig(sourceId)
                if memberSourceConfig.RobotId == 0 then
                    result = result + memberSourceConfig.AddScore
                end
                result = result + memberTargetConfig.AddScore
            end
        end
        self.CurrentChallengeScore = result
    end
end

function XReformMemberGroup:GetMaxChallengeScore()
    if self.__MaxChallengeScore == nil then
        local result = 0
        for _, source in ipairs(self.Sources) do
            result = result + source:GetMaxTargetScore()
        end
        self.__MaxChallengeScore = result
    end
    return self.__MaxChallengeScore
end

function XReformMemberGroup:GetTeamMaxChallengeScore()
    if self.__TeamMaxChallengeScore == nil then
        self.__TeamMaxChallengeScore = 0
        table.sort(self.Sources, function(sourceA, sourceB)
            return sourceA:GetScore() > sourceB:GetScore()
        end)
        for i = 1, 3 do
            if self.Sources[i] then
                self.__TeamMaxChallengeScore = self.__TeamMaxChallengeScore + self.Sources[i]:GetScore()
            end
        end
    end
    return self.__TeamMaxChallengeScore
end

function XReformMemberGroup:GetName()
    return CS.XTextManager.GetText("ReformEvolvableMemberNameText")
end

function XReformMemberGroup:GetAllCanJoinTeamSources()
    local result = {}
    local robotId = nil
    for _, source in ipairs(self.Sources) do
        robotId = source:GetRobotId()
        if robotId ~= 0 and robotId ~= nil then
            table.insert(result, source)
        end
    end
    return result
end

-- 检查所有源是否带有相同角色
function XReformMemberGroup:CheckSourcesWithSameCharacterId(id)
    if id == nil or id <= 0 then
        return false, nil
    end
    local robotId = nil
    local result = false
    local sourceId = nil
    for _, source in ipairs(self.Sources) do
        robotId = source:GetRobotId()
        if robotId ~= 0 and robotId ~= nil then
            result = source:GetCharacterId() == id
            sourceId = source:GetId()
            if result then break end
        end
    end
    return result, sourceId
end

function XReformMemberGroup:GetRoleScoreByCharacterId(value)
    for _, source in ipairs(self.Sources) do
        if source:GetCharacterId() == value then
            return source:GetScore()
        end
    end
    return 0
end

--######################## 私有方法 ########################

function XReformMemberGroup:InitSources()
    local config = nil
    local data = nil
    for _, sourceId in ipairs(self.Config.SubId) do
        config = XReformConfigs.GetMemberSourceConfig(sourceId)
        if config then
            data = XReformMemberSource.New(config)
            table.insert(self.Sources, data)
            self.SourceDic[data:GetId()] = data
        end 
    end
end

return XReformMemberGroup