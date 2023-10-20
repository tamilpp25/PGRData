XUiGridArchiveMonster = XClass(XUiNode, "XUiGridArchiveMonster")

local LockNameText = CS.XTextManager.GetText("ArchiveLockNameText")

function XUiGridArchiveMonster:OnStart()
    self:SetButtonCallBack()
end

function XUiGridArchiveMonster:SetButtonCallBack()
    self.TemplateBtn.CallBack = function()
        self:OnBtnSelect()
    end
end

function XUiGridArchiveMonster:OnBtnSelect()
    if self.Chapter:GetIsLockMain() then
        XUiManager.TipText("ArchiveMonsterLock")
        return
    end
    XMVCA.XArchive:GetMonsterEvaluateFromSever(self.Chapter:GetNpcId(), function()
        XLuaUiManager.Open("UiArchiveMonsterDetail", self.ChapterList, self.CurIndex)
    end)
end

function XUiGridArchiveMonster:UpdateGrid(chapterList, base, index)
    if chapterList and chapterList[index] then
        self.Chapter = chapterList[index]
        self.ChapterList = chapterList
        self:SetMonsterData(self.Chapter)
        self:CheckNewTag(self.Chapter:GetId())
        self:CheckRedPoint(self.Chapter:GetId())
    end
    self.Base = base
    self.CurIndex = index
end

function XUiGridArchiveMonster:CheckNewTag(monsterId)
    XRedPointManager.CheckOnce(
    self.OnCheckArchiveTag,
    self,
    { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_TAG },
    monsterId
    )
end

function XUiGridArchiveMonster:CheckRedPoint(monsterId)
    XRedPointManager.CheckOnce(
    self.OnCheckArchiveRedPoint,
    self,
    { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_RED },
    monsterId
    )
end

function XUiGridArchiveMonster:SetMonsterData(chapter)
    if chapter:GetIsLockMain() then
        self.MonsterName.text = LockNameText
        if chapter:GetLockPic() and #chapter:GetLockPic() > 0 then
            self.MonsterImg:SetRawImage(chapter:GetLockPic())
        end
    else
        self.MonsterName.text = self._Control:GetMonsterArchiveName(chapter)
        if chapter:GetPic() and #chapter:GetPic() > 0 then
            self.MonsterImg:SetRawImage(chapter:GetPic())
        end
    end
end

function XUiGridArchiveMonster:OnCheckArchiveRedPoint(count)
    self.TemplateBtn:ShowReddot(count >= 0)
end

function XUiGridArchiveMonster:OnCheckArchiveTag(count)
    self.TemplateBtn:ShowTag(count >= 0)
end