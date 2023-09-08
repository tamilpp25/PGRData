
---@class XBlackRockChessEnemy 敌人
---@field _Control XBlackRockChessControl
---@field _Imp XBlackRockChess.XChessEnemy
---@field _PieceInfoDict table<number, XBlackRockChessPiece>
local XBlackRockChessEnemy = XClass(nil, "XBlackRockChessEnemy")

--棋子类型
local ChessPieceType = {
    --士兵
    Pawn    = 1,
    --骑士
    Knight  = 2,
    --主教
    Bishop  = 3,
    --城堡
    Rook    = 4,
    --女王
    Queen   = 5,
    --国王
    King    = 6,
}

--战斗力排序
local SortPieceTypeByPower = {
    [ChessPieceType.Queen]  = 1,
    [ChessPieceType.Rook]   = 2,
    [ChessPieceType.Bishop] = 3,
    [ChessPieceType.Knight] = 4,
    [ChessPieceType.Pawn]   = 5,
    [ChessPieceType.King]   = 6,
}

--Action排行
local SortPieceTypeByActionType = {
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE] = 1,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.PROMOTION] = 2,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_PREVIEW] = 3,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_TRIGGER] = 4,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM] = 5,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON] = 6,
}

local AsyncMove = asynTask(function(pieceInfo, point, onlyMove, cb)
    if not pieceInfo then
        if cb then cb() end
        return
    end
    pieceInfo:MoveTo(point, onlyMove, cb)
end)

function XBlackRockChessEnemy:Ctor(id, control)
    self._PieceInfoDict = {}
    self._SummonDict = {}
    self._TransformDict = {}
    self._ActionList = {}
    self._ReinforceDict = {}
    self._Id = id
    self._Control = control
    self._AsyncOnRoundBeginCb = handler(self, self.AsyncOnRoundBegin)
    self._OnSortMoveAndAttack = handler(self, self.OnSortMoveAndAttack)
    local interval, _ = self._Control:GetPieceMoveConfig()
    self._MoveInterval = interval
end

function XBlackRockChessEnemy:SetImp(imp)
    --避免重复设置
    if self._Imp then
        return
    end
    self._Imp = imp
end

function XBlackRockChessEnemy:GetPieceInfoDict()
    return self._PieceInfoDict
end

---@param pieceInfo XBlackRockChessPiece
function XBlackRockChessEnemy:AddPieceInfo(id, pieceInfo)
    self._PieceInfoDict[id] = pieceInfo
    if self._SummonDict[id] then
        local imp, virtual = self._SummonDict[id].Imp, self._SummonDict[id].IsVirtual
        pieceInfo:Summon(imp, virtual)
        self._SummonDict[id] = nil
        return
    end

    if self._ReinforceDict[id] then
        pieceInfo:Reinforce(self._ReinforceDict[id])
        self:DelReinforceImp(id)
    end
end

function XBlackRockChessEnemy:RemovePieceInfo(id)
    self._PieceInfoDict[id] = nil
end

---@return XBlackRockChessPiece
function XBlackRockChessEnemy:GetPieceInfo(id)
    return self._PieceInfoDict[id]
end

function XBlackRockChessEnemy:GetPieceHpProgress(id)
    local piece = self:GetPieceInfo(id)
    if not piece then
        return 0
    end
 
    return piece:GetHp() / self._Control:GetPieceMaxLife(piece:GetConfigId())
end

function XBlackRockChessEnemy:GetPieceMoveCd(id)
    local piece = self:GetPieceInfo(id)
    if not piece then
        return 0
    end
    return piece:GetMoveCd()
end

--- 获取可移动的棋子
---@return XBlackRockChessPiece[]
--------------------------
function XBlackRockChessEnemy:GetCanMovePieceList()
    local list = {}
    for _, info in pairs(self._PieceInfoDict) do
        --棋子已经死亡 | 刚增援
        if not info:IsAlive() or not info:IsPiece() then
            goto continue
        end

        --当前回合不能移动
        if not info:IsCanMove() then
            goto continue
        end

        --被眩晕
        if info:IsDizzy() then
            goto continue
        end
        
        table.insert(list, info)
        ::continue::
    end

    table.sort(list, self._OnSortMoveAndAttack)
    return list
end

--- 可攻击棋子
---@return XBlackRockChessPiece[]
--------------------------
function XBlackRockChessEnemy:GetAttackPieceList()
    local list = {}
    for _, info in pairs(self._PieceInfoDict) do
        if info:IsAttack() then
            table.insert(list, info)
        end
    end
   
    table.sort(list, self._OnSortMoveAndAttack)
    return list
end

function XBlackRockChessEnemy:OnSortMoveAndAttack(pieceA, pieceB)
    local typeA = self._Control:GetPieceType(pieceA:GetConfigId())
    local typeB = self._Control:GetPieceType(pieceB:GetConfigId())

    if typeA ~= typeB then
        return SortPieceTypeByPower[typeA] < SortPieceTypeByPower[typeB]
    end

    local xA, yA = pieceA:GetPos()
    local xB, yB = pieceB:GetPos()

    --Y轴坐标从小到大，优先选择小的（最靠近“下”），目前左下角为原点
    if yA ~= yB then
        return yA < yB
    end

    --X轴坐标从小到大，优先选择小的（最靠近“左”）
    if xA ~= xB then
        return xA < xB
    end

    return pieceA:GetId() > pieceB:GetId()
end

function XBlackRockChessEnemy:AsyncOnRoundBegin()
    -- 1. 获取玩家位置
    local playerPoint = self._Control:GetPlayerMovePoint()
    -- 2. 遍历是否有棋子可以攻击玩家
    local attack = false
    local attackList = self:GetAttackPieceList()
    for _, info in pairs(attackList) do
        if info:CheckAttack(playerPoint) then
            AsyncMove(info, playerPoint, true)
            self._Control:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.PIECE_MOVED)
            attack = true
            break
        end
    end
    if attack then
        local asyncPlay = asynTask(function(animName, cb) 
            self._Control:PlayGamerAnimation(animName, cb)
        end)
        self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.REFRESH_CHECK_MATE, true)
        asyncPlay("BRSFall")
        -- 标记复活
        self._Control:GetChessGamer():SetRevive()
        asyncPlay("BRSJumpDown")
        self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.REFRESH_CHECK_MATE, false)
        -- 回合结束
        self:OnRoundEnd()
        return
    end
    -- 3. 获取可以移动的棋子
    local moveList = self:GetCanMovePieceList()
    for _, pieceInfo in pairs(moveList) do
        --AsyncMove(pieceInfo, playerPoint, false)
        pieceInfo:MoveTo(playerPoint, false)
    end
    if not XTool.IsTableEmpty(moveList) then
        asynWaitSecond(self._MoveInterval)

        self._Control:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.PIECE_MOVED)
    end
    -- 4. 触发升变
    for _, pieceInfo in pairs(attackList) do
        if pieceInfo:IsPromotion() then
            pieceInfo:Promotion()
        end
    end
    -- 5. 增援倒计时
    -- 6. 增援触发
    self._Control:UpdateReinforce()
    -- 7. 回合结束
    self:OnRoundEnd()
end

function XBlackRockChessEnemy:OnRoundBegin()
    if not self._Imp then
        return
    end
    --self._Control:BroadcastRound(false, false)
    self._Imp:OnRoundBegin()
    self:ProcessPieceEffectOnBegin()
    RunAsyn(self._AsyncOnRoundBeginCb)
end

function XBlackRockChessEnemy:OnRoundEnd()
    if not self._Imp then
        return
    end
    self._Imp:OnRoundEnd()
    self:ProcessPieceEffectOnEnd()
    --发送同步回合协议
    self._Control:RequestSyncRound()
end

function XBlackRockChessEnemy:ProcessPieceEffectOnBegin()
    for _, piece in pairs(self._PieceInfoDict) do
        piece:DoHideEffectOnRoundBegin()
        piece:DoProcessBuffEffect()
    end
end

function XBlackRockChessEnemy:ProcessPieceEffectOnEnd()
    for _, piece in pairs(self._PieceInfoDict) do
        piece:DoHideEffectOnRoundEnd()
        piece:CancelPrepareAttack()
    end
end

function XBlackRockChessEnemy:ProcessPieceEffect()
    for _, piece in pairs(self._PieceInfoDict) do
        piece:DoProcessBuffEffect()
    end
end

function XBlackRockChessEnemy:HideWarningEffect()
    for _, piece in pairs(self._PieceInfoDict) do
        piece:CancelPrepareAttack()
    end
end

function XBlackRockChessEnemy:Sync()
    for _, info in pairs(self._PieceInfoDict) do
        info:Sync()
    end
    self._ActionList = {}
end

function XBlackRockChessEnemy:Restore()
    self:RestoreBuff()
    for _, info in pairs(self._PieceInfoDict) do
        info:Restore()
    end
    self._ActionList = {}
end

function XBlackRockChessEnemy:RestoreBuff()
    for _, action in pairs(self._ActionList) do
        if action.ActionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON then
            local insId = action.Params[2] or 0
            local impData = self._SummonDict[insId]
            if impData then
                CS.XBlackRockChess.XBlackRockChessManager.Instance:RestoreSummon(impData.Imp)
                if impData.IsVirtual then
                    CS.XBlackRockChess.XBlackRockChessManager.Instance:RestoreVirtualShadow(impData.Imp)
                end
            end
            self._SummonDict[insId] = nil
        elseif action.ActionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM then
            local insId = action.Params[1]
            local localInfo = self._TransformDict[insId]
            local info = self:GetPieceInfo(insId)
            if info then
                info:RestoreTransform(localInfo.Imp, localInfo.ConfigId, localInfo.IsVirtual)
            end
            self._TransformDict[insId] = nil
        end
    end
end

function XBlackRockChessEnemy:GetValidActionList()
    local list = {}
    for _, action in pairs(self._ActionList) do
        if action.ActionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON then
            local insId = action.Params[2]
            local impData = self._SummonDict[insId]
            --虚影时判断该位置是否有棋子
            if impData and impData.IsVirtual then
                local point = impData.Imp.Coordinate
                --存在棋子，移除虚影召唤
                if CS.XBlackRockChess.XBlackRockChessManager.Instance:PieceAtCoord(point) then
                    CS.XBlackRockChess.XBlackRockChessManager.Instance:RestoreVirtualShadow(impData.Imp)
                    --因为这里还未生成实体，如果从棋盘上移除，会移除棋子的位置
                    impData.Imp:Destroy()
                    self._SummonDict[insId] = nil
                else
                    table.insert(list, action)
                end
            elseif impData then
                table.insert(list, action)
            end
        elseif action == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM then
            local insId = action.Params[1]
            local localInfo = self._TransformDict[insId]
            local info = self:GetPieceInfo(insId)
            if localInfo and info then
                --虚影时判断该位置是否有棋子
                if localInfo.IsVirtual then
                    local point = localInfo.Imp.Coordinate
                    --存在棋子，移除虚影召唤
                    if CS.XBlackRockChess.XBlackRockChessManager.Instance:PieceAtCoord(point) then
                        info:RestoreTransform(localInfo.Imp, localInfo.ConfigId, localInfo.IsVirtual)
                        self._TransformDict[insId] = nil
                    else
                        table.insert(list, action)
                    end
                else
                    table.insert(list, action)
                end
            end
        else
            table.insert(list, action)
        end
        
    end
    
    return list
end

function XBlackRockChessEnemy:GetActionList()
    local list = {}
    local isRevive = self._Control:GetChessGamer():IsRevive()
    for _, info in pairs(self._PieceInfoDict) do
        list = XTool.MergeArray(list, info:GetActionList(isRevive))
    end
    --玩家死亡后，直接移除召唤 + 转换的虚影
    if isRevive then
        self:RestoreBuff()
    else
        list = XTool.MergeArray(list, self:GetValidActionList())
        list = XTool.MergeArray(list, self._Control:GetReinforceActionList())
    end
   
    table.sort(list, function(a, b) 
        local typeA = a.ActionType
        local typeB = b.ActionType
        if typeA ~= typeB then
            return SortPieceTypeByActionType[typeA] < SortPieceTypeByActionType[typeB]
        end

        
        local pieceA = self:GetPieceInfo(a.ObjId)
        local pieceB = self:GetPieceInfo(b.ObjId)

        if not pieceA and pieceB then
            return false
        end

        if not pieceB and pieceA then
            return true
        end

        if not pieceA and not pieceB then
            return false
        end
        
        return self:OnSortMoveAndAttack(pieceA, pieceB)
    end)
    
    return list
end

--- 棋子召唤
---@param pieceId number 挂载buff的棋子id
---@param impList XBlackRockChess.XPiece[]
---@return
--------------------------
function XBlackRockChessEnemy:Summon(pieceId, buffId, impList, isVirtual)
    for i = 0, impList.Count - 1 do
        local imp = impList[i]
        if imp then
            if isVirtual then
                self._Control:LoadVirtualEffect(imp, imp.ConfigId)
            end
            local insId = self._Control:GetIncId()
            self._SummonDict[insId] = {
                Imp = imp,
                IsVirtual = isVirtual,
            }

            table.insert(self._ActionList, {
                ObjId = pieceId,
                ActionType = XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON,
                Params = { imp.ConfigId, insId, imp.Coordinate.x, imp.Coordinate.y, buffId }
            })
        end
    end
end

--- 棋子转换
---@param pieceId number 挂载buff的棋子id
---@param imp XBlackRockChess.XPiece
--------------------------
function XBlackRockChessEnemy:TransformPiece(pieceId, imp, originObjId)
    if XTool.UObjIsNil(imp) then
        return
    end
    local pieceInfo = self:GetPieceInfo(originObjId)
    if not pieceInfo or pieceInfo:IsPreview() or not pieceInfo:IsAlive() then
        imp:Disable()
        imp:Destroy()
        return
    end
    self._TransformDict[originObjId] = pieceInfo:GetLocalInfo()
    pieceInfo:TransformPiece(imp, imp.ConfigId)
    table.insert(self._ActionList, {
        ObjId = pieceId,
        ActionType = XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM,
        Params = { originObjId, imp.ConfigId }
    })
end

function XBlackRockChessEnemy:UpdateTransformPiece(id)
    if not self._TransformDict[id] then
        return
    end
    local info = self._TransformDict[id]
    local currentInfo = self:GetPieceInfo(id)
    if info.IsVirtual and currentInfo then
        local imp = currentInfo:GetLocalInfo().Imp
        local tmp = CS.XBlackRockChess.XBlackRockChessManager.Instance:Virtual2Piece(imp)
        if not tmp then
            self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.HIDE_HEAD_HUD, id)
            info.Imp:Destroy()
            self:RemovePieceInfo(id)
        else
            self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_HEAD_HUD, id, currentInfo:IconFollowTarget())
        end
    end
    self._TransformDict[id] = nil
end

function XBlackRockChessEnemy:AddReinforceImp(pieceId, imp)
    self._ReinforceDict[pieceId] = imp
end

function XBlackRockChessEnemy:DelReinforceImp(pieceId)
    self._ReinforceDict[pieceId] = nil
end

function XBlackRockChessEnemy:Release()
    self._Imp = nil
    for _, info in pairs(self._PieceInfoDict) do
        info:Release()
    end
    self._PieceInfoDict = {}
    self._SummonDict = {}
    self._TransformDict = {}
    self._ActionList = {}
    self._ReinforceDict = {}
end

return XBlackRockChessEnemy