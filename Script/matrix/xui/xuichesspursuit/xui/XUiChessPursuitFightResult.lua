local XChessPursuitCtrl = require("XUi/XUiChessPursuit/XChessPursuitCtrl")
local XUiChessPursuitFightResult = XLuaUiManager.Register(XLuaUi, "UiChessPursuitFightResult")
local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiChessPursuitFightResult:OnAwake()
    self:AutoAddListener()
end

function XUiChessPursuitFightResult:OnStart(params, callBack)
    self.MapId = params.MapId
    self.ChessPursuitSyncAction = params.ChessPursuitSyncAction
    self.Settle = params.Settle
    self.TeamGridIndex = params.TeamGridIndex
    self.ChessPursuitMapBoss = XDataCenter.ChessPursuitManager.GetChessPursuitMapBoss(params.BossId)
    self.CallBack = callBack
    self.ChessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
    self.TxtTile.text = XChessPursuitConfig.GetChessPursuitActivityNameByMapId(self.MapId)

    self:UpdateInfo()
end

function XUiChessPursuitFightResult:OnEnable()
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    self:OnActivityEnd()
end

function XUiChessPursuitFightResult:OnDestroy()
    self:StopAudio()
    if self.CallBack then
        self.CallBack()
    end

    XEventManager.DispatchEvent(XEventId.EVENT_CHESSPURSUIT_FIGHT_FINISH_WIN)
end

function XUiChessPursuitFightResult:OnActivityEnd()
    if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
        return
    end
    
    XUiManager.TipText("BossOnlineOver")
    XLuaUiManager.RunMain()
end

--@region 点击事件

function XUiChessPursuitFightResult:AutoAddListener()
    self:RegisterClickEvent(self.BtnExitFight, self.OnBtnExitFightClick)
    self:RegisterClickEvent(self.BtnReFight, self.OnBtnReFightClick)
end

function XUiChessPursuitFightResult:OnBtnExitFightClick()
    XDataCenter.ChessPursuitManager.RequestChessPursuitEndBattleRequest(function ()
        self:Close()
    end)
end

function XUiChessPursuitFightResult:OnBtnReFightClick()
    local chessPursuitMapTemplate = self.ChessPursuitMapDb:GetChessPursuitMapTemplate()
    local chessPursuitBoss = XChessPursuitConfig.GetChessPursuitBossTemplate(chessPursuitMapTemplate.BossId)
    local stageId = chessPursuitBoss.StageId
    local stage = XDataCenter.FubenManager.GetStageCfg(stageId)
    local gridTeamDb = self.ChessPursuitMapDb:GetGridTeamDbByGridId(self.TeamGridIndex)

    XDataCenter.FubenManager.EnterChessPursuitFight(stage, {
        CardIds = gridTeamDb.CardIds,
        CaptainPos = gridTeamDb.CaptainPos,
        FirstFightPos = gridTeamDb.FirstFightPos,
        RobotIds = gridTeamDb.RobotIds,
        StageId = stage.StageId,
    }, function() 
        self:Close()
    end)
end

--@endregion


function XUiChessPursuitFightResult:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
        self.AudioInfo = nil
    end
end

function XUiChessPursuitFightResult:UpdateInfo(settleData)
    local mapsCfg = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)
    --通关时间
    local leftTime = self.ChessPursuitSyncAction:GetLeftTime()
    --战斗结束打BOSS最高可获得的分数
    local battleHurtMax = self.ChessPursuitMapBoss:GetBattleHurtMax()
    --战斗结束我方血量最高可获得的分数
    local selfHpMax = self.ChessPursuitMapBoss:GetSelfHpMax()
    --战斗完我方血量的百分比（整数）
    local selfHp = self.ChessPursuitSyncAction:GetSelfHp()
    --战斗完我方血量的积分
    local selfScore = self.ChessPursuitSyncAction:GetSelfScore()
    --战斗完对Boss造成的伤害积分    
    local battleScore = self.ChessPursuitSyncAction:GetBattleScore()
    --战斗完对Boss造成的伤害
    local battleHurt = self.ChessPursuitSyncAction:GetBattleHurt()
    --战斗完的总积分
    local sumScore = self.ChessPursuitSyncAction:GetSumScore()
    --扣除BOSS的血量百分比
    local maxHp = self.ChessPursuitMapBoss:GetInitHp()
    local ration = sumScore / maxHp
    --历史百分比
    local oldRation = self.ChessPursuitMapDb:GetHurtBossByGridId(self.TeamGridIndex) / maxHp
    
    if oldRation < 0 then
        oldRation = 0
    end

    --扣的血不可超过配置的最大血量
    local maxHpRatio = self.ChessPursuitMapBoss:GetMaxHpRatio()
    if ration > maxHpRatio and maxHpRatio > 0 then
        ration = maxHpRatio
    end

    self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)

    self.TxtHighScore.text = string.format("%.2f%%", oldRation * 100)
    self.TxtRemainHpScoreMax.text = CSXTextManagerGetText("ChessPursuitMaxScore", selfHpMax)
    self.TxtRemainHp.text = selfHp .. "%"

    if mapsCfg.Stage == XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD then
        self.TxtHitSocreMax.text = CSXTextManagerGetText("ArenaMaxSingleNoScore")
    else
        self.TxtHitSocreMax.text = CSXTextManagerGetText("ChessPursuitMaxScore", battleHurtMax)
    end
    self.TxtHitCombo.text = battleHurt
    self.PanelNewRecord.gameObject:SetActiveEx(oldRation < ration)

    XUiHelper.Tween(CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime"), function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        
        self.TxtCostTime.text =  XUiHelper.GetTime(math.floor(f * leftTime))
        self.TxtHitScore.text = "+" ..  math.floor(f * battleScore)
        self.TxtRemainHpScore.text = "+" ..  math.floor(f * selfScore)
        self.TxtTotalPointNumber.text =  math.floor(f * sumScore)
        self.TxtDeductionProportion.text = string.format("%.2f%%", f * ration * 100)
    end, function()
        self:StopAudio()
    end)
end
