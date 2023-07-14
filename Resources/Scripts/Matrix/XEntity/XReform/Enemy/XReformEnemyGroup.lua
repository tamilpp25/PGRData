local XReformEnemySource = require("XEntity/XReform/Enemy/XReformEnemySource")
local XReformBaseSourceGroup = require("XEntity/XReform/XReformBaseSourceGroup")
local XReformEnemyGroup = XClass(XReformBaseSourceGroup, "XReformEnemyGroup")

-- config : XReformConfigs.EnemyGroupConfig
function XReformEnemyGroup:Ctor(config)
    self:InitSources()
end

function XReformEnemyGroup:UpdateReplaceIdDic(replaceIdDic)
    for _, source in ipairs(self.Sources) do
        source:UpdateTargetId(replaceIdDic[source:GetId()])
    end
end

function XReformEnemyGroup:GetName()
    return CS.XTextManager.GetText("ReformEvolvableEnemyNameText")
end

--######################## 私有方法 ########################

function XReformEnemyGroup:InitSources()
    local config = nil
    local data = nil
    for _, sourceId in ipairs(self.Config.SubId) do
        config = XReformConfigs.GetEnemySourceConfig(sourceId)
        data = XReformEnemySource.New(config)
        table.insert(self.Sources, data)
        self.SourceDic[data:GetId()] = data
    end
end

return XReformEnemyGroup