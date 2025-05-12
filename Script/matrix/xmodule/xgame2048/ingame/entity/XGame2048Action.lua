---@class XGame2048Action
local XGame2048Action = XClass(nil ,'XGame2048Action')

function XGame2048Action:Ctor()
    
end

function XGame2048Action:SetActionType(type)
    self._Type = type
    self:ResetData()
end

function XGame2048Action:SetMoveAction(moveGridUid, fromx, fromy, tox, toy, followUid)
    self.GridUidA = moveGridUid
    self.MoveFromX = fromx
    self.MoveFromY = fromy
    self.MoveToX = tox
    self.MoveToY = toy
    -- 如果有关联的移动行为，后续需更新关联行为的目的地坐标
    self.GridUidB = followUid
end

function XGame2048Action:SetTempGridData(gridData)
    self.TempGridData = gridData
end

function XGame2048Action:SetMergeAction(mergeFromUid, mergeToUid, mergeToBlockId)
    self.GridUidA = mergeFromUid
    self.GridUidB = mergeToUid
    self.GridIdB = mergeToBlockId
end

function XGame2048Action:SetDispelAction(gridUid)
    self.GridUidA = gridUid
end

function XGame2048Action:SetReduceAction(gridUid)
    self.GridUidA = gridUid
end

function XGame2048Action:SetNewBornAction(gridUid)
    self.GridUidA = gridUid
end 

function XGame2048Action:SetLevelUpAction(gridUid)
    self.GridUidA = gridUid
end

function XGame2048Action:SetPosAimAction(x, y)
    self.MoveFromX = x
    self.MoveFromY = y
end

function XGame2048Action:SetEventCall(eventId, ...)
    self.EventId = eventId
    self.EventArgs = {...}
end

function XGame2048Action:SetMergeEffectType(type)
    self.MergeEffectType = type
end

function XGame2048Action:ResetData()
    self.MoveFromX = 0
    self.MoveFromY = 0
    self.MoveToX = 0
    self.MoveToY = 0
    self.GridUidA = nil
    self.GridUidB = nil
    self.EventId = nil
    self.EventArgs = nil
    self.GridIdB = nil
    self.TempGridData = nil
    self.MergeEffectType = nil
end

function XGame2048Action:GetActionType()
    return self._Type or XMVCA.XGame2048.EnumConst.ActionType.None
end

return XGame2048Action