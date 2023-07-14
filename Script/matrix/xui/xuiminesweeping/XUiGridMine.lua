local XUiGridMine = XClass(nil, "XUiGridMine")
local CSTextManagerGetText = CS.XTextManager.GetText
local Vector3 = CS.UnityEngine.Vector3
function XUiGridMine:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.Win.gameObject:SetActiveEx(false)
    self.IsOpendShow = false
end

function XUiGridMine:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
end

function XUiGridMine:OnBtnClick()
    local xIndex, yIndex = self.Data:GetPosIndex()
    XDataCenter.MineSweepingManager.MineSweepingOpenRequest(self.ChapterId, self.StageId, xIndex, yIndex, function (rewardGoodsList)
            local chapterEntity = XDataCenter.MineSweepingManager.GetChapterByChapterId(self.ChapterId)
            local stageEntity = chapterEntity:GetStageEntityById(self.StageId)
            if stageEntity:IsFinish() then
                if chapterEntity:IsFinish() then
                    self.Root:SetSpecialState(XMineSweepingConfigs.SpecialState.ChapterWin, self.ChapterId, self.StageId)
                else
                    self.Root:SetSpecialState(XMineSweepingConfigs.SpecialState.StageWin, self.ChapterId, self.StageId)
                end
                self.Root:ShowStageWinEffect()
            end
            if stageEntity:IsFailed() then
                self.Root:SetSpecialState(XMineSweepingConfigs.SpecialState.StageLose, self.ChapterId, self.StageId)
            end
            self.Root:SetFinishReward(rewardGoodsList)
            self.IsOpendShow = true
    end)
end

function XUiGridMine:UpdateGrid(data, chapterId, stageId)
    self.Data = data
    self.ChapterId = chapterId
    self.StageId = stageId
    if data then
        self:ShowPanel()
        self:UpdatePanelNumber()
        self:UpdatePanelMine()
    end
end

function XUiGridMine:ShowPanel()
    self.Number.gameObject:SetActiveEx(self.Data:IsSafe())
    self.NorNumber.gameObject:SetActiveEx(self.Data:IsSafe())
    self.Mine.gameObject:SetActiveEx(self.Data:IsMine())
    self.BtnClick.gameObject:SetActiveEx(self.Data:IsUnknown())
end

function XUiGridMine:UpdatePanelNumber()
    local num = self.Data:GetRoundMineNumber()
    self.Number:GetObject("Text").text = num
    self.Number.gameObject:SetActiveEx(num > 0)
    self.NorNumber.gameObject:SetActiveEx(num <= 0)
end

function XUiGridMine:UpdatePanelMine()
    local chapterEntity = XDataCenter.MineSweepingManager.GetChapterByChapterId(self.ChapterId)
    local icon = chapterEntity:GetMineIcon()
    self.Mine:GetObject("Image"):SetSprite(icon)
    self.Mine:GetObject("MineEffect").gameObject:SetActiveEx(false)
    if self.Data:IsMine() and self.IsOpendShow then
        self.Mine:GetObject("MineEffect"):LoadUiEffect(chapterEntity:GetMineEffect())
        self.Mine:GetObject("MineEffect").gameObject:SetActiveEx(true)
        self.IsOpendShow = false
    end
end

function XUiGridMine:ShowEffect()
    local chapterEntity = XDataCenter.MineSweepingManager.GetChapterByChapterId(self.ChapterId)
    if self.Data:IsMine() or self.Data:IsUnknown() then
        self.Win:GetObject("WinEffect"):LoadUiEffect(chapterEntity:GetWinGridEffect())
        self.Win.gameObject:SetActiveEx(true)
    end
end

function XUiGridMine:ResetEffect()
    self.Win.gameObject:SetActiveEx(false)
end

return XUiGridMine