local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

local XUiRiftPluginShopItem = XClass(nil, "UiRiftPluginShopItem")

function XUiRiftPluginShopItem:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)

    self:RegisterButtonEvent()
    self.PluginGrid = XUiRiftPluginGrid.New(self.GridRiftPlugin)
end

function XUiRiftPluginShopItem:Refresh(goodData)
    self.GoodData = goodData

    self:Show()
    self.Plugin = XDataCenter.RiftManager.GetShopGoodsPlugin(goodData)
    self.PluginGrid:Refresh(self.Plugin)

    self.TxtCostCount3.text = goodData.ConsumeCount
    local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.RiftGold)
    self.RImgCostIcon3:SetRawImage(icon)
end

function XUiRiftPluginShopItem:RegisterButtonEvent()
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
    self.BtnUse.CallBack = function()
        self:OnClickBtnBuy()
    end
end

function XUiRiftPluginShopItem:OnClickBtnBuy()
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
    local canBuy = ownCnt >= self.GoodData.ConsumeCount
    if not canBuy then
        XUiManager.TipText("RogueLikeBuyNotEnough")
        return
    end

    XDataCenter.RiftManager.RequestBuyPlugin(self.GoodData.Id, function(newPluginId, decomposeValue)
        self:Close()
        self.Base:RefreshBuy()
        self.Base:OnShowPluginTip(newPluginId, decomposeValue)
    end)
end

function XUiRiftPluginShopItem:Show()
    self.GameObject.gameObject:SetActiveEx(true)
end

function XUiRiftPluginShopItem:Close()
    self.GameObject.gameObject:SetActiveEx(false)
end

return XUiRiftPluginShopItem