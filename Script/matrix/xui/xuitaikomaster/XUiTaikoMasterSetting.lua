---@class XUiTaikoMasterSetting:XLuaUi
local XUiTaikoMasterSetting = XLuaUiManager.Register(XLuaUi, "UiTaikoMasterSetting")

function XUiTaikoMasterSetting:Ctor()
    self._IsSettingChanged = false
    self._SettingAppearScale = XDataCenter.TaikoMasterManager.GetSettingAppearScale()
    self._SettingJudgeScale = XDataCenter.TaikoMasterManager.GetSettingJudgeScale()
end

function XUiTaikoMasterSetting:OnStart(isPlayEnableAnimation)
    self:RegisterButtonClick()
    self:InitSlider()
    if isPlayEnableAnimation then
        self:PlayAnimation("Enable")
        self.BtnTimeline.gameObject:SetActiveEx(true)
    end
end

function XUiTaikoMasterSetting:RequestSaveSetting()
    if self._IsSettingChanged then
        XDataCenter.TaikoMasterManager.RequestSaveSetting(self._SettingAppearScale, self._SettingJudgeScale)
        self._IsSettingChanged = false
    end
end

function XUiTaikoMasterSetting:RegisterButtonClick()
    self:RegisterClickEvent(self.BtnTcanchaungBlack, self.EnterTrainingStage)
    self:RegisterClickEvent(self.BtnBack, self.CloseAndRequest)
end

function XUiTaikoMasterSetting:CloseAndRequest()
    self:RequestSaveSetting()
    self:Close()
end

function XUiTaikoMasterSetting:EnterTrainingStage()
    self:RequestSaveSetting()
    XDataCenter.TaikoMasterManager.OpenUiRoom(XDataCenter.TaikoMasterManager.GetSettingStageId())
end

function XUiTaikoMasterSetting:InitSlider()
    local XUiTaikoMasterSlider = require("XUi/XUiTaikoMaster/XUiTaikoMasterSlider")
    local sliderAppear = XUiTaikoMasterSlider.New(self.PanelVisuals)
    sliderAppear:SetData(XTaikoMasterConfigs.GetSettingAppearScale())
    sliderAppear:SetValue(self._SettingAppearScale)
    sliderAppear:SetOnChanged(
        function()
            self._IsSettingChanged = true
            self._SettingAppearScale = sliderAppear:GetValue()
        end
    )

    local sliderJudge = XUiTaikoMasterSlider.New(self.PanelOffset)
    sliderJudge:SetData(XTaikoMasterConfigs.GetSettingJudgeScale())
    sliderJudge:SetValue(self._SettingJudgeScale)
    sliderJudge:SetOnChanged(
        function()
            self._IsSettingChanged = true
            self._SettingJudgeScale = sliderJudge:GetValue()
        end
    )
end

return XUiTaikoMasterSetting
