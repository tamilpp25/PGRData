---@field _Control XReformControl
---@class XUiReformListGrid:XUiNode
local XUiReformListGrid = XClass(XUiNode, "XUiReformListGrid")

function XUiReformListGrid:OnStart()
    self.Red = self.Red or XUiHelper.TryGetComponent(self.Transform, "ImgUiMainRed", "RectTransform")
    local button = XUiHelper.TryGetComponent(self.Transform, "", "XUiButton")
    XUiHelper.RegisterClickEvent(self, button, self.OnClickAdd)
    ---@type XUiComponent.XUiButton
    self._Button = button
    --XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnClickAdd)
    --XUiHelper.RegisterClickEvent(self, self.BtnReform, self.OnClickAdd)

    ---@type XViewModelReform2ndList
    self._ViewModel = self._Control:GetViewModelList()
    self._Data = false

    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end

    self.GridTag = self.GridTag or XUiHelper.TryGetComponent(self.Transform, "ListTag/GridTag", "Transform")
    self._Labels = { self.GridTag }

    self._IsHard = nil
end

function XUiReformListGrid:SetViewModel(viewModel)
    self._ViewModel = viewModel
end

---@param data UiReformMobData
function XUiReformListGrid:Update(data)
    self._Data = data
    self.TxtName.text = data.Name
    self.RImgHead:SetRawImage(data.Icon)
    --self.TagName.text = data.TextLevel
    self.TxtCost.text = data.Pressure
    if self.Select then
        self.Select.gameObject:SetActiveEx(data.IsSelected)
    end

    local labels = data.Label
    for i, label in ipairs(labels) do
        if not self._Labels[i] then
            local instance = XUiHelper.Instantiate(self.GridTag.transform, self.GridTag.transform.parent)
            self._Labels[i] = instance
        end
        local textComponent = XUiHelper.TryGetComponent(self._Labels[i], "TagName", "Text")
        textComponent.text = label
        self._Labels[i].gameObject:SetActiveEx(true)
    end
    for i = #labels + 1, #self._Labels do
        self._Labels[i].gameObject:SetActiveEx(false)
    end

    if data.IsLock then
        self._Button:SetButtonState(CS.UiButtonState.Disable)
    else
        self._Button:SetButtonState(CS.UiButtonState.Normal)
    end

    if self._IsHard ~= data.IsHard then
        self._IsHard = data.IsHard
        if self.ImgBgHard then
            if data.IsHard then
                self.ImgBgHard.gameObject:SetActiveEx(true)
                self.ImgBg.gameObject:SetActiveEx(false)
                self:PlayAnimation("Red")
                self:StopAnimation("Green")
            else
                self.ImgBgHard.gameObject:SetActiveEx(false)
                self.ImgBg.gameObject:SetActiveEx(true)
                self:StopAnimation("Red")
                self:PlayAnimation("Green")
            end
        end
    end

    XLog.Debug("打印怪物红点:" .. tostring(data.Mob:GetId()) .. data.Name .. tostring(data.IsRed))
    if self.Red then
        if data.IsRed then
            self.Red.gameObject:SetActiveEx(true)
        else
            self.Red.gameObject:SetActiveEx(false)
        end
    end
end

function XUiReformListGrid:OnClickAdd()
    self._ViewModel:SetSelectedMob(self._Data)
end

return XUiReformListGrid
