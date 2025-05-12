---@class XUiPanelPurchaseRandomList: XUiNode
local XUiPanelPurchaseRandomList = XClass(XUiNode, 'XUiPanelPurchaseRandomList')
local XUiGridPurchaseRandomItem = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPurchaseRandomBoxSelection/XUiGridPurchaseRandomItem')

function XUiPanelPurchaseRandomList:Refresh(randomGoods)
    self._RandomGoods = randomGoods
    self:RefreshList()
end

function XUiPanelPurchaseRandomList:RefreshList()
    -- 需要移除已经选择的部分
    local randomBoxChocies = self.Parent.RandomBoxChoices
    local showList = nil

    if not XTool.IsTableEmpty(randomBoxChocies) then
        showList = {}
        for i, v in pairs(self._RandomGoods) do
            if not table.contains(randomBoxChocies, v.Id) then
                table.insert(showList, v)
            end
        end
    else
        showList = self._RandomGoods
    end

    --- lua实例与gameobject映射字典，需要长期缓存
    if self._ItemMapInGroup == nil then
        self._ItemMapInGroup = {}
    end

    --- lua实例的索引列表，每次刷新都重新映射一遍
    if not XTool.IsTableEmpty(self._ItemInGroupList) then
        for i, v in pairs(self._ItemInGroupList) do
            v:Close()
        end
    end
    self._ItemInGroupList = {}

    XUiHelper.RefreshCustomizedList(self.PanelReward, self.PanelPropItem, showList and #showList or 0, function(index, go)
        local item = self._ItemMapInGroup[go]

        if not item then
            item = XUiGridPurchaseRandomItem.New(go, self)
            item:Init(self.Parent)
            item:SetRootUi(self.Parent)
            self._ItemMapInGroup[go] = item
        end

        item:OnRefresh(showList[index].RewardGoods)
        item:SetId(showList[index].Id)
        item:SetTogIsOn(false)
        item:Open()
        
        table.insert(self._ItemInGroupList, item)
    end)
end

function XUiPanelPurchaseRandomList:GetIsCanSubmit()
    return self.Parent:GetIsCanSubmit()
end

return XUiPanelPurchaseRandomList