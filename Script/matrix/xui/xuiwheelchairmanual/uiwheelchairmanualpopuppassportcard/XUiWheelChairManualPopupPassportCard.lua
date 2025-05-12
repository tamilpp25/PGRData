---@class XUiWheelChairManualPopupPassportCard: XLuaUi
---@field _Control XWheelchairManualControl
local XUiWheelChairManualPopupPassportCard = XLuaUiManager.Register(XLuaUi, 'UiWheelChairManualPopupPassportCard')
local XUiPanelWheelChairManualPopupPassportCard = require('XUi/XUiWheelchairManual/UiWheelChairManualPopupPassportCard/XUiPanelWheelChairManualPopupPassportCard')

function XUiWheelChairManualPopupPassportCard:OnAwake()
    self.BtnClose.CallBack = handler(self, self.Close)
end

function XUiWheelChairManualPopupPassportCard:OnStart()
    local url = self._Control:GetCurActivityPassportCardPrefabAddress()

    if not string.IsNilOrEmpty(url) then
        local uiGo = self.PanelContent:LoadPrefab(url)
        XUiHelper.SetCanvasesSortingOrder(uiGo.transform)
        self._SubPanel = XUiPanelWheelChairManualPopupPassportCard.New(uiGo, self)
        self._SubPanel:Open()
    end

    if XMVCA.XWheelchairManual:SetSubActivityIsOld(XEnumConst.WheelchairManual.TabType.BPReward) then
        XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT)
    end
end

return XUiWheelChairManualPopupPassportCard