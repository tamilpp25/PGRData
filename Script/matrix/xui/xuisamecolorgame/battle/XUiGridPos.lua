---@class XUiSCBattleGridPos:XUiNode
---@field _Control XSameColorControl
local XUiGridPos = XClass(XUiNode, "XUiGridPos")

function XUiGridPos:Ctor(ui, parent, row, col)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    ---Y
    self.Row = row
    ---X
    self.Col = col
    self._SizeDeltaY = ui.transform.sizeDelta.y
    XTool.InitUiObject(self)
    self.BallRemovePos = self._Control:GetClientCfgValue("BallRemoveEffPos")
    self.WeakRemovePos = self._Control:GetClientCfgValue("WeakRemoveEffPos")
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
function XUiGridPos:ShowRemoveEffect(ballId, skillId)
    local battleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    local curUsingSkillId = skillId or battleManager:GetCurUsingSkillId()
    local SkillMoveEffectList = self._Control:GetCfgSkillBallRemoveEffect(curUsingSkillId)

    local effectUrl
    local effectPosX, effectPosY = self.BallRemovePos[1], self.BallRemovePos[2]
    local ballConfig = XSameColorGameConfigs.GetBallConfig(ballId)
    if ballConfig.Type == XEnumConst.SAME_COLOR_GAME.BallType.Weak then
        effectPosX, effectPosY = self.WeakRemovePos[1], self.WeakRemovePos[2]
        effectUrl = self._Control:GetClientCfgStringValue("WeakBallRemoveEffect")
    --elseif battleManager:IsBallRemoveByProp(self, XEnumConst.SAME_COLOR_GAME.PropType.DaoDan, true) then
    --    effectUrl = self._Control:GetClientCfgStringValue("DaoDanRemoveEffect")
    else
        effectUrl = self._Control:GetClientCfgStringValue("BattleBallRemoveEffect")
    end

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
    self.EffectRemove.transform.localPosition = CS.UnityEngine.Vector3(tonumber(effectPosX), tonumber(effectPosY), 0)
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