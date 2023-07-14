local XUiPanelActiveBuff = require("XUi/XUiNewRoomSingle/XUiPanelActiveBuff")
local XUiPanelActiveBuffTip = require("XUi/XUiNewRoomSingle/XUiPanelActiveBuffTip")
local XUiPanelChangeStage = require("XUi/XUiMultiplayerRoom/XUiPanelChangeStage")

local XUiPanelArenaOnline = XClass(nil, "XUiPanelArenaOnline")

function XUiPanelArenaOnline:Ctor(ui, rootUi, stageId, challengeId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self.ChangeStagePanel = XUiPanelChangeStage.New(self.PanelChangeStage, true)
    -- 开启同调
    self.ActiveBuffObj = XUiPanelActiveBuff.New(self.PanelTeamBuff, self.RootUi, stageId, challengeId)
    self.ActiveBuffObj:Refresh()
    self.ActiveBuffObj:Show()
    self.ActiveBuffPanelTip = XUiPanelActiveBuffTip.New(self.PanelActiveBuffTip)
    self.ActiveBuffObj:RegisterPanel(self.ActiveBuffPanelTip)
    self:Refresh(stageId, challengeId)
    self.BtnDifficultySelect.CallBack = function() self:OnBtnDifficultySelectClick() end
    self.BtnChangeStage.CallBack = function() self:OnBtnChangeStageClick() end
end

function XUiPanelArenaOnline:Refresh(stageId, challengeId)
    self.StageId = stageId
    self.ChallengeId = challengeId
    local isPassed = XDataCenter.ArenaOnlineManager.CheckStagePass(challengeId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local arenaStageCfg = XDataCenter.ArenaOnlineManager.GetArenaOnlineStageCfgStageId(challengeId)
    local arenaChapterCfg = XDataCenter.ArenaOnlineManager.GetCurChapterCfg()
    self.PanelArenaOnlineTip.gameObject:SetActiveEx(isPassed)
    -- self.PanelConsume.gameObject:SetActiveEx(false)
    local cost = isPassed and 0 or arenaStageCfg.EnduranceCost
    self.TxtStamina.text = cost
    self.TxtLv.text = CS.XTextManager.GetText("ArenaOnlineChapterLevel", arenaChapterCfg.MinLevel, arenaChapterCfg.MaxLevel)
    self.ActiveBuffObj:Show(stageId)

    local difficult = XDataCenter.ArenaOnlineManager.GetSingleModeDifficulty(challengeId)
    local levelControl = XDataCenter.FubenManager.GetStageMultiplayerLevelControl(stageId, difficult)
    self.TxtAdditionDest.text = levelControl.AdditionDest
    self.TxtRecommend.text = CS.XTextManager.GetText("MultiplayerRoomRecommendAbility", levelControl.RecommendAbility)
    self.TxtTitle.text = stageCfg.Name
    
    self.ActiveBuffObj:Refresh()
end

function XUiPanelArenaOnline:OnBtnDifficultySelectClick()
    local msg = CS.XTextManager.GetText("SingleModeCanNotSelectDifficulty")
    XUiManager.TipMsg(msg)
    return
end

-- 改变关卡
function XUiPanelArenaOnline:OnBtnChangeStageClick()
    self.ChangeStagePanel:Show(self.ChallengeId)
    self.RootUi:PlayAnimation("ChangeStageEnable")
end

function XUiPanelArenaOnline:CheckTongdiaoState(playerId)
    return self.ActiveBuffObj:CheckActiveOn(playerId)
end

return XUiPanelArenaOnline


-- XDataCenter.ArenaOnlineManager.CheckStagePass(self.ChallengeId)