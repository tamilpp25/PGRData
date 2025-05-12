
---@class XBlackRockChessWeapon
local XBlackRockChessWeapon = XClass(nil, "XBlackRockChessWeapon")

function XBlackRockChessWeapon:Ctor(info)
    -- 移动方式
    self.MOVE_TYPE = {
        NEAR = 1, -- 靠近
        AWAY = 2, -- 远离
    }

    ---@type XChessBoss
    self._Boss = info
    -- 武器Id
    self._WeaponId = self._Boss:GetWeaponId()
    -- 武器技能Id
    self._SkillIds = self._Boss._OwnControl:GetWeaponSkillIds(self._WeaponId)
    table.sort(self._SkillIds, function(a, b) return a > b end) -- 优先级由大到小
    -- 移动方式
    self._MoveType = self.MOVE_TYPE.NEAR
    
    self:OnInit()
end

function XBlackRockChessWeapon:OnInit()

end

function XBlackRockChessWeapon:OnRelease()

end

-- C#调用，由继承类实现
-- 获取移动范围
function XBlackRockChessWeapon:Search(csharpList)

end

-- C#调用，由继承类实现
-- 获取进攻范围
function XBlackRockChessWeapon:SearchAttack(csharpList)

end

-- 由继承类实现
-- 获取可移动的点位
function XBlackRockChessWeapon:GetMovePoints()
    return {}
end

-- 获取武器Id
function XBlackRockChessWeapon:GetWeaponId()
    return self._WeaponId
end

-- 获取移动的位置
function XBlackRockChessWeapon:SearchMovePoint(targetPoint)
    if self._MoveType == self.MOVE_TYPE.NEAR then
        return self:SearchMovePointNear(targetPoint)
    elseif self._MoveType == self.MOVE_TYPE.AWAY then
        return self:SearchMovePointAway(targetPoint)
    end
end

-- 获取移动点位，靠近
function XBlackRockChessWeapon:SearchMovePointNear(targetPoint)
    -- Y轴优先级>X轴优先级，Y轴优先选择靠近上方，X轴优先选择靠近左方
    local points = self:GetMovePoints()
    local selPoint = points[1]
    local cnt = #points
    if cnt > 1 then
        local distance = self:GetPointDistance(selPoint, targetPoint)
        for i = 2, cnt do
            local p = points[i]
            local d = self:GetPointDistance(p, targetPoint)
            if d ~= 0 and (d < distance or (d == distance and p.y > selPoint.y) or (d == distance and p.y == selPoint.y and p.x > selPoint.x)) then
                distance = d
                selPoint = p
            end
        end
    end
    return selPoint
end

-- 获取移动点位，远离
function XBlackRockChessWeapon:SearchMovePointAway(targetPoint)
    -- Y轴优先级>X轴优先级，Y轴优先选择靠近上方，X轴优先选择靠近左方
    local points = self:GetMovePoints()
    local selPoint = points[1]
    local cnt = #points
    if cnt > 1 then
        local distance = self:GetPointDistance(selPoint, targetPoint)
        for i = 2, cnt do
            local p = points[i]
            local d = self:GetPointDistance(p, targetPoint)
            if d ~= 0 and (d > distance or (d == distance and p.y > selPoint.y) or (d == distance and p.y == selPoint.y and p.x > selPoint.x))  then
                distance = d
                selPoint = p
            end
        end
    end
    return selPoint
end

-- 两个点之间的距离，不开根号，只用来比大小
function XBlackRockChessWeapon:GetPointDistance(p1, p2)
    local xDistance = math.abs(p1.x - p2.x)
    local yDistance = math.abs(p1.y - p2.y)
    return xDistance * xDistance + yDistance * yDistance
end

-- 检测能否攻击到这个点位
function XBlackRockChessWeapon:CheckAttackPoint(point)
    return false
end

-- 是否可以播放技能
function XBlackRockChessWeapon:IsCanPlaySkill()
    return false
end

-- 是否在移动后检测追加普攻技能释放
function XBlackRockChessWeapon:IsCheckPlayAttackSkillAfterMove()
    return self._CheckPlayAttackSkillAfterMove == true
end

-- 获取使用的技能Id
function XBlackRockChessWeapon:GetSkillId()
    return self._SkillId
end

-- 获取使用的技能类型
function XBlackRockChessWeapon:GetSkillType()
    return self._SkillType
end

-- 点位Boss是否可移动
---@return boolean, CS.UnityEngine.Vector2Int
function XBlackRockChessWeapon:IsPointBossCanMove(x, y)
    return self:IsPointEmpty(x, y)
end

-- 点位Boss是否可攻击
---@return CS.UnityEngine.Vector2Int
function XBlackRockChessWeapon:IsPointBossCanAttack(x, y)
    if CS.XBlackRockChess.XBlackRockChessUtil.IsSafeCoordinate(x, y) then
        local coordPoint = CS.XBlackRockChess.XBlackRockChessUtil.Convert2Coordinate(x, y)
        local piece = CS.XBlackRockChess.XBlackRockChessManager.Instance:PieceAtCoord(coordPoint)
        -- 没有棋子/非无敌角色
        if not piece or (piece.ChessRole and not piece.ChessRole:IsInvisibleWhenUseSkill()) then
            return true, coordPoint
        end
    end
end

-- 点位是否为空
---@return CS.UnityEngine.Vector2Int
function XBlackRockChessWeapon:IsPointEmpty(x, y)
    if CS.XBlackRockChess.XBlackRockChessUtil.IsSafeCoordinate(x, y) then
        local coordPoint = CS.XBlackRockChess.XBlackRockChessUtil.Convert2Coordinate(x, y)
        local piece = CS.XBlackRockChess.XBlackRockChessManager.Instance:PieceAtCoord(coordPoint)
        local virtualPiece = CS.XBlackRockChess.XBlackRockChessManager.Instance:VirtualPieceAtCoord(coordPoint)
        -- 没有棋子
        if not piece and not virtualPiece then
            return true, coordPoint
        end
    end
    return false
end

-- 是否可以释放普攻技能
function XBlackRockChessWeapon:IsCanPlayAttackSkill()
    
end

-- 获取延迟释放技能的攻击点位
function XBlackRockChessWeapon:GetDelayDamagePoints()

end

-- 释放技能
function XBlackRockChessWeapon:PlaySkill()
    
end

-- 检测处理延迟技能
function XBlackRockChessWeapon:CheckPlayDelaySkill()
    
end

-- 是否在延迟技能之后眩晕
function XBlackRockChessWeapon:IsDizzyAfterDelaySkill()
    return false
end

-- 刷新技能特效
function XBlackRockChessWeapon:RefreshSkillEffects()
    
end

-- 是否处于移动强化状态
function XBlackRockChessWeapon:IsInMoveStrengthen()
    return false
end

-- 是否处于技能强化状态
function XBlackRockChessWeapon:IsInSkillStrengthen()
    return false
end

-- 播放受击表现
function XBlackRockChessWeapon:PlayAttacked()
    
end

return XBlackRockChessWeapon