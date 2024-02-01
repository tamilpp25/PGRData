---@field _Control XReformControl
---@class XUiReformListEnvironmentGrid:XUiNode
local XUiReformListEnvironmentGrid = XClass(XUiNode, "XUiReformListEnvironmentGrid")

function XUiReformListEnvironmentGrid:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
    self._OnClick = nil
    self._EnvironmentId = nil
end

function XUiReformListEnvironmentGrid:RegisterClick(func)
    self._OnClick = func
end

---@param data XViewModelReformEnvironment
function XUiReformListEnvironmentGrid:Update(data)
    self._EnvironmentId = data.EnvironmentId
    self.Text.text = data.Name
    self.Text2.text = data.Desc
    self.TxtCost.text = data.AddScore
    self.RawImage:SetRawImage(data.Icon)
    self.Select.gameObject:SetActiveEx(data.IsSelected)
end

function XUiReformListEnvironmentGrid:OnClick()
    self._OnClick(self._EnvironmentId)
end

return XUiReformListEnvironmentGrid