local AnimationPhase = XFubenSpecialTrainConfig.AnimationPhase

---@class XUiSpecialTrainBreakthroughSettleGrid
local XUiSpecialTrainBreakthroughSettleGrid = XClass(nil, "XUiSpecialTrainBreakthroughSettleGrid")

function XUiSpecialTrainBreakthroughSettleGrid:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
    self:InitButton()

    self._PlayerId = false
    self._Data = false
    self._PhaseScore = { Type = AnimationPhase.Phase1, Time = 0, ScrollTime = 1.5 }
    self._PhaseDeduct = { Type = AnimationPhase.Phase1, Time = 0, ScrollTime = 1.5 }
    self._PhaseScoreTotal = { Type = AnimationPhase.Phase1, Time = 0, ScrollTime = 1.5 }
end

function XUiSpecialTrainBreakthroughSettleGrid:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnDz, self.OnBtnLikeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnJhy, self.OnBtnAddFriendClick)
end

function XUiSpecialTrainBreakthroughSettleGrid:SetData(data)
    if not data then
        return
    end
    self._Data = data

    local playerId = data.PlayerId
    self._PlayerId = playerId
    local beginData = XDataCenter.FubenManager.GetFightBeginData()
    local playerList = beginData and beginData.PlayerList
    local playerInfo = playerList and playerList[playerId]
    if not playerInfo then
        playerInfo = {
            Name = XPlayer.Name,
            HeadPortraitId = XPlayer.CurrHeadPortraitId,
            HeadFrameId = XPlayer.CurrHeadFrameId,
        }
    end
    if playerInfo.CharacterId then
        local imagePath = XCharacterCuteConfig.GetCuteModelHalfBodyImage(playerInfo.CharacterId)
        local uiObject = XUiPLayerHead.Create(self.Head, false)
        local imageIcon = uiObject:GetObject("ImgIcon")
        imageIcon:SetRawImage(imagePath)
    end
    --XUiPLayerHead.InitPortrait(playerInfo.HeadPortraitId, playerInfo.HeadFrameId, self.Head)
    self.TxtName.text = playerInfo.Name

    -- 新纪录
    if self.PanelNewTag then
        if data.IsHellStage then
            if playerId == XPlayer.Id
                    and XDataCenter.FubenSpecialTrainManager.BreakthroughGetPersonalScoreOld() < data.PersonalScore
            then
                self.PanelNewTag.gameObject:SetActiveEx(true)
            else
                self.PanelNewTag.gameObject:SetActiveEx(false)
            end
        else
            self.PanelNewTag.gameObject:SetActiveEx(false)
        end
    end

    -- mvp
    --self.TxtMvpTeammateDamage.gameObject:SetActiveEx(data.TeammateDamage == dataMvp.TeammateDamage)
    --self.TxtMvpWeakness.gameObject:SetActiveEx(data.BossDamage == dataMvp.BossDamage)
    --self.TxtMvpScore.gameObject:SetActiveEx(data.PersonalScore == dataMvp.PersonalScore)

    -- 非困难关卡，无友伤
    --local stageId = beginData and beginData.StageId
    --if not XFubenSpecialTrainConfig.IsHellStageId(stageId) then
    --    self.PanelTeammateDamage.gameObject:SetActiveEx(false)
    --end
end

function XUiSpecialTrainBreakthroughSettleGrid:OnBtnLikeClick()
    XDataCenter.RoomManager.AddLike(self._PlayerId)
    self.BtnDz:SetButtonState(CS.UiButtonState.Disable)
end

function XUiSpecialTrainBreakthroughSettleGrid:OnBtnAddFriendClick()
    XDataCenter.SocialManager.ApplyFriend(self._PlayerId)
end

function XUiSpecialTrainBreakthroughSettleGrid:InitAnimation()
    local data = self._Data
    if not data then
        return
    end
end

function XUiSpecialTrainBreakthroughSettleGrid:IsEndPersonalScoreAndDeduct()
    return self._PhaseScore.Type == AnimationPhase.PhaseEnd
            and self._PhaseDeduct.Type == AnimationPhase.PhaseEnd
end

--个人积分：data.BaseScoreSummation + data.HitSummation
--伤害扣减：data.BossDamage + data.TeammateDamage
--个人总积分：data.RoundSummation + data.RemainRoundAddition
function XUiSpecialTrainBreakthroughSettleGrid:Tick(deltaTime, isEndPersonalScoreAndDeduct)
    local data = self._Data

    --region 基础积分
    if self._PhaseScore.Type == AnimationPhase.Phase1 then
        self._PhaseScore.Type = AnimationPhase.Phase2
        self.TxtWeakness.text = data.BaseScoreSummation

    elseif self._PhaseScore.Type == AnimationPhase.Phase2 then
        -- 个人命中
        if data.HitSummation > 0 then
            if self._PhaseScore.Time == 0 then
                self.TxtJiaCheng03.text = XUiHelper.GetText("SpecialTrainBreakthroughSettleDesc3", data.HitSummation)
                self.TxtJiaCheng03.gameObject:SetActiveEx(true)
            end
            self._PhaseScore.Time = self._PhaseScore.Time + deltaTime
            if self._PhaseScore.Time > self._PhaseScore.ScrollTime then
                self._PhaseScore.Type = AnimationPhase.Phase3
                self._PhaseScore.Time = 0
                self.TxtJiaCheng03.gameObject:SetActiveEx(false)
            end
        else
            self.TxtJiaCheng03.gameObject:SetActiveEx(false)
            self._PhaseScore.Type = AnimationPhase.Phase3
        end

    elseif self._PhaseScore.Type == AnimationPhase.Phase3 then
        self._PhaseScore.Type = AnimationPhase.PhaseEnd
        self.TxtWeakness.text = data.BaseScoreSummation + data.HitSummation
    end
    --endregion 基础积分

    --region 伤害扣减
    if self._PhaseDeduct.Type == AnimationPhase.Phase1 then
        self._PhaseDeduct.Type = AnimationPhase.Phase2
        self.TxtTeammateDamage.text = 0

    elseif self._PhaseDeduct.Type == AnimationPhase.Phase2 then
        -- boss伤害
        if data.BossDamage ~= 0 then
            if self._PhaseDeduct.Time == 0 then
                self.TxtJiaCheng02.text = XUiHelper.GetText("SpecialTrainBreakthroughSettleDesc2", math.abs(data.BossDamage))
                self.TxtJiaCheng02.gameObject:SetActiveEx(true)
            end
            self._PhaseDeduct.Time = self._PhaseDeduct.Time + deltaTime
            if self._PhaseDeduct.Time > self._PhaseDeduct.ScrollTime then
                self._PhaseDeduct.Type = AnimationPhase.Phase3
                self._PhaseDeduct.Time = 0
                self.TxtJiaCheng02.gameObject:SetActiveEx(false)
                self.TxtTeammateDamage.text = data.BossDamage
            end
        else
            self._PhaseDeduct.Type = AnimationPhase.Phase3
            self.TxtJiaCheng02.gameObject:SetActiveEx(false)
        end

    elseif self._PhaseDeduct.Type == AnimationPhase.Phase3 then
        -- 友伤扣减
        if data.TeammateDamage ~= 0 then
            if self._PhaseDeduct.Time == 0 then
                self.TxtJiaCheng02.text = XUiHelper.GetText("SpecialTrainBreakthroughSettleDesc4", math.abs(data.TeammateDamage))
                self.TxtJiaCheng02.gameObject:SetActiveEx(true)
            end
            self._PhaseDeduct.Time = self._PhaseDeduct.Time + deltaTime
            if self._PhaseDeduct.Time > self._PhaseDeduct.ScrollTime then
                self._PhaseDeduct.Type = AnimationPhase.Phase4
                self._PhaseDeduct.Time = 0
                self.TxtJiaCheng02.gameObject:SetActiveEx(false)
            end
        else
            self._PhaseDeduct.Type = AnimationPhase.Phase4
        end

    elseif self._PhaseDeduct.Type == AnimationPhase.Phase4 then
        self._PhaseDeduct.Type = AnimationPhase.PhaseEnd
        self.TxtTeammateDamage.text = data.BossDamage + data.TeammateDamage
    end
    --endregion 伤害扣减

    --region 个人总积分
    if self._PhaseScoreTotal.Type == AnimationPhase.Phase1 then
        self.TxtScore.gameObject:SetActiveEx(false)
        self.TxtJiaCheng01.gameObject:SetActiveEx(false)
        self._PhaseScoreTotal.Type = AnimationPhase.Phase2

    elseif self._PhaseScoreTotal.Type == AnimationPhase.Phase2 then
        -- 等待 基础积分和伤害扣减
        if isEndPersonalScoreAndDeduct
                and self._PhaseScore.Type == AnimationPhase.PhaseEnd
                and self._PhaseDeduct.Type == AnimationPhase.PhaseEnd then
            self._PhaseScoreTotal.Type = AnimationPhase.Phase3
            self.TxtScore.text = data.RoundSummation
        end

    elseif self._PhaseScoreTotal.Type == AnimationPhase.Phase3 then
        -- 剩余轮次加成
        if data.RemainRoundAddition > 0 then
            if self._PhaseScoreTotal.Time == 0 then
                self.TxtJiaCheng01.text = XUiHelper.GetText("SpecialTrainBreakthroughSettleDesc1", data.RemainRoundAddition)
                self.TxtJiaCheng01.gameObject:SetActiveEx(true)
                self.TxtScore.gameObject:SetActiveEx(true)
            end
            self._PhaseScoreTotal.Time = self._PhaseScoreTotal.Time + deltaTime
            if self._PhaseScoreTotal.Time > self._PhaseScoreTotal.ScrollTime then
                self._PhaseScoreTotal.Type = AnimationPhase.Phase4
                self._PhaseScoreTotal.Time = 0
                self.TxtJiaCheng01.gameObject:SetActiveEx(false)
            end
        else
            self.TxtScore.gameObject:SetActiveEx(true)
            self.TxtJiaCheng01.gameObject:SetActiveEx(false)
            self._PhaseScoreTotal.Type = AnimationPhase.Phase4
        end

    elseif self._PhaseScoreTotal.Type == AnimationPhase.Phase4 then
        self._PhaseScoreTotal.Type = AnimationPhase.PhaseEnd
        self.TxtScore.text = data.RoundSummation + data.RemainRoundAddition
        self.TxtJiaCheng01.gameObject:SetActiveEx(false)
    end
    --endregion 个人总积分

    return self._PhaseScoreTotal.Type == AnimationPhase.PhaseEnd
end

return XUiSpecialTrainBreakthroughSettleGrid