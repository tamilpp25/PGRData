local XUiSettleWinTutorialCount=XLuaUiManager.Register(XLuaUi,'UiSettleWinTutorialCount')
local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiStageSettleSound = require("XUi/XUiSettleWin/XUiStageSettleSound")

local SyncStageType=
{
    TeachingActivity=1,
    PracticeFight=2
}

--region 生命周期
function XUiSettleWinTutorialCount:OnAwake()
    self:InitAutoScript()
    self.GridReward.gameObject:SetActive(false)
    self.GridReward2.gameObject:SetActive(false)
end

function XUiSettleWinTutorialCount:OnStart(data, cb, closeCb, onlyTouchBtn,displayStar)
    self.WinData = data
    self.StageInfos = XDataCenter.FubenManager.GetStageInfo(data.StageId)
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(data.StageId)
    self.CurrentStageId = data.StageId
    if displayStar then
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.CurrentStageId)
        self.HasStarDesc=(next(stageCfg.StarDesc) and true or false)
    else
        self.HasStarDesc=false
    end
    self.HasSyncPassedStage=not XTool.IsTableEmpty(self.WinData.SettleData.TeachingActivityFightResult) or not XTool.IsTableEmpty(self.WinData.SettleData.PracticeFightResult)
    if self.HasSyncPassedStage then
        self.SyncPassedResult=self.WinData.SettleData.TeachingActivityFightResult or self.WinData.SettleData.PracticeFightResult
        self.SyncType=self.WinData.SettleData.TeachingActivityFightResult and SyncStageType.TeachingActivity or (self.WinData.SettleData.PracticeFightResult and SyncStageType.PracticeFight or nil)
    end
    self.CurrAssistInfo = data.ClientAssistInfo
    self.Cb = cb
    self.CloseCb = closeCb
    self.OnlyTouchBtn = onlyTouchBtn
    self.IsFirst = true;
    self:InitInfo(data)
    XLuaUiManager.SetMask(true)
    self:PlayRewardAnimation()
    ---@type XUiStageSettleSound
    self.UiStageSettleSound = XUiStageSettleSound.New(self, self.CurrentStageId, true)
end

function XUiSettleWinTutorialCount:OnEnable()
    if not self.IsFirst then
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
            self:PlaySecondAnimation()
        end, 0)
    end
    self.UiStageSettleSound:PlaySettleSound()
end

function XUiSettleWinTutorialCount:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
    self.UiStageSettleSound:StopSettleSound()
end

--endregion

--region 事件
function XUiSettleWinTutorialCount:OnBtnFriCloseClick()
    self:PlayAnimation("PanelFriendDisable")
    self.PanelFriend.gameObject:SetActive(false)
end

function XUiSettleWinTutorialCount:OnBtnFriAddClick()
    if not self.CurrAssistInfo then
        return
    end

    XDataCenter.SocialManager.ApplyFriend(self.CurrAssistInfo.Id)

    self.CurrAssistInfo = nil
    self:PlayAnimation("PanelFriendDisable")
    self.PanelFriend.gameObject:SetActive(false)
end

function XUiSettleWinTutorialCount:OnBtnEnterNextClick()
    if self.StageInfos.NextStageId then
        local nextStageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageInfos.NextStageId)
        self:HidePanel()
        XDataCenter.FubenManager.OpenRoomSingle(nextStageCfg)
    else
        local text = CS.XTextManager.GetText("BattleWinMainCannotEnter")
        XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
    end
end

function XUiSettleWinTutorialCount:OnBtnBackClick(isRunMain)
    if isRunMain then
        XLuaUiManager.RunMain()
    else
        self:HidePanel()
    end
end

function XUiSettleWinTutorialCount:OnBtnBlockClick()

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
--endregion

--region 显示更新
function XUiSettleWinTutorialCount:InitInfo(data)
    self.PanelFriend.gameObject:SetActive(false)
    XTipManager.Execute()

    -- 获取跳转缓存数据 
    self.TeleportRewardCache = XDataCenter.FubenMainLineManager.GetTeleportRewardCache(self.StageInfos.ChapterId)
    if not XTool.IsTableEmpty(self.TeleportRewardCache) then
        -- 清空缓存
        XDataCenter.FubenMainLineManager.RemoveTeleportRewardCache(self.StageInfos.ChapterId)
    end

    self.PanelLeft.gameObject:SetActiveEx(self.HasStarDesc)
    self.Panelcelica.gameObject:SetActiveEx(not self.HasStarDesc)

    self:SetBtnsInfo(data)
    self:SetStageInfo(data)
    self:UpdatePlayerInfo(data)
    self:InitRewardCharacterList(data)
    self:InitRewardList(data.RewardGoodsList)
    self:InitSyncPassedStageRewardList()
    XTipManager.Add(function()
        if data.UrgentId > 0 then
            XLuaUiManager.Open("UiSettleUrgentEvent", data.UrgentId)
        end
    end)
end

function XUiSettleWinTutorialCount:SetBtnsInfo(data)
    local stageData = XDataCenter.FubenManager.GetStageData(data.StageId)
    self.PanelCond.gameObject:SetActiveEx(self.HasStarDesc)
    self:UpdateConditions(data.StageId, data.StarsMap)
    self.PanelTouch.gameObject:SetActiveEx(true)
end

function XUiSettleWinTutorialCount:SetStageInfo(data)
    self.PanelFirst.gameObject:SetActiveEx(false)
    local chapterName, stageName = XDataCenter.FubenManager.GetFubenNames(data.StageId)
end
-- 角色奖励列表
function XUiSettleWinTutorialCount:InitRewardCharacterList(data)
    self.GridWinRole.gameObject:SetActiveEx(false)
    self.GridWinRole2.gameObject:SetActiveEx(false)
    local usingGridWinRole=self.HasStarDesc and self.GridWinRole or self.GridWinRole2
    local usingRootTrans=self.HasStarDesc and self.PanelRoleContent or self.PanelRoleContent2
    if self.StageCfg.RobotId and #self.StageCfg.RobotId > 0 then
        for i = 1, #self.StageCfg.RobotId do
            if self.StageCfg.RobotId[i] > 0 then
                local ui = CS.UnityEngine.Object.Instantiate(usingGridWinRole)
                local grid = XUiGridWinRole.New(self, ui)
                grid.Transform:SetParent(usingRootTrans, false)
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

            local ui = CS.UnityEngine.Object.Instantiate(usingGridWinRole)
            local grid = XUiGridWinRole.New(self, ui)
            grid.Transform:SetParent(usingRootTrans, false)
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
function XUiSettleWinTutorialCount:UpdatePlayerInfo(data)
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
    local usingExpBarPrefab=self.HasStarDesc and self.PanelPlayerExpBar or self.PanelPlayerExpBar2
    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(usingExpBarPrefab)
    self.PlayerExpBar:LetsRoll(lastLevel, lastExp, lastMaxExp, curLevel, curExp, curMaxExp, addExp, txtLevelName)
end

-- 物品奖励列表
function XUiSettleWinTutorialCount:InitRewardList(rewardGoodsList)
    self.RewardList.gameObject:SetActiveEx(true)
    self.Txt01.gameObject:SetActiveEx(self.HasSyncPassedStage)
    if self.HasSyncPassedStage then
        if self.SyncType==SyncStageType.PracticeFight then
            self.Txt01.text=XUiHelper.GetText('SettleWinTutorialSyncPractice',XFubenNewCharConfig.GetNewCharKoroCfg().Name,XDataCenter.FubenManager.GetStageDes(self.CurrentStageId))
        elseif self.SyncType==SyncStageType.TeachingActivity then
            self.Txt01.text=XUiHelper.GetText('SettleWinTutorialSyncTeaching',XDataCenter.FubenManager.GetStageDes(self.CurrentStageId))
            XDataCenter.PracticeManager.RefreshStagePassedByStageId(self.SyncPassedResult.LinkStageId)
        end
    end
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

function XUiSettleWinTutorialCount:InitSyncPassedStageRewardList()
    self.PanelRight2.gameObject:SetActiveEx(self.HasSyncPassedStage and not XTool.IsTableEmpty(self.SyncPassedResult.LinkStageRewardGoodsList))
    if self.HasSyncPassedStage then
        local rewardGoodsList=self.SyncPassedResult.LinkStageRewardGoodsList
        rewardGoodsList = rewardGoodsList or {}
        -- 获取跳转缓存数据
        for _, info in pairs(self.TeleportRewardCache or {}) do
            local rewardList = info.RewardGoodsList or {}
            rewardGoodsList = XTool.MergeArray(rewardGoodsList, rewardList)
        end
        self.GridRewardList2 = {}
        local rewards = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
        for _, item in ipairs(rewards) do
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward2)
            local grid = XUiGridCommon.New(self, ui)
            grid.Transform:SetParent(self.PanelRewardContent2, false)
            grid:Refresh(item, nil, nil, true)
            grid.GameObject:SetActive(false)
            table.insert(self.GridRewardList2, grid)
        end
    end
end

-- 根据描述数量显示胜利满足的条件
function XUiSettleWinTutorialCount:UpdateConditionsShowForDesc(stageId, starMap)
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
function XUiSettleWinTutorialCount:UpdateConditions(stageId, starMap)
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

--endregion

-- 奖励动画
function XUiSettleWinTutorialCount:PlayRewardAnimation()
    local delay = XDataCenter.FubenManager.SettleRewardAnimationDelay
    local interval = XDataCenter.FubenManager.SettleRewardAnimationInterval
    local this = self

    local noRewardList=XTool.IsTableEmpty(self.GridRewardList)
    local noRewardList2=XTool.IsTableEmpty(self.GridRewardList2)
    -- 没有奖励则直接播放第二个动画
    if noRewardList and noRewardList2 then
        XScheduleManager.ScheduleOnce(function()
            this:PlaySecondAnimation()
        end, delay)
        return
    end

    self.RewardAnimationIndex = 1
    self.RewardAnimationIndex2 = 1
    self.RewardListAnimEnd=noRewardList and true or false
    self.RewardList2AnimEnd=noRewardList2 and true or false
    self.HasPlaySecondAnim=false
    --自身关卡奖励显示演出
    if not noRewardList then
        XScheduleManager.Schedule(function()
            if this.RewardAnimationIndex == #self.GridRewardList then
                self.RewardListAnimEnd=true
                if self.RewardList2AnimEnd and not self.HasPlaySecondAnim then
                    self.HasPlaySecondAnim=true
                    this:PlayReward(this.RewardAnimationIndex, function()
                        this:PlaySecondAnimation()
                    end)
                else
                    this:PlayReward(this.RewardAnimationIndex)
                end
            else
                this:PlayReward(this.RewardAnimationIndex)
            end
            this.RewardAnimationIndex = this.RewardAnimationIndex + 1
        end, interval, #self.GridRewardList, delay)
    end

    --同步关卡奖励显示演出
    if not noRewardList2 then
        XScheduleManager.Schedule(function()
            if this.RewardAnimationIndex2==#self.GridRewardList2 then
                self.RewardList2AnimEnd=true
                if self.RewardListAnimEnd and not self.HasPlaySecondAnim then
                    self.HasPlaySecondAnim=true
                    this:PlayReward2(this.RewardAnimationIndex2, function()
                        this:PlaySecondAnimation()
                    end)
                else
                    this:PlayReward2(this.RewardAnimationIndex2)
                end
            else
                this:PlayReward2(this.RewardAnimationIndex2)
            end
            this.RewardAnimationIndex2 = this.RewardAnimationIndex2 + 1
        end, interval, #self.GridRewardList2, delay)
    end
end

-- 第二个动画
function XUiSettleWinTutorialCount:PlaySecondAnimation()
    local this = self
    self:PlayAnimation("AnimEnable2", function()
        XLuaUiManager.SetMask(false)
        this:PlayTipMission()
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
        self.IsFirst = false;
        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_TOWER_CONDITION_LISTENING, XFubenCharacterTowerConfigs.ListeningType.Stage, { StageId = self.StageCfg.StageId })
    end)
end

function XUiSettleWinTutorialCount:PlayTipMission()
    if XDataCenter.TaskForceManager.ShowMaxTaskForceTeamCountChangeTips then
        local missionData = XDataCenter.TaskForceManager.GetTaskForeInfo()
        local taskForeCfg = XDataCenter.TaskForceManager.GetTaskForceConfigById(missionData.ConfigIndex)
        XUiManager.TipMsg(string.format(CS.XTextManager.GetText("MissionTaskTeamCountContent"), taskForeCfg.MaxTaskForceCount), nil, handler(self, self.PlayShowFriend))
        XDataCenter.TaskForceManager.ShowMaxTaskForceTeamCountChangeTips = false
    else
        self:PlayShowFriend()
    end
end

function XUiSettleWinTutorialCount:PlayShowFriend()
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
function XUiSettleWinTutorialCount:InitAutoScript()
    self:AutoAddListener()
end

function XUiSettleWinTutorialCount:AutoAddListener()
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnBlockClick)
    self:RegisterClickEvent(self.BtnFriClose, self.OnBtnFriCloseClick)
    self:RegisterClickEvent(self.BtnFriAdd, self.OnBtnFriAddClick)
end
-- auto

function XUiSettleWinTutorialCount:SetBtnByType(btnType)
    if btnType == XRoomSingleManager.BtnType.SelectStage then
        self:OnBtnBackClick(false)
    elseif btnType == XRoomSingleManager.BtnType.Again then
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom", self.StageCfg.StageId, nil, nil, nil, true)
    elseif btnType == XRoomSingleManager.BtnType.Next then
        self:OnBtnEnterNextClick()
    elseif btnType == XRoomSingleManager.BtnType.Main then
        self:OnBtnBackClick(true)
    end
end

function XUiSettleWinTutorialCount:HidePanel()
    self:Close()
end

function XUiSettleWinTutorialCount:PlayCondition(index, cb)
    self:PlayAnimation("GirdCond", cb)
end

function XUiSettleWinTutorialCount:PlayReward(index, cb)
    self.GridRewardList[index].GameObject:SetActive(true)
    self:PlayAnimation("GridReward", cb)
end

function XUiSettleWinTutorialCount:PlayReward2(index, cb)
    self.GridRewardList2[index].GameObject:SetActive(true)
    self:PlayAnimation("GridReward", cb)
end

return XUiSettleWinTutorialCount