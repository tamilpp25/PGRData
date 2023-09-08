XUiGridArchive = XClass(XUiNode, "XUiGridArchive")

function XUiGridArchive:OnStart()
    self:SetButtonCallBack()
end

function XUiGridArchive:AddRedPointEvent(type)
    if type == XArchiveConfigs.SubSystemType.Monster then
        self:AddRedPointEvent(self.ArchiveBtn,
            self.OnCheckArchiveRedPoint,
            self,
            { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_ALL })
    elseif type == XArchiveConfigs.SubSystemType.Weapon then
        self:AddRedPointEvent(self.ArchiveBtn,
            self.OnCheckArchiveRedPoint,
            self,
            { XRedPointConditions.Types.CONDITION_ARCHIVE_WEAPON })
    elseif type == XArchiveConfigs.SubSystemType.Awareness then
        self:AddRedPointEvent(self.ArchiveBtn,
            self.OnCheckArchiveRedPoint,
            self,
            { XRedPointConditions.Types.CONDITION_ARCHIVE_AWARENESS })
    elseif type == XArchiveConfigs.SubSystemType.CG then
        self:AddRedPointEvent(self.ArchiveBtn,
            self.OnCheckArchiveRedPoint,
            self,
            { XRedPointConditions.Types.CONDITION_ARCHIVE_CG_ALL })
    end

end

function XUiGridArchive:SetButtonCallBack()
    self.ArchiveBtn.CallBack = function()
        self:OnBtnSelect()
    end
end

function XUiGridArchive:OnBtnSelect()
    if self.SkipId then
        XFunctionManager.SkipInterface(self.SkipId)
    end
end

function XUiGridArchive:UpdateGrid(chapter, parent, type)
    self.Base = parent
    self:SetArchiveData(chapter)
    self:SetCompletionRate(type)
    self:CheckLock()
end

function XUiGridArchive:CheckLock()
    local IsLock = true
    local SkipFunctional = XFunctionConfig.GetSkipList(self.SkipId)
    if SkipFunctional then
        IsLock = not XFunctionManager.JudgeCanOpen(SkipFunctional.FunctionalId)
    end
    self:ShowLock(IsLock)
end

function XUiGridArchive:ShowLock(Lock)
    self.LockedGroup.gameObject:SetActiveEx(Lock)
    self.UnLockedGroup.gameObject:SetActiveEx(not Lock)
end

function XUiGridArchive:OnCheckArchiveRedPoint(count)
    self.ArchiveBtn:ShowReddot(count >= 0)
end

function XUiGridArchive:SetArchiveData(chapter)
    self.SkipId = chapter.SkipId
    self.ArchiveTitle.text = chapter.Name
    self.ProgressText.text = chapter.TagText

    self.GridTemplateTitle.gameObject:SetActiveEx(chapter.ShowTag > 0)

    if chapter.lockBg and #chapter.lockBg > 0 then
        self.LockedArchiveImg:SetRawImage(chapter.lockBg)
    end
    if chapter.UnLockBg and #chapter.UnLockBg > 0 then
        self.UnLockedArchiveImg:SetRawImage(chapter.UnLockBg)
    end
end

function XUiGridArchive:SetCompletionRate(type)
    local rate = 0
    if type == XArchiveConfigs.SubSystemType.Monster then
        rate = XDataCenter.ArchiveManager.GetMonsterCompletionRate()
    elseif type == XArchiveConfigs.SubSystemType.Weapon then
        rate = XDataCenter.ArchiveManager.GetWeaponCollectRate()
    elseif type == XArchiveConfigs.SubSystemType.Awareness then
        rate = XDataCenter.ArchiveManager.GetAwarenessCollectRate()
    elseif type == XArchiveConfigs.SubSystemType.Story then
        rate = XDataCenter.ArchiveManager.GetStoryCollectRate()
    elseif type == XArchiveConfigs.SubSystemType.CG then
        rate = XDataCenter.ArchiveManager.GetCGCompletionRate()
    elseif type == XArchiveConfigs.SubSystemType.NPC then
        rate = XDataCenter.ArchiveManager.GetNPCCompletionRate()
    elseif type == XArchiveConfigs.SubSystemType.Partner then
        rate = XDataCenter.ArchiveManager.GetPartnerCompletionRate()
    elseif type == XArchiveConfigs.SubSystemType.PV then
        rate = XDataCenter.ArchiveManager.GetPVCompletionRate()
    end
    self.ProgressNub.text = string.format("%d%s", rate, "%")
    self.ProgressSlider.value = rate / 100
end