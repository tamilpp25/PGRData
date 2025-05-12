local XUiGridCond = require("XUi/XUiSettleWinMainLine/XUiGridCond")
local XUiGridWinRole = require("XUi/XUiSettleWin/XUiGridWinRole")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiSettleWinCommonDefaultProxy = require("XUi/XUiSettleWin/XUiSettleWinCommonDefaultProxy")
local XUiSettleWinCommon = XLuaUiManager.Register(XLuaUi, "UiSettleWinCommon")

function XUiSettleWinCommon:OnAwake()
    self.WinData = nil
    -- 关卡配置
    self.StageConfig = nil
    self.StageInfo = nil
    -- 星级内容数据
    self.StarsMap = nil
    -- 角色数据
    self.CharData = nil
    self.RoleLevel = nil
    self.RoleExp = nil
    -- 奖励物品数据
    self.RewardGoodsList = nil
    self.RewardGrids = {}
    -- XFubenManager
    self.FubenManager = XDataCenter.FubenManager
    self.SocialManager = XDataCenter.SocialManager
    -- 援助数据
    self.CurrentAssistInfo = nil
    -- UiPanelExpBar 经验条
    self.UiPanelExpBar = nil
    self.Proxy = nil
    self.ChildPanelData = nil
    self.BtnType2Func = {
        [XRoomSingleManager.BtnType.Again] = function()
            XLuaUiManager.PopThenOpen("UiBattleRoleRoom", self.StageConfig.StageId, nil, nil, nil, true)
        end,
        [XRoomSingleManager.BtnType.Next] = function()
            if self.StageInfo == nil then return end
            if self.StageInfo.NextStageId == nil then
                XUiManager.TipMsg(XUiHelper.GetText("BattleWinMainCannotEnter"), XUiManager.UiTipType.Tip)
                return
            end
            self:Close()
            local nextStageConfig = self.FubenManager.GetStageCfg(self.StageInfo.NextStageId)
            if self.FubenManager.CheckPreFight(nextStageConfig) then
                XLuaUiManager.Open("UiBattleRoleRoom", nextStageConfig.StageId)
            end
        end,
        [XRoomSingleManager.BtnType.Main] = function()
            XLuaUiManager.RunMain()
        end,
        [XRoomSingleManager.BtnType.SelectStage] = function()
            self:Close()
        end,
    }
    self:RegisterUiEvents()
end

-- winData : XFubenManager.GetChallengeWinData
function XUiSettleWinCommon:OnStart(winData, proxy)
    self.WinData = winData
    self.StageConfig = self.FubenManager.GetStageCfg(winData.StageId)
    self.StageInfo = self.FubenManager.GetStageInfo(winData.StageId)
    self.StarsMap = winData.StarsMap
    self.CharData = winData.CharExp
    self.RoleLevel = winData.RoleLevel
    self.RoleExp = winData.RoleExp
    self.RewardGoodsList = winData.RewardGoodsList or {}
    self.CurrentAssistInfo = winData.ClientAssistInfo
    local proxyInstance = nil -- 代理实例
    if proxy == nil then -- 使用默认的
        proxyInstance = XUiSettleWinCommonDefaultProxy.New(winData)
    elseif not CheckIsClass(proxy) then -- 使用匿名类
        proxyInstance = CreateAnonClassInstance(proxy, XUiSettleWinCommonDefaultProxy, winData)
    else -- 使用自定义类
        proxyInstance = proxy.New(winData)
    end
    self.Proxy = proxyInstance
    local isStop = self.Proxy:AOPOnStartBefore(self)
    if isStop then return end
    self:RefreshStarContents()
    self:RefreshRoleContents()
    self:RefreshPlayerExp()
    self:RefreshRewards()
    self:RefreshBtns()
    -- 关卡名字
    local chapterName, stageName = self.FubenManager.GetFubenNames(self.StageConfig.StageId)
    self.TxtChapterName.text = chapterName
    self.TxtStageName.text = stageName
    -- 首次通关
    self.PanelFirst.gameObject:SetActiveEx(false)
    self.PanelFriend.gameObject:SetActive(false)
    -- 播放奖励动画
    self:PlayRewardAnim()
    -- 设置子面板配置
    self.ChildPanelData = self.Proxy:GetChildPanelData()
    self:LoadChildPanelInfo()
    self.Proxy:AOPOnStartAfter(self)
    -- "再次挑战"上方显示血清消耗
    self.UiEncorePrice = require("XUi/XUiSettleWin/XUiSettleEncorePrice").New(self, winData.StageId)
end

function XUiSettleWinCommon:OnEnable()
    if self.__finishFirstEnable then
        XScheduleManager.ScheduleOnce(function()
            self:PlayCustomEnableAnim()    
        end, 0)
    end
    self.__finishFirstEnable = true
end

function XUiSettleWinCommon:OnDestroy()
    XUiSettleWinCommon.Super.OnDestroy(self)
    self.UiPanelExpBar:StopAnim()
end

--######################## 私有方法 ########################

function XUiSettleWinCommon:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnLeft, self.OnBtnLeftClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnRight, self.OnBtnRightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnFriendClose, self.OnBtnFriendCloseClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnFriendAdd, self.OnBtnFriendAddClicked)
end

function XUiSettleWinCommon:OnBtnFriendCloseClicked()
    self:PlayAnimation("PanelFriendDisable")
    self.PanelFriend.gameObject:SetActive(false)
end

function XUiSettleWinCommon:OnBtnFriendAddClicked()
    if not self.CurrentAssistInfo then
        return
    end
    XDataCenter.SocialManager.ApplyFriend(self.CurrentAssistInfo.Id)
    self.CurrentAssistInfo = nil
    self:PlayAnimation("PanelFriendDisable")
    self.PanelFriend.gameObject:SetActive(false)
end

function XUiSettleWinCommon:OnBtnLeftClicked()
    self:OnBtnTypeClicked(self.StageConfig.FunctionLeftBtn)
end  

function XUiSettleWinCommon:OnBtnRightClicked()
    self:OnBtnTypeClicked(self.StageConfig.FunctionRightBtn)
end

function XUiSettleWinCommon:OnBtnBackClicked()
    if self.CGPanelBtns.alpha < 1 then
        return
    end
    local firstGotoSkipId = self.StageConfig.FirstGotoSkipId
    if firstGotoSkipId > 0 then
        XFunctionManager.SkipInterface(firstGotoSkipId)
        self:Remove()
        return
    end
    self:Close()
end

function XUiSettleWinCommon:OnBtnTypeClicked(btnType)
    if self.CGPanelBtns.alpha < 1 then
        return
    end
    local func = self.BtnType2Func[btnType]
    if func == nil then
        XLog.Error(string.format("类型%s找不到匹配的按钮方法", btnType))
        return
    end
    func()
end

-- 刷新星级挑战显示内容
function XUiSettleWinCommon:RefreshStarContents()
    self.PanelStar.gameObject:SetActiveEx(#self.StarsMap > 0 and #self.StageConfig.StarDesc > 0)
    XUiHelper.RefreshCustomizedList(self.PanelStarContent, self.GridStarContent, #self.StarsMap
    , function(index, gridGo)
        local grid = XUiGridCond.New(gridGo)
        grid:Refresh(self.StageConfig.StarDesc[index], self.StarsMap[index])
    end)
end

-- 刷新角色内容
function XUiSettleWinCommon:RefreshRoleContents()
    local robotIds = self.StageConfig.RobotId
    if #robotIds > 0 then
        XUiHelper.RefreshCustomizedList(self.PanelRoleContent, self.GridRole, #robotIds
        , function(index, gridGo)
            local grid = XUiGridWinRole.New(self, gridGo)
            grid:UpdateRobotInfo(robotIds[index])
        end)
    else
        XUiHelper.RefreshCustomizedList(self.PanelRoleContent, self.GridRole, #self.CharData
        , function(index, gridGo)
            local grid = XUiGridWinRole.New(self, gridGo)
            local cardExp = XDataCenter.FubenManager.GetCardExp(self.StageConfig.StageId)
            grid:UpdateRoleInfo(self.CharData[index], cardExp)
        end) 
    end
end

function XUiSettleWinCommon:RefreshPlayerExp()
    local currentLevel = XPlayer.GetLevelOrHonorLevel()
    local isHonorLevelOpen = XPlayer.IsHonorLevelOpen()
    local txtName = isHonorLevelOpen and XUiHelper.GetText("HonorLevel") or nil
    local teamExp = XDataCenter.FubenManager.GetTeamExp(self.StageConfig.StageId)
    self.UiPanelExpBar = XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.UiPanelExpBar:LetsRoll(self.RoleLevel, self.RoleExp
        , XPlayerManager.GetMaxExp(self.RoleLevel, isHonorLevelOpen)
        , currentLevel
        , XPlayer.Exp
        , XPlayerManager.GetMaxExp(currentLevel, isHonorLevelOpen)
        , teamExp
        , txtName)
end

function XUiSettleWinCommon:RefreshRewards()
    local rewards = XRewardManager.MergeAndSortRewardGoodsList(self.RewardGoodsList)
    if #rewards > 0 then
        self.RewardGrids = nil
        self.RewardGrids = {}
    end
    XUiHelper.RefreshCustomizedList(self.PanelRewardContent, self.GridReward, #rewards
    , function(index, gridGo)
        local grid = XUiGridCommon.New(self, gridGo)
        grid:Refresh(rewards[index], nil, nil, true)
        grid.GameObject:SetActiveEx(false)
        table.insert(self.RewardGrids, grid)
    end)
end

function XUiSettleWinCommon:RefreshBtns()
    local stageData = self.FubenManager.GetStageData(self.StageConfig.StageId)
    local passTime = stageData and stageData.PassTimesToday or 0
    local useFixBtn = self.StageConfig.HaveFirstPass and passTime < 2
    self.PanelConfigBtns.gameObject:SetActiveEx(not useFixBtn)
    self.PanelFixBtns.gameObject:SetActiveEx(useFixBtn)
    if not useFixBtn then
        local leftType = self.StageConfig.FunctionLeftBtn
        local rightType = self.StageConfig.FunctionRightBtn
        self.BtnLeft.gameObject:SetActive(leftType > 0)
        self.BtnRight.gameObject:SetActive(rightType > 0)
        self.TxtLeft.text = XRoomSingleManager.GetBtnText(leftType)
        self.TxtRight.text = XRoomSingleManager.GetBtnText(rightType)
    end
end

function XUiSettleWinCommon:PlayRewardAnim()
    local delay = self.FubenManager.SettleRewardAnimationDelay
    local interval = self.FubenManager.SettleRewardAnimationInterval
    local rewardCount = #self.RewardGrids
    -- 没有奖励或已经隐藏直接播放第二个动画
    if rewardCount <= 0 or not self.PanelRewardList.gameObject.activeSelf then
        XScheduleManager.ScheduleOnce(function()
            self:PlayCustomEnableAnim()    
        end, delay)
        return
    end
    -- 播放奖励动画
    local animIndex = 1
    local rewardAnimFunc = function(index, callback)
        self.RewardGrids[index].GameObject:SetActiveEx(true)
        self:PlayAnimation("GridReward", callback)
    end
    XScheduleManager.Schedule(function()
        if animIndex == rewardCount then
            rewardAnimFunc(animIndex, function()
                self:PlayCustomEnableAnim()
            end)
        else
            rewardAnimFunc(animIndex)
        end
        animIndex = animIndex + 1
    end, interval, rewardCount, delay)
end

function XUiSettleWinCommon:PlayCustomEnableAnim()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self:PlayAnimation("AnimEnable2", function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:EnableFriendPanel()
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    end)
end

function XUiSettleWinCommon:EnableFriendPanel()
    if not (self.CurrentAssistInfo ~= nil and self.CurrentAssistInfo.Id ~= 0 
        and self.CurrentAssistInfo.Id ~= XPlayer.Id) then
        return
    end
    if self.SocialManager.CheckIsApplyed(self.CurrentAssistInfo.Id) 
        or self.SocialManager.CheckIsFriend(self.CurrentAssistInfo.Id) then
        return
    end
    self.TxtAssistName.text = self.CurrentAssistInfo.Name
    self.TxtAssistLevel.text = self.CurrentAssistInfo.Level
    XUiPlayerHead.InitPortrait(self.CurrentAssistInfo.HeadPortraitId, self.CurrentAssistInfo.HeadFrameId, self.AssistHead)
    self.PanelFriend.gameObject:SetActive(true)
    self:PlayAnimation("PanelFriendEnable")
end

function XUiSettleWinCommon:LoadChildPanelInfo()
    if not self.ChildPanelData then return end
    local childPanelData = self.ChildPanelData
    -- 加载panel asset
    local instanceGo = childPanelData.instanceGo
    if XTool.UObjIsNil(instanceGo) then
        instanceGo = self.PanelExtraUiInfo:LoadPrefab(childPanelData.assetPath)
        childPanelData.instanceGo = instanceGo
        -- 加载panel proxy
        childPanelData.instanceProxy = childPanelData.proxy.New(instanceGo, self)
    end
    -- 加载proxy参数
    local proxyArgs = {}
    if childPanelData.proxyArgs then
        for _, argName in ipairs(childPanelData.proxyArgs) do
            if type(argName) == "string" then
                proxyArgs[#proxyArgs + 1] = self[argName]
            else
                proxyArgs[#proxyArgs + 1] = argName
            end
        end
    end
    childPanelData.instanceProxy:SetData(table.unpack(proxyArgs))
end

return XUiSettleWinCommon