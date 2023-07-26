---@class XUiGridMonsterCombatBtn
---@field BtnChapter XUiComponent.XUiButton
local XUiGridMonsterCombatBtn = XClass(nil, "XUiGridMonsterCombatBtn")

---@param rootUi XUiMonsterCombatMain
function XUiGridMonsterCombatBtn:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnChapter, self.OnBtnChapterClick)
end

function XUiGridMonsterCombatBtn:Refresh(chapterId)
    self.ChapterId = chapterId
    self.ChapterEntity = XDataCenter.MonsterCombatManager.GetChapterEntity(chapterId)
    -- 章节名
    self.TxtActiveName.text = self.ChapterEntity:GetName()
    self.TxtLockName.text = self.ChapterEntity:GetName()
    -- 是否解锁
    local isUnlock = self.ChapterEntity:CheckIsUnlock()
    local isCore = self.ChapterEntity:CheckIsCoreChapter()
    if isUnlock then
        -- 关卡积分
        self.TxtScore.gameObject:SetActiveEx(not isCore)
        if not isCore then
            self.TxtScore.text = self.ChapterEntity:GetChapterScore()
        end
    else
        -- 锁定描述
        self.TxtLockDesc.text = self.ChapterEntity:GetLockShowDesc()
    end
    -- 刷新红点
    local isRedPoint = self.ChapterEntity:CheckNewUnlockChapter()
    self.BtnChapter:ShowReddot(isRedPoint)
    local isAnim = XDataCenter.MonsterCombatManager.CheckChapterAnimation(self.ChapterId)
    if not isCore or not isUnlock or isAnim then
        self:RefreshChapterStatus(isUnlock)
    else
        self:PlayCoreChapterAnim(isUnlock)
    end
end

function XUiGridMonsterCombatBtn:PlayCoreChapterAnim(isUnlock)
    if isUnlock then
        self.RootUi:PlayAnimationWithMask("PanelStageActiveEnable", function()
            self:RefreshChapterStatus(true)
        end, function()
            self:RefreshChapterStatus(false)
        end)
        XDataCenter.MonsterCombatManager.SaveChapterAnimation(self.ChapterId)
    end
end

function XUiGridMonsterCombatBtn:RefreshChapterStatus(isUnlock)
    self.BtnChapter:SetButtonState(isUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.PanelStageActive.gameObject:SetActiveEx(isUnlock)
    self.PanelStageLock.gameObject:SetActiveEx(not isUnlock)
end

function XUiGridMonsterCombatBtn:OnBtnChapterClick()
    -- 判断章节是否解锁
    local isUnlock, lockDesc = self.ChapterEntity:CheckIsUnlock()
    if not isUnlock then
        XUiManager.TipMsg(lockDesc)
        return
    end
    XDataCenter.MonsterCombatManager.SaveChapterClick(self.ChapterId)
    XLuaUiManager.Open("UiMonsterCombatChapter", self.ChapterId)
end

return XUiGridMonsterCombatBtn