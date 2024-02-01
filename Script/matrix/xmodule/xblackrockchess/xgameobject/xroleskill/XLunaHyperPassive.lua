
local XRoleSkill = require("XModule/XBlackRockChess/XGameObject/XRoleSkill/XRoleSkill")

---@class XLunaHyperPassive : XRoleSkill 露娜大招被动
---@field _MaxTimes number 最大层数
local XLunaHyperPassive = XClass(XRoleSkill, "XLunaHyperPassive")

function XLunaHyperPassive:OnInit()
    local params = self._Control:GetRoleSkillParam(self._Id)
    self._Type = self._Control:GetRoleSkillType(self._Id)
    self._MaxTimes = params[1]
    self._Params = params
    self._TriggerTimes = 0 --触发次数
end

--- 触发大招被动
---@return boolean 是否触发成功
--------------------------
function XLunaHyperPassive:Trigger(isAuto)
    --触发次数
    local triggerTimes = isAuto and self._TriggerTimes or math.min(self._TriggerTimes + 1, self._MaxTimes)
    local value = self:GetValue(triggerTimes)
    local actor = self._Control:GetChessGamer():GetRole(self._RoleId)
    if self._Type == XMVCA.XBlackRockChess.RoleSkillType.LunaHyperAddDps then
        actor:AddDamage(value)
    elseif self._Type == XMVCA.XBlackRockChess.RoleSkillType.LunaHyperAddMove then
        actor:AddMoveRange(value)
    elseif self._Type == XMVCA.XBlackRockChess.RoleSkillType.LunaHyperAddRange then 
        actor:AddShotRange(value)
    end
    self._TriggerTimes = triggerTimes
    return true
end

--function XLunaHyperPassive:IsTriggerOnEnterFight()
--    return true
--end

function XLunaHyperPassive:UpdateData(triggerTimes)
    self._TriggerTimes = triggerTimes
end

function XLunaHyperPassive:GetValue(triggerTimes)
    if triggerTimes <= 0 then
        return 0
    end
    return self._Params[triggerTimes + 1] or 0
end

function XLunaHyperPassive:GetTriggerTimes()
    return self._TriggerTimes
end

function XLunaHyperPassive:OnRelease()
    self._TriggerTimes = 0
    self._Params = nil
end

return XLunaHyperPassive