local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

local XUiRiftPluginShopGrid = XClass(nil, "UiRiftPluginShopGrid")
local Color = {
    red = XUiHelper.Hexcolor2Color("d11227"),
    blue = XUiHelper.Hexcolor2Color("0f70bc"),
}

function XUiRiftPluginShopGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiRiftPluginShopGrid:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.PanelLock, self.OnBtnConditionClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClick)
end

function XUiRiftPluginShopGrid:OnBtnPluginDetail()
    XLuaUiManager.Open("UiRiftPluginShopTips", self.GoodData)
end

function XUiRiftPluginShopGrid:OnBtnConditionClick()
    if self.ConditionDesc then
        XUiManager.TipError(self.ConditionDesc)
    end
end

function XUiRiftPluginShopGrid:OnBtnBuyClick()
    if self.IsSellOut then
        XUiManager.TipErrorWithKey("PurchaseSettOut")
    else
        self.Parent:OnClickGridBuy(self.GoodData)
    end
end

function XUiRiftPluginShopGrid:Init(parent)
    self.Parent = parent
    self.PluginGrid = XUiRiftPluginGrid.New(self.GridRiftPlugin)
    self.PluginGrid:Init(function()
        self:OnBtnPluginDetail()
    end)
end

---@param data XTableRiftPluginShopGoods
function XUiRiftPluginShopGrid:Refresh(data)
    self.GoodData = data
    self.Plugin = XDataCenter.RiftManager.GetShopGoodsPlugin(data)
    self.PluginGrid:Refresh(self.Plugin)
    self.TxtName.text = self.Plugin:GetName()

    -- 已拥有即售罄
    if data.GoodsType == XEnumConst.Rift.RandomShopGoodType then
        self.IsSellOut = true
        for _, v in pairs(data.PluginIds) do
            local randomPlugin = XDataCenter.RiftManager.GetPlugin(v)
            if not randomPlugin:GetHave() then
                self.IsSellOut = false
                break
            end
        end
    else
        self.IsSellOut = self.Plugin:GetHave()
    end
    self.ImgSellOut.gameObject:SetActiveEx(self.IsSellOut)
    self.TxtCount.text = XUiHelper.GetText("CanBuy", self.IsSellOut and 0 or 1)

    -- 价格
    self.TxtNewPrice1.text = data.ConsumeCount
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
    self.TxtNewPrice1.color = ownCnt >= data.ConsumeCount and Color.blue or Color.red
    local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.RiftGold)
    self.RImgPrice1:SetRawImage(icon)

    self.PanelLock.gameObject:SetActiveEx(false)

    if not self.IsSellOut then
        local isOpen, desc = true, ""
        for _, v in pairs(data.ConditionId) do
            isOpen, desc = XConditionManager.CheckCondition(v)
            if not isOpen then
                break
            end
        end
        if not isOpen then
            self.ConditionDesc = desc
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = desc
        end
    end
end

return XUiRiftPluginShopGrid