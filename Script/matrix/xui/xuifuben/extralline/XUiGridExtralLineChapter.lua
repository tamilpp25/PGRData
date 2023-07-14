local XUiGridFubenChapter = require("XUi/XUiFuben/UiDynamicList/XUiGridFubenChapter")
local XUiBtnDownload = require("XUi/XUiDlcDownload/XUiBtnDownload")
local XUiGridExtralLineChapter = XClass(XUiGridFubenChapter, "XUiGridExtralLineChapter")

function XUiGridExtralLineChapter:Ctor(ui, clickFunc, openCb)
    XUiHelper.InitUiClass(self, ui)
    self.ClickFunc = clickFunc
    self.ChapterViewModel = nil
    self.Manager = nil
    XUiHelper.RegisterClickEvent(self, self.BtnSelf, self.OnBtnSelfClicked)
    self:SetOpenCallback(openCb)
    ---@type XUiBtnDownload
    self.GirdBtnDownload = XUiBtnDownload.New(self.BtnDownload)
end

function XUiGridExtralLineChapter:SetManager(value)
    self.Manager = value
end

function XUiGridExtralLineChapter:SetData(index, viewModel)
    XUiGridExtralLineChapter.Super.SetData(self, index)
    self.ChapterViewModel = viewModel
    -- 背景图
    self.RImgBigIcon:SetRawImage(viewModel:GetIcon())
    -- 进度条
    local hideProgressBar = viewModel.CheckHideProgressBar and viewModel:CheckHideProgressBar() or false
    self.ImgProgress.gameObject:SetActiveEx(not hideProgressBar)
    self.BgProgress.gameObject:SetActiveEx(not hideProgressBar and not viewModel:GetIsLocked())
    if not hideProgressBar then
        local currentProgress, maxProgress = viewModel:GetCurrentAndMaxProgress()
        self.ImgProgress.fillAmount = currentProgress / maxProgress
        self.TxtProgress.text = string.format( "%s%%", math.ceil(100 * currentProgress / maxProgress))
    end
    -- 进度提示
    local progressTips = viewModel:GetProgressTips()
    if not string.IsNilOrEmpty(progressTips) then
        self.TxtProgress.text = progressTips
        if self.TxtProgress2 then
            self.TxtProgress2.text = progressTips
        end
    end
    self.TxtPercentNormal.gameObject:SetActiveEx(not viewModel:GetIsLocked())
    local isShowThumbnailProgressTips = viewModel.CheckShowThumbnailProgressTips and viewModel:CheckShowThumbnailProgressTips() or false
    if self.TxtProgress2 then
        self.TxtProgress2.gameObject:SetActiveEx(isShowThumbnailProgressTips)
    end
    -- 名字
    self.TxtName.text = string.format("%s %s", viewModel:GetExtralName(), viewModel:GetName())
    local minText = string.gsub(self.TxtName.text, "ER", "") -- 缩略图太挤了 去掉前缀
    minText = string.gsub(minText, "EX", "")
    self.TxtName2.text = viewModel.GetMinCharacterName and viewModel.GetMinCharacterName() or minText
    -- 锁
    self.PanelChapterLock.gameObject:SetActiveEx(viewModel:GetIsLocked())
    
    self.TxtLock1.text = XUiHelper.GetText("CommonLockedTip") --2是放大的，1是缩小的
    self.TxtLock2.text = viewModel:GetLockTip()
    -- 左上角标签
    self.PanelActivityTag.gameObject:SetActiveEx(viewModel:CheckHasTimeLimitTag())
    self.PanelNewEffect.gameObject:SetActiveEx(viewModel:CheckHasNewTag())
    -- 周目挑战
    local weeklyChallengeCount = viewModel:GetWeeklyChallengeCount()
    self.PanelMultipleWeeksTag.gameObject:SetActiveEx(weeklyChallengeCount > 0)
    self.TxtWeekNum.text = weeklyChallengeCount
    
    self.UnSelectedImg.gameObject:SetActiveEx(not viewModel:GetIsLocked()) -- 避免刷新数据格子换数据，出现的双层遮罩问题
    -- 红点处理
    self:RefreshRedPoint()
    -- 普通模式(之后不再需要普通模式标签)
    self.PanelNormal.gameObject:SetActiveEx(false)
    local chapterType = self.Manager:ExGetChapterType()
    self.ImgKuai.gameObject:SetActiveEx(chapterType == XFubenConfigs.ChapterType.Prequel)
    local entryType = XDlcConfig.GetEntryTypeByChapterType(chapterType)
    self.GirdBtnDownload:Init(entryType, self.ChapterViewModel:GetId(), nil, handler(self, self.OnDownloadComplete))
    self.GirdBtnDownload:RefreshView()
    self.RImgLockMask.gameObject:SetActiveEx(viewModel:GetIsLocked() or self.GirdBtnDownload:CheckNeedDownload())
end

function XUiGridExtralLineChapter:OnBtnSelfClicked()
    if self.GirdBtnDownload:CheckNeedDownload() then
        self.GirdBtnDownload:OnBtnClick()
        return
    end
    if self.ClickFunc then
        self.ClickFunc(self.Index, self.ChapterViewModel)
    end
end
 
function XUiGridExtralLineChapter:RefreshRedPoint()
    if self.Manager:ExCheckHasOtherDifficulty() then
        local hardViewModel = self.Manager:ExGetChapterViewModelById(self.ChapterViewModel:GetId(), XDataCenter.FubenManager.DifficultHard)
        self.ImgRedDot.gameObject:SetActiveEx(self.ChapterViewModel:CheckHasRedPoint() or (hardViewModel and hardViewModel:CheckHasRedPoint()) )
    else
        self.ImgRedDot.gameObject:SetActiveEx(self.ChapterViewModel:CheckHasRedPoint())
    end
end

function XUiGridExtralLineChapter:GetMoveDuration(isOpen)
    if isOpen then
        return XFubenConfigs.ExtralLineMoveOpenTime
    else
        return XFubenConfigs.ExtralLineMoveCloseTime
    end
end

function XUiGridExtralLineChapter:OnDownloadComplete()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.RImgLockMask.gameObject:SetActiveEx(self.ChapterViewModel:GetIsLocked() or self.GirdBtnDownload:CheckNeedDownload())
end


return XUiGridExtralLineChapter