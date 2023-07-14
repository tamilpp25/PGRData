local tableInsert = table.insert
local CsXTextManagerGetText = CS.XTextManager.GetText
local TimeFormat = "yyyy-MM-dd"
local CsXScheduleManager = XScheduleManager
local XUiGridChapter = require("XUi/XUiFubenMainLineChapter/XUiGridChapter")

local ChildDetailUi = "UiFubenRepeatChallengeStageDetail"
local ChapterBtnNum = 5

local XUiFubenRepeatchallenge = XLuaUiManager.Register(XLuaUi, "UiFubenRepeatchallenge")

function XUiFubenRepeatchallenge:OnAwake()
    local tabGroup = {}
    for i = 1, ChapterBtnNum do
        tableInsert(tabGroup, self["BtnChapter" .. i])
    end
    self.TxtBtnExtraList = {
        self.TxtBtnExtra1,
        self.TxtBtnExtra2,
        self.TxtBtnExtra3,
        self.TxtBtnExtra4,
        self.TxtBtnExtra5
    }
    self.PanelTabChapterGroup:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:AutoAddListener()
    --XFunctionManager.CheckSkipInDuration(id)
end

function XUiFubenRepeatchallenge:OnStart(difficultType, stageId)
    difficultType = difficultType or XDataCenter.FubenRepeatChallengeManager.DifficultType.Normal
    self.DefaultStageId = stageId
    self.ChapterList = {}

    XDataCenter.FubenRepeatChallengeManager.SelectDifficult(difficultType)
    self.RedPointId = XRedPointManager.AddRedPointEvent(self.BtnTreasure, self.OnCheckRewards, self, { XRedPointConditions.Types.CONDITION_REPEAT_CHALLENGE_CHAPTER_REWARD }, nil, false)
end

function XUiFubenRepeatchallenge:OnEnable()
    local newChapterTip = XDataCenter.FubenRepeatChallengeManager.GetNewChapterTipInfo()
    if next(newChapterTip) then
        XLuaUiManager.Open("UiFubenRepeatChallengeNewChapter", newChapterTip.OldIndex, newChapterTip.NewIndex)
        XDataCenter.FubenRepeatChallengeManager.ResetNewChapterTipInfo()
    end

    if not XDataCenter.FubenRepeatChallengeManager.GetIsFirstAutoFightOpen() and XDataCenter.FubenRepeatChallengeManager.IsAutoFightOpen() then 
        XDataCenter.FubenRepeatChallengeManager.SetAutoFightOpen()
        XUiManager.TipErrorWithKey("AutoFightUnLock")
    end

    self:Refresh()
end

function XUiFubenRepeatchallenge:OnDisable()
    self:DestroyActivityTimer()
end

function XUiFubenRepeatchallenge:Refresh()
    local difficultType = XDataCenter.FubenRepeatChallengeManager.GetSelectDifficult()
    self.DifficultType = difficultType

    self:CreateActivityTimer()
    self:RefreshLevel()
    self:RefreshChapterBtns()
end

function XUiFubenRepeatchallenge:RefreshChapterBtns()
    local difficultType = self.DifficultType
    local selectChapterIndex = XDataCenter.FubenRepeatChallengeManager.GetCurChapterIndex(difficultType)
    if not selectChapterIndex then return end

    local chapterNum = XDataCenter.FubenRepeatChallengeManager.GetChapterNum(difficultType)
    for i = 1, ChapterBtnNum do
        local btn = self["BtnChapter" .. i]
        local txtBtnExtra = self.TxtBtnExtraList[i]
        if i <= chapterNum then
            local chapterId = XDataCenter.FubenRepeatChallengeManager.GetChapterId(difficultType, i)
            local isRed = XDataCenter.FubenRepeatChallengeManager.CheckChapterRewardCanGetReal(chapterId)
            if i > selectChapterIndex then
                local onlyShowNextCondition = CsXTextManagerGetText("ActivityRepeatChallengeChapterLockBtn1")
                txtBtnExtra.gameObject:SetActiveEx(true)
                txtBtnExtra.text = onlyShowNextCondition
                btn:ShowReddot(false)
                btn:ShowTag(false)
                btn:SetDisable(true)
            elseif i < selectChapterIndex then
                btn:ShowReddot(isRed)
                txtBtnExtra.gameObject:SetActiveEx(false)
                btn:ShowTag(true)
                btn:SetDisable(false)
            else
                if XDataCenter.FubenRepeatChallengeManager.IsStatusEqualFightEnd() then
                    btn:ShowTag(true)
                    txtBtnExtra.gameObject:SetActiveEx(false)
                else
                    btn:ShowTag(false)
                    local time = XTime.GetServerNowTimestamp()
                    local endTime = XDataCenter.FubenRepeatChallengeManager.GetChapterEndTime(chapterId)
                    local timeStr = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
                    txtBtnExtra.text = CsXTextManagerGetText("ActivityRepeatChallengeChapterCurBtn", timeStr)
                    txtBtnExtra.gameObject:SetActiveEx(true)
                end
                btn:ShowReddot(isRed)
                btn:SetDisable(false)
            end
            local chapterConfig = XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
            btn:SetName(chapterConfig.Name)
            btn.gameObject:SetActiveEx(true)
        else
            btn.gameObject:SetActiveEx(false)
            txtBtnExtra.gameObject:SetActiveEx(false)
        end
    end
    self.PanelTabChapterGroup:SelectIndex(selectChapterIndex)
    self.PanelTabChapterGroup.gameObject:SetActiveEx(difficultType == XDataCenter.FubenRepeatChallengeManager.DifficultType.Normal)
end

function XUiFubenRepeatchallenge:RefreshCurChapter()
    local difficultType = self.DifficultType
    local chapterId = self.SelectChapterId
    if not chapterId then
        local firstChapterId = XDataCenter.FubenRepeatChallengeManager.GetChapterIds(difficultType)[1]
        local time = XTime.GetServerNowTimestamp()
        local beginTime = XDataCenter.FubenRepeatChallengeManager.GetChapterBeginTime(firstChapterId)
        local timeStr = XUiHelper.GetTime(beginTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        XUiManager.TipError(CsXTextManagerGetText("ActivityRepeatChallengeChapterLock", timeStr))
        return
    end

    local activityCfg = XDataCenter.FubenRepeatChallengeManager.GetActivityConfig()
    local chapterCfg = XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
    self.RImgBg:SetRawImage(chapterCfg.Bg)
    self.TxtName.text = activityCfg.Name
    --self.TxtTitle.text = chapterCfg.Name
    local titlePath = chapterCfg.TitlePath
    if titlePath then
        self.RImgTitle.gameObject:SetActiveEx(true)
        self.RImgTitle:SetRawImage(titlePath)
    else
        self.RImgTitle.gameObject:SetActiveEx(false)
    end

    self.PanelEffect.gameObject:LoadUiEffect(chapterCfg.EffectPath)

    local isSelectDifficult = difficultType == XDataCenter.FubenRepeatChallengeManager.DifficultType.Difficult
    -- self.BtnSwitch2Fight.gameObject:SetActiveEx(not isSelectDifficult)
    self.BtnSwitch2Fight.gameObject:SetActiveEx(false)
    self.BtnSwitch2Regional.gameObject:SetActiveEx(isSelectDifficult)

    local buffDes = XDataCenter.FubenRepeatChallengeManager.GetBuffDes(chapterCfg.BuffId)
    if buffDes then
        self.TxtBuff.text = CsXTextManagerGetText("ActivityRepeatChallengeBuffDes", buffDes)
        self.TxtBuff.gameObject:SetActiveEx(true)
    else
        self.TxtBuff.gameObject:SetActiveEx(false)
    end

    self.GridCostItem.gameObject:SetActiveEx(false)
    local exConsumeId = XDataCenter.FubenRepeatChallengeManager.ExCostItemId
    if exConsumeId ~= 0 then
        self.CommonGrid = self.CommonGrid or XUiGridCommon.New(self, self.GridCostItem)
        self.CommonGrid:Refresh({ TemplateId = exConsumeId, Count = XDataCenter.ItemManager.GetCount(exConsumeId) })
        self.CommonGrid.GameObject:SetActiveEx(true)
    end
end

function XUiFubenRepeatchallenge:RefreshLevel()
    local level = XDataCenter.FubenRepeatChallengeManager.GetLevel()
    local exp = XDataCenter.FubenRepeatChallengeManager.GetExp()
    local levelConfig = XFubenRepeatChallengeConfigs.GetLevelConfig(level)
    local curLevelMaxExp = levelConfig.UpExp
    local isMaxLv = level == XFubenRepeatChallengeConfigs.GetMaxLevel()

    self.ImgExp.fillAmount = isMaxLv and 1 or (exp / curLevelMaxExp)
    self.TxtBuffDes.gameObject:SetActiveEx(not isMaxLv)
    self.TxtLevel.text = CsXTextManagerGetText("ActivityRepeatChallengeLevel", level)
    local nextShowLevel = XDataCenter.FubenRepeatChallengeManager.GetNextShowLevel()
    if nextShowLevel then
        local nextLvCfg = XFubenRepeatChallengeConfigs.GetLevelConfig(nextShowLevel)
        self.TxtBuffDes.text = nextLvCfg.SimpleDesc
        self.TxtExp.text = CsXTextManagerGetText("ActivityRepeatChallengeNextLevelDesc", nextShowLevel)
    else
        self.TxtBuffDes.gameObject:SetActiveEx(false)
        self.TxtExp.transform.position = CS.UnityEngine.Vector3.Lerp(self.TxtExp.transform.position, self.TxtBuffDes.transform.position, 0.5)
        if isMaxLv then
            self.TxtExp.text = CsXTextManagerGetText("ActivityRepeatChallengeMaxLevelTip")
        else
            self.TxtExp.text = CsXTextManagerGetText("ActivityRepeatChallengeExp", exp, curLevelMaxExp)
        end
    end
    -- TxtExpMax -> "(已达每日上限)"
    self.TxtExpMax.gameObject:SetActiveEx(false)
end

function XUiFubenRepeatchallenge:SelectChapter(chapterId)
    self.SelectChapterId = chapterId
    self:CloseChildUi(ChildDetailUi)
    self:RefreshCurChapter()
    self:RefreshChapterList()
    self:RefreshChapterReward(chapterId)
end

function XUiFubenRepeatchallenge:RefreshChapterList()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    local chapterId = self.SelectChapterId
    local chapterCfg = XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
    local data = {
        Chapter = chapterCfg,
        StageList = chapterCfg.StageId,
        HideStageCb = handler(self, self.CloseStageDetailCb),
        ShowStageCb = handler(self, self.ShowStageDetail),
    }
    local prefabName = chapterCfg.Prefab
    local grid = self.ChapterList[prefabName]
    if not grid or XTool.UObjIsNil(grid.GameObject) then
        local go = self.PanelChapter:LoadPrefab(prefabName)
        if not XTool.UObjIsNil(go) then
            grid = XUiGridChapter.New(self, go)
            self.ChapterList[prefabName] = grid
        end
    end
    grid:UpdateChapterGrid(data)
    self.CurGrid = grid

    if self.DefaultStageId then
        grid:ClickStageGridByStageId(self.DefaultStageId)
        self.DefaultStageId = nil
    end
end

function XUiFubenRepeatchallenge:RefreshChapterReward(chapterId)
    self.ChapterRewardGrids = self.ChapterRewardGrids or {}
    local rewardId = XDataCenter.FubenRepeatChallengeManager.GetChapterRewardId(chapterId)
    local rewards = XRewardManager.GetRewardList(rewardId)

    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.ChapterRewardGrids[i]
        if not grid then
            local go = i == 1 and self.GridCommonPopUp or CS.UnityEngine.Object.Instantiate(self.GridCommonPopUp)
            grid = XUiGridCommon.New(self, go)
            self.ChapterRewardGrids[i] = grid
        end
        grid:Refresh(rewards[i])
        grid.Transform:SetParent(self.PanelRewrds, false)
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.ChapterRewardGrids do
        self.ChapterRewardGrids[i].GameObject:SetActiveEx(false)
    end

    local canGet, des = XDataCenter.FubenRepeatChallengeManager.CheckChapterRewardCanGet(chapterId)
    local hasGot = XDataCenter.FubenRepeatChallengeManager.CheckChapterRewardGot(chapterId)
    if hasGot then
        self.BtnTreasure:SetDisable(true)
        self.TxtCondition.gameObject:SetActiveEx(false)
        self.BtnTreasure.gameObject:SetActiveEx(true)
    else
        if not canGet then
            self.TxtCondition.text = des
            self.TxtCondition.gameObject:SetActiveEx(true)
            self.BtnTreasure.gameObject:SetActiveEx(false)
        else
            self.TxtCondition.gameObject:SetActiveEx(false)
            self.BtnTreasure:SetDisable(false)
            self.BtnTreasure.gameObject:SetActiveEx(true)
        end
    end

    XRedPointManager.Check(self.RedPointId, chapterId)
end

function XUiFubenRepeatchallenge:OnCheckRewards(count)
    local isRed = count >= 0
    local chapterIndex = self.CurChapterIndex
    if chapterIndex then
        self["BtnChapter" .. chapterIndex]:ShowReddot(isRed)
    end
end

function XUiFubenRepeatchallenge:ShowStageDetail(stage)
    -- 复刷关拦截已结束章节
    local isFinished = XDataCenter.FubenRepeatChallengeManager.IsStageFinished(stage.StageId)
    if isFinished then
        XUiManager.TipError(CsXTextManagerGetText("ActivityRepeatChallengeChapterFinished"))
        return
    end

    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Main_huge)

    if XDataCenter.FubenRepeatChallengeManager.IsStatusEqualFightEnd() then
        XUiManager.TipText("ActivityRepeatChallengeFightEnd")
        return
    end

    self:OpenOneChildUi(ChildDetailUi, self)
    self:FindChildUiObj(ChildDetailUi):Refresh(stage)
end

function XUiFubenRepeatchallenge:CloseStageDetailCb()
    if XLuaUiManager.IsUiShow(ChildDetailUi) then
        self:FindChildUiObj(ChildDetailUi):CloseWithAnimDisable()
    end
end

function XUiFubenRepeatchallenge:CloseStageDetail()
    if self.CurGrid then
        self.CurGrid:CancelSelect()
    end
end

function XUiFubenRepeatchallenge:CreateActivityTimer()
    self:DestroyActivityTimer()

    local time = XTime.GetServerNowTimestamp()
    local fightEndTime = XDataCenter.FubenRepeatChallengeManager.GetFightEndTime()
    local activityEndTime = XDataCenter.FubenRepeatChallengeManager.GetActivityEndTime()
    local shopStr = CsXTextManagerGetText("ActivityBranchShopLeftTime")
    local fightStr = CsXTextManagerGetText("ActivityBranchFightLeftTime")

    if XDataCenter.FubenRepeatChallengeManager.IsStatusEqualFightEnd() then
        self.TxtResetDesc.text = shopStr
        self.TxtLeftTime.text = XUiHelper.GetTime(activityEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
    else
        self.TxtResetDesc.text = fightStr
        self.TxtLeftTime.text = XUiHelper.GetTime(fightEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
    end

    self.ActivityTimer = CsXScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtLeftTime) then
            self:DestroyActivityTimer()
            return
        end

        time = time + 1

        if time >= activityEndTime then
            self:DestroyActivityTimer()
            XDataCenter.FubenRepeatChallengeManager.OnActivityEnd()
        elseif fightEndTime <= time then
            local leftTime = activityEndTime - time
            if leftTime > 0 then
                self.TxtResetDesc.text = shopStr
                self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            end
        else
            local leftTime = fightEndTime - time
            if leftTime > 0 then
                self.TxtResetDesc.text = fightStr
                self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            else
                self:DestroyActivityTimer()
                self:CreateActivityTimer()
            end
        end
    end, CsXScheduleManager.SECOND, 0)
end

function XUiFubenRepeatchallenge:DestroyActivityTimer()
    if self.ActivityTimer then
        CsXScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiFubenRepeatchallenge:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnActDesc, self.OnBtnActDescClick)
    self:RegisterClickEvent(self.BtnSwitch2Fight, self.OnBtnSwitch2FightClick)
    self:RegisterClickEvent(self.BtnSwitch2Regional, self.OnBtnSwitch2RegionalClick)
    self:RegisterClickEvent(self.BtnLevelDes, self.OnBtnLevelDesClick)
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    self.BtnShop.CallBack = function() self:OnBtnShopClick() end
end

function XUiFubenRepeatchallenge:OnBtnBackClick()
    if XLuaUiManager.IsUiShow(ChildDetailUi) then
        self:CloseStageDetail()
    else
        self:Close()
    end
end

function XUiFubenRepeatchallenge:OnBtnCloseDetailClick()
    self:CloseStageDetail()
end

function XUiFubenRepeatchallenge:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenRepeatchallenge:OnBtnActDescClick()
    XUiManager.UiFubenDialogTip("", XDataCenter.FubenRepeatChallengeManager.GetActDescription())
end

function XUiFubenRepeatchallenge:OnBtnSwitch2FightClick()
    if not XDataCenter.FubenRepeatChallengeManager.IsStatusEqualChallengeBegin()
    or not XDataCenter.FubenRepeatChallengeManager.GetCurChapterIndex(XDataCenter.FubenRepeatChallengeManager.DifficultType.Difficult) then
        local chanllengeBeginTime = XDataCenter.FubenRepeatChallengeManager.GetActivityChallengeBeginTime()
        local timeStr = XTime.TimestampToGameDateTimeString(chanllengeBeginTime, TimeFormat)
        local desc = CsXTextManagerGetText("ActivityRepeatChallengeHideBeginTime", timeStr)
        XUiManager.TipError(desc)
        return
    end

    local ret, desc = XDataCenter.FubenRepeatChallengeManager.IsDifficultModeOpen()
    if not ret then
        XUiManager.TipError(desc)
        return
    end

    XDataCenter.FubenRepeatChallengeManager.SelectDifficult(XDataCenter.FubenRepeatChallengeManager.DifficultType.Difficult)
    self.PanelTabChapterGroup.gameObject:SetActiveEx(false)
    self:CloseStageDetail()
    self:Refresh()
end

function XUiFubenRepeatchallenge:OnBtnSwitch2RegionalClick()
    XDataCenter.FubenRepeatChallengeManager.SelectDifficult(XDataCenter.FubenRepeatChallengeManager.DifficultType.Normal)
    self.PanelTabChapterGroup.gameObject:SetActiveEx(true)
    self:CloseStageDetail()
    self:Refresh()
end

function XUiFubenRepeatchallenge:OnBtnLevelDesClick()
    XLuaUiManager.Open("UiFubenRepeatchallengeLevelDes")
end

function XUiFubenRepeatchallenge:OnClickTabCallBack(tabIndex)
    local chapterId = XDataCenter.FubenRepeatChallengeManager.GetChapterId(self.DifficultType, tabIndex)
    local isFinished = XDataCenter.FubenRepeatChallengeManager.IsChapterFinished(chapterId)
    local isUnlock = XDataCenter.FubenRepeatChallengeManager.IsChapterUnlock(chapterId)
    if not isFinished and not isUnlock then
        local time = XTime.GetServerNowTimestamp()
        local beginTime = XDataCenter.FubenRepeatChallengeManager.GetChapterBeginTime(chapterId)
        local timeStr = XUiHelper.GetTime(beginTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        XUiManager.TipError(CsXTextManagerGetText("ActivityRepeatChallengeChapterLock", timeStr))
        return
    end

    self.CurChapterIndex = tabIndex
    self:CloseStageDetail()
    self:PlayAnimation("AnimBeijingQieHuan")
    self:SelectChapter(chapterId)
end

function XUiFubenRepeatchallenge:OnBtnTreasureClick()
    local chapterId = self.SelectChapterId
    if XDataCenter.FubenRepeatChallengeManager.CheckChapterRewardGot(chapterId) then
        XUiManager.TipText("ActivityRepeatChallengeTaskAlreadyFinish")
        return
    end

    XDataCenter.FubenRepeatChallengeManager.RequesetGetReward(chapterId, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
        local exConsumeId = XDataCenter.FubenRepeatChallengeManager.ExCostItemId
        if exConsumeId and exConsumeId ~= 0 and self.CommonGrid then
            self.CommonGrid:Refresh({ TemplateId = exConsumeId, Count = XDataCenter.ItemManager.GetCount(exConsumeId) })
        end
        self:RefreshChapterReward(chapterId)
    end)
end

function XUiFubenRepeatchallenge:OnBtnShopClick()
    local skipId = XDataCenter.FubenRepeatChallengeManager.GetActivityConfig().ShopSkipId
    XFunctionManager.SkipInterface(skipId)
end
