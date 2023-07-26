local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiStageSettleSound = require("XUi/XUiSettleWin/XUiStageSettleSound")

local XUiSettleWinMainLine = XLuaUiManager.Register(XLuaUi, "UiSettleWinMainLine")

function XUiSettleWinMainLine:OnAwake()
    self:InitAutoScript()
    self.GridReward.gameObject:SetActive(false)
end

function XUiSettleWinMainLine:OnStart(data, cb, closeCb, onlyTouchBtn)
    self.WinData = data
    self.StageInfos = XDataCenter.FubenManager.GetStageInfo(data.StageId)
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(data.StageId)
    self.CurrentStageId = data.StageId
    self.CurrAssistInfo = data.ClientAssistInfo
    self.Cb = cb
    self.CloseCb = closeCb
    self.OnlyTouchBtn = onlyTouchBtn
    self.IsFirst = true;
    self:InitInfo(data)
    XLuaUiManager.SetMask(true)
    self:PlayRewardAnimation()
    -- "再次挑战"上方显示血清消耗
    self.UiEncorePrice = require("XUi/XUiSettleWin/XUiSettleEncorePrice").New(self, data.StageId)
    ---@type XUiStageSettleSound
    self.UiStageSettleSound = XUiStageSettleSound.New(self, self.CurrentStageId, true)
end

function XUiSettleWinMainLine:OnEnable()
    if not self.IsFirst then
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
            self:PlaySecondAnimation()
        end, 0)
    end
    self.UiStageSettleSound:PlaySettleSound()
end

function XUiSettleWinMainLine:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
    self.UiStageSettleSound:StopSettleSound()
end

-- 奖励动画
function XUiSettleWinMainLine:PlayRewardAnimation()
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
function XUiSettleWinMainLine:PlaySecondAnimation()
    local this = self
    self:PlayAnimation("AnimEnable2", function()
        XLuaUiManager.SetMask(false)
        this:PlayTipMission()
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
        self.IsFirst = false;
        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_TOWER_CONDITION_LISTENING, XFubenCharacterTowerConfigs.ListeningType.Stage, { StageId = self.StageCfg.StageId })
    end)
end

function XUiSettleWinMainLine:PlayTipMission()
    if XDataCenter.TaskForceManager.ShowMaxTaskForceTeamCountChangeTips then
        local missionData = XDataCenter.TaskForceManager.GetTaskForeInfo()
        local taskForeCfg = XDataCenter.TaskForceManager.GetTaskForceConfigById(missionData.ConfigIndex)
        XUiManager.TipMsg(string.format(CS.XTextManager.GetText("MissionTaskTeamCountContent"), taskForeCfg.MaxTaskForceCount), nil, handler(self, self.PlayShowFriend))
        XDataCenter.TaskForceManager.ShowMaxTaskForceTeamCountChangeTips = false
    else
        self:PlayShowFriend()
    end
end

function XUiSettleWinMainLine:PlayShowFriend()
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
function XUiSettleWinMainLine:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiSettleWinMainLine:AutoInitUi()
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
    self.PaenlRewardList = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/RewardList")
    self.PanelAssist = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/PanelAssist")
    self.TxtAssist = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/PanelAssist/TxtAssist"):GetComponent("Text")
end

function XUiSettleWinMainLine:AutoAddListener()
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick)
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnBlockClick)
    self:RegisterClickEvent(self.BtnFriClose, self.OnBtnFriCloseClick)
    self:RegisterClickEvent(self.BtnFriAdd, self.OnBtnFriAddClick)
end
-- auto
function XUiSettleWinMainLine:OnBtnLeftClick()
    self:SetBtnByType(self.StageCfg.FunctionLeftBtn)
end

function XUiSettleWinMainLine:OnBtnFriCloseClick()
    self:PlayAnimation("PanelFriendDisable")
    self.PanelFriend.gameObject:SetActive(false)
end

function XUiSettleWinMainLine:OnBtnFriAddClick()
    if not self.CurrAssistInfo then
        return
    end

    XDataCenter.SocialManager.ApplyFriend(self.CurrAssistInfo.Id)

    self.CurrAssistInfo = nil
    self:PlayAnimation("PanelFriendDisable")
    self.PanelFriend.gameObject:SetActive(false)
end

function XUiSettleWinMainLine:InitInfo(data)
    self.PanelFriend.gameObject:SetActive(false)
    XTipManager.Execute()

    -- 获取跳转缓存数据 
    self.TeleportRewardCache = XDataCenter.FubenMainLineManager.GetTeleportRewardCache(self.StageInfos.ChapterId)
    if not XTool.IsTableEmpty(self.TeleportRewardCache) then
        -- 清空缓存
        XDataCenter.FubenMainLineManager.RemoveTeleportRewardCache(self.StageInfos.ChapterId)
    end
    
    self:SetBtnsInfo(data)
    self:SetStageInfo(data)
    self:UpdatePlayerInfo(data)
    self:InitRewardCharacterList(data)
    self:InitRewardList(data.RewardGoodsList)
    XTipManager.Add(function()
        if data.UrgentId > 0 then
            XLuaUiManager.Open("UiSettleUrgentEvent", data.UrgentId)
        end
    end)
end

function XUiSettleWinMainLine:SetBtnsInfo(data)
    local stageData = XDataCenter.FubenManager.GetStageData(data.StageId)
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.Tower or self.StageInfos.Type == XDataCenter.FubenManager.StageType.BossSingle then
        self.PanelCond.gameObject:SetActive(false)
    elseif self.StageInfos.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        local challengeId = XDataCenter.ArenaOnlineManager.GetCurChallengeId()
        local stasMap = XDataCenter.ArenaOnlineManager.GetStageStarsMapByChallengeId(challengeId)
        self.PanelCond.gameObject:SetActive(true)
        self:UpdateConditions(data.StageId, stasMap)
    elseif self.StageInfos.Type == XDataCenter.FubenManager.StageType.CerberusGame then
        self.PanelCond.gameObject:SetActive(true)
        self:UpdateConditionsShowForDesc(data.StageId, data.StarsMap)
    else
        self.PanelCond.gameObject:SetActive(true)
        self:UpdateConditions(data.StageId, data.StarsMap)
    end

    local passTimes = stageData and stageData.PassTimesToday or 0
    if (self.StageCfg.HaveFirstPass and passTimes < 2) or self.OnlyTouchBtn then
        self.PanelTouch.gameObject:SetActive(true)
        self.PanelBtns.gameObject:SetActive(false)
    else
        local leftType = self.StageCfg.FunctionLeftBtn
        local rightType = self.StageCfg.FunctionRightBtn

        self.BtnLeft.gameObject:SetActive(leftType > 0)
        self.BtnRight.gameObject:SetActive(rightType > 0)
        self.TxtLeft.text = XRoomSingleManager.GetBtnText(leftType)
        self.TxtRight.text = XRoomSingleManager.GetBtnText(rightType)

        self.PanelTouch.gameObject:SetActive(false)
        self.PanelBtns.gameObject:SetActive(true)
    end
end

function XUiSettleWinMainLine:SetStageInfo(data)
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        local beginData = XDataCenter.FubenManager.GetFightBeginData()
        self.PanelFirst.gameObject:SetActiveEx(not beginData.LastPassed)

        if not beginData.Passed then
            self:PlayAnimation("PanelFirstEnable")
        end
    else
        self.PanelFirst.gameObject:SetActiveEx(false)
    end

    local chapterName, stageName = XDataCenter.FubenManager.GetFubenNames(data.StageId)
    self.TxtChapterName.text = chapterName
    self.TxtStageName.text = stageName
end

-- 角色奖励列表
function XUiSettleWinMainLine:InitRewardCharacterList(data)
    self.GridWinRole.gameObject:SetActive(false)
    if self.StageCfg.RobotId and #self.StageCfg.RobotId > 0 then
        for i = 1, #self.StageCfg.RobotId do
            if self.StageCfg.RobotId[i] > 0 then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
                local grid = XUiGridWinRole.New(self, ui)
                grid.Transform:SetParent(self.PanelRoleContent, false)
                grid:UpdateRobotInfo(self.StageCfg.RobotId[i])
                grid.GameObject:SetActive(true)
            end
        end
    else
        local charExp = data.CharExp
        local count = #charExp
        if count <= 0 then
            return
        end

        for i = 1, count do

            local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
            local grid = XUiGridWinRole.New(self, ui)
            grid.Transform:SetParent(self.PanelRoleContent, false)
            local cardExp = XDataCenter.FubenManager.GetCardExp(self.CurrentStageId)
            -- 获取跳转缓存数据
            for _, info in pairs(self.TeleportRewardCache or {}) do
                for _, v in pairs(info.CharExp or {}) do
                    if v.Id == charExp[i].Id then
                        cardExp = cardExp + info.AddCardExp
                    end
                end
            end
            grid:UpdateRoleInfo(charExp[i], cardExp)
            grid.GameObject:SetActive(true)
        end
    end
end

-- 玩家经验
function XUiSettleWinMainLine:UpdatePlayerInfo(data)
    if not data or not next(data) then return end

    local lastLevel = data.RoleLevel
    local lastExp = data.RoleExp
    local lastMaxExp = XPlayerManager.GetMaxExp(lastLevel, XPlayer.IsHonorLevelOpen())
    local curLevel = XPlayer.GetLevelOrHonorLevel()
    local curExp = XPlayer.Exp
    local curMaxExp = XPlayerManager.GetMaxExp(curLevel, XPlayer.IsHonorLevelOpen())
    local txtLevelName = XPlayer.IsHonorLevelOpen() and CS.XTextManager.GetText("HonorLevel") or nil
    local addExp = XDataCenter.FubenManager.GetTeamExp(self.CurrentStageId)
    -- 获取跳转缓存数据
    for _, info in pairs(self.TeleportRewardCache or {}) do
        addExp = addExp + info.AddTeamExp
    end
    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.PlayerExpBar:LetsRoll(lastLevel, lastExp, lastMaxExp, curLevel, curExp, curMaxExp, addExp, txtLevelName)
end

-- 物品奖励列表
function XUiSettleWinMainLine:InitRewardList(rewardGoodsList)
    local beginData = XDataCenter.FubenManager.GetFightBeginData()
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.ArenaOnline and beginData then
        -- 联机模式若非首通则显示协助次数面板，跳过显示奖励逻辑
        if not XDataCenter.ArenaOnlineManager.CheckSingleMode() and beginData.LastPassed then
            local index = 0
            self.PanelAssist.gameObject:SetActiveEx(true)
            self.PaenlRewardList.gameObject:SetActiveEx(false)
            for _, _ in pairs(beginData.PlayerList) do
                index = index + 1
            end

            if index > 1 then
                local lastAssistCount = XDataCenter.ArenaOnlineManager.GetLastAssistCount()
                self.TxtAssist.text = CS.XTextManager.GetText("ArenaOnlineSettleAssist", lastAssistCount)
            else
                local assistCount = XDataCenter.ArenaOnlineManager.GetAssistCount()
                self.TxtAssist.text = assistCount
            end
            return
        end
    end

    self.PanelAssist.gameObject:SetActiveEx(false)
    self.PaenlRewardList.gameObject:SetActiveEx(true)
    rewardGoodsList = rewardGoodsList or {}
    -- 获取跳转缓存数据
    for _, info in pairs(self.TeleportRewardCache or {}) do
        local rewardList = info.RewardGoodsList or {}
        rewardGoodsList = XTool.MergeArray(rewardGoodsList, rewardList)
    end
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

-- 根据描述数量显示胜利满足的条件
function XUiSettleWinMainLine:UpdateConditionsShowForDesc(stageId, starMap)
    self.GridCond.gameObject:SetActive(false)
    if starMap == nil then
        return
    end

    self.GridCondList = {}
    for i = 1, #starMap do
        local conDesc = self.StageCfg.StarDesc[i]
        if conDesc then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCond)
            local grid = XUiGridCond.New(ui)
            grid.Transform:SetParent(self.PanelCondContent, false)
            grid:Refresh(conDesc, starMap[i])
            grid.GameObject:SetActive(true)
            self.GridCondList[i] = grid
        end
    end
end

-- 显示胜利满足的条件
function XUiSettleWinMainLine:UpdateConditions(stageId, starMap)
    self.GridCond.gameObject:SetActive(false)
    if starMap == nil then
        return
    end

    self.GridCondList = {}
    for i = 1, #starMap do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridCond)
        local grid = XUiGridCond.New(ui)
        grid.Transform:SetParent(self.PanelCondContent, false)
        grid:Refresh(self.StageCfg.StarDesc[i], starMap[i])
        grid.GameObject:SetActive(true)
        self.GridCondList[i] = grid
    end
end

function XUiSettleWinMainLine:OnBtnRightClick()
    self:SetBtnByType(self.StageCfg.FunctionRightBtn)
end

function XUiSettleWinMainLine:SetBtnByType(btnType)
    if btnType == XRoomSingleManager.BtnType.SelectStage then
        self:OnBtnBackClick(false)
    elseif btnType == XRoomSingleManager.BtnType.Again then
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom", self.StageCfg.StageId, nil, nil, nil, true)
    elseif btnType == XRoomSingleManager.BtnType.Next then
        self:OnBtnEnterNextClick()
    elseif btnType == XRoomSingleManager.BtnType.Main then
        self:OnBtnBackClick(true)
    elseif btnType == XRoomSingleManager.BtnType.ArenaOnlineBack then
        self:OnArenaOnlineBtnBackClick()
    elseif btnType == XRoomSingleManager.BtnType.ArenaOnlineAgain then
        self:OnArenaOnlineBtnAgainClick()
    end
end

function XUiSettleWinMainLine:OnBtnEnterNextClick()
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.Tower then
        local stageId = XDataCenter.TowerManager.GetTowerData().CurrentStageId
        if XDataCenter.TowerManager.CheckStageCanEnter(stageId) then
            XLuaUiManager.PopThenOpen("UiBattleRoleRoom", stageId)
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

function XUiSettleWinMainLine:OnBtnBackClick(isRunMain)
    if isRunMain then
        XLuaUiManager.RunMain()
    else
        self:HidePanel()
    end
end

-- 区域联机退出队伍
function XUiSettleWinMainLine:OnArenaOnlineBtnBackClick()
    if XDataCenter.ArenaOnlineManager.JudgeGotoMainWhenFightOver(self.WinData.StageId) then
        return
    end

    local title = CS.XTextManager.GetText("TipTitle")
    local cancelMatchMsg = CS.XTextManager.GetText("ArenaOnlineInstanceQuitRoom")
    XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
        XLuaUiManager.CloseWithCallback("UiSettleWinMainLine", function()
            if not XDataCenter.ArenaOnlineManager.CheckSingleMode() then
                XDataCenter.RoomManager.Quit(function()
                    XDataCenter.RoomManager.CloseMultiPlayerRoom()
                end)
            end
        end)
    end)
end

-- 区域联机维持本队
function XUiSettleWinMainLine:OnArenaOnlineBtnAgainClick()
    if XDataCenter.ArenaOnlineManager.JudgeGotoMainWhenFightOver(self.WinData.StageId) then
        return
    end

    self:HidePanel()
end

function XUiSettleWinMainLine:OnBtnBlockClick()

    if self.StageCfg.FirstGotoSkipId > 0 then
        XFunctionManager.SkipInterface(self.StageCfg.FirstGotoSkipId)
        self:Remove()
    else
        self:HidePanel()
    end

    if self.CloseCb then
        self:CloseCb()
    end
end

function XUiSettleWinMainLine:HidePanel()
    self:Close()
end

function XUiSettleWinMainLine:PlayCondition(index, cb)
    self:PlayAnimation("GirdCond", cb)
end

function XUiSettleWinMainLine:PlayReward(index, cb)
    self.GridRewardList[index].GameObject:SetActive(true)
    self:PlayAnimation("GridReward", cb)
end