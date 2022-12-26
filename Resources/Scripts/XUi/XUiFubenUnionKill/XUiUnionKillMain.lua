local XUiUnionKillMain = XLuaUiManager.Register(XLuaUi, "UiUnionKillMain")

function XUiUnionKillMain:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    self.BtnMatch.CallBack = function() self:OnBtnMatchClick() end
    self.BtnCancelMatch.CallBack = function() self:OnBtnCancelMatchClick() end
    self.BtnCreateRoom.CallBack = function() self:OnBtnCreateRoomClick() end
    self.BtnThumbsUp.CallBack = function() self:OnBtnThumbsUpClick() end
    self.BtnKillNumber.CallBack = function() self:OnBtnKillNumberClick() end
    self.BtnBlackSquare.CallBack = function() self:OnBtnBlackSquareClick() end
    self.BtnReward.CallBack = function() self:OnBtnRewardClick() end
    self.BtnHelp.CallBack = function() self:OnBtnHelpClick() end
    self:BindHelpBtnOnly(self.BtnHelp)

    self.RewardCommon = {}

    self:AddEventListeners()
end

function XUiUnionKillMain:OnDestroy()
    self:StopActivityCountDown()
    self:RemoveEventListeners()
end

function XUiUnionKillMain:AddEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILL_BOSSCOUNTCHANGE, self.SyncBossCountChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILLROOM_MATCHRESULT, self.OnMatchResult, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILL_ACTIVITYINFO, self.OnActivityInfoChanged, self)

end

function XUiUnionKillMain:RemoveEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILL_BOSSCOUNTCHANGE, self.SyncBossCountChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILLROOM_MATCHRESULT, self.OnMatchResult, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILL_ACTIVITYINFO, self.OnActivityInfoChanged, self)
end

-- 击杀boss次数变化
function XUiUnionKillMain:SyncBossCountChanged()
    if not self.UnionKillInfo then return end
    local sectionId = self.UnionKillInfo.CurSectionId
    local curSectionInfo = XDataCenter.FubenUnionKillManager.GetSectionInfoById(sectionId)
    local curSectionTemplate = XFubenUnionKillConfigs.GetUnionSectionById(sectionId)
    if not curSectionTemplate then return end

    self.TxtCondition.gameObject:SetActiveEx(false)
    self.BtnReward.gameObject:SetActiveEx(false)
    self.TxtTaskProgress.gameObject:SetActiveEx(false)

    local syncCount = XDataCenter.FubenUnionKillManager.GetBossKillCount(sectionId)
    if not curSectionInfo then
        self.TxtTaskProgress.text = CS.XTextManager.GetText("UnionResetText", syncCount, curSectionTemplate.KillBossCount)
        -- 可领取
        if syncCount >= curSectionTemplate.KillBossCount then
            self.BtnReward:ShowReddot(true)
            self.BtnReward:ShowTag(false)
            self.BtnReward.gameObject:SetActiveEx(true)
        else
        -- 不可领取
            self.BtnReward:ShowReddot(false)
            self.BtnReward:ShowTag(true)
            self.TxtTaskProgress.gameObject:SetActiveEx(true)
        end
    else
        local killBossCount = curSectionInfo.KillBoss or 0
        syncCount = killBossCount > syncCount and killBossCount or syncCount
        self.TxtTaskProgress.text = CS.XTextManager.GetText("UnionResetText", syncCount, curSectionTemplate.KillBossCount)
        -- 未领取
        if curSectionInfo.RewardStatus == 0 then
            -- 可领取
            if syncCount >= curSectionTemplate.KillBossCount then
                self.BtnReward:ShowReddot(true)
                self.BtnReward.gameObject:SetActiveEx(true)
            else
            -- 不可领取
                self.BtnReward:ShowReddot(false)
                self.TxtTaskProgress.gameObject:SetActiveEx(true)
            end
            self.BtnReward:ShowTag(false)
        else
        -- 已领取
            self.BtnReward:ShowReddot(false)
            self.BtnReward:ShowTag(true)
            self.TxtCondition.gameObject:SetActiveEx(true)
        end
    end
end

function XUiUnionKillMain:OnStart()
    self.UnionKillInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
    if self.UnionKillInfo == nil then return end
    if self.UnionKillInfo.Id == nil or self.UnionKillInfo.Id == 0 then return end
    self.CurrentUnionActivityConfig = XFubenUnionKillConfigs.GetUnionActivityConfigById(self.UnionKillInfo.Id)
    self.CurrentUnionActivityTemplate = XFubenUnionKillConfigs.GetUnionActivityById(self.UnionKillInfo.Id)

    self:InitUnionSectionView()
    self:SetMainInfo()
    self:SyncBossCountChanged()

    local firstShowKey = string.format("%s_%s_%d", XFubenUnionKillConfigs.FirstShowHelp, tostring(XPlayer.Id), self.UnionKillInfo.Id)
    self:PlayAnimation("AnimStartEnable", function()
        XLuaUiManager.SetMask(false)

        -- 首次弹帮助说明
        local cacheValue = XDataCenter.FubenUnionKillManager.GetUnionKillStringPrefs(firstShowKey, "0")
        if cacheValue == "0" then
            XUiManager.ShowHelpTip("UnionKillMainHelp")
            XDataCenter.FubenUnionKillManager.SaveUnionKillStringPrefs(firstShowKey, "1")
        end
    end, function()
        XLuaUiManager.SetMask(true)
    end)
    XRedPointManager.AddRedPointEvent(self.RedTask, self.RefreshTaskLimited, self, { XRedPointConditions.Types.CONDITION_TASK_LIMIT_TYPE }, self.CurrentUnionActivityTemplate.TaskLimitId)
end

function XUiUnionKillMain:RefreshTaskLimited(count)
    self.RedTask.gameObject:SetActiveEx(count >= 0)
end

function XUiUnionKillMain:OnEnable()
    self:CheckActivityEnd(false)
end

function XUiUnionKillMain:SetMainInfo()
    self.TxtTitle.text = self.CurrentUnionActivityConfig.Name

    local weatherConfig = XFubenUnionKillConfigs.GetUnionWeatherConfigById(self.UnionKillInfo.WeatherId)
    self.TxtShuXing.text = string.format("(%s：%s)", weatherConfig.Name, weatherConfig.Description)

    self:StartActivityCountDown()
end

-- 启动活动结束倒计时
function XUiUnionKillMain:StartActivityCountDown()
    self:StopActivityCountDown()

    local _, endTime = XFubenUnionKillConfigs.GetUnionActivityTimes(self.UnionKillInfo.Id)
    local _, tmpSectionEndTime = XFubenUnionKillConfigs.GetUnionSectionTimes(self.UnionKillInfo.CurSectionId)
    local now = XTime.GetServerNowTimestamp()
    if not endTime then return end

    self.TxtDay.text = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    local invalidTime = CS.XTextManager.GetText("UnionMainOverdue")
    if now <= tmpSectionEndTime then
        self.TxtSectionDay.text = CS.XTextManager.GetText("UnionRewardResetTime", XUiHelper.GetTime(tmpSectionEndTime - now, XUiHelper.TimeFormatType.ACTIVITY))
    else
        self.TxtSectionDay.text = CS.XTextManager.GetText("UnionRewardResetTime", invalidTime)
    end

    self.UnionKillTimer =
        XScheduleManager.ScheduleForever(function()
            now = XTime.GetServerNowTimestamp()
            if now > endTime then
                self:StopActivityCountDown()
                self:CheckActivityEnd(true)
                return
            end
            self.TxtDay.text = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
            if now <= tmpSectionEndTime then
                self.TxtSectionDay.text = CS.XTextManager.GetText("UnionRewardResetTime", XUiHelper.GetTime(tmpSectionEndTime - now, XUiHelper.TimeFormatType.ACTIVITY))
            else
                self.TxtSectionDay.text = CS.XTextManager.GetText("UnionRewardResetTime", invalidTime)
            end

            if self.IsMatching and self.BeginMatchingTime then
                local tmpNow = XTime.GetServerNowTimestamp()
                self.TxtMatchTime.text = XUiHelper.GetTime(tmpNow - self.BeginMatchingTime)
            end

        end, XScheduleManager.SECOND, 0)
end

-- 关闭活动结束倒计时
function XUiUnionKillMain:StopActivityCountDown()
    if self.UnionKillTimer ~= nil then
        XScheduleManager.UnSchedule(self.UnionKillTimer)
        self.UnionKillTimer = nil
    end
end

function XUiUnionKillMain:OnBtnHelpClick()
    if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
        return
    end

    XUiManager.ShowHelpTip("UnionKillMainHelp")
end

-- 活动任务
function XUiUnionKillMain:OnBtnBlackSquareClick()
    if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
        return
    end

    XLuaUiManager.Open("UiUnionKillTask")
end

-- 奖励
function XUiUnionKillMain:OnBtnRewardClick()
    if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
        return
    end

    -- 获得奖励逻辑
    if not self.UnionKillInfo then return end
    local sectionId = self.UnionKillInfo.CurSectionId
    local curSectionInfo = XDataCenter.FubenUnionKillManager.GetSectionInfoById(sectionId)
    local curSectionTemplate = XFubenUnionKillConfigs.GetUnionSectionById(sectionId)
    if not curSectionInfo then return end
    if not curSectionTemplate then return end
    if curSectionInfo.RewardStatus == 1 then
        XUiManager.TipMsg(CS.XTextManager.GetText("UnionMainRewardHasClick"))
        return
    end
    local syncCount = XDataCenter.FubenUnionKillManager.GetBossKillCount(sectionId)
    local killBossCount = curSectionInfo and curSectionInfo.KillBoss or 0
    syncCount = killBossCount > syncCount and killBossCount or syncCount
    if syncCount < curSectionTemplate.KillBossCount then
        XUiManager.TipMsg(CS.XTextManager.GetText("UnionMainKillLimited"))
        return
    end

    XDataCenter.FubenUnionKillManager.GetUnionBoxReward(sectionId, function()
        curSectionInfo.RewardStatus = 1
        self:SyncBossCountChanged()
    end)
end

-- 击杀排行
function XUiUnionKillMain:OnBtnKillNumberClick()
    if not self.UnionKillInfo then return end
    if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
        return
    end

    local sectionId = self.UnionKillInfo.CurSectionId
    local sectionInfo = XDataCenter.FubenUnionKillManager.GetSectionInfoById(sectionId)
    if not sectionInfo then return end

    local rankLevel = sectionInfo.RankLevel
    local rankLevelInfos = XDataCenter.FubenUnionKillManager.GetKillRankInfosByLevel(rankLevel)
    local now = XTime.GetServerNowTimestamp()

    if not rankLevelInfos or now - rankLevelInfos.LastModify > XFubenUnionKillConfigs.RankRequestInterval then
        XDataCenter.FubenUnionKillManager.GetUnionKillRankData(sectionInfo.RankLevel, function()
            XLuaUiManager.Open("UiUnionKillRank", XFubenUnionKillConfigs.UnionRankType.KillNumber)
        end)
    else
        XLuaUiManager.Open("UiUnionKillRank", XFubenUnionKillConfigs.UnionRankType.KillNumber)
    end

end

-- 点赞排行
function XUiUnionKillMain:OnBtnThumbsUpClick()
    if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
        return
    end

    local rankPraiseInfos = XDataCenter.FubenUnionKillManager.GetPraiseRankInfos()
    local now = XTime.GetServerNowTimestamp()
    if not rankPraiseInfos or now - rankPraiseInfos.LastModify > XFubenUnionKillConfigs.RankRequestInterval then
        XDataCenter.FubenUnionKillManager.GetPraiseRankData(function()
            XLuaUiManager.Open("UiUnionKillRank", XFubenUnionKillConfigs.UnionRankType.ThumbsUp)
        end)
    else
        XLuaUiManager.Open("UiUnionKillRank", XFubenUnionKillConfigs.UnionRankType.ThumbsUp)
    end
end

-- 创建房间
function XUiUnionKillMain:OnBtnCreateRoomClick()
    if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
        XUiManager.TipMsg(CS.XTextManager.GetText("UnionInMatching"))
        return
    end
    XDataCenter.FubenUnionKillRoomManager.CreateUnionRoom(true, function()
        XLuaUiManager.Open("UiUnionKillRoom")
    end)
end

-- 匹配
function XUiUnionKillMain:OnBtnMatchClick()
    XDataCenter.FubenUnionKillRoomManager.MatchUnionRoom(function()
        self.IsMatching = true
        self.BeginMatchingTime = XTime.GetServerNowTimestamp()
        self.TxtMatchTime.text = XUiHelper.GetTime(0)

        self.PiPeiGroup.gameObject:SetActiveEx(true)
        self.BtnMatch.gameObject:SetActiveEx(false)
        self.BtnMatching.gameObject:SetActiveEx(true)
    end)
end

-- 取消匹配
function XUiUnionKillMain:OnBtnCancelMatchClick()
    XDataCenter.FubenUnionKillRoomManager.CancelUnionMatch(function()
        self.IsMatching = false

        self.PiPeiGroup.gameObject:SetActiveEx(false)
        self.BtnMatch.gameObject:SetActiveEx(true)
        self.BtnMatching.gameObject:SetActiveEx(false)
    end)

end

-- 匹配到结果
function XUiUnionKillMain:OnMatchResult()
    self.IsMatching = false

    self.PiPeiGroup.gameObject:SetActiveEx(false)
    self.BtnMatch.gameObject:SetActiveEx(true)
    self.BtnMatching.gameObject:SetActiveEx(false)
end

-- 天气、章节变化
function XUiUnionKillMain:OnActivityInfoChanged()
    if not self.UnionKillInfo then return end
    if not self.CurrentUnionActivityTemplate then return end

    -- 天气
    local weatherConfig = XFubenUnionKillConfigs.GetUnionWeatherConfigById(self.UnionKillInfo.WeatherId)
    self.TxtWeather.text = weatherConfig.Name
    self.TxtShuXing.text = weatherConfig.Description
    if weatherConfig.Icon ~= "" then
        self:SetUiSprite(self.ImgWeatherIcon, weatherConfig.Icon)
    end

    -- 章节切换
    local sectionId = self.UnionKillInfo.CurSectionId
    local selectIndex = self.CurrentSelectedSection
    local allSectionIds = self.CurrentUnionActivityTemplate.SectionId
    for index, id in pairs(allSectionIds) do
        if id == sectionId then
            selectIndex = index
            break
        end
    end
    self:OnSectionSelected(selectIndex)

    -- boss条件
    self:SyncBossCountChanged()
end

-- 右切
function XUiUnionKillMain:OnBtnBgQiehuanRightClcik()
end

-- 左切
function XUiUnionKillMain:OnBtnBgQiehuanLeftClick()
end

-- 初始化切换点
function XUiUnionKillMain:InitUnionSectionView()

    if not self.CurrentUnionActivityTemplate then return end
    if not self.UnionKillInfo then return end
    local sectionId = self.UnionKillInfo.CurSectionId
    -- Switch
    self.CurrentSelectedSection = 1
    local allSectionIds = self.CurrentUnionActivityTemplate.SectionId
    for i = 1, #allSectionIds do
        if allSectionIds[i] == sectionId then
            self.CurrentSelectedSection = i
        end
    end

    self:OnSectionSelected(self.CurrentSelectedSection)
end

function XUiUnionKillMain:OnSectionSelected(index)

    self.CurrentSelectedSection = index
    self:UpdateSectionInfo(self.CurrentSelectedSection)
end


-- 更新当前选中的章节
function XUiUnionKillMain:UpdateSectionInfo(index)
    if not self.CurrentUnionActivityTemplate then return end
    if not self.UnionKillInfo then return end

    local selectSectoinId = self.CurrentUnionActivityTemplate.SectionId[index]

    local selectSectionTemplate = XFubenUnionKillConfigs.GetUnionSectionById(selectSectoinId)
    if not selectSectionTemplate or not selectSectoinId or selectSectoinId <= 0 then return end

    local sectionConfig = XFubenUnionKillConfigs.GetUnionSectionConfigById(selectSectoinId)
    self:SwitchBackground(sectionConfig)

    -- 过期、时间未到
    local sectionId = self.UnionKillInfo.CurSectionId
    local curOpenIndex = 1
    for i = 1, #self.CurrentUnionActivityTemplate.SectionId do
        if self.CurrentUnionActivityTemplate.SectionId[i] == sectionId then
            curOpenIndex = i
            break
        end
    end

    self.PassPanel.gameObject:SetActiveEx(curOpenIndex ~= index)
    self.TxtWeiKaiQi.gameObject:SetActiveEx(curOpenIndex < index)
    self.TxtYiTongGuo.gameObject:SetActiveEx(curOpenIndex > index)
    if curOpenIndex < index then
        local now = XTime.GetServerNowTimestamp()
        local beginTime = XFubenUnionKillConfigs.GetUnionSectionTimes(selectSectoinId)
        self.TxtWeiKaiQi.text = CS.XTextManager.GetText("UnionSectionIsComing", XUiHelper.GetTime(beginTime - now, XUiHelper.TimeFormatType.ACTIVITY))
    end

    -- 隐藏多余数据
    local isOpen = curOpenIndex == index
    self.RewardGroup.gameObject:SetActiveEx(isOpen)
    self.BtnBlackSquare.gameObject:SetActiveEx(isOpen)
    self.BtnBottomRight.gameObject:SetActiveEx(isOpen)
    self.WeatherGroup.gameObject:SetActiveEx(isOpen)
    self.BtnRight.gameObject:SetActiveEx(isOpen)

    -- 显示奖励
    local rewards = XRewardManager.GetRewardList(selectSectionTemplate.BoxRewardId)
    for i = 1, #rewards do
        if not self.RewardCommon[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommonPopUp)
            ui.transform:SetParent(self.PanelRewrds, false)
            self.RewardCommon[i] = XUiGridCommon.New(self, ui)
        end
        self.RewardCommon[i]:Refresh(rewards[i])
    end
    for i = #rewards + 1, #self.RewardCommon do
        self.RewardCommon[i].GameObject:SetActiveEx(false)
    end
end

function XUiUnionKillMain:CheckActivityEnd(isCheckPanel)

    if not self.UnionKillInfo or self.UnionKillInfo.Id <= 0 then
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("UnionKillMainNotInActivity"))
        -- 退出
        return
    end

    if not XFubenUnionKillConfigs.UnionKillInActivity(self.UnionKillInfo.Id) and not CS.XFight.IsRunning then
        if isCheckPanel and XLuaUiManager.IsUiShow("UiUnionKillMain") then
            -- 退出
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(CS.XTextManager.GetText("UnionKillMainNotInActivity"))
            return
        end
        -- 退出
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("UnionKillMainNotInActivity"))
    end
end

function XUiUnionKillMain:SwitchBackground(sectionConfig)
    if not sectionConfig then return end

    for i = 1, #sectionConfig.SectionIcon do
        self[string.format("RImgBg%d", i)]:SetRawImage(sectionConfig.SectionIcon[i])
    end

end

function XUiUnionKillMain:OnBtnBackClick()
    if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
        local title = CS.XTextManager.GetText("TipTitle")
        local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceCancelMatch")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.FubenUnionKillRoomManager.CancelUnionMatch(function()
                self.IsMatching = false

                self.PiPeiGroup.gameObject:SetActiveEx(false)
                self.BtnMatch.gameObject:SetActiveEx(true)
                self.BtnMatching.gameObject:SetActiveEx(false)
                self:Close()
            end)
        end)
    else
        self:Close()
    end
end

function XUiUnionKillMain:OnBtnMainUiClick()
    if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
        local title = CS.XTextManager.GetText("TipTitle")
        local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceCancelMatch")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.FubenUnionKillRoomManager.CancelUnionMatch(function()
                self.IsMatching = false

                self.PiPeiGroup.gameObject:SetActiveEx(false)
                self.BtnMatch.gameObject:SetActiveEx(true)
                self.BtnMatching.gameObject:SetActiveEx(false)
                XLuaUiManager.RunMain()
            end)
        end)

    else
        XLuaUiManager.RunMain()
    end

end