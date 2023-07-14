local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiGridWinRole = require("XUi/XUiFubenSimulatedCombat/XUiSettleWin/XUiGridWinRole")
local XUiGridCond = require("XUi/XUiFubenSimulatedCombat/XUiSettleWin/XUiGridCond")

local XUiSimulatedCombatSettleWin = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatSettleWin")

function XUiSimulatedCombatSettleWin:OnAwake()
    self:InitAutoScript()
    self.GridReward.gameObject:SetActive(false)
end

function XUiSimulatedCombatSettleWin:OnStart(data, stageInterInfo, cb, closeCb, onlyTouchBtn)
    self.WinData = data
    self.StageInfos = XDataCenter.FubenManager.GetStageInfo(data.StageId)
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(data.StageId)
    self.StageId = data.StageId
    self.StageInterInfo = stageInterInfo
    self.Cb = cb
    self.CloseCb = closeCb
    self.OnlyTouchBtn = onlyTouchBtn
    self.IsFirst = true;
    self:InitInfo(data)
    XLuaUiManager.SetMask(true)
    self:PlayRewardAnimation()
end

function XUiSimulatedCombatSettleWin:OnEnable()
    if not self.IsFirst then
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
            self:PlaySecondAnimation()
        end, 0)
    end
end

function XUiSimulatedCombatSettleWin:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
end

-- 奖励动画
function XUiSimulatedCombatSettleWin:PlayRewardAnimation()
    local delay = XDataCenter.FubenManager.SettleRewardAnimationDelay
    local interval = XDataCenter.FubenManager.SettleRewardAnimationInterval
    local this = self

    -- 没有奖励则直接播放第二个动画
    if not self.GridRewardList or #self.GridRewardList == 0 then
        XScheduleManager.ScheduleOnce(function()
            this:PlaySecondAnimation()
        end, delay)
        return
    end

    self.RewardAnimationIndex = 1
    XScheduleManager.Schedule(function()
        if this.RewardAnimationIndex == #self.GridRewardList then
            this:PlayReward(this.RewardAnimationIndex, function()
                this:PlaySecondAnimation()
            end)
        else
            this:PlayReward(this.RewardAnimationIndex)
        end
        this.RewardAnimationIndex = this.RewardAnimationIndex + 1
    end, interval, #self.GridRewardList, delay)
end

-- 第二个动画
function XUiSimulatedCombatSettleWin:PlaySecondAnimation()
    local this = self
    self:PlayAnimation("AnimEnable2", function()
        XLuaUiManager.SetMask(false)
        this:PlayTipMission()
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
        self.IsFirst = false;
    end)
end

function XUiSimulatedCombatSettleWin:PlayTipMission()
    if XDataCenter.TaskForceManager.ShowMaxTaskForceTeamCountChangeTips then
        local missionData = XDataCenter.TaskForceManager.GetTaskForeInfo()
        local taskForeCfg = XDataCenter.TaskForceManager.GetTaskForceConfigById(missionData.ConfigIndex)
        XUiManager.TipMsg(string.format(CS.XTextManager.GetText("MissionTaskTeamCountContent"), taskForeCfg.MaxTaskForceCount), nil, handler(self, self.PlayShowFriend))
        XDataCenter.TaskForceManager.ShowMaxTaskForceTeamCountChangeTips = false
    else
        self:PlayShowFriend()
    end
end

function XUiSimulatedCombatSettleWin:PlayShowFriend()
    if not (self.CurrAssistInfo ~= nil and self.CurrAssistInfo.Id ~= 0 and self.CurrAssistInfo.Id ~= XPlayer.Id) then
        if self.Cb then
            self.Cb()
        end
        return
    end

    if XDataCenter.SocialManager.CheckIsApplyed(self.CurrAssistInfo.Id) or XDataCenter.SocialManager.CheckIsFriend(self.CurrAssistInfo.Id) then
        if self.Cb then
            self.Cb()
        end
        return
    end

    self.TxtName.text = self.CurrAssistInfo.Name
    self.TxtLv.text = self.CurrAssistInfo.Level
    
    XUiPLayerHead.InitPortrait(self.CurrAssistInfo.HeadPortraitId, self.CurrAssistInfo.HeadFrameId, self.Head)

    self.PanelFriend.gameObject:SetActive(true)
    self:PlayAnimation("PanelFriendEnable", self.Cb)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiSimulatedCombatSettleWin:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiSimulatedCombatSettleWin:AutoInitUi()
    self.PanelNorWinInfo = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo")
    self.PanelNor = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor")
    self.PanelBtn = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn")
    self.PanelBtns = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns")
    self.BtnLeft = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnLeft"):GetComponent("Button")
    self.TxtLeft = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnLeft/TxtLeft"):GetComponent("Text")
    self.BtnRight = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnRight"):GetComponent("Button")
    self.TxtRight = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnRight/TxtRight"):GetComponent("Text")
    self.PanelTouch = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelTouch")
    self.BtnBlock = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelTouch/BtnBlock"):GetComponent("Button")
    self.TxtLeftA = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelTouch/BtnBlock/TxtLeft"):GetComponent("Text")
    self.PanelLeft = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft")
    self.PanelCond = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/PanelCond")
    self.PanelCondContent = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/PanelCond/PanelCondContent")
    self.GridCond = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/PanelCond/PanelCondContent/GridCond")
    self.PanelRoleContent = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/Team/PanelRoleContent")
    self.GridWinRole = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/Team/PanelRoleContent/GridWinRole")
    self.PanelRight = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight")
    self.TxtChapterName = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/StageInfo/TxtChapterName"):GetComponent("Text")
    self.TxtStageName = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/StageInfo/TxtStageName"):GetComponent("Text")
    self.PanelRewardContent = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/RewardList/Viewport/PanelRewardContent")
    self.GridReward = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/RewardList/Viewport/PanelRewardContent/GridReward")
    self.PanelFriend = self.Transform:Find("SafeAreaContentPane/PanelFriend")
    self.PanelInf = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf")
    self.PanelHead = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf/PanelHead")
    self.TxtName = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf/TxtName"):GetComponent("Text")
    self.TxtLv = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf/TxtLv"):GetComponent("Text")
    self.BtnFriClose = self.Transform:Find("SafeAreaContentPane/PanelFriend/BtnFriClose"):GetComponent("Button")
    self.BtnFriAdd = self.Transform:Find("SafeAreaContentPane/PanelFriend/BtnFriAdd"):GetComponent("Button")
    self.PanelPlayerExpBar = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/PlayerExp/PanelPlayerExpBar")
    self.PanelFirst = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelFirst")
    self.PanelRewardList = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/RewardList")
    self.PanelAssist = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/PanelAssist")
    self.TxtAssist = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/PanelAssist/TxtAssist"):GetComponent("Text")
end

function XUiSimulatedCombatSettleWin:AutoAddListener()
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick)
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnBlockClick)
    self:RegisterClickEvent(self.BtnFriClose, self.OnBtnFriCloseClick)
    self:RegisterClickEvent(self.BtnFriAdd, self.OnBtnFriAddClick)
end
-- auto

function XUiSimulatedCombatSettleWin:InitInfo(data)
    XTipManager.Execute()
    self:UpdateConditions(data.StageId, data.StarsMap)
    self:SetBtnsInfo(data)
    self:SetStageInfo(data)
    self:UpdatePlayerInfo(data)
    self:InitRobotList(data)
    self:InitRewardList(data.RewardGoodsList)
    XTipManager.Add(function()
        if data.UrgentId > 0 then
            XLuaUiManager.Open("UiSettleUrgentEvent", data.UrgentId)
        end
    end)
end

function XUiSimulatedCombatSettleWin:SetBtnsInfo(data)
    local canGetReward = false
    if self.StageInterInfo.Type == XFubenSimulatedCombatConfig.StageType.Challenge then
        self.PanelRewardInfo.gameObject:SetActiveEx(true)
        local remainTime = XDataCenter.FubenSimulatedCombatManager.GetDailyRewardRemainCount()
        self.TxtRewardTime.text = remainTime
        if remainTime > 0 then
            canGetReward = true
        end
    elseif self.StageInterInfo.Type == XFubenSimulatedCombatConfig.StageType.Normal then
        self.PanelRewardInfo.gameObject:SetActiveEx(false)
    end
    self.PanelTouch.gameObject:SetActive(not canGetReward)
    self.PanelBtns.gameObject:SetActive(canGetReward)
end

function XUiSimulatedCombatSettleWin:SetStageInfo(data)
    self.PanelFirst.gameObject:SetActiveEx(false)

    local chapterName, stageName = XDataCenter.FubenManager.GetFubenNames(data.StageId)
    self.TxtChapterName.text = chapterName
    self.TxtStageName.text = stageName
end

-- 角色奖励列表
function XUiSimulatedCombatSettleWin:InitRobotList(data)
    self.GridWinRole.gameObject:SetActive(false)

    for i, v in ipairs(data.NpcInfo) do
        if v.CharacterId > 0 then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
            local grid = XUiGridWinRole.New(self, ui)
            grid.Transform:SetParent(self.PanelRoleContent, false)
            local data = XDataCenter.FubenSimulatedCombatManager.GetCurStageMemberDataByCharId(v.CharacterId)
            grid:UpdateRobotInfo(data.RobotId ,data.Star)
            grid.GameObject:SetActive(true)
        end
    end
end

-- 玩家经验
function XUiSimulatedCombatSettleWin:UpdatePlayerInfo(data)
    if not data or not next(data) then return end

    local lastLevel = data.RoleLevel
    local lastExp = data.RoleExp
    local lastMaxExp = XPlayerManager.GetMaxExp(lastLevel, XPlayer.IsHonorLevelOpen())
    local curLevel = XPlayer.GetLevelOrHonorLevel()
    local curExp = XPlayer.Exp
    local curMaxExp = XPlayerManager.GetMaxExp(curLevel, XPlayer.IsHonorLevelOpen())
    local txtLevelName = XPlayer.IsHonorLevelOpen() and CS.XTextManager.GetText("HonorLevel") or CS.XTextManager.GetText("PlayerLevelShort")
    local addExp = XDataCenter.FubenManager.GetTeamExp(self.StageId)
    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.PlayerExpBar:LetsRoll(lastLevel, lastExp, lastMaxExp, curLevel, curExp, curMaxExp, addExp, txtLevelName)
end

-- 物品奖励列表
function XUiSimulatedCombatSettleWin:InitRewardList(rewardGoodsList)
    self.PanelAssist.gameObject:SetActiveEx(false)
    self.PanelRewardList.gameObject:SetActiveEx(true)

    if self.StageInterInfo.Type == XFubenSimulatedCombatConfig.StageType.Challenge then
        local remainTime = XDataCenter.FubenSimulatedCombatManager.GetDailyRewardRemainCount()
        if remainTime <= 0 then
            self.TxtRewardTimeTitle.gameObject:SetActiveEx(true)
            self.TxtRewardTimeTitle.text = CS.XTextManager.GetText("SimulatedCombatNoRewardTodayTip")
            return
        end
    end

    rewardGoodsList = rewardGoodsList or {}
    self.GridRewardList = {}
    local rewards = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    for _, item in ipairs(rewards) do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
        local grid = XUiGridCommon.New(self, ui)
        grid.Transform:SetParent(self.PanelRewardContent, false)
        grid:Refresh(item, nil, nil, true)
        grid.GameObject:SetActive(false)
        table.insert(self.GridRewardList, grid)
    end
end

-- 显示胜利满足的条件
function XUiSimulatedCombatSettleWin:UpdateConditions(stageId, starMap)
    self.GridCond.gameObject:SetActive(false)
    if starMap == nil then
        self.PanelCond.gameObject:SetActiveEx(false)
        return
    end

    self.GridCondList = {}
    for i = 1, #starMap do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridCond)
        local grid = XUiGridCond.New(ui)
        grid.Transform:SetParent(self.PanelCondContent, false)
        local clgInfo = XFubenSimulatedCombatConfig.GetChallengeById(self.StageInterInfo.ChallengeIds[i])
        if clgInfo then
            grid:Refresh(clgInfo.Description, starMap[i])
            grid.GameObject:SetActive(true)
        end
        self.GridCondList[i] = grid
    end
end

function XUiSimulatedCombatSettleWin:OnBtnLeftClick()
    self:Close()
end

function XUiSimulatedCombatSettleWin:OnBtnRightClick()
    XDataCenter.FubenSimulatedCombatManager.GetStageReward(function()
        XUiManager.TipText("SimulatedCombatGetRewardSucc")
        self:Close()
    end)
end

function XUiSimulatedCombatSettleWin:OnBtnEnterNextClick()
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.Tower then
        local stageId = XDataCenter.TowerManager.GetTowerData().CurrentStageId
        if XDataCenter.TowerManager.CheckStageCanEnter(stageId) then
            XLuaUiManager.PopThenOpen("UiNewRoomSingle", stageId)
        else
            local text = CS.XTextManager.GetText("TowerCannotEnter")
            XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
        end
    else
        if self.StageInfos.NextStageId then
            local nextStageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageInfos.NextStageId)
            self:HidePanel()
            XDataCenter.FubenManager.OpenRoomSingle(nextStageCfg)
        else
            local text = CS.XTextManager.GetText("BattleWinMainCannotEnter")
            XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
        end
    end
end

function XUiSimulatedCombatSettleWin:OnBtnBackClick(isRunMain)
    if isRunMain then
        XLuaUiManager.RunMain()
    else
        self:HidePanel()
    end
end

function XUiSimulatedCombatSettleWin:OnBtnBlockClick()
    self:HidePanel()
    if self.CloseCb then
        self:CloseCb()
    end
end

function XUiSimulatedCombatSettleWin:HidePanel()
    self:Close()
end

function XUiSimulatedCombatSettleWin:PlayCondition(index, cb)
    self:PlayAnimation("GirdCond", cb)
end

function XUiSimulatedCombatSettleWin:PlayReward(index, cb)
    self.GridRewardList[index].GameObject:SetActive(true)
    self:PlayAnimation("GridReward", cb)
end