---@class XUiBigWorldSetPanelOther : XBigWorldUi
---@field SliderAdaptation UnityEngine.UI.Slider
---@field TxtAdaptation UnityEngine.UI.Text
---@field SafeAreaContentPanel XUiSafeAreaAdapter
---@field ParentUi XUiBigWorldSet
---@field _Control XBigWorldSetControl
local XUiBigWorldSetPanelOther = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldSetPanelOther")

function XUiBigWorldSetPanelOther:OnAwake()
    ---@type XBWOtherSetting
    self._Setting = false

    self:_RegisterButtonClicks()
end

function XUiBigWorldSetPanelOther:OnStart()
    self._Setting = self._Control:GetSettingBySetType(XEnumConst.BWSetting.SetType.Other)
end

function XUiBigWorldSetPanelOther:OnEnable()
    self:_Refresh()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldSetPanelOther:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldSetPanelOther:OnDestroy()
end

function XUiBigWorldSetPanelOther:OnSliderAdaptationValueChanged(value)
    if value ~= self._Setting:GetScreenOffValue() then
        self._Setting:SetScreenOffValue(value)
        self:_ChangeAdaptation()
    end
end

function XUiBigWorldSetPanelOther:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterSliderChangeEvent(self, self.SliderAdaptation, self.OnSliderAdaptationValueChanged, true)
end

function XUiBigWorldSetPanelOther:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESET, self._Refresh, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESTORE, self._Refresh, self)
end

function XUiBigWorldSetPanelOther:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESET, self._Refresh, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESTORE, self._Refresh, self)
end

function XUiBigWorldSetPanelOther:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldSetPanelOther:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldSetPanelOther:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldSetPanelOther:_ChangeAdaptation()
    self.ParentUi:UpdateSpecialScreenOff()
    self._Control:RefreshSpecialScreenOff(self.SafeAreaContentPanel)
end

function XUiBigWorldSetPanelOther:_Refresh()
    self.SliderAdaptation.value = self._Setting:GetScreenOffValue()
end

return XUiBigWorldSetPanelOther
