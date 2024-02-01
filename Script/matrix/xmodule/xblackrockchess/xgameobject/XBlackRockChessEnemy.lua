
---@class XBlackRockChessEnemy : XEntityControl 敌人
---@field _MainControl XBlackRockChessControl
---@field _Imp XBlackRockChess.XChessEnemy
---@field _PieceInfoDict table<number, XBlackRockChessPiece>
---@field _FailReinforceList table<number, XBlackRockChessPiece[]>
local XBlackRockChessEnemy = XClass(XEntityControl, "XBlackRockChessEnemy")
local XBlackRockChessPiece = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessPiece")

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

function XBlackRockChessEnemy:OnInit()
    self._PieceInfoDict = {}
    self._SummonDict = {}
    self._TransformDict = {}
    self._ActionList = {}
    self._ReinforceDict = {}
    self._FailReinforceList = {}

    self._AsyncOnRoundBeginCb = handler(self, self.AsyncOnRoundBegin)
    self._OnSortMoveAndAttack = handler(self, self.OnSortMoveAndAttack)
    local interval, _ = self._MainControl:GetPieceMoveConfig()
    self._MoveInterval = interval
end

function XBlackRockChessEnemy:DoEnterFight()
    local pieceDict = self:GetPieceInfoDict()
    local prepareRemove = {}
    for _, piece in pairs(pieceDict) do
        local x, y = piece:GetPos()
        local templateId = piece:GetConfigId()
        local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddPiece(templateId, x, y, not piece:IsPiece())
        if imp then
            piece:SetImp(imp, true)
        else
            prepareRemove[piece:GetId()] = true
        end
    end

    for id, _ in pairs(prepareRemove) do
        self:RemovePieceInfo(id)
    end
end

function XBlackRockChessEnemy:SetImp(imp)
    --避免重复设置
    if self._Imp then
        return
    end
    self._Imp = imp
end

function XBlackRockChessEnemy:UpdateFormation(exists)
    if XTool.IsTableEmpty(exists) then
        return
    end
    local removeId = {}
    for _, info in pairs(self._PieceInfoDict) do
        if not exists[info:GetId()] then
            table.insert(removeId, info:GetId())
        end
    end

    if not XTool.IsTableEmpty(removeId) then
        for _, id in ipairs(removeId) do
            self:RemovePieceInfo(id)
        end
    end
end

function XBlackRockChessEnemy:UpdateData(formation, exists)
    local pieceInfo = formation.PieceInfo or {}
    local id = pieceInfo.Guid
    exists[id] = true
    local info = self:GetPieceInfo(id)
    if not info then
        info = self:AddEntity(XBlackRockChessPiece, id, pieceInfo.PieceId)
        self:AddPieceInfo(id, info)
    end
    info:UpdateData(formation.X, formation.Y, formation.Type, pieceInfo)
    self:UpdateTransformPiece(id)
    
    local curRound = self._MainControl:GetChessRound()
    for round, list in pairs(self._FailReinforceList) do
        if curRound - round >= 2 then
            for _, info in pairs(list) do
                local id = info:GetId()
                self:RemovePieceInfo(id)
            end
        end
    end
end

function XBlackRockChessEnemy:RetractData(formation, disableDict, removeDict, allPieceDict)
    local pieceInfo = formation.PieceInfo or {}
    local id = pieceInfo.Guid
    local info = self:GetPieceInfo(id)
    --上个回合击杀了
    if info then
        --已经死亡但未同步
        local isDead = (not info:IsAlive())
        if isDead then
            disableDict[id] = true
        end
        info:UpdateData(formation.X, formation.Y, formation.Type, pieceInfo)
        self:UpdateTransformPiece(id)
        if not isDead then
            info:Sync()
        end
    else
        removeDict[id] = formation
    end
    allPieceDict[id] = true
end

function XBlackRockChessEnemy:Retract(disableDict, removeDict, allPieceDict)
    if not XTool.IsTableEmpty(allPieceDict) then
        local remove = {}
        for id, info in pairs(self._PieceInfoDict) do
            if not allPieceDict[id] then
                remove[id] = id
                info:ForceDestroy()
            end
            --不是棋子，则变回虚影
            if not info:IsPiece() and not remove[id] then
                info:DoReinforcePreviewRetract()
            end
        end
        for id, info in pairs(remove) do
            self:RemovePieceInfo(id)
        end
    end
    --将隐藏的棋子重新显示
    for id, _ in pairs(disableDict) do
        local info = self:GetPieceInfo(id)
        info:Restore()
    end
    --将移除的棋子重新加载
    for id, formation in pairs(removeDict) do
        local pieceInfo = formation.PieceInfo or {}
        local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddPiece(pieceInfo.PieceId,
                formation.X, formation.Y, formation.Type ~= XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PIECE)
        if imp then
            local info = self:AddEntity(XBlackRockChessPiece, id, pieceInfo.PieceId)
            self:AddPieceInfo(id, info)

            info:UpdateData(formation.X, formation.Y, formation.Type, pieceInfo)
            info:SetImp(imp)
        end
    end
    self:RestoreBuff()
    local curRound = self._MainControl:GetChessRound() + 1
    local failList = self._FailReinforceList[curRound]
    if not XTool.IsTableEmpty(failList) then
        for _, info in pairs(failList) do
            info:DoReinforcePreviewRetract(true)
        end
        self._FailReinforceList[curRound] = nil
    end
end

---@param cls any 实体的Class
---@return XBlackRockChessPiece
function XBlackRockChessEnemy:AddEntity(cls, ...)
    ---@type XEntity
    local entity = cls.New(self._MainControl)
    local uid = entity:GetUid()

    local minUid = self._TypesMinUid[cls]
    if not minUid or minUid > uid then --记录一个最小id
        self._TypesMinUid[cls] = uid
    end

    self._EntitiesDict[uid] = entity

    local typesDict = self._EntitiesTypesDict[cls]
    if not typesDict then
        typesDict = {}
        self._EntitiesTypesDict[cls] = typesDict
    end

    typesDict[uid] = entity
    entity:__Init(...)
    return entity
end

function XBlackRockChessEnemy:GetPieceInfoDict()
    return self._PieceInfoDict
end

function XBlackRockChessEnemy:IsAllPieceDead()
    local allDead = true
    if XTool.IsTableEmpty(self._PieceInfoDict) then
        return allDead
    end
    for _, info in pairs(self._PieceInfoDict) do
        if info:IsAlive() then
            allDead = false
            break
        end
    end
    return allDead
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
        pieceInfo:DoReinforcePreview(self._ReinforceDict[id])
        self:RemoveReinforce(id)
    end
end

function XBlackRockChessEnemy:RemovePieceInfo(id)
    local info = self._PieceInfoDict[id]
    if info then
        self:RemoveEntity(info)
    end
    self._PieceInfoDict[id] = nil
end

---@return XBlackRockChessPiece
function XBlackRockChessEnemy:GetPieceInfo(id)
    return self._PieceInfoDict[id]
end

function XBlackRockChessEnemy:GetPieceInfoByPoint(point)
    for _, info in pairs(self._PieceInfoDict) do
        if CS.XBlackRockChess.XBlackRockChessUtil.EqualVec2Int(info:GetMovedPoint(), point) then
            return info
        end
    end
    return nil
end

function XBlackRockChessEnemy:GetPieceListByConfigId(configId)
    local list = {}
    for _, info in pairs(self._PieceInfoDict) do
        if info:GetConfigId() == configId then
            table.insert(list, info)
        end
    end
    return list
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
        if info:IsAttackAble() then
            table.insert(list, info)
        end
    end
   
    table.sort(list, self._OnSortMoveAndAttack)
    return list
end

function XBlackRockChessEnemy:OnSortMoveAndAttack(pieceA, pieceB)
    local typeA = self._MainControl:GetPieceType(pieceA:GetConfigId())
    local typeB = self._MainControl:GetPieceType(pieceB:GetConfigId())

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
    local actor = self._MainControl:GetChessGamer():GetRole(self._MainControl:GetMasterRoleId())
    local playerPoint = actor:GetMovedPoint()
    -- 2. 遍历是否有棋子可以攻击玩家
    local attack = nil
    local attackList = self:GetAttackPieceList()
    for _, info in pairs(attackList) do
        if info:CheckAttack(playerPoint) then
            attack = info
            break
        end
    end
    if attack then
        actor:AsyncAttacked(attack, AsyncMove)
        -- 等待表演结束
        self._MainControl:SyncWait()
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
    end
    -- 4. 触发升变
    for _, pieceInfo in pairs(attackList) do
        if pieceInfo:IsPromotion() then
            pieceInfo:Promotion()
        end
    end
    -- 5. 增援倒计时
    -- 6. 增援触发
    self._MainControl:UpdateReinforce()
    -- 7. 等待表演结束
    self._MainControl:SyncWait()
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
    self._MainControl:RequestSyncRound()
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
                local point = impData.Imp.CurrentPoint
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
                    local point = localInfo.Imp.CurrentPoint
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
    local isRevive = self._MainControl:GetChessGamer():IsRevive()
    local isTriggerProtect = self._MainControl:GetChessGamer():IsTriggerProtect()
    
    local isRestore = isRevive or isTriggerProtect
    for _, info in pairs(self._PieceInfoDict) do
        local iList = info:GetActionList(isRestore)
        list = XTool.MergeArray(list, iList)
    end
    --玩家死亡后，直接移除召唤 + 转换的虚影
    if isRestore then
        self:RestoreBuff()
    else
        list = XTool.MergeArray(list, self:GetValidActionList())
        list = XTool.MergeArray(list, self._MainControl:GetReinforceActionList())
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
function XBlackRockChessEnemy:Summon(pieceId, buffId, impList, isVirtual, effectCount, hitActorId, hitRoundCount)
    for i = 0, impList.Count - 1 do
        local imp = impList[i]
        if imp then
            if isVirtual then
                self._MainControl:LoadVirtualEffect(imp, imp.ConfigId)
            end
            local insId = self._MainControl:GetIncId()
            self._SummonDict[insId] = {
                Imp = imp,
                IsVirtual = isVirtual,
            }
            
            table.insert(self._ActionList, self:CreateAction(pieceId, XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON, 
                    imp.ConfigId, insId, imp.CurrentPoint.x, imp.CurrentPoint.y, buffId, effectCount, hitActorId, hitRoundCount))
        end
    end
end

--- 棋子转换
---@param pieceId number 挂载buff的棋子id
---@param imp XBlackRockChess.XPiece
--------------------------
function XBlackRockChessEnemy:TransformPiece(pieceId, imp, originObjId, hitActorId, hitRoundCount)
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
    
    table.insert(self._ActionList, self:CreateAction(pieceId, XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM, 
            originObjId, imp.ConfigId, hitActorId, hitRoundCount))
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
            self._MainControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.HIDE_HEAD_HUD, id)
            info.Imp:Destroy()
            self:RemovePieceInfo(id)
        else
            self._MainControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_HEAD_HUD, id, currentInfo:GetIconFollow())
        end
    end
    self._TransformDict[id] = nil
end

function XBlackRockChessEnemy:AddReinforceImp(pieceId, info)
    self._ReinforceDict[pieceId] = info
end

function XBlackRockChessEnemy:RemoveReinforce(pieceId)
    self._ReinforceDict[pieceId] = nil
end

---@return XBlackRockChess.XPiece
function XBlackRockChessEnemy:GetReinforceImp(pieceId)
    return self._ReinforceDict[pieceId]
end

function XBlackRockChessEnemy:UpdateUpdateContainReinforce()
    local value = false
    if not XTool.IsTableEmpty(self._PieceInfoDict) then
        for _, info in pairs(self._PieceInfoDict) do
            if not info:IsPiece() then
                value = true
                break
            end
        end
    end
    self._Model:UpdateContainReinforce(value)
end

--- 增援失败棋子
---@param info XBlackRockChessPiece
--------------------------
function XBlackRockChessEnemy:AddFailReinforceImp(info)
    local curRound = self._MainControl:GetChessRound()
    if not self._FailReinforceList[curRound] then
        self._FailReinforceList[curRound] = {}
    end
    table.insert(self._FailReinforceList[curRound], info)
end

function XBlackRockChessEnemy:CreateAction(objId, actionType, ...)
    return self._MainControl:CreateAction(objId, actionType, XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PIECE, ...)
end

function XBlackRockChessEnemy:AddHpByType(pieceType, value)
    local dict = self:GetPieceInfoDict()
    for _, piece in pairs(dict) do
        if piece:GetPieceType() == pieceType then
            piece:AddHp(value)
        end
    end
end

function XBlackRockChessEnemy:OnRelease()
    self._Imp = nil
    self._PieceInfoDict = {}
    self._SummonDict = {}
    self._TransformDict = {}
    self._ActionList = {}
    self._ReinforceDict = {}
    self._FailReinforceList = {}
end

return XBlackRockChessEnemy