
---@class XRoleSkill 角色被动技能，被动触发的技能
---@field _Control XBlackRockChessControl
local XRoleSkill = XClass(nil, "XRoleSkill")

function XRoleSkill:Ctor(control, skillId, roleId)
    self._Control = control
    self._Id = skillId
    self._RoleId = roleId
    
    self:OnInit()
end

function XRoleSkill:OnInit()

end

function XRoleSkill:Trigger(...)
    return false
end

function XRoleSkill:SetImp(imp)
end

function XRoleSkill:GetSkillType()
    return self._Control:GetRoleSkillType(self._Id)
end

--在被攻击时触发
function XRoleSkill:IsTriggerOnAttacked()
    return false
end

--在刚进入战斗时触发
function XRoleSkill:IsTriggerOnEnterFight()
    return false
end

function XRoleSkill:UpdateData(...)

end

function XRoleSkill:Release()
    self._Control = nil
    
    self:OnRelease()
end

function XRoleSkill:OnRelease()
end

function XRoleSkill:DispatchBuff()
end

function XRoleSkill:GetTriggerTimes()
    return 0
end

return XRoleSkill