---@class XUiArchive.XUiGridArchive: XUiNode
---@field private _Control XArchiveControl
local XUiGridArchive = XClass(XUiNode, "XUiGridArchive")

function XUiGridArchive:OnStart(type)
    self:SetButtonCallBack()
    self:InitPointEvent(type)
end

function XUiGridArchive:InitPointEvent(type)
    self.ArchiveBtn:ShowReddot(false)
    
    if type == XEnumConst.Archive.SubSystemType.Monster then
        self:AddRedPointEvent(self.ArchiveBtn,
            self.OnCheckArchiveRedPoint,
            self,
            { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_ALL })
    elseif type == XEnumConst.Archive.SubSystemType.Weapon then
        self:AddRedPointEvent(self.ArchiveBtn,
            self.OnCheckArchiveRedPoint,
            self,
            { XRedPointConditions.Types.CONDITION_ARCHIVE_WEAPON })
    elseif type == XEnumConst.Archive.SubSystemType.Awareness then
        self:AddRedPointEvent(self.ArchiveBtn,
            self.OnCheckArchiveRedPoint,
            self,
            { XRedPointConditions.Types.CONDITION_ARCHIVE_AWARENESS })
    elseif type == XEnumConst.Archive.SubSystemType.CG then
        self:AddRedPointEvent(self.ArchiveBtn,
            self.OnCheckArchiveRedPoint,
            self,
            { XRedPointConditions.Types.CONDITION_ARCHIVE_CG_ALL })
    elseif type == XEnumConst.Archive.SubSystemType.Comic then
        self:AddRedPointEvent(self.ArchiveBtn, 
            self.OnCheckArchiveRedPoint,
            self,
            { XRedPointConditions.Types.CONDITION_ARCHIVE_COMIC_GROUP_RED }) 
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
    if not chapter then
        return
    end
    
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
    if type == XEnumConst.Archive.SubSystemType.Monster then
        rate = self._Control:GetMonsterCompletionRate()
    elseif type == XEnumConst.Archive.SubSystemType.Weapon then
        rate = self._Control:GetWeaponCollectRate()
    elseif type == XEnumConst.Archive.SubSystemType.Awareness then
        rate = self._Control.AwarenessControl:GetAwarenessCollectRate()
    elseif type == XEnumConst.Archive.SubSystemType.Story then
        rate = self._Control:GetStoryCollectRate()
    elseif type == XEnumConst.Archive.SubSystemType.CG then
        rate = self._Control:GetCGCompletionRate()
    elseif type == XEnumConst.Archive.SubSystemType.NPC then
        rate = self._Control:GetNPCCompletionRate()
    elseif type == XEnumConst.Archive.SubSystemType.Partner then
        rate = self._Control:GetPartnerCompletionRate()
    elseif type == XEnumConst.Archive.SubSystemType.PV then
        rate = self._Control:GetPVCompletionRate()
    elseif type == XEnumConst.Archive.SubSystemType.Comic then
        rate = self._Control.ComicControl:GetComicCompletionRate()
    end
    self.ProgressNub.text = string.format("%d%s", rate, "%")
    self.ProgressSlider.value = rate / 100
end

return XUiGridArchive