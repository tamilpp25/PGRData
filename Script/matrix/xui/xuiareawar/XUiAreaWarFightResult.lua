local handler = handler
local ToInt = XMath.ToInt
--local CsXTextManagerGetText = CsXTextManagerGetText
--local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiAreaWarFightResult = XLuaUiManager.Register(XLuaUi, "UiAreaWarFightResult")

function XUiAreaWarFightResult:OnAwake()
    self:AutoAddListener()
    self.TxtRemainHp.gameObject:SetActiveEx(false)
    self.TxtRewardNumber.gameObject:SetActiveEx(false)
end

function XUiAreaWarFightResult:OnStart(data, closeCb)
    self.WinData = data
    self.CloseCb = closeCb
end

function XUiAreaWarFightResult:OnEnable()
    self:UpdateView()
end

function XUiAreaWarFightResult:OnDestroy()
    self:StopAudio()
    if self.CloseCb then
        self.CloseCb()
    end
    XDataCenter.AntiAddictionManager.EndFightAction()
end

function XUiAreaWarFightResult:UpdateView()
    local data = self.WinData.SettleData.AreaWarFightResult
    local blockId = XAreaWarConfigs.GetBlockIdByStageId(self.WinData.StageId)

    --区块名称
    self.TxtTile.text = XAreaWarConfigs.GetBlockName(blockId)

    --确认消耗
    self.RImgConsume:SetRawImage(XDataCenter.AreaWarManager.GetActionPointItemIcon())
    self.TxtConsume.text = XAreaWarConfigs.GetBlockActionPoint(blockId)

    self.RImgConsumeAgain:SetRawImage(XDataCenter.AreaWarManager.GetActionPointItemIcon())
    self.TxtConsumeAgain.text = XAreaWarConfigs.GetBlockActionPoint(blockId)
    
    -- 播放音效
    self.AudioInfo = CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiSettle_Win_Number)
    
    --根据活动时期决定显示哪些内容
    local isRepeatTime=data.IsRepeatChallenge==1 and true or false
    self.GridScoreInfo1.gameObject:SetActiveEx(not isRepeatTime)
    self.GridScoreInfo2.gameObject:SetActiveEx(not isRepeatTime)
    self.Desc.gameObject:SetActiveEx(not isRepeatTime)
    self.BaseScoreDesc.gameObject:SetActiveEx(not isRepeatTime)
    self.Desc2.gameObject:SetActiveEx(isRepeatTime)
    self.TxtHighScore.gameObject:SetActiveEx(not isRepeatTime)
    self.TxtPoint.gameObject:SetActiveEx(not isRepeatTime)

    if isRepeatTime then
        self:ShowReward()
    end
    
    --分数动画
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    XUiHelper.Tween(
        time,
        function(f)
            if XTool.UObjIsNil(self.Transform) then
                return
            end
            if not isRepeatTime then
                --本次积分
                self.TxtPoint.text = ToInt(f * data.TotalScore)
                --累计净化贡献
                self.TxtHighScore.text = ToInt(f * data.TotalPurification)
                --伤害积分
                self.TxtHitScore.text = ToInt(f * data.DamageScore)
                --伤害量
                self.TxtHitCombo.text = ToInt(f * data.DamageHurt)
                --参与积分
                self.TxtRemainHpScore.text = ToInt(f * data.BaseScore)
            end
            --通关时间
            self.TxtCostTime.text = XUiHelper.GetTime(ToInt(f * data.UseTime))

            
        end,
        function()
            if XTool.UObjIsNil(self.Transform) then
                return
            end
            self:StopAudio()
            if not isRepeatTime then
                self:ShowReward()
            end
        end
    )
end

function XUiAreaWarFightResult:ShowReward()
    local data = self.WinData.SettleData.AreaWarFightResult
    --奖励物品
    local reward = data.RewardGoods and data.RewardGoods[1]
    if not XTool.IsTableEmpty(reward) then
        local itemId = reward.TemplateId
        self.RImgIcon:SetRawImage(XItemConfigs.GetItemIconById(itemId))
        self.TxtRewardNumber.text = reward.Count
        self.TxtRewardNumber.gameObject:SetActiveEx(true)
    else
        self.TxtRewardNumber.gameObject:SetActiveEx(false)
    end
end

function XUiAreaWarFightResult:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

function XUiAreaWarFightResult:AutoAddListener()
    self.BtnExitFight.CallBack = handler(self, self.Close)
    self.BtnConsume.CallBack = handler(self, self.OnClickBtnConsume)
    self.BtnConsumeAgain.CallBack=handler(self,self.OnClickBtnConsumeAgain)
end

function XUiAreaWarFightResult:OnClickBtnConsume()
    local stageId = self.WinData.StageId
    XDataCenter.AreaWarManager.AreaWarConfirmFightResultRequest(
        stageId,
        function(rewardGoodsList)
            if not XTool.IsTableEmpty(rewardGoodsList) then
                XUiManager.OpenUiObtain(rewardGoodsList)
            end
        end
    )
    self:Close()
end

function XUiAreaWarFightResult:OnClickBtnConsumeAgain()
    local stageId = self.WinData.StageId

    XDataCenter.AreaWarManager.AreaWarConfirmFightResultRequest(
            stageId,
            function(rewardGoodsList)
                if not XTool.IsTableEmpty(rewardGoodsList) then
                    XUiManager.OpenUiObtain(rewardGoodsList)
                end
            end
    )
    XLuaUiManager.PopThenOpen(
            "UiBattleRoleRoom",
            stageId,
            XDataCenter.AreaWarManager.GetTeam(),
            require("XUi/XUiAreaWar/XUiAreaWarBattleRoleRoom")
    )
end
