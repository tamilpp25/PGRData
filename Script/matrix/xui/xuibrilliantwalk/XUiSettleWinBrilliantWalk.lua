--这个界面仅仅用在BOSS关卡胜利时展示，其他光辉同行结算界面使用通用
local XUiSettleWinBrilliantWalk = XLuaUiManager.Register(XLuaUi, "UiSettleWinBrilliantWalk")
local RollingAnimeTime = CS.XGame.ClientConfig:GetFloat("BrilliantWalkBossGameSetAnimeTime") --动画滚动时间
local PerfectRollingAnimeTime = CS.XGame.ClientConfig:GetFloat("BrilliantWalkBossGameSetPerfectAnimeTime") --完美动画滚动时间
local MAX_RANKING = 7 --最大评价等级
function XUiSettleWinBrilliantWalk:OnAwake()
    self.BtnSkipAnime.CallBack = function()
        self:OnBtnSkipAnimeClick()
    end
    
    self.BtnSave.CallBack =  function()
        self:OnBtnSaveClick()
    end
end
--settleData = { --仅供参考
--    ["MaxComboScore"] = 0,
--    ["ComboScore"] = 0,
--    ["MaxTimeScore"] = 0,
--    ["HighestCombo"] = 0,
--    ["TimeScore"] = 0,
--    ["FightTime"] = 0,
--    ["HpLeftPer"] = 0,
--    ["HpScore"] = 0,
--    ["StageId"] = 30061305,
--    ["MaxHpScore"] = 0,
--    ["TotalScore"] = 0,
--},
function XUiSettleWinBrilliantWalk:OnEnable()
    local settleData = XDataCenter.BrilliantWalkManager.GetUIBossStageSettleWin()
    if not settleData then
        self:Close()
    end
    self:ResetSchedule()
    self:UpdateView(settleData)
end
--重置动画计时器
function XUiSettleWinBrilliantWalk:ResetSchedule()
    if self.AnimeSchedule then
        self.BtnSkipAnime.gameObject:SetActiveEx(false)
        XScheduleManager.UnSchedule(self.AnimeSchedule)
        self.AnimeSchedule = nil
    end
end
--刷新界面
function XUiSettleWinBrilliantWalk:UpdateView(settleData)
    self.SettleData = settleData
    local stageId = settleData.StageId
    local stageType = XBrilliantWalkConfigs.GetStageType(stageId)
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    local isPerfect = settleData.IsPerfect == 1
    --关卡名
    self.TxtName.text = stageConfig.Name
    --难度
    if stageType == XBrilliantWalkStageType.Boss then
        self.TxtDifficult.text = CsXTextManagerGetText("BrilliantWalkBossGameSetDifficultNormal")
    elseif stageType == XBrilliantWalkStageType.HardBoss then
        self.TxtDifficult.text = CsXTextManagerGetText("BrilliantWalkBossGameSetDifficultHard")
    end
    --最大可能获取分数
    self.TxAlltLeftTimeScore.text = CsXTextManagerGetText("BrilliantWalkMaxPoint",settleData.MaxTimeScore)
    self.TxtAllCharLeftHpScore.text = CsXTextManagerGetText("BrilliantWalkMaxPoint",settleData.MaxHpScore)
    self.TxtBossAllLoseHpScore.text = CsXTextManagerGetText("BrilliantWalkMaxPoint",settleData.MaxComboScore)
    --是否完美通关
    self.TextNoInjured.gameObject:SetActiveEx(isPerfect)
    --关闭刷新纪录
    self.PanelNewTag.gameObject:SetActiveEx(false)
    self.Txtx2.gameObject:SetActiveEx(false)
    self:PlayRollingAnime(settleData)
end
--播放滚动动画
function XUiSettleWinBrilliantWalk:PlayRollingAnime(settleData)
    local stageId = settleData.StageId
    local isPerfect = settleData.IsPerfect == 1
    --评价等级UI
    self.RawImage:SetRawImage(CS.XGame.ClientConfig:GetString("BrilliantWalkStageDetailRankRImg1"))
    --动画滚动到最后时的分数
    local finalScore = 0
    if isPerfect then
        finalScore = settleData.TotalScore / 2
    else
        finalScore = settleData.TotalScore
    end
    --动画滚动到最后时的评价等级 用来计算滚动动画时长
    local finalRank = XDataCenter.BrilliantWalkManager.GetStageScoreRank(stageId,finalScore)
    --分数滚动动画
    local currentAnimRank = 1
    local animTime = RollingAnimeTime / MAX_RANKING * finalRank
    self.BtnSkipAnime.gameObject:SetActiveEx(true)
    self.AnimeSchedule = XUiHelper.Tween(animTime, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        local leftTime = XUiHelper.GetTime(math.floor(f * settleData.FightTime),XUiHelper.TimeFormatType.MINUTE_SECOND)
        local leftTimeScore = "+" .. math.floor(f * settleData.TimeScore)
        local charLeftHp = math.floor(f * settleData.HpLeftPer) .. "%"
        local charLeftHpScore = "+" .. math.floor(f * settleData.HpScore)
        local bossLoseHp = math.floor(f * settleData.HighestCombo)
        local bossLoseHpScore = "+" .. math.floor(f * settleData.ComboScore)
        local allScore = math.floor(f * finalScore)
        local rank = XDataCenter.BrilliantWalkManager.GetStageScoreRank(stageId,allScore)
        --通关时间相关
        self.TxtLeftTime.text = leftTime
        self.TxtLeftTimeScore.text = leftTimeScore
        --剩余血量相关
        self.TxtCharLeftHp.text = charLeftHp
        self.TxtCharLeftHpScore.text = charLeftHpScore
        ---最大连击相关
        self.TxtBossLoseHp.text = bossLoseHp
        self.TxtBossLoseHpScore.text = bossLoseHpScore
        --总分
        self.TxtAllScore.text = allScore
        --评价等级
        if rank > currentAnimRank then
            self.RawImage:SetRawImage(CS.XGame.ClientConfig:GetString("BrilliantWalkStageDetailRankRImg" .. rank))
            self:PlayAnimation("RawImageEnable")
        end
        currentAnimRank = rank
    end, function()
        if isPerfect then
            self:PlayPerfectRollingAnime(settleData)
        else
            self:FinishUpdateView(settleData)
        end
    end)
end
--播放完美滚动动画
function XUiSettleWinBrilliantWalk:PlayPerfectRollingAnime(settleData)
    local stageId = settleData.StageId
    self:PlayAnimation("TxtAllScoreEnable")
    --评价等级UI
    local currentAnimRank = XDataCenter.BrilliantWalkManager.GetStageScoreRank(stageId,settleData.TotalScore / 2)
    self.RawImage:SetRawImage(CS.XGame.ClientConfig:GetString("BrilliantWalkStageDetailRankRImg" .. currentAnimRank))
    self.TxtAllScore.text = settleData.TotalScore / 2
    local animTime = PerfectRollingAnimeTime
    self.BtnSkipAnime.gameObject:SetActiveEx(true)
    self.AnimeSchedule = XUiHelper.Tween(animTime, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        --动画滚到到最后
        local allScore = settleData.TotalScore / 2 + math.floor(f * settleData.TotalScore / 2)
        --动画最后时的关卡评价 用来计算滚动动画总时长
        local rank = XDataCenter.BrilliantWalkManager.GetStageScoreRank(stageId,allScore)
        --总分
        self.TxtAllScore.text = allScore
        --评价等级
        if rank > currentAnimRank then
            self.RawImage:SetRawImage(CS.XGame.ClientConfig:GetString("BrilliantWalkStageDetailRankRImg" .. rank))
            self:PlayAnimation("RawImageEnable")
        end
        currentAnimRank = rank
    end, function()
        self:FinishUpdateView(settleData)
    end)
end
--显示最终结果画面
function XUiSettleWinBrilliantWalk:FinishUpdateView(settleData)
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self:ResetSchedule()
    local stageId = settleData.StageId
    local stageType = XBrilliantWalkConfigs.GetStageType(stageId)
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    local isPerfect = settleData.IsPerfect == 1
    local isNewRecord = settleData.IsNewRecord
    --关卡名
    self.TxtName.text = stageConfig.Name
    --难度
    if stageType == XBrilliantWalkStageType.Boss then
        self.TxtDifficult.text = CsXTextManagerGetText("BrilliantWalkBossGameSetDifficultNormal")
    elseif stageType == XBrilliantWalkStageType.HardBoss then
        self.TxtDifficult.text = CsXTextManagerGetText("BrilliantWalkBossGameSetDifficultHard")
    end
    --通关时间相关
    self.TxtLeftTime.text = XUiHelper.GetTime(settleData.FightTime,XUiHelper.TimeFormatType.MINUTE_SECOND)
    self.TxtLeftTimeScore.text = "+" .. settleData.TimeScore
    self.TxAlltLeftTimeScore.text = CsXTextManagerGetText("BrilliantWalkMaxPoint",settleData.MaxTimeScore)
    --剩余血量相关
    self.TxtCharLeftHp.text = settleData.HpLeftPer .. "%"
    self.TxtCharLeftHpScore.text = "+" .. settleData.HpScore
    self.TxtAllCharLeftHpScore.text = CsXTextManagerGetText("BrilliantWalkMaxPoint",settleData.MaxHpScore)
    ---最大连击相关
    self.TxtBossLoseHp.text = settleData.HighestCombo
    self.TxtBossLoseHpScore.text = "+" .. settleData.ComboScore
    self.TxtBossAllLoseHpScore.text = CsXTextManagerGetText("BrilliantWalkMaxPoint",settleData.MaxComboScore)
    --最大分数和评价
    self.TxtAllScore.text = settleData.TotalScore
    local rank = XDataCenter.BrilliantWalkManager.GetStageScoreRank(stageId,settleData.TotalScore)
    self.RawImage:SetRawImage(CS.XGame.ClientConfig:GetString("BrilliantWalkStageDetailRankRImg" .. rank))
    --是否完美通关
    self.TextNoInjured.gameObject:SetActiveEx(isPerfect)
    self.PanelNewTag.gameObject:SetActiveEx(isNewRecord)
end
--点击中断动画
function XUiSettleWinBrilliantWalk:OnBtnSkipAnimeClick()
    if self.AnimeSchedule then
        self:FinishUpdateView(self.SettleData)
    end
end
--点击保存
function XUiSettleWinBrilliantWalk:OnBtnSaveClick()
    self:Close()
end
