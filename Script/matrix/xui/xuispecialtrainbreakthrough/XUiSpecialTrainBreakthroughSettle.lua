local AnimationPhase = XFubenSpecialTrainConfig.AnimationPhase

local XUiSpecialTrainBreakthroughSettleGrid = require("XUi/XUiSpecialTrainBreakthrough/XUiSpecialTrainBreakthroughSettleGrid")

---@class XUiSpecialTrainBreakthroughSettle:XLuaUi
local XUiSpecialTrainBreakthroughSettle = XLuaUiManager.Register(XLuaUi, "UiSpecialTrainBreakthroughSettle")

function XUiSpecialTrainBreakthroughSettle:Ctor()
    self._Timer = false
    ---@type XUiSpecialTrainBreakthroughSettleGrid[]
    self._Panels = {}
    self._PhaseTeamScore = { Type = AnimationPhase.Phase1, Time = 0 }
    self._Data = false
end

function XUiSpecialTrainBreakthroughSettle:OnEnable()
    self:StartCountDown()
    self:RegisterClickEvent(self.BtnClose, self.OnCloseClick)
end

function XUiSpecialTrainBreakthroughSettle:OnDisable()
    self:StopCountDown()
end

function XUiSpecialTrainBreakthroughSettle:StartCountDown()
    if self._Timer then
        return
    end
    self:Tick(0)
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:Tick(CS.XUnityEx.DeltaTime)
    end, 0)
end

function XUiSpecialTrainBreakthroughSettle:StopCountDown()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end

function XUiSpecialTrainBreakthroughSettle:OnStart(winData)
    if not winData then
        return
    end
    local settleData = winData.SettleData
    local stageId = settleData and settleData.StageId
    local isHellStage = false
    if stageId then
        -- 困难模式才纪录历史积分
        isHellStage = XFubenSpecialTrainConfig.IsHellStageId(stageId)
    end

    local data = settleData and settleData.SpecialTrainCubeResult or {}
    data.IsHellStage = isHellStage
    self._Data = data

    local panelInfoMe = XUiSpecialTrainBreakthroughSettleGrid.New(self.ListInfoMe)
    local panelInfo1 = XUiSpecialTrainBreakthroughSettleGrid.New(self.ListInfoOther01)
    local panelInfo2 = XUiSpecialTrainBreakthroughSettleGrid.New(self.ListInfoOther02)

    -- mvp
    --local mvpWeakness, mvpTeammateDamage, mvpScore = 0, math.huge, 0
    --for i = 1, #data.Players do
    --    local info = data.Players[i]
    --    if info.TeammateDamage < mvpTeammateDamage then
    --        mvpTeammateDamage = info.TeammateDamage
    --    end
    --    if info.BossDamage > mvpWeakness then
    --        mvpWeakness = info.BossDamage
    --    end
    --    if info.PersonalScore > mvpScore then
    --        mvpScore = info.PersonalScore
    --    end
    --end
    --local dataMvp = {
    --    TeammateDamage = mvpTeammateDamage,
    --    BossDamage = mvpWeakness,
    --    PersonalScore = mvpScore,
    --}

    local myInfo
    local otherInfos = {}
    for i = 1, #data.Players do
        local info = data.Players[i]
        if info.PlayerId == XPlayer.Id then
            myInfo = info
        else
            otherInfos[#otherInfos + 1] = info
        end
        info.BaseScoreSummation = data.BaseScoreSummation
        info.RemainRoundAddition = data.RemainRoundAddition
        info.IsHellStage = isHellStage
    end
    if myInfo then
        panelInfoMe:SetData(myInfo)
        self._Panels[#self._Panels + 1] = panelInfoMe
    else
        panelInfoMe.GameObject:SetActiveEx(false)
    end
    if otherInfos[1] then
        panelInfo1:SetData(otherInfos[1])
        panelInfo1.GameObject:SetActiveEx(true)
        self._Panels[#self._Panels + 1] = panelInfo1
    else
        panelInfo1.GameObject:SetActiveEx(false)
    end
    if otherInfos[2] then
        panelInfo2:SetData(otherInfos[2])
        panelInfo2.GameObject:SetActiveEx(true)
        self._Panels[#self._Panels + 1] = panelInfo2
    else
        panelInfo2.GameObject:SetActiveEx(false)
    end

    --if data then
    --self.TxtAllScore.text = data.TeamScore
    --self.TxtJiaCheng.text = XUiHelper.GetText("SpecialTrainBreakthroughSettleRound", data.RemainRound)
    --end
    self.TxtAllScore.gameObject:SetActiveEx(false)
    self.TxtJiaCheng.gameObject:SetActiveEx(false)
    self.PanelNewTag.gameObject:SetActiveEx(false)

    -- 历史最高分
    --if XDataCenter.FubenSpecialTrainManager.BreakthroughGetTeamScoreOld() < data.TeamScore then
    --    self.PanelNewTag.gameObject:SetActiveEx(true)
    --else
    --    self.PanelNewTag.gameObject:SetActiveEx(false)
    --end
end

function XUiSpecialTrainBreakthroughSettle:Tick(deltaTime)
    --region 团队总成绩
    if self._PhaseTeamScore.Type == AnimationPhase.Phase1 then
        local endCountPersonalScoreAndDeduct = 0
        for i = 1, #self._Panels do
            local panel = self._Panels[i]
            if panel:IsEndPersonalScoreAndDeduct() then
                endCountPersonalScoreAndDeduct = endCountPersonalScoreAndDeduct + 1
            end
        end
        local isEndPersonalScoreAndDeduct = endCountPersonalScoreAndDeduct == #self._Panels

        local endCount = 0
        for i = 1, #self._Panels do
            local panel = self._Panels[i]
            if panel:Tick(deltaTime, isEndPersonalScoreAndDeduct) then
                endCount = endCount + 1
            end
        end
        if endCount == #self._Panels then
            self._PhaseTeamScore.Type = AnimationPhase.Phase2
        end

    elseif self._PhaseTeamScore.Type == AnimationPhase.Phase2 then
        -- 团队总成绩
        local data = self._Data
        local timeScroll = 1.5
        if self._PhaseTeamScore.Time == 0 then
            self.TxtAllScore.gameObject:SetActiveEx(true)
            --self.TxtJiaCheng.gameObject:SetActiveEx(true)
            self.TxtAllScore.text = 0
            -- 剩余轮次加成
            --self.TxtJiaCheng.text = XUiHelper.GetText("SpecialTrainBreakthroughSettleRound", data.RemainRound)
        else
            local timePassed = self._PhaseTeamScore.Time / timeScroll
            self.TxtAllScore.text = math.ceil(data.TeamScore * timePassed)
        end
        self._PhaseTeamScore.Time = self._PhaseTeamScore.Time + deltaTime
        if self._PhaseTeamScore.Time > timeScroll then
            self.TxtAllScore.text = data.TeamScore
            self._PhaseTeamScore.Type = AnimationPhase.Phase3
            self._PhaseTeamScore.Time = 0
        end

    elseif self._PhaseTeamScore.Type == AnimationPhase.Phase3 then
        -- 新纪录
        self._PhaseTeamScore.Type = AnimationPhase.PhaseEnd
        if self._Data.IsHellStage
                and
                XDataCenter.FubenSpecialTrainManager.BreakthroughGetTeamScoreOld() < self._Data.TeamScore then
            self.PanelNewTag.gameObject:SetActiveEx(true)
        else
            self.PanelNewTag.gameObject:SetActiveEx(false)
        end
    end
    --endregion 团队总成绩
end

function XUiSpecialTrainBreakthroughSettle:OnCloseClick()
    if self._PhaseTeamScore.Type == AnimationPhase.PhaseEnd then
        self:Close()
    else
        for i = 1, 99 do
            if self._PhaseTeamScore.Type ~= AnimationPhase.PhaseEnd then
                self:Tick(9999)
            else
                return
            end
        end
        self._PhaseTeamScore.Type = AnimationPhase.PhaseEnd
        XLog.Error("[XUiSpecialTrainBreakthroughSettle] force end animation")
    end
end

return XUiSpecialTrainBreakthroughSettle