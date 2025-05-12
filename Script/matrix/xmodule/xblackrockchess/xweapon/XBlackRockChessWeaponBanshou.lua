---@type XBlackRockChessWeapon
local XBlackRockChessWeapon = require("XModule/XBlackRockChess/XWeapon/XBlackRockChessWeapon")

---@class XBlackRockChessWeaponBanshou
---@field _Boss XChessBoss
local XBlackRockChessWeaponBanshou = XClass(XBlackRockChessWeapon, "XBlackRockChessWeaponBanshou")

-- 初始化
function XBlackRockChessWeaponBanshou:OnInit()
    -- 技能方向类型
    self.DIRECTION_TYPE = {
        NONE = 0,
        UP = 1,
        RIGHT = 2,
        DOWN = 3,
        LEFT = 4,
    }

    -- 技能范围
    self.SKILL_RANGE = {
        [self.DIRECTION_TYPE.UP] = {
            0, 4,    -- 第一个坐标的x方向偏移，y方向偏移，需要发给服务端
            -1, 4,
            1, 4,
            0, 3,
            0, 2,
            0, 1,
            -1, 1,
            1, 1,
        },
        [self.DIRECTION_TYPE.RIGHT] = {
            4, 0,
            4, 1,
            4, -1,
            3, 0,
            2, 0,
            1, 0,
            1, 1,
            1, -1,
        },
        [self.DIRECTION_TYPE.DOWN] = {
            0, -4,
            -1, -4,
            1, -4,
            0, -3,
            0, -2,
            0, -1,
            -1, -1,
            1, -1,
        },
        [self.DIRECTION_TYPE.LEFT] = {
            -4, 0,
            -4, 1,
            -4, -1,
            -3, 0,
            -2, 0,
            -1, 0,
            -1, 1,
            -1, -1,
        }
    }

    -- 强化后的技能范围
    self.SKILL_STRENGTH_RANGE = {
        [self.DIRECTION_TYPE.UP] = {
            0, 5,    -- 第一个坐标的x方向偏移，y方向偏移，需要发给服务端
            -1, 5,
            1, 5,
            -2, 5,
            2, 5,
            0, 4,
            -1, 4,
            1, 4,
            0, 3,
            0, 2,
            -1, 2,
            1, 2,
            0, 1,
            -1, 1,
            1, 1,
            -2, 1,
            2, 1,
        },
        [self.DIRECTION_TYPE.RIGHT] = {
            5, 0,
            5, -1,
            5, 1,
            5, -2,
            5, 2,
            4, 0,
            4, -1,
            4, 1,
            3, 0,
            2, 0,
            2, -1,
            2, 1,
            1, 0,
            1, -1,
            1, 1,
            1, -2,
            1, 2,
        },
        [self.DIRECTION_TYPE.DOWN] = {
            0, -5,
            -1, -5,
            1, -5,
            -2, -5,
            2, -5,
            0, -4,
            -1, -4,
            1, -4,
            0, -3,
            0, -2,
            -1, -2,
            1, -2,
            0, -1,
            -1, -1,
            1, -1,
            -2, -1,
            2, -1,
        },
        [self.DIRECTION_TYPE.LEFT] = {
            -5, 0,
            -5, -1,
            -5, 1,
            -5, -2,
            -5, 2,
            -4, 0,
            -4, -1,
            -4, 1,
            -3, 0,
            -2, 0,
            -2, -1,
            -2, 1,
            -1, 0,
            -1, -1,
            -1, 1,
            -1, -2,
            -1, 2,
        }
    }

    -- 移动类型
    self._MoveType = self.MOVE_TYPE.NEAR
    
    -- 选择使用的技能Id
    self._SkillId = nil
    -- 普攻/技能目标点位坐标
    self._SkillTargetPoint = nil
end

function XBlackRockChessWeaponBanshou:OnRelease()
    self.DIRECTION_TYPE = nil
    self.SKILL_RANGE = nil
    self.SKILL_STRENGTH_RANGE = nil
end

-- 由C#调用
-- 获取移动范围
function XBlackRockChessWeaponBanshou:Search(csharpList)
    -- 存在延迟生效的技能，使用延迟技能的攻击范围
    if self._Boss:IsExitSkillDelay() then
        
    -- 添加移动点位
    else
        self:AddMoveRange(csharpList)
    end
end

-- C#调用，由继承类实现
-- 获取进攻范围
function XBlackRockChessWeaponBanshou:SearchAttack(csharpList)
    -- 存在延迟生效的技能，使用延迟技能的攻击范围
    if self._Boss:IsExitSkillDelay() then
        local skillInfo = self._Boss:GetDelaySkillInfo()
        if skillInfo.DelayRound == 0 then
            local skillId = skillInfo.SkillId
            local targetX = skillInfo.DelayInfo.TargetLocation[1]
            local targetY = skillInfo.DelayInfo.TargetLocation[2]
            local skillType = self._Boss._OwnControl:GetWeaponSkillType(skillId)
            
            -- 跳劈技能
            if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_SKILL then
                local isStrengthRange, direction = self:GetSkillDirection(targetX, targetY)
                self:AddSkillRange(csharpList, nil, isStrengthRange, direction)

                -- 普攻技能
            elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_ATTACK then
                local coordPoint = CS.XBlackRockChess.XBlackRockChessUtil.Convert2Coordinate(targetX, targetY)
                csharpList:Add(coordPoint)
            end
        end
    end
end

-- 获取可移动的点位，用于计算最佳移动点位
function XBlackRockChessWeaponBanshou:GetMovePoints()
    local points = {}
    local curPoint = self._Boss:GetMovedPoint()
    local range = self:IsAddMoveRange() and 2 or 1
    for offsetX = -range, range do
        for offsetY = -range, range do
            local targetX = curPoint.x + offsetX
            local targetY = curPoint.y + offsetY
            local isValid, coordPoint = self:IsPointBossCanMove(targetX, targetY)
            if isValid then
                table.insert(points, coordPoint)
            end
        end
    end
    return points
end

-- 添加移动范围
function XBlackRockChessWeaponBanshou:AddMoveRange(csharpList)
    local points = self:GetMovePoints()
    for _, p in ipairs(points) do
        csharpList:Add(p)
    end
end

-- 检测能否攻击到这个点位
function XBlackRockChessWeaponBanshou:CheckAttackPoint(point)
    -- 存在延迟生效的技能，使用延迟技能的攻击范围
    if self._Boss:IsExitSkillDelay() then
        local skillInfo = self._Boss:GetDelaySkillInfo()
        local delayRound = skillInfo.DelayRound
        if delayRound == 0 then
            local skillId = skillInfo.SkillId
            local targetX = skillInfo.DelayInfo.TargetLocation[1]
            local targetY = skillInfo.DelayInfo.TargetLocation[2]
            local curPoint = self._Boss:GetMovedPoint()
            local skillType = self._Boss._OwnControl:GetWeaponSkillType(skillId)
            
            -- 跳劈技能
            if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_SKILL then
                local isStrengthRange, direction = self:GetSkillDirection(targetX, targetY)
                local skillRange = isStrengthRange and self.SKILL_STRENGTH_RANGE or self.SKILL_RANGE
                local offsetX = point.x - curPoint.x
                local offsetY = point.y - curPoint.y
                local offsets = skillRange[direction]
                for i = 1, #offsets, 2 do
                    if offsets[i] == offsetX and  offsets[i + 1] == offsetY then
                        self._SkillId = skillId
                        self._SkillTargetPoint = { x = targetX, y = targetY }
                        return true
                    end
                end

            -- 普攻技能
            elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_ATTACK then
                return point.x == targetX and point.y == targetY
            end
        end
    end
    return false
end

-- 是否可以播放技能
function XBlackRockChessWeaponBanshou:IsCanPlaySkill()
    self._SkillId = nil
    self._SkillTargetPoint = nil

    for _, skillId in ipairs(self._SkillIds) do
        local skillType = self._Boss._OwnControl:GetWeaponSkillType(skillId)
        if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_BIG_SKILL and self:IsCanPlaySpecialSkill(skillId) then
            return true
        elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_SKILL and self:IsCanPlayNormalSkill(skillId) then
            return true
        elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_ATTACK and self:IsCanPlayAttackSkill(skillId) then
            return true
        end
    end
    
    return false
end

-- 是否可以使用普攻
function XBlackRockChessWeaponBanshou:IsCanPlayAttackSkill(skillId)
    if self._Boss:IsSkillInCD(skillId) then
        return false
    end

    self._SkillTargetPoint = nil
    local curPoint = self._Boss:GetMovedPoint()
    local range = 1
    local roleDic = self._Boss._OwnControl:GetChessGamer():GetRoleDict()
    for _, role in pairs(roleDic) do
        if role:IsInBoard() then
            local rolePoint = role:GetMovedPoint()
            local offsetX = rolePoint.x - curPoint.x
            local offsetY = rolePoint.y - curPoint.y
            local isInRange = math.abs(offsetX) <= range and math.abs(offsetY) <= range
            if isInRange then
                self._SkillId = skillId
                self._SkillTargetPoint = { x = rolePoint.x, y = rolePoint.y }
                self._SkillAttackTimes = 1

                -- 优先指向包含角色的方位
                if not role:IsSupport() then
                    return true
                end
            end
        end
    end
    
    return self._SkillTargetPoint ~= nil
end

-- 添加普攻范围
function XBlackRockChessWeaponBanshou:AddAttackRange(csharpList)
    local curPoint = self._Boss:GetMovedPoint()
    local range = self:IsAddMoveRange() and 2 or 1
    for offsetX = -range, range do
        for offsetY = -range, range do
            local targetX = curPoint.x + offsetX
            local targetY = curPoint.y + offsetY
            local isValid, coordPoint = self:IsPointBossCanMove(targetX, targetY)
            if isValid then
                csharpList:Add(coordPoint)
            end
        end
    end
end

-- 是否可以使用普通技能
function XBlackRockChessWeaponBanshou:IsCanPlayNormalSkill(skillId)
    if self._Boss:IsSkillInCD(skillId) then
        return false
    end
    
    self._SkillTargetPoint = nil
    local curPoint = self._Boss:GetMovedPoint()
    local dirRanges = self:IsAddSkillRange() and self.SKILL_STRENGTH_RANGE or self.SKILL_RANGE
    local roleDic = self._Boss._OwnControl:GetChessGamer():GetRoleDict()
    for _, role in pairs(roleDic) do
        if role:IsInBoard() then
            local rolePoint = role:GetMovedPoint()
            local offsetX = rolePoint.x - curPoint.x
            local offsetY = rolePoint.y - curPoint.y
            
            for _, offsets in ipairs(dirRanges) do
                for i = 1, #offsets, 2 do
                    if offsets[i] == offsetX and offsets[i + 1] == offsetY then
                        self._SkillId = skillId
                        self._SkillTargetPoint = { x = offsets[1] + curPoint.x, y = offsets[2] + curPoint.y }
                        self._SkillAttackTimes = 1
                        
                        -- 优先指向包含角色的方位
                        if not role:IsSupport() then
                            return true
                        end
                    end
                end
            end
        end
    end

    return self._SkillTargetPoint ~= nil
end

-- 增加技能范围
function XBlackRockChessWeaponBanshou:AddSkillRange(csharpList, luaList, isStrengthRange, direction)
    local curPoint = self._Boss:GetMovedPoint()
    local skillRange = isStrengthRange and self.SKILL_STRENGTH_RANGE or self.SKILL_RANGE
    local offsets = skillRange[direction]
    if offsets then
        for i = 1, #offsets, 2 do
            local targetX = curPoint.x + offsets[i]
            local targetY = curPoint.y + offsets[i + 1]
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
end

-- 获取目标位置对应的技能方向
---@return boolean 是否是强化技能
---@return number 技能方向
function XBlackRockChessWeaponBanshou:GetSkillDirection(targetX, targetY)
    local curPoint = self._Boss:GetMovedPoint()
    local offsetX = targetX - curPoint.x
    local offsetY = targetY - curPoint.y
    for dir, offsets in pairs(self.SKILL_STRENGTH_RANGE) do
        if offsets[1] == offsetX and offsets[2] == offsetY then
            return true, dir
        end
    end
    for dir, offsets in pairs(self.SKILL_RANGE) do
        if offsets[1] == offsetX and offsets[2] == offsetY then
            return false, dir
        end
    end
    return false, self.DIRECTION_TYPE.NONE
end

-- 是否可以使用大招
function XBlackRockChessWeaponBanshou:IsCanPlaySpecialSkill(skillId)
    if self._Boss:IsSkillInCD(skillId) then
        return false
    end

    self._SkillId = skillId
    self._SkillTargetPoint = self._Boss:GetMovedPoint()
    self._SkillAttackTimes = 1
    return true
end

-- 是否增加移动距离
function XBlackRockChessWeaponBanshou:IsAddMoveRange()
    local skillInfo = self._Boss._CharacterSkillDict[XEnumConst.BLACK_ROCK_CHESS.CHARACTER_SKILL_TYPE.BANSHOU_ADD_MOVE_RANGE]
    return skillInfo and skillInfo.RemainRound > 0
end

-- 是否增加移动距离
function XBlackRockChessWeaponBanshou:IsAddSkillRange()
    local skillInfo = self._Boss._CharacterSkillDict[XEnumConst.BLACK_ROCK_CHESS.CHARACTER_SKILL_TYPE.BANSHOU_ADD_SKILL_RANGE]
    return skillInfo and skillInfo.RemainRound > 0
end

-- 是否在大招状态中
function XBlackRockChessWeaponBanshou:IsInBigSkill()
    return self:IsAddMoveRange() or self:IsAddSkillRange()
end

-- 获取延迟释放技能的攻击点位
function XBlackRockChessWeaponBanshou:GetDelayDamagePoints()
    local points = {}
    if self._Boss:IsExitSkillDelay() then
        local skillInfo = self._Boss:GetDelaySkillInfo()
        if skillInfo.DelayRound == 0 then
            local skillType = self._Boss._OwnControl:GetWeaponSkillType(skillInfo.SkillId)
            local targetX = skillInfo.DelayInfo.TargetLocation[1]
            local targetY = skillInfo.DelayInfo.TargetLocation[2]

            -- 跳劈开
            if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_SKILL then
                local isStrengthRange, direction = self:GetSkillDirection(targetX, targetY)
                self:AddSkillRange(nil, points, isStrengthRange, direction)

                -- 普攻
            elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_ATTACK then
                local coordPoint = CS.XBlackRockChess.XBlackRockChessUtil.Convert2Coordinate(targetX, targetY)
                table.insert(points, coordPoint)
            end
        end
    end
    return points
end

-- 释放技能
function XBlackRockChessWeaponBanshou:PlaySkill()
    local animTime = 0 -- 表现时间，单位：秒
    
    -- 添加Action
    local skillId = self._SkillId
    self._Boss:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK, XEnumConst.BLACK_ROCK_CHESS.CHESS_OBJ_TYPE.BOSS, 
            self._WeaponId, skillId, self._SkillTargetPoint.x, self._SkillTargetPoint.y, self._SkillAttackTimes)

    local skillType = self._Boss._OwnControl:GetWeaponSkillType(skillId)
    -- 大招动画表现
    if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_BIG_SKILL then
        -- 横幅
        XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_PLAY_SKILL, skillType, false, function()
            -- 横幅结束之后播放特效+播放动画
            self._Boss:GetImp():LoadEffectInternal(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.BANSHOU_BIGSKILL_EFFECT1, false)
            self._Boss:GetImp():PlayAnimation("BigSkill", 0, function()
                -- 显示常驻特效
                self._Boss:GetImp():LoadEffectInternal(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.BANSHOU_BIGSKILL_EFFECT2, false)
            end)

            self._Boss._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.BANSHOU_BIGSKILL)
        end)
        animTime = animTime + 3

    -- 技能动画表现
    elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_SKILL then
        self._Boss:GetImp():PlayAnimation("Aim")
        animTime = animTime + 1

    -- 普攻动画表现
    elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_ATTACK then
        self._Boss:GetImp().Weapon:TurnRound(self._SkillTargetPoint.x, self._SkillTargetPoint.y)
        self._Boss:GetImp():PlayAnimation("Aim")
        animTime = animTime + 1
    end
    return animTime
end

-- 检测处理延迟技能
function XBlackRockChessWeaponBanshou:CheckPlayDelaySkill()
    local animTime = 0 -- 表现时间，单位：秒
    for skillId, skillInfo in pairs(self._Boss:GetWeaponSkillDict()) do
        if skillInfo.DelayRound == 0 then
            local targetX = skillInfo.DelayInfo.TargetLocation[1]
            local targetY = skillInfo.DelayInfo.TargetLocation[2]
            
            -- 添加Action
            local attackTimes = 1
            self._Boss:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.DELAY_SKILL, XEnumConst.BLACK_ROCK_CHESS.CHESS_OBJ_TYPE.BOSS, 
                    self._WeaponId, skillId, attackTimes)

            local skillType = self._Boss._OwnControl:GetWeaponSkillType(skillId)
            -- 跳劈技能表现
            if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_SKILL then
                local points = self:GetDelayDamagePoints()
                -- 后空翻
                self._Boss:GetImp():PlayAnimation("Skill01", 0, function()
                    -- 每个格子都要播放砸地板特效
                    local effectId = XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.BANSHOU_SKILL_EFFECT
                    local offset = CS.UnityEngine.Vector3.zero
                    local rotate = CS.UnityEngine.Vector3.zero
                    local ChessBoard = CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard
                    local XBlackRockChessUtil = CS.XBlackRockChess.XBlackRockChessUtil
                    for _, point in ipairs(points) do
                        local pointKey = XBlackRockChessUtil.Convert2Int(point.x, point.y)
                        ChessBoard:LoadGridEffect(pointKey, effectId, offset, rotate)
                    end

                    self._Boss._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.BANSHOU_SKILL)
                end)
                animTime = animTime + 2 -- 后空翻+地板特效时间
                -- 震屏特效
                if self:IsInBigSkill() then
                    self._Boss:GetImp():LoadEffectInternal(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.BANSHOU_SKILL_SCREAN_EFFECT, false)
                    animTime = animTime + 0.5 -- 震屏特效时间
                end
                
            -- 普攻动画表现
            elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_ATTACK then
                self._Boss:GetImp().Weapon:TurnRound(targetX, targetY)
                self._Boss:GetImp():PlayAnimation("Attack")
                self._Boss:GetImp():LoadEffectInternal(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.BANSHOU_ATTACK_EFFECT, false)
                self._Boss._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.BANSHOU_ATTACK)
                animTime = animTime + 2
            end
            
            -- 回收伤害预览特效
            self._Boss:RecycleDelayDamageEffect()
        end
    end
    return animTime
end

-- 刷新技能特效
function XBlackRockChessWeaponBanshou:RefreshSkillEffects()
    -- 大招中需要显示常驻特效
    local bigSkillEffectId = XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.BANSHOU_BIGSKILL_EFFECT2
    if self:IsInBigSkill() then
        if not self._Boss:GetImp():IsEffectShow(bigSkillEffectId) and not self.IsRecoverEffect then
            self._Boss:GetImp():LoadEffectInternal(bigSkillEffectId, false)
        end
    else
        self._Boss:GetImp():HideEffect(bigSkillEffectId)
    end

    if self._Boss:IsExitSkillDelay() then
        local skillInfo = self._Boss:GetDelaySkillInfo()
        local skillType = self._Boss._OwnControl:GetWeaponSkillType(skillInfo.SkillId)
        -- 跳劈技能中
        if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_SKILL and not self.IsRecoverEffect then
            self._Boss:GetImp():PlayAnimation("AimLoop")
        
        -- 普攻技能中
        elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_ATTACK and not self.IsRecoverEffect then
            self._Boss:GetImp():PlayAnimation("Aim")
        end
    end
    
    -- 第一次进入玩法才需要恢复延迟技能/持续技能的特效
    self.IsRecoverEffect = true
end

-- 是否处于移动强化状态
function XBlackRockChessWeaponBanshou:IsInMoveStrengthen()
    return self:IsInBigSkill()
end

-- 是否处于技能强化状态
function XBlackRockChessWeaponBanshou:IsInSkillStrengthen(skillId)
    local skillType = self._Boss._OwnControl:GetWeaponSkillType(skillId)
    return skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_SKILL and self:IsInBigSkill()
end

function XBlackRockChessWeaponBanshou:PlayAttacked()
    self._Boss._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.BANSHOU_ATTACKED)
end

return XBlackRockChessWeaponBanshou