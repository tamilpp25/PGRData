---@class XGoldenMinerSystemMove
local XGoldenMinerSystemMove = XClass(nil, "XGoldenMinerSystemMove")

---@param game XGoldenMinerGame
function XGoldenMinerSystemMove:Update(game, time)
    local stoneList = game.StoneEntityList
    if XTool.IsTableEmpty(stoneList) then
        return
    end
    for _, stoneEntity in ipairs(stoneList) do
        -- 是定春且处于定春静止时定春不动
        if not stoneEntity.Mouse or not game:CheckHasBuff(XGoldenMinerConfigs.BuffType.GoldenMinerMouseStop) then
            self:StoneMove(stoneEntity, time, game.BuffContainer)
        end
    end
end

--region Move
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemMove:StoneMove(stoneEntity, time)
    if not stoneEntity.Move or not stoneEntity.Stone then
        return
    end
    -- 不是Alive都不移动
    if stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE then
        return
    end
    -- 静止态不动
    if stoneEntity.Move.MoveType == XGoldenMinerConfigs.StoneMoveType.None then
        return
    end

    local direction = stoneEntity.Move.CurDirection
    local speed = stoneEntity.Move.Speed
    local position = stoneEntity.Stone.Transform.localPosition
    if stoneEntity.Move.MoveType == XGoldenMinerConfigs.StoneMoveType.Horizontal then
        local x = position.x + time * direction * speed
        if x < stoneEntity.Move.MoveMinLimit then
            x = stoneEntity.Move.MoveMinLimit
            self:ChangeMoveDirection(stoneEntity)
        elseif x > stoneEntity.Move.MoveMaxLimit then
            x = stoneEntity.Move.MoveMaxLimit
            self:ChangeMoveDirection(stoneEntity)
        end
        stoneEntity.Stone.Transform.localPosition = Vector3(x, position.y, position.z)
    elseif stoneEntity.Move.MoveType == XGoldenMinerConfigs.StoneMoveType.Vertical then
        local y = position.y + time * direction * speed
        if y < stoneEntity.Move.MoveMinLimit then
            y = stoneEntity.Move.MoveMinLimit
            self:ChangeMoveDirection(stoneEntity)
        elseif y > stoneEntity.Move.MoveMaxLimit then
            y = stoneEntity.Move.MoveMaxLimit
            self:ChangeMoveDirection(stoneEntity)
        end
        stoneEntity.Stone.Transform.localPosition = Vector3(position.x, y, position.z)
    elseif stoneEntity.Move.MoveType == XGoldenMinerConfigs.StoneMoveType.Circle then
        stoneEntity.Stone.Transform:RotateAround(stoneEntity.Move.CircleMovePoint, -CS.UnityEngine.Vector3.forward, speed * time)
    end
end

local MILLION_PERCENT = 1000000
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemMove:ChangeMoveDirection(stoneEntity)
    stoneEntity.Move.CurDirection = -stoneEntity.Move.CurDirection
    if stoneEntity.Data:GetType() ~= XGoldenMinerConfigs.StoneType.Mouse
            or stoneEntity.Move.MoveType == XGoldenMinerConfigs.StoneMoveType.Circle then
        return
    end
    -- 定春移动需要处理表现方向
    local scale = stoneEntity.Data:GetScale() / MILLION_PERCENT
    -- 转向时翻面
    stoneEntity.Stone.Transform.localScale = Vector3(scale * stoneEntity.Move.CurDirection, scale, scale)
    -- 携带物转向不翻面
    --if stoneEntity.CarryStone then
    --    stoneEntity.CarryStone.Transform.localScale = Vector3(
    --            stoneEntity.CarryStone.Transform.localScale.x * stoneEntity.Move.CurDirection,
    --            stoneEntity.CarryStone.Transform.localScale.y,
    --            stoneEntity.CarryStone.Transform.localScale.z)
    --end
end
--endregion


return XGoldenMinerSystemMove