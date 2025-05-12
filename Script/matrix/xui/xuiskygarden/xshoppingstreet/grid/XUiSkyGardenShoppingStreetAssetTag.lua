---@class XUiSkyGardenShoppingStreetAssetTag : XUiNode
---@field TxtNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetAssetTag = XClass(XUiNode, "XUiSkyGardenShoppingStreetAssetTag")

--region 生命周期
function XUiSkyGardenShoppingStreetAssetTag:OnStart()
    self._TextComponent = self.TxtNumGrid or self.TxtNum
end

function XUiSkyGardenShoppingStreetAssetTag:Update(key, i)
    local resCfgs = self._Control:GetStageResConfigs()
    local cfg = resCfgs[key]
    self:SetSprite(cfg.Icon)
    self:SetSpriteColor(XUiHelper.Hexcolor2Color(cfg.IconColor))
    
    local num = self._Control:GetStageResById(key)
    self:SetTextColor(XUiHelper.Hexcolor2Color(cfg.Color))
    self:SetText(self._Control:GetValueByResConfig(num, cfg))
end

function XUiSkyGardenShoppingStreetAssetTag:SetTextColor(color)
    self._TextComponent.color = color
end

function XUiSkyGardenShoppingStreetAssetTag:SetText(text)
    self._TextComponent.text = text
end

function XUiSkyGardenShoppingStreetAssetTag:SetSprite(sprite)
    self.ImgAsset:SetSprite(sprite)
end

function XUiSkyGardenShoppingStreetAssetTag:SetSpriteColor(color)
    self.ImgAsset.color = color
end
--endregion

return XUiSkyGardenShoppingStreetAssetTag
