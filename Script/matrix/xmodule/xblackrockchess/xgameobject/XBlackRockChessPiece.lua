
---@class XBlackRockChessPiece : XEntity 棋子
---@field _MoveCd number 移动冷却回合
---@field _Id number 流水号Id
---@field _ConfigId number 配置Id
---@field _Life number 生命值
---@field _Imp XBlackRockChess.XPiece 棋子CS引用
---@field _OwnControl XBlackRockChessControl 控制器
---@field _BuffDict table<number, XBlackRockChess.XBuff> buff字典， Key为BuffId
local XBlackRockChessPiece = XClass(XEntity, "XBlackRockChessPiece")

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
    self._Life = 0
    self._AttackedTimes = 0
    self._Status = 0
    self._ReinforceId = 0
end

function XBlackRockChessPiece:SetImp(imp, isEnterFight)
    self._Imp = imp
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

function XBlackRockChessPiece:InitImp()
    self._Imp.Id = self._Id
    self._Imp:UpdateData(self._AttackedTimes, self:IsPreview())
    local isAttack = function()
        return self:IsAttackAble()
    end
    self._Imp:RegisterLuaCallBack(handler(self, self.OnClick), handler(self, self.PrepareAttack), 
            isAttack, handler(self, self.OnMoveEnd))
    
    self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_HEAD_HUD, self._Id, self:GetIconFollow())
    if self:IsPreview() then
        self._OwnControl:LoadVirtualEffect(self._Imp, self._ConfigId)
    end
    self._Imp:InitAnimator(self._OwnControl:GetPieceController())
end

function XBlackRockChessPiece:ApplyBuff()
    local buffIds = self._OwnControl:GetPieceBuffIds(self._ConfigId)
    local map = {}
    self._BuffDict = {}
    for _, buffId in ipairs(buffIds) do
        local buffType = self._OwnControl:GetBuffType(buffId)
        --local buff = CS.XBlackRockChess.XBlackRockChessUtil.CreateBuff(buffType)
        map[buffType] = buffId
        --if buff then
        --    local args = self._Control:GetBuffParams(buffId)
        --    table.insert(self._Buffs, buff)
        --    buff:Apply(buffId, self._Imp, table.unpack(args))
        --    buff:AddTakeEffectCb(handler(self, self.OnBuffTakeEffect))
        --end
    end
    for buffType, buffId in pairs(map) do
        local buff = CS.XBlackRockChess.XBlackRockChessUtil.CreateBuff(buffType)
        if buff then
            local args = self._OwnControl:GetBuffParams(buffId)
            self._BuffDict[buffId] = buff
            buff:Apply(buffId, self._Imp, table.unpack(args))
            buff:AddTakeEffectCb(handler(self, self.OnBuffTakeEffect))

            if buff:IsEffectiveByStageInit() then
                buff:TakeEffect()
            end
        end
    end
    --self:DoProcessBuffEffect()
    self:DoProcessBuffEffectOnLoad()
end

function XBlackRockChessPiece:GetLocalInfo()
    return {
        Imp = self._Imp,
        ConfigId = self._ConfigId,
        IsVirtual = self._OwnControl:GetChessGamer():IsExtraTurn()
    }
end

function XBlackRockChessPiece:OnRelease()
    self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.HIDE_HEAD_HUD, self._Id)
    self._Imp = nil
    self._OwnControl = nil
    self._IsPrepareRemove = false
    self._IsDizzy = false
    self._IsPromotion = false
    self._BuffDict = {}
end

function XBlackRockChessPiece:UpdateData(x, y, memberType, data)
    self._X = x
    self._Y = y
    self._MemberType = memberType
    self._MoveCd = data.MoveCd
    self._Life = data.Life
    self._AttackedTimes = data.AttackedTimes
    self._Status = data.Status
    self._ReinforceId = data.ReinforceId
    --触发了升变，当前回合改变了
    if self._ConfigId ~= data.PieceId then
        self._OldConfigId = data.PieceId
        self._IsPromotion = true
        self:RestorePromotion()
    end
    self._ConfigId = data.PieceId
    if not XTool.IsTableEmpty(data.BuffList) then
        for _, buffData in ipairs(data.BuffList) do
            local buff = self._BuffDict[buffData.BuffId]
            if buff then
                buff.EffectCount = buffData.Count
            end
        end
    end
    if self._Imp then
        self._Imp:UpdateData(self._AttackedTimes, self:IsPreview())
    end
    self:UpdateReinforce()
    self:DoProcessEffectOnDataUpdate()
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

function XBlackRockChessPiece:GetAttackTimes()
    return self._AttackedTimes
end

function XBlackRockChessPiece:GetPieceType()
    if not self._OwnControl then
        return
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
    if not self._Imp then
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

function XBlackRockChessPiece:GetMoveCd()
    return self._MoveCd
end

function XBlackRockChessPiece:CheckAttack(point)
    if not self._Imp then
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

function XBlackRockChessPiece:IsPreview()
    return self._MemberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.REINFORCE_PREVIEW
end

function XBlackRockChessPiece:IsMoved()
    return self._IsMoved
end

function XBlackRockChessPiece:GetPos()
    return self._X, self._Y
end

function XBlackRockChessPiece:GetMovedPoint()
    if not self._Imp then
        return CS.UnityEngine.Vector2Int.zero
    end
    return self._Imp.MovedPoint
end

function XBlackRockChessPiece:GetCurrentPoint()
    if not self._Imp then
        return CS.UnityEngine.Vector2Int.zero
    end
    return self._Imp.CurrentPoint
end

function XBlackRockChessPiece:MoveTo(point, onlyMove, finishCb)
    if not self._Imp then
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

function XBlackRockChessPiece:JumpTo(col, row, headHeight, finishCb)
    if not self._Imp then
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
    if not self._Imp then
        return list
    end
    local movedPoint = self:GetMovedPoint()
    if self:IsMoved() then
        table.insert(list, self:CreateAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE, movedPoint.x, movedPoint.y))
    end
    
    
    if self._IsPromotion and not isRevive then
        table.insert(list, self:CreateAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.PROMOTION, self._ConfigId))
    end
    
    if self:IsPreview() and self._MoveCd == 0 and XTool.IsNumberValid(self._ReinforceId) and self._Imp and not isRevive then
        local result = self:DoReinforce()
        table.insert(list, self:CreateAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_TRIGGER,
                self._ReinforceId, movedPoint.x, movedPoint.y))
    end
    return list
end

function XBlackRockChessPiece:CreateAction(actionType, ...)
    return self._OwnControl:GetChessEnemy():CreateAction(self._Id, actionType, ...)
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

--- 被攻击
---@param damage number 伤害
---@param isDizzy boolean 是否眩晕
---@param isOneShotKill boolean 是否一击必杀
---@param actorId number 造成伤害的角色Id
---@param hitRoundCount number 造成伤害角色回合数
---@return boolean 是否造成伤害
--------------------------
function XBlackRockChessPiece:AttackEd(damage, isDizzy, isOneShotKill, actorId, hitRoundCount)
    if not self:IsPiece() then
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
    local isInvincible = self:TriggerAttackedBuff(actorId)
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
        self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_HEAD_HUD, self._Id, self:GetIconFollow())
        return true
    end
    damage = math.max(0, damage)
    self._Life = math.max(0, self._Life - damage)
    --self:DebugDps(damage, isDizzy, isOneShotKill, actorId, false, self._Life)
    if self._Life <= 0 or isOneShotKill then
        self._Life = 0
        self._Imp:MarkDead()
        self._OwnControl:AddKillCount(self:GetPieceType())
        return true
    end
    self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_HEAD_HUD, self._Id, self:GetIconFollow())

    return true
end

function XBlackRockChessPiece:TriggerAttackedBuff(actorId)
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
        if buff:IsEffectiveByAttacked() then
            --触发每个buff
            self:TakeBuffEffect(buff, actorId, true)
            if buff:IsImmuneInjury() then
                isInvincible = true
            end
        end
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
    if not self:IsAlive() or not self:IsPiece() then
        return
    end
    self._Life = self._Life + value
    self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_HEAD_HUD, self._Id, self:GetIconFollow())
end

function XBlackRockChessPiece:SetPreviewDead(value)
    if not self._Imp then
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

--是否无敌
function XBlackRockChessPiece:IsInvincible(actorId, previewCount)
    if actorId and actorId > 0 then
        local actor = self._OwnControl:GetChessGamer():GetRole(actorId)
        if actor and actor:IsSilentAttackedBuff() then
            return false
        end
    end
    local isInvincible = false
    for _, buff in pairs(self._BuffDict) do
        if buff:IsEffectiveByAttacked() and buff:IsImmuneInjury(previewCount) then
            isInvincible = true
            break
        end
    end
    
    return isInvincible
end

function XBlackRockChessPiece:LookAt(col, row)
    if not self._Imp then
        return
    end
    self._Imp:TurnRound(col, row)
end

function XBlackRockChessPiece:GetIconFollow()
    if not self._Imp then
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
    self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.PIECE_BREAK)
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
        if not self._Imp then
            return
        end
        self._Imp:Disable()
        self._IsPrepareRemove = true
        self:TriggerDeadBuff(self._HitActorId)
        XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_ENEMY, self._Id, false)
        self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.HIDE_HEAD_HUD, self._Id)
        self._OwnControl:GetChessEnemy():ProcessPieceEffect()
    end, hideDelay)
    
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
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
    
    self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_HEAD_HUD, self._Id, self:GetIconFollow())
end

---@param imp XBlackRockChess.XPiece
function XBlackRockChessPiece:DoReinforcePreview(imp)
    if not imp then
        return
    end
    self:SetImp(imp)
end

function XBlackRockChessPiece:DoReinforcePreviewRetract(needEnable)
    if not self._Imp then
        return
    end
    if needEnable then
        self._Imp:Enable()
    end
    CS.XBlackRockChess.XBlackRockChessManager.Instance:Piece2Virtual(self._Imp)
    self:DoReinforcePreview(self._Imp)
end

function XBlackRockChessPiece:DoReinforce()
    if not self._Imp then
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
    self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.HIDE_HEAD_HUD, self._Id)
    self._Imp:Disable()
    self._OwnControl:GetChessEnemy():AddFailReinforceImp(self)
    return false
end

function XBlackRockChessPiece:RestoreReinforce()
    if not self._Imp then
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
    if not self._Imp or not self:IsPiece() then
        return
    end

    --不是虚影
    if not self._Imp.IsVirtual then
        return
    end
    
    self:DoReinforce()
end

function XBlackRockChessPiece:Summon(imp, isVirtual)
    if isVirtual then
        self._OwnControl:HideVirtualEffect(imp, imp.ConfigId)
        local temp = CS.XBlackRockChess.XBlackRockChessManager.Instance:Virtual2Piece(imp)
        if temp then
            self:SetImp(temp)
        else
            self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.HIDE_HEAD_HUD, self._Id)
            imp:Destroy()
            self._OwnControl:GetChessEnemy():RemovePieceInfo(self._Id)
        end
    else
        self:SetImp(imp)
    end
    
    self._OwnControl:GetChessEnemy():ProcessPieceEffect()
end

function XBlackRockChessPiece:TransformPiece(imp, configId)
    self._ConfigId = configId
    --提前更新数据
    self._MoveCd = self._OwnControl:GetPieceInitCd(self._ConfigId)
    self._Life = self._OwnControl:GetPieceMaxLife(self._ConfigId)
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
    local buffId, buffType = args[0], args[1]

    if buffType == XMVCA.XBlackRockChess.BuffType.CallAfterDeath
            or buffType == XMVCA.XBlackRockChess.BuffType.CallAfterDeathWithAround
            or buffType == XMVCA.XBlackRockChess.BuffType.CallAfterWithAttacked
            or buffType == XMVCA.XBlackRockChess.BuffType.CallAfterMoveWithAround
    then
        local buff = self._BuffDict[buffId]
        local effectCount = buff and buff.EffectCount or 0
        self._OwnControl:GetChessEnemy():Summon(self._Id, buffId, args[2], 
                args[3] or self._OwnControl:GetChessGamer():IsExtraTurn(), effectCount, self._HitActorId, self
                        ._HitRoundCount)
        
    elseif buffType == XMVCA.XBlackRockChess.BuffType.TransformerWithDeath then
        self._OwnControl:GetChessEnemy():TransformPiece(self._Id, args[2], args[3], self._HitActorId, self._HitRoundCount)
        
    elseif buffType == XMVCA.XBlackRockChess.BuffType.ChangeSkillPropertyWithDeath then
        local cd, energy = args[2], args[3]
        self._OwnControl:GetChessGamer():ConsumeEnergy(-energy)
        if XTool.IsNumberValid(self._HitActorId) then
            local actor = self._OwnControl:GetChessGamer():GetRole(self._HitActorId)
            --不在场，则获取主控角色
            if not actor or not actor:IsInBoard() then
                actor = self._OwnControl:GetChessGamer():GetRole(self._OwnControl:GetMasterRoleId())
            end
            actor:AddSkillCd(cd)
        end
    elseif buffType == XMVCA.XBlackRockChess.BuffType.AddFriendlyHpWithDeath then
        local addHp, pieceTypes = args[2], args[3]
        for i = 0, pieceTypes.Length - 1 do
            local pieceType = pieceTypes[i]
            self._OwnControl:GetChessEnemy():AddHpByType(pieceType, addHp)
        end
    end
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
    buff:TakeEffect()
end

function XBlackRockChessPiece:LoadEffect(effectId, offset, rotate, delay, isBindRole)
    if not self._Imp then
        return
    end
    offset = offset or CS.UnityEngine.Vector3.zero
    rotate = rotate or CS.UnityEngine.Vector3.zero
    if delay and delay > 0 then
        XScheduleManager.ScheduleOnce(function()
            if not self._Imp then
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
    if not self._Imp then
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
    if not self._Imp then
        return
    end
    if not self:IsPiece() then
        return
    end
    for _, buff in pairs(self._BuffDict) do
        if not buff then
            goto continue
        end
        local isImmuneInjury = buff:IsImmuneInjury()
        local effectId = self._OwnControl:GetBuffEffectId(buff.Id)
        --只处理无敌的特效，本期暂无其他特效
        if not isImmuneInjury then
            if XTool.IsNumberValid(effectId) then
                self:HideEffect(effectId)
            end
            goto continue
        end

        if not XTool.IsNumberValid(effectId) then
            XLog.Error("Buff加载特效失败，Buff的特效Id配置为0, BuffId = " .. buff.Id)
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
    if not self._Imp then
        return
    end
    -- 虚影
    if not self:IsPreview() then
        self._OwnControl:HideVirtualEffect(self._Imp, self._ConfigId)
    end
end

function XBlackRockChessPiece:PlayAnimation(actionId, isInverse, finish)
    if not self._Imp then
        return
    end
    isInverse = isInverse or false
    self._Imp:PlayAnimation(actionId, isInverse, finish)
end

function XBlackRockChessPiece:ShowBubbleText(text)
    if not self._Imp then
        return
    end
    self._OwnControl:ShowBubbleText(self._Imp, text)
end

--region   ------------------Sync start-------------------

function XBlackRockChessPiece:SyncLocation()
    if not self._Imp then
        return
    end
    self._Imp:Sync(self._X, self._Y)
end

function XBlackRockChessPiece:RestoreLocation()
    if not self._Imp then
        return
    end
    self._Imp:Restore(self._X, self._Y)
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
        local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddPiece(self._ConfigId, x, y, false)
        self:SetImp(imp)
        self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_HEAD_HUD, self._Id, self:GetIconFollow())
        self._OldConfigId = nil
    end
    self._IsPromotion = false
end

function XBlackRockChessPiece:SyncRemove()
    if self._IsPrepareRemove then
        self._Imp:Destroy()
        self._OwnControl:GetChessEnemy():RemovePieceInfo(self._Id)
    end
    self._IsPrepareRemove = false
end

function XBlackRockChessPiece:RestoreRemove()
    if self._Imp and self._IsPrepareRemove then
        self._Imp:Enable()
        self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_HEAD_HUD, self._Id, self:GetIconFollow())
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

function XBlackRockChessPiece:Restore()
    self:RestorePromotion()
    self:RestoreRemove()
    self:RestoreLocation()
    self._IsDizzy = false
    self._IsMoved = false
    self._IsPlayDead = false
end

function XBlackRockChessPiece:ForceDestroy()
    if not self._Imp then
        return
    end
    self._Imp:Destroy()
    self._Imp = nil
end

--endregion------------------Sync finish------------------

return XBlackRockChessPiece