-- 兵法蓝图天赋树线控件
local XUiRpgTowerGrowPageNatureLine = XClass(nil, "XUiRpgTowerGrowPageNatureLine")

function XUiRpgTowerGrowPageNatureLine:Ctor(ui, prepos, pos)
    if not ui then XLog.Error(string.format("无法找到天赋树连线Ui：prePos：%d pos：%d", prepos, pos)) return end
    self.GrayLine = ui.transform:Find("Gray")   
end

function XUiRpgTowerGrowPageNatureLine:SetLineState(isShow)
    self.GrayLine.gameObject:SetActiveEx(not isShow)
end

return XUiRpgTowerGrowPageNatureLine