---@class XUiGachaCanLiverMain: XLuaUi
---@field _Control XGachaCanLiverControl
local XUiGachaCanLiverMain = XLuaUiManager.Register(XLuaUi, 'UiGachaCanLiverMain')

local XUiPanelGachaLiverDrawBase = require('XUi/XUiGachaCanLiver/XUiGachaCanLiverMain/XUiPanelGachaLiverDrawBase')

function XUiGachaCanLiverMain:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
end

function XUiGachaCanLiverMain:OnStart(gachaId, isTimelimit)
    self._PanelCommonDraw = XUiPanelGachaLiverDrawBase.New(self.UiGachaCanLiverMain, self, gachaId, isTimelimit, self)
    self._PanelCommonDraw:Open()
end

return XUiGachaCanLiverMain