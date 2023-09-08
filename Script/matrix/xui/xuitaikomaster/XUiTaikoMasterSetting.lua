---@class XUiTaikoMasterSetting:XLuaUi
---@field _Control XTaikoMasterControl
local XUiTaikoMasterSetting = XLuaUiManager.Register(XLuaUi, "UiTaikoMasterSetting")

function XUiTaikoMasterSetting:OnStart(isPlayEnableAnimation)
    local uiData = self._Control:GetUiData()
    self._IsSettingChanged = false
    self._SettingAppearScale = uiData.SettingAppearScale
    self._SettingJudgeScale = uiData.SettingJudgeScale
    
    self:InitSlider()
    self:RegisterButtonClick()
    if isPlayEnableAnimation then
        self:PlayAnimation("Enable")
        self.BtnTimeline.gameObject:SetActiveEx(true)
    end
end

function XUiTaikoMasterSetting:RequestSaveSetting()
    if self._IsSettingChanged then
        self._Control:RequestSaveSetting(self._SettingAppearScale, self._SettingJudgeScale)
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
    local uiData = self._Control:GetUiData()
    self:RequestSaveSetting()
    self._Control:OpenBattleRoom(uiData.SettingStageId)
end

function XUiTaikoMasterSetting:InitSlider()
    local XUiTaikoMasterSlider = require("XUi/XUiTaikoMaster/XUiTaikoMasterSlider")
    local sliderAppear = XUiTaikoMasterSlider.New(self.PanelVisuals)
    sliderAppear:SetData(self._Control:GetSettingAppearScale())
    sliderAppear:SetValue(self._SettingAppearScale)
    sliderAppear:SetOnChanged(
        function()
            self._IsSettingChanged = true
            self._SettingAppearScale = sliderAppear:GetValue()
        end
    )

    local sliderJudge = XUiTaikoMasterSlider.New(self.PanelOffset)
    sliderJudge:SetData(self._Control:GetSettingJudgeScale())
    sliderJudge:SetValue(self._SettingJudgeScale)
    sliderJudge:SetOnChanged(
        function()
            self._IsSettingChanged = true
            self._SettingJudgeScale = sliderJudge:GetValue()
        end
    )
end

return XUiTaikoMasterSetting
