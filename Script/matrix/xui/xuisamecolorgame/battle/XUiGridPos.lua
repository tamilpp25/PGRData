---@class XUiSCBattleGridPos:XUiNode
---@field _Control XSameColorControl
local XUiGridPos = XClass(XUiNode, "XUiGridPos")

function XUiGridPos:Ctor(ui, parent, row, col)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Row = row
    self.Col = col
    self._SizeDeltaY = ui.transform.sizeDelta.y
    XTool.InitUiObject(self)
end

function XUiGridPos:GetPosKey(row, col, boardRow, boardCol, MaxSize)
    local IsNotUse = (boardRow < MaxSize and (row == 1 or row == MaxSize)) or (boardCol < MaxSize and (col == 1 or col == MaxSize))
    self:ShowGrid(not IsNotUse)
    return (not IsNotUse) and XSameColorGameConfigs.CreatePosKey(col, row)
end

function XUiGridPos:ShowGrid(IsShow)
    self.PanelUse.gameObject:SetActiveEx(IsShow)
    self.PanelNotUse.gameObject:SetActiveEx(not IsShow)
end

--region Ui - Anim
function XUiGridPos:ShowRemoveEffect(ballId)
    local battleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    local curUsingSkillId = battleManager:GetCurUsingSkillId()
    local SkillMoveEffectList = self._Control:GetCfgSkillBallRemoveEffect(curUsingSkillId)
    local effectUrl = self._Control:GetClientCfgStringValue("BattleBallRemoveEffect")

    self.EffectRemove.gameObject:SetActiveEx(false)
    self.EffectRemove.gameObject:SetActiveEx(true)
    
    if curUsingSkillId and not XTool.IsTableEmpty(SkillMoveEffectList) then
        local index = self:_GetBallIndex(ballId)
        if not string.IsNilOrEmpty(SkillMoveEffectList[index]) then
            effectUrl = SkillMoveEffectList[index]
        end
    end
    if self._PlayEffectUrl == effectUrl then
        return
    end
    self._PlayEffectUrl = effectUrl
    self.EffectRemove:LoadUiEffect(self._PlayEffectUrl, false)
end

function XUiGridPos:PrepareDefaultEffect()
    self.EffectRemove.gameObject:SetActiveEx(false)
    self._PlayEffectUrl = self._Control:GetClientCfgStringValue("BattleBallRemoveEffect")
    self.EffectRemove:LoadUiEffect(self._PlayEffectUrl, false)
end

function XUiGridPos:_GetBallIndex(ballId)
    local battleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    local roleBallList = battleManager:GetCurRole():GetBalls()
    for index, ball in ipairs(roleBallList) do
        if ball:GetBallId() == ballId then
            return index
        end
    end
    return 1
end

function XUiGridPos:GetPosition()
    return self.Transform.position
end

function XUiGridPos:GetSizeDeltaY()
    return self._SizeDeltaY
end

return XUiGridPos