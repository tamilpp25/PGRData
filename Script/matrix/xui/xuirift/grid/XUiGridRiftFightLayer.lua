local XUiGridRiftFightLayer = XClass(nil, "XUiGridRiftFightLayer")
local State = 
{
    Normal = 1,
    Select = 2,
    Disable = 3,
}

function XUiGridRiftFightLayer:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

function XUiGridRiftFightLayer:Update(xFightLayer, index)
    self.XFightLayer = xFightLayer
    self.Index = index
    self.Btn:SetNameByGroup(0, xFightLayer:GetId()) -- 标签名
    self.Clear.gameObject:SetActiveEx(xFightLayer:CheckHasPassed()) 
    if xFightLayer:GetType() == XRiftConfig.LayerType.Normal then
        self.CurNormal = self.Normal
        self.NormalSpecial.gameObject:SetActiveEx(false)
    else
        self.CurNormal = self.NormalSpecial
        self.Normal.gameObject:SetActiveEx(false)
    end

    self:RefreshReddot()
end

function XUiGridRiftFightLayer:RefreshReddot()
    self.Btn:ShowReddot(self.XFightLayer:CheckRedPoint())
end

function XUiGridRiftFightLayer:SetState(state)
    local showDisable = state == State.Disable
    self.CurNormal.gameObject:SetActiveEx(state == State.Normal)
    self.Select.gameObject:SetActiveEx(state == State.Select)
    self.Disable.gameObject:SetActiveEx(showDisable)
    self.Btn:SetDisable(showDisable)
end

function XUiGridRiftFightLayer:SetSelect(value)
    if value then
        self:SetState(State.Select)
    else
        if self.XFightLayer:CheckHasLock() then
            self:SetState(State.Disable)
        else
            self:SetState(State.Normal)
        end
    end

    if value then
        self.RootUi:OnGridFightLayerSelected(self)
    end
end

return XUiGridRiftFightLayer
