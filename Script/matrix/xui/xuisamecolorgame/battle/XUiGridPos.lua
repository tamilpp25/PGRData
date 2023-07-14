local XUiGridPos = XClass(nil, "XUiGridPos")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiGridPos:Ctor(ui, row, col)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Row = row
    self.Col = col
    XTool.InitUiObject(self)
    self.EffectRemove.gameObject:SetActiveEx(false)
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

function XUiGridPos:ShowRemoveEffect()
    self.EffectRemove.gameObject:SetActiveEx(false)
    self.EffectRemove.gameObject:SetActiveEx(true)
end

function XUiGridPos:GetPosition()
    return self.Transform.position
end

return XUiGridPos