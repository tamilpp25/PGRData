--- 福袋礼包的选择界面
---@class XUiPurchaseRandomBoxSelection: XLuaUi
local XUiPurchaseRandomBoxSelection = XLuaUiManager.Register(XLuaUi, 'UiPurchaseRandomBoxSelection')
local XUiPanelPurchaseRandomList = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPurchaseRandomBoxSelection/XUiPanelPurchaseRandomList')
local XUiPanelPurchaseRandomSelectedList = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPurchaseRandomBoxSelection/XUiPanelPurchaseRandomSelectedList')

function XUiPurchaseRandomBoxSelection:OnAwake()
    self.BtnClose.CallBack = handler(self, self.CloseWithCancel)
    self.BtnTanchuangClose.CallBack = handler(self, self.CloseWithCancel)
    self.BtnHelp.CallBack = handler(self, self.OnTipsClick)
    self.BtnBuy.CallBack = handler(self, self.CloseWithSubmit)
end

function XUiPurchaseRandomBoxSelection:OnStart(data, showBuyTimes)
    self.Data = data
    self._ShowBuyTimes = showBuyTimes
    self:InitSelectionData()

    self._PanelSelectedList = XUiPanelPurchaseRandomSelectedList.New(self.ListSelectedReward, self, self.Data.SelectDataForClient.RandomGoods)
    self._PanelSelectedList:Open()
    
    self._PanelList = XUiPanelPurchaseRandomList.New(self.ListRewards, self)
    self._PanelList:Open()
    self._PanelList:Refresh(self.Data.SelectDataForClient.RandomGoods)
    
    self:TryForcePopTips()
end

function XUiPurchaseRandomBoxSelection:OnEnable()
    self:RefreshListShow()
end

function XUiPurchaseRandomBoxSelection:CloseWithCancel()
    self:Close()
end

function XUiPurchaseRandomBoxSelection:CloseWithSubmit()
    if self._CanSubmit then
        self:SyncChoices()
        self:Close()
    end
end

--- 从选择数据中拷贝一份在该界面使用
function XUiPurchaseRandomBoxSelection:InitSelectionData()
    ---@type XPurchaseSelectionData
    local selectionData = XDataCenter.PurchaseManager.GetPurchaseSelectionData()

    if XTool.IsTableEmpty(selectionData.RandomBoxChoices) then
        self.RandomBoxChoices = nil    
    else
        self.RandomBoxChoices = XTool.Clone(selectionData.RandomBoxChoices)
    end
end

function XUiPurchaseRandomBoxSelection:RefreshListShow()
    self:CheckSelectComplete()
    self._PanelSelectedList:RefreshList()
    self._PanelList:RefreshList()
end

function XUiPurchaseRandomBoxSelection:CheckSelectComplete()
    local selectedCount = XTool.GetTableCount(self.RandomBoxChoices)
    local needSelectCount = self.Data.SelectDataForClient.RandomSelectCount

    self._CanSubmit = selectedCount == needSelectCount
    self.BtnBuy:SetButtonState(self._CanSubmit and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    if self._CanSubmit then
        self.BtnBuy:SetNameByGroup(0, XUiHelper.GetText('PurchaseRandomBoxValidSubmitTips'))
    else
        self.BtnBuy:SetNameByGroup(0, XUiHelper.GetText('PurchaseRandomBoxInvalidSubmitTips', needSelectCount - selectedCount))
    end
    
    self.TxtTitle.text = XUiHelper.GetText('PurchaseRandomBoxProgressTitle', needSelectCount, selectedCount, needSelectCount)
end

function XUiPurchaseRandomBoxSelection:OnTipsClick()
    XLuaUiManager.Open('UiPurchaseRandomRewardTips', self.Data, self._ShowBuyTimes)
end

function XUiPurchaseRandomBoxSelection:TryForcePopTips()
    if XDataCenter.PurchaseManager.CheckNeedForcePopTips() then
        XLuaUiManager.Open('UiPurchaseRandomRewardTips', self.Data, self._ShowBuyTimes, XPurchaseConfigs.UiRandomRewardTipsTabIndex.GotDetail)
    end
end

function XUiPurchaseRandomBoxSelection:GetIsCanSubmit()
    return self._CanSubmit
end

function XUiPurchaseRandomBoxSelection:SetRandomChoice(templateId, isjoin)
    if self.RandomBoxChoices == nil then
        self.RandomBoxChoices = {}
    end

    local isin, index = table.contains(self.RandomBoxChoices, templateId)

    if isjoin then
        if isin then
            XLog.Error(tostring(templateId)..'已经在选择列表中，但仍尝试加入选择')
        else
            table.insert(self.RandomBoxChoices, templateId)
        end
    else
        if not isin then
            XLog.Error(tostring(templateId)..'不在选择列表中，但尝试移除选择')
        else
            table.remove(self.RandomBoxChoices, index)
        end
    end
end

function XUiPurchaseRandomBoxSelection:CheckRandomChoiceIsSelect(templateId)
    if self.RandomBoxChoices == nil then
        return false
    end

    return table.contains(self.RandomBoxChoices, templateId)
end

--- 将该界面的选择情况同步到礼包选择数据中
function XUiPurchaseRandomBoxSelection:SyncChoices()
    XDataCenter.PurchaseManager.ClearRandomBoxChoices()
    
    if not XTool.IsTableEmpty(self.RandomBoxChoices) then
        for i, v in ipairs(self.RandomBoxChoices) do
            XDataCenter.PurchaseManager.SetRandomChoice(v, true)
        end
    end
end

return XUiPurchaseRandomBoxSelection