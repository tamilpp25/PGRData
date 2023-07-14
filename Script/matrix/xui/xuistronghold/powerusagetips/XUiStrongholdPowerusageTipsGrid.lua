local XUiStrongholdPowerusageTipsGrid = XClass(nil, "XUiStrongholdPowerusageTipsGrid")

function XUiStrongholdPowerusageTipsGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiStrongholdPowerusageTipsGrid:Refresh(chapterId, curSelectChapterId)
    local name = XStrongholdConfigs.GetChapterName(chapterId)
    self.TxtNorName.text = name
    self.TxtPreName.text = name

    local suggestElectric = XStrongholdConfigs.GetChapterSuggestElectric(chapterId, XDataCenter.StrongholdManager.GetLevelId())
    local extraElectricEnergy = XDataCenter.StrongholdManager.GetExtraElectricEnergy()
    local suggestElectricDesc = XTool.IsNumberValid(suggestElectric) and XUiHelper.GetText("StrongholdSuggestElectricDesc", suggestElectric, extraElectricEnergy) or ""
    self.TxtNorSuggestElectric.text = suggestElectricDesc
    self.TxtPreSuggestElectric.text = suggestElectricDesc

    local maxElectricUse = XStrongholdConfigs.GetChapterMaxElectricUse(chapterId)
    self.TxtMineral.text = XTool.IsNumberValid(maxElectricUse) and maxElectricUse or ""

    local isCurChapter = chapterId == curSelectChapterId
    self.Normal.gameObject:SetActiveEx(not isCurChapter)
    self.Press.gameObject:SetActiveEx(isCurChapter)
end

return XUiStrongholdPowerusageTipsGrid