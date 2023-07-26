local XUiButton = require("XUi/XUiCommon/XUiButton")

---@class XUiReformListTabButton
local XUiReformListTabButton = XClass(nil, "XUiReformListTabButton")

function XUiReformListTabButton:Ctor(ui, viewModel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    ---@type XUiButtonLua
    self._BtnNormal = XUiButton.New(self.BtnNormal)
    XUiHelper.RegisterClickEvent(self, self.BtnNormal, self.OnClick)
    XUiHelper.RegisterClickEvent(self, self.BtnExtra, self.OnClick)

    ---@type XViewModelReform2ndList
    self._ViewModel = viewModel
    self._Data = false
end

---@param data XUiReformTabButtonData
function XUiReformListTabButton:SetData(data)
    self._Data = data
    if data.IsAdd then
        self.BtnNormal.gameObject:SetActiveEx(false)
        self.BtnExtra.gameObject:SetActiveEx(true)
    else
        self.BtnNormal.gameObject:SetActiveEx(true)
        self.BtnExtra.gameObject:SetActiveEx(false)
        self._BtnNormal:SetText("Txt1", data.Text1)
        self._BtnNormal:SetText("Txt2", data.Text2)
    end
    self:UpdateSelected()
end

function XUiReformListTabButton:OnClick()
    local index = self._Data.Index
    self._ViewModel:OnClickTabButton(index)
end

function XUiReformListTabButton:UpdateSelected()
    local index = self._Data.Index
    if self._ViewModel:GetButtonGroupIndex() == index then
        self.BtnNormal:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnNormal:SetButtonState(CS.UiButtonState.Normal)
    end
end

return XUiReformListTabButton
