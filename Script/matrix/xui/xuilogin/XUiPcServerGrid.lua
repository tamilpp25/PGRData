---@class XUiPcServerGrid
local XUiPcServerGrid = XClass(nil, "XUiPcServerGrid")

function XUiPcServerGrid:Ctor(ui)
    self._Server = false
    self._Callback = false
    -- 不用uiObject的原因是:这两个grid是美术手动复制的, 没有用DynamicTable
    local transform = ui.transform
    self.Transform = transform
    self.TextServerName = XUiHelper.TryGetComponent(transform, "Server1", "Text")
    self.ImageRecommend = XUiHelper.TryGetComponent(transform, "PanelTab", "Image")
    self.ImageLastLogin = XUiHelper.TryGetComponent(transform, "PanelTab1", "Image")
    self.ImageSelect = XUiHelper.TryGetComponent(transform, "PanelSelect", "Image")
    self.ButtonSelect = XUiHelper.TryGetComponent(transform, "", "Button")
    self:Init()
end

function XUiPcServerGrid:Init()
    XUiHelper.RegisterClickEvent(self, self.ButtonSelect, self.OnSelected)
end

function XUiPcServerGrid:SetCallback(callback)
    self._Callback = callback
end

function XUiPcServerGrid:OnSelected()
    if self._Callback then
        self._Callback(self._Server)
    end
end

function XUiPcServerGrid:SetSelected(isSelected)
    self.ImageSelect.gameObject:SetActiveEx(isSelected)
end

function XUiPcServerGrid:IsSelectedServer(server)
    return self._Server == server
end

function XUiPcServerGrid:Update(params)
    self._Server = params.server
    self.TextServerName.text = params.serverName
    if params.isLastLogin then
        self.ImageLastLogin.gameObject:SetActiveEx(true)
        self.ImageRecommend.gameObject:SetActiveEx(false)
    elseif params.isRecommend then
        self.ImageLastLogin.gameObject:SetActiveEx(false)
        self.ImageRecommend.gameObject:SetActiveEx(true)
    else
        self.ImageLastLogin.gameObject:SetActiveEx(false)
        self.ImageRecommend.gameObject:SetActiveEx(false)    
    end
end

function XUiPcServerGrid:Show()
    self.Transform.gameObject:SetActiveEx(true)
end

function XUiPcServerGrid:Hide()
    self.Transform.gameObject:SetActiveEx(false)
end

return XUiPcServerGrid
