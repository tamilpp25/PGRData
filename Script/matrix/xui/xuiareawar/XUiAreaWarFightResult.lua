local handler = handler
local ToInt = XMath.ToInt
--local CsXTextManagerGetText = CsXTextManagerGetText
--local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiAreaWarFightResult = XLuaUiManager.Register(XLuaUi, "UiAreaWarFightResult")

function XUiAreaWarFightResult:OnAwake()
    self:AutoAddListener()
    self.TxtRemainHp.gameObject:SetActiveEx(false)
    self.TxtRewardNumber.gameObject:SetActiveEx(false)
    self.GridRewards = {}
end

function XUiAreaWarFightResult:OnStart(data, closeCb)
    self.WinData = data
    self.CloseCb = closeCb

    local endTime = XDataCenter.AreaWarManager.GetEndTime()
    self.EndTime = endTime
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
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
    local info = XDataCenter.AreaWarManager.GetPersonal():GetFightData()
    local isQuest = info.IsQuest
    self.GridScoreInfo1.gameObject:SetActiveEx(not isQuest)
    self.GridScoreInfo2.gameObject:SetActiveEx(not isQuest)
    self.GridScoreInfo3.gameObject:SetActiveEx(not isQuest)
    self.AllScore.gameObject:SetActiveEx(not isQuest)
    self.PanelSearch.gameObject:SetActiveEx(isQuest)
    
    if isQuest then
        self:RefreshQuest(info)
    else
        self:RefreshBlock(info)
    end
end

function XUiAreaWarFightResult:RefreshBlock(info)
    local data = self.WinData.SettleData.AreaWarFightResult
    local blockId = XAreaWarConfigs.GetBlockIdByStageId(self.WinData.StageId)
    local fightCount = 1
    if info and info.FightCount then
        fightCount = info.FightCount
    end
    --区块名称
    self.TxtTile.text = XAreaWarConfigs.GetBlockName(blockId)

    --确认消耗
    self.RImgConsume:SetRawImage(XDataCenter.AreaWarManager.GetActionPointItemIcon())
    self.TxtConsume.text = XAreaWarConfigs.GetBlockActionPoint(blockId) * fightCount

    self.RImgConsumeAgain:SetRawImage(XDataCenter.AreaWarManager.GetActionPointItemIcon())
    self.TxtConsumeAgain.text = XAreaWarConfigs.GetBlockActionPoint(blockId) * fightCount
    
    self.TxtFightCount.text = fightCount

    -- 播放音效
    self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)

    --根据活动时期决定显示哪些内容
    local isRepeatTime=data.IsRepeatChallenge==1 and true or false
    self.GridScoreInfo1.gameObject:SetActiveEx(not isRepeatTime)
    self.GridScoreInfo2.gameObject:SetActiveEx(not isRepeatTime)
    self.GridScoreInfo3.gameObject:SetActiveEx(true)
    self.Desc.gameObject:SetActiveEx(not isRepeatTime)
    self.BaseScoreDesc.gameObject:SetActiveEx(not isRepeatTime)
    self.Desc2.gameObject:SetActiveEx(isRepeatTime)
    self.TxtHighScore.gameObject:SetActiveEx(not isRepeatTime)
    self.TxtPoint.gameObject:SetActiveEx(not isRepeatTime)

    if isRepeatTime then
        self:ShowReward(fightCount)
    end

    
    local totalScore = data.TotalScore * fightCount
    local totalPurification = data.TotalPurification + totalScore - data.TotalScore
    local damageScore = data.DamageScore * fightCount
    local damageHurt = data.DamageHurt * fightCount
    local baseScore = data.BaseScore * fightCount
    --分数动画
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    XUiHelper.Tween(time, function(f)
                if XTool.UObjIsNil(self.Transform) then
                    return
                end
                if not isRepeatTime then
                    --本次积分
                    self.TxtPoint.text = ToInt(f * totalScore)
                    --累计净化贡献
                    self.TxtHighScore.text = ToInt(f * totalPurification)
                    --伤害积分
                    self.TxtHitScore.text = ToInt(f * damageScore)
                    --伤害量
                    self.TxtHitCombo.text = ToInt(f * damageHurt)
                    --参与积分
                    self.TxtRemainHpScore.text = ToInt(f * baseScore)
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
                    self:ShowReward(fightCount)
                end
            end
    )
end

function XUiAreaWarFightResult:RefreshQuest(info)
    local data = self.WinData.SettleData.AreaWarFightResult
    --区块名称
    self.TxtTile.text = XMVCA.XFuben:GetStageName(self.WinData.StageId)

    self:ShowQuestReward()
    --分数动画
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        --通关时间
        self.TxtCostTime.text = XUiHelper.GetTime(ToInt(f * data.UseTime))
    end)
end

function XUiAreaWarFightResult:ShowReward(fightCount)
    fightCount = fightCount or 1
    local data = self.WinData.SettleData.AreaWarFightResult
    --奖励物品
    local reward = data.RewardGoods and data.RewardGoods[1]
    if not XTool.IsTableEmpty(reward) then
        local itemId = reward.TemplateId
        self.RImgIcon:SetRawImage(XItemConfigs.GetItemIconById(itemId))
        self.TxtRewardNumber.text = reward.Count * fightCount
        self.TxtRewardNumber.gameObject:SetActiveEx(true)
    else
        self.TxtRewardNumber.gameObject:SetActiveEx(false)
    end
end

function XUiAreaWarFightResult:ShowQuestReward()
    for _, grid in pairs(self.GridRewards) do
        grid.GameObject:SetActiveEx(false)
    end
    local data = self.WinData.SettleData.AreaWarFightResult
    --奖励物品
    local rewards = data.RewardGoods
    if XTool.IsTableEmpty(rewards) then
        self.GridReward.gameObject:SetActiveEx(false)
        return
    end
    for index, reward in ipairs(rewards) do
        local grid = self.GridRewards[index]
        if not grid then
            local ui = index == 1 and self.GridReward or XUiHelper.Instantiate(self.GridReward, self.ListReward)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.GridRewards[index] = grid
        end
        grid.TxtCount.text = reward.Count
        grid.RImgIcon:SetRawImage(XItemConfigs.GetItemIconById(reward.TemplateId))
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiAreaWarFightResult:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

function XUiAreaWarFightResult:AutoAddListener()
    self.BtnExitFight.CallBack = function()
        if XDataCenter.AreaWarManager.OnActivityEnd() then
            return
        end
        self:Close()
    end
    self.BtnConsume.CallBack = handler(self, self.OnClickBtnConsume)
    self.BtnEndExplore.CallBack = handler(self, self.OnClickBtnConsume)
    self.BtnConsumeAgain.CallBack=handler(self,self.OnClickBtnConsumeAgain)
end

function XUiAreaWarFightResult:OnClickBtnConsume()
    if XDataCenter.AreaWarManager.OnActivityEnd() then
        return
    end
    local stageId = self.WinData.StageId
    local info = XDataCenter.AreaWarManager.GetPersonal():GetFightData()
    local questId = info.IsQuest and info.Id or 0
    local fightCount = info.FightCount
    XDataCenter.AreaWarManager.AreaWarConfirmFightResultRequest(
        stageId, questId, fightCount, 
        function(rewardGoodsList)
            if not XTool.IsTableEmpty(rewardGoodsList) then
                XUiManager.OpenUiObtain(rewardGoodsList)
            end
        end
    )
    self:Close()
end

function XUiAreaWarFightResult:OnClickBtnConsumeAgain()
    if XDataCenter.AreaWarManager.OnActivityEnd() then
        return
    end
    local stageId = self.WinData.StageId
    local info = XDataCenter.AreaWarManager.GetPersonal():GetFightData()
    local questId = info.IsQuest and info.Id or 0
    local fightCount = info.FightCount
    XDataCenter.AreaWarManager.AreaWarConfirmFightResultRequest(
            stageId, questId, fightCount,
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

function XUiAreaWarFightResult:OnCheckActivity(isClose)
    if not isClose then
        return
    end

    XDataCenter.AreaWarManager.OnActivityEnd()
end
