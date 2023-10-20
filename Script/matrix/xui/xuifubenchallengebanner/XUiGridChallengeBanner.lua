local XUiGridChallengeBanner = XClass(nil, "XUiGridChallengeBanner")

function XUiGridChallengeBanner:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridChallengeBanner:InitAutoScript()
    self:AutoAddListener()
end

function XUiGridChallengeBanner:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridChallengeBanner:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridChallengeBanner:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridChallengeBanner:AutoAddListener()
end
-- auto
function XUiGridChallengeBanner:UpdateGrid(chapter)
    self.Chapter = chapter
    self.RImgChallenge.transform:DestroyChildren()
    self.PanelLock.gameObject:SetActiveEx(false)
    self.ImgRedPoint.gameObject:SetActiveEx(false)
    self:UnBindTimer()
    --显示New角标
    self.PanelNewEffect.gameObject:SetActiveEx(self:CanShowIconNew(chapter))
    if chapter.Type == XDataCenter.FubenManager.ChapterType.Urgent then
        -- 紧急事件
        self.TxtRank.text = ""
        self.TxtProgress.text = ""
        self.TxtDes.text = chapter.UrgentCfg.SimpleDesc
        self.ImgForbidEnter.gameObject:SetActiveEx(false)
        self.RImgChallenge:SetRawImage(chapter.UrgentCfg.Icon)
        local refreshTime = function()
            local v = XCountDown.GetRemainTime(tostring(chapter.Id))
            v = v > 0 and v or 0
            local timeText = XUiHelper.GetTime(v, XUiHelper.TimeFormatType.CHALLENGE)
            self.TxtTime.text = CS.XTextManager.GetText("BossSingleLeftTimeIcon", timeText)
        end
        refreshTime()
        self.Timer = XScheduleManager.ScheduleForever(refreshTime, XScheduleManager.SECOND, 0)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.ARENA then
        -- 竞技副本
        self.TxtRank.text = ""
        self.TxtDes.text = chapter.SimpleDesc
        self.RImgChallenge:SetRawImage(chapter.Icon)
        self.ImgForbidEnter.gameObject:SetActiveEx(false)

        local functionNameId = XFunctionManager.FunctionName.FubenArena
        if not XFunctionManager.JudgeCanOpen(functionNameId) then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
            self.TxtTime.text = ""
            self.TxtProgress.text = ""
        else
            local status = XDataCenter.ArenaManager.GetArenaActivityStatus()
            if status == XArenaActivityStatus.Rest then
                self.TxtProgress.text = CS.XTextManager.GetText("ArenaTeamDescription")
            elseif status == XArenaActivityStatus.Fight then
                local isJoin = XDataCenter.ArenaManager.GetIsJoinActivity()
                if isJoin then
                    self.TxtProgress.text = CS.XTextManager.GetText("ArenaFightJoinDescription")
                else
                    self.TxtProgress.text = CS.XTextManager.GetText("ArenaFightNotJoinDescription")
                end
            elseif status == XArenaActivityStatus.Over then
                self.TxtProgress.text = CS.XTextManager.GetText("ArenaOverDescription")
            end

            XCountDown.BindTimer(self, XArenaConfigs.ArenaTimerName, function(v)
                v = v > 0 and v or 0
                local state = XDataCenter.ArenaManager.GetArenaActivityStatus()
                local timeText = ""
                if state == XArenaActivityStatus.Rest then
                    timeText = CS.XTextManager.GetText("ArenaActivityBeginCountDown") .. XUiHelper.GetTime(v, XUiHelper.TimeFormatType.CHALLENGE)
                elseif state == XArenaActivityStatus.Fight then
                    timeText = CS.XTextManager.GetText("ArenaActivityEndCountDown", XUiHelper.GetTime(v, XUiHelper.TimeFormatType.CHALLENGE))
                elseif state == XArenaActivityStatus.Over then
                    timeText = CS.XTextManager.GetText("ArenaActivityResultCountDown") .. XUiHelper.GetTime(v, XUiHelper.TimeFormatType.CHALLENGE)
                end
                self.TxtTime.text = timeText
            end)
        end
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Trial then
        self.TxtTime.text = ""
        self.TxtRank.text = ""
        self.TxtProgress.text = ""
        self.TxtDes.text = chapter.SimpleDesc
        self.RImgChallenge:SetRawImage(chapter.Icon)

        local functionNameId = XFunctionManager.FunctionName.FubenChallengeTrial
        if not XFunctionManager.JudgeCanOpen(functionNameId) then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
            self.TxtTime.text = ""
            self.TxtProgress.text = ""
        else
            if not self.InitRedPoint then
                self.InitRedPoint = true
                self.RedPointId = XRedPointManager.AddRedPointEvent(self.ImgRedPoint, nil, self, { XRedPointConditions.Types.CONDITION_TRIAL_RED })
            end
            XRedPointManager.Check(self.RedPointId)
            if XDataCenter.TrialManager.FinishTrialType() == XDataCenter.TrialManager.TrialTypeCfg.TrialBackEnd and XDataCenter.TrialManager.TrialRewardGetedFinish() then
                self.TxtProgress.text = CS.XTextManager.GetText("TrialBackEndPro", XDataCenter.TrialManager:TrialBackEndFinishLevel(), XTrialConfigs.GetBackEndTotalLength())
            else
                self.TxtProgress.text = CS.XTextManager.GetText("TrialForPro", XDataCenter.TrialManager:TrialForFinishLevel(), XTrialConfigs.GetForTotalLength())

            end
        end
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.BossSingle then
        self.RImgChallenge:SetRawImage(chapter.Icon)
        self.TxtRank.text = ""
        self.TxtTime.text = ""
        self.TxtProgress.text = ""
        self.TxtDes.text = chapter.SimpleDesc

        local functionNameId = XFunctionManager.FunctionName.FubenChallengeBossSingle
        if not XFunctionManager.JudgeCanOpen(functionNameId) then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
            self.TxtTime.text = ""
            self.TxtProgress.text = ""
        else
            if not self.InitRedPointBossSingle then
                self.InitRedPointBossSingle = true
                self.RedPointBossSingleId = XRedPointManager.AddRedPointEvent(self.ImgRedPoint, nil, self, { XRedPointConditions.Types.CONDITION_BOSS_SINGLE_REWARD })
            end

            -- 剩余时间
            XCountDown.BindTimer(self, XDataCenter.FubenBossSingleManager.GetResetCountDownName(), function(v)
                v = v > 0 and v or 0
                local timeText = XUiHelper.GetTime(v, XUiHelper.TimeFormatType.CHALLENGE)
                self.TxtTime.text = CS.XTextManager.GetText("BossSingleLeftTimeIcon", timeText)
            end)

            -- 进度
            if XDataCenter.FubenBossSingleManager.CheckNeedChooseLevelType() then
                self.TxtProgress.text = CS.XTextManager.GetText("BossSingleProgressChooseable")
            else
                local allCount = XDataCenter.FubenBossSingleManager.GetChallengeCount()
                local challengeCount = XDataCenter.FubenBossSingleManager.GetBoosSingleData().ChallengeCount
                self.TxtProgress.text = CS.XTextManager.GetText("BossSingleProgress", challengeCount, allCount)
            end
        end
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Explore then
        self.RImgChallenge:SetRawImage(chapter.Icon)
        self.TxtRank.text = ""
        self.TxtTime.text = ""
        self.TxtProgress.text = ""
        self.TxtDes.text = chapter.SimpleDesc

        local functionNameId = XFunctionManager.FunctionName.FubenExplore
        if not XFunctionManager.JudgeCanOpen(functionNameId) then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
            self.TxtTime.text = ""
            self.TxtProgress.text = ""
        else
            if not self.InitRedPointExplore then
                self.InitRedPointExplore = true
                self.RedPointExploreId = XRedPointManager.AddRedPointEvent(self.ImgRedPoint, nil, self, { XRedPointConditions.Types.CONDITION_EXPLORE_REWARD })
            end
            XRedPointManager.Check(self.RedPointExploreId)
            if XDataCenter.FubenExploreManager.GetCurProgressName() ~= nil then
                self.TxtProgress.text = CS.XTextManager.GetText("ExploreBannerProgress") .. XDataCenter.FubenExploreManager.GetCurProgressName()
            else
                self.TxtProgress.text = CS.XTextManager.GetText("ExploreBannerProgressEnd")
            end
        end
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Practice then
        self.RImgChallenge:SetRawImage(chapter.Icon)
        self.TxtRank.text = ""
        self.TxtTime.text = ""
        self.TxtProgress.text = ""
        self.TxtDes.text = chapter.SimpleDesc
        local functionNameId = XFunctionManager.FunctionName.Practice

        if not XFunctionManager.JudgeCanOpen(functionNameId) then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
        else
            if not self.InitRedPointPractice then
                self.InitRedPointPractice = true
                self.RedPointPracticeId = XRedPointManager.AddRedPointEvent(self.ImgRedPoint, nil, self, { XRedPointConditions.Types.CONDITION_PRACTICE_ALL_RED_POINT })
            end
            XRedPointManager.Check(self.RedPointPracticeId)
        end
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Course then
        self.RImgChallenge:SetRawImage(chapter.Icon)
        self.TxtRank.text = ""
        self.TxtTime.text = ""
        self.TxtProgress.text = ""
        self.TxtDes.text = chapter.SimpleDesc
        local functionNameId = XFunctionManager.FunctionName.Course
        if not XFunctionManager.JudgeCanOpen(functionNameId) then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
        end
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Assign then
        self.RImgChallenge:SetRawImage(chapter.Icon)
        self.TxtRank.text = ""
        self.TxtTime.text = ""
        self.TxtProgress.text = XDataCenter.FubenAssignManager.GetChapterProgressTxt()
        self.TxtDes.text = chapter.SimpleDesc
        local functionNameId = XFunctionManager.FunctionName.FubenAssign
        if not XFunctionManager.JudgeCanOpen(functionNameId) then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
        else
            self.TxtLock.text = ""
            if not self.InitRedPointAssign then
                self.InitRedPointAssign = true
                self.RedPointAssignId = XRedPointManager.AddRedPointEvent(self.ImgRedPoint, nil, self, { XRedPointConditions.Types.CONDITION_ASSIGN_REWARD })
            end
            XRedPointManager.Check(self.RedPointAssignId)
        end
    --elseif chapter.Type == XDataCenter.FubenManager.ChapterType.InfestorExplore then
    --    self.RImgChallenge:SetRawImage(chapter.Icon)
    --    self.TxtDes.text = chapter.SimpleDesc
    --    self.TxtRank.text = ""
    --
    --    local functionNameId = XFunctionManager.FunctionName.FubenInfesotorExplore
    --    if not XFunctionManager.JudgeCanOpen(functionNameId) then
    --        self.PanelLock.gameObject:SetActiveEx(true)
    --        self.TxtProgress.gameObject:SetActiveEx(false)
    --        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
    --    else
    --        self.TxtProgress.text = XDataCenter.FubenInfestorExploreManager.GetCurSectionName()
    --        self.TxtProgress.gameObject:SetActiveEx(true)
    --        self.PanelLock.gameObject:SetActiveEx(false)
    --        XCountDown.BindTimer(self, XCountDown.GTimerName.FubenInfestorExplore, function(time)
    --            time = time > 0 and time or 0
    --            local timeText = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHALLENGE)
    --            if XDataCenter.FubenInfestorExploreManager.IsInSectionOne() then
    --                self.TxtTime.text = CS.XTextManager.GetText("InfestorExploreSectionLeftTimeSection1", timeText)
    --            else
    --                self.TxtTime.text = CS.XTextManager.GetText("InfestorExploreSectionLeftTimeSection2", timeText)
    --            end
    --        end)
    --    end
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.MaintainerAction then
        self:RefreshMaintainerActionBanner(chapter)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Stronghold then
        self:RefreshStrongholdBanner()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.PartnerTeaching then
        self:RefreshPartnerTeaching()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Theatre then
        self:RefreshTheatre()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.PivotCombat then
        self:RefreshPivotCombat()
    end
end

function XUiGridChallengeBanner:OnRecycle()
    self:UnBindTimer()
end

function XUiGridChallengeBanner:UnBindTimer()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.FubenInfestorExplore)
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.Stronghold)
    XCountDown.UnBindTimer(self, XArenaConfigs.ArenaTimerName)
    XCountDown.UnBindTimer(self, XDataCenter.FubenBossSingleManager.GetResetCountDownName())
    XCountDown.UnBindTimer(self, XDataCenter.MaintainerActionManager.GetResetCountDownName())
    if self.RedPointExploreId then
        XRedPointManager.RemoveRedPointEvent(self.RedPointExploreId)
        self.InitRedPointExplore = nil
        self.RedPointExploreId = nil
    end

    if self.RedPointId then
        XRedPointManager.RemoveRedPointEvent(self.RedPointId)
        self.InitRedPoint = nil
        self.RedPointId = nil
    end

    if self.RedPointBossSingleId then
        XRedPointManager.RemoveRedPointEvent(self.RedPointBossSingleId)
        self.InitRedPointBossSingle = nil
        self.RedPointBossSingleId = nil
    end

    if self.RedPointAssignId then
        XRedPointManager.RemoveRedPointEvent(self.RedPointAssignId)
        self.InitRedPointAssign = nil
        self.RedPointAssignId = nil
    end

    if self.RedPointPracticeId then
        XRedPointManager.RemoveRedPointEvent(self.RedPointPracticeId)
        self.InitRedPointPractice = nil
        self.RedPointPracticeId = nil
    end

    XEventManager.RemoveEventListener(XEventId.EVENT_STRONGHOLD_ACTIVITY_STATUS_CHANGE, self.RefreshStrongholdBanner, self)
end

-- 显示新玩法新角标
function XUiGridChallengeBanner:CanShowIconNew(chapter)
    -- 检查是否有配置New角标时间段
    if string.IsNilOrEmpty(chapter.ShowNewStartTime) then return false end
    -- 检查配置时间段是否符合条件
    local timeNow = XTime.GetServerNowTimestamp()
    local startTime = XTime.ParseToTimestamp(chapter.ShowNewStartTime)
    local endTime = XTime.ParseToTimestamp(chapter.ShowNewEndTime)
    return startTime and endTime and startTime <= timeNow and endTime >= timeNow
end

-- 大富翁玩法入口
function XUiGridChallengeBanner:RefreshMaintainerActionBanner(chapter)
    local name = XDataCenter.MaintainerActionManager.GetMaintainerActionName()
    self.RImgChallenge:SetRawImage(chapter.Icon)
    self.TxtDes.text = name
    self.TxtRank.text = ""
    self.TxtTime.text = ""

    local functionNameId = XFunctionManager.FunctionName.MaintainerAction
    if not XFunctionManager.JudgeCanOpen(functionNameId) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtProgress.gameObject:SetActiveEx(false)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
    else
        self.TxtProgress.gameObject:SetActiveEx(true)
        -- 剩余时间
        XCountDown.BindTimer(self, XDataCenter.MaintainerActionManager.GetResetCountDownName(), function(v)
            v = v > 0 and v or 0
            local timeText = XUiHelper.GetTime(v, XUiHelper.TimeFormatType.CHALLENGE)
            self.TxtTime.text = CS.XTextManager.GetText("MaintainerActionLeftTime", timeText)
        end)

        -- 进度
        local gameData = XDataCenter.MaintainerActionManager.GetGameData()
        local allCount = gameData:GetMaxFightWinCount()
        local challengeCount = gameData:GetFightWinCount()
        self.TxtProgress.text = CS.XTextManager.GetText("MaintainerActionProgress", challengeCount, allCount)
    end
end

-- 超级据点
function XUiGridChallengeBanner:RefreshStrongholdBanner()
    local chapter = self.Chapter
    if not chapter then return end

    XEventManager.AddEventListener(XEventId.EVENT_STRONGHOLD_ACTIVITY_STATUS_CHANGE, self.RefreshStrongholdBanner, self)

    self.RImgChallenge:SetRawImage(chapter.Icon)
    self.TxtDes.text = chapter.SimpleDesc
    self.TxtRank.text = ""

    local functionNameId = XFunctionManager.FunctionName.Stronghold
    if not XFunctionManager.JudgeCanOpen(functionNameId) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtProgress.gameObject:SetActiveEx(false)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
    else

        if not XDataCenter.StrongholdManager.IsOpen() then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtProgress.gameObject:SetActiveEx(false)
            self.TxtLock.text = CsXTextManagerGetText("StrongholdActivityTimeNotOpen")
        else

            local finishCount, totalCount = XDataCenter.StrongholdManager.GetGroupProgress()
            self.TxtProgress.text = CsXTextManagerGetText("StrongholdActivityProgress", finishCount, totalCount)
            self.TxtProgress.gameObject:SetActiveEx(true)
            self.PanelLock.gameObject:SetActiveEx(false)

            XCountDown.UnBindTimer(self, XCountDown.GTimerName.Stronghold)
            XCountDown.BindTimer(self, XCountDown.GTimerName.Stronghold, function(time)
                time = time > 0 and time or 0

                local timeText = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.STRONGHOLD)
                if XDataCenter.StrongholdManager.IsActivityBegin() then
                    self.TxtTime.text = CsXTextManagerGetText("StrongholdActivityTimeActivityBegin", timeText)
                elseif XDataCenter.StrongholdManager.IsFightBegin() then
                    self.TxtTime.text = CsXTextManagerGetText("StrongholdActivityTimeFightBegin", timeText)
                elseif XDataCenter.StrongholdManager.IsFightEnd() then
                    self.TxtTime.text = CsXTextManagerGetText("StrongholdActivityTimeFightEnd", timeText)
                end
            end)

            local isShow = XRedPointConditions.Check(XRedPointConditions.Types.XRedPointConditionStrongholdRewardCanGet)
            self.ImgRedPoint.gameObject:SetActiveEx(isShow)
        end
    end
end

-- 宠物教学
function XUiGridChallengeBanner:RefreshPartnerTeaching()
    self.RImgChallenge:SetRawImage(self.Chapter.Icon)
    self.TxtRank.text = ""
    self.TxtTime.text = ""
    self.TxtProgress.text = ""
    self.TxtDes.text = self.Chapter.SimpleDesc
    local functionNameId = XFunctionManager.FunctionName.PartnerTeaching
    if not XFunctionManager.JudgeCanOpen(functionNameId) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
    end
end

--肉鸽玩法
function XUiGridChallengeBanner:RefreshTheatre()
    self.RImgChallenge:SetRawImage(self.Chapter.Icon)
    self.TxtRank.text = ""
    self.TxtTime.text = ""
    self.TxtProgress.text = ""
    self.TxtDes.text = self.Chapter.SimpleDesc
    local functionNameId = XFunctionManager.FunctionName.Theatre
    if not XFunctionManager.JudgeCanOpen(functionNameId) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
    end

    local isShow = XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_THEATRE_ALL_RED_POINT)
    self.ImgRedPoint.gameObject:SetActiveEx(isShow)
end

--独域特攻
function XUiGridChallengeBanner:RefreshPivotCombat()
    self.RImgChallenge:SetRawImage(self.Chapter.Icon)
    self.TxtRank.text = ""
    self.TxtTime.text = ""
    self.TxtProgress.text = ""
    self.TxtDes.text = self.Chapter.SimpleDesc
    local functionNameId = XFunctionManager.FunctionName.PivotCombat
    if not XFunctionManager.JudgeCanOpen(functionNameId) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(functionNameId)
    end
end

return XUiGridChallengeBanner