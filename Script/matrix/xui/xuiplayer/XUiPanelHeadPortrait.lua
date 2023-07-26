XUiPanelHeadPortrait = XClass(nil, "XUiPanelHeadPortrait")

function XUiPanelHeadPortrait:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiPanelHeadPortrait:AutoAddListener()
    self.BtnRole.CallBack = function()
        self:OnBtnRoleClick()
    end
end

function XUiPanelHeadPortrait:OnBtnRoleClick()
    self.Base:SetImgRole(self.HeadPortraitId)
    self:SetSelectShow(self.Base)
    self.Base.OldSelectGrig:SetSelectShow(self.Base)
    self.Base.OldSelectGrig = self
    self:ShowRedPoint(false, true)

    self.Base:RefreshDynamicTable()
end

function XUiPanelHeadPortrait:UpdateGrid(chapter, parent)
    self.Base = parent
    self.HeadPortraitId = chapter.Id
    if chapter.ImgSrc ~= nil then
        self.UnLockImgHeadImg:SetRawImage(chapter.ImgSrc)
        self.LockImgHeadImg:SetRawImage(chapter.ImgSrc)
        self.HeadIcon = chapter.ImgSrc
    end

    if chapter.Effect then
        self.HeadIconEffect.gameObject:LoadPrefab(chapter.Effect)
        self.HeadIconEffect.gameObject:SetActiveEx(true)
    else
        self.HeadIconEffect.gameObject:SetActiveEx(false)
    end

    local isTimeLimit = chapter.LimitType ~= XDataCenter.HeadPortraitManager.HeadTimeLimitType.Forever
    self.LockIconTime.gameObject:SetActiveEx(isTimeLimit)
    self.SelIconTime.gameObject:SetActiveEx(isTimeLimit)

    self:SetSelectShow(parent)
    self:ShowLock(XDataCenter.HeadPortraitManager.IsHeadPortraitValid(self.HeadPortraitId))
end

function XUiPanelHeadPortrait:SetSelectShow(parent)
    if parent.TempHeadPortraitId == self.HeadPortraitId then
        self:ShowSelect(true)
    else
        self:ShowSelect(false)
    end
    if parent.CurrHeadPortraitId == self.HeadPortraitId then
        self:ShowTxt(true)
        if not self.Base.OldSelectGrig then
            self.Base.OldSelectGrig = self
            self:ShowRedPoint(false,true)
        end
    else
        self:ShowTxt(false)
    end
end

function XUiPanelHeadPortrait:ShowSelect(bShow)
    self.ImgRoleSelect.gameObject:SetActive(bShow)
end

function XUiPanelHeadPortrait:ShowTxt(bShow)
    self.TxtDangqian.gameObject:SetActive(bShow)
end

function XUiPanelHeadPortrait:ShowLock(unLock)
    self.SelRoleHead.gameObject:SetActive(unLock)
    self.LockRoleHead.gameObject:SetActive(not unLock)
end

function XUiPanelHeadPortrait:ShowRedPoint(bShow,IsClick)
    if not XDataCenter.HeadPortraitManager.IsHeadPortraitValid(self.HeadPortraitId) then
        self.Red.gameObject:SetActive(false)
    else
        self.Red.gameObject:SetActive(bShow)
    end

    if not bShow and IsClick then
        XDataCenter.HeadPortraitManager.SetHeadPortraitForOld(self.HeadPortraitId)
    end
end