---@class XUiReformListPanelMobGridAffix:XUiNode
local XUiReformListPanelMobGridAffix = XClass(XUiNode, "XUiReformListPanelMobGridAffix")

function XUiReformListPanelMobGridAffix:OnStart()
    self.Red = self.Red or XUiHelper.TryGetComponent(self.Transform, "ImgUiMainRed", "RectTransform")
    ---@type XViewModelReform2ndList
    self._ViewModel = false
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
    self._Button = XUiHelper.TryGetComponent(self.BtnClick, "", "XUiButton")
    self._IsHard = nil
end

function XUiReformListPanelMobGridAffix:SetViewModel(viewModel)
    self._ViewModel = viewModel
end

---@param data XReformAffixData
function XUiReformListPanelMobGridAffix:Update(data)
    self._Data = data
    self.Text.text = data.Name
    self.Text2.text = data.Desc
    self.RawImage:SetRawImage(data.Icon)
    self.TxtCost.text = data.Pressure
    self.Select.gameObject:SetActiveEx(data.IsSelected)
    self.PanelRepulsion.gameObject:SetActiveEx(data.IsShowMask)
    if data.IsLock then
        self._Button:SetButtonState(CS.UiButtonState.Disable)
    else
        self._Button:SetButtonState(CS.UiButtonState.Normal)
    end

    if self.ImgBgHard then
        if self._IsHard ~= data.IsHard then
            self._IsHard = data.IsHard
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

    XLog.Debug("打印词缀红点:" .. tostring(data.Affix:GetId()) .. data.Name .. tostring(data.IsRed))
    if self.Red then
        if data.IsRed then
            self.Red.gameObject:SetActiveEx(true)
        else
            self.Red.gameObject:SetActiveEx(false)
        end
    end
end

function XUiReformListPanelMobGridAffix:OnClick()
    if self._ViewModel.DataMob.PlayingAnimation then
        return
    end
    self._ViewModel:SetAffixSelected(self._Data)
end

function XUiReformListPanelMobGridAffix:PlayAnimationEnable()
    if not self.GameObject.activeInHierarchy then
        return
    end
    self.Transform:Find("Animation/GridEnable"):PlayTimelineAnimation(function()
        --canvasGroup.alpha = 1
        --rect.anchoredPosition = Vector2(rect.anchoredPosition.x, beforePlayPosY) -- 播放完的回调也强设一遍目标值
    end)
end

return XUiReformListPanelMobGridAffix
