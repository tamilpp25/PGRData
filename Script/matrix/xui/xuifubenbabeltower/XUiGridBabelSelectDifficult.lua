local CSXTextManagerGetText = CS.XTextManager.GetText

---@class XUiGridBabelSelectDifficult
local XUiGridBabelSelectDifficult = XClass(nil, "XUiGridBabelSelectDifficult")

function XUiGridBabelSelectDifficult:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.BtnSelect.CallBack = function() self:OnClickBtnSelect() end
end

---@param rootUi XUiBabelTowerSelectDiffcult
function XUiGridBabelSelectDifficult:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridBabelSelectDifficult:Refresh(stageId, teamId, config)
    self.StageId = stageId
    self.TeamId = teamId
    self.Difficult = config.Level

    self.TxtDiffcult.text = config.Name
    self.TxtAbility.text = CSXTextManagerGetText("BabelTowerSelectDifficultAbility", config.RecommendAblity)
    self.TxtPoint.text = CSXTextManagerGetText("BabelTowerSelectDifficultRatio", getRoundingValue(config.ScoreRatio + 0.0001, 1))

    --当前章节曾经最高达到的层数
    local overMaxLevel = XDataCenter.FubenBabelTowerManager.GetStageMaxScore(stageId)
    local collectionInfo = XDataCenter.FubenBabelTowerManager.GetBabelTowerInfo(XFubenBabelTowerConfigs.COLLECTION_ITEM_QUALITY, nil)
    if overMaxLevel >= config.UnlockCondLevel or (not XTool.IsTableEmpty(collectionInfo) and self.Difficult <= collectionInfo.Level) then
        -- 满足解锁条件
        self.PanelDifficulty.gameObject:SetActiveEx(false)
        local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(stageId, teamId)
        local isCur = selectDifficult == self.Difficult
        self.PanelCurSelect.gameObject:SetActiveEx(isCur)
        self.BtnSelect.gameObject:SetActiveEx(not isCur)
    else
        -- 不满足解锁条件
        self.PanelDifficulty.gameObject:SetActiveEx(true)
        local desc = CSXTextManagerGetText("BabelTowerStageUnlockDifficulty", config.UnlockCondLevel)
        self.PanelDifficultyText.text = XUiHelper.ConvertLineBreakSymbol(desc)
        self.PanelCurSelect.gameObject:SetActiveEx(false)
        self.BtnSelect.gameObject:SetActiveEx(false)
    end
end

function XUiGridBabelSelectDifficult:OnClickBtnSelect()
    XDataCenter.FubenBabelTowerManager.UpdateTeamSelectDifficult(self.StageId, self.TeamId, self.Difficult)
    self.RootUi:Close()
end

return XUiGridBabelSelectDifficult
