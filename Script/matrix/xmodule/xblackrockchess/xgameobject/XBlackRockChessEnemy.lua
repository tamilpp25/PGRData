
---@class XBlackRockChessEnemy : XEntityControl 敌人
---@field _MainControl XBlackRockChessControl
---@field _Imp XBlackRockChess.XChessEnemy
---@field _PieceInfoDict table<number, XBlackRockChessPiece>
---@field _BossInfoDict table<number, XChessBoss>
---@field _FailReinforceList table<number, XBlackRockChessPiece[]>
local XBlackRockChessEnemy = XClass(XEntityControl, "XBlackRockChessEnemy")
local XBlackRockChessPiece = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessPiece")

--战斗力排序
local SortPieceTypeByPower = {
    [XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.QUEEN]  = 1,
    [XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.ROOK]   = 2,
    [XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.BISHOP] = 3,
    [XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.KNIGHT] = 4,
    [XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.PAWN]   = 5,
    [XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.KING]   = 6,
}

--Action排行
local SortPieceTypeByActionType = {
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.DELAY_SKILL] = 0,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE] = 1,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.PROMOTION] = 2,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_PREVIEW] = 3,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_TRIGGER] = 4,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM] = 5,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON] = 6,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON_VIRTUAL] = 7,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK] = 8,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_ATTACK_BACK] = 9,
}

local AfterActionType = {
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_PREVIEW] = true,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_TRIGGER] = true,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON] = true,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM] = true,
}

---@param pieceInfo XBlackRockChessPiece
local AsyncMove = asynTask(function(pieceInfo, point, onlyMove, cb)
    if not pieceInfo then
        if cb then cb() end
        return
    end
    pieceInfo:MoveTo(point, onlyMove, cb)
end)

---@param pieceInfo XBlackRockChessPiece
local AsyncPlayMove = asynTask(function(pieceInfo, point, cb)
    if not pieceInfo then
        if cb then cb() end
        return
    end
    pieceInfo:PlayMoveTo(point, cb)
end)

---@param pieceInfo XBlackRockChessPiece
local AsyncPlayMoveWithPause = asynTask(function(pieceInfo, point, distance, cb)
    if not pieceInfo then
        if cb then cb() end
        return
    end
    pieceInfo:PlayMoveToWithPause(point, distance, cb)
end)

function XBlackRockChessEnemy:OnInit()
    self._PieceInfoDict = {}
    self._BossInfoDict = {}
    self._SummonDict = {}
    self._TransformDict = {}
    self._ActionList = {}
    self._ReinforceDict = {}
    self._FailReinforceList = {}
    
    self._OnSortMoveAndAttack = handler(self, self.OnSortMoveAndAttack)
    local interval, _ = self._MainControl:GetPieceMoveConfig()
    self._MoveInterval = interval
    self._MovePauseDistance = self._MainControl:GetMovePauseDistance()
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

    -- boss布局
    local bossDict = self:GetBossInfoDict()
    for roleId, boss in pairs(bossDict) do
        local x, y = boss:GetPos()
        local weaponId = boss:GetWeaponId()
        local weaponSkills = self._MainControl:GetWeaponSkillIds(weaponId)
        local moveRange = self._MainControl:GetWeaponMoveRange(weaponId)
        local modelUrl = self._MainControl:GetWeaponModelUrl(weaponId)
        local controllerUrl = self._MainControl:GetWeaponControllerUrl(weaponId)
        local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddBoss(roleId, modelUrl, controllerUrl, x, y, weaponId, #weaponSkills, moveRange)
        if not imp then
            XLog.Error("加载boss" .. roleId .. "失败")
        else
            boss:SetImp(imp)
        end
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
    local removeId = {}
    for _, info in pairs(self._PieceInfoDict) do
        if not exists[info:GetId()] or (info:GetIsTemp() and info:GetLiveCd() <= 0) then
            table.insert(removeId, info:GetId())
        end
    end

    if not XTool.IsTableEmpty(removeId) then
        for _, id in ipairs(removeId) do
            self:RemovePieceInfo(id)
        end
    end
end

function XBlackRockChessEnemy:UpdateBossFormation(bossExits)
    local removeIds = {}
    for _, info in pairs(self._BossInfoDict) do
        if not bossExits[info:GetId()] then
            table.insert(removeIds, info:GetId())
        end
    end

    if not XTool.IsTableEmpty(removeIds) then
        for _, id in ipairs(removeIds) do
            self:RemoveBossInfo(id)
        end
    end
end

function XBlackRockChessEnemy:UpdateData(formation, exists)
    local pieceInfo = formation.PieceInfo or {}
    local id = formation.Guid
    exists[id] = true
    local info = self:GetPieceInfo(id)
    if not info then
        info = self:AddEntity(XBlackRockChessPiece, id, pieceInfo.PieceId)
        self:AddPieceInfo(id, info)
    end
    local lastMemberType = info:GetMemberType()
    info:UpdateData(formation)
    self:UpdateTransformPiece(id, lastMemberType)
    
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

-- 更新boss信息
function XBlackRockChessEnemy:UpdateBossData(formation, exists)
    local characterInfo = formation.CharacterInfo or {}
    local characterId = characterInfo.CharacterId
    exists[characterId] = true
    local boss = self._BossInfoDict[characterId]
    if not boss then
        local XChessBoss = require("XModule/XBlackRockChess/XGameObject/XChessBoss")
        boss = self:AddEntity(XChessBoss, characterId)
        self._BossInfoDict[characterId] = boss
    end
    boss:UpdateData(formation)
end

function XBlackRockChessEnemy:RetractData(formation, disableDict, removeDict, allPieceDict)
    local id = formation.Guid
    local info = self:GetPieceInfo(id)
    --上个回合击杀了
    if info then
        --已经死亡但未同步
        local isDead = (not info:IsAlive())
        if isDead then
            disableDict[id] = true
        end
        info:UpdateData(formation)
        self:UpdateTransformPiece(id)
        if not isDead then
            info:Sync()
        end
    else
        removeDict[id] = formation
    end
    allPieceDict[id] = true
end

function XBlackRockChessEnemy:RetractBossData(formation)
    
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

            info:UpdateData(formation)
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

function XBlackRockChessEnemy:GetBossInfoDict()
    return self._BossInfoDict
end

function XBlackRockChessEnemy:GetBossInfo(bossId)
    return self._BossInfoDict[bossId]
end

-- 是否存在boss
function XBlackRockChessEnemy:GetBossList()
    local bossList = {}
    for _, bossInfo in pairs(self._BossInfoDict) do
        table.insert(bossList, bossInfo)
    end
    table.sort(bossList, function(a, b) 
        return a:GetId() < b:GetId()
    end)
    
    return bossList
end

function XBlackRockChessEnemy:GetKingPiece()
    for _, piece in pairs(self._PieceInfoDict) do
        if piece:GetPieceType() == XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.KING then
            return piece
        end
    end
    return nil
end

function XBlackRockChessEnemy:IsKingPieceDead()
    for _, piece in pairs(self._PieceInfoDict) do
        if piece:GetPieceType() == XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.KING then
            return not piece:IsAlive()
        end
    end
    return false
end

-- Boss是否死亡
function XBlackRockChessEnemy:IsBosseDead()
    local isExitBoss = false
    local isAllBossDead = true
    for _, boss in pairs(self._BossInfoDict) do
        isExitBoss = true
        if boss:IsAlive() then
            isAllBossDead = false
        end
    end
    return isExitBoss and isAllBossDead
end

function XBlackRockChessEnemy:IsAllPieceDead()
    -- 存在增援虚影
    if not XTool.IsTableEmpty(self._ReinforceDict) then
        return false
    end
    for _, info in pairs(self._PieceInfoDict) do
        if info:IsAlive() then
            return false
        end
    end
    for _, boss in pairs(self._BossInfoDict) do
        if boss:IsAlive() then
            return false
        end
    end
    return true
end

---@param pieceInfo XBlackRockChessPiece
function XBlackRockChessEnemy:AddPieceInfo(id, pieceInfo)
    self._PieceInfoDict[id] = pieceInfo
    if self._SummonDict[id] then
        local imp, virtual = self._SummonDict[id].Imp, self._SummonDict[id].IsVirtual
        pieceInfo:Summon(imp, false, virtual)
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

function XBlackRockChessEnemy:RemoveBossInfo(id)
    local info = self._BossInfoDict[id]
    if info then
        local imp = info:GetImp()
        if imp then
            local CSXBlackRockChessManager = CS.XBlackRockChess.XBlackRockChessManager.Instance
            CSXBlackRockChessManager.PieceDict:Remove(imp.Weapon.MovedPoint)
            CSXBlackRockChessManager.Enemy:RemovePiece(imp.Weapon)
            self:RemoveEntity(info)
            CS.UnityEngine.Object.Destroy(imp.gameObject)
        end
    end
    self._BossInfoDict[id] = nil
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
function XBlackRockChessEnemy:GetCanMovePieceList(customInfoDict)
    local list = {}
    local pieceInfoDict = customInfoDict or self._PieceInfoDict
    for _, info in pairs(pieceInfoDict) do
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

---@return XBlackRockChessPiece[]
function XBlackRockChessEnemy:GetCanAttackPieceList()
    local list = {}
    for _, info in pairs(self._PieceInfoDict) do
        --棋子已经死亡 | 刚增援
        if not info:IsAlive() or not info:IsPiece() then
            goto continue
        end

        --被眩晕
        if info:IsDizzy() then
            goto continue
        end

        table.insert(list, info)
        :: continue ::
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

---@param pieceA XBlackRockChessPiece
---@param pieceB XBlackRockChessPiece
function XBlackRockChessEnemy:OnSortMoveAndAttack(pieceA, pieceB)
    local typeA = self._MainControl:GetPieceType(pieceA:GetSortConfigId())
    local typeB = self._MainControl:GetPieceType(pieceB:GetSortConfigId())

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

---@param partner XBlackRockChessPartnerPiece
---@param enemy XBlackRockChessPiece
function XBlackRockChessEnemy:DoAttack(enemy, partner)
    local enemyAtk = enemy:GetHp() + enemy:GetAtkLift()
    local partnerAtk = partner:GetHp()
    local enemyPoint = enemy:GetMovedPoint()
    local partnerPoint = partner:GetMovedPoint()
    if partner:AttackEdByPiece(enemyAtk) then
        enemy:AttackEdByPiece(partnerAtk)
        CS.XBlackRockChess.XBlackRockChessManager.Instance:ShowDpsOnGrid(partnerPoint.x, partnerPoint.y, enemyAtk)
        CS.XBlackRockChess.XBlackRockChessManager.Instance:ShowDpsOnGrid(enemyPoint.x, enemyPoint.y, partnerAtk)
        self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_PARTNER_HEAD_HUD, partner:GetId(), partner:GetIconFollow())
        self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_ENEMY_HEAD_HUD, enemy:GetId(), enemy:GetIconFollow())
        enemy:OnSkillHit()
        partner:OnSkillHit()
        if not enemy:IsAlive() then
            -- 敌方棋子被友方棋子反击击杀 角色回复能量（怒气）
            self._MainControl:PartnerFightRecoverEnergy()
        end
        return
    end
    CS.XBlackRockChess.XBlackRockChessManager.Instance:ShowDpsOnGrid(partnerPoint.x, partnerPoint.y, 0)
end

-- 棋子的cd指的是移动cd，如果攻击范围内有角色/友棋，则必定攻击（即攻击无cd）
function XBlackRockChessEnemy:AsyncOnRoundBegin()
    -- 1.检查范围内有无血量更低的友方棋子 存在则优先攻击友方棋子
    ---@type XBlackRockChessPiece[]
    local dontAttackPartner = {}    -- 攻击角色/仅移动
    local partners = self._MainControl:GetChessPartner():GetPieceInfoDict()
    local enemys = self:GetCanAttackPieceList()
    local ignorePieceIds = {}
    -- 2. 获取玩家位置
    local actor = self._MainControl:GetMasterRole()
    local actorPoint = actor:GetMovedPoint()
    -- 3. 检查是否有棋子可以攻击玩家
    ---@type XBlackRockChessPiece
    local attack = nil
    for _, enemy in ipairs(enemys) do
        local imp = enemy:SearchEnemyAttackTarget(ignorePieceIds)
        if imp and not imp.ChessRole then
            ignorePieceIds[imp.Id] = true
        else
            table.insert(dontAttackPartner, enemy)
        end
        if imp and not attack and imp.MovedPoint.x == actorPoint.x and imp.MovedPoint.y == actorPoint.y then
            attack = enemy
        end
    end
    if attack and not attack:IsPieceNoAttack() then
        -- 格挡判断
        local actorDead = false
        if actor:CheckDefense() then
            -- 敌方棋子攻击后移动回原地（需要手动记录下Action 因为回到原地时底层判断没有移动过就不会创建）
            local piecePoint = attack:GetMovedPoint()
            AsyncPlayMoveWithPause(attack, actorPoint, self._MovePauseDistance)
            actor:DoDefense()
            AsyncPlayMove(attack, piecePoint)
            table.insert(self._ActionList, attack:CreateAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE, actorPoint.x, actorPoint.y))
            -- 红怒状态下会触发反击
            actor:DoCounterattack()
        elseif actor:TriggerAttackedBuff(1) or actor:DoInjuryFree() then
            -- buff免伤 > 融合buff免伤
            local piecePoint = attack:GetMovedPoint()
            AsyncPlayMove(attack, actorPoint)
            asynWaitSecond(self._MoveInterval)
            AsyncPlayMove(attack, piecePoint)
            table.insert(self._ActionList, attack:CreateAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE, actorPoint.x, actorPoint.y))
        elseif actor:IsBlendPieceId() then
            -- 角色附身棋子时 角色死亡 友方解除附身状态 敌方攻击后回到原位
            local piecePoint = attack:GetMovedPoint()
            self._BlendMoveAction = attack:CreateAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE, actorPoint.x, actorPoint.y)
            actor:AsyncAttacked(attack, AsyncMove)
            asynWaitSecond(self._MoveInterval)
            AsyncPlayMove(attack, piecePoint)
            actorDead = true
        else
            actor:AsyncAttacked(attack, AsyncMove)
            actorDead = true
        end
        -- 等待表演结束
        self._MainControl:SyncWait()
        -- 增援触发
        if not actorDead then
            self._MainControl:UpdateReinforce()
        end
        -- 回合结束
        self:OnRoundEnd()
        return
    end

    -- 检查是否有Boss可以攻击玩家
    local bossAttack = nil
    for _, info in pairs(self._BossInfoDict) do
        if info:CheckAttackPoint(actorPoint) then
            bossAttack = info
            break
        end
    end
    if bossAttack then
        -- boss攻击
        local animTime =  bossAttack:AttackTo(actor:GetMovedPoint())
        if animTime and animTime > 0 then
            asynWaitSecond(animTime) -- 等待表演结束
        end
        -- 角色被攻击
        if actor:CheckDefense() then
            actor:DoDefense()
            actor:DoCounterattackBoss()
            local WAIT_SECOND = 2 -- 反击击杀棋子表现，等待2秒
            asynWaitSecond(WAIT_SECOND)
        else
            actor:Attacked(bossAttack)
        end
        -- 免死：格挡/buff免伤/融合buff免伤
        local isNoDead = actor:CheckDefense() or actor:TriggerAttackedBuff(1) or actor:DoInjuryFree()
        if not isNoDead then
            -- 回合结束
            self:OnRoundEnd()
            return
        end
    end

    -- 4. 攻击友方棋子
    --for enemy, imp in pairs(attackPartner) do
    --    local pos = enemy:GetMovedPoint()
    --    local partner = self._MainControl:GetChessPartner():GetPieceInfo(imp.Id)
    --    if not partner then
    --        XLog.Error(enemy._Id .. " 攻击友方 " .. imp.Id)
    --    end
    --    if partner:IsCanBeAttacked() then
    --        enemy:MoveTo(imp.MovedPoint, true, function()
    --            self:DoAttack(enemy, partner)
    --        end)
    --    else
    --        enemy:PlayMoveTo(imp.MovedPoint, function()
    --            -- 攻击失败 回到原位
    --            enemy:PlayMoveTo(pos)
    --        end)
    --    end
    --end
    -- 5. 获取可以移动的棋子
    local isMovie = false
    local moveList = self:GetCanMovePieceList(dontAttackPartner)
    for _, pieceInfo in pairs(moveList) do
        pieceInfo:MoveTo(nil, false)
        isMovie = true
    end
    if isMovie then
        asynWaitSecond(self._MoveInterval)
    end
    
    -- boss行动
    for _, bossInfo in pairs(self._BossInfoDict) do
        if not bossInfo:IsAlive() then
            goto CONTINUE
        end
        
        -- 检测延迟技能结束
        local animTime = bossInfo ~= bossAttack and bossInfo:CheckPlayDelaySkill() or 0
        if animTime and animTime > 0 then
            asynWaitSecond(animTime) -- 等待表演结束
        end

        -- 可以行动
        if bossInfo:IsCanTakeAction() then
            -- 技能满足触发条件，释放技能，结束
            if bossInfo:IsCanPlaySkill() then
                animTime = bossInfo:PlaySkill()
                if animTime and animTime > 0 then
                    asynWaitSecond(animTime) -- 等待表演结束
                end
                
            -- boss移动
            elseif bossInfo:IsCanMove() and not bossInfo:IsDizzy() and bossInfo:IsAlive() then
                bossInfo:MoveTo(actorPoint, false)
                asynWaitSecond(self._MoveInterval) -- 等待移动结束
                
                -- 移动后，技能满足触发条件，释放技能，结束
                if bossInfo:IsCanPlaySkill() then
                    animTime = bossInfo:PlaySkill()
                    if animTime and animTime > 0 then
                        asynWaitSecond(animTime) -- 等待表演结束
                    end
                end
            end
        end
        :: CONTINUE ::
    end
    -- 6. 触发升变
    local attackList = self:GetAttackPieceList()
    for _, pieceInfo in pairs(attackList) do
        if pieceInfo:IsPromotion() then
            pieceInfo:Promotion()
        end
    end
    -- 7. 等待表演结束
    self._MainControl:SyncWait()
    -- 8. 增援触发
    self._MainControl:UpdateReinforce()
    -- 9. 回合结束
    self:OnRoundEnd()
end

function XBlackRockChessEnemy:OnRoundBegin()
    if not self._Imp then
        return
    end
    --self._Control:BroadcastRound(false, false)
    self._Imp:OnRoundBegin()
    self:ProcessPieceEffectOnBegin()
    self:AsyncOnRoundBegin()
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
        piece:DoProcessBuffEffect()
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
    for _, info in pairs(self._BossInfoDict) do
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

function XBlackRockChessEnemy:GetBossActionList()
    local list = {}
    for _, action in pairs(self._ActionList) do
        local objId = action.ObjId
        if self:GetBossInfo(objId)  then
            table.insert(list, action)
        end
    end
    return list
end

function XBlackRockChessEnemy:GetValidActionList(isRestore)
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
        elseif action.ActionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM then
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
        elseif not isRestore then
            table.insert(list, action)
        end
        
    end
    
    return list
end

function XBlackRockChessEnemy:GetActionList()
    local list = {}
    local isRevive = self._MainControl:GetChessGamer():IsRevive()
    local isTriggerProtect = self._MainControl:GetChessGamer():IsTriggerProtect()

    --特殊处理 角色附身棋子后被敌方攻击
    if self._BlendMoveAction then
        table.insert(list, self._BlendMoveAction)
        self._BlendMoveAction = nil
    end
    
    local isRestore = isRevive or isTriggerProtect
    for _, info in pairs(self._PieceInfoDict) do
        local iList = info:GetActionList(isRestore)
        list = XTool.MergeArray(list, iList)
    end
    --玩家死亡后，直接移除召唤 + 转换的虚影
    if isRestore then
        --self:RestoreBuff()
        list = XTool.MergeArray(list, self:GetValidActionList(true))
        list = XTool.MergeArray(list, self._MainControl:GetReinforceActionList())
        list = XTool.MergeArray(list, self:GetBossActionList())
    else
        list = XTool.MergeArray(list, self:GetValidActionList(false))
        list = XTool.MergeArray(list, self._MainControl:GetReinforceActionList())
    end
   
    table.sort(list, function(a, b)
        -- Boss的行动放在最后
        local isBossA = self._BossInfoDict[a.ObjId] ~= nil and 1 or 0
        local isBossB = self._BossInfoDict[b.ObjId] ~= nil and 1 or 0
        if isBossA ~= isBossB then
            return isBossA < isBossB
        end

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

    local before, after = {}, {}
    for _, v in ipairs(list) do
        if AfterActionType[v.ActionType] then
            table.insert(after, v)
        else
            table.insert(before, v)
        end
    end

    return before, after
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
            self:SummonOne(pieceId, buffId, imp, isVirtual, effectCount, hitActorId, hitRoundCount)
        end
    end
end

function XBlackRockChessEnemy:SummonOne(pieceId, buffId, imp, isVirtual, effectCount, hitActorId, hitRoundCount)
    --以前出虚影表示可以踩 出实体表示不能踩 现在只出虚影 表示不能踩
    self._MainControl:LoadVirtualEffect(imp, imp.ConfigId)
    local insId = self._MainControl:GetIncId()
    imp.Id = insId
    self._SummonDict[insId] = {
        Imp = imp,
        IsVirtual = isVirtual,
    }

    table.insert(self._ActionList, self:CreateAction(pieceId, XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON,
            imp.ConfigId, insId, imp.CurrentPoint.x, imp.CurrentPoint.y, buffId, effectCount, hitActorId, hitRoundCount))
end

--- 棋子虚影召唤
---@param pieceId number 挂载buff的棋子id
---@param impList table
---@return
--------------------------
function XBlackRockChessEnemy:SummonVirtual(insId, pieceId, imp)
    self._MainControl:LoadVirtualEffect(imp, pieceId)
    self._SummonDict[insId] = {
        Imp = imp,
        IsVirtual = true,
    }
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

function XBlackRockChessEnemy:UpdateTransformPiece(id, lastMemberType)
    -- 召唤虚影转实体
    local currentInfo = self:GetPieceInfo(id)
    local CHESS_MEMBER_TYPE = XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE
    if lastMemberType == CHESS_MEMBER_TYPE.PIECE_PREVIEW and currentInfo:GetMemberType() == CHESS_MEMBER_TYPE.PIECE then
        local imp = currentInfo:GetLocalInfo().Imp
        CS.XBlackRockChess.XBlackRockChessManager.Instance:Virtual2Piece(imp)
    end
    
    if not self._TransformDict[id] then
        return
    end
    local info = self._TransformDict[id]
    if info.IsVirtual and currentInfo then
        local imp = currentInfo:GetLocalInfo().Imp
        local tmp = CS.XBlackRockChess.XBlackRockChessManager.Instance:Virtual2Piece(imp)
        if not tmp then
            self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_ENEMY_HEAD_HUD, id)
            info.Imp:Destroy()
            self:RemovePieceInfo(id)
        else
            self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_ENEMY_HEAD_HUD, id, currentInfo:GetIconFollow())
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
    return self._MainControl:CreateAction(objId, actionType, XEnumConst.BLACK_ROCK_CHESS.CHESS_OBJ_TYPE.ENEMY, ...)
end

function XBlackRockChessEnemy:AddAction(action, isRemove)
    table.insert(self._ActionList, action)
end

function XBlackRockChessEnemy:AddHpOverflowByType(pieceType, value)
    local dict = self:GetPieceInfoDict()
    for _, piece in pairs(dict) do
        if piece:GetPieceType() == pieceType then
            piece:AddHpOverflow(value)
        end
    end
end

---是否和备战棋子重叠
---@param prepare XBlackRockChessPreparePiece
function XBlackRockChessEnemy:IsOverlap(prepare)
    if not prepare then
        return false
    end
    local dict = self:GetPieceInfoDict()
    for _, piece in pairs(dict) do
        local point = piece:GetMovedPoint()
        local preparePoint = prepare:GetMovedPoint()
        if point.x == preparePoint.x and point.y == preparePoint.y then
            return true
        end
    end
    return false
end

-- 销毁召唤的临时棋子
function XBlackRockChessEnemy:CheckDestroyTempPiece()
    -- 召唤虚影-变成实体-临时棋子到期清理掉
    local removeIds = {}
    for id, info in pairs(self._PieceInfoDict) do
        if info:GetIsTemp() then
            table.insert(removeIds, id)
        end
    end
    for _, id in pairs(removeIds) do
        local info = self._PieceInfoDict[id]
        info:DoDestroy()
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