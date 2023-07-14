--兵法蓝图主页面
local XUiRpgTowerMain = XLuaUiManager.Register(XLuaUi, "UiRpgTowerMain")
local XUiRpgTowerMonstersPanel = require("XUi/XUiRpgTower/MainPage/PanelMonsters/XUiRpgTowerMonstersPanel")
local XUiRpgTwerStageDetails = require("XUi/XUiRpgTower/MainPage/PanelStageDetails/XUiRpgTowerStageDetails")
local XUiRpgTowerStageList = require("XUi/XUiRpgTower/MainPage/PanelStageList/XUiRpgTowerStageList")
-- =========           =========
-- =========生命周期方法=========
-- =========           =========
function XUiRpgTowerMain:OnAwake()
    XTool.InitUiObject(self)
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    XDataCenter.RpgTowerManager.SetNewBegining()
    self:InitButtons()
    self:InitMonsterPanel()
    self:InitStageDetailPanel()
    self:InitStageList()
    self:InitTeamLevel()
    self.RedEvents = {}
end

function XUiRpgTowerMain:OnEnable()
    if self.MainEnable and not XDataCenter.RpgTowerManager.GetIsReset() then
        self.MainEnable.gameObject:SetActiveEx(false)
        self.MainEnable.gameObject:SetActiveEx(true)
    else
        self:OnActivityReset()
        return
    end
    self:OnShowPanel()
    self:AddRedPointEvents()
    --[[
    if XDataCenter.RpgTowerManager.GetIsFirstIn() then
        XUiManager.ShowHelpTip("RpgTowerHelp")
    end]]
    CS.XShadowHelper.SetDisableUIGlobalShadowMeshHeight(true)
end

function XUiRpgTowerMain:OnDisable()
    self:StopTimer()
    self:RemoveRedPointEvents()
    CS.XShadowHelper.SetDisableUIGlobalShadowMeshHeight(false)
end

function XUiRpgTowerMain:OnGetEvents()
    return { XEventId.EVENT_RPGTOWER_RESET, XEventId.EVENT_RPGTOWER_REFRESH_DAILYREWARD }
end

function XUiRpgTowerMain:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_RPGTOWER_RESET then
        self:OnActivityReset()
    elseif evt == XEventId.EVENT_RPGTOWER_REFRESH_DAILYREWARD then
        self:RefreshSupply()
        self:RefreshTeamLevel()
    end
end

--================
--初始化按钮
--================
function XUiRpgTowerMain:InitButtons()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "RpgTowerHelp")
    self.BtnEnterStage.CallBack = function() self:OnEnterStageClick() end
    self.BtnActivityTask.CallBack = function() self:OnTaskClick() end
    self.BtnTeam.CallBack = function() self:OnTeamClick() end
    XUiHelper.RegisterClickEvent(self, self.ImgSupply, function() self:OnSupplyClick() end)
end
--================
--返回按钮
--================
function XUiRpgTowerMain:OnBtnBackClick()
    self:Close()
end
--================
--主界面按钮
--================
function XUiRpgTowerMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--================
--进入关卡按钮
--================
function XUiRpgTowerMain:OnEnterStageClick()
    self.StageDetail:ShowPanel()
end
--================
--活动任务按钮
--================
function XUiRpgTowerMain:OnTaskClick()
    XLuaUiManager.Open("UiRpgTowerTask")
end
--================
--队伍养成按钮
--================
function XUiRpgTowerMain:OnTeamClick()
    XLuaUiManager.Open("UiRpgTowerRoleList")
end
--================
--获取今日补给
--================
function XUiRpgTowerMain:OnSupplyClick()
    if XDataCenter.RpgTowerManager.GetCanReceiveSupply() then
        XDataCenter.RpgTowerManager.ReceiveSupply()
    else
        XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerCantGetSupply"))
    end
end
--================
--初始化怪兽模型面板
--================
function XUiRpgTowerMain:InitMonsterPanel()
    local uiModelRoot = self.UiModelGo.transform
    self.MonstersPanel = XUiRpgTowerMonstersPanel.New(self.PanelMonster, uiModelRoot)
end
--================
--初始化关卡列表
--================
function XUiRpgTowerMain:InitStageList()
    self.StageList = XUiRpgTowerStageList.New(self.PanelStageList, self)
end
--================
--初始化关卡详细
--================
function XUiRpgTowerMain:InitStageDetailPanel()
    self.StageDetail = XUiRpgTwerStageDetails.New(self.PanelStageDetail, self)
    self.StageDetail:HidePanel()
end

function XUiRpgTowerMain:InitTeamLevel()
    local teamLevelScript = require("XUi/XUiRpgTower/Common/XUiRpgTowerTeamBar")
    self.TeamLevel = teamLevelScript.New(self.PanelTeamBar, self)
    self.TeamLevel:RefreshBar()
end
--================
--点击关卡控件时
--================
function XUiRpgTowerMain:OnClickStageGrid(rStage)
    if self.RStage == rStage then return end
    self.RStage = rStage
    self.StageDetail:RefreshStage(self.RStage)
    self.MonstersPanel:RefreshMonsters(self.RStage)
    local isShowScore = self.RStage:GetIsShowScore()
    self.TxtStageScore.gameObject:SetActiveEx(isShowScore)
    if isShowScore then self:SetStageScoreText() end
end
--================
--设置关卡分数
--================
function XUiRpgTowerMain:SetStageScoreText()
    local score = self.RStage:GetScore()
    if score > 100000000 then
        local billion = math.floor(score / 100000000)
        local delta = score - billion * 100000000
        local scoreNum = string.format("%.2f",delta / 10000)
        self.TxtStageScore.text = XUiHelper.GetText("RpgTowerStageScoreBiggerThenBillion", billion, scoreNum)
    else
        local scoreNum = string.format("%.2f",score / 10000)
        self.TxtStageScore.text = XUiHelper.GetText("RpgTowerStageScoreStr", scoreNum)
    end
end

--================
--显示界面时
--================
function XUiRpgTowerMain:OnShowPanel()
    self.StageList:UpdateData()
    self:RefreshSupply()
    self:RefreshTeamLevel()
    self:SetTimer()
end
--================
--设置界面计时器
--================
function XUiRpgTowerMain:SetTimer()
    self:StopTimer()
    self:SetResetTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
            self:SetResetTime()
        end, XScheduleManager.SECOND, 0)
end
--================
--显示倒计时与处理倒计时完成时事件
--================
function XUiRpgTowerMain:SetResetTime()
    local endTimeSecond = XDataCenter.RpgTowerManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    local remainTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtRemainTime.text = CS.XTextManager.GetText("RpgTowerRemainTime", remainTime)
    if leftTime <= 0 then
        self:OnActivityReset()
    end
end
--================
--停止界面计时器
--================
function XUiRpgTowerMain:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--================
--活动周期结束时弹回主界面
--================
function XUiRpgTowerMain:OnActivityReset()
    if self.IsReseting then return end
    self.IsReseting = true
    self:StopTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerFinished"))
end
--================
--刷新每日补给
--================
function XUiRpgTowerMain:RefreshSupply()
    local haveSupply = XDataCenter.RpgTowerManager.GetCanReceiveSupply()
    self.TxtSupplyNotReceive.gameObject:SetActiveEx(haveSupply)
    self.TxtSupplyReceive.gameObject:SetActiveEx(not haveSupply)
    self.ObjSupplyRed.gameObject:SetActiveEx(haveSupply)
end
--================
--刷新队伍经验条
--================
function XUiRpgTowerMain:RefreshTeamLevel()
    if XDataCenter.RpgTowerManager.CheckExpChange() then
        local changes = XDataCenter.RpgTowerManager.GetExpChanges()
        self.TeamLevel:AddExp(changes.ChangeExp, changes.PreTeamExp, changes.PreTeamLevel)
    else
        self.TeamLevel:RefreshBar()  
    end
end
--================
--注册页面红点事件
--================
function XUiRpgTowerMain:AddRedPointEvents()
    if self.AlreadyAddRed then return end
    self.AlreadyAddRed = true
    table.insert(self.RedEvents, XRedPointManager.AddRedPointEvent(self.BtnActivityTask, self.OnCheckBtnTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_RPGTOWER_TASK_RED }))
    table.insert(self.RedEvents, XRedPointManager.AddRedPointEvent(self.BtnTeam, self.OnCheckBtnTeamRedPoint, self, { XRedPointConditions.Types.CONDITION_RPGTOWER_TEAM_RED }))
end
--================
--注销页面红点事件
--================
function XUiRpgTowerMain:RemoveRedPointEvents()
    if not self.AlreadyAddRed then return end
    for _, eventId in pairs(self.RedEvents) do
        XRedPointManager.RemoveRedPointEvent(eventId)
    end
    self.RedEvents = {}
    self.AlreadyAddRed = false
end
--================
--检查任务按钮红点
--================
function XUiRpgTowerMain:OnCheckBtnTaskRedPoint(count)
    self.BtnActivityTask:ShowReddot(count >= 0)
end
--================
--检查养成界面按钮红点
--================
function XUiRpgTowerMain:OnCheckBtnTeamRedPoint(count)
    self.BtnTeam:ShowReddot(count >= 0)
end
return XUiRpgTowerMain