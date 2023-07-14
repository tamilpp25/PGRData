--================
--超级爬塔 爬塔关卡 结算界面 分数计算项控件
--================
local XUiStTsScoreItem = XClass(nil, "XUiStTsScoreItem")

function XUiStTsScoreItem:Ctor(uiGameObject, scoreRateId)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.RatioCfg = XSuperTowerConfigs.GetTierScoreRatioCfgById(scoreRateId)
end

function XUiStTsScoreItem:Refresh(count, score)
    self.Score = score
    self.TxtName.text = self.RatioCfg.Desc
    self.TxtCount.text = count
    self.TxtScore.text = "+" .. self.Score
end

function XUiStTsScoreItem:GetScore()
    return self.Score
end

function XUiStTsScoreItem:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiStTsScoreItem:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiStTsScoreItem