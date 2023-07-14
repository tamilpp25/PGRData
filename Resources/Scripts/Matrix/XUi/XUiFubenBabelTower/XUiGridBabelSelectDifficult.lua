local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridBabelSelectDifficult = XClass(nil, "XUiGridBabelSelectDifficult")

function XUiGridBabelSelectDifficult:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.BtnSelect.CallBack = function() self:OnClickBtnSelect() end
end

function XUiGridBabelSelectDifficult:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridBabelSelectDifficult:Refresh(stageId, teamId, config)
    self.StageId = stageId
    self.TeamId = teamId
    self.Difficult = config.Level

    self.TxtDiffcult.text = config.Name
    self.TxtAbility.text = CSXTextManagerGetText("BabelTowerSelectDifficultAbility", config.RecommendAblity)
    self.TxtPoint.text = CSXTextManagerGetText("BabelTowerSelectDifficultRatio", config.ScoreRatio)

    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(stageId, teamId)
    local isCur = selectDifficult == self.Difficult
    self.PanelCurSelect.gameObject:SetActiveEx(isCur)
    self.BtnSelect.gameObject:SetActiveEx(not isCur)
end

function XUiGridBabelSelectDifficult:OnClickBtnSelect()
    XDataCenter.FubenBabelTowerManager.UpdateTeamSelectDifficult(self.StageId, self.TeamId, self.Difficult)
    self.RootUi:Close()
end

return XUiGridBabelSelectDifficult