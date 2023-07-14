local XUiFubenSnowGameFight = XLuaUiManager.Register(XLuaUi, "UiFubenSnowGameFight")
local XUiGridSnowGameFightItem = require("XUi/XUiSpecialTrainSnow/XUiGridSnowGameFightItem")
local MathLerp = CS.UnityEngine.Mathf.Lerp

local ClickState = {
    CountDown = 1,
    RankScore = 2,
    Close = 3
}

function XUiFubenSnowGameFight:OnAwake()
    self:RegisterClickEvent(self.BtnContinue, self.OnBtnContinueClick)
end

function XUiFubenSnowGameFight:OnStart(winData, cb)
    self.Cb = cb
    self.WinData = winData
    self:InitPlayerData()
    self:InitGradeItem()
    self:InitPanelMedal()
    self:StartCountDown()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_KICKOUT, self.OnKickOut, self)
end

function XUiFubenSnowGameFight:InitPlayerData()
    self.PlayerList = self.WinData.PlayerList
    for _, play in pairs(self.PlayerList) do
        if play.Id == XPlayer.Id then
            self.CurPlayer = play
        end
    end
    
    local SpecialTrainRankFightResult = self.WinData.SettleData.SpecialTrainRankFightResult
    local players  = SpecialTrainRankFightResult and SpecialTrainRankFightResult.Players or nil
    
    self.ResultPlayer = {}
    for _, player in pairs(players) do
        self.ResultPlayer[player.PlayerId] = player
    end
    
    local rankMvp = -1
    local scoreMvpTable = {}

    local rankMvpValue = -1
    local scoreMvpValue = -1
    XTool.LoopMap(self.ResultPlayer, function(k, v)
        if rankMvpValue == -1 or v.Ranking < rankMvpValue then
            rankMvpValue = v.Ranking
            rankMvp = k
        end

        if scoreMvpValue == -1 or v.Score >= scoreMvpValue then
            if v.Score > scoreMvpValue then
                scoreMvpTable = {}
                scoreMvpValue = v.Score
            end
            table.insert(scoreMvpTable,{ Ranking = v.Ranking, Mvp = k })
        end
    end)

    if rankMvp ~= -1 and self.ResultPlayer[rankMvp] then
        self.ResultPlayer[rankMvp].IsRankingMvp = true
    end

    if not XTool.IsTableEmpty(scoreMvpTable) then
        table.sort(scoreMvpTable,function(a, b) return a.Ranking < b.Ranking end)
        local mvp = scoreMvpTable[1].Mvp
        if self.ResultPlayer[mvp] then
            self.ResultPlayer[mvp].IsScoreMvp = true
        end
    end
end

function XUiFubenSnowGameFight:InitGradeItem()
    self.GridList = {}
    for _, v in pairs(self.PlayerList) do
        local ui
        if v.Id == XPlayer.Id then
            ui = self.GridFightGradeItem
        else
            ui = CS.UnityEngine.GameObject.Instantiate(self.GridFightGradeItem, self.PanelFightGradeContainer)
        end
        self.GridList[v.Id] = XUiGridSnowGameFightItem.New(ui, self)
    end
    self.PanelMedal.gameObject:SetActiveEx(false)

    for _, v in pairs(self.PlayerList) do
        local grid = self.GridList[v.Id]
        grid:RefreshPlayerData(v)
        
        local data = self.ResultPlayer[v.Id]
        grid:RefreshDataItem(data)
    end
end

function XUiFubenSnowGameFight:StartCountDown()
    self.CurrentClickState = ClickState.CountDown
    self.TxtContinue.gameObject:SetActiveEx(false)
    self.PanelCountDown.gameObject:SetActiveEx(true)
    self:StartTimer()
end

function XUiFubenSnowGameFight:StartTimer()
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

function XUiFubenSnowGameFight:OnUpdateTime()
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

function XUiFubenSnowGameFight:StopTimer()
    if self.Timers then
        XScheduleManager.UnSchedule(self.Timers)
        self.ImgCountDownBarRight.fillAmount = 0
        self.ImgCountDownBarLeft.fillAmount = 0
        
        self.Timers = nil
    end
end

function XUiFubenSnowGameFight:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_KICKOUT, self.OnKickOut, self)
end

function XUiFubenSnowGameFight:OnKickOut()
    XDataCenter.RoomManager.RemoveMultiPlayerRoom()
end

function XUiFubenSnowGameFight:OnBtnContinueClick()
    if self.CurrentClickState == ClickState.CountDown then
        self:OnSkipCountDown()
    elseif self.CurrentClickState == ClickState.RankScore then
        self:OnSkipRankScoreClose()
    elseif self.CurrentClickState == ClickState.Close then
        self:Close()
    end
end

--跳过倒计时到奖杯结算界面
function XUiFubenSnowGameFight:OnSkipCountDown()
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
function XUiFubenSnowGameFight:OnSkipRankScoreClose()
    if self.IsPanelMedalEnable then --正在播放动画PanelMedalEnable
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

function XUiFubenSnowGameFight:InitPanelMedal()
    self:InitMedalGrid()
    --结算前数据
    local curScore = self.CurPlayer.RankScore
    self.BeginInfo = self:GetCurRankInfoByScore(curScore)
    self:RefreshRawImage(self.BeginInfo.CurIcon, self.BeginInfo.CurIcon)
    self.ImgPlayerExpFillAdd.fillAmount = self.BeginInfo.Value
    self.ImgPlayerExpFill.fillAmount = self.BeginInfo.Value
    --结算后数据
    local playerData = self.ResultPlayer[XPlayer.Id]
    local Score = playerData.Score and playerData.Score or 0
    self.Increase.text = CSXTextManagerGetText("SnowGameIncrease", Score)
    self.CurInfo = self:GetCurRankInfoByScore(curScore + Score)
    self:RefreshTextScore(self.CurInfo)
end

function XUiFubenSnowGameFight:GetCurRankInfoByScore(score)
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

function XUiFubenSnowGameFight:InitMedalGrid()
    self.MedalGrid = XUiGridSnowGameFightItem.New(self.PanelMedalGrid, self)
    self.MedalGrid:RefreshPlayerData(self.CurPlayer)
    self.MedalGrid:RefreshDataItem(self.ResultPlayer[XPlayer.Id])
end

function XUiFubenSnowGameFight:RefreshTextScore(info)
    if info.IsHighestGrade then
        self.TxtNex.text = CSXTextManagerGetText("SnowHighestGrade") --最高段位
        self.TextNow.text = info.CurScore
    else
        self.TxtNex.text = CSXTextManagerGetText("SnowNextGrade") --下一段位
        self.TextNow.text = CSXTextManagerGetText("SnowGradeScore", info.CurScore, info.NextRankScore)
    end
end

function XUiFubenSnowGameFight:RefreshRawImage(rankIcon, nextRankIcon)
    self.RankIcon:SetRawImage(rankIcon)
    self.NextRankIcon:SetRawImage(nextRankIcon)
end

function XUiFubenSnowGameFight:GetSettlementPanelData()
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

function XUiFubenSnowGameFight:RefreshSettlementPanel()
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

function XUiFubenSnowGameFight:ProgressAnimation(start, tar, isNext, cb)
    if self.ImageFillAdd then
        self:StopProgressAnimation()
    end
    local duration = CS.XGame.Config:GetInt("SnowGameProgressDuration")
    self.ImageFillAdd = self:DoFillAmount(self.ImgPlayerExpFill, self.ImgPlayerExpFillAdd, start, tar, duration, isNext, XUiHelper.EaseType.Linear, cb)
end

function XUiFubenSnowGameFight:StopProgressAnimation()
    if self.ImageFillAdd then
        XScheduleManager.UnSchedule(self.ImageFillAdd)
        self.ImageFillAdd = nil
    end
end

function XUiFubenSnowGameFight:DoFillAmount(image, imageAdd, startFill, tarFill, duration, isNext, easeType, cb)
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

return XUiFubenSnowGameFight