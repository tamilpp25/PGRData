local XUiSummerEpisodeSettle = XLuaUiManager.Register(XLuaUi, "UiSummerEpisodeSettle")
local XUiGridFightGradeItem = require("XUi/XUiSummerEpisode/Settle/XUiGridSummerEpisodeSettleItem")

local countDownTime = CS.XGame.Config:GetInt("OnlinePraiseCountDown")

function XUiSummerEpisodeSettle:OnAwake()
    self:RegisterClickEvent(self.BtnContinue, self.OnBtnContinueClick)
end

function XUiSummerEpisodeSettle:OnStart(winData, cb)
    self.WinData = winData
    self:Init()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_KICKOUT, self.OnKickOut, self)
    self.Cb = cb
end

function XUiSummerEpisodeSettle:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_KICKOUT, self.OnKickOut, self)
end

function XUiSummerEpisodeSettle:OnKickOut()
    XDataCenter.RoomManager.RemoveMultiPlayerRoom()
end

function XUiSummerEpisodeSettle:OnBtnContinueClick()
    if not self.IsCountDownFinish then
        return
    end
    self:Close()
end

function XUiSummerEpisodeSettle:Init()
    local PlayerList = self.WinData.PlayerList
    local settleData = self.WinData.SettleData
    local dpsTable = self:GetSummerEpisodeDpsTable(settleData.EpisodeFightResult)
    if not dpsTable then
        return
    end
    local index = 0
    self.GridList = {}
    for _, v in pairs(PlayerList) do
        local ui
        if index == 0 then
            ui = self.GridFightGradeItem
        else
            ui = CS.UnityEngine.GameObject.Instantiate(self.GridFightGradeItem, self.PanelFightGradeContainer)
        end
        self.GridList[v.Id] = XUiGridFightGradeItem.New(ui, self)
        index = index + 1
    end

    for _, v in pairs(PlayerList) do
        local dps = dpsTable[v.Id]
        local grid = self.GridList[v.Id]
        grid:Init(v, index, self.WinData.StageId)
        grid:Refresh(dps)
        if v.Id == XPlayer.Id then
            grid:SwitchMyself()
        else
            grid:SwitchNormal()
        end
    end

    self:StartCountDown()
end

function XUiSummerEpisodeSettle:StartCountDown()
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

function XUiSummerEpisodeSettle:OnAddLike(playerId)
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

function XUiSummerEpisodeSettle:OnApplyFriend(playerId)
    XDataCenter.SocialManager.ApplyFriend(playerId)
end

function XUiSummerEpisodeSettle:GetSummerEpisodeDpsTable(episodeFightResult)
    --夏活拍照关数据
    local photoMvp = -1
    local mischiefMvp = -1
    local photoValue = -1
    local mischiefValue = -1
    local resultTable = {}
    XTool.LoopMap(episodeFightResult, function(roleId, v)
        resultTable[roleId] = {}
        resultTable[roleId].ScorePhoto = v.ScoreByTakePhoto
        resultTable[roleId].ScoreByMischief = v.ScoreByMischief
        resultTable[roleId].RoleId = roleId
        if v.ScoreByTakePhoto > photoValue then
            photoValue = v.ScoreByTakePhoto
            photoMvp = roleId
        end
        if v.ScoreByMischief > mischiefValue then
            mischiefValue = v.ScoreByMischief
            mischiefMvp = roleId
        end
    end)

    if mischiefMvp ~= -1 and resultTable[mischiefMvp] then
        resultTable[mischiefMvp].IsMischiefMvp = true
    end

    if photoMvp ~= -1 and resultTable[photoMvp] then
        resultTable[photoMvp].IsPhotoMvp = true
    end

    return resultTable
end

return XUiSummerEpisodeSettle