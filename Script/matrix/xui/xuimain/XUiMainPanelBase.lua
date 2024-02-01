---@class XUiMainPanelBase : XUiNode 主界面位置页面基类
---@field UiTheme XUiTheme
local XUiMainPanelBase = XClass(XUiNode, "XUiMainPanelBase")

function XUiMainPanelBase:InitTheme(transform)
    if transform then
        self.Transform = transform
    end
    self.UiTheme = self.Transform:GetComponent("XUiTheme")
    if not self.UiTheme then
        return
    end

    self.UiTheme:SetColorHandler(handler(self, self.OnHandleColor))
    self.UiTheme:SetPicturePathHandler(handler(self, self.OnHandleBackground))
    self.UiTheme:SetEffectPathHandler(handler(self, self.OnHandleEffect))
end

function XUiMainPanelBase:OnHandleColor(key, graphics)
    if not self.ThemeData then
        return
    end

    if graphics and graphics.color then
        local index = tonumber(key)
        graphics.color = XUiHelper.ConvertColorRGB(graphics.color, self.ThemeData.Colors[index])
    end
end

function XUiMainPanelBase:OnHandleBackground(key)
    if not self.ThemeData then
        return
    end
    local index = tonumber(key)
    return self.ThemeData.Backgrounds[index]
end

function XUiMainPanelBase:OnHandleEffect(key)
    if not self.ThemeData then
        return
    end
    local index = tonumber(key)
    return self.ThemeData.Effects[index]
end

function XUiMainPanelBase:UpdateTheme(themeData)
    if not themeData or not self.UiTheme then
        return
    end

    self.ThemeData = themeData
    self.UiTheme:RefreshTheme()

    self.ChangeColorFin = true
    self:AfterChangeColorCb()
end

function XUiMainPanelBase:AfterChangeColorCb()
end

return XUiMainPanelBase