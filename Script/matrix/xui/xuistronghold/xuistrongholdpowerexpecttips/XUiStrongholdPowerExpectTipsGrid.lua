local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdPowerExpectTipsGrid = XClass(nil, "XUiStrongholdPowerExpectTipsGrid")

function XUiStrongholdPowerExpectTipsGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiStrongholdPowerExpectTipsGrid:Refresh(index, electricId)
    local levelId = XDataCenter.StrongholdManager.GetLevelId()
    local electric = index == 1 and XStrongholdConfigs.GetLevelInitElectricEnergy(levelId) or XStrongholdConfigs.GetElectricAdd(electricId - 1, levelId)
    local curDay = XDataCenter.StrongholdManager.GetCurDay()

    self.TxtDayNormal.text = CsXTextManagerGetText("StrongholdJournalDay", XTool.ConvertNumberString(index))
    self.TxtNumberNormal.text = electric
    self.TxtDayDisable.text = CsXTextManagerGetText("StrongholdJournalDay", XTool.ConvertNumberString(index))
    self.TxtNumberDisable.text = electric

    self.Normal.gameObject:SetActiveEx(curDay >= index)
    self.Disable.gameObject:SetActiveEx(curDay < index)

    self.ImgSelect.gameObject:SetActiveEx(curDay == index)
end

return XUiStrongholdPowerExpectTipsGrid