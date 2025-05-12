local XUiPanelRogueSimCommonMainCity = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimCommonMainCity")
local XUiPanelRogueSimCommonOtherCity = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimCommonOtherCity")
local XUiPanelRogueSimCasinoSettlement = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimCasinoSettlement")
---@class XUiRogueSimPopupCommonHorizontal : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimPopupCommonHorizontal = XLuaUiManager.Register(XLuaUi, "UiRogueSimPopupCommonHorizontal")

function XUiRogueSimPopupCommonHorizontal:OnAwake()
    self.PanelOtherCity.gameObject:SetActive(false)
    self.PanelMainCity.gameObject:SetActive(false)
    self.PanelCasinoSettlement.gameObject:SetActive(false)
    self:RegisterUiEvents()
end

---@param data { IsMainCity:boolean, CityId:number, EventGambleId:number }
function XUiRogueSimPopupCommonHorizontal:OnStart(data)
    self.Data = data
    if data.IsMainCity then
        self:OpenMainCityPopup()
    elseif XTool.IsNumberValid(data.CityId) then
        self:OpenOtherCityPopup(data.CityId)
    elseif XTool.IsNumberValid(data.EventGambleId) then
        self:OpenCasinoSettlementPopup(data.EventGambleId)
    end
end

-- 打开主城升级弹框
function XUiRogueSimPopupCommonHorizontal:OpenMainCityPopup()
    if not self.PanelMainCityUi then
        ---@type XUiPanelRogueSimCommonMainCity
        self.PanelMainCityUi = XUiPanelRogueSimCommonMainCity.New(self.PanelMainCity, self)
    end
    self.PanelMainCityUi:Open()
    self.PanelMainCityUi:Refresh()
end

-- 打开其他城市升级弹框
function XUiRogueSimPopupCommonHorizontal:OpenOtherCityPopup(cityId)
    if not self.PanelOtherCityUi then
        ---@type XUiPanelRogueSimCommonOtherCity
        self.PanelOtherCityUi = XUiPanelRogueSimCommonOtherCity.New(self.PanelOtherCity, self)
    end
    self.PanelOtherCityUi:Open()
    self.PanelOtherCityUi:Refresh(cityId)
end

-- 打开赌场结算弹框
function XUiRogueSimPopupCommonHorizontal:OpenCasinoSettlementPopup(eventGambleId)
    if not self.PanelCasinoSettlementUi then
        ---@type XUiPanelRogueSimCasinoSettlement
        self.PanelCasinoSettlementUi = XUiPanelRogueSimCasinoSettlement.New(self.PanelCasinoSettlement, self)
    end
    self.PanelCasinoSettlementUi:Open()
    -- 隐藏关闭按钮
    self.BtnClose.gameObject:SetActive(false)
    self.TxtClose.gameObject:SetActive(false)
    self.PanelCasinoSettlementUi:Refresh(eventGambleId)
end

function XUiRogueSimPopupCommonHorizontal:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiRogueSimPopupCommonHorizontal:OnBtnCloseClick()
    self._Control:CheckNeedShowNextPopup(self.Name, true)
end

return XUiRogueSimPopupCommonHorizontal
