local XUiSettleWinWorldBoss = XLuaUiManager.Register(XLuaUi, "UiSettleWinWorldBoss")

function XUiSettleWinWorldBoss:OnStart(data)
    self:SetButtonCallback()
    self:ShowPanel(data)
end

function XUiSettleWinWorldBoss:OnEnable()
    self:PlayAnimation("PanelBossSingleinfo",function ()
            XDataCenter.FunctionEventManager.UnLockFunctionEvent()
        end)
end

function XUiSettleWinWorldBoss:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
end

function XUiSettleWinWorldBoss:SetButtonCallback()
    self.BtnCancel.CallBack = function()
        self:OnBtnCancelClick()
    end
end

function XUiSettleWinWorldBoss:ShowPanel(data)
    self.StageId = data.StageId
    self.RewardGoodsList = data.RewardGoodsList
    self.WorldBossFightResult = data.WorldBossFightResult

    local stageInfo = XDataCenter.FubenManager.GetStageInfo(data.StageId)
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(data.StageId)

    local totalTime = self.WorldBossFightResult.FightTime
    local damageAllScore = self.WorldBossFightResult.DamageMaxScore
    local allLeftHpScore = self.WorldBossFightResult.HpMaxScore

    for _,rewardGoods in pairs(self.RewardGoodsList) do
        --只要第一个
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(rewardGoods.TemplateId)
        local count = rewardGoods.Count
        local icon = goodsShowParams.Icon
        self.AttributeMoneyImg:SetSprite(icon)
        self.AttributeMoneyNum.text = count
        self.BossMoneyImg:SetSprite(icon)
        self.BossMoneyNum.text = count
        break
    end

    self.TxtDifficult.text = stageInfo.ChapterName
    self.TxtDamageAllScore.text = CS.XTextManager.GetText("BossSingleAutoFightDesc10", damageAllScore)
    self.TxtAllCharLeftHpScore.text = CS.XTextManager.GetText("BossSingleAutoFightDesc10", allLeftHpScore)

    self.PanelAttributeArea.gameObject:SetActiveEx(stageInfo.AreaType == XWorldBossConfigs.AreaType.Attribute)
    self.PanelBossArea.gameObject:SetActiveEx(stageInfo.AreaType == XWorldBossConfigs.AreaType.Boss)

    -- 播放音效
    self.AudioInfo = CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiSettle_Win_Number)
    XUiHelper.Tween(time, function(f)
            if XTool.UObjIsNil(self.Transform) then
                return
            end

            local totalTimeText = XUiHelper.GetTime(math.floor(f * totalTime))
            local bossLoseHpText = math.floor(f * self.WorldBossFightResult.Damage)
            local bossLoseHpScoreText = '+' .. math.floor(f * self.WorldBossFightResult.DamageScore)
            local charLeftHpText = math.floor(f *  self.WorldBossFightResult.HpLeftPer) .. "%"
            local charLeftHpScoreText = '+' .. math.floor(f * self.WorldBossFightResult.HpScore)
            local allScoreText = math.floor(f * (self.WorldBossFightResult.DamageScore + self.WorldBossFightResult.HpScore))

            self.TxtStageTime.text = totalTimeText
            self.TxtDamage.text = bossLoseHpText
            self.TxtBossLoseHpScore.text = bossLoseHpText
            self.TxtDamageScore.text = bossLoseHpScoreText
            self.TxtCharLeftHp.text = charLeftHpText
            self.TxtCharLeftHpScore.text = charLeftHpScoreText
            self.TxtAllScore.text = allScoreText
        end, function()
            if XTool.UObjIsNil(self.Transform)then
                return
            end
            self:StopAudio()
        end)


end

function XUiSettleWinWorldBoss:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

function XUiSettleWinWorldBoss:OnBtnCancelClick()
    self:StopAudio()
    XLuaUiManager.Close("UiSettleWinWorldBoss")
    XTipManager.Execute()
end
