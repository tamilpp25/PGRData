local XUiFubenYuanXiaoFight = XLuaUiManager.Register(XLuaUi,"UiFubenYuanXiaoFight")
local XUiGridYuanXiaoFightItem = require("XUi/XUiSpecialTrainYuanXiao/XUiGridYuanXiaoFightItem")
local MathLerp = CS.UnityEngine.Mathf.Lerp

local ClickState = {
    CountDown = 1,
    RankScore = 2,
    Close = 3
}

function XUiFubenYuanXiaoFight:OnAwake()
    self:RegisterClickEvent(self.BtnContinue, self.OnBtnContinueClick)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_KICKOUT, self.OnKickOut, self)
end

function XUiFubenYuanXiaoFight:OnStart(winData, itemClass, proxy)
    self.WinData = winData
    self.FightItemClass = itemClass
    self.Proxy = proxy and proxy.New()
    self:InitPlayerData()
    self:InitGradeItem()
    self:InitPanelMedal()
    self:StartCountDown()

    -- 开启自动关闭检查
    local endTime = XDataCenter.FubenSpecialTrainManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.FubenSpecialTrainManager.HandleActivityEndTime()
        end
    end)
end

function XUiFubenYuanXiaoFight:InitPlayerData()
    self.PlayerList = self.WinData.PlayerList
    for _, play in pairs(self.PlayerList) do
        if play.Id == XPlayer.Id then
            self.CurPlayer = play
        end
    end

    self.ResultPlayer = {}
    local settleData = self.WinData.SettleData
    local SpecialTrainRankFightResult = settleData.SpecialTrainRankFightResult or settleData.SpecialTrainBreakthroughResult
    local players  = SpecialTrainRankFightResult and SpecialTrainRankFightResult.Players or nil
    local fightResult = XMVCA.XFuben:GetCurFightResult()
    if not fightResult then
        return
    end
    local customData = fightResult.CustomData
    
    if not players then
        return
    end
    
    -- Value：名次、回合数、总分、结算combo数、最高combo数 对应Key数字1~5
    for _, player in pairs(players) do
        if customData then
            local roleCustomData = customData[player.PlayerId].Dict
            local data = {}
            if roleCustomData then
                data.Rank = roleCustomData[1] --名次
                data.Round = roleCustomData[2] --回合数
                data.Score = player.Score --奖杯数
                data.StageScore = player.StageScore or 0 --关卡积分
            end
            self.ResultPlayer[player.PlayerId] = data
        end
    end
    
    local rankMvp = -1
    local roundMvpTable = {}
    local scoreMvpTable = {}
    local stageScoreMvpTable = {}

    local rankMvpValue = -1
    local roundMvpValue = -1
    local scoreMvpValue = -1
    local stageScoreMvpValue = -1
    XTool.LoopMap(self.ResultPlayer, function(k, v)
        if rankMvpValue == -1 or v.Rank < rankMvpValue then
            rankMvpValue = v.Rank
            rankMvp = k
        end
        
        if roundMvpValue == -1 or v.Round >= roundMvpValue then
            if v.Round > roundMvpValue then
                roundMvpTable = {}
                roundMvpValue = v.Round
            end
            table.insert(roundMvpTable,{ Rank = v.Rank, Mvp = k })
        end
        
        if scoreMvpValue == -1 or v.Score >= scoreMvpValue then
            if v.Score > scoreMvpValue then
                scoreMvpTable = {}
                scoreMvpValue = v.Score
            end
            table.insert(scoreMvpTable,{ Rank = v.Rank, Mvp = k })
        end
        
        local stageScore = v.StageScore or 0
        if stageScoreMvpValue == -1 or stageScore >= stageScoreMvpValue then
            if stageScore > stageScoreMvpValue then
                stageScoreMvpTable = {}
                stageScoreMvpValue = stageScore
            end
            table.insert(stageScoreMvpTable,{ Rank = v.Rank, Mvp = k })
        end
    end)
    
    if self.Proxy then
        self.Proxy:RankMvp(self, rankMvp, roundMvpTable, scoreMvpTable, stageScoreMvpTable)
    else
        --region 元宵2023
        rankMvp = {}
        roundMvpTable = {}
        --scoreMvpTable = {}
        stageScoreMvpTable = {}
        --endregion 元宵2023
        self:RankMvp(rankMvp, roundMvpTable, scoreMvpTable, stageScoreMvpTable)
    end
end

function XUiFubenYuanXiaoFight:RankMvp(rankMvp, roundMvpTable, scoreMvpTable, stageScoreMvpTable)
    if rankMvp ~= -1 and self.ResultPlayer[rankMvp] then
        self.ResultPlayer[rankMvp].IsRankingMvp = true
    end
    
    if not XTool.IsTableEmpty(roundMvpTable) then
        table.sort(roundMvpTable,function(a, b) return a.Rank < b.Rank end)
        local mvp = roundMvpTable[1].Mvp
        if self.ResultPlayer[mvp] then
            self.ResultPlayer[mvp].IsRoundMvp = true
        end
    end
    
    if not XTool.IsTableEmpty(scoreMvpTable) then
        table.sort(scoreMvpTable,function(a, b) return a.Rank < b.Rank end)
        local mvp = scoreMvpTable[1].Mvp
        if self.ResultPlayer[mvp] then
            self.ResultPlayer[mvp].IsScoreMvp = true
        end
    end

    if not XTool.IsTableEmpty(stageScoreMvpTable) then
        table.sort(stageScoreMvpTable,function(a, b) return a.Rank < b.Rank end)
        local mvp = stageScoreMvpTable[1].Mvp
        if self.ResultPlayer[mvp] then
            self.ResultPlayer[mvp].IsStageScoreMvp = true
        end
    end
end

function XUiFubenYuanXiaoFight:InitGradeItem()
    self.GridList = {}
    for _, v in pairs(self.PlayerList) do
        local ui
        if v.Id == XPlayer.Id then
            ui = self.GridFightGradeItem
        else
            ui = CS.UnityEngine.GameObject.Instantiate(self.GridFightGradeItem, self.PanelFightGradeContainer)
        end
        self.GridList[v.Id] = self:NewFightItem(ui, self)
    end
    self.PanelMedal.gameObject:SetActiveEx(false)

    for _, v in pairs(self.PlayerList) do
        local grid = self.GridList[v.Id]
        grid:RefreshPlayerData(v)

        local data = self.ResultPlayer[v.Id]
        grid:RefreshDataItem(data)
    end
end

function XUiFubenYuanXiaoFight:InitPanelMedal()
    self:InitMedalGrid()
    --结算前数据
    local curScore = self.CurPlayer.RankScore
    self.BeginInfo = self:GetCurRankInfoByScore(curScore)
    self:RefreshRawImage(self.BeginInfo.CurIcon, self.BeginInfo.CurIcon)
    self.ImgPlayerExpFillAdd.fillAmount = self.BeginInfo.Value
    self.ImgPlayerExpFill.fillAmount = self.BeginInfo.Value
    --结算后数据
    local playerData = self.ResultPlayer[XPlayer.Id]
    if not playerData then
        return
    end
    local Score = playerData.Score and playerData.Score or 0
    self.Increase.text = CSXTextManagerGetText("SnowGameIncrease", Score)
    self.CurInfo = self:GetCurRankInfoByScore(curScore + Score)
    self:RefreshTextScore(self.CurInfo)
end

function XUiFubenYuanXiaoFight:InitMedalGrid()
    self.MedalGrid = self:NewFightItem(self.PanelMedalGrid, self)
    self.MedalGrid:RefreshPlayerData(self.CurPlayer)
    self.MedalGrid:RefreshDataItem(self.ResultPlayer[XPlayer.Id])
end

function XUiFubenYuanXiaoFight:RefreshRawImage(rankIcon, nextRankIcon)
    self.RankIcon:SetRawImage(rankIcon)
    self.NextRankIcon:SetRawImage(nextRankIcon)
end

function XUiFubenYuanXiaoFight:GetCurRankInfoByScore(score)
    local info = {}
    info.CurScore = score
    --当前段位Id、是否是最高段位、下一段位id
    info.CurRankId, info.IsHighestGrade, info.NextRankId = XDataCenter.FubenSpecialTrainManager.GetCurIdAndNextIdByScore(info.CurScore)
    info.CurIcon = XFubenSpecialTrainConfig.GetRankIconById(info.CurRankId)
    if not info.IsHighestGrade then
        info.CurRankScore = XFubenSpecialTrainConfig.GetRankScoreById(info.CurRankId)
        info.NextRankScore = XFubenSpecialTrainConfig.GetRankScoreById(info.NextRankId)
        info.Value = (info.CurScore - info.CurRankScore) / (info.NextRankScore - info.CurRankScore)
    else
        info.Value = 1 --最高段位时progress为1
    end
    return info
end

function XUiFubenYuanXiaoFight:RefreshTextScore(info)
    if info.IsHighestGrade then
        self.TxtNex.text = CSXTextManagerGetText("SnowHighestGrade") --最高段位
        self.TextNow.text = info.CurScore
    else
        self.TxtNex.text = CSXTextManagerGetText("SnowNextGrade") --下一段位
        self.TextNow.text = CSXTextManagerGetText("SnowGradeScore", info.CurScore, info.NextRankScore)
    end
end

function XUiFubenYuanXiaoFight:StartCountDown()
    self.CurrentClickState = ClickState.CountDown
    self.TxtContinue.gameObject:SetActiveEx(false)
    self.PanelCountDown.gameObject:SetActiveEx(true)
    self:StartTimer()
end

function XUiFubenYuanXiaoFight:StartTimer()
    if self.Timers then
        self:StopTimer()
    end

    self.TotalTime = CS.XGame.Config:GetInt("PlayThroughCountDown")
    self.Time = self.TotalTime
    self.StartTicks = CS.XTimerManager.Ticks

    self.Timers = XScheduleManager.ScheduleForever(function(timer)
        self:OnUpdateTime(timer)
    end, 0)
end

function XUiFubenYuanXiaoFight:OnUpdateTime()
    if not self.ImgCountDownBarRight.gameObject:Exist() or not self.ImgCountDownBarLeft.gameObject:Exist() then
        self:StopTimer()
        return
    end

    self.ImgCountDownBarRight.fillAmount = self.Time / self.TotalTime
    self.ImgCountDownBarLeft.fillAmount = self.Time / self.TotalTime

    local t = self.TotalTime - (CS.XTimerManager.Ticks - self.StartTicks) / CS.System.TimeSpan.TicksPerSecond
    self.Time = t
    if self.Time <= 0 then
        self:OnSkipCountDown()
    end
end

function XUiFubenYuanXiaoFight:StopTimer()
    if self.Timers then
        XScheduleManager.UnSchedule(self.Timers)
        self.ImgCountDownBarRight.fillAmount = 0
        self.ImgCountDownBarLeft.fillAmount = 0

        self.Timers = nil
    end
end

function XUiFubenYuanXiaoFight:OnBtnContinueClick()
    if self.CurrentClickState == ClickState.CountDown then
        self:OnSkipCountDown()
    elseif self.CurrentClickState == ClickState.RankScore then
        self:OnSkipRankScoreClose()
    elseif self.CurrentClickState == ClickState.Close then
        self:Close()
    end
end

--跳过倒计时到奖杯结算界面
function XUiFubenYuanXiaoFight:OnSkipCountDown()
    self:StopTimer()
    self.PanelCountDown.gameObject:SetActiveEx(false)

    self:PlayAnimation("PanelMedalEnable",function()
        self.TxtContinue.gameObject:SetActiveEx(true)
        self.IsPanelMedalEnable = false
        self:RefreshSettlementPanel()
    end,function()
        self.IsPanelMedalEnable = true
        self.PanelMedal.gameObject:SetActiveEx(true)
    end)
    self.CurrentClickState = ClickState.RankScore
end

--跳过奖杯结算界面
function XUiFubenYuanXiaoFight:OnSkipRankScoreClose()
    if self.IsPanelMedalEnable then --正在播放动画PanelMedalEnable
        return
    end
    if not self.CurInfo then
        self:StopProgressAnimation()
        self.CurrentClickState = ClickState.Close
        return
    end

    self:StopProgressAnimation()
    self:RefreshRawImage(self.CurInfo.CurIcon, self.CurInfo.CurIcon)
    self.ImgPlayerExpFillAdd.fillAmount = self.CurInfo.Value
    if self.BeginInfo.CurRankId ~= self.CurInfo.CurRankId and not self.CurInfo.IsHighestGrade then
        self.ImgPlayerExpFill.fillAmount = 0
    end
    self.CurrentClickState = ClickState.Close
end

function XUiFubenYuanXiaoFight:RefreshSettlementPanel()
    local data = self:GetSettlementPanelData()

    local animation = function()
        if data.IsPlayAnimation then
            self:PlayAnimation("IconQieHuan", function()
                self:OnSkipRankScoreClose()
            end, function()
                self:RefreshRawImage(self.BeginInfo.CurIcon, self.CurInfo.CurIcon)
            end)
        else
            self:OnSkipRankScoreClose()
        end
    end

    if data.IsProgressAnimation then
        self:ProgressAnimation(self.BeginInfo.Value, self.CurInfo.Value, data.IsNext, function()
            animation()
        end)
    else
        self:OnSkipRankScoreClose()
    end
end

function XUiFubenYuanXiaoFight:GetSettlementPanelData()
    local data = {}
    if self.BeginInfo.IsHighestGrade or self.BeginInfo.CurScore == self.CurInfo.CurScore then
        data.IsProgressAnimation = false
        return data
    end
    if self.CurInfo.IsHighestGrade then
        data.IsProgressAnimation = true
        data.IsPlayAnimation = true
        return data
    end
    if self.BeginInfo.CurRankId ~= self.CurInfo.CurRankId then
        data.IsProgressAnimation = true
        data.IsPlayAnimation = true
        data.IsNext = true
    elseif self.BeginInfo.CurScore < self.CurInfo.CurScore then
        data.IsProgressAnimation = true
    end
    return data
end

function XUiFubenYuanXiaoFight:ProgressAnimation(start, tar, isNext, cb)
    if self.ImageFillAdd then
        self:StopProgressAnimation()
    end
    local duration = CS.XGame.Config:GetInt("SnowGameProgressDuration")
    self.ImageFillAdd = self:DoFillAmount(self.ImgPlayerExpFill, self.ImgPlayerExpFillAdd, start, tar, duration, isNext, XUiHelper.EaseType.Linear, cb)
end

function XUiFubenYuanXiaoFight:StopProgressAnimation()
    if self.ImageFillAdd then
        XScheduleManager.UnSchedule(self.ImageFillAdd)
        self.ImageFillAdd = nil
    end
end

function XUiFubenYuanXiaoFight:DoFillAmount(image, imageAdd, startFill, tarFill, duration, isNext, easeType, cb)
    easeType = easeType or XUiHelper.EaseType.Linear
    local tarValue = isNext and 1 + tarFill or tarFill
    local value = 0
    local timer = XUiHelper.Tween(
            duration,
            function(t)
                if not image:Exist() or not imageAdd:Exist() then
                    return true
                end
                value = MathLerp(startFill, tarValue, t)
                if isNext and value >= 1 then
                    image.fillAmount = 0
                    value = value - 1
                end
                imageAdd.fillAmount = value
            end,
            cb,
            function(t)
                return XUiHelper.Evaluate(easeType, t)
            end
    )
    return timer
end

function XUiFubenYuanXiaoFight:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_KICKOUT, self.OnKickOut, self)
end

function XUiFubenYuanXiaoFight:OnKickOut()
    XDataCenter.RoomManager.RemoveMultiPlayerRoom()
end

function XUiFubenYuanXiaoFight:NewFightItem(...)
    if self.FightItemClass then
        return self.FightItemClass.New(...) 
    end
    return XUiGridYuanXiaoFightItem.New(...)
end

return XUiFubenYuanXiaoFight