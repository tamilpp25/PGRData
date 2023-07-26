local XUiPanelFeature = require("XUi/XUiEscape/XUiPanelFeature")

--大逃杀2期进入战斗
local XUiEscape2EnterFight = XLuaUiManager.Register(XLuaUi, "UiEscape2EnterFight")

function XUiEscape2EnterFight:OnAwake()
    self:AddBtnClickListener()
end

function XUiEscape2EnterFight:OnStart(chapterId, layerId, stageId)
    self._ChapterId = chapterId
    self._StageId = stageId
    self._LayerId = layerId
    self._EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    self._FeaturePanel = XUiPanelFeature.New(self.PanelBuffList)
end

function XUiEscape2EnterFight:OnEnable()
    self:UpdateText()
    self:UpdateLock()
    self:UpdateBuff()
end

function XUiEscape2EnterFight:OnDisable()
end

--region UiRefresh
function XUiEscape2EnterFight:UpdateLock()
    local layerState, challengeConditionDesc = XDataCenter.EscapeManager.GetLayerChallengeState(self._ChapterId, self._LayerId)

    self.TxtTips.gameObject:SetActiveEx(layerState == XEscapeConfigs.LayerState.Lock)
    self.BtnEnterArena.gameObject:SetActiveEx(layerState == XEscapeConfigs.LayerState.Now)
    local challengeStateDesc = ""
    local isStageClear = self._EscapeData:IsCurChapterStageClear(self._StageId)
    if isStageClear then
        challengeStateDesc = XUiHelper.GetText("ClearStage")
    elseif layerState == XEscapeConfigs.LayerState.Lock then
        challengeStateDesc = challengeConditionDesc
    end
    self.TxtTips.text = challengeStateDesc
end

function XUiEscape2EnterFight:UpdateText()
    local stageDesc = XDataCenter.FubenManager.GetStageDes(self._StageId)
    self.TxtArenatName.text = XFubenConfigs.GetStageName(self._StageId)
    self.TxtArenaDetail.text = XUiHelper.ConvertLineBreakSymbol(stageDesc)
end

function XUiEscape2EnterFight:UpdateBuff()
    local stageFightEvent = XFubenConfigs.GetStageFightEventByStageId(self._StageId)
    self._FeaturePanel:Refresh(stageFightEvent and stageFightEvent.FightEventIds)
end
--endregion

--region BtnListener
function XUiEscape2EnterFight:AddBtnClickListener()
    self:RegisterClickEvent(self.BtnMaskB, self.Close)
    self:RegisterClickEvent(self.BtnEnterArena, self.OnBtnEnterClick)
end

function XUiEscape2EnterFight:OnBtnEnterClick()
    XDataCenter.EscapeManager.OpenBattleRoleRoom(self._ChapterId, self._StageId)
end
--endregion