---@class XUiPanelPurchaseRandomSelectedList: XUiNode
local XUiPanelPurchaseRandomSelectedList = XClass(XUiNode, 'XUiPanelPurchaseRandomSelectedList')
local XUiGridPurchaseRandomItem = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPurchaseRandomBoxSelection/XUiGridPurchaseRandomItem')

function XUiPanelPurchaseRandomSelectedList:OnStart(randomGoods)
    self._RandomGoods = randomGoods
end

function XUiPanelPurchaseRandomSelectedList:RefreshList()
    local selectedList = self.Parent.RandomBoxChoices

    local isEmpty = XTool.IsTableEmpty(selectedList)
    self.ImgNone.gameObject:SetActiveEx(isEmpty)
    self.PanelHksd.gameObject:SetActiveEx(not isEmpty)
    
    --- 刷新前隐藏之前的格子
    if not XTool.IsTableEmpty(self._ItemInGroupList) then
        for i, v in pairs(self._ItemInGroupList) do
            v:Close()
        end
    end
    
    if isEmpty then
        self._ItemInGroupList = nil
        return
    end
    
    --- lua实例与gameobject映射字典，需要长期缓存
    if self._ItemMapInGroup == nil then
        self._ItemMapInGroup = {}
    end

    --- lua实例的索引列表，每次刷新都重新映射一遍
    self._ItemInGroupList = {}

    XUiHelper.RefreshCustomizedList(self.PanelReward, self.PanelPropItem, selectedList and #selectedList or 0, function(index, go)
        local item = self._ItemMapInGroup[go]

        if not item then
            item = XUiGridPurchaseRandomItem.New(go, self)
            item:Init(self.Parent)
            item:SetRootUi(self.Parent)
            self._ItemMapInGroup[go] = item
        end
        
        local id = selectedList[index]
        for i, v in pairs(self._RandomGoods) do
            if v.Id == id then
                item:OnRefresh(v.RewardGoods)
                item:SetId(id)
                item:SetTogIsOn(true)
                item:Open()
                break
            end
        end
        
        table.insert(self._ItemInGroupList, item)
    end)
end

return XUiPanelPurchaseRandomSelectedList