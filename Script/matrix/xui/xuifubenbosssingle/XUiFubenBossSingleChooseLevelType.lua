---@class XUiFubenBossSingleChooseLevelType : XLuaUi
---@field BtnHigh XUiComponent.XUiButton
---@field BtnExtreme XUiComponent.XUiButton
---@field BtnConfirm XUiComponent.XUiButton
---@field BtnCancel XUiComponent.XUiButton
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field BtnHighHelp XUiComponent.XUiButton
---@field BtnExtremeHelp XUiComponent.XUiButton
local XUiFubenBossSingleChooseLevelType = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleChooseLevelType")
local XUiButton = require("XUi/XUiCommon/XUiButton")
local BOSS_MAX_COUNT = 3

function XUiFubenBossSingleChooseLevelType:Ctor()
    self._HighBossList = nil
    self._ExtremeBossList = nil
    self._LevelType = nil
    ---@type XUiButtonLua
    self._BtnHighProxy = nil
    ---@type XUiButtonLua
    self._BtnExtremeProxy = nil
end

function XUiFubenBossSingleChooseLevelType:OnAwake()
    self._BtnHighProxy = XUiButton.New(self.BtnHigh)
    self._BtnExtremeProxy = XUiButton.New(self.BtnExtreme)
    self:_RegisterButtonListeners()
end

function XUiFubenBossSingleChooseLevelType:OnStart(highBossList, extremeBossList)
    self._HighBossList = highBossList
    self._ExtremeBossList = extremeBossList
    self:_InitBoss()
end

function XUiFubenBossSingleChooseLevelType:_RegisterButtonListeners()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close, true)
    self:RegisterClickEvent(self.BtnCancel, self.Close, true)
    self:RegisterClickEvent(self.BtnHigh, self.OnBtnHighClick, true)
    self:RegisterClickEvent(self.BtnExtreme, self.OnBtnExtremeClick, true)
    self:RegisterClickEvent(self.BtnConfirm, self.OnClickBtnConfirm, true)
    self:RegisterClickEvent(self.BtnHighHelp, self.OnBtnHighHelpClick, true)
    self:RegisterClickEvent(self.BtnExtremeHelp, self.OnBtnExtremeHelpClick, true)
end

function XUiFubenBossSingleChooseLevelType:OnBtnHighClick()
    self:_SelectLevelType(XFubenBossSingleConfigs.LevelType.High)
end

function XUiFubenBossSingleChooseLevelType:OnBtnExtremeClick()
    self:_SelectLevelType(XFubenBossSingleConfigs.LevelType.Extreme)
end

function XUiFubenBossSingleChooseLevelType:OnClickBtnConfirm()
    if not self._LevelType then
        XUiManager.TipText("BossSingleChooseLevelTypeEmpty")
        return
    end

    XDataCenter.FubenBossSingleManager.ReqChooseLevelType(self._LevelType)
    self:Close()
end

function XUiFubenBossSingleChooseLevelType:OnBtnHighHelpClick()
    self:_LevelHelpClick(XFubenBossSingleConfigs.LevelType.High)
end

function XUiFubenBossSingleChooseLevelType:OnBtnExtremeHelpClick()
    self:_LevelHelpClick(XFubenBossSingleConfigs.LevelType.Extreme)
end

function XUiFubenBossSingleChooseLevelType:_LevelHelpClick(levelType)
    local bossList = nil

    if levelType == XFubenBossSingleConfigs.LevelType.High then
        bossList = self._HighBossList
    else
        bossList = self._ExtremeBossList
    end

    XLuaUiManager.Open("UiFubenBossSingleChooseDetail", bossList)
end

function XUiFubenBossSingleChooseLevelType:_SelectLevelType(levelType)
    self._LevelType = levelType

    if levelType == XFubenBossSingleConfigs.LevelType.High then
        self.BtnHigh:SetButtonState(CS.UiButtonState.Select)
        self.BtnExtreme:SetButtonState(CS.UiButtonState.Normal)
    elseif levelType == XFubenBossSingleConfigs.LevelType.Extreme then
        self.BtnHigh:SetButtonState(CS.UiButtonState.Normal)
        self.BtnExtreme:SetButtonState(CS.UiButtonState.Select)
    end
end

function XUiFubenBossSingleChooseLevelType:_InitBoss()
    if not XTool.IsTableEmpty(self._HighBossList) and not XTool.IsTableEmpty(self._ExtremeBossList) then
        for i = 1, #self._HighBossList do
            local bossInfo = XDataCenter.FubenBossSingleManager.GetBossCurDifficultyInfo(self._HighBossList[i], 1)

            self._BtnHighProxy:SetRawImage("ImgBoss" .. i, bossInfo.bossIcon)
            self._BtnHighProxy:SetActive("ImgBoss" .. i, true)
        end
        for i = #self._HighBossList + 1, BOSS_MAX_COUNT do
            self._BtnHighProxy:SetActive("ImgBoss" .. i, false)
        end
        for i = 1, #self._ExtremeBossList do
            local bossInfo = XDataCenter.FubenBossSingleManager.GetBossCurDifficultyInfo(self._ExtremeBossList[i], 1)

            self._BtnExtremeProxy:SetRawImage("ImgBoss" .. i, bossInfo.bossIcon)
        end
        for i = #self._ExtremeBossList + 1, BOSS_MAX_COUNT do
            self._BtnExtremeProxy:SetActive("ImgBoss" .. i, false)
        end
    end
end

return XUiFubenBossSingleChooseLevelType
