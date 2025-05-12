
---@class XBlackRockChessPiece : XEntity 棋子
---@field _MoveCd number 移动冷却回合
---@field _Id number 流水号Id
---@field _ConfigId number 配置Id
---@field _Life number 生命值
---@field _ExtraMaxLife number 血量上限提升
---@field _Imp XBlackRockChess.XPiece 棋子CS引用
---@field _OwnControl XBlackRockChessControl 控制器
---@field _BuffDict table<number, XBlackRockChess.XBuff> buff字典， Key为BuffId
local XBlackRockChessPiece = XClass(XEntity, "XBlackRockChessPiece")

local BuffType = XMVCA.XBlackRockChess.BuffType

---无敌类Buff
local ImmuneInjuryBuffDict = {
    [BuffType.InvincibleCount] = true,
    [BuffType.InvincibleAlive] = true,
    [BuffType.InvincibleAround] = true,
}

function XBlackRockChessPiece:OnInit(pieceId, configId)
    self._Id = pieceId
    self._ConfigId = configId
    self._IsPrepareRemove = false
    self._IsDizzy = false
    self._IsPromotion = false
    self._AttackedTimes = 0
    self._BuffDict = {}
    self._X = 0
    self._Y = 0
    self._MemberType = XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.REINFORCE_PREVIEW
    self._MoveCd = 0
    self:SetHp(0)
    self._ExtraMaxLife = 0
    self._AttackedTimes = 0
    self._ReinforceId = 0
end

function XBlackRockChessPiece:SetImp(imp, isEnterFight)
    self._Imp = imp
    self._Imp.IsNoAttack = false
    
    self:ApplyBuff()
    self:InitImp()

    if not isEnterFight and not self._PlayBornGrowls then
        --受击喊话
        self._OwnControl:PlayGrowls(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PIECE,
                XMVCA.XBlackRockChess.GrowlsTriggerType.PieceGenerate, self:GetConfigId())
        self._PlayBornGrowls = true
    end
    
    self._OwnControl:GetChessEnemy():ProcessPieceEffect()
end

function XBlackRockChessPiece:GetImp()
    return  self._Imp
end

function XBlackRockChessPiece:SetHp(hp)
    self._Life = hp
    if self._Imp then
        self._Imp.Hp = hp
    end
end

function XBlackRockChessPiece:UpdateHeadHud()
    if self:IsPartner() then
        self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_PARTNER_HEAD_HUD, self._Id, self:GetIconFollow())
    else
        self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_ENEMY_HEAD_HUD, self._Id, self:GetIconFollow())
    end
end

function XBlackRockChessPiece:HideHeadHud()
    if self:IsPartner() then
        self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_PARTNER_HEAD_HUD, self._Id)
    else
        self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_ENEMY_HEAD_HUD, self._Id)
    end
end

function XBlackRockChessPiece:InitImp()
    self._Imp.Id = self._Id
    self._Imp:UpdateData(self._AttackedTimes, self:IsPreview())
    local isAttack = function()
        return self:IsAttackAble()
    end
    self._Imp:RegisterLuaCallBack(handler(self, self.OnClick), handler(self, self.PrepareAttack), 
            isAttack, handler(self, self.OnMoveEnd))
    
    self:UpdateHeadHud()
    if self:IsPreview() then
        self._OwnControl:LoadVirtualEffect(self._Imp, self._ConfigId)
    end
    self._Imp:InitAnimator(self._OwnControl:GetPieceController())
end

function XBlackRockChessPiece:IsPieceNoAttack()
    if XTool.UObjIsNil(self._Imp) then
        return false
    end
    return self._Imp.IsNoAttack
end

function XBlackRockChessPiece:ApplyBuff()
    local buffIds = self:IsPartner() and self._OwnControl:GetPartnerBuffIds(self._ConfigId) or self._OwnControl:GetPieceBuffIds(self._ConfigId)
    local map = {}
    self._BuffDict = {}
    for _, buffId in ipairs(buffIds) do
        local buffType = self._OwnControl:GetBuffType(buffId)
        map[buffType] = buffId
    end
    for buffType, buffId in pairs(map) do
        local buff = CS.XBlackRockChess.XBlackRockChessUtil.CreateBuff(buffType)
        if buff then
            local args = self._OwnControl:GetBuffParams(buffId)
            self._BuffDict[buffId] = buff
            buff:DoApply(buffId, self._Imp, table.unpack(args))
            buff:AddTakeEffectCb(handler(self, self.OnBuffTakeEffect))

            if buff:IsEffectiveByStageInit() then
                buff:DoTakeEffect()
            end
        end
    end
    --self:DoProcessBuffEffect()
    self:DoProcessBuffEffectOnLoad()
end

function XBlackRockChessPiece:IsExistBuff(buffId)
    return self._BuffDict and self._BuffDict[buffId] ~= nil
end

function XBlackRockChessPiece:GetLocalInfo()
    return {
        Imp = self._Imp,
        ConfigId = self._ConfigId,
        IsVirtual = self._OwnControl:GetChessGamer():IsExtraTurn()
    }
end

function XBlackRockChessPiece:OnRelease()
    self:HideHeadHud()
    if self._Imp then
        self._Imp:Destroy()
    end
    self._Imp = nil
    self._OwnControl = nil
    self._IsPrepareRemove = false
    self._IsDizzy = false
    self._IsPromotion = false
    self._BuffDict = {}
end

function XBlackRockChessPiece:UpdateData(data)
    self._X = data.X
    self._Y = data.Y
    self._MemberType = data.Type
    self._MoveCd = data.PieceInfo.MoveCd
    self._IsTemp = data.PieceInfo.IsTemp --是否临时棋子
    self._LiveCd = data.PieceInfo.RemainRound --剩余回合
    self:SetHp(data.Life)
    self._ExtraMaxLife = data.ExtraMaxLife
    self._AttackedTimes = data.AttackedTimes
    self._ReinforceId = data.PieceInfo.ReinforceId
    --触发了升变，当前回合改变了
    if self._ConfigId ~= data.PieceInfo.PieceId then
        self._OldConfigId = data.PieceInfo.PieceId
        self._IsPromotion = true
        self:RestorePromotion()
    end
    self._ConfigId = data.PieceInfo.PieceId
    if not XTool.IsTableEmpty(data.BuffList) then
        for _, buffData in ipairs(data.BuffList) do
            local buff = self._BuffDict[buffData.BuffId]
            if buff then
                buff.EffectCount = buffData.Count
            end
        end
    end
    if self._Imp then
        self._Imp:UpdateData(self._AttackedTimes)
        self:UpdateHeadHud()
    end
    self:UpdateReinforce()
    self:DoProcessEffectOnDataUpdate()
end

function XBlackRockChessPiece:GetIsTemp()
    return self._IsTemp
end

function XBlackRockChessPiece:GetLiveCd()
    return self._LiveCd
end

function XBlackRockChessPiece:IsAlive()
    return self._Life and self._Life > 0
end

function XBlackRockChessPiece:IsDizzy()
    return self._IsDizzy
end

function XBlackRockChessPiece:IsCanMove()
    return self._MoveCd == 0
end

function XBlackRockChessPiece:GetConfigId()
    return self._ConfigId
end

function XBlackRockChessPiece:GetSortConfigId()
    if self._IsPromotion then
        return self._OldConfigId
    end
    return self._ConfigId
end

function XBlackRockChessPiece:GetAttackTimes()
    return self._AttackedTimes
end

function XBlackRockChessPiece:GetPieceType()
    if not self._OwnControl then
        return
    end
    if self:IsPartner() then
        return self._OwnControl:GetPartnerPieceType(self._ConfigId)
    end
    return self._OwnControl:GetPieceType(self._ConfigId)
end

function XBlackRockChessPiece:GetBuffDesc(buffId)
    if not XTool.IsNumberValid(buffId) then
        return ""
    end
    local buffType = self._OwnControl:GetBuffType(buffId)
    --只针对免疫次数Buff的显示额外处理
    if buffType ~= 2 then
        return self._OwnControl:GetBuffDesc(buffId)
    end
    ---@type XBlackRockChess.XBuff
    local temp = self._BuffDict[buffId]
    local params = self._OwnControl:GetBuffParams(buffId)
    local desc = self._OwnControl:GetBuffDesc(buffId)
    local count = params[1]
    if not temp or count < 0 then
        return desc
    end
    if count > self._AttackedTimes then
        return string.format(desc, count - self._AttackedTimes)
    end
    return ""
end

--- 能否升变
---@return boolean
--------------------------
function XBlackRockChessPiece:IsPromotion()
    if XTool.UObjIsNil(self._Imp) then
        return false
    end
    return self._Imp:IsReachBottom() and XTool.IsNumberValid(self._OwnControl:GetPromotionPieceId(self._ConfigId))
end

function XBlackRockChessPiece:GetId()
    return self._Id
end

function XBlackRockChessPiece:GetHp()
    return self._Life
end

function XBlackRockChessPiece:GetExtraMaxHp()
    return self._ExtraMaxLife
end

function XBlackRockChessPiece:GetMaxHp()
    return self:GetConfigMaxHp() + self:GetExtraMaxHp()
end

function XBlackRockChessPiece:GetConfigMaxHp()
    if self:IsPiece() then
        return self._OwnControl:GetPieceMaxLife(self._ConfigId)
    else
        return self._OwnControl:GetPartnerMaxLife(self._ConfigId)
    end
end

function XBlackRockChessPiece:GetMoveCd()
    return self._MoveCd
end

function XBlackRockChessPiece:GetReinforceCd()
    return self._OwnControl:GetReinforceCd(self._ReinforceId)
end

function XBlackRockChessPiece:GetPartnerBornCd()
    local bornCd = self._OwnControl:GetPartnerPieceById(self._ConfigId).BornCd
    local roundCount = self._OwnControl:GetChessRound()
    return bornCd - roundCount
end

function XBlackRockChessPiece:CheckAttack(point)
    if XTool.UObjIsNil(self._Imp) then
        return false
    end
    if not self:IsAttackAble() then
        return false
    end
    return self._Imp:CheckAttack(point)
end

function XBlackRockChessPiece:IsAttackAble()
    if not self:IsPiece() then
        return false
    end

    if not self:IsAlive() then
        return false
    end

    if self:IsDizzy() then
        return false
    end

    return true
end

function XBlackRockChessPiece:GetMemberType()
    return self._MemberType
end

function XBlackRockChessPiece:IsPiece()
    return self._MemberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PIECE
end

---是否敌人增援虚影
function XBlackRockChessPiece:IsEnemyPreview()
    return self._MemberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.REINFORCE_PREVIEW
end

function XBlackRockChessPiece:IsPreview()
    return self._MemberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.REINFORCE_PREVIEW or self._MemberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PIECE_PREVIEW
end

function XBlackRockChessPiece:IsPartner()
    return self._MemberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PARTNERPIECE or self._MemberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PARTNERPIECE_PREVIEW
end

function XBlackRockChessPiece:IsBoss()
    return false
end

---是否友方预告（显示为虚影）
function XBlackRockChessPiece:IsPartnerPreview()
    return self._MemberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PARTNERPIECE_PREVIEW
end

function XBlackRockChessPiece:IsMoved()
    return self._IsMoved
end

function XBlackRockChessPiece:IsVirtual()
    if XTool.UObjIsNil(self._Imp) then
        return false
    end
    return self._Imp.IsVirtual
end

function XBlackRockChessPiece:GetPos()
    return self._X, self._Y
end

function XBlackRockChessPiece:GetMovedPoint()
    if XTool.UObjIsNil(self._Imp) then
        return CS.UnityEngine.Vector2Int.zero
    end
    return self._Imp.MovedPoint
end

function XBlackRockChessPiece:GetCurrentPoint()
    if XTool.UObjIsNil(self._Imp) then
        return CS.UnityEngine.Vector2Int.zero
    end
    return self._Imp.CurrentPoint
end

function XBlackRockChessPiece:MoveTo(point, onlyMove, finishCb)
    if XTool.UObjIsNil(self._Imp) then
        if finishCb then finishCb() end
        return
    end
    if self._Imp:IsMoving() then
        if finishCb then finishCb() end
        return
    end
    
    local movePoint = onlyMove and point or self._Imp:SearchByPoint()
    
    local newFinishCb = function()
        for _, buff in pairs(self._BuffDict) do
            if buff and buff:IsEffectiveByMoved() then
                self:TakeBuffEffect(buff, 0, false)
            end
        end
        self._OwnControl:SubWaitCount()
        if finishCb then finishCb() end
    end
    
    self._OwnControl:AddWaitCount()
    CS.XBlackRockChess.XBlackRockChessManager.Instance:MoveTo(self._Imp, movePoint.x, movePoint.y, newFinishCb)
    local movedPoint = self:GetMovedPoint()
    self._IsMoved = self._Imp:IsMoved() or not CS.XBlackRockChess.XBlackRockChessUtil.EqualVec2Int(movedPoint, movePoint)
end

---仅移动 不更新位置数据
function XBlackRockChessPiece:PlayMoveTo(point, finishCb)
    if XTool.UObjIsNil(self._Imp) or self._Imp:IsMoving() then
        if finishCb then
            finishCb()
        end
        return
    end

    local newFinishCb = function()
        --目前这个接口用于棋子受到格挡/角色免伤而返回原地的情况 这个时候棋子移动不成功 所以不用触发buff
        --for _, buff in pairs(self._BuffDict) do
        --    if buff and buff:IsEffectiveByMoved() then
        --        self:TakeBuffEffect(buff, 0, false)
        --    end
        --end
        self._OwnControl:SubWaitCount()
        if finishCb then
            finishCb()
        end
    end

    self._OwnControl:AddWaitCount()
    CS.XBlackRockChess.XBlackRockChessManager.Instance:PlayMoveTo(self._Imp, point.x, point.y, newFinishCb)
    local movedPoint = self:GetMovedPoint()
    self._IsMoved = self._Imp:IsMoved() or not CS.XBlackRockChess.XBlackRockChessUtil.EqualVec2Int(movedPoint, point)
end

function XBlackRockChessPiece:PlayMoveToWithPause(point, distance, finishCb)
    if XTool.UObjIsNil(self._Imp) or self._Imp:IsMoving() then
        if finishCb then
            finishCb()
        end
        return
    end

    local newFinishCb = function()
        --棋子移动不成功 不用触发buff
        --for _, buff in pairs(self._BuffDict) do
        --    if buff and buff:IsEffectiveByMoved() then
        --        self:TakeBuffEffect(buff, 0, false)
        --    end
        --end
        self._OwnControl:SubWaitCount()
        if finishCb then
            finishCb()
        end
    end

    self._OwnControl:AddWaitCount()
    CS.XBlackRockChess.XBlackRockChessManager.Instance:PlayMoveToWithPause(self._Imp, point.x, point.y, distance, newFinishCb)
    local movedPoint = self:GetMovedPoint()
    self._IsMoved = self._Imp:IsMoved() or not CS.XBlackRockChess.XBlackRockChessUtil.EqualVec2Int(movedPoint, point)
end

---寻找敌棋攻击目标
---1、如果攻击范围内存在友方棋子 则攻击友方棋子 否则攻击角色
---2、友方棋子排序：距离>血量
function XBlackRockChessPiece:SearchEnemyAttackTarget(ignorePieceIds)
    if XTool.UObjIsNil(self._Imp) then
        return nil
    end
    
    local actor = nil
    local partner = nil
    local distance = 0
    local impPoints = self._Imp:Search(self._Imp.MovedPoint, false)

    for i = 0, impPoints.Count - 1 do
        local point = impPoints[i]
        ---@type XBlackRockChess.XIPiece
        local target = CS.XBlackRockChess.XBlackRockChessManager.Instance:PieceAtCoord(point, true, false)
        if target then
            if target.ChessRole then
                actor = target
            elseif target.IsPartner and not target.IsVirtual and not ignorePieceIds[target.Id] then
                local dis = CS.UnityEngine.Vector2Int.Distance(self._Imp.MovedPoint, point)
                if not partner or dis < distance then
                    distance = dis
                    partner = target
                end
            end
        end
    end

    return actor or partner
end

---被角色击退
function XBlackRockChessPiece:AttackBack(point, onlyMove, finishCb)
    if XTool.UObjIsNil(self._Imp) then
        if finishCb then
            finishCb()
        end
        return
    end

    local movePoint = onlyMove and point or self._Imp:SearchByPoint()
    self._OwnControl:AddWaitCount()

    CS.XBlackRockChess.XBlackRockChessManager.Instance:MoveTo(self._Imp, movePoint.x, movePoint.y, function()
        --棋子移动不成功 不用触发buff
        --for _, buff in pairs(self._BuffDict) do
        --    if buff and buff:IsEffectiveByMoved() then
        --        self:TakeBuffEffect(buff, 0, false)
        --    end
        --end
        self._OwnControl:SubWaitCount()
        if finishCb then
            finishCb()
        end
    end)

    --击退无需发Action给服务端 服务端会根据角色技能和位置自己计算 
    self._IsMoved = false
end

function XBlackRockChessPiece:JumpTo(col, row, headHeight, finishCb)
    if XTool.UObjIsNil(self._Imp) then
        if finishCb then finishCb() end
        return
    end
    headHeight = headHeight or 1
    self._Imp:JumpTo(col, row, headHeight, finishCb)
    self._IsMoved = self._Imp:IsMoved()
end

function XBlackRockChessPiece:OnMoveEnd(col, row, isManual)
    self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.PIECE_MOVED)
end

function XBlackRockChessPiece:GetActionList(isRevive)
    local list = {}
    if XTool.UObjIsNil(self._Imp) then
        return list
    end
    local movedPoint = self:GetMovedPoint()
    if self:IsMoved() then
        table.insert(list, self:CreateAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE, movedPoint.x, movedPoint.y))
    end
    
    
    if self._IsPromotion and not isRevive then
        table.insert(list, self:CreateAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.PROMOTION, self._ConfigId))
    end
    
    local reinforceCd = self:GetReinforceCd() -- 下回合需要出现实体
    if self:IsPreview() and reinforceCd <= 0 and XTool.IsNumberValid(self._ReinforceId) and self._Imp and not isRevive then
        local result = self:DoReinforce()
        table.insert(list, self:CreateAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_TRIGGER,
                self._ReinforceId, movedPoint.x, movedPoint.y))
    end
    return list
end

function XBlackRockChessPiece:CreateAction(actionType, ...)
    if self:IsPartner() then
        return self._OwnControl:CreateAction(self._Id, actionType, XEnumConst.BLACK_ROCK_CHESS.CHESS_OBJ_TYPE.PARTNER, ...)
    else
        return self._OwnControl:CreateAction(self._Id, actionType, XEnumConst.BLACK_ROCK_CHESS.CHESS_OBJ_TYPE.ENEMY, ...)
    end
end

function XBlackRockChessPiece:OnClick(isPreview)
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_ENEMY, self._Id, isPreview)
end

function XBlackRockChessPiece:PrepareAttack(isAttack)
    if isAttack then
        self:Prepare4Attack()
    else
        self:CancelPrepareAttack()
    end
end

function XBlackRockChessPiece:Prepare4Attack()
    self._IsPrepareAttack = true
    if not self._OwnControl then
        return
    end
    self:LoadEffect(self._OwnControl:GetWarningEffectId(self:GetPieceType()))
end

function XBlackRockChessPiece:CancelPrepareAttack()
    self._IsPrepareAttack = false
    if not self._OwnControl then
        return
    end
    self:HideEffect(self._OwnControl:GetWarningEffectId(self:GetPieceType()))
end

--- 是否准备攻击
---@param 
---@return
--------------------------
function XBlackRockChessPiece:IsPrepareAttack()
    return self._IsPrepareAttack
end

function XBlackRockChessPiece:GetHitActorId()
    return self._OwnControl:GetMasterRoleId() --V3.0只有1个角色
end

function XBlackRockChessPiece:GetHitRoundCount()
    return 1 --V3.0没有多段伤害
end

--- 被角色攻击
---@param damage number 伤害
---@param isDizzy boolean 是否眩晕
---@param isOneShotKill boolean 是否一击必杀
---@param actorId number 造成伤害的角色Id
---@param hitRoundCount number 造成伤害角色回合数
---@param isNoCallBuff boolean 本次攻击是否不触发召唤buff
---@return boolean 是否造成伤害
--------------------------
function XBlackRockChessPiece:AttackEd(damage, isDizzy, isOneShotKill, actorId, hitRoundCount, isNoAttackedCallBuff)
    if not self:IsPiece() and not self:IsPartner() then
        return false
    end
    --已经被击杀了
    if self._Life <= 0 then
        return false
    end
    self._HitActorId = actorId
    self._HitRoundCount = hitRoundCount
    self._IsDizzy = isDizzy
    self._IsOnShotKill = isOneShotKill
    local isInvincible = self:TriggerAttackedBuff(actorId, isNoAttackedCallBuff)
    if self._Imp then
        self._AttackedTimes = self._AttackedTimes + 1
        self._Imp:UpdateData(self._AttackedTimes, self:IsPreview())
    end
    --受击喊话
    self._OwnControl:PlayGrowls(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PIECE,
            XMVCA.XBlackRockChess.GrowlsTriggerType.PieceAttacked, self:GetConfigId())
    --无敌
    if isInvincible then
        --self:DebugDps(0, isDizzy, isOneShotKill, actorId, true, self._Life)
        self:UpdateHeadHud()
        return true
    end
    damage = math.max(0, damage)
    self:SetHp(math.max(0, self._Life - damage))
    --self:DebugDps(damage, isDizzy, isOneShotKill, actorId, false, self._Life)
    if self._Life <= 0 or isOneShotKill then
        self:SetHp(0)
        self._Imp:MarkDead()
        if self:IsPiece() then
            self._OwnControl:AddKillCount(self:GetPieceType(), actorId)
        end
        return true
    end
    self:UpdateHeadHud()

    return true
end

--- 被棋子攻击（敌方棋子攻击友方棋子，友方棋子攻击敌方棋子）
function XBlackRockChessPiece:AttackEdByPiece(damage)
    return self:AttackEd(damage, false, false, nil, 0)
end

--- 是否能被攻击
function XBlackRockChessPiece:IsCanBeAttacked()
    --无敌
    if self:TriggerAttackedBuff() then
        return false
    end
    --敌方虚影
    if self:IsPreview() then
        return false
    end
    --友方虚影
    if self:IsPartnerPreview() then
        return false
    end
    return true
end

---获取棋子后方位置
---@param point UnityEngine.Vector2Int 参考位置
---@param dist number 距离
function XBlackRockChessPiece:GetPositionBehind(point, dist)
    local behinds = {}
    local movePoint = self:GetMovedPoint()
    for i = 1, dist do
        if movePoint.x == point.x then
            local offset = movePoint.y >= point.y and dist or -dist
            table.insert(behinds, { movePoint.x, movePoint.y + offset })
        elseif movePoint.y == point.y then
            local offset = movePoint.x >= point.x and dist or -dist
            table.insert(behinds, { movePoint.x + offset, movePoint.y })
        else
            local offsetX = movePoint.x >= point.x and dist or -dist
            local offsetY = movePoint.y >= point.y and dist or -dist
            table.insert(behinds, { movePoint.x + offsetX, movePoint.y + offsetY })
        end
    end
    return behinds
end

function XBlackRockChessPiece:GetAtkLift()
    return self._OwnControl:GetPieceAtkLife(self._ConfigId)
end

function XBlackRockChessPiece:TriggerAttackedBuff(actorId, isNoAttackedCallBuff)
    --一击必杀buff失效
    if self._IsOnShotKill then
        return false
    end
    --黑格buff失效
    if actorId and actorId > 0 then
        local actor = self._OwnControl:GetChessGamer():GetRole(actorId)
        if actor and actor:IsSilentAttackedBuff() then
            return false
        end
    end
    local isInvincible = false
    for _, buff in pairs(self._BuffDict) do
        local buffType = self._OwnControl:GetBuffType(buff.Id)
        --棋子受到反击伤害后又受到撞击伤害 则后面的撞击不会触发【受伤时召唤棋子的buff】
        if isNoAttackedCallBuff and buffType == BuffType.CallAfterWithAttacked then
            goto continue
        end
        if buff:IsEffectiveByAttacked() then
            --触发每个buff
            self:TakeBuffEffect(buff, actorId, true)
            if buff:CheckIsImmuneInjury() then
                isInvincible = true
            end
        end
        :: continue ::
    end
    
    return isInvincible
end

function XBlackRockChessPiece:DebugDps(damage, isDizzy, isOneShotKill, actorId, isInvincible, life)
    local point = self:GetMovedPoint()
    local pos = "(" .. point.x .. ", " .. point.y ..")"
    local str = string.format("攻击信息: \nId: %s\n坐标：%s\n伤害：%s\n生命：%s\n眩晕：%s\n一击必杀：%s\n攻击者：%s\n无敌：%s\n死亡：%s", 
            self:GetId(), pos, damage, life, isDizzy, isOneShotKill, actorId, isInvincible, life <= 0)
    
    XLog.Error(str)
end

function XBlackRockChessPiece:AddHp(value)
    if not self:IsAlive() or (not self:IsPiece() and not self:IsPartner()) then
        return
    end
    local maxLift = self:GetMaxHp()
    self:SetHp(math.min(maxLift, self._Life + value))
    self:UpdateHeadHud()
end

---增加HP和血量上限
function XBlackRockChessPiece:AddHpOverflow(value)
    if not self:IsAlive() or (not self:IsPiece() and not self:IsPartner()) then
        return
    end
    self:SetHp(self._Life + value)
    self._ExtraMaxLife = math.max(0, self._Life - self:GetConfigMaxHp())
    self:UpdateHeadHud()
end

function XBlackRockChessPiece:SetPreviewDead(value)
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    if not self:IsPiece() then
        return
    end

    if not self:IsAlive() then
        return
    end

    if self._Imp.IsPreviewDead == nil then
        return
    end
    
    self._Imp.IsPreviewDead = value
end

function XBlackRockChessPiece:IsPreviewDead()
    if XTool.UObjIsNil(self._Imp) then
        return false
    end
    return self._Imp.IsPreviewDead
end

--是否无敌
function XBlackRockChessPiece:IsInvincible(actorId, previewCount)
    previewCount = previewCount or -1
    if actorId and actorId > 0 then
        local actor = self._OwnControl:GetChessGamer():GetRole(actorId)
        if actor and actor:IsSilentAttackedBuff() then
            return false
        end
    end
    local isInvincible = false
    for _, buff in pairs(self._BuffDict) do
        if buff:IsEffectiveByAttacked() and buff:CheckIsImmuneInjury(previewCount) then
            isInvincible = true
            break
        end
    end
    
    return isInvincible
end

function XBlackRockChessPiece:LookAt(col, row)
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    self._Imp:TurnRound(col, row)
end

function XBlackRockChessPiece:GetIconFollow()
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    return self._Imp.transform 
end

function XBlackRockChessPiece:DoDead()
    if self._IsPlayDead then
        return
    end
    
    self._IsPlayDead = true
    --标记等待
    self._OwnControl:AddWaitCount()
    --倒地动画
    self:PlayAnimation("ChessFall")
    --死亡喊话
    self._OwnControl:PlayGrowls(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PIECE, 
            XMVCA.XBlackRockChess.GrowlsTriggerType.PieceKilled, self:GetConfigId())
    --播放音效
    --self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.PIECE_BREAK)
    local playDelay = self._OwnControl:GetDeadEffectDelay(1)
    --延时加载死亡特效
    self:LoadEffect(self._OwnControl:GetDeadEffectId(), nil, nil, playDelay)
    local hideDelay = self._OwnControl:GetDeadEffectDelay(2)
    --等待特效播放完毕摧毁棋子
    XScheduleManager.ScheduleOnce(function()
        --取消标记
        if self._OwnControl then
            self._OwnControl:SubWaitCount()
        end
        if XTool.UObjIsNil(self._Imp) then
            return
        end
        self._Imp:Disable()
        self._IsPrepareRemove = true
        self:TriggerDeadBuff(self._HitActorId)
        XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_ENEMY, self._Id, false)
        self:HideHeadHud()
        self._OwnControl:GetChessEnemy():ProcessPieceEffect()
    end, hideDelay)

    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
end

-- 临时棋子过期移除
function XBlackRockChessPiece:DoDestroy()
    self:SetHp(0)
    self:UpdateHeadHud()
    --倒地动画
    self:PlayAnimation("ChessFall")
    --延时加载死亡特效
    local playDelay = self._OwnControl:GetDeadEffectDelay(1)
    self:LoadEffect(self._OwnControl:GetDeadEffectId(), nil, nil, playDelay)
    --等待特效播放完毕摧毁棋子
    local hideDelay = self._OwnControl:GetDeadEffectDelay(2)
    XScheduleManager.ScheduleOnce(function()
        if self._Imp then
            self._Imp.gameObject:SetActiveEx(false)
            self:HideHeadHud()
        end
    end, hideDelay)
end

function XBlackRockChessPiece:TriggerDeadBuff(actorId)
    if self._IsOnShotKill then
        return
    end
    for _, buff in pairs(self._BuffDict) do
        if buff:IsEffectiveByDead() then
            --触发每个buff
            self:TakeBuffEffect(buff, actorId, true)
        end
    end
end

--升变
function XBlackRockChessPiece:Promotion()
    local pieceId = self._OwnControl:GetPromotionPieceId(self._ConfigId)
    local movedPoint = self:GetMovedPoint()
    local x, y = movedPoint.x, movedPoint.y
    --移除旧棋子
    self._Imp:Destroy()
    --添加新棋子
    local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddPiece(pieceId, x, y, false)
    self._OldConfigId = self._ConfigId
    self._ConfigId = pieceId
    self._IsPromotion = true
    self:SetImp(imp)
    self:UpdateHeadHud()
end

---@param imp XBlackRockChess.XPiece
function XBlackRockChessPiece:DoReinforcePreview(imp)
    if not imp then
        return
    end
    self:SetImp(imp)
end

function XBlackRockChessPiece:DoReinforcePreviewRetract(needEnable)
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    if needEnable then
        self._Imp:Enable()
    end
    CS.XBlackRockChess.XBlackRockChessManager.Instance:Piece2Virtual(self._Imp)
    self:DoReinforcePreview(self._Imp)
end

function XBlackRockChessPiece:DoReinforce()
    if XTool.UObjIsNil(self._Imp) then
        return false
    end
    local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:Virtual2Piece(self._Imp)
    if imp then
        --成功增援
        self:SetImp(imp)
        self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.REINFORCE_COMING)
        return true
    end

    --增援失败
    self:HideHeadHud()
    self._Imp:Disable()
    self._OwnControl:GetChessEnemy():AddFailReinforceImp(self)
    return false
end

function XBlackRockChessPiece:RestoreReinforce()
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    CS.XBlackRockChess.XBlackRockChessManager.Instance:Piece2Virtual(self._Imp)
    self._OwnControl:LoadVirtualEffect(self._Imp, self._ConfigId)
end

--处理类型为棋子，ReinforceId不为空，但是棋子还是虚影的情况
function XBlackRockChessPiece:UpdateReinforce()
    --不是增援出的棋子
    if not XTool.IsNumberValid(self._ReinforceId) then
        return
    end
    
    --不是棋子
    if XTool.UObjIsNil(self._Imp) or not self:IsPiece() then
        return
    end

    --不是虚影
    if not self._Imp.IsVirtual then
        return
    end
    
    self:DoReinforce()
end

function XBlackRockChessPiece:Summon(imp, isPartner, isVirtual)
    if isVirtual then
        self._OwnControl:HideVirtualEffect(imp, imp.ConfigId)
        local temp = CS.XBlackRockChess.XBlackRockChessManager.Instance:Virtual2Piece(imp)
        if temp then
            self:SetImp(temp)
        else
            self:HideHeadHud()
            imp:Destroy()
            if self:IsPartner() then
                self._OwnControl:GetChessPartner():RemovePieceInfo(self._Id)
            else
                self._OwnControl:GetChessEnemy():RemovePieceInfo(self._Id)
            end
        end
    else
        self:SetImp(imp)
    end
    if self:IsPartner() then
        self._OwnControl:GetChessPartner():ProcessPieceEffect()
    else
        self._OwnControl:GetChessEnemy():ProcessPieceEffect()
    end
end

function XBlackRockChessPiece:TransformPiece(imp, configId)
    self._ConfigId = configId
    --提前更新数据
    self._MoveCd = self._OwnControl:GetPieceInitCd(self._ConfigId)
    --转化不会继承额外最大血量
    self:SetHp(self:GetConfigMaxHp())
    self._ExtraMaxLife = 0
    --避免当前回合移动了，下回合更新后正常
    self._MemberType = XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.REINFORCE_PREVIEW
    self:SetImp(imp)

    self._OwnControl:GetChessEnemy():ProcessPieceEffect()
end

function XBlackRockChessPiece:RestoreTransform(imp, configId, isVirtual)
    self._ConfigId = configId
    --避免当前回合移动了，下回合更新后正常
    self._MemberType = XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PIECE
    CS.XBlackRockChess.XBlackRockChessManager.Instance:RestoreTransformer(imp, self._Imp)
    if isVirtual then
        CS.XBlackRockChess.XBlackRockChessManager.Instance:RestoreVirtualShadow(self._Imp)
    end
    self:SetImp(imp)
end

function XBlackRockChessPiece:OnBuffTakeEffect(args)
    local buffId = args[0]
    self._OwnControl:OnBuffTakeEffect(args, self._BuffDict[buffId], self)
end

--- 触发Buff
---@param buff XBlackRockChess.XBuff
---@param actorId number
---@param isCheckBuff boolean
---@return
--------------------------
function XBlackRockChessPiece:TakeBuffEffect(buff, actorId, isCheckBuff)
    if not buff then
        return
    end
    --被强制击杀时, 如果是击杀+受击类Buff不生效
    if self._IsOnShotKill then
        if buff:IsEffectiveByAttacked() or buff:IsEffectiveByDead() then
            return
        end
    end
    --buff效果不生效
    if isCheckBuff and actorId and actorId > 0 then
        local actor = self._OwnControl:GetChessGamer():GetRole(actorId)
        if actor and actor:IsSilentAttackedBuff() then
            return
        end
    end
    buff:DoTakeEffect()
end

function XBlackRockChessPiece:LoadEffect(effectId, offset, rotate, delay, isBindRole)
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    offset = offset or CS.UnityEngine.Vector3.zero
    rotate = rotate or CS.UnityEngine.Vector3.zero
    if delay and delay > 0 then
        XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self._Imp) then
                return
            end

            if XTool.UObjIsNil(self._Imp.gameObject) then
                return
            end
            self._Imp:LoadEffect(effectId, offset, rotate)
        end, delay)
    end
    isBindRole = isBindRole or false
    self._Imp:LoadEffect(effectId, offset, rotate, isBindRole)
end

function XBlackRockChessPiece:HideEffect(effectId)
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    self._Imp:HideEffect(effectId)
end

function XBlackRockChessPiece:OnSkillHit()
    local hitEffectId = self._OwnControl:GetHitEffectId(self:GetPieceType())
    self:OnSkillHitManual(hitEffectId)
end

function XBlackRockChessPiece:OnSkillHitManual(hitEffectId)
    self:LoadEffect(hitEffectId)
    if self._IsDizzy then
        self:LoadEffect(self._OwnControl:GetDizzyEffectId())
    end
    --更新特效显示
    self:DoProcessBuffEffect()

    local isDead = not self:IsAlive()
    if isDead then
        self:DoDead()
    end
end

-- 回合开始时，需要隐藏的特效
function XBlackRockChessPiece:DoHideEffectOnRoundBegin()
    -- 眩晕
    self:HideEffect(self._OwnControl:GetDizzyEffectId())
end

function XBlackRockChessPiece:DoHideEffectOnRoundEnd()
    
end

-- 回合开始，处理Buff特效
function XBlackRockChessPiece:DoProcessBuffEffect()
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    if not self:IsPiece() then
        return
    end
    for _, buff in pairs(self._BuffDict) do
        if not buff then
            goto continue
        end
        local isImmuneInjury = buff:CheckIsImmuneInjury()
        local effectId = self._OwnControl:GetBuffEffectId(buff.Id)
        local buffType = self._OwnControl:GetBuffType(buff.Id)
        --本期需要判断特效显示和隐藏的 只有无敌类buff 其余buff的特效 一直显示即可
        if ImmuneInjuryBuffDict[buffType] then
            if not isImmuneInjury then
                if XTool.IsNumberValid(effectId) then
                    self:HideEffect(effectId)
                end
                goto continue
            end
        end

        if not XTool.IsNumberValid(effectId) then
            goto continue
        end
        
        self:LoadEffect(effectId)
        
        ::continue::
    end
end

--棋子加载时处理buff特效
function XBlackRockChessPiece:DoProcessBuffEffectOnLoad()
    if not self:IsPiece() then
        return
    end
    local isLoad = false
    for _, buff in pairs(self._BuffDict) do
        if not buff then
            goto continue
        end
        local effectId = self._OwnControl:GetBuffEffectId(buff.Id)
        local buffType = self._OwnControl:GetBuffType(buff.Id)
        --2,3,4为无敌特效，由具体逻辑计算
        if buffType == 2 or buffType == 3 or buffType == 4 then
            goto continue
        end
        if not XTool.IsNumberValid(effectId) then
            XLog.Error("Buff加载特效失败，Buff的特效Id配置为0, BuffId = " .. buff.Id)
            goto continue
        end
        isLoad = true
        self:LoadEffect(effectId)
        ::continue::
    end
    if isLoad then
        self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.PIECE_BUFF)
    end
end

--数据更新时
function XBlackRockChessPiece:DoProcessEffectOnDataUpdate()
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    -- 虚影
    if not self:IsPreview() then
        self._OwnControl:HideVirtualEffect(self._Imp, self._ConfigId)
    end
end

function XBlackRockChessPiece:PlayAnimation(actionId, isInverse, finish)
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    isInverse = isInverse or false
    self._Imp:PlayAnimation(actionId, isInverse, finish)
end

function XBlackRockChessPiece:ShowBubbleText(text)
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    self._OwnControl:ShowBubbleText(self._Imp, text)
end

--region   ------------------Sync start-------------------

function XBlackRockChessPiece:SyncLocation()
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    self._Imp:Sync(self._X, self._Y)
end

function XBlackRockChessPiece:RestoreLocation()
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    self._OwnControl:AddWaitCount()
    self._Imp:Restore(self._X, self._Y, function()
        self._OwnControl:SubWaitCount()
    end)
end

function XBlackRockChessPiece:SyncPromotion()
    if self._IsPromotion then
        self._OldConfigId = nil
    end
    self._IsPromotion = false
end

function XBlackRockChessPiece:RestorePromotion()
    --移除新棋子
    if self._IsPromotion then
        self._ConfigId = self._OldConfigId
        local movedPoint = self:GetMovedPoint()
        local x, y = movedPoint.x, movedPoint.y
        self._Imp:Destroy()
        --还原旧棋子
        local imp
        if self:IsPartner() then
            imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddPartnerPiece(self._ConfigId, x, y, false)
        else
            imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddPiece(self._ConfigId, x, y, false)
        end
        self:SetImp(imp)
        self:UpdateHeadHud()
        self._OldConfigId = nil
    end
    self._IsPromotion = false
end

function XBlackRockChessPiece:SyncRemove()
    if self._IsPrepareRemove then
        self._Imp:Destroy()
        if self:IsPartner() then
            self._OwnControl:GetChessPartner():RemovePieceInfo(self._Id)
        else
            self._OwnControl:GetChessEnemy():RemovePieceInfo(self._Id)
        end
    end
    self._IsPrepareRemove = false
end

function XBlackRockChessPiece:RestoreRemove()
    if self._Imp and self._IsPrepareRemove then
        self._Imp:Enable()
        self:UpdateHeadHud()
    end
    self._IsPrepareRemove = false
    
end

function XBlackRockChessPiece:Sync()
    self:SyncLocation()
    self:SyncRemove()
    self:SyncPromotion()
    self._IsDizzy = false
    self._IsMoved = false
    self._IsPlayDead = false
end

---在角色预览技能攻击范围且有棋子将会被击杀时 棋子是否能攻击到角色
function XBlackRockChessPiece:IsAttackActorPreview(point)
    if XTool.UObjIsNil(self._Imp) then
        return false
    end
    local pieceType = self:GetPieceType()
    local chessType = XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE
    -- 士兵、骑士和国王的攻击范围比较特殊
    if pieceType == chessType.PAWN or pieceType == chessType.KNIGHT or pieceType == chessType.KING then
        return false
    end
    local actorPoint = self._OwnControl:GetMasterRole():GetMovedPoint()
    if pieceType == chessType.BISHOP then
        return self:CheckBishopMoveRange(point)
    elseif pieceType == chessType.ROOK then
        return self:CheckRookMoveRange(point)
    elseif pieceType == chessType.QUEEN then
        return self:CheckQueenMoveRange(point)
    end
    return false
end

function XBlackRockChessPiece:IsAttackPointPreview(dimPoint)
    if XTool.UObjIsNil(self._Imp) then
        return false
    end
    local impPoints = self._Imp:Search(self._Imp.MovedPoint, false)
    for i = 0, impPoints.Count - 1 do
        local point = impPoints[i]
        if point.x == dimPoint.x and point.y == dimPoint.y then
            return true
        end
    end
    return self:IsAttackActorPreview(dimPoint)
end

-- 主教移动范围：X
function XBlackRockChessPiece:CheckBishopMoveRange(point)
    local v2Int = CS.UnityEngine.Vector2Int(0, 0)
    local moveRange = self._Imp.BuffMoveRange >= 0 and self._Imp.BuffMoveRange or self._Imp.DefaultMoveRange
    for i = 1, 4 do
        local isBlockDead = false
        for j = 1, moveRange do
            local x, y
            if i == 1 then
                x = -j
                y = j
            elseif i == 2 then
                x = j
                y = j
            elseif i == 3 then
                x = j
                y = -j
            else
                x = -j
                y = -j
            end
            x = x + self._Imp.MovedPoint.x
            y = y + self._Imp.MovedPoint.y
            if x > 8 or y > 8 or x < 1 or y < 1 then
                break
            end
            if point.x == x and point.y == y then
                -- 只有在阻挡棋子死亡后能攻击到时才返回true
                return isBlockDead
            end
            v2Int:Set(x, y)
            local piece = CS.XBlackRockChess.XBlackRockChessManager.Instance:PieceAtCoord(v2Int)
            if piece then
                if piece.IsPreviewDead then
                    isBlockDead = true
                else
                    break
                end
            end
        end
    end
    return false
end

-- 城堡移动范围：＋
function XBlackRockChessPiece:CheckRookMoveRange(point)
    local v2Int = CS.UnityEngine.Vector2Int(0, 0)
    local moveRange = self._Imp.BuffMoveRange >= 0 and self._Imp.BuffMoveRange or self._Imp.DefaultMoveRange
    for i = 1, 4 do
        local isBlockDead = false
        for j = 1, moveRange do
            local x, y
            if i == 1 then
                x = 0
                y = j
            elseif i == 2 then
                x = j
                y = 0
            elseif i == 3 then
                x = 0
                y = -j
            else
                x = -j
                y = 0
            end
            x = x + self._Imp.MovedPoint.x
            y = y + self._Imp.MovedPoint.y
            if x > 8 or y > 8 or x < 1 or y < 1 then
                break
            end
            if point.x == x and point.y == y then
                -- 只有在阻挡棋子死亡后能攻击到时才返回true
                return isBlockDead
            end
            v2Int:Set(x, y)
            local piece = CS.XBlackRockChess.XBlackRockChessManager.Instance:PieceAtCoord(v2Int)
            if piece then
                if piece.IsPreviewDead then
                    isBlockDead = true
                else
                    break
                end
            end
        end
    end
    return false
end

-- 皇后移动范围：※
function XBlackRockChessPiece:CheckQueenMoveRange(point)
    return self:CheckBishopMoveRange(point) or self:CheckRookMoveRange(point)
end

function XBlackRockChessPiece:Restore()
    self:RestorePromotion()
    self:RestoreRemove()
    self:RestoreLocation()
    self._IsDizzy = false
    self._IsMoved = false
    self._IsPlayDead = false
end

function XBlackRockChessPiece:ForceDestroy()
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    self._Imp:Destroy()
    self._Imp = nil
end

--endregion------------------Sync finish------------------

return XBlackRockChessPiece