local XUiUnionKillGrade = XLuaUiManager.Register(XLuaUi, "UiUnionKillGrade")
local XUiUnionKillGridTeamCard = require("XUi/XUiFubenUnionKill/XUiUnionKillGridTeamCard")

function XUiUnionKillGrade:OnAwake()
    self.BtnContinue.CallBack = function() self:OnBtnContinueClick() end

    self.PanelCountDown.gameObject:SetActiveEx(true)
    self.TeamCards = {}
end

function XUiUnionKillGrade:OnDestroy()
    self:EndCountDown()
end

function XUiUnionKillGrade:OnStart(winData)
    self.WinData = winData
    self.StageId = self.WinData.SettleData.StageId

    local unionKillResult = self.WinData.SettleData.UnionKillResult
    if unionKillResult then
        local shareResults = unionKillResult.ShareResultInfos
        self:UpdateShareInfos(shareResults)
    end

    self:EndCountDown()
    -- 开启倒计时、倒计时结束开始可以退出
    local now = XTime.GetServerNowTimestamp()
    local endSecond = now + XFubenUnionKillConfigs.PraiseInterval

    self.TxtContinue.gameObject:SetActiveEx(false)
    -- self.BtnContinue.enabled = false
    self.TxtCountDown.text = CS.XTextManager.GetText("UnionGradeCountDown", endSecond - now)
    self.UnionGradeTimer = XScheduleManager.ScheduleForever(function()
        now = XTime.GetServerNowTimestamp()
        if now > endSecond then
            self:EndCountDown()
            self:BeforeGradeClose()
            return
        end
        self.TxtCountDown.text = CS.XTextManager.GetText("UnionGradeCountDown", endSecond - now)
    end, XScheduleManager.SECOND, 0)
end

function XUiUnionKillGrade:UpdateShareInfos(shareResults)
    if not shareResults then return end
    for i = 1, #shareResults do
        if not self.TeamCards[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridFightGradeItem.gameObject)
            ui.transform:SetParent(self.PanelFightGradeContainer, false)
            self.TeamCards[i] = XUiUnionKillGridTeamCard.New(ui, self)
        end
        self.TeamCards[i].GameObject:SetActiveEx(true)
        self.TeamCards[i]:Refresh(shareResults[i])
    end
    for i = #shareResults + 1, #self.TeamCards do
        self.TeamCards[i].GameObject:SetActiveEx(false)
    end
end

function XUiUnionKillGrade:EndCountDown()
    if self.UnionGradeTimer ~= nil then
        XScheduleManager.UnSchedule(self.UnionGradeTimer)
        self.UnionGradeTimer = nil
    end
    self.TxtCountDown.text = ""
    self.TxtContinue.gameObject:SetActiveEx(true)
    -- self.BtnContinue.enabled = true
end

function XUiUnionKillGrade:BeforeGradeClose()

    if XLuaUiManager.IsUiShow("UiPlayerInfo") then
        XLuaUiManager.Close("UiPlayerInfo")
    end

    self:Close()

    -- 打开其他界面
    -- 事件关卡
    if XDataCenter.FubenUnionKillManager.IsEventStage(self.StageId) then
        XLuaUiManager.Open("UiSettleWin", self.WinData)
        return
    end

    -- boss、试炼关卡
    -- if XDataCenter.FubenUnionKillManager.IsBossStage(self.StageId) or XDataCenter.FubenUnionKillManager.IsTrialStage(self.StageId) then
    --     if self.WinData.SettleData.UnionKillResult then
    --         XLuaUiManager.Open("UiArenaFightResult", self.WinData)
    --         return
    --     end
    -- end

end

function XUiUnionKillGrade:OnBtnContinueClick()
    self:BeforeGradeClose()
end