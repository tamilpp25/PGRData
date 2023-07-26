---@class XUiReformListPanelMobGridAffix
local XUiReformListPanelMobGridAffix = XClass(nil, "XUiReformListPanelMobGridAffix")

function XUiReformListPanelMobGridAffix:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XViewModelReform2ndList
    self._ViewModel = false
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
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
