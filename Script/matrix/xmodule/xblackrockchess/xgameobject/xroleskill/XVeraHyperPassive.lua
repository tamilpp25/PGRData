local XRoleSkill = require("XModule/XBlackRockChess/XGameObject/XRoleSkill/XRoleSkill")

local RoleSkillType = XMVCA.XBlackRockChess.RoleSkillType

---@class XVeraHyperPassive : XRoleSkill 薇拉大招被动
local XVeraHyperPassive = XClass(XRoleSkill, "XVeraHyperPassive")

function XVeraHyperPassive:OnInit()
    self._Params = self._Control:GetRoleSkillParam(self._Id)
    self._Type = self._Control:GetRoleSkillType(self._Id)
end

--- 触发大招被动
---@return boolean 是否触发成功
function XVeraHyperPassive:Trigger(isAuto)
    local actor = self._Control:GetChessGamer():GetRole(self._RoleId)
    if self._Type == RoleSkillType.VeraHyperAddDps then
        -- 增伤
        actor:AddRoundDamage(self:GetTriggerTimes() * self._Params[1])
    elseif self._Type == RoleSkillType.VeraHyperAddCost then
        -- 增加能量消耗
        actor:AddRoundCost(self:GetTriggerTimes() * self._Params[1])
    --[[elseif self._Type == RoleSkillType.VeraHyperSummon then
        -- 秽土转生
        -- 敌方     最大血量：50  额外血量：20
        -- 我方临时 最大血量=我方配置表血量上限（0）+70*50%
        -- 我方临时 当前血量=70*50%
        -- 我方临时 额外血量=70*50%
        if self._Control:IsFightingStageEnd() then
            return
        end
        ---@type XBlackRockChessPiece[]
        local killPieces = self._Param
        if XTool.IsTableEmpty(killPieces) then
            return
        end
        local liveCd = self._Params[2]
        local ignorePieceType = self._Params[3]
        for _, piece in pairs(killPieces) do
            local configId = piece:GetConfigId()
            local pieceType = self._Control:GetPieceType(configId)
            if ignorePieceType ~= pieceType then
                local hp = math.ceil(self._Params[1] / 100 * piece:GetMaxHp())
                local guid = piece:GetId()
                local point = piece:GetMovedPoint()
                self._Control:GetChessEnemy():RemovePieceInfo(guid)
                self._Control:GetChessPartner():Transmigration(configId, guid, point, liveCd, hp)
            end
        end]]
    end
end

function XVeraHyperPassive:UpdateData(triggerTimes)

end

function XVeraHyperPassive:GetTriggerTimes()
    return self._Skill:GetSkillUsedTimes()
end

function XVeraHyperPassive:OnRelease()
    self._Params = nil
end

return XVeraHyperPassive