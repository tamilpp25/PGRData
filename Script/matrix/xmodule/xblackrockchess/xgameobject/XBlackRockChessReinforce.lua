
---@class XBlackRockChessReinforce 增援
---@field _Id number
---@field _Control XBlackRockChessControl 控制器
local XBlackRockChessReinforce = XClass(nil, "XBlackRockChessReinforce")

local XBlackRockChessManager = CS.XBlackRockChess.XBlackRockChessManager.Instance
local XBlackRockChessUtil = CS.XBlackRockChess.XBlackRockChessUtil

function XBlackRockChessReinforce:Ctor(reinforceId, control)
    self._Id = reinforceId
    self._Control = control
    
    self._Type = self._Control:GetReinforceType(self._Id)
    self._Locations = self._Control:GetReinforceLocations(self._Id)
    self._PieceIds = self._Control:GetReinforcePieceIds(self._Id)
    self._Range = self._Control:GetReinforceRange(self._Id)
    self._Condition = self._Control:GetReinforceCondition(self._Id)
    self._PreviewCd = self._Control:GetReinforcePreviewCd(self._Id)
    self._TriggerCd = self._Control:GetReinforceTriggerCd(self._Id)
    self._ConditionPassed = false
    self._ActionList = {}
    self._PreviewIds = {}
end

function XBlackRockChessReinforce:UpdateData(previewCd, triggerCd)
    self._PreviewCd = previewCd
    self._TriggerCd = triggerCd
    self._ConditionPassed = false
    self._PreviewIds = {}
end

function XBlackRockChessReinforce:GetTriggerCd()
    return self._TriggerCd
end

function XBlackRockChessReinforce:UpdateAction()
    --超过出现回合
    if self._PreviewCd < 0 and self._TriggerCd < 0 then
        return
    end

    --已经触发过，不再重复触发
    --if self._Control:CheckReinforceTrigger(self._Id) then
    --    return
    --end

    -- 在UpdateCondition里特殊处理
    local previewCd = self._Control:GetReinforcePreviewCd(self._Id)
    if previewCd == 1 then
        return
    end
    
    --previewCd由服务端更新，如果为0，必出虚影
    if self._PreviewCd == 0 then
        self:DoPreview()
    end
end

function XBlackRockChessReinforce:UpdateCondition()
    if not XTool.IsNumberValid(self._Condition) then
        return
    end
    
    --已经触发过，不再重复触发
    if self._Control:CheckReinforceTrigger(self._Id) then
        return
    end
    
    local check, _ = self._Control:CheckCondition(self._Condition)
    if not check then
        
        --如果已经通过一次，当本次不通过时，需要将虚影销毁
        if self._ConditionPassed then
            self:Restore()
            self._PreviewIds = {}
        end
        self._ConditionPassed = false
        return
    end

    --检测通过, 如果配置了条件，当条件通过时，如果刚好PreviewCd == 1
    --需要立即出现虚影，给玩家提示
    local previewCd = self._Control:GetReinforcePreviewCd(self._Id)
    if previewCd == 1 and not self._ConditionPassed and self._PreviewCd > 0 then
        self:DoPreview()
        --local triggerCd = self._Control:GetReinforceTriggerCd(self._Id)
        ----需要在本回合结束后立即变成实体
        --if triggerCd == 2 then
        --    for _, previewId in ipairs(self._PreviewIds) do
        --        local imp = self._Control:GetChessEnemy():GetReinforceImp(previewId)
        --        if imp then
        --            self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_TRIGGER, previewId, 
        --                    self._Id, imp.MovedPoint.x, imp.MovedPoint.y)
        --        end
        --    end
        --end
        self._ConditionPassed = true
    end
    
end

function XBlackRockChessReinforce:Release()
    self._Control = nil
end

--出现虚影
function XBlackRockChessReinforce:DoPreview()
    --棋盘指定位置 如果位置被占用则在周围寻找一个新的空位
    if self._Type == XEnumConst.BLACK_ROCK_CHESS.REINFORCE_TYPE.SPECIFIC then
        for i, pieceId in ipairs(self._PieceIds) do
            local location = self._Locations[i]
            local pos = string.Split(location, "|")
            local centerPoint = CS.UnityEngine.Vector2Int(tonumber(pos[1]), tonumber(pos[2]))
            local point = self:FindAroundEmptySpecial(centerPoint)
            local imp = XBlackRockChessManager:AddPiece(pieceId, point.x, point.y, true)
            self:AddPreview(imp, pieceId)
        end
    elseif self._Type == XEnumConst.BLACK_ROCK_CHESS.REINFORCE_TYPE.KING_AROUND then --国王周围随机
        for _, pieceId in ipairs(self._PieceIds) do
            local imp = self:AddVirtualShadowAround(pieceId)
            self:AddPreview(imp, pieceId)
        end
    elseif self._Type == XEnumConst.BLACK_ROCK_CHESS.REINFORCE_TYPE.KING_RELATIVE then --国王相对位置
        for i, pieceId in ipairs(self._PieceIds) do
            local location = self._Locations[i]
            local pos = string.Split(location, "|")
            local imp = XBlackRockChessManager:AddVirtualShadowRelative(pieceId, tonumber(pos[1]), tonumber(pos[2]), true)
            self:AddPreview(imp, pieceId)
        end
    elseif self._Type == XEnumConst.BLACK_ROCK_CHESS.REINFORCE_TYPE.MASTER_AROUND then --主控角色身边
        for _, pieceId in ipairs(self._PieceIds) do
            local imp = XBlackRockChessManager:AddVirtualShadowAround(pieceId, self._Range, false)
            self:AddPreview(imp, pieceId)
        end
    elseif self._Type == XEnumConst.BLACK_ROCK_CHESS.REINFORCE_TYPE.MASTER_RELATIVE then --主控相对位置
        for i, pieceId in ipairs(self._PieceIds) do
            local location = self._Locations[i]
            local pos = string.Split(location, "|")
            local imp = XBlackRockChessManager:AddVirtualShadowRelative(pieceId, tonumber(pos[1]), tonumber(pos[2]), false)
            self:AddPreview(imp, pieceId)
        end
    end
end

function XBlackRockChessReinforce:AddPreview(imp, pieceId)
    if not imp then
        return
    end
    local id = self._Control:GetIncId()
    table.insert(self._PreviewIds, id)
    self._Control:GetChessEnemy():AddReinforceImp(id, imp)
    --设置成虚影
    self._Control:LoadVirtualEffect(imp, pieceId)
    self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_PREVIEW, id, self._Id, pieceId, imp.MovedPoint.x, imp.MovedPoint.y)
end

function XBlackRockChessReinforce:AddAction(actionType, id, ...)
    table.insert(self._ActionList, self._Control:GetChessEnemy():CreateAction(id, actionType, ...))
end

function XBlackRockChessReinforce:Sync()
    self._ActionList = {}
end

function XBlackRockChessReinforce:Restore()
    for _, action in pairs(self._ActionList) do
        local objId = action.ObjId
        if action.ActionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_TRIGGER then
            local info = self._Control:GetChessEnemy():GetPieceInfo(objId)
            if info then
                info:RestoreReinforce()
            end
        elseif action.ActionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_PREVIEW then
            local imp = self._Control:GetChessEnemy():GetReinforceImp(objId)
            if imp then
                XBlackRockChessManager:RestoreVirtualShadow(imp)
            end
            self._Control:GetChessEnemy():RemovePieceInfo(objId)
        end
    end
    self._ActionList = {}
end

function XBlackRockChessReinforce:GetActionList()
    return self._ActionList
end

function XBlackRockChessReinforce:AddVirtualShadowAround(pieceId)
    local king = XBlackRockChessManager.Enemy:FindKing()
    if not king then
        XLog.Warning("增援失败:棋盘上不存在国王，无法出增援!")
        return
    end
    local point = self:FindAroundEmptySpecial(king.MovedPoint)
    if XBlackRockChessUtil.IsUnSafeCoordinate(point) then
        XLog.Warning("增援失败: 增援位置不在棋盘上")
        return
    end
    return XBlackRockChessManager:AddPiece(pieceId, point.x, point.y, true)
end

--- 仅适用于增援类型1的获取召唤位置的方法
--- 1、先下后上
--- 2、远离角色1格远距离
--- 3、查找不到合适位置就再扩圈查找
function XBlackRockChessReinforce:FindAroundEmptySpecial(point)
    if XBlackRockChessManager:IsSummonValidPoint(point) then
        return point
    end

    local actor = self._Control:GetMasterRole()
    if not actor then
        XLog.Error("查找增援位置失败：角色不存在")
        return point
    end

    local round = 1
    local index = 1
    local actorPoint = actor:GetMovedPoint()
    local cur = CS.UnityEngine.Vector2Int(0, 0)
    local targetPoint = CS.UnityEngine.Vector2Int(0, 0)

    while round <= 8 do
        if index == 1 then
            --起始点在【中下】
            cur:Set(0, -round)
        else
            --顺时针
            if cur.x > -round and cur.y == -round then
                cur.x = cur.x - 1
            elseif cur.y < round and cur.x == -round then
                cur.y = cur.y + 1
            elseif cur.x < round and cur.y == round then
                cur.x = cur.x + 1
            else
                cur.y = cur.y - 1
            end
        end
        targetPoint = cur + point
        if XBlackRockChessManager:IsSummonValidPoint(targetPoint) then
            if math.abs(actorPoint.x - targetPoint.x) > 1 or math.abs(actorPoint.y - targetPoint.y) > 1 then
                break
            end
        end
        if index >= 8 * round then
            index = 1
            round = round + 1
        else
            index = index + 1
        end
    end
    
    return targetPoint
end

return XBlackRockChessReinforce