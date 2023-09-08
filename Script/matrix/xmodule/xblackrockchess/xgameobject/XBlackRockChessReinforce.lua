
---@class XBlackRockChessReinforce 增援
---@field _Id number
---@field _Control XBlackRockChessControl 控制器
local XBlackRockChessReinforce = XClass(nil, "XBlackRockChessReinforce")

function XBlackRockChessReinforce:Ctor(reinforceId, control)
    self._Id = reinforceId
    self._Control = control
    
    self._Type = self._Control:GetReinforceType(self._Id)
    self._Locations = self._Control:GetReinforceLocations(self._Id)
    self._PieceIds = self._Control:GetReinforcePieceIds(self._Id)
    
    self._ActionList = {}
end

function XBlackRockChessReinforce:UpdateData(previewCd, triggerCd)
    self._PreviewCd = previewCd
    self._TriggerCd = triggerCd
end

function XBlackRockChessReinforce:UpdateAction()
    --超过出现回合
    if self._PreviewCd < 0 and self._TriggerCd < 0 then
        return
    end
    if self._PreviewCd == 0 then
        self:DoPreview()
    end
end

function XBlackRockChessReinforce:Release()
    self._Control = nil
end

--出现虚影
function XBlackRockChessReinforce:DoPreview()
    if self._Type == XEnumConst.BLACK_ROCK_CHESS.REINFORCE_TYPE.KING_RANDOM then
        for _, pieceId in ipairs(self._PieceIds) do
            local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddVirtualShadow(pieceId)
            if imp then
                local id = self._Control:GetIncId()
                self._Control:GetChessEnemy():AddReinforceImp(id, imp)
                self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_PREVIEW, id, self._Id, pieceId, imp.MovePoint.x, imp.MovePoint.y)
            end 
        end
    elseif self._Type == XEnumConst.BLACK_ROCK_CHESS.REINFORCE_TYPE.SPECIFIC then
        for i, pieceId in ipairs(self._PieceIds) do
            local location = self._Locations[i]
            local pos = string.Split(location, "|")
            local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddPiece(pieceId, tonumber(pos[1]), tonumber(pos[2]), true)
            if imp then
                local id = self._Control:GetIncId()
                self._Control:GetChessEnemy():AddReinforceImp(id, imp)
                self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_PREVIEW, id, self._Id, pieceId, imp.MovePoint.x, imp.MovePoint.y)
            end
        end
    end
    self._PreviewCd = self._PreviewCd - 1
end

function XBlackRockChessReinforce:AddAction(actionType, id, ...)
    table.insert(self._ActionList, {
        ObjId = id,
        ActionType = actionType,
        Params = { ... }
    })
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
            local imp = self._ImpDict[objId]
            if imp then
                CS.XBlackRockChess.XBlackRockChessManager.Instance:RestoreVirtualShadow(imp)
            end
            self._Control:GetChessEnemy():DelReinforceImp(objId)
            self._ImpDict[objId] = nil
        end
    end
    self._ActionList = {}
end

function XBlackRockChessReinforce:GetActionList()
    return self._ActionList
end

return XBlackRockChessReinforce