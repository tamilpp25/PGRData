local XUiPurchaseLBTipsListItem = require("XUi/XUiPurchase/XUiPurchaseLBTipsListItem")

---@class XUiGridPurchaseRandomItem: XUiPurchaseLBTipsListItem
local XUiGridPurchaseRandomItem = XClass(XUiPurchaseLBTipsListItem, 'XUiGridPurchaseRandomItem')

function XUiGridPurchaseRandomItem:OnStart()
    self.Tog.onValueChanged:AddListener(handler(self, self.OnTogClick))
end

---@param rootUi XLuaUi
function XUiGridPurchaseRandomItem:SetRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridPurchaseRandomItem:SetId(id)
    self.Id = id
end

function XUiGridPurchaseRandomItem:SetTogIsOn(isOn)
    if self.Tog.isOn ~= isOn then
        self._IgnoreTogChange = true
    end
    self.Tog.isOn = isOn
end

function XUiGridPurchaseRandomItem:OnTogClick(isOn)
    if self._IgnoreTogChange then
        self._IgnoreTogChange = false
        return
    end
    
    if self.RootUi:CheckRandomChoiceIsSelect(self.Id) then
        self.RootUi:SetRandomChoice(self.Id, false)
    else
        if self.Parent:GetIsCanSubmit() then
            -- 已经可以提交了说明已经选够了，不能再选了
            XUiManager.TipText('PurchaseRandomBoxSelectOverflowTips')
            self:SetTogIsOn(false)
            return
        end
        self.RootUi:SetRandomChoice(self.Id, true)
    end

    self.RootUi:RefreshListShow()
end


return XUiGridPurchaseRandomItem