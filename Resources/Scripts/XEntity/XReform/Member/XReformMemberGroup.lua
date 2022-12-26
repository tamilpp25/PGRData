local XReformMemberSource = require("XEntity/XReform/Member/XReformMemberSource")
local XReformBaseSourceGroup = require("XEntity/XReform/XReformBaseSourceGroup")
local XReformMemberGroup = XClass(XReformBaseSourceGroup, "XReformMemberGroup")

-- config : XReformConfigs.MemberGroupConfig
function XReformMemberGroup:Ctor(config)
    self:InitSources()
end

function XReformMemberGroup:UpdateReplaceIdDic(replaceIdDic)
    for _, source in ipairs(self.Sources) do
        source:UpdateTargetId(replaceIdDic[source:GetId()])
    end
end

function XReformMemberGroup:GetMemberSourcesWithRobot()
    local result = {}
    local starLevelResult = {}
    for _, source in ipairs(self.Sources) do
        -- 查找实体
        if source:GetEntityType() == XReformConfigs.EntityType.Entity 
            or source:GetTargetId() ~= nil then
            table.insert(result, source:GetRobot())
            table.insert(starLevelResult, source:GetStarLevel())
        end
    end
    return result, starLevelResult
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