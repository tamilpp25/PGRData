--[[    管理界面的活动按钮相关，
    功能相关和各版本临时代码写在XUiActivityBriefBase.lua（尽量）
]]
local XUiActivityBriefRefreshButton = XClass(nil, "XUiActivityBriefRefreshButton")
local CSXTextManagerGetText = CS.XTextManager.GetText
local XActivityBrieButton = require("XUi/XUiActivityBrief/XActivityBrieButton")

function XUiActivityBriefRefreshButton:Ctor(rootUi, panelType)
    self.GameObject = rootUi.GameObject
    self.Transform = rootUi.Transform
    self.RootUi = rootUi
    self.TlActivityBrieButton = {}
    -- 根据主副面板Id进行Btn事件绑定
    self.PanelType = panelType

    XTool.InitUiObject(self)
end

--@region 按钮的刷新逻辑
function XUiActivityBriefRefreshButton:Refresh()
    -- Logo节点刷新独立于各Btn刷新函数
    self:RefreshLogo()
    -- Btn刷新
    for index, groupId in ipairs(XActivityBriefConfigs.GetGroupIdList(self.PanelType)) do
        local funcName = XActivityBriefConfigs.GetActivityGroupBtnInitMethodName(groupId)
        local func = XUiActivityBriefRefreshButton[funcName]
        -- 设置对应Btn
        self:InitActivityBriefButton(index, groupId)
        if func then
            -- 通用跳转函数临时ActivityGroupId(BtnId)
            self.ActivityGroupId = groupId
            func(self)
            -- 重置临时ActivityGroupId
            self.ActivityGroupId = 0
        end
    end
end

--@endregion
--@region 活动的各个按钮处理函数
--Logo节点的
function XUiActivityBriefRefreshButton:RefreshLogo()
    local nowTime = XTime.GetServerNowTimestamp()
    local taskBeginTime = XActivityBriefConfigs.GetActivityBeginTime()
    local taskEndTime = XActivityBriefConfigs.GetActivityEndTime()
    if taskBeginTime > nowTime or nowTime >= taskEndTime then
        self.TxtTime.gameObject:SetActiveEx(false)
        self.TxtTimeSecond.gameObject:SetActiveEx(false)
    else
        local timeStr = XUiHelper.GetTime(taskEndTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
        -- local textStr = CSXTextManagerGetText("ActivityBriefLeftTime", timeStr)
        self.TxtTime.text = timeStr
        self.TxtTime.gameObject:SetActiveEx(true)        
        self.TxtTimeSecond.text = timeStr
        self.TxtTimeSecond.gameObject:SetActiveEx(true)
    end
end

--===========================================================================
--v1.27 商店
--===========================================================================
function XUiActivityBriefRefreshButton:RefreshActivityShop()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.ActivityBriefShop)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local closeCb = function()
            self.RootUi:PlayAnimationWithMask("AnimEnable1")
        end
        local openCb = function()
            self.RootUi:Close()
        end
        XShopManager.GetShopInfoList(XDataCenter.ActivityBriefManager.GetActivityShopIds(),function()
            XLuaUiManager.Open("UiActivityBriefShop", closeCb, openCb)
        end)
    end)
end

--- 副商店
function XUiActivityBriefRefreshButton:RefreshSecondActivityShop()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.SecondActivityBriefShop)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local closeCb = function()
            self.RootUi:PlayAnimationWithMask("AnimEnable1")
        end
        local openCb = function()
            self.RootUi:Close()
        end
        XShopManager.GetShopInfoList(XDataCenter.ActivityBriefManager.GetActivityShopIds(),function()
            XLuaUiManager.Open("UiActivityBriefShop", closeCb, openCb)
        end)
    end)
end

--- 抽卡
function XUiActivityBriefRefreshButton:RefreshDrawActivity()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.ActivityDrawCard)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.ActivityDrawCard)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

---幻痛囚笼
function XUiActivityBriefRefreshButton:RefreshFubenBossSingle()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.FubenBossSingle)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.FubenBossSingle)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--自走棋
function XUiActivityBriefRefreshButton:RefreshExpedition()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Expedition)
    if not activityBrieButton then
        return
    end

    local isShowTag = XDataCenter.ExpeditionManager.CheckActivityRedPoint()

    activityBrieButton:Refresh()
    activityBrieButton:ShowTag(isShowTag)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Expedition)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--世界Boss
function XUiActivityBriefRefreshButton:RefreshWorldBoss()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.WorldBoss)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.WorldBoss)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshActivityMainLine()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.MainLine)
    if not activityBrieButton then
        return
    end
    local skipConfig = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.MainLine).SkipId
    local skipList = XFunctionConfig.GetSkipList(skipConfig)
    local stageId = skipList and skipList.CustomParams[1]
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    activityBrieButton:AddRedPointEvent({XRedPointConditions.Types.CONDITION_MAINLINE_CHAPTER_REWARD},stageInfo.ChapterId)
    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.MainLine)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--番外篇，普通或困难
function XUiActivityBriefRefreshButton:RefreshActivityExtra()
    self:RefreshActivityExtraByType(XActivityBriefConfigs.ActivityGroupId.Extra, XDataCenter.FubenManager.DifficultNormal)
    self:RefreshActivityExtraByType(XActivityBriefConfigs.ActivityGroupId.Extra2, XDataCenter.FubenManager.DifficultHard)
end

function XUiActivityBriefRefreshButton:RefreshActivityExtraByType(activityGroupId, difficultType)
    local activityBrieButton = self:GetActivityBrieButton(activityGroupId)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh({
        activityGroupId = activityGroupId,
        difficultType = difficultType
    })

    activityBrieButton:AddNewTagEvent({ XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_EXTRA }, {
        activityGroupId = activityGroupId,
        difficultType = difficultType
    })

    local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
    local skipId = config and config.SkipId
    local showRed = false
    if skipId then
        local skipList = XFunctionConfig.GetSkipList(config.SkipId)
        local chapterId = skipList and skipList.CustomParams[1]
        showRed = chapterId and XDataCenter.ExtraChapterManager.CheckTreasureReward(chapterId)
    end
    activityBrieButton:ShowReddot(showRed)

    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--大作战
function XUiActivityBriefRefreshButton:RefreshActivityBigWar()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.BigWar)
    if not activityBrieButton then
        return
    end

    local isShowTag = XDataCenter.FubenSpecialTrainManager.CheckNotPassStage()

    activityBrieButton:Refresh()
    activityBrieButton:ShowTag(isShowTag)
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_SPECIALTRAIN_RED })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.BigWar)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--资源
function XUiActivityBriefRefreshButton:RefreshActivityResource()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Resource)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Resource)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--公会
function XUiActivityBriefRefreshButton:RefreshActivitySociety()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Society)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:GetButtonCom():SetDisable(true) --因为延期，暂时写死

    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Society)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--迷宫
function XUiActivityBriefRefreshButton:RefreshActivityLabyrinth()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Labyrinth)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Labyrinth)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshActivityShortStories()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.ShortStories)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        XLuaUiManager.Open("UiActivityBriefStory")
    end)
end

function XUiActivityBriefRefreshButton:RefreshActivityBranch()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Branch)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Branch)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshActivityBossSingle()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.BossSingle)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:AddNewTagEvent({ XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BOSSSINGLE })

    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.BossSingle)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshActivityBossOnline()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.BossOnline)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.BossOnline)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshAllActivityPrequel()--全部间章
    self:RefreshActivityPrequel(XActivityBriefConfigs.ActivityGroupId.Prequel)
    self:RefreshActivityPrequel(XActivityBriefConfigs.ActivityGroupId.Prequel2)
end

function XUiActivityBriefRefreshButton:RefreshActivityPrequel(activityGroupId)
    local activityBrieButton = self:GetActivityBrieButton(activityGroupId)
    if not activityBrieButton then
    return
    end

    local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
    local skipId = config.SkipId
    local skipList = XFunctionConfig.GetSkipList(skipId)
    local isShowRed = XDataCenter.PrequelManager.CheckRewardAvailable(skipList.CustomParams[2])
    activityBrieButton:Refresh(activityGroupId)
    activityBrieButton:ShowReddot(isShowRed)
    activityBrieButton:AddNewTagEvent({ XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_PREQUEL }, {
        activityGroupId = activityGroupId,
        chapterId = skipList.CustomParams[2]
    })

    activityBrieButton:SetOnClick(function()
        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshActivityBabelTower()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.BabelTower)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:AddNewTagEvent({ XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BABELTOWER })
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BABELTOWER_REWARD })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.BabelTower)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshActivityRogueLike() -- 爬塔
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.RougueLike)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:AddNewTagEvent({ XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_ROGUELIKEMAIN })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.RougueLike)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--===========================================================================
--v1.27 复刷关 - 哈卡玛
--===========================================================================
function XUiActivityBriefRefreshButton:RefreshActivityRepeateChallenge()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.RepeatChallenge)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_REPEAT_CHALLENGE_REWARD })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.RepeatChallenge)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshActivityArenaOnline()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.ArenaOnline)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.ArenaOnline)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshActivityUnionKill()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.UnionKill)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.UnionKill)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshMaintainerAction()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.MaintainerAction)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.MaintainerAction)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshRpgTower()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.RpgTower)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_RPGTOWER_TEAM_RED,XRedPointConditions.Types.CONDITION_RPGTOWER_TASK_RED,XRedPointConditions.Types.CONDITION_RPGTOWER_DAILYREWARD_RED })
    local isShowTag = XDataCenter.RpgTowerManager.GetHaveNewStage()
    activityBrieButton:ShowTag(isShowTag)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.RpgTower)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshTRPG()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.TRPGMainLine)
    if not activityBrieButton then
        return
    end

    local curEndurance = XDataCenter.TRPGManager.GetExploreCurEndurance()
    local maxEndurance = XDataCenter.TRPGManager.GetExploreMaxEndurance()
    local isShowTag = XDataCenter.TRPGManager.IsActivityShowTag()

    self.TxtEndurance.text = CSXTextManagerGetText("TRPGExploreEnduranceForActivity", curEndurance, maxEndurance)
    activityBrieButton:Refresh()
    activityBrieButton:ShowTag(isShowTag)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.TRPGMainLine)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--===========================================================================
--v1.27 新角色预热 - 哈卡玛
--===========================================================================
function XUiActivityBriefRefreshButton:RefreshNewCharActivity()
    local activityGroupId = XActivityBriefConfigs.ActivityGroupId.NewCharActivity
    local activityBrieButton = self:GetActivityBrieButton(activityGroupId)
    if not activityBrieButton then
        return
    end

    local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
    local skipList = XFunctionConfig.GetSkipList(config.SkipId)
    local actId = skipList.CustomParams[1]
    local isShowTag = XDataCenter.FubenNewCharActivityManager.IsChallengeable(actId)
    activityBrieButton:Refresh(actId)
    activityBrieButton:AddRedPointEvent({XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYMAINRED})
    activityBrieButton:ShowTag(isShowTag)
    activityBrieButton:SetOnClick(function()
        XFunctionManager.SkipInterface(config.SkipId)
    end)
end

--===========================================================================
--v1.27 涂装试玩 - 哈卡玛
--===========================================================================
function XUiActivityBriefRefreshButton:RefreshFubenActivityTrial()
    local activityGroupId = XActivityBriefConfigs.ActivityGroupId.FubenActivityTrial
    local activityBrieButton = self:GetActivityBrieButton(activityGroupId)
    if not activityBrieButton then
        return
    end
    local isShowTag = XDataCenter.FubenExperimentManager.CheckSkinTrialRedPoint()

    activityBrieButton:Refresh()
    --activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_FASHION_STORY_HAVE_STAGE })
    activityBrieButton:ShowTag(isShowTag)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshShiTu()
    local activityGroupId = XActivityBriefConfigs.ActivityGroupId.ShiTu
    local activityBrieButton = self:GetActivityBrieButton(activityGroupId)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--尼尔玩法
function XUiActivityBriefRefreshButton:RefreshNier()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Nier)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:AddNewTagEvent({ XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_NIER })
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_NIER_RED })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Nier)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--口袋战双
function XUiActivityBriefRefreshButton:RefreshPokemon()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Pokemon)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    local isShowRed = XRedPointConditionPokemonRed.Check()
    activityBrieButton:ShowReddot(isShowRed)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Pokemon)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--追击玩法
function XUiActivityBriefRefreshButton:RefreshPursuit()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Pursuit)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    local isShowRed = XDataCenter.ChessPursuitManager.CheckIsCanFightTips()
    activityBrieButton:ShowTag(isShowRed)
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_CHESSPURSUIT_REWARD_RED })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Pursuit)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--模拟战
function XUiActivityBriefRefreshButton:RefreshSimulate()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Simulate)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_SIMULATED_COMBAT })
    local isShowTag = XDataCenter.FubenSimulatedCombatManager.IsChallengeable()
    activityBrieButton:ShowTag(isShowTag)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Simulate)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--据点
function XUiActivityBriefRefreshButton:RefreshStrongHold()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.StrongHold)
    if not activityBrieButton then
        return
    end

    activityBrieButton:Refresh()
    local isShowRed = XRedPointConditionStrongholdMineralLeft.Check() or XDataCenter.StrongholdManager.IsAnyRewardCanGet()
    activityBrieButton:ShowReddot(isShowRed)
    local isShowTag = XDataCenter.StrongholdManager.CheckHasUnFinishedCanFightGroup()
    activityBrieButton:ShowTag(isShowTag)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.StrongHold)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end

--伙伴系统
function XUiActivityBriefRefreshButton:RefreshPartner()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Partner)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_PARTNER_COMPOSE_RED,XRedPointConditions.Types.CONDITION_PARTNER_NEWSKILL_RED })

    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Partner)
        local skipId = config.SkipId

        XFunctionManager.SkipInterface(skipId)
    end)
end
--萌战
function XUiActivityBriefRefreshButton:RefreshMoeWar()
	local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.MoeWar)
	if not activityBrieButton then
		return
	end
    activityBrieButton:AddRedPointEvent({XRedPointConditions.Types.CONDITION_MOEWAR_PREPARATION_REWARD,XRedPointConditions.Types.CONDITION_MOEWAR_TASK})
    activityBrieButton:AddNewTagEvent({ XRedPointConditions.Types.CONDITION_MOEWAR_PREPARATION_OPEN_STAGE }, nil, true)
    activityBrieButton:Refresh()
	activityBrieButton:SetOnClick(function()
			local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.MoeWar)
			local skipId = config.SkipId
			XFunctionManager.SkipInterface(skipId)
		end)
end
--宠物抽卡
function XUiActivityBriefRefreshButton:RefreshPetCard()
	local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.PetCard)
	if not activityBrieButton then
		return
	end
	activityBrieButton:Refresh()
	activityBrieButton:SetOnClick(function()
			local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.PetCard)
			local skipId = config.SkipId
			XFunctionManager.SkipInterface(skipId)
		end)
end

--宠物试玩
function XUiActivityBriefRefreshButton:RefreshPetTrial()
	local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.PetTrial)
	if not activityBrieButton then
		return
	end
	activityBrieButton:Refresh()
	activityBrieButton:SetOnClick(function()
			local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.PetTrial)
			local skipId = config.SkipId
			XFunctionManager.SkipInterface(skipId)
		end)
end

--翻牌
function XUiActivityBriefRefreshButton:RefreshPokerGuessing()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.PokerGuessing)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_POKER_GUESSING_RED })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.PokerGuessing)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--端午活动
function XUiActivityBriefRefreshButton:RefreshRpgMaker()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.RpgMaker)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_RPG_MAKER_GAME_RED })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.RpgMaker)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--骇客
function XUiActivityBriefRefreshButton:RefreshHack()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Hack)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_FUBEN_HACK_STAR })
    local isShowTag = XDataCenter.FubenHackManager.IsChallengeable()
    activityBrieButton:ShowTag(isShowTag)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Hack)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--改造
function XUiActivityBriefRefreshButton:RefreshReform()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Reform)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_REFORM_All_RED_POINT })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Reform)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--===========================================================================
--v1.27 双人同行(分光双星)三期
--===========================================================================
function XUiActivityBriefRefreshButton:RefreshCoupleCombat()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.CoupleCombat)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({XRedPointConditions.Types.CONDITION_COUPLE_COMBAT_TASK_REWARD})
    local isShowTag = XDataCenter.FubenCoupleCombatManager.IsChallengeable()
    activityBrieButton:ShowTag(isShowTag)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.CoupleCombat)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--超级爬塔
function XUiActivityBriefRefreshButton:RefreshSuperTower()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.SuperTower)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_SUPERTOWER_ROLE_LEVELUP, XRedPointConditions.Types.CONDITION_SUPERTOWER_ROLE_PLUGIN, XRedPointConditions.Types.CONDITION_SUPERTOWER_ROLE_INDULT })
    local gachaNeedItemCount = XSuperTowerConfigs.GetClientBaseConfigByKey("GachaNeedItemCount", true)
    local gachaItem = XSuperTowerConfigs.GetClientBaseConfigByKey("GachaItemId", true)
    local gachaItemCount = XDataCenter.ItemManager.GetCount(gachaItem)
    activityBrieButton:ShowReddot(gachaItemCount >= gachaNeedItemCount)
    activityBrieButton:ShowTag(true)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.SuperTower)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--杀戮无双
function XUiActivityBriefRefreshButton:RefreshKillZone()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.KillZone)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.XRedPointConditionKillZoneActivity })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.KillZone)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--夏活系列关
function XUiActivityBriefRefreshButton:RefreshSummerSeries()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.SummerSeries)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.SummerSeries)
    local skipId = config.SkipId
    local skipList = XFunctionConfig.GetSkipList(skipId)
    if skipList then
        local chapterId = skipList.CustomParams[1]
        local passCount,totalCount = XDataCenter.FubenFestivalActivityManager.GetFestivalProgress(chapterId)
        activityBrieButton:ShowTag(passCount < totalCount)
    end
    activityBrieButton:SetOnClick(function()
        XFunctionManager.SkipInterface(skipId)
    end)
end

--虚像地平线
function XUiActivityBriefRefreshButton:RefreshExpedition()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Expedition)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_EXPEDITION_CAN_RECRUIT })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Expedition)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--三消游戏
function XUiActivityBriefRefreshButton:RefreshSameColor()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.SameColorGame)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_SAMECOLOR_TASK })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.SameColorGame)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--全服决战
function XUiActivityBriefRefreshButton:RefreshAreaWar()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.AreaWar)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.XRedPointConditionAreaWarActivity })
    activityBrieButton:ShowTag(true)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.AreaWar)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--全服决战
function XUiActivityBriefRefreshButton:RefreshSuperSmashBros()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.SuperSmashBros)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_SUPERSMASHBROS_HAVE_REWARD })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.SuperSmashBros)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshTeachingSkin()
    local activityGroupId = XActivityBriefConfigs.ActivityGroupId.TeachingSkin
    local activityBrieButton = self:GetActivityBrieButton(activityGroupId)
    if not activityBrieButton then
        return
    end

    local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
    local skipList = XFunctionConfig.GetSkipList(config.SkipId)
    local actId = skipList.CustomParams[1]
    activityBrieButton:Refresh(actId)
    activityBrieButton:SetOnClick(function()
        XFunctionManager.SkipInterface(config.SkipId)
    end)
end

--射击玩法 异构阵线
function XUiActivityBriefRefreshButton:RefreshMaverick()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Maverick)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:ShowTag(true)
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_MAVERICK_MAIN })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Maverick)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshMemorySave()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.MemorySave)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_MEMORYSAVE_ALL_RED_POINT })
    local isShowTag = not XDataCenter.MemorySaveManager.IsFinishCurOpened()
    activityBrieButton:ShowTag(isShowTag)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.MemorySave)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshTheatre()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Theatre)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:ShowTag(true)
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_THEATRE_ALL_RED_POINT })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Theatre)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshDoomsDay()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.DoomsDay)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.XRedPointConditionDoomsdayActivity })
    local isShowTag = XDataCenter.DoomsdayManager.CheckHasStageIncomplete()
    activityBrieButton:ShowTag(isShowTag)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.DoomsDay)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--===========================================================================
--v1.27 独域特攻二期
--===========================================================================
function XUiActivityBriefRefreshButton:RefreshPivotCombat()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({XRedPointConditions.Types.CONDITION_PIVOTCOMBAT_TASK_REWARD_RED_POINT})
    end
end

function XUiActivityBriefRefreshButton:RefreshEscape()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.Escape)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Escape)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--===========================================================================
--v1.27 哈卡吗大间章
--===========================================================================
function XUiActivityBriefRefreshButton:RefreshFubenShortStory()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.FubenShortStory)
    if not activityBrieButton then
        return
    end
    local skipConfig = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.FubenShortStory).SkipId
    local skipList = XFunctionConfig.GetSkipList(skipConfig)
    local chapterId = skipList and skipList.CustomParams[1]
    activityBrieButton:AddRedPointEvent({XRedPointConditions.Types.CONDITION_SHORT_STORY_CHAPTER_REWARD},chapterId)
    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.FubenShortStory)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshGoldenMiner()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.GoldenMiner)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    local isCanReward = XDataCenter.GoldenMinerManager.CheckTaskCanReward()
    activityBrieButton:ShowReddot(isCanReward)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.GoldenMiner)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshDoubleTower()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.DoubleTowers)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_DOUBLE_TOWERS })
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.DoubleTowers)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshGuildWar()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.GuildWar)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    local timeOffset = 15 * XScheduleManager.SECOND * 3600
    activityBrieButton:ShowTag(true, timeOffset)
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.GuildWar)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshQiGuan()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.QiGuan)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.QiGuan)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

function XUiActivityBriefRefreshButton:RefreshSecondActivityPanel()
    local activityBrieButton = self:GetActivityBrieButton(XActivityBriefConfigs.ActivityGroupId.SecondBriefPanel)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.SecondBriefPanel)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--===========================================================================
--v1.27 音游小游戏
--===========================================================================
function XUiActivityBriefRefreshButton:RefreshTaiKoMaster()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({XRedPointConditions.Types.CONDITION_ACTIVITY_TAIKO_MASTER_TASK})
        btn:AddNewTagEvent({XRedPointConditions.Types.CONDITION_ACTIVITY_TAIKO_MASTER_CD_UNLOCK})
    end
end

--===========================================================================
--v1.27 多维挑战
--===========================================================================
function XUiActivityBriefRefreshButton:RefreshMultiDim()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:ShowReddot(XDataCenter.MultiDimManager.CheckLimitTaskGroup())
        btn:ShowTag(XDataCenter.MultiDimManager.CheckTeamIsOpen())
    end
end

--@endregion
--@region 通用函数

--===========================================================================
--v1.27 通用Btn事件绑定函数，不包含RedDot和Tag处理
--===========================================================================
function XUiActivityBriefRefreshButton:RefreshNormal()
    if not XTool.IsNumberValid(self.ActivityGroupId) then return end
    local activityGroupId = self.ActivityGroupId

    -- local activityBrieButton = self.TlActivityBrieButton[activityGroupId]
    local activityBrieButton = self:GetActivityBrieButton(activityGroupId)
    if not activityBrieButton then
        return
    end
    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--===========================================================================
--v1.28 活动面板优化：Btn初始化函数
--===========================================================================
function XUiActivityBriefRefreshButton:InitActivityBriefButton(index, groupId)
    local btnName
    if self.PanelType then      -- 主面板按钮占位
        btnName = "MainBtn" .. index
    else                        -- 副面板按钮占位
        btnName = "SecondBtn" .. index
    end
    
    local btn
    local btnGrid = self[btnName]
    if XTool.IsNumberValid(btnGrid.transform.childCount) then
        btn = btnGrid.transform:GetChild(0):GetComponent("XUiButton")
    else
        -- Todo-根据配置读取预制体动态生成
        -- local btnPrefab = btnGrid:LoadPrefab(XActivityBriefConfigs.GetActivityGroupConfig(groupId).BtnPath)
        -- btn = btnPrefab.transform:GetComponent("XUiButton")
        XLog.Error("InitActivityBriefButton() Error: ".. btnName .." 下不存在XUiButton")
        return
    end

    if XTool.UObjIsNil(btn) then
        XLog.Error("InitActivityBriefButton() Error: Prefab文件不包含了XUiButton Component")
        return
    end

    if self.TlActivityBrieButton[groupId] == nil then
        self.TlActivityBrieButton[groupId] = XActivityBrieButton.New(btn, self, groupId)
    end
end

--===========================================================================
--v1.28 活动面板优化：根据activityGroupId获取Btn
--===========================================================================
function XUiActivityBriefRefreshButton:GetActivityBrieButton(activityGroupId)
    if not self.TlActivityBrieButton then
        XLog.Error("GetActivityBrieButton() Error: self.TlActivityBrieButton为空")
        return
    end
    if self.TlActivityBrieButton[activityGroupId] then
        return self.TlActivityBrieButton[activityGroupId]
    else
        XLog.Error("GetActivityBrieButton() Error: Btn不存在 activityGroupId = ", activityGroupId)
        return
    end
end
--@endregion
return XUiActivityBriefRefreshButton