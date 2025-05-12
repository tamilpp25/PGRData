local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantOperation = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperation")

---@class XLuckyTenantOperationAddPassiveSkill:XLuckyTenantOperation
local XLuckyTenantOperationAddPassiveSkill = XClass(XLuckyTenantOperation, "XLuckyTenantOperationAddPassiveSkill")

function XLuckyTenantOperationAddPassiveSkill:Ctor()
    self._Type = XLuckyTenantEnum.Operation.AddPassiveSkill
    self._PassiveSkillId = 0
end

function XLuckyTenantOperationAddPassiveSkill:SetData(skillId)
    self._PassiveSkillId = skillId
end

function XLuckyTenantOperationAddPassiveSkill:Do(model, game)
    XMVCA.XLuckyTenant:Print("增加被动技能：" .. self._PassiveSkillId)
    local isSuccess = game:AddPassiveSkillById(model, self._PassiveSkillId)
    return isSuccess
end

return XLuckyTenantOperationAddPassiveSkill
