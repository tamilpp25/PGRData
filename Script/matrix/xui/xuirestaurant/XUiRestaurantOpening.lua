---@class XUiRestaurantOpening : XLuaUi
local XUiRestaurantOpening = XLuaUiManager.Register(XLuaUi, "UiRestaurantOpening")

function XUiRestaurantOpening:OnStart(isLevelUp)
    self.IsLevelUp = isLevelUp
    self:InitView()
end

function XUiRestaurantOpening:InitView()
    --Loading的关闭黑幕会遮住开门动画，所以直接Remove
    XLuaUiManager.Remove("UiLoading")

    self:PlayAnimationWithMask("AnimOpen", function()
        XDataCenter.RestaurantManager.OpenMainView(self.IsLevelUp, true, false)
    end)
end