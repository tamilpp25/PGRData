local XUiGridHeadFrame = XClass(nil, "XUiGridHeadFrame")

function XUiGridHeadFrame:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridHeadFrame:AutoAddListener()
    self.BtnRole.CallBack = function()
        self:OnBtnRoleClick()
    end
end

function XUiGridHeadFrame:OnBtnRoleClick()
    local IsTrueHeadFrame = self.Base:SetHeadFrameImgRole(self.HeadFrameId)
    self:SetSelectShow(self.Base)
    if self.Base.OldFrameSelectGrig then
        self.Base.OldFrameSelectGrig:SetSelectShow(self.Base)
    end
    self.Base.OldFrameSelectGrig = self
    self:ShowRedPoint(false, true)

    self.Base:ShowHeadFramePanel(IsTrueHeadFrame)
    self.Base:RefreshHeadFrameDynamicTable()
end

function XUiGridHeadFrame:UpdateGrid(chapter, parent)
    self.Base = parent
    self.HeadFrameId = chapter.Id
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

    local isTimeLimit = chapter.LimitType ~= XHeadPortraitConfigs.HeadTimeLimitType.Forever
    self.LockIconTime.gameObject:SetActiveEx(isTimeLimit)
    self.SelIconTime.gameObject:SetActiveEx(isTimeLimit)

    self:SetSelectShow(parent)
    self:ShowLock(XDataCenter.HeadPortraitManager.IsHeadPortraitValid(self.HeadFrameId))
end

function XUiGridHeadFrame:SetSelectShow(parent)
    if parent.TempHeadFrameId == self.HeadFrameId then
        self:ShowSelect(true)
    else
        self:ShowSelect(false)
    end
    if parent.CurrHeadFrameId == self.HeadFrameId then
        self:ShowTxt(true)
        if not self.Base.OldFrameSelectGrig then
            self.Base.OldFrameSelectGrig = self
            self:ShowRedPoint(false,true)
        end
    else
        self:ShowTxt(false)
    end
end

function XUiGridHeadFrame:ShowSelect(bShow)
    self.ImgRoleSelect.gameObject:SetActive(bShow)
end

function XUiGridHeadFrame:ShowTxt(bShow)
    self.TxtDangqian.gameObject:SetActive(bShow)
end

function XUiGridHeadFrame:ShowLock(unLock)
    self.SelRoleHead.gameObject:SetActive(unLock)
    self.LockRoleHead.gameObject:SetActive(not unLock)
end

function XUiGridHeadFrame:ShowRedPoint(bShow,IsClick)
    if not XDataCenter.HeadPortraitManager.IsHeadPortraitValid(self.HeadFrameId) then
        self.Red.gameObject:SetActive(false)
    else
        self.Red.gameObject:SetActive(bShow)
    end

    if not bShow and IsClick then
        XDataCenter.HeadPortraitManager.SetHeadPortraitForOld(self.HeadFrameId)
        self.Base:ShowHeadFrameRedPoint()
    end
end

return XUiGridHeadFrame