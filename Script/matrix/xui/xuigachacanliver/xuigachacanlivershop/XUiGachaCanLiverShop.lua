---@class XUiGachaCanLiverShop: XLuaUi
---@field _Control XGachaCanLiverControl
local XUiGachaCanLiverShop = XLuaUiManager.Register(XLuaUi, 'UiGachaCanLiverShop')
local XUiPanelGachaCanLiverShop = require('XUi/XUiGachaCanLiver/XUiGachaCanLiverShop/XUiPanelGachaCanLiverShop')

function XUiGachaCanLiverShop:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
end

function XUiGachaCanLiverShop:OnStart(shopIds)
    self._ShopIds = shopIds
    self:InitPanelAssets()
    self:InitShopPanels()
    XMVCA.XGachaCanLiver:SetReddotHideByKey(XEnumConst.GachaCanLiver.ReddotKey.ShopNoEnter)

    -- 如果没有记录过活动界面的剩余代币提示蓝点，则需要判断
    if XMVCA.XGachaCanLiver:CheckReddotShowByKey(XEnumConst.GachaCanLiver.ReddotKey.ShopNoEnterAfterTLClsoed) then
        -- 限时卡池结束后、常驻卡池抽完，且有货币的情况下, 进入过商店需要消除对应蓝点
        if XMVCA.XGachaCanLiver:CheckTimeLimitDrawIsOutTime()
                and XMVCA.XGachaCanLiver:CheckGachaIsSellOutRare(XMVCA.XGachaCanLiver:GetCurActivityResidentGachaId())
                and XMVCA.XGachaCanLiver:CheckHasItemCoin() then
            
            XMVCA.XGachaCanLiver:SetReddotHideByKey(XEnumConst.GachaCanLiver.ReddotKey.ShopNoEnterAfterTLClsoed)
        end
    end
    
    
    
    XMVCA.XGachaCanLiver:ClearShopGoodsReddot()
end

function XUiGachaCanLiverShop:InitPanelAssets()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ self._Control:GetCurActivityCoinItemId() }, self.PanelActivityAsset, self)
end

function XUiGachaCanLiverShop:InitShopPanels()
    local isTimelimitMap = {
        false,
        true
    }
    
    self._ShopPanels = {}
    
    XUiHelper.RefreshCustomizedList(self.SortGroup.transform.parent, self.SortGroup, #self._ShopIds, function(index, go)
        local panel = XUiPanelGachaCanLiverShop.New(go, self, self._ShopIds[index], isTimelimitMap[index])
        panel:Open()
        
        table.insert(self._ShopPanels, panel)
    end)
end

return XUiGachaCanLiverShop