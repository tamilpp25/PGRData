---@class XUiFubenBossSingleChooseLevelType : XLuaUi
---@field BtnHigh XUiComponent.XUiButton
---@field BtnExtreme XUiComponent.XUiButton
---@field BtnConfirm XUiComponent.XUiButton
---@field BtnCancel XUiComponent.XUiButton
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field BtnHighHelp XUiComponent.XUiButton
---@field BtnExtremeHelp XUiComponent.XUiButton
---@field _Control XFubenBossSingleControl
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
    self:_SelectLevelType(XEnumConst.BossSingle.LevelType.High)
end

function XUiFubenBossSingleChooseLevelType:OnBtnExtremeClick()
    self:_SelectLevelType(XEnumConst.BossSingle.LevelType.Extreme)
end

function XUiFubenBossSingleChooseLevelType:OnClickBtnConfirm()
    if not self._LevelType then
        XUiManager.TipText("BossSingleChooseLevelTypeEmpty")
        return
    end

    XMVCA.XFubenBossSingle:RequestChooseLevelType(self._Control:GetLevelTypeByGradeType(self._LevelType))
    self:Close()
end

function XUiFubenBossSingleChooseLevelType:OnBtnHighHelpClick()
    self:_LevelHelpClick(XEnumConst.BossSingle.LevelType.High)
end

function XUiFubenBossSingleChooseLevelType:OnBtnExtremeHelpClick()
    self:_LevelHelpClick(XEnumConst.BossSingle.LevelType.Extreme)
end

function XUiFubenBossSingleChooseLevelType:_LevelHelpClick(levelType)
    local bossList = nil

    if levelType == XEnumConst.BossSingle.LevelType.High then
        bossList = self._HighBossList
    else
        bossList = self._ExtremeBossList
    end

    XLuaUiManager.Open("UiFubenBossSingleChooseDetail", bossList)
end

function XUiFubenBossSingleChooseLevelType:_SelectLevelType(levelType)
    self._LevelType = levelType

    if levelType == XEnumConst.BossSingle.LevelType.High then
        self.BtnHigh:SetButtonState(CS.UiButtonState.Select)
        self.BtnExtreme:SetButtonState(CS.UiButtonState.Normal)
    elseif levelType == XEnumConst.BossSingle.LevelType.Extreme then
        self.BtnHigh:SetButtonState(CS.UiButtonState.Normal)
        self.BtnExtreme:SetButtonState(CS.UiButtonState.Select)
    end
end

function XUiFubenBossSingleChooseLevelType:_InitBoss()
    local bossSingle = self._Control:GetBossSingleData()

    if not XTool.IsTableEmpty(self._HighBossList) and not XTool.IsTableEmpty(self._ExtremeBossList) then
        for i = 1, #self._HighBossList do
            local bossIcon = self._Control:GetBossIcon(self._HighBossList[i])

            self._BtnHighProxy:SetRawImage("ImgBoss" .. i, bossIcon)
            self._BtnHighProxy:SetActive("ImgBoss" .. i, true)
        end
        for i = #self._HighBossList + 1, BOSS_MAX_COUNT do
            self._BtnHighProxy:SetActive("ImgBoss" .. i, false)
        end
        for i = 1, #self._ExtremeBossList do
            local bossIcon = self._Control:GetBossIcon(self._ExtremeBossList[i])

            self._BtnExtremeProxy:SetRawImage("ImgBoss" .. i, bossIcon)
        end
        for i = #self._ExtremeBossList + 1, BOSS_MAX_COUNT do
            self._BtnExtremeProxy:SetActive("ImgBoss" .. i, false)
        end
    end
    local isNewVersion = bossSingle and bossSingle:IsNewVersion() or false

    self.TxtTips.gameObject:SetActiveEx(isNewVersion)
    if isNewVersion then
        self.TxtTips.text = XUiHelper.GetText("BossSingleModeTips")
    end
end

return XUiFubenBossSingleChooseLevelType
