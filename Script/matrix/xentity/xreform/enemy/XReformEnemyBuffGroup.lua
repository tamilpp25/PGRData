local XReformEnemyBuff = require("XEntity/XReform/Enemy/XReformEnemyBuff")
local XReformEnemyBuffGroup = XClass(nil, "XReformEnemyBuffGroup")

function XReformEnemyBuffGroup:Ctor(id)
    self.Config = XReformConfigs.GetCfgByIdKey(XReformConfigs.TableKey.ReformAffixGroup, id)
    self.BuffDic = {}
    self.ActiveBuffIds = {}
end

function XReformEnemyBuffGroup:UpdateActiveBuffIds(value)
    self.ActiveBuffIds = value
end

function XReformEnemyBuffGroup:GetActiveBuffIds()
    return self.ActiveBuffIds
end

function XReformEnemyBuffGroup:CheckBuffIsActive(id)
    for _, buffId in ipairs(self.ActiveBuffIds) do
        if buffId == id then
            return true
        end
    end
    return false
end

function XReformEnemyBuffGroup:GetActiveBuffs()
    local result = {}
    for _, id in ipairs(self:GetActiveBuffIds() or {}) do
        table.insert(result, self:GetBuffById(id))
    end
    return result
end

function XReformEnemyBuffGroup:GetAllBuffs()
    local result = {}
    for _, id in ipairs(self.Config.SubId) do
        table.insert(result, self:GetBuffById(id))
    end
    return result
end

function XReformEnemyBuffGroup:GetBuffById(id)
    local result = self.BuffDic[id]
    if result == nil then
        result = XReformEnemyBuff.New(id)
        self.BuffDic[id] = result
    end
    return result
end

return XReformEnemyBuffGroup