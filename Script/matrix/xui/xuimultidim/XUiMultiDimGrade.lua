local XUiMultiDimGrade = XLuaUiManager.Register(XLuaUi,"UiMultiDimGrade")
local XUiGridMultiDimGradePlayer = require("XUi/XUiMultiDim/XUiGridMultiDimGradePlayer")
local countDownTime = CS.XGame.Config:GetInt("OnlinePraiseCountDown")

function XUiMultiDimGrade:OnStart(winData,cb)
    self.WinData = winData
    self.CloseCb = cb
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_KICKOUT, self.OnKickOut, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ADD_LIKE_NOTIFY, self.OnNotifyAddLike, self)
    self:RegisterClickEvent(self.BtnContinue, self.OnBtnContinueClick)
    self:Init()
    self:InitGradeItem()
    self:StartCountDown()
end

function XUiMultiDimGrade:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_KICKOUT, self.OnKickOut, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ADD_LIKE_NOTIFY, self.OnNotifyAddLike, self)
end

function XUiMultiDimGrade:OnKickOut()
    XDataCenter.RoomManager.RemoveMultiPlayerRoom()
end

function XUiMultiDimGrade:Init()
    self.PlayerList = self.WinData.PlayerList
    for _, play in pairs(self.PlayerList) do
        if play.Id == XPlayer.Id then
            self.CurPlayer = play
        end
    end

    self.ResultPlayer = {}
    local multiDimFightResult = self.WinData.SettleData.MultiDimFightResult
    local dpsTable = XDataCenter.FubenManager.LastDpsTable

    for _, player in pairs(self.WinData.PlayerList) do
        local data = {}
        data.UseTime = multiDimFightResult.UseTime --通关时长
        data.DamageTotal = multiDimFightResult.PlayerDamages[player.Id] or 0  --总伤害
        data.Score = multiDimFightResult.PlayerScores[player.Id] or 0 --玩家评分
        self.ResultPlayer[player.Id] = data
    end

    local damageMvp = -1
    local scoreMvp = -1

    local damageMvpValue = -1
    local scoreMvpValue = -1
    XTool.LoopMap(self.ResultPlayer, function(k, v)
        if damageMvpValue == -1 or v.DamageTotal > damageMvpValue then
            damageMvpValue = v.DamageTotal
            damageMvp = k
        end

        if scoreMvpValue == -1 or v.Score >= scoreMvpValue then
            if v.Score > scoreMvpValue then
                scoreMvp = k
                scoreMvpValue = v.Score
            end
        end
    end)

    if damageMvp ~= -1 and self.ResultPlayer[damageMvp] then
        self.ResultPlayer[damageMvp].IsDamageMvp = true
    end

    if scoreMvp ~= -1 and self.ResultPlayer[scoreMvp] then
        self.ResultPlayer[scoreMvp].IsScoreMvp = true
    end
end

function XUiMultiDimGrade:InitGradeItem()
    self.GridList = {}
    for _, v in pairs(self.PlayerList) do
        local ui = CS.UnityEngine.GameObject.Instantiate(self.GridFightGradeItem, self.PanelFightGradeContainer)
        self.GridList[v.Id] = XUiGridMultiDimGradePlayer.New(ui, self)
    end

    for _, v in pairs(self.PlayerList) do
        local grid = self.GridList[v.Id]
        grid:RefreshPlayerData(v)

        local data = self.ResultPlayer[v.Id]
        grid:RefreshDataItem(data)
    end
    self.GridFightGradeItem.gameObject:SetActiveEx(false)
end

function XUiMultiDimGrade:OnBtnContinueClick()
    if not self.IsCountDownFinish then
        return
    end

    if self.CloseCb then
        self.CloseCb()
    else
        self:Close()
    end
end

function XUiMultiDimGrade:StartCountDown()
    self.IsCountDownFinish = false
    self.TxtContinue.gameObject:SetActive(false)
    self.PanelCountDown.gameObject:SetActive(true)
    local startTicks = CS.XTimerManager.Ticks
    local refresh = function(timer)
        if not self.GameObject or not self.GameObject:Exist() then
            self.IsCountDownFinish = true
            XScheduleManager.UnSchedule(timer)
            return
        end
        local t = countDownTime - (CS.XTimerManager.Ticks - startTicks) / CS.System.TimeSpan.TicksPerSecond
        self.ImgCountDownBarRight.fillAmount = t / countDownTime
        self.ImgCountDownBarLeft.fillAmount = t / countDownTime
        if t <= 0 then
            self.IsCountDownFinish = true
            XScheduleManager.UnSchedule(timer)
            self.TxtContinue.gameObject:SetActive(true)
            self.PanelCountDown.gameObject:SetActive(false)
        end
    end
    XScheduleManager.ScheduleForever(refresh, 0)
end

function XUiMultiDimGrade:OnAddLike(playerId)
    XDataCenter.RoomManager.AddLike(playerId)
    for k, v in pairs(self.GridList) do
        if k ~= XPlayer.Id then
            if k == playerId then
                v:SwitchAlreadyLike()
            else
                v:SwitchDisabledLike()
            end
        end
    end
end

function XUiMultiDimGrade:OnNotifyAddLike(data)
    local playerId = data.ToPlayerId
    self.GridList[playerId]:AddLikeNumber()
end

return XUiMultiDimGrade