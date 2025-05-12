---@class XUiSkyGardenShoppingStreetGameGridConflict : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field RImgLogo UnityEngine.UI.RawImage
---@field TxtDetail1 UnityEngine.UI.Text
---@field GridCelebration XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetGameGridConflict = XClass(XUiNode, "XUiSkyGardenShoppingStreetGameGridConflict")

--region 生命周期
function XUiSkyGardenShoppingStreetGameGridConflict:OnStart(...)
    self:_RegisterButtonClicks()
end
--endregion

function XUiSkyGardenShoppingStreetGameGridConflict:Update(promotionId, i)
    self._SelectIndex = i
end

--region 按钮事件
function XUiSkyGardenShoppingStreetGameGridConflict:OnUiSkyGardenShoppingStreetGameGridConflictClick()
    if self.Parent.OnConflictEventClick then
        self.Parent:OnConflictEventClick(self._SelectIndex)
    end
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetGameGridConflict:_RegisterButtonClicks()
    self.UiSkyGardenShoppingStreetGameGridConflict.CallBack = function() self:OnUiSkyGardenShoppingStreetGameGridConflictClick() end
end
--endregion

return XUiSkyGardenShoppingStreetGameGridConflict
