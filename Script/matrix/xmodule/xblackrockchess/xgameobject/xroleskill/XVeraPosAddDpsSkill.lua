
local XRoleSkill = require("XModule/XBlackRockChess/XGameObject/XRoleSkill/XRoleSkill")

---@class XVeraPosAddDpsSkill : XRoleSkill 露娜受攻击时触发保护
---@field _Imp XBlackRockChess.XBeheadedSkill
local XVeraPosAddDpsSkill = XClass(XRoleSkill, "XVeraPosAddDpsSkill")

function XVeraPosAddDpsSkill:OnInit()
    local params = self._Control:GetRoleSkillParam(self._Id)
    self._AddDps = params[1] or 0
end

function XVeraPosAddDpsSkill:SetImp(imp)
    
end

function XVeraPosAddDpsSkill:IsTriggerOnAttack()
    return true
end

--- 触发保护被动
---@param piece XBlackRockChessPiece
---@return boolean 是否触发成功
--------------------------
function XVeraPosAddDpsSkill:Trigger(piece)
    if not piece or not piece.IsBoss or not piece:IsBoss() then
        return 0
    end

    local weaponId = piece:GetWeaponId()
    local weaponType = self._Control:GetWeaponType(weaponId)
    local actor = self._Control:GetChessGamer():GetRole(self._RoleId)
    local rolePoint = actor:GetMovedPoint()
    local CSXBlackRockChessManager = CS.XBlackRockChess.XBlackRockChessManager.Instance
    if weaponType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_TYPE.ZHETIAN_WHITE and CSXBlackRockChessManager:IsBlackBlock(rolePoint.x, rolePoint.y) then
        return self._AddDps
    elseif weaponType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_TYPE.ZHETIAN_BLACK and CSXBlackRockChessManager:IsWhiteBlock(rolePoint.x, rolePoint.y) then
        return self._AddDps
    end
    return 0
end

function XVeraPosAddDpsSkill:GetDamage()
    return self._Damage
end

function XVeraPosAddDpsSkill:OnRelease()
    self._EffectiveTimes = 0
end

function XVeraPosAddDpsSkill:UpdateData(effectiveTimes)
    self._EffectiveTimes = effectiveTimes
end

return XVeraPosAddDpsSkill