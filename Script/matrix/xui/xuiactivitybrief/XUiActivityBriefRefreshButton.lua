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
    ---@type table<number, XActivityBrieButton>
    self.TlActivityBrieButton = {}
    -- 根据主副面板Id进行Btn事件绑定
    self.PanelType = panelType

    XTool.InitUiObject(self)
end

---刷新总接口
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
    -- self:CheckBtnUnlockAnim()
end

--region 按钮的刷新逻辑

---v1.28 活动面板优化:Btn初始化函数
---@param index number ActivityBriefGroup.tab的GroupIdList的下标索引
---@param groupId number ActivityBriefGroup.tab的Id,对应XActivityBriefConfigs.ActivityGroupId
function XUiActivityBriefRefreshButton:InitActivityBriefButton(index, groupId)
    local btnName
    if self.PanelType == XActivityBriefConfigs.PanelType.Main then     -- 主面板按钮占位
        btnName = "MainBtn" .. index
    else                            -- 副面板按钮占位
        btnName = "SecondBtn" .. index
    end
    local btn
    local btnGrid = self[btnName]
    if XTool.IsNumberValid(btnGrid.transform.childCount) then
        btn = btnGrid.transform:GetChild(0):GetComponent("XUiButton")
    else
        XLog.Error("InitActivityBriefButton() Error: ".. btnName .." 下不存在Button")
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

---v1.28 活动面板优化:根据activityGroupId获取Btn
---@param activityGroupId number ActivityBriefGroup.tab的Id,对应XActivityBriefConfigs.ActivityGroupId
---@return XActivityBrieButton|nil
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

---Logo节点刷新接口
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

---v1.27 通用Btn事件绑定函数,不包含RedDot和Tag处理
function XUiActivityBriefRefreshButton:RefreshNormal()
    if not XTool.IsNumberValid(self.ActivityGroupId) then return end
    local activityGroupId = self.ActivityGroupId

    local activityBrieButton = self:GetActivityBrieButton(activityGroupId)
    if not activityBrieButton then
        return
    end
    local tagCondition = XActivityBriefConfigs.GetActivityBriefGroupTagCondition(activityGroupId)
    local tagOffset = XActivityBriefConfigs.GetActivityBriefGroupTagOffset(activityGroupId) * 3600
    if not string.IsNilOrEmpty(tagCondition) then
        if tagCondition == "Default" then
            activityBrieButton:ShowTag(true)
        elseif XRedPointConditions.Types[tagCondition] then
            activityBrieButton:AddNewTagEvent({ XRedPointConditions.Types[tagCondition] }, nil, false, tagOffset)
        elseif XTool.IsNumberValid(tagOffset) then
            activityBrieButton:ShowTag(true, tagOffset)
        end
    elseif XTool.IsNumberValid(tagOffset) then
        activityBrieButton:ShowTag(true, tagOffset)
    end
    activityBrieButton:Refresh()
    activityBrieButton:SetOnClick(function()
        local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
        local skipId = config.SkipId
        XFunctionManager.SkipInterface(skipId)
    end)
end

--endregion


--region 解锁动画相关

---检查是否有动画要解锁
function XUiActivityBriefRefreshButton:CheckBtnUnlockAnim()
    self.UnlockAcitvityList = XDataCenter.ActivityBriefManager.GetNeedUnlockAnimGroupIdList(self.PanelType)
    if XTool.IsTableEmpty(self.UnlockAcitvityList) then
        return
    end
    -- 播放列表索引
    self.UnLockAnimPlayIndex = 1
    self:PlayBtnUnlockAnim()
end

---动画递归回调方法
function XUiActivityBriefRefreshButton:PlayBtnUnlockAnim()
    local btn = self.TlActivityBrieButton[self.UnlockAcitvityList[self.UnLockAnimPlayIndex]]
    if self.UnLockAnimPlayIndex == 1 then
        XLuaUiManager.SetMask(true)
    end
    self.UnLockAnimPlayIndex = self.UnLockAnimPlayIndex + 1
    if btn then
        btn:PlayUnlockAnim(function ()
            self:PlayBtnUnlockAnim()
        end)
    else
        self.UnLockAnimPlayIndex = 1
        XLuaUiManager.SetMask(false)
    end
end

--endregion


--region 活动的各个按钮处理函数

--常驻 商店
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
        XDataCenter.ActivityBriefManager.OpenShop(closeCb, openCb)
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
        XDataCenter.ActivityBriefManager.OpenShop(closeCb, openCb)
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

--幻痛囚笼
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
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        local skipConfig = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.MainLine).SkipId
        local skipList = XFunctionConfig.GetSkipList(skipConfig)
        local stageId = skipList and skipList.CustomParams[1]
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        btn:AddRedPointEvent({XRedPointConditions.Types.CONDITION_MAINLINE_CHAPTER_REWARD},stageInfo.ChapterId)
    end
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
        XFunctionManager.SkipInterface(skipId)
    end)
end

--v2.4 特训关:大作战/魔方2.0/元宵/冰雪感谢祭
function XUiActivityBriefRefreshButton:RefreshActivitySpecialTrain()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        --local isShowTag = XDataCenter.FubenSpecialTrainManager.CheckNotPassStage()
        --btn:ShowTag(isShowTag)
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_SPECIALTRAIN_RED })
    end
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

-- v2.6 超难关
function XUiActivityBriefRefreshButton:RefreshActivityBossSingle()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        local isShowRed = XDataCenter.FubenActivityBossSingleManager.CheckRedPoint()
        btn:ShowReddot(isShowRed)
    end
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

--v2.6 巴别塔
function XUiActivityBriefRefreshButton:RefreshActivityBabelTower()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BABELTOWER_REWARD })
        --btn:AddNewTagEvent({XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BABELTOWER})
    end
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

--常驻 复刷关
function XUiActivityBriefRefreshButton:RefreshActivityRepeateChallenge()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_REPEAT_CHALLENGE_REWARD })
    end
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

--v1.31 RPG五期
function XUiActivityBriefRefreshButton:RefreshRpgTower()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        local isShowTag = XDataCenter.RpgTowerManager.GetHaveNewStage()
        btn:ShowTag(isShowTag)
        btn:AddRedPointEvent({
            XRedPointConditions.Types.CONDITION_RPGTOWER_TEAM_RED,
            XRedPointConditions.Types.CONDITION_RPGTOWER_TASK_RED,
            XRedPointConditions.Types.CONDITION_RPGTOWER_DAILYREWARD_RED })
    end
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

--常驻 新角色预热
function XUiActivityBriefRefreshButton:RefreshNewCharActivity()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYMAINRED })
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.NewCharActivity)
        local skipList = XFunctionConfig.GetSkipList(config.SkipId)
        local actId = skipList.CustomParams[1]
        -- local isShowTag = XDataCenter.FubenNewCharActivityManager.IsChallengeable(actId)
        -- btn:ShowTag(isShowTag)
        btn:Refresh(actId)
    end
end

--常驻 涂装试玩
function XUiActivityBriefRefreshButton:RefreshFubenActivityTrial()
    self:RefreshNormal()
    -- local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    -- if btn then
        -- btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_FASHION_STORY_HAVE_STAGE })
        -- local isShowTag = XDataCenter.FubenExperimentManager.CheckSkinTrialRedPoint()
        -- btn:ShowTag(isShowTag)
    -- end
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

--v2.2 推箱子4.0
function XUiActivityBriefRefreshButton:RefreshRpgMaker()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_RPG_MAKER_GAME_RED })
    end
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

--v2.4 改造(界限构解)4.0
function XUiActivityBriefRefreshButton:RefreshReform()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_REFORM_All_RED_POINT })
        -- 九点刷新
        --local timeOffset = 4 * XScheduleManager.SECOND * 3600
        --btn:ShowTag(XDataCenter.ReformActivityManager.GetIsOpen(), timeOffset)
    end
end

--v1.32 双人同行(分光双星)4.0
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

--v1.32 超级爬塔
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

--v2.5 杀戮无双
function XUiActivityBriefRefreshButton:RefreshKillZone()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.XRedPointConditionKillZoneActivity })
        --btn:ShowTag(true)
    end
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

--虚像地平线(自走棋)
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

--v2.3 三消4.0
function XUiActivityBriefRefreshButton:RefreshSameColor()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_SAMECOLOR_TASK })
        btn:AddNewTagEvent({XRedPointConditions.Types.CONDITION_SAMECOLOR_IS_CHALLENGE})
    end
end

--v2.5 全服决战/全境特遣
function XUiActivityBriefRefreshButton:RefreshAreaWar()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.XRedPointConditionAreaWarActivity })
    end
end

--全服决战
function XUiActivityBriefRefreshButton:RefreshSuperSmashBros()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_SUPERSMASHBROS_HAVE_REWARD })
    end
end

--v1.32 涂装教学关
function XUiActivityBriefRefreshButton:RefreshTeachingSkin()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.TeachingSkin)
        local skipList = XFunctionConfig.GetSkipList(config.SkipId)
        local actId = skipList.CustomParams[1]
        btn:Refresh(actId)
    end
end

--射击玩法 异构阵线
function XUiActivityBriefRefreshButton:RefreshMaverick()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_MAVERICK_MAIN })
    end
end

--v2.0 意识拯救战
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

-- 肉鸽1/宣叙妄响
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

--v2.1 肉鸽2/厄怨潮声
function XUiActivityBriefRefreshButton:RefreshBiancaTheatre()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_BIANCATHEATRE_ALL_RED_POINT })
        btn:ShowTag(true)
    end
end

--v1.29 模拟经营二期
function XUiActivityBriefRefreshButton:RefreshDoomsDay()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.XRedPointConditionDoomsdayActivity })
        btn:ShowTag(XDataCenter.DoomsdayManager.CheckHasStageIncomplete())
    end
end

--v2.2 独域特攻5.0
function XUiActivityBriefRefreshButton:RefreshPivotCombat()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({XRedPointConditions.Types.CONDITION_PIVOTCOMBAT_TASK_REWARD_RED_POINT})
    end
end

---v2.4 大逃杀2.0
function XUiActivityBriefRefreshButton:RefreshEscape()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        --btn:AddRedPointEvent({XRedPointConditions.Types.XRedPointConditionEscapeTask})
    end
end

--常驻 主线
function XUiActivityBriefRefreshButton:RefreshFubenShortStory()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        local skipConfig = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.FubenShortStory).SkipId
        local skipList = XFunctionConfig.GetSkipList(skipConfig)
        local chapterId = skipList and skipList.CustomParams[1]
        btn:AddRedPointEvent({XRedPointConditions.Types.CONDITION_SHORT_STORY_CHAPTER_REWARD},chapterId)
    end
end

--v2.5 黄金矿工3.0
function XUiActivityBriefRefreshButton:RefreshGoldenMiner()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        local isCanReward = XDataCenter.GoldenMinerManager.CheckTaskCanReward()
        btn:ShowReddot(isCanReward)
    end
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

--v2.6 公会战4.0
function XUiActivityBriefRefreshButton:RefreshGuildWar()
    self:RefreshNormal()
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

--v1.27 音游
function XUiActivityBriefRefreshButton:RefreshTaiKoMaster()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({XRedPointConditions.Types.CONDITION_ACTIVITY_TAIKO_MASTER_TASK})
        btn:AddNewTagEvent({XRedPointConditions.Types.CONDITION_ACTIVITY_TAIKO_MASTER_CD_UNLOCK})
    end
end

--v1.27 多维挑战
function XUiActivityBriefRefreshButton:RefreshMultiDim()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:ShowReddot(XDataCenter.MultiDimManager.CheckLimitTaskGroup())
        btn:ShowTag(XDataCenter.MultiDimManager.CheckTeamIsOpen())
    end
end

--v2.2 正逆塔
function XUiActivityBriefRefreshButton:RefreshTwoSideTower()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_TWO_SIDE_TOWER_TASK })
        -- btn:AddNewTagEvent({ XRedPointConditions.Types.CONDITION_TWO_SIDE_TOWER_NEW_CHAPTER })
    end
end

--v1.29 拟真围剿
function XUiActivityBriefRefreshButton:RefreshGuildBoss()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_GUILDBOSS_BOSSHP, XRedPointConditions.Types.CONDITION_GUILDBOSS_SCORE })
    end
end

--v2.6 节日 - 七夕
function XUiActivityBriefRefreshButton:RefreshActivityFestival()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_POKER_GUESSING_RED})
    end
end

--v1.32 角色塔 - 本我回廊
function XUiActivityBriefRefreshButton:RefreshActivityCharacterTower()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:ShowReddot(XDataCenter.CharacterTowerManager:ExCheckIsShowRedPoint())
        btn:ShowTag(XDataCenter.CharacterTowerManager.CheckNewCharacterTowerChapterOpen())
    end
end

--v1.32 战双大秘境
function XUiActivityBriefRefreshButton:RefreshActivityRift()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_RIFT_ENTRANCE })
        btn:ShowTag(XDataCenter.RiftManager.CheckIsHasFightLayerRedPoint())
    end
end

--v2.0 调色板战争
function XUiActivityBriefRefreshButton:RefreshColorTable()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_COLORTABLE_ENTRANCE })
    end
end

--v2.0 光辉同行
function XUiActivityBriefRefreshButton:RefreshBrilliantWalk()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_BRILLIANTWALK_ENTRANCE })
    end
end

--v2.0 意识公约(危机公约)
function XUiActivityBriefRefreshButton:RefreshFubenAwareness()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:ShowReddot(XDataCenter.FubenAwarenessManager.CheckIsShowRedPoint())
    end
end

--v2.6 春节厨房/战双厨房(春节餐厅/战双餐厅)
function XUiActivityBriefRefreshButton:RefreshRestaurant()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_RESTAURANT_ENTRANCE })
    end
end

--v2.3 行星环游记
function XUiActivityBriefRefreshButton:RefreshPlanetRunning()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_PLANET_RUNNING_REWARD })
        --btn:AddNewTagEvent({XRedPointConditions.Types.CONDITION_PLANET_RUNNING_NEW_CHAPTER})
    end
end

--v2.3 战双BVB
function XUiActivityBriefRefreshButton:RefreshMonsterCombat()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:AddRedPointEvent({ XRedPointConditions.Types.CONDITION_MONSTER_COMBAT_ACTIVITY })
        --btn:AddNewTagEvent({XRedPointConditions.Types.CONDITION_MONSTER_COMBAT_NEW_CHAPTER})
    end
end

--v2.5 超限连战
function XUiActivityBriefRefreshButton:RefreshTransfinite()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        btn:ShowReddot(XDataCenter.TransfiniteManager.IsRewardCanReceive())
    end
end

--v2.6 肉鸽3
function XUiActivityBriefRefreshButton:RefreshTheatre3()
    self:RefreshNormal()
    local btn = self.TlActivityBrieButton[self.ActivityGroupId]
    if btn then
        ---@type XTheatre3Agency
        local agency = XMVCA:GetAgency(ModuleId.XTheatre3)
        btn:ShowReddot(agency:ExCheckIsShowRedPoint())
    end
end
--endregion

return XUiActivityBriefRefreshButton