--- 可肝卡池特殊的购买提示窗，用于特殊处理采购->可肝商店的跳转提示
---@class XUiGachaCanLiverDialog: XLuaUi
local XUiGachaCanLiverDialog = XLuaUiManager.Register(XLuaUi, 'UiGachaCanLiverDialog')

function XUiGachaCanLiverDialog:OnAwake()
    self:RegisterClickEvent(self.BtnBuy, self.OnBuyBtnClick)
    self:RegisterClickEvent(self.BtnJumpTo, self.OnJumpBtnClick)
    self:RegisterClickEvent(self.BtnCloseBg, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.Close)
end

function XUiGachaCanLiverDialog:OnStart(continueBuyCb, skipId)
    self._ContinueBuyCb = continueBuyCb
    self._SkipId = skipId
end

function XUiGachaCanLiverDialog:OnBuyBtnClick()
    self:Close()
    if self._ContinueBuyCb then
        self._ContinueBuyCb()
    end
end

function XUiGachaCanLiverDialog:OnJumpBtnClick()
    self:Close()
    if XFunctionManager.IsCanSkip(self._SkipId) then
        XFunctionManager.SkipInterface(self._SkipId)
    end
end

return XUiGachaCanLiverDialog