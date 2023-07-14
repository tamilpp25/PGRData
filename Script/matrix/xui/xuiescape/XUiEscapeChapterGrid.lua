local XUiEscapeChapterGrid = XClass(nil, "XUiEscapeChapterGrid")
local MAX_GRID_COUNT = 2

function XUiEscapeChapterGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)

    self.EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    self:InitClickCallback()
end

function XUiEscapeChapterGrid:InitClickCallback()
    for i = 1, MAX_GRID_COUNT do
        self["BtnEnterChapter" .. i].CallBack = function()
            self:OnBtnClick()
        end
    end
end

function XUiEscapeChapterGrid:Refresh(chapterGroupId, index, isHideLine)
    self.ChapterGroupId = chapterGroupId
    local useGridIndex = index % 2 ~= 0 and 1 or 2  --格子下标是单数的用1号位组件，否则用2号位
    local btnEnterChapter = self["BtnEnterChapter" .. useGridIndex]
    local chapterIdList = XEscapeConfigs.GetEscapeChapterIdListByGroupId(chapterGroupId)
    local normalChapterId = chapterIdList[XEscapeConfigs.Difficulty.Normal]
    local hardChapterId = chapterIdList[XEscapeConfigs.Difficulty.Hard]
    local normalChapterResult = self.EscapeData:GetChapterResult(normalChapterId)
    local hardChapterResult = self.EscapeData:GetChapterResult(hardChapterId)

    --章节名
    local chapterName = normalChapterId and XEscapeConfigs.GetChapterName(normalChapterId) or ""
    btnEnterChapter:SetNameByGroup(0, chapterName)

    --是否正在挑战中
    local challengeDesc = (self.EscapeData:IsInChallengeChapter(normalChapterId) or self.EscapeData:IsInChallengeChapter(hardChapterId)) and XUiHelper.GetText("InChallenge") or ""
    btnEnterChapter:SetNameByGroup(1, challengeDesc)

    --章节下标
    btnEnterChapter:SetNameByGroup(2, string.format("%02d", index))

    --简单难度通关积分
    local score = normalChapterResult and normalChapterResult:GetScore() or 0
    local grade = XEscapeConfigs.GetChapterSettleRemainTimeGrade(score)
    local stageChellengeDesc = self.EscapeData:IsChapterClear(normalChapterId) and string.format("%s(%s)", score, grade) or XUiHelper.GetText("EscapeNotChallenge")
    btnEnterChapter:SetNameByGroup(3, stageChellengeDesc)

    --困难难度通关积分
    score = hardChapterResult and hardChapterResult:GetScore() or 0
    grade = XEscapeConfigs.GetChapterSettleRemainTimeGrade(score)
    stageChellengeDesc = self.EscapeData:IsChapterClear(hardChapterId) and string.format("%s(%s)", score, grade) or XUiHelper.GetText("EscapeNotChallenge")
    btnEnterChapter:SetNameByGroup(4, stageChellengeDesc)

    --是否未解锁和解锁条件
    local timeId = XEscapeConfigs.GetChapterTimeId(normalChapterId)
    local conditionId = XEscapeConfigs.GetChapterOpenCondition(normalChapterId)
    local isOpen, desc
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        isOpen = false
        desc = XUiHelper.GetText("EscapeTimeCondition", os.date("%m-%d", XFunctionManager.GetStartTimeByTimeId(timeId)))
    elseif XTool.IsNumberValid(conditionId) then
        isOpen, desc = XConditionManager.CheckCondition(conditionId)
    else
        isOpen, desc = true, ""
    end
    btnEnterChapter:SetNameByGroup(5, desc)
    btnEnterChapter:SetDisable(not isOpen)

    for i = 1, MAX_GRID_COUNT do
        self["Line" .. i].gameObject:SetActiveEx(i == useGridIndex and not isHideLine)
        self["Stage" .. i].gameObject:SetActiveEx(i == useGridIndex)
    end
end

function XUiEscapeChapterGrid:SetStageObjActive(index, isActive)
    local stageObj = self["Stage" .. index]
    if stageObj then
        stageObj.gameObject:SetActiveEx(isActive)
    end
end

function XUiEscapeChapterGrid:SetLineObjActive(index, isActive)
    local lineObj = self["Line" .. index]
    if lineObj then
        lineObj.gameObject:SetActiveEx(isActive)
    end
end

function XUiEscapeChapterGrid:OnBtnClick()
    local chapterGroupId = self.ChapterGroupId
    local chapterIdList = XEscapeConfigs.GetEscapeChapterIdListByGroupId(chapterGroupId)
    local curChallengeChapterId = self.EscapeData:GetChapterId()

    --正在挑战其他章节
    if XTool.IsNumberValid(curChallengeChapterId) then
        local isNotClick = true
        for _, chapterId in ipairs(chapterIdList or {}) do
            if self.EscapeData:IsInChallengeChapter(chapterId) then
                isNotClick = false
            end
        end
        if isNotClick then
            XUiManager.TipErrorWithKey("ExcapeInChallenge", XEscapeConfigs.GetChapterName(curChallengeChapterId))
            return
        end
    end

    --未达到开启时间
    local normalChapterId = chapterIdList and chapterIdList[XEscapeConfigs.Difficulty.Normal]
    if not XDataCenter.EscapeManager.IsChapterOpen(normalChapterId, true) then
        return
    end
    XLuaUiManager.Open("UiEscapeFuben", chapterGroupId)
end

return XUiEscapeChapterGrid