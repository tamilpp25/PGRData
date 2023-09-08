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
    self.ChapterViewModel = viewModel
    local extralData = viewModel:GetExtralData()
    self.RImgBigIcon:SetRawImage(viewModel:GetIcon())
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
    self.TxtName2.text = string.format( "%s %s", viewModel:GetExtralName(), viewModel:GetName())
    self.TxtNumber.text = viewModel:GetExtralName()
    self.PanelChapterLock.gameObject:SetActiveEx(viewModel:GetIsLocked())
    self.ImgProgressLock.gameObject:SetActiveEx(viewModel:GetIsLocked())
    self.PanelCollect.gameObject:SetActiveEx(not viewModel:GetIsLocked())
    self.RawImageBlueBg.gameObject:SetActiveEx(not viewModel:GetIsLocked())
    self.TxtPercentNormal.gameObject:SetActiveEx(not viewModel:GetIsLocked())
    self.TxtLock1.text = XUiHelper.GetText("CommonLockedTip") --2是放大的，1是缩小的
    self.TxtLock2.text = viewModel:GetLockTip()
    self.PanelActivityTag.gameObject:SetActiveEx(viewModel:CheckHasTimeLimitTag())
    local weeklyChallengeCount = viewModel:GetWeeklyChallengeCount()
    self.PanelMultipleWeeksTag.gameObject:SetActiveEx(weeklyChallengeCount > 0)
    self.TxtWeekNum.text = weeklyChallengeCount
    self.PanelNewEffect.gameObject:SetActiveEx(viewModel:CheckHasNewTag())
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
    local extralData = self.ChapterViewModel:GetExtralData()
    local hardViewModel = self.MainLineManager:ExGetChapterViewModelById(extralData.MainId, XDataCenter.FubenManager.DifficultHard, extralData.Index)
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