---@class XUiPlanetPopover:XLuaUi
local XUiPlanetPopover = XLuaUiManager.Register(XLuaUi, "UiPlanetPopover")

function XUiPlanetPopover:Ctor()
end

function XUiPlanetPopover:OnAwake()
    self:RegisterClickEvent(self.BtnConfirm, self._OnClickSure)
    self:RegisterClickEvent(self.BtnCancel, self._OnClickClose)
    self:RegisterClickEvent(self.BtnClose, self._OnClickClose)
    self:RegisterClickEvent(self.BtnTanchuangClose, self._OnClickClose)
    self:RegisterClickEvent(self.BtnHint, self._OnIsNotTip)
end

function XUiPlanetPopover:OnStart(buildId, count, sureCb, closeCb)
    self.SureCb = sureCb or false
    self.CloseCb = closeCb or false

    self:Refresh(buildId, count)
end

function XUiPlanetPopover:Refresh(buildId, count)
    if self.TxtTitle02 then
        self.TxtTitle02.text = "X" .. XPlanetTalentConfigs.GetTalentBuildingBuyPrices(buildId) * count
    end
    if self.TxtTitle04 then
        self.TxtTitle04.text = XPlanetTalentConfigs.GetTalentBuildingName(buildId)
    end
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.PlanetRunningTalent))
    end
end

function XUiPlanetPopover:_OnClickClose()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiPlanetPopover:_OnClickSure()
    self:Close()
    if self.SureCb then
        self.SureCb()
    end
end

function XUiPlanetPopover:_OnIsNotTip()
    if self.BtnHint.isOn then
        XDataCenter.PlanetManager.SetIsReformBuyBuildTip(true)
    else
        XDataCenter.PlanetManager.SetIsReformBuyBuildTip(false)
    end
end

return XUiPlanetPopover
