--- 福袋礼包的详情页弹窗
---@class XUiPurchaseRandomRewardTips: XLuaUi
local XUiPurchaseRandomRewardTips = XLuaUiManager.Register(XLuaUi, 'UiPurchaseRandomRewardTips')
local XUiPanelPurchaseRandomBaseDesc = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPurchaseRandomRewardTips/XUiPanelPurchaseRandomBaseDesc')
local XUiPanelPurchaseRandomGotDetail = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPurchaseRandomRewardTips/XUiPanelPurchaseRandomGotDetail')

function XUiPurchaseRandomRewardTips:OnAwake()
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
end

function XUiPurchaseRandomRewardTips:OnStart(data, showBuyTimes, defaultSelectIndex)
    self.Data = data
    self._ShowBuyTimes = showBuyTimes
    self:InitButtonGroup()
    self:InitPanels()

    defaultSelectIndex = XTool.IsNumberValid(defaultSelectIndex) and XMath.Clamp(defaultSelectIndex, 1, XTool.GetTableCount(self._PanelIndexMap)) or 1
    
    self.PanelTabTc:SelectIndex(defaultSelectIndex)
end

function XUiPurchaseRandomRewardTips:InitButtonGroup()
    self.PanelTabTc:InitBtns({ self.BtnTab1, self.BtnTab2 }, handler(self, self.OnBtnGroupSelect))
end

function XUiPurchaseRandomRewardTips:InitPanels()
    self._PanelBaseDesc = XUiPanelPurchaseRandomBaseDesc.New(self.PanelBaseDesc, self)
    self._PanelBaseDesc:Close()
    
    self._PanelGotDetail = XUiPanelPurchaseRandomGotDetail.New(self.PanelGotDetail, self, self.Data, self._ShowBuyTimes, self)
    self._PanelGotDetail:Close()
    
    self._PanelIndexMap = {
        self._PanelBaseDesc,
        self._PanelGotDetail,
    }
end

function XUiPurchaseRandomRewardTips:OnBtnGroupSelect(index, force)
    if self._CurIndex == index and not force then
        return
    end

    if self._CurPanel then
        self._CurPanel:Close()
        self._CurPanel = nil
    end
    
    self._CurIndex = index

    self._CurPanel = self._PanelIndexMap[self._CurIndex]

    self._CurPanel:Open()
end

return XUiPurchaseRandomRewardTips