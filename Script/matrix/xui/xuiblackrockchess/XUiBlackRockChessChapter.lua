local XUiPanelChapter = require("XUi/XUiBlackRockChess/XUiGrid/XUiPanelChapter")

---@class XUiBlackRockChessChapter : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessChapter = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessChapter")

function XUiBlackRockChessChapter:OnAwake()
    self:RegisterClickEvent(self.BtnDifficult, self.OnClickBtnDifficult)
    if not self.BtnEasy then
        self.BtnEasy = self.Transform:FindTransform("BtnEasy"):GetComponent("XUiButton")
    end
    self:RegisterClickEvent(self.BtnEasy, self.OnClickBtnDifficult)
    if self.BtnEasy02 then
        self:RegisterClickEvent(self.BtnEasy02, self.OnClickBtnDifficult)
    end
    if self.BtnDifficultHard02 then
        self:RegisterClickEvent(self.BtnDifficultHard02, self.OnClickBtnDifficult)
    end
    self:BindHelpBtn(self.BtnHelp, "UiBlackRockChessChapter")
end

function XUiBlackRockChessChapter:OnStart(chapterId, isNormal)
    self._ChapterId = chapterId
    ---@type XUiPanelChapter[]
    self._Chapters = {}
    self:InitCompnent()
    self:InitBtnDifficulty(isNormal)
    self:UpdateView()
    self:UpdateProgress()
end

function XUiBlackRockChessChapter:OnEnable()
    for _, chapter in pairs(self._Chapters) do
        chapter:Refresh()
    end
    self:UpdateProgress()
end

function XUiBlackRockChessChapter:OnDestroy()

end

function XUiBlackRockChessChapter:InitCompnent()
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControlVariable)

    local endTime = self._Control:GetActivityStopTime()
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
end

function XUiBlackRockChessChapter:UpdateView()
    self:UpdateChapterShow()
    self:LoadChapterPrefab()
    
    self:UpdateProgress()

    local isChapterOne = self._ChapterId == XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_ONE
    local isNormal = self._Difficulty == XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL
    self.TxtChapterName01.gameObject:SetActiveEx(isChapterOne and isNormal)
    self.TxtChapterName02.gameObject:SetActiveEx(isChapterOne and not isNormal)
    self.TxtChapterName03.gameObject:SetActiveEx(not isChapterOne and isNormal)
    self.TxtChapterName04.gameObject:SetActiveEx(not isChapterOne and not isNormal)

    if self.BtnEasy02 and self.BtnDifficultHard02 then
        self.BtnEasy02.gameObject:SetActiveEx(not isChapterOne and not isNormal)
        self.BtnDifficultHard02.gameObject:SetActiveEx(not isChapterOne and isNormal)
        self.BtnDifficult.gameObject:SetActiveEx(isChapterOne and isNormal)
        self.BtnEasy.gameObject:SetActiveEx(isChapterOne and not isNormal)
    else
        self.BtnEasy.gameObject:SetActiveEx(not self._IsNormal)
        self.BtnDifficult.gameObject:SetActiveEx(self._IsNormal)
    end
end

function XUiBlackRockChessChapter:LoadChapterPrefab()
    local path = self._Control:GetChapterPrefabPath(self._ChapterId, self._Difficulty)
    if not self._Chapters[self._Difficulty] then
        local root = self._IsNormal and self.PanelNormalChapter or self.PanelHardChapter
        local go = root.gameObject:LoadPrefab(path)
        self._Chapters[self._Difficulty] = XUiPanelChapter.New(go, self)
        self._Chapters[self._Difficulty]:SetData(self._ChapterId, self._Difficulty)
    end
end

function XUiBlackRockChessChapter:UpdateChapterShow()
    self.PanelNormalChapter.gameObject:SetActiveEx(self._IsNormal)
    self.PanelHardChapter.gameObject:SetActiveEx(not self._IsNormal)

    
    --简单关卡，显示困难按钮红点
    if self._IsNormal then
        local isShow = self._Control:CheckHardRedPoint(self._ChapterId)
        self.BtnDifficult:ShowReddot(isShow)
        if self.BtnDifficultHard02 then
            self.BtnDifficultHard02:ShowReddot(isShow)
        end
    else --困难关卡，标记红点已读
        self._Control:MarkHardChapterRedPoint(self._ChapterId)
    end
end

function XUiBlackRockChessChapter:InitBtnDifficulty(isNormal)
    if isNormal == nil then
        isNormal = true
    end
    self._IsHardOpen, self._TipDesc = self._Control:IsHardOpen(self._ChapterId)
    if not isNormal then
        if not self._IsHardOpen then
            isNormal = true
        end
    end
    self._IsNormal = isNormal
    self._Difficulty = self._IsNormal and XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL or XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD
    if not self._IsHardOpen then
        self.BtnDifficult:SetButtonState(CS.UiButtonState.Disable)
        if self.BtnDifficultHard02 then
            self.BtnDifficultHard02:SetButtonState(CS.UiButtonState.Disable)
        end
    end
end

function XUiBlackRockChessChapter:OnClickBtnDifficult()
    if not self._IsHardOpen then
        XUiManager.TipMsg(self._TipDesc)
        return
    end
    
    self:PlayAnimation("QieHuan")
    self._IsNormal = not self._IsNormal
    self._Control:UpdateDifficultCache(self._ChapterId, self._IsNormal)
    self._Difficulty = self._IsNormal and XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL or XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD
    self:UpdateView()
end

function XUiBlackRockChessChapter:UpdateProgress()
    if self._Difficulty ~= XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL then
        return
    end
    local curStar = 0
    local totalStar = 0
    local stageIds = self._Control:GetChapterStageIds(self._ChapterId, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD)
    for _, stageId in pairs(stageIds) do
        curStar = curStar + self._Control:GetStageStar(stageId)
        totalStar = totalStar + self._Control:GetStageMaxStar(stageId)
    end
    local str = string.format("%s/%s", curStar, totalStar)
    self.BtnDifficult:SetNameByGroup(0, str)
    self.BtnDifficultHard02:SetNameByGroup(0, str)
end

function XUiBlackRockChessChapter:OnCheckActivity(isClose)
    if isClose then
        self._Control:OnActivityEnd()
        return
    end
end

return XUiBlackRockChessChapter