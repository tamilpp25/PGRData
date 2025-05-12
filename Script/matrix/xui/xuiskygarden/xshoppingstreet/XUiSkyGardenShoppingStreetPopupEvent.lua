---@class XUiSkyGardenShoppingStreetPopupEvent : XLuaUi
---@field BtnCustomer XUiComponent.XUiButton
---@field BtnStore XUiComponent.XUiButton
---@field TxtDetail UnityEngine.UI.Text
---@field TxtDetailCustomer UnityEngine.UI.Text
---@field RImgStory UnityEngine.UI.RawImage
---@field PanelTop UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetPopupEvent = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetPopupEvent")
local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")

--region 生命周期
function XUiSkyGardenShoppingStreetPopupEvent:OnAwake()
    ---@type XUiSkyGardenShoppingStreetAsset
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelTop, self)
    self:_RegisterButtonClicks()

    local rt = self.PanelProgressBar.transform:GetComponent(typeof(CS.UnityEngine.RectTransform))
    self._RtBaseSize = rt.sizeDelta
    self._CustomerRt = self.ImgCustomer.transform:GetComponent(typeof(CS.UnityEngine.RectTransform))
end

function XUiSkyGardenShoppingStreetPopupEvent:OnStart(taskData)
    self._IsSelect = false
    self.BtnClose.gameObject:SetActive(self._IsSelect)

    self._EventData = taskData.EventData
    local eventId = self._EventData.EmergencyEventId
    self._Config = self._Control:GetCustomerEventEmergencyById(eventId)

    self.TxtTitle.text = self._Config.Desc
    if string.IsNilOrEmpty(self._Config.Icon) then
        self.RImgStory.gameObject:SetActive(false)
    else
        self.RImgStory:SetRawImage(self._Config.Icon)
        self.RImgStory.gameObject:SetActive(true)
    end
    self.TxtDetail.text = self._Config.OptionDescs[2]
    self.TxtDetailCustomer.text = self._Config.OptionDescs[1]
    self.PanelProgressBar.gameObject:SetActive(false)
end

function XUiSkyGardenShoppingStreetPopupEvent:UpdateBarInfo(percentage)
    local per = percentage
    if not per then
        local total = 0
        local right = 0
        for _, num in ipairs(self._EventData.EmergencyOptionTimesList or {80, 20}) do
            total = total + num
            right = num
        end
        per = (total - right) / total
    end
    local sizeData = self._CustomerRt.sizeDelta
    sizeData.x = self._RtBaseSize.x * per
    self._CustomerRt.sizeDelta = sizeData

    local leftNum = XTool.MathGetRoundingValue(per, 2) * 100
    self.TxtBtnCustomerNum.text = leftNum .. "%"
    self.TxtBtnStoreNum.text = (100 - leftNum) .. "%"

    self.PanelProgressBar.gameObject:SetActive(true)
end
--endregion

--region 按钮事件
function XUiSkyGardenShoppingStreetPopupEvent:OnBtnCustomerClick()
    if self._IsSelect then return end
    self:_DoEmergencyEventByIndex(1)
end

function XUiSkyGardenShoppingStreetPopupEvent:OnBtnStoreClick()
    if self._IsSelect then return end
    self:_DoEmergencyEventByIndex(2)
end

function XUiSkyGardenShoppingStreetPopupEvent:OnBtnCloseClick()
    self:Close()
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetPopupEvent:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnCustomer.CallBack = function() self:OnBtnCustomerClick() end
    self.BtnStore.CallBack = function() self:OnBtnStoreClick() end
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
end

function XUiSkyGardenShoppingStreetPopupEvent:_SetSelectState()
    self._IsSelect = true
    self.BtnClose.gameObject:SetActive(self._IsSelect)
    self.BtnCustomer:SetButtonState(CS.UiButtonState.Disable)
    self.BtnStore:SetButtonState(CS.UiButtonState.Disable)
end

function XUiSkyGardenShoppingStreetPopupEvent:_DoEmergencyEventByIndex(index)
    self:_SetSelectState()
    self._Control:DoEmergencyEvent(self._EventData.Id, index, self._Config.OptionBuffs[index])
    self:UpdateBarInfo()
end
--endregion

return XUiSkyGardenShoppingStreetPopupEvent
