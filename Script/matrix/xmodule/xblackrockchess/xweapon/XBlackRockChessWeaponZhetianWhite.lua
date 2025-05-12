---@type XBlackRockChessWeapon
local XBlackRockChessWeapon = require("XModule/XBlackRockChess/XWeapon/XBlackRockChessWeapon")

---@class XBlackRockChessWeaponZhetianWhite
---@field _Boss XChessBoss
local XBlackRockChessWeaponZhetianWhite = XClass(XBlackRockChessWeapon, "XBlackRockChessWeaponZhetianWhite")

-- 初始化
function XBlackRockChessWeaponZhetianWhite:OnInit()
    -- 普攻范围
    self._ATTACK_RANGE = {
        {x = 0, y = 1}, 
        {x = 1, y = 0}, 
        {x = 0, y = -1}, 
        {x = -1, y = 0}
    }
    
    -- 移动类型
    self._MoveType = self.MOVE_TYPE.AWAY
    self._MoveMaxDistance = 2 -- 远离敌人不超过2圈距离
    -- 在移动后进行检测追加普攻Action
    self._CheckPlayAttackSkillAfterMove = true
end

function XBlackRockChessWeaponZhetianWhite:OnRelease()
    self._ATTACK_RANGE = nil
    self._Boss = nil
    self._WeaponId = nil
    self._MoveType = nil
end

-- 由C#调用
-- 获取移动范围
function XBlackRockChessWeaponZhetianWhite:Search(csharpList)
    -- 存在延迟生效的技能，使用延迟技能的攻击范围
    if self._Boss:IsExitSkillDelay() then
        
    -- 可以释放大招
    elseif self:IsCanPlaySpecialSkill() then
        self:AddMoveRange(csharpList)
    -- 可以释放技能
    elseif self:IsCanPlayNormalSkill() then
        self:AddMoveRange(csharpList)
    -- 可以切换技能
    elseif self:IsCanPlayChangeSkill() then
        self:AddMoveRange(csharpList)
    -- 可以释放普攻
    elseif self:IsCanPlayAttackSkill() then
        
    else
        -- 移动范围
        self:AddMoveRange(csharpList)
    end
end

-- C#调用，由继承类实现
-- 获取进攻范围
function XBlackRockChessWeaponZhetianWhite:SearchAttack(csharpList)
    -- 存在延迟生效的技能，使用延迟技能的攻击范围
    if self._Boss:IsExitSkillDelay() then
        local skillInfo = self._Boss:GetDelaySkillInfo()
        if skillInfo.DelayRound == 0 then
            local skillId = skillInfo.SkillId
            local targetLocation = skillInfo.DelayInfo.TargetLocation
            if skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_SKILL then
                self:AddNormalSkillRange(csharpList)
            elseif skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_BIGSKILL then
                local ATTACK_TYPE = 2
                if skillInfo.Count == ATTACK_TYPE then
                    self:AddSpecialSkillRange(csharpList)
                end
            elseif skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_ATTACK then
                local isValid, coordPoint = self:IsPointBossCanAttack(targetLocation[1], targetLocation[2])
                csharpList:Add(coordPoint)
            end
        end
        -- 可以释放大招
    elseif self:IsCanPlaySpecialSkill() then
        -- 可以释放技能
    elseif self:IsCanPlayNormalSkill() then
        -- 可以切换技能
    elseif self:IsCanPlayChangeSkill() then
        -- 可以释放普攻
    elseif self:IsCanPlayAttackSkill() then
    end
end

-- 获取可移动的点位，用于计算最佳移动点位
function XBlackRockChessWeaponZhetianWhite:GetMovePoints()
    local points = {}
    local curPoint = self._Boss:GetMovedPoint()
    for x = 1, XEnumConst.BLACK_ROCK_CHESS.BOARD_WIDTH do
        for y = 1, XEnumConst.BLACK_ROCK_CHESS.BOARD_HEIGHT do
            local isWhite = CS.XBlackRockChess.XBlackRockChessManager.Instance:IsWhiteBlock(x, y)
            if isWhite and math.abs(x - curPoint.x) <= self._MoveMaxDistance and math.abs(y - curPoint.y) <= self._MoveMaxDistance then
                local isValid, coordPoint = self:IsPointBossCanMove(x, y)
                if isValid then
                    table.insert(points, coordPoint)
                end
            end
        end
    end
    return points
end

-- 添加移动范围
function XBlackRockChessWeaponZhetianWhite:AddMoveRange(csharpList)
    local points = self:GetMovePoints()
    for _, p in ipairs(points) do
        csharpList:Add(p)
    end
end

-- 检测能否攻击到这个点位
function XBlackRockChessWeaponZhetianWhite:CheckAttackPoint(point)
    -- 存在延迟生效的技能，使用延迟技能的攻击范围
    if self._Boss:IsExitSkillDelay() then
        local skillInfo = self._Boss:GetDelaySkillInfo()
        local skillId = skillInfo.SkillId
        if skillInfo.DelayRound == 0 then
            local targetX = skillInfo.DelayInfo.TargetLocation[1]
            local targetY = skillInfo.DelayInfo.TargetLocation[2]
            -- 白雷击：对所有黑格造成伤害
            if skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_SKILL then
                local isWhite = CS.XBlackRockChess.XBlackRockChessManager.Instance:IsWhiteBlock(point.x, point.y)
                return isWhite
            -- 大招：1阶段召唤、2阶段全屏伤害
            elseif skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_BIGSKILL then
                local ATTACK_TYPE = 2
                return skillInfo.Count == ATTACK_TYPE
            -- 普攻
            elseif skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_ATTACK then
                if point.x == targetX and point.y == targetY then
                    return true
                end
            end
        end
    -- 可以释放大招
    elseif self:IsCanPlaySpecialSkill() then
        return false
    -- 可以释放技能
    elseif self:IsCanPlayNormalSkill() then
        return false
    -- 可以切换技能
    elseif self:IsCanPlayChangeSkill() then
        return false
    -- 可以释放普攻
    elseif self:IsCanPlayAttackSkill() then
        return false
    end
    return false
end

-- 是否可以释放技能
function XBlackRockChessWeaponZhetianWhite:IsCanPlaySkill()
    -- 本回合没有收到伤害时，移动后会释放天罚雷击
    if not self._Boss:GetIsAttacked() and self._Boss:GetIsMoved() then
        self._SkillId = XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_CHANGE
        self._ActionType = XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_ATTACK_BACK
        self._SkillTargetPoint = self._Boss:GetMovedPoint()
        self._SkillAttackTimes = 1
        return true
    end
    
    self._SkillId = nil
    self._ActionType = nil
    self._SkillTargetPoint = nil
    self._SkillAttackTimes = 1
    self._SummonParams = nil
    self._SwitchWeaponId = nil
    if self:IsCanPlaySpecialSkill() then
        return true
    end

    if self:IsCanPlayNormalSkill() then
        return true
    end

    if self:IsCanPlayChangeSkill() then
        return true
    end

    if self:IsCanPlayAttackSkill() then
        return true
    end

    return false
end

-- 是否可以使用大招
function XBlackRockChessWeaponZhetianWhite:IsCanPlaySpecialSkill()
    if self._Boss:IsSkillInCD(XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_BIGSKILL) then
        return false
    end

    self._SkillId = XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_BIGSKILL
    self._ActionType = XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK
    self._SkillTargetPoint = self._Boss:GetMovedPoint()
    self._SkillAttackTimes = 1
    return true
end

-- 获取技能对应的召唤怪物信息
function XBlackRockChessWeaponZhetianWhite:GetSkillSummonParams(skillId)
    -- 召唤怪物信息
    local params = self._Boss._OwnControl:GetWeaponSkillParams(skillId)
    local summonParams = {
        Delay = params[5], -- 延迟出现回合数
        Exit = params[6], -- 存在回合数
        List = {}, -- 召唤棋子列表
    }
    -- 获取空位置
    local emptyPos = {}
    for y = XEnumConst.BLACK_ROCK_CHESS.BOARD_HEIGHT, 1, -1 do
        for x = 1, XEnumConst.BLACK_ROCK_CHESS.BOARD_WIDTH do
            local isValid, coordPoint = self:IsPointEmpty(x, y)
            if isValid then
                table.insert(emptyPos, coordPoint)
            end
        end
    end
    local startIndex = 7
    for i = startIndex, #params do
        local index = i - startIndex + 1
        table.insert(summonParams.List, {Id = params[i], Pos = emptyPos[index] })
    end
    return summonParams
end

-- 添加大招技能的攻击范围
function XBlackRockChessWeaponZhetianWhite:AddSpecialSkillRange(csharpList, luaList)
    for x = 1, XEnumConst.BLACK_ROCK_CHESS.BOARD_WIDTH do
        for y = 1, XEnumConst.BLACK_ROCK_CHESS.BOARD_HEIGHT do
            local isValid, coordPoint = self:IsPointBossCanAttack(x, y)
            if isValid then
                if csharpList then
                    csharpList:Add(coordPoint)
                end
                if luaList then
                    table.insert(luaList, coordPoint)
                end
            end
        end
    end
end

-- 是否可以使用普通技能
function XBlackRockChessWeaponZhetianWhite:IsCanPlayNormalSkill()
    if self._Boss:IsSkillInCD(XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_SKILL) then
        return false
    end

    -- 判断能否打到目标
    local haveTarget = false
    local roleDic = self._Boss._OwnControl:GetChessGamer():GetRoleDict()
    for _, role in pairs(roleDic) do
        if role:IsInBoard() then
            local rolePoint = role:GetMovedPoint()
            local isWhite = CS.XBlackRockChess.XBlackRockChessManager.Instance:IsWhiteBlock(rolePoint.x, rolePoint.y)
            haveTarget = haveTarget or isWhite
        end
    end
    if not haveTarget then return false end

    self._SkillId = XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_SKILL
    self._ActionType = XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK
    self._SkillTargetPoint = self._Boss:GetMovedPoint()
    self._SkillAttackTimes = 1
    return true
end

-- 添加普通技能的攻击范围
function XBlackRockChessWeaponZhetianWhite:AddNormalSkillRange(csharpList, luaList)
    for x = 1, XEnumConst.BLACK_ROCK_CHESS.BOARD_WIDTH do
        for y = 1, XEnumConst.BLACK_ROCK_CHESS.BOARD_HEIGHT do
            local isWhite = CS.XBlackRockChess.XBlackRockChessManager.Instance:IsWhiteBlock(x, y)
            if isWhite then
                local isValid, coordPoint = self:IsPointBossCanAttack(x, y)
                if isValid then
                    if csharpList then
                        csharpList:Add(coordPoint)
                    end
                    if luaList then
                        table.insert(luaList, coordPoint)
                    end
                end
            end
        end
    end
end

-- 是否可以使用切换技能
function XBlackRockChessWeaponZhetianWhite:IsCanPlayChangeSkill()
    if self._Boss:IsSkillInCD(XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_CHANGE) then
        return false
    end

    self._SkillId = XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_CHANGE
    self._ActionType = XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK
    self._SkillTargetPoint = self._Boss:GetMovedPoint()
    self._SkillAttackTimes = 1
    self._SwitchWeaponId = XEnumConst.BLACK_ROCK_CHESS.WEAPON_TYPE.ZHETIAN_BLACK
    return true
end

-- 是否可以使用普攻
function XBlackRockChessWeaponZhetianWhite:IsCanPlayAttackSkill()
    if self._Boss:IsSkillInCD(XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_ATTACK) then
        return false
    end

    self._SkillTargetPoint = nil
    local curPoint = self._Boss:GetMovedPoint()
    for _, offset in ipairs(self._ATTACK_RANGE) do
        local targetX = curPoint.x + offset.x
        local targetY = curPoint.y + offset.y
        local isValid, coordPoint = self:IsPointBossCanAttack(targetX, targetY)
        if isValid then
            -- 有角色
            local piece = CS.XBlackRockChess.XBlackRockChessManager.Instance:PieceAtCoord(coordPoint)
            if piece and piece.ChessRole then
                self._SkillId = XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_ATTACK
                self._ActionType = XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK
                self._SkillTargetPoint = { x = targetX, y = targetY }
                self._SkillAttackTimes = 1

                -- 非支援角色
                if not piece.ChessRole.IsSupport then
                    break
                end
            end
        end
    end
    return self._SkillTargetPoint ~= nil
end

-- 添加普攻范围
function XBlackRockChessWeaponZhetianWhite:AddAttackRange(csharpList, luaList)
    local curPoint = self._Boss:GetMovedPoint()
    for _, offset in ipairs(self._ATTACK_RANGE) do
        local targetX = curPoint.x + offset.x
        local targetY = curPoint.y + offset.y
        local isValid, coordPoint = self:IsPointBossCanAttack(targetX, targetY)
        if isValid then
            if csharpList then
                csharpList:Add(coordPoint)
            end
            if luaList then
                table.insert(luaList, coordPoint)
            end
        end
    end
end

-- 获取延迟释放技能的攻击点位
function XBlackRockChessWeaponZhetianWhite:GetDelayDamagePoints()
    local points = {}
    -- 存在延迟生效的技能，使用延迟技能的攻击范围
    if self._Boss:IsExitSkillDelay() then
        local skillInfo = self._Boss:GetDelaySkillInfo()
        if skillInfo.DelayRound == 0 then
            local skillId = skillInfo.SkillId
            local targetLocation = skillInfo.DelayInfo.TargetLocation
            if skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_SKILL then
                self:AddNormalSkillRange(nil, points)
            elseif skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_BIGSKILL then
                local ATTACK_TYPE = 2 -- 攻击阶段对应的值是2
                if skillInfo.Count == ATTACK_TYPE then
                    self:AddSpecialSkillRange(nil, points)
                end
            elseif skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_ATTACK then
                local isValid, coordPoint = self:IsPointBossCanAttack(targetLocation[1], targetLocation[2])
                return { coordPoint }
            end
        end
        -- 可以释放大招
    elseif self:IsCanPlaySpecialSkill() then
        -- 可以释放技能
    elseif self:IsCanPlayNormalSkill() then
        -- 可以切换技能
    elseif self:IsCanPlayChangeSkill() then
        -- 可以释放普攻
    elseif self:IsCanPlayAttackSkill() then
    end
    return points
end

-- 释放技能
function XBlackRockChessWeaponZhetianWhite:PlaySkill()
    local animTime = 0
    
    -- 添加Action
    local skillId = self._SkillId
    self._Boss:AddAction(self._ActionType, XEnumConst.BLACK_ROCK_CHESS.CHESS_OBJ_TYPE.BOSS, 
            self._WeaponId, skillId, self._SkillTargetPoint.x, self._SkillTargetPoint.y, self._SkillAttackTimes)

    -- 白状态的反击技能，使用雷击
    if self._ActionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_ATTACK_BACK then
        skillId = XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_SKILL
    end
    
    -- 大招动画表现
    if skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_BIGSKILL then
        self._Boss:GetImp():PlayAnimation("Aim")
        self._Boss:GetImp():LoadEffectInternal(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.ZHETIAN_BIGSKILLSKILL_EFFECT, false)

    -- 技能动画表现
    elseif skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_SKILL then
        self._Boss:GetImp():PlayAnimation("Aim")
        
    -- 切换状态动画表现
    elseif skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_CHANGE then
        self._Boss:GetImp():LoadEffectInternal(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.ZHETIAN_CHANGE_EFFECT, false)
        self._Boss:GetImp():PlayAnimation("Skill01", 0, function()
            self._Boss:ReloadBossModel(XEnumConst.BLACK_ROCK_CHESS.WEAPON_TYPE.ZHETIAN_BLACK)
            self._Boss:GetImp():LoadEffectInternal(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.ZHETIAN_CHANGE_EFFECT_BLACK, false)
        end)
        animTime = animTime + 3 -- 动画+切模型
        
    -- 普攻动画表现
    elseif skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_ATTACK then
        self._Boss:GetImp():PlayAnimation("Aim")
    end

    return animTime
end

-- 检测处理延迟技能
function XBlackRockChessWeaponZhetianWhite:CheckPlayDelaySkill()
    local XBlackRockChessUtil = CS.XBlackRockChess.XBlackRockChessUtil
    local ChessBoard = CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard
    
    local animTime = 0 -- 表现时间，单位：秒
    for skillId, skillInfo in pairs(self._Boss:GetWeaponSkillDict()) do
        if skillInfo.DelayRound == 0 then
            local targetX = skillInfo.DelayInfo.TargetLocation[1]
            local targetY = skillInfo.DelayInfo.TargetLocation[2]
            local isSummonVirtual = false
            -- 普攻技能结算
            if skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_ATTACK then
                self._Boss:GetImp().Weapon:TurnRound(targetX, targetY)
                self._Boss:GetImp():PlayAnimation("Attack", 0, function()
                    local effectId = XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.ZHETIAN_ATTACK
                    local offset = CS.UnityEngine.Vector3.zero
                    local rotate = CS.UnityEngine.Vector3.zero
                    local pointKey = CS.XBlackRockChess.XBlackRockChessUtil.Convert2Int(targetX, targetY)
                    CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard:LoadGridEffect(pointKey, effectId, offset, rotate)
                    self._Boss._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.ZHETIAN_ATTACK)
                end)
                animTime = animTime + 2 -- 雷击时间
                
            -- 雷击技能结算
            elseif skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_SKILL then
                self._Boss:GetImp():PlayAnimation("Attack", 0, function()
                    -- 头顶表情特效
                    self._Boss:GetImp():LoadEffectInternal(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.ZHETIAN_SKILL_EFFECT1, false)
                    -- 雷击特效
                    local points = {}
                    self:AddNormalSkillRange(nil, points)
                    local effectId = XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.ZHETIAN_SKILL_EFFECT2
                    local offset = CS.UnityEngine.Vector3.zero
                    local rotate = CS.UnityEngine.Vector3.zero
                    for _, point in ipairs(points) do
                        local pointKey = XBlackRockChessUtil.Convert2Int(point.x, point.y)
                        ChessBoard:LoadGridEffect(pointKey, effectId, offset, rotate)
                    end
                    -- 回收伤害预览特效
                    self._Boss:RecycleDelayDamageEffect()
                    self._Boss._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.ZHETIAN_SKILL)
                end)
                animTime = animTime + 3 -- 动画+雷击时间
                
            -- 大招动画表现
            elseif skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_BIGSKILL then
                if skillInfo.Count == 1 then
                    self._SummonParams = self:GetSkillSummonParams(skillId)
                    -- 生成召唤虚影
                    for _, p in ipairs(self._SummonParams.List) do
                        local pieceId = p.Id
                        local point = p.Pos
                        p.InsId = self._Boss._OwnControl:GetIncId()
                        self._Boss:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON_VIRTUAL, XEnumConst.BLACK_ROCK_CHESS.CHESS_OBJ_TYPE.ENEMY, 
                                p.InsId, pieceId, point.x, point.y, skillId)
                    end
                    isSummonVirtual = true
                    
                    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_PLAY_SKILL, skillId, false, function()
                        -- 召唤动画
                        self._Boss:GetImp():PlayAnimation("BigSkill", 0, function()
                            -- 生成召唤虚影
                            for _, p in ipairs(self._SummonParams.List) do
                                local pieceId = p.Id
                                local point = p.Pos
                                local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:Summon(pieceId, false, point, true)
                                self._Boss._OwnControl:GetChessEnemy():SummonVirtual(p.InsId, pieceId, imp)
                            end
                            -- 播放特效
                            self._Boss:GetImp():LoadEffectInternal(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.ZHETIAN_BIGSKILLSKILL_DISAPPER, false)

                            -- 给格子添加锁定特效
                            local curPoint = self._Boss:GetMovedPoint()
                            self._Boss:LoadLockGridEffects({curPoint})
                            
                            -- 常驻特效
                            self._Boss:GetImp():LoadEffectInternal(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.ZHETIAN_BIGSKILLSKILL_LOOP, false)
                        end)
                    end)
                    animTime = animTime + 3 -- 横幅+动画
                else
                    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_PLAY_SKILL, skillId, true, function()
                        -- 雷击特效
                        local points = {}
                        self:AddSpecialSkillRange(nil, points)
                        local effectId = XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.ZHETIAN_BIGSKILLSKILL_THUNDER
                        local offset = CS.UnityEngine.Vector3.zero
                        local rotate = CS.UnityEngine.Vector3.zero
                        for _, point in ipairs(points) do
                            local pointKey = XBlackRockChessUtil.Convert2Int(point.x, point.y)
                            ChessBoard:LoadGridEffect(pointKey, effectId, offset, rotate)
                        end
                        -- TODO Boss出现
                        -- TODO 眩晕
                        self._Boss:GetImp():PlayAnimation("BigSkillOver", 0, function()
                            -- 销毁临时召唤棋子
                            self._Boss._OwnControl:GetChessEnemy():CheckDestroyTempPiece()
                        end)

                        -- 隐藏锁定特效
                        self._Boss:RecycleLockGridEffects()
                        -- 回收伤害预览特效
                        self._Boss:RecycleDelayDamageEffect()
                        -- 隐藏常驻特效
                        self._Boss:GetImp():HideEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.ZHETIAN_BIGSKILLSKILL_LOOP)
                        -- 音效
                        self._Boss._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.ZHETIAN_BIGSKILL)
                    end)
                    animTime = animTime + 4 -- 横幅+动画+棋子销毁
                end
            end

            -- 添加延迟结算Action
            if not isSummonVirtual then
                local attackTimes = 1
                self._Boss:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.DELAY_SKILL, XEnumConst.BLACK_ROCK_CHESS.CHESS_OBJ_TYPE.BOSS, self._WeaponId, skillId, attackTimes)
            end
        end
    end
    return animTime
end

-- 是否在延迟技能之后眩晕
function XBlackRockChessWeaponZhetianWhite:IsDizzyAfterDelaySkill()
    for skillId, skillInfo in pairs(self._Boss:GetWeaponSkillDict()) do
        if skillInfo.DelayRound == 0 then
            if skillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_BIGSKILL then
                local END_COUNT = 2
                if skillInfo.Count == END_COUNT then
                    return true
                end
            end
        end
    end
    return false
end

-- 刷新技能特效
function XBlackRockChessWeaponZhetianWhite:RefreshSkillEffects()
    if self._Boss:IsExitSkillDelay() then
        local skillInfo = self._Boss:GetDelaySkillInfo()
        -- 跳劈技能中
        if skillInfo.SkillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_BIGSKILL and not self.IsRecoverEffect then
            if skillInfo.Count == 1 then
                self._Boss:GetImp():PlayAnimation("Aim")
            else
                self._Boss:GetImp():PlayAnimation("BigSkill")
                -- 给格子添加锁定特效
                local curPoint = self._Boss:GetMovedPoint()
                self._Boss:LoadLockGridEffects({curPoint})
                -- 常驻特效
                self._Boss:GetImp():LoadEffectInternal(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.ZHETIAN_BIGSKILLSKILL_LOOP, false)
            end
        end
    end
    
    -- 第一次进入玩法才需要恢复延迟技能/持续技能的特效
    self.IsRecoverEffect = true
end

return XBlackRockChessWeaponZhetianWhite