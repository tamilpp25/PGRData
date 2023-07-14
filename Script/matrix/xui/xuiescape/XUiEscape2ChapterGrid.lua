---@class XUiEscape2ChapterGrid
local XUiEscape2ChapterGrid = XClass(nil, "XUiEscape2ChapterGrid")

function XUiEscape2ChapterGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    ---@type UnityEngine.Transform
    self.HardEffect = XUiHelper.TryGetComponent(self.Transform, "StageOpen/HardEffect")
    if self.HardEffect then
        self.HardEffect.gameObject:SetActiveEx(false)
    end
    self:_AddBtnClickListener()
end

--region UiRefresh
function XUiEscape2ChapterGrid:Refresh(chapterId, index)
    self._ChapterId = chapterId
    local escapeData = XDataCenter.EscapeManager.GetEscapeData()
    local isInChallenge = escapeData and escapeData:IsInChallengeChapter(self._ChapterId)
    local isClear = escapeData and escapeData:IsChapterClear(self._ChapterId)
    
    -- BG&Icon
    local difficulty = XEscapeConfigs.GetChapterDifficulty(self._ChapterId)
    local numIconUrl = XEscapeConfigs.GetChapterNumIconUrl(index)
    local bgUrl = XEscapeConfigs.GetChapterDifficultyBgUrl(difficulty)
    if not string.IsNilOrEmpty(numIconUrl) then
        self.ImgStageNum:SetSprite(numIconUrl)
    end
    if not string.IsNilOrEmpty(bgUrl) then
        self.RImgModel:SetRawImage(bgUrl)
    end
    -- DifficultyEffect
    if self.HardEffect then
        self.HardEffect.gameObject:SetActiveEx(difficulty == XEscapeConfigs.Difficulty.Hard)
    end
    -- Text
    self.TxtStageTitle.text = XEscapeConfigs.GetChapterName(self._ChapterId)
    self.En.text = XEscapeConfigs.GetChapterEnName(self._ChapterId)
    -- Lock
    local isOpen, desc
    local timeId = XEscapeConfigs.GetChapterTimeId(self._ChapterId)
    local conditionId = XEscapeConfigs.GetChapterOpenCondition(self._ChapterId)
    local lockUrl = XEscapeConfigs.GetChapterDifficultyLockUrl(difficulty)
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        isOpen = false
        desc = XUiHelper.GetText("EscapeTimeCondition", os.date("%m-%d", XFunctionManager.GetStartTimeByTimeId(timeId)))
    elseif XTool.IsNumberValid(conditionId) then
        isOpen, desc = XConditionManager.CheckCondition(conditionId)
    else
        isOpen, desc = true, ""
    end
    if not isOpen then
        if not string.IsNilOrEmpty(lockUrl) then
            self.RImgLock:SetRawImage(lockUrl)
        end
        self.TxtLock.text = desc
    end
    self.Lock.gameObject:SetActiveEx(not isOpen)
    self.StageOpen.gameObject:SetActiveEx(isOpen)
    -- InChallenge
    self.PanelInChallenge.gameObject:SetActiveEx(isOpen and isInChallenge)
    -- IsClear
    self.PanleClear.gameObject:SetActiveEx(isOpen and not isInChallenge and isClear)
end

function XUiEscape2ChapterGrid:SetActive(active)
    self.GameObject:SetActiveEx(active)
end
--endregion

--region Button
function XUiEscape2ChapterGrid:_AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.Transform, self._OnBtnClick)
    if self.Btn then
        XUiHelper.RegisterClickEvent(self, self.Btn, self._OnBtnClick)
    end
end

function XUiEscape2ChapterGrid:_OnBtnClick()
    local escapeData = XDataCenter.EscapeManager.GetEscapeData()
    -- Lock
    if not XDataCenter.EscapeManager.IsChapterOpen(self._ChapterId, true) then
        return
    end
    -- InChallenge
    if escapeData and XTool.IsNumberValid(escapeData:GetChapterId()) then
        if not escapeData:IsInChallengeChapter(self._ChapterId) then
            XUiManager.TipErrorWithKey("ExcapeInChallenge", XEscapeConfigs.GetChapterName(escapeData:GetChapterId()))
            return
        end
    end
    
    XLuaUiManager.Open("UiEscapeFuben", self._ChapterId)
end
--endregion

return XUiEscape2ChapterGrid