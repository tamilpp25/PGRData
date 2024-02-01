
local XRoleSkill = require("XModule/XBlackRockChess/XGameObject/XRoleSkill/XRoleSkill")

---@class XLunaProtectedSkill : XRoleSkill 露娜受攻击时触发保护
---@field _Imp XBlackRockChess.XBeheadedSkill
local XLunaProtectedSkill = XClass(XRoleSkill, "XLunaProtectedSkill")

function XLunaProtectedSkill:OnInit()
    local params = self._Control:GetRoleSkillParam(self._Id)
    self._MaxTimes = params[1]
    self._Damage = params[2]
    self._CharacterId = params[3]
    self._ExcludePieceType = params[4]
    self._EffectiveTimes = 0 --触发次数 
end

function XLunaProtectedSkill:SetImp(imp)
    self._Imp = imp
    self._Imp:InitParam(self._Id, 0, self._Control:GetRoleSkillType(self._Id), 
            self._Control:GetRoleSkillParam(self._Id))
end

function XLunaProtectedSkill:IsTriggerOnAttacked()
    return true
end

--- 触发保护被动
---@param piece XBlackRockChessPiece
---@return boolean 是否触发成功
--------------------------
function XLunaProtectedSkill:Trigger(piece)
    -- 触发次数小于0
    if self._EffectiveTimes >= self._MaxTimes then
        return false
    end

    --非棋子
    if not piece or not piece.IsPiece 
            or not piece:IsPiece() then
        return false
    end

    --排除对象
    if self._ExcludePieceType == piece:GetPieceType() then
        return false
    end

    --无敌不生效
    --if piece:IsInvincible() then
    --    return false
    --end
    
    local actor = self._Control:GetChessGamer():GetRole(self._RoleId)
    if not actor then
        return false
    end

    self._EffectiveTimes = self._EffectiveTimes + 1
    --触发保护
    actor:Protect(self._Id, self._CharacterId, piece)
    self._Control:PlayGrowls(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER,
            XMVCA.XBlackRockChess.GrowlsTriggerType.CharacterSkill, self._CharacterId, self._Id)
    return true
end

function XLunaProtectedSkill:GetDamage()
    return self._Damage
end

function XLunaProtectedSkill:OnRelease()
    self._EffectiveTimes = 0
end

function XLunaProtectedSkill:UpdateData(effectiveTimes)
    self._EffectiveTimes = effectiveTimes
end

return XLunaProtectedSkill