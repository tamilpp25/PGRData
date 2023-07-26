
local XUiSSBOrderGrid = XClass(nil, "XUiSSBOrderGrid")

function XUiSSBOrderGrid:Ctor(uiPrefab, index, onSelectColor, onSelectCaptain)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.OnSelectColor = onSelectColor
    self.OnSelectCaptain = onSelectCaptain
    self.Index = index
    self:InitPanel()
end

function XUiSSBOrderGrid:InitPanel()
    local btns = {self.BtnRed, self.BtnBlue, self.BtnYellow}
    self.BtnGroupColors:Init(btns, function(index) self:SelectColor(index) end)
    --self.ToggleCaptain:onValueChanged('+', function(isOn) self:OnValueChange(isOn) end)
    self.ToggleCaptain.onValueChanged:AddListener(function(isOn) self:OnValueChange(isOn) end)
    self.TxtTitle.text = "P" .. self.Index
end

function XUiSSBOrderGrid:SetColor(colorIndex)
    if colorIndex and colorIndex > 0 then
        self.BtnGroupColors:SelectIndex(colorIndex)
    end
end

function XUiSSBOrderGrid:SetCaptainPos(captainIndex)
    self.ToggleCaptain.isOn = captainIndex == self.Index
end

function XUiSSBOrderGrid:SelectColor(index)
    if self.OnSelectColor then
        self.OnSelectColor(index, self.Index)
    end
end

function XUiSSBOrderGrid:OnValueChange(isOn)
    if self.OnSelectCaptain then
        self.OnSelectCaptain(isOn, self.Index)
    end
    self.ToggleCaptain.graphic.gameObject:SetActiveEx(isOn)
end

return XUiSSBOrderGrid