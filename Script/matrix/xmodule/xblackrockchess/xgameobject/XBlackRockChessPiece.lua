
---@class XBlackRockChessPiece 棋子
---@field _MoveCd number 移动冷却回合
---@field _Id number 流水号Id
---@field _ConfigId number 配置Id
---@field _Life number 生命值
---@field _Imp XBlackRockChess.XPiece 棋子CS引用
---@field _Control XBlackRockChessControl 控制器
---@field _Buffs XBlackRockChess.XBuff[] buff列表
---@field _Animator UnityEngine.Animator
local XBlackRockChessPiece = XClass(nil, "XBlackRockChessPiece")

local CsVector2Int = CS.UnityEngine.Vector2Int
local PawnType = CS.XBlackRockChess.XChessPieceType.Pawn:GetHashCode()

function XBlackRockChessPiece:Ctor(id, configId, control)
    self._Id = id
    self._ConfigId = configId
    self._Control = control
    self._IsPrepareRemove = false
    self._IsDizzy = false
    self._IsPromotion = false
    self._Buffs = {}
end

function XBlackRockChessPiece:SetImp(imp)
    self._Imp = imp
    self:ApplyBuff()
    self:InitImp()
    
    self._Control:GetChessEnemy():ProcessPieceEffect()
end

function XBlackRockChessPiece:InitImp()
    self._Imp.Id = self._Id
    self._Imp.AttackedTimes = self._AttackedTimes
    self._Imp:RegisterSelect(handler(self, self.OnClick))
    self._Imp:RegisterPrepare4Attack(handler(self, self.Prepare4Attack))
    self._Imp.IsAttack = function() 
        return self:IsAttack()
    end
    self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_HEAD_HUD, self._Id, self:IconFollowTarget())
    if self:IsPreview() then
        self._Control:LoadVirtualEffect(self._Imp, self._ConfigId)
    end
    
    self._Animator = self._Imp.gameObject:GetComponent("Animator")
    if self._Animator then
        local resource = CS.XResourceManager.Load(self._Control:GetPieceController())
        if resource and resource.Asset then
            self._Animator.runtimeAnimatorController = resource.Asset
        end
        self._Resource = resource
    end
end

function XBlackRockChessPiece:ApplyBuff()
    local buffIds = self._Control:GetPieceBuffIds(self._ConfigId)
    local map = {}
    for _, buffId in ipairs(buffIds) do
        local buffType = self._Control:GetBuffType(buffId)
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
            local args = self._Control:GetBuffParams(buffId)
            table.insert(self._Buffs, buff)
            buff:Apply(buffId, self._Imp, table.unpack(args))
            buff:AddTakeEffectCb(handler(self, self.OnBuffTakeEffect))
        end
    end
    --self:DoProcessBuffEffect()
    self:DoProcessBuffEffectOnLoad()
end

function XBlackRockChessPiece:GetLocalInfo()
    return {
        Imp = self._Imp,
        ConfigId = self._ConfigId,
        IsVirtual = self._Control:GetChessGamer():IsExtraTurn()
    }
end

function XBlackRockChessPiece:Release()
    self._Imp = nil
    self._Control = nil
    self._IsPrepareRemove = false
    self._IsDizzy = false
    self._IsPromotion = false
    self._Buffs = {}
    if self._Resource then
        self._Resource:Release()
    end
    self._Resource = nil
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

    if self._Imp then
        self._Imp.AttackedTimes = data.AttackedTimes
    end
    
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

function XBlackRockChessPiece:GetPieceType()
    return self._Control:GetPieceType(self._ConfigId)
end

function XBlackRockChessPiece:GetBuffDesc(buffId)
    if not XTool.IsNumberValid(buffId) then
        return ""
    end
    local buffType = self._Control:GetBuffType(buffId)
    --只针对免疫次数Buff的显示额外处理
    if buffType ~= 2 then
        return self._Control:GetBuffDesc(buffId)
    end
    ---@type XBlackRockChess.XBuff
    local temp
    for _, buff in pairs(self._Buffs) do
        if buff.Id == buffId then
            temp = buff
            break
        end
    end
    local params = self._Control:GetBuffParams(buffId)
    local desc = self._Control:GetBuffDesc(buffId)
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
    return self._Imp:IsReachBottom() and XTool.IsNumberValid(self._Control:GetPromotionPieceId(self._ConfigId))
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
    if not self:IsAlive() then
        return false
    end
    if self:IsDizzy() then
        return false
    end
    return self._Imp:CheckAttack(point)
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

function XBlackRockChessPiece:MoveTo(point, onlyMove, finishCb)
    if not self._Imp then
        if finishCb then finishCb() end
        return
    end
    local movePoint = onlyMove and point or self._Imp:SearchByPoint(point)
    --self:PlayAnimation("ChessMoveUp")
    CS.XBlackRockChess.XBlackRockChessManager.Instance:MoveTo(self._Imp, movePoint.x, movePoint.y, finishCb)
    self._IsMoved = self._Imp:IsMoved() or not CS.XBlackRockChess.XBlackRockChessUtil.EqualVec2Int(self._Imp.MovePoint, movePoint)
end

--- 根据玩家坐标查询到可以移动的坐标, 由于修改了C#，所以逻辑放到Lua重写, 只提交分支即可
---@param point UnityEngine.Vector2Int
---@return UnityEngine.Vector2Int
--------------------------
function XBlackRockChessPiece:SearchByPoint(point)
    self._TargetPoint = point
    if not self._Imp then
        return CsVector2Int.zero
    end
    -- 小兵的逻辑沿用C#
    if self:GetPieceType() == PawnType then
        return self._Imp:SearchByPoint(point)
    end
    local movePoints = self._Imp:Search(self._Imp.Coordinate, true)
    if not movePoints or movePoints.Count <= 0 then
        return self._Imp.Coordinate;
    end
    -- 玩家站在棋子的攻击范围内
    for i = 0, movePoints.Count - 1 do
        local temp = movePoints[i];
        -- 可以攻击到玩家
        if CS.XBlackRockChess.XBlackRockChessUtil.EqualVec2Int(temp, point) then
            return temp;
        end
    end
    -- 将自身的移动方式应用到玩家的坐标
    local otherPoint = self._Imp:Search(point, true);
    -- 将重合的点存起来
    local intersection = {}
    for i = 0, movePoints.Count - 1 do
        local temp = movePoints[i];
        if otherPoint:Contains(temp) then
            table.insert(intersection, temp)
        end
    end
    
    local count = #intersection
    --没有交点
    if count == 0 then
        local p = movePoints[0]
        for i = 1, movePoints.Count - 1 do
            local temp = self:SortMultiPoint(p, movePoints[i])
            if temp > 0 then
                p = movePoints[i]
            end
        end
        return p
    elseif count == 1 then --一个交点
        return intersection[1]
    else --多个交集点
        local p = intersection[1]
        for i = 2, count do
            local temp = self:SortMultiPoint(p, intersection[i])
            if temp > 0 then
                p = intersection[i]
            end
        end
        return p
    end
end

function XBlackRockChessPiece:SortMultiPoint(a, b)
    local disA = math.abs(self._TargetPoint.x - a.x) + math.abs(self._TargetPoint.y - a.y);
    local disB = math.abs(self._TargetPoint.x - b.x) + math.abs(self._TargetPoint.y - b.y);

    if disA ~= disB then
        return self:CompareTo(disA, disB)
    end

    if a.y ~= b. y then
        return self:CompareTo(a.y, b. y)
    end
    
    return self:CompareTo(a.x, b.x)
end

function XBlackRockChessPiece:CompareTo(a, b)
    if a > b then
        return 1
    elseif a == b then
        return 0
    else
        return -1
    end
end

function XBlackRockChessPiece:GetActionList(isRevive)
    local list = {}
    if not self._Imp then
        return list
    end

    if self:IsMoved() then
        table.insert(list, {
            ObjId = self._Id,
            ActionType = XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE,
            Params = {
                self._Imp.MovePoint.x,
                self._Imp.MovePoint.y,
                0
            }
        })
    end
    if self._IsPromotion and not isRevive then
        table.insert(list, {
            ObjId = self._Id,
            ActionType = XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.PROMOTION,
            Params = {
                self._ConfigId
            }
        })
    end

    if self:IsPreview() and self._MoveCd == 0 and XTool.IsNumberValid(self._ReinforceId) and self._Imp and not isRevive then
        local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:Virtual2Piece(self._Imp)
        table.insert(list, {
            ObjId = self._Id,
            ActionType = XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_TRIGGER,
            Params = {
                self._ReinforceId,
                self._Imp.MovePoint.x,
                self._Imp.MovePoint.y,
            }
        })
        if imp then
            self:Reinforce(imp)
        else
            self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.HIDE_HEAD_HUD, self._Id)
            self._Imp:Destroy()
            self._Control:GetChessEnemy():RemovePieceInfo(self._Id)
            self._Control:GetChessEnemy():DelReinforceImp(self._Id)
        end
        
    end
    
    return list
end

function XBlackRockChessPiece:OnClick(isPreview)
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_ENEMY, self._Id, isPreview)
end

function XBlackRockChessPiece:Prepare4Attack()
    self:LoadEffect(self._Control:GetWarningEffectId(self:GetPieceType()))
end

function XBlackRockChessPiece:CancelPrepareAttack()
    self:HideEffect(self._Control:GetWarningEffectId(self:GetPieceType()))
end

function XBlackRockChessPiece:IsAttack()
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

--- 被攻击
---@param damage number 伤害
---@param isDizzy boolean 是否眩晕
---@return boolean 是否造成伤害
--------------------------
function XBlackRockChessPiece:AttackEd(damage, isDizzy, skillId, isFront)
    if not self:IsPiece() then
        return false
    end
    self._IsDizzy = isDizzy
    local isInvincible = false
        for _, buff in pairs(self._Buffs) do
        if buff:IsEffectiveByAttacked() then
            buff:TakeEffect()
            if buff:IsImmuneInjury() then
                isInvincible = true
            end
        end
    end
    if self._Imp then
        self._Imp.AttackedTimes = self._Imp.AttackedTimes + 1
    end
    --无敌
    if isInvincible then
        self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_HEAD_HUD, self._Id, self:IconFollowTarget())
        return true
    end
    damage = math.max(0, damage)
    self._Life = math.max(0, self._Life - damage)
    if self._Life <= 0 then
        self._Control:AddKillCount(self:GetPieceType())
        return true
    end
    self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_HEAD_HUD, self._Id, self:IconFollowTarget())

    return true
end

--是否无敌
function XBlackRockChessPiece:IsInvincible()
    local isInvincible = false
    for _, buff in pairs(self._Buffs) do
        if buff:IsEffectiveByAttacked() and buff:IsImmuneInjury() then
            isInvincible = true
            break
        end
    end
    
    return isInvincible
end

function XBlackRockChessPiece:LookAt(position)
    if not self._Imp then
        return
    end
    self._Imp:TurnAround(position)
end

function XBlackRockChessPiece:IconFollowTarget()
    if not self._Imp then
        return
    end
    return self._Imp.transform 
end

function XBlackRockChessPiece:DoDead()
    --标记等待
    self._Control:ConfirmWaiting()
    --倒地动画
    self:PlayAnimation("ChessFall")
    --播放音效
    self._Control:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.PIECE_BREAK)
    local playDelay = self._Control:GetDeadEffectDelay(1)
    --延时加载死亡特效
    self:LoadEffect(self._Control:GetDeadEffectId(), nil, nil, playDelay)
    local hideDelay = self._Control:GetDeadEffectDelay(2)
    --等待特效播放完毕摧毁棋子
    XScheduleManager.ScheduleOnce(function()
        --取消标记
        if self._Control then
            self._Control:CancelWaiting()
        end
        if not self._Imp then
            return
        end
        self._Imp:Disable()
        self._IsPrepareRemove = true
        for _, buff in pairs(self._Buffs) do
            if buff:IsEffectiveByDead() then
                buff:TakeEffect()
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_ENEMY, self._Id, false)
        self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.HIDE_HEAD_HUD, self._Id)
        self._Control:GetChessEnemy():ProcessPieceEffect()
    end, hideDelay)
    
end

function XBlackRockChessPiece:Promotion()
    local pieceId = self._Control:GetPromotionPieceId(self._ConfigId)
    local x, y = self._Imp.MovePoint.x, self._Imp.MovePoint.y
    --移除旧棋子
    self._Imp:Disable()
    self._Imp:Destroy()
    --添加新棋子
    local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddPiece(pieceId, x, y, false)
    self._OldConfigId = self._ConfigId
    self._ConfigId = pieceId
    self._IsPromotion = true
    self:SetImp(imp)
    
    self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_HEAD_HUD, self._Id, self:IconFollowTarget())
end

function XBlackRockChessPiece:Reinforce(imp)
    self:SetImp(imp)
    self._Control:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.REINFORCE_COMING)
end

function XBlackRockChessPiece:RestoreReinforce()
    if not self._Imp then
        return
    end
    CS.XBlackRockChess.XBlackRockChessManager.Instance:RestoreVirtualPiece(self._Imp)
    self._Imp:Disable()
end

function XBlackRockChessPiece:Summon(imp, isVirtual)
    if isVirtual then
        self._Control:HideVirtualEffect(imp, imp.ConfigId)
        local temp = CS.XBlackRockChess.XBlackRockChessManager.Instance:Virtual2Piece(imp)
        if temp then
            self:SetImp(temp)
        else
            self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.HIDE_HEAD_HUD, self._Id)
            imp:Destroy()
            self._Control:GetChessEnemy():RemovePieceInfo(self._Id)
        end
    else
        self:SetImp(imp)
    end
    
    self._Control:GetChessEnemy():ProcessPieceEffect()
end

function XBlackRockChessPiece:TransformPiece(imp, configId)
    self._ConfigId = configId
    --提前更新数据
    self._MoveCd = self._Control:GetPieceInitCd(self._ConfigId)
    self._Life = self._Control:GetPieceMaxLife(self._ConfigId)
    --避免当前回合移动了，下回合更新后正常
    self._MemberType = XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.REINFORCE_PREVIEW
    self:SetImp(imp)

    self._Control:GetChessEnemy():ProcessPieceEffect()
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
    local actionType = args[1]

    if actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON then
        self._Control:GetChessEnemy():Summon(self._Id, buffId, args[2], args[3] or self._Control:GetChessGamer():IsExtraTurn())
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM then
        self._Control:GetChessEnemy():TransformPiece(self._Id, args[2], args[3])
    end
end

function XBlackRockChessPiece:LoadEffect(effectId, offset, rotate, delay)
    self._Control:LoadEffect(self._Imp, effectId, offset, rotate, delay)
end

function XBlackRockChessPiece:HideEffect(effectId)
    if not self._Imp then
        return
    end
    self._Imp:HideEffect(self._Control:GetEffectUrl(effectId))
end

function XBlackRockChessPiece:PlayHit(effectId, hitPos)
    local hitEffectId = self._Control:GetHitEffectId(self:GetPieceType())
    self:LoadEffect(hitEffectId)
    if self._IsDizzy then
        self:LoadEffect(self._Control:GetDizzyEffectId())
    end
    if XTool.IsNumberValid(effectId) then
        local curPos = self._Imp.MovePoint
        local rotate = CS.XBlackRockChess.XBlackRockChessUtil.CalCoordinateRotate(hitPos, curPos)
        rotate.y = rotate.y - self._Imp.transform.localEulerAngles.y - 180
        self:LoadEffect(effectId, nil, rotate)
    end
    --更新特效显示
    self:DoProcessBuffEffect()

    if not self:IsAlive() then
        self:DoDead()
    end
end

-- 回合开始时，需要隐藏的特效
function XBlackRockChessPiece:DoHideEffectOnRoundBegin()
    -- 眩晕
    self:HideEffect(self._Control:GetDizzyEffectId())
end

function XBlackRockChessPiece:DoHideEffectOnRoundEnd()
    
end

-- 回合开始，处理Buff特效
function XBlackRockChessPiece:DoProcessBuffEffect()
    if not self._Imp then
        return
    end
    for _, buff in pairs(self._Buffs) do
        if not buff then
            goto continue
        end
        local isImmuneInjury = buff:IsImmuneInjury()
        local effectId = self._Control:GetBuffEffectId(buff.Id)
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
    for _, buff in pairs(self._Buffs) do
        if not buff then
            goto continue
        end
        local effectId = self._Control:GetBuffEffectId(buff.Id)
        local buffType = self._Control:GetBuffType(buff.Id)
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
        self._Control:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.PIECE_BUFF)
    end
end

--数据更新时
function XBlackRockChessPiece:DoProcessEffectOnDataUpdate()
    if not self._Imp then
        return
    end
    -- 虚影
    if not self:IsPreview() then
        self._Control:HideVirtualEffect(self._Imp, self._ConfigId)
    end
end

function XBlackRockChessPiece:PlayAnimation(animName)
    if not self._Imp or not self:IsPiece() or not self._Animator then
        return
    end
    self._Animator:Play(animName, 0)
end

--region   ------------------Sync start-------------------

function XBlackRockChessPiece:SyncLocation()
    if not self._Imp then
        return
    end
    self._Imp:SyncLocation()
end

function XBlackRockChessPiece:RestoreLocation()
    if not self._Imp then
        return
    end
    self._Imp:RestoreLocation()
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
        local x, y = self._Imp.MovePoint.x, self._Imp.MovePoint.y
        self._Imp:Disable()
        self._Imp:Destroy()
        --还原旧棋子
        local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddPiece(self._ConfigId, x, y, false)
        self:SetImp(imp)
        self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_HEAD_HUD, self._Id, self:IconFollowTarget())
        self._OldConfigId = nil
    end
    self._IsPromotion = false
end

function XBlackRockChessPiece:SyncRemove()
    if self._IsPrepareRemove then
        self._Control:RemovePiece(self._Id)
        self._Imp:Destroy()
    end
    self._IsPrepareRemove = false
end

function XBlackRockChessPiece:RestoreRemove()
    if self._Imp and self._IsPrepareRemove then
        self._Imp:RestoreHide()
        self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_HEAD_HUD, self._Id, self:IconFollowTarget())
    end
    self._IsPrepareRemove = false
    
end

function XBlackRockChessPiece:RestoreTr()

end

function XBlackRockChessPiece:Sync()
    self:SyncLocation()
    self:SyncRemove()
    self:SyncPromotion()
    self._IsDizzy = false
    self._IsMoved = false
end

function XBlackRockChessPiece:Restore()
    self:RestorePromotion()
    self:RestoreRemove()
    self:RestoreLocation()
    self._IsDizzy = false
    self._IsMoved = false
end

--endregion------------------Sync finish------------------

return XBlackRockChessPiece