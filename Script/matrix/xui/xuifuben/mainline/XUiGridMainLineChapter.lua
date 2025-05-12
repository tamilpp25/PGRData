local XUiGridFubenChapter = require("XUi/XUiFuben/UiDynamicList/XUiGridFubenChapter")
local XUiGridMainLineChapter = XClass(XUiGridFubenChapter, "XUiGridMainLineChapter")

function XUiGridMainLineChapter:Ctor(ui, clickFunc)
    XUiHelper.InitUiClass(self, ui)
    self.ClickFunc = clickFunc
    self.ChapterViewModel = nil
    self.MainLineManager = XDataCenter.FubenManagerEx.GetMainLineManager()
    XUiHelper.RegisterClickEvent(self, self.BtnSelf, self.OnBtnSelfClicked)
end

function XUiGridMainLineChapter:SetData(index, viewModel)
    XUiGridMainLineChapter.Super.SetData(self, index, viewModel)
    self.PanelTag.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)

    self.ChapterViewModel = viewModel
    local extralData = viewModel:GetExtralData()
    self.RImgBigIcon:SetRawImage(viewModel:GetIcon())

    -- 成就图标
    local achievementIcon = viewModel:GetAchievementIcon()
    local isShowAchieve = achievementIcon ~= nil
    self.RImgAchievement.gameObject:SetActiveEx(isShowAchieve)
    self.RImgAchievementUnlock.gameObject:SetActiveEx(isShowAchieve)
    if isShowAchieve then
        local isUnlock = viewModel:IsAchievementUnlock()
        self.RImgAchievement.gameObject:SetActiveEx(not isUnlock)
        self.RImgAchievementUnlock.gameObject:SetActiveEx(isUnlock)
        self.RImgAchievementUnlock:SetRawImage(achievementIcon)

        local iconLock = viewModel:GetAchievementIconLock()
        self.RImgAchievement:SetRawImage(iconLock)
    end

    -- 特效
    local isShowEffect = viewModel:IsShowEffect()
    self.Effect.gameObject:SetActiveEx(isShowEffect)

    if viewModel:GetId() == XDataCenter.FubenMainLineManager.TRPGChapterId then
        local progress = XDataCenter.TRPGManager.GetProgress()
        self.ImgProgress.fillAmount = progress / 100
        self.TxtProgress.text = string.format( "%s%%", progress)
        self.TxtCollectTip.text = self.TxtProgress.text
    else
        local currentProgress, maxProgress = viewModel:GetCurrentAndMaxProgress()
        self.ImgProgress.fillAmount = currentProgress / maxProgress
        self.TxtProgress.text = string.format( "%s%%", math.ceil(100 * currentProgress / maxProgress))
        self.TxtCollectTip.text = string.format( "%s/%s", currentProgress, maxProgress)
    end
    self.TxtName.text = viewModel:GetName()
    local fontSize = viewModel.GetNameFontSize and viewModel:GetNameFontSize() or 0
    if XTool.IsNumberValid(fontSize) then
        self.TxtName2.text = string.format("<size=%s>%s %s</size>", fontSize, viewModel:GetExtralName(), viewModel:GetName())
    else
        self.TxtName2.text = string.format("%s %s", viewModel:GetExtralName(), viewModel:GetName())
    end
    self.TxtNumber.text = viewModel:GetExtralName()
    self.PanelChapterLock.gameObject:SetActiveEx(viewModel:GetIsLocked())
    self.ImgProgressLock.gameObject:SetActiveEx(viewModel:GetIsLocked())
    self.PanelCollect.gameObject:SetActiveEx(not viewModel:GetIsLocked())
    self.RawImageBlueBg.gameObject:SetActiveEx(not viewModel:GetIsLocked())
    self.TxtPercentNormal.gameObject:SetActiveEx(not viewModel:GetIsLocked())
    self.TxtLock1.text = XUiHelper.GetText("CommonLockedTip") --2是放大的，1是缩小的
    self.TxtLock2.text = viewModel:GetLockTip()

    -- 特殊标签、特效
    if viewModel:CheckHasSpecialTag() then
        self.PanelTag.gameObject:SetActiveEx(true)
        self.TagImage.color = XUiHelper.Hexcolor2Color(XEnumConst.MAINLINE2.MAIN_TAG_COLOR.SPECIAL)
        self.TagText.text = viewModel:GetSpecialTagName()
        
        local effectPath = viewModel:GetSpecialEffect()
        self.PanelEffectLink.transform:LoadPrefab(effectPath)
        self.PanelEffect.gameObject:SetActiveEx(true)

    -- 限时开放页签
    elseif viewModel:CheckHasTimeLimitTag() then
        self.PanelTag.gameObject:SetActiveEx(true)
        self.TagImage.color = XUiHelper.Hexcolor2Color(XEnumConst.MAINLINE2.MAIN_TAG_COLOR.LIMIT_TIME)
        self.TagText.text = XUiHelper.GetText("MainLineChapterTimeLimitTag")

    -- 新章节页签
    elseif viewModel:CheckHasNewTag() then
        self.PanelTag.gameObject:SetActiveEx(true)
        self.TagImage.color = XUiHelper.Hexcolor2Color(XEnumConst.MAINLINE2.MAIN_TAG_COLOR.NEW)
        self.TagText.text = XUiHelper.GetText("MainLineChapterNewTag")
    end

    local weeklyChallengeCount = viewModel:GetWeeklyChallengeCount()
    self.PanelMultipleWeeksTag.gameObject:SetActiveEx(weeklyChallengeCount > 0)
    self.TxtWeekNum.text = weeklyChallengeCount
    self.UnSelectedImg.gameObject:SetActiveEx(not viewModel:GetIsLocked()) -- 避免刷新数据格子换数据，出现的双层遮罩问题
    self.UnSelectedImg.transform.parent.gameObject:SetActiveEx(true)
    self:RefreshRedPoint()
    self.RImgLockMask.gameObject:SetActiveEx(viewModel:GetIsLocked())
end

function XUiGridMainLineChapter:OnBtnSelfClicked()
    if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.MainLine, self.ChapterViewModel:GetId()) then
        return
    end
    if self.ClickFunc then
        self.ClickFunc(self.Index, self.ChapterViewModel)
    end
end

function XUiGridMainLineChapter:RefreshRedPoint()
    local hardViewModel = self.MainLineManager:GetHardChapterViewModel(self.ChapterViewModel)
    -- 普通模式(之后不再需要普通模式标签)
    self.PanelNormal.gameObject:SetActiveEx(false)
    -- 红点处理
    self.ImgRedDot.gameObject:SetActiveEx(self.ChapterViewModel:CheckHasRedPoint() or (hardViewModel and hardViewModel:CheckHasRedPoint()))
end

function XUiGridMainLineChapter:GetMoveDuration(isOpen)
    if isOpen then
        return XFubenConfigs.MainLineMoveOpenTime
    else
        return XFubenConfigs.MainLineMoveCloseTime
    end
end

return XUiGridMainLineChapter