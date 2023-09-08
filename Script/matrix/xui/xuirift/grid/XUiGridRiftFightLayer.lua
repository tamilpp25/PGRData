---@class XUiGridRiftFightLayer
local XUiGridRiftFightLayer = XClass(nil, "XUiGridRiftFightLayer")

function XUiGridRiftFightLayer:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

---@param xFightLayer XRiftFightLayer
function XUiGridRiftFightLayer:Update(xFightLayer, index)
    self.XFightLayer = xFightLayer
    self.Index = index
    local layerType = xFightLayer:GetType()
    local isSeasonLayer = xFightLayer:IsSeasonLayer()
    local isPass = xFightLayer:CheckHasPassed()
    local isNormal = layerType == XRiftConfig.LayerType.Normal
    self.Pass.gameObject:SetActiveEx(isPass)
    self.Special.gameObject:SetActiveEx(not isNormal)
    self.Simple.gameObject:SetActiveEx(isNormal)
    for i = 1, 2 do
        self["TxtDeep" .. i].text = xFightLayer:GetId()
        self["ImgZoom" .. i].gameObject:SetActiveEx(layerType == XRiftConfig.LayerType.Zoom and not isSeasonLayer)
        self["ImgMatch" .. i].gameObject:SetActiveEx(layerType == XRiftConfig.LayerType.Zoom and isSeasonLayer)
        self["ImgMulti" .. i].gameObject:SetActiveEx(layerType == XRiftConfig.LayerType.Multi)
    end
    self:RefreshReddot()
end

function XUiGridRiftFightLayer:RefreshReddot()
    self.Btn:ShowReddot(self.XFightLayer:CheckRedPoint())
end

function XUiGridRiftFightLayer:SetState(state)
    self.Btn:SetButtonState(state)
    self.Lock.gameObject:SetActiveEx(state == CS.UiButtonState.Disable)
    self.Unlock.gameObject:SetActiveEx(state ~= CS.UiButtonState.Disable)
end

function XUiGridRiftFightLayer:SetSelect(value)
    if value then
        self:SetState(CS.UiButtonState.Select)
    else
        if self.XFightLayer:CheckHasLock() then
            self:SetState(CS.UiButtonState.Disable)
        else
            self:SetState(CS.UiButtonState.Normal)
        end
    end

    if value then
        self.RootUi:OnGridFightLayerSelected(self)
    end
end

return XUiGridRiftFightLayer
