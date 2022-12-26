local XReformEnvironment = require("XEntity/XReform/Environment/XReformEnvironment")
local XReformEnvironmentGroup = XClass(nil, "XReformEnvironmentGroup")

-- config : XReformConfigs.EnvironmentGroupConfig
function XReformEnvironmentGroup:Ctor(config)
    -- XReformEnvironment
    self.Environments = {}
    -- key : id, value : XReformEnvironment
    self.EnvironmentDic = {}
    self.Config = config
    self:InitEnvironments()
end

-- 所有环境数据
function XReformEnvironmentGroup:GetEnvironments()
    return self.Environments
end

function XReformEnvironmentGroup:GetName()
    return CS.XTextManager.GetText("ReformEvolvableEnvNameText")
end

function XReformEnvironmentGroup:GetEnvironmentById(id)
    return self.EnvironmentDic[id]
end

--######################## 私有方法 ########################

function XReformEnvironmentGroup:InitEnvironments()
    local config = nil
    local data = nil
    for _, id in ipairs(self.Config.SubId) do
        config = XReformConfigs.GetEnvironmentConfig(id)
        if config then
            data = XReformEnvironment.New(config)
            table.insert(self.Environments, data)
            self.EnvironmentDic[data:GetId()] = data
        end
    end
end

return XReformEnvironmentGroup