---@class XUiTaikoMasterSlider
local XUiTaikoMasterSlider = XClass(nil, "XUiTaikoMasterSlider")

function XUiTaikoMasterSlider:Ctor(ui)
    self._Index = 1
    self._Value = false
    self._Data = false
    self._PositionX = false
    self._UiSlider = ui
    self._CenterIndex = 1

    self.UiScaleArray = {}
    self._UiIcon = XUiHelper.TryGetComponent(ui, "ImgLan", "Image")
    self._LeftBtn = XUiHelper.TryGetComponent(ui, "BtnReduce", "Button")
    self._RightBtn = XUiHelper.TryGetComponent(ui, "BtnAdd", "Button")
    self._UiScaleBegin = XUiHelper.TryGetComponent(ui, "PanelDianeZuo", "RectTransform")
    self._UiScaleEnd = XUiHelper.TryGetComponent(ui, "PanelDianeYou", "RectTransform")
    self._TextValue = XUiHelper.TryGetComponent(self._UiIcon.transform, "TxtNumberLan", "Text")
    self:Init()
end

function XUiTaikoMasterSlider:Init()
    XUiHelper.RegisterClickEvent(self, self._LeftBtn, self.OnBtnLeft)
    XUiHelper.RegisterClickEvent(self, self._RightBtn, self.OnBtnRight)
end

function XUiTaikoMasterSlider:GetClosestIndex(value)
    for i = 1, #self._Data do
        if self._Data[i] == value then
            return i
        end
    end
    return 1
end

function XUiTaikoMasterSlider:SetSliderIndex(index, isSetBtn)
    self._Index = XMath.Clamp(index, 1, #self._Data)
    self:RefreshIconPosition()
    self:RefreshTextValue()
end

function XUiTaikoMasterSlider:CallOnSliderValueChanged()
    if self._OnSliderValueChanged then
        self._OnSliderValueChanged()
    end
end

function XUiTaikoMasterSlider:OnBtnLeft()
    self:SetSliderIndex(self._Index - 1, true)
    self:CallOnSliderValueChanged()
end

function XUiTaikoMasterSlider:OnBtnRight()
    self:SetSliderIndex(self._Index + 1, true)
    self:CallOnSliderValueChanged()
end

function XUiTaikoMasterSlider:RefreshIconPosition()
    local posX = self._PositionX[self._Index]
    if not posX then
        return
    end
    local position = self._UiIcon.transform.localPosition
    self._UiIcon.transform.localPosition = Vector3(posX, position.y, position.z)
end

function XUiTaikoMasterSlider:GetValue()
    return self._Data[self._Index]
end

function XUiTaikoMasterSlider:SetOnChanged(func)
    self._OnSliderValueChanged = func
end

function XUiTaikoMasterSlider:SetData(data)
    self._Data = data
    self._CenterIndex = math.floor((#data - 1) / 2) + 1
    local rectSlider = XUiHelper.TryGetComponent(self._UiSlider.transform, "PanelDi", "RectTransform")
    local widthSlider = rectSlider.rect.width
    local eachWidth = widthSlider / (#data - 1)
    self._PositionX = {}
    for i = 1, #data do
        self._PositionX[i] = (i - 1) * eachWidth - widthSlider / 2
    end
    for i = 1, #data do
        local uiScale = self.UiScaleArray[i]
        if not uiScale then
            if i == 1 then
                uiScale = self._UiScaleBegin
            elseif i == #data then
                uiScale = self._UiScaleEnd
            else
                uiScale = CS.UnityEngine.Object.Instantiate(self._UiScaleBegin, self._UiScaleBegin.transform.parent)
                local posX = self._PositionX[i]
                local position = uiScale.transform.localPosition
                uiScale.transform.localPosition = Vector3(posX, position.y, position.z)
            end
        end
        -- 显示首,尾,中
        local textValue = XUiHelper.TryGetComponent(uiScale, "TxtNumber", "Text")
        if self:IsShowSliderValue(i) then
            textValue.text = XUiHelper.GetText("TaikoMasterFrame", self._Data[i] or "??")
        else
            textValue.text = ""
        end
    end
end

--setData before setValue
function XUiTaikoMasterSlider:SetValue(value)
    if not self._Data then
        XLog.Error("[XUiTaikoMasterSlider] setData before setValue")
        return
    end
    self:SetSliderIndex(self:GetClosestIndex(value), true)
end

function XUiTaikoMasterSlider:RefreshTextValue()
    if self._TextValue then
        self._TextValue.text = self:GetValue()
    end
end

function XUiTaikoMasterSlider:IsShowSliderValue(index)
    return index == self._CenterIndex or index == 1 or index == #self._Data
end

return XUiTaikoMasterSlider
