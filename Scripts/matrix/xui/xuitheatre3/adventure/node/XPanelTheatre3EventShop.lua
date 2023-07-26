local XGridTheatre3EventShop = require("XUi/XUiTheatre3/Adventure/Node/XGridTheatre3EventShop")

---@class XPanelTheatre3EventShop : XUiNode
---@field _Control XTheatre3Control
---@field Parent XUiTheatre3Outpost
local XPanelTheatre3EventShop = XClass(XUiNode, "XPanelTheatre3EventShop")

function XPanelTheatre3EventShop:OnStart()
    self:_InitBuyItemDynamicTable()
    self:AddBtnListener()
end

function XPanelTheatre3EventShop:OnEnable()

end

function XPanelTheatre3EventShop:OnDisable()

end

--region Ui - Refresh
---@param shopCfg XTableTheatre3NodeShop
---@param slot XTheatre3NodeSlot
function XPanelTheatre3EventShop:Refresh(shopCfg, slot)
    self._ShopCfg = shopCfg
    self._NodeSlot = slot

    self:_RefreshPanelAsset()
    self:_RefreshTitle()
    self:_RefreshBtnOK()
    self:_RefreshBuyItem()
end

function XPanelTheatre3EventShop:_RefreshPanelAsset()
    self.PanelAssetitems.gameObject:SetActiveEx(false)
end

function XPanelTheatre3EventShop:_RefreshTitle()
    if not string.IsNilOrEmpty(self._ShopCfg.TitleContent) then
        self.TxtTitle.text = self._ShopCfg.TitleContent
    else
        self.TxtTitle.gameObject:SetActiveEx(false)
    end
    if not string.IsNilOrEmpty(self._ShopCfg.Desc) then
        XUiHelper.SetText2LineBreak(self.TxtContent, self._ShopCfg.Desc)
    else
        self.TxtContent.gameObject:SetActiveEx(false)
    end
end

function XPanelTheatre3EventShop:_RefreshBtnOK()
    if not string.IsNilOrEmpty(self._ShopCfg.EndComfirmText) then
        self.BtnOK:SetNameByGroup(0, self._ShopCfg.EndComfirmText)
    end
end

function XPanelTheatre3EventShop:_RefreshBuyItem()
    self.DynamicTable:SetDataSource(self._NodeSlot:GetShopItems())
    self.DynamicTable:ReloadDataSync(1)
    self.ShopGrid.gameObject:SetActiveEx(false)
end

function XPanelTheatre3EventShop:_InitBuyItemDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelShopList)
    self.DynamicTable:SetProxy(XGridTheatre3EventShop, self)
    self.DynamicTable:SetDelegate(self)
end

---@param grid XGridTheatre3EventShop
function XPanelTheatre3EventShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._NodeSlot:GetShopItems()[index])
    end
end
--endregion

--region Ui - BtnListener
function XPanelTheatre3EventShop:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnConfirmClick)
end

function XPanelTheatre3EventShop:OnBtnConfirmClick()
    
    self._Control:OpenTextTip(function()
            self._Control:RequestAdventureEndNode(function()
                self._NodeSlot:SetShopEndBuy()
                XLuaUiManager.PopThenOpen("UiTheatre3Outpost", self._NodeSlot)
            end)
        end,
        XUiHelper.ReadTextWithNewLineWithNotNumber("Theatre3EndShopTitle"),
        XUiHelper.ReadTextWithNewLineWithNotNumber("Theatre3EndShopContent"))
end
--endregion

return XPanelTheatre3EventShop