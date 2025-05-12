local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPurchaseRandomObtain: XLuaUi
local XUiPurchaseRandomObtain = XLuaUiManager.Register(XLuaUi, 'UiPurchaseRandomObtain')

function XUiPurchaseRandomObtain:OnAwake()
    self.BtnClose.CallBack = handler(self, self.Close)
end

function XUiPurchaseRandomObtain:OnStart(originRewardGoodsList, finalRewardGoodsList)
    self:RefreshRewardGoods(originRewardGoodsList, self.OriGrid256New)
    self:RefreshRewardGoods(finalRewardGoodsList, self.DesGrid256New)
end

function XUiPurchaseRandomObtain:RefreshRewardGoods(rewardGoodsList, gridObj)
    XUiHelper.RefreshCustomizedList(gridObj.transform.parent, gridObj, rewardGoodsList and #rewardGoodsList or 0, function(index, go)
        local grid = XUiGridCommon.New(self, go)
        grid:Refresh(rewardGoodsList[index])
    end)
end

return XUiPurchaseRandomObtain