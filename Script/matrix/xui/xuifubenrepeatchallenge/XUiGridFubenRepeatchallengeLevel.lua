local XUiGridFubenRepeatchallengeLevel = XClass(nil, "XUiGridFubenRepeatchallengeLevel")

function XUiGridFubenRepeatchallengeLevel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridFubenRepeatchallengeLevel:Refresh(level)
    local levelConfig = XFubenRepeatChallengeConfigs.GetLevelConfig(level)
    local buffId = levelConfig.BuffId
    local buffDes = #buffId > 0 and XDataCenter.FubenRepeatChallengeManager.GetBuffDes(levelConfig.BuffId[1]) or levelConfig.SimpleDesc
    for i = 1, 2 do
        self["TxtLevel" .. i].text = level
        self["TxtPoint" .. i].text = levelConfig.UpExp
        self["TxtBuff" .. i].text = buffDes 
    end

    local curLevel = XDataCenter.FubenRepeatChallengeManager.GetLevel()
    local isSelect = curLevel >= level
    self.PanelSelect.gameObject:SetActiveEx(isSelect)
    self.PanelNormal.gameObject:SetActiveEx(not isSelect)
end

return XUiGridFubenRepeatchallengeLevel