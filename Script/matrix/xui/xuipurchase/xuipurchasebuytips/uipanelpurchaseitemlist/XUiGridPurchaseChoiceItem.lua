local XUiPurchaseLBTipsListItem = require("XUi/XUiPurchase/XUiPurchaseLBTipsListItem")

---@class XUiGridPurchaseChoiceItem: XUiPurchaseLBTipsListItem
local XUiGridPurchaseChoiceItem = XClass(XUiPurchaseLBTipsListItem, 'XUiGridPurchaseChoiceItem')

function XUiGridPurchaseChoiceItem:OnStart()
    if self.GridNone then
        self.GridNone.CallBack = handler(self, self.OpenChoicePanel)
    end

    if self.Tog then
        self.Tog.onValueChanged:AddListener(handler(self, self.OnTogClick))
    end
end

function XUiGridPurchaseChoiceItem:SetShowHistroySelection(isShow)
    self.GridItemUi.GameObject:SetActive(isShow)

    if self.GridNone then
        self.GridNone.gameObject:SetActive(not isShow)
    end
end

function XUiGridPurchaseChoiceItem:SetIsSelected(isSelect)
    self.GridNone:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

--region 自选礼包选中位相关

---自选礼包空位所属的组的索引
function XUiGridPurchaseChoiceItem:SetGroupIndex(groupIndex)
    self.GroupIndex = groupIndex
end

function XUiGridPurchaseChoiceItem:SetEnableSelect(enable)
    if enable then
        self.GridItemUi:SetProxyClickFunc(handler(self, self.OpenChoicePanel))
    else
        self.GridItemUi:SetProxyClickFunc(nil)
    end
end

function XUiGridPurchaseChoiceItem:SetIsNormalAllOwn(isNormalAllOwn)
    self._IsNormalAllOwn = isNormalAllOwn
end

function XUiGridPurchaseChoiceItem:OpenChoicePanel()
    if self._IsNormalAllOwn then
        return
    end
    self.Parent:ShowSelectList(self.GroupIndex, self)
end

--endregion

--region 自选礼包单选组相关

function XUiGridPurchaseChoiceItem:SetToggleState(isOn)
    if self.Tog.isOn ~= isOn then
        self._IgnoreTogChange = true
    end
    self.Tog.isOn = isOn
end

--- 自选礼包物品设置所属的组和Id
function XUiGridPurchaseChoiceItem:SetGroupId(groupId, id)
    self.GroupId = groupId
    self.Id = id
    
    self:SetToggleState(XDataCenter.PurchaseManager.CheckSelfChoiceIsSelect(self.GroupId, self.Id))
end

function XUiGridPurchaseChoiceItem:OnTogClick(isOn)
    if self._IgnoreTogChange then
        self._IgnoreTogChange = false
        return
    end
    
    if XDataCenter.PurchaseManager.CheckSelfChoiceIsSelect(self.GroupId, self.Id) then
        XDataCenter.PurchaseManager.SetSelfChoice(self.GroupId, nil)
    else
        XDataCenter.PurchaseManager.SetSelfChoice(self.GroupId, self.Id)
    end
    
    self.Parent:OnGroupSelect()
end
--endregion

--region 福袋道具相关
--- 设置福袋道具抽取结果展示
function XUiGridPurchaseChoiceItem:SetItemStatus(isGet, isSelect, isIgnore)
    self.ImgGetOutPermit.gameObject:SetActiveEx(not isIgnore and isGet)
    self.ImgNotGetPermit.gameObject:SetActiveEx(not isIgnore and not isGet and isSelect)
    self.ImgNotSelected.gameObject:SetActiveEx(not isIgnore and not isSelect)
end
--endregion

return XUiGridPurchaseChoiceItem