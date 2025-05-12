---@class XUiGridRiftShowPlugin : XUiNode 仅展示用插件、简化版XUiRiftPluginGrid
---@field _Control XRiftControl
local XUiGridRiftShowPlugin = XClass(XUiNode, "XUiGridRiftShowPlugin")

function XUiGridRiftShowPlugin:OnStart()

end

function XUiGridRiftShowPlugin:Refresh(pluginId)
    local plugin = self._Control:GetPlugin(pluginId)
    local qualityImage, qualityImageBg = self._Control:GetPluginQualityImage(plugin.Quality)
    self.RImgIcon:SetRawImage(plugin.Icon)
    self.ImgQuality:SetSprite(qualityImage)
    self.ImgQualityBg:SetSprite(qualityImageBg)
    self.TxtName.text = plugin.Name
end

return XUiGridRiftShowPlugin