local XUiGridHeadPortrait = XClass(XUiNode, "XUiGridHeadPortrait")

function XUiGridHeadPortrait:OnStart(rootUi)
    self._RootUi = rootUi
    self:AutoAddListener()
end

function XUiGridHeadPortrait:AutoAddListener()
    self.BtnRole.CallBack = function()
        self:OnBtnRoleClick()
    end
end

function XUiGridHeadPortrait:OnBtnRoleClick()
    self.Base:SetHeadPortraitImgRole(self.HeadPortraitId)
    self:SetSelectShow(self.Base)
    if self.Base.OldPortraitSelectGrig then
        self.Base.OldPortraitSelectGrig:SetSelectShow(self.Base)
    end
    self.Base.OldPortraitSelectGrig = self
    self:ShowRedPoint(false, true)

    self.Base:ShowHeadPortraitPanel()
    self.Base:RefreshHeadPortraitDynamicTable()
end

function XUiGridHeadPortrait:UpdateGrid(chapter, parent)
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

    local isTimeLimit = chapter.LimitType ~= XHeadPortraitConfigs.HeadTimeLimitType.Forever
    self.LockIconTime.gameObject:SetActiveEx(isTimeLimit)
    self.SelIconTime.gameObject:SetActiveEx(isTimeLimit)

    self:SetSelectShow(parent)
    self:ShowLock(XDataCenter.HeadPortraitManager.IsHeadPortraitValid(self.HeadPortraitId))
end

function XUiGridHeadPortrait:SetSelectShow(parent)
    --这个头像类貌似不仅仅在个性设置里会用到，因此需要支持原逻辑处理
    local accessor = self._RootUi or parent
    
    if accessor.TempHeadPortraitId == self.HeadPortraitId then
        self:ShowSelect(true)
    else
        self:ShowSelect(false)
    end
    if accessor.CurrHeadPortraitId == self.HeadPortraitId then
        self:ShowTxt(true)
        if not self.Base.OldPortraitSelectGrig then
            self.Base.OldPortraitSelectGrig = self
            self:ShowRedPoint(false,true)
        end
    else
        self:ShowTxt(false)
    end
end

function XUiGridHeadPortrait:ShowSelect(bShow)
    self.ImgRoleSelect.gameObject:SetActive(bShow)
end

function XUiGridHeadPortrait:ShowTxt(bShow)
    self.TxtDangqian.gameObject:SetActive(bShow)
end

function XUiGridHeadPortrait:ShowLock(unLock)
    self.SelRoleHead.gameObject:SetActive(unLock)
    self.LockRoleHead.gameObject:SetActive(not unLock)
end

function XUiGridHeadPortrait:ShowRedPoint(bShow,IsClick)
    if not XDataCenter.HeadPortraitManager.IsHeadPortraitValid(self.HeadPortraitId) then
        self.Red.gameObject:SetActive(false)
    else
        self.Red.gameObject:SetActive(bShow)
    end

    if not bShow and IsClick then
        local accessor = self._RootUi or self.Base
        
        XDataCenter.HeadPortraitManager.SetHeadPortraitForOld(self.HeadPortraitId)
        accessor:ShowHeadPortraitRedPoint()
    end
end

return XUiGridHeadPortrait