local textManager = CS.XTextManager

local XUiClickClearPanelGameTask = XClass(nil, "XUiClickClearPanelGameTask")

function XUiClickClearPanelGameTask:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiClickClearPanelGameTask:Show()
    self.GameObject:SetActiveEx(true)
    self:Refresh()
end

function XUiClickClearPanelGameTask:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiClickClearPanelGameTask:HeadDataHasChanged()
    self:RefreshData()
end

function XUiClickClearPanelGameTask:Refresh()
    local gameInfo = XDataCenter.XClickClearGameManager.GetGameInfo()

    local normalTaskDesc = gameInfo.HeadNormalDesc
    local specialTaskDesc = gameInfo.HeadSpecialDesc

    self.TextNormalDesc.text = normalTaskDesc
    self.TextSpecialDesc.text = specialTaskDesc
    
    self:RefreshData()
end

function XUiClickClearPanelGameTask:RefreshData()
    local gameInfo = XDataCenter.XClickClearGameManager.GetGameInfo()
    local normalHeadCount = gameInfo.HeadNormalCurCount
    local normalHeadTarCount = gameInfo.HeadNormalTargetCount
    local specialHeadCount = gameInfo.HeadSpecialCurCount
    local specialHeadTarCount = gameInfo.HeadSpecialTargetCount

    local normalProcess = normalHeadCount/normalHeadTarCount
    local specialProcess = specialHeadCount/specialHeadTarCount

    self.SliderNormalProcess.fillAmount = normalProcess
    self.SliderSpecialProcess.fillAmount = specialProcess
    self.TextNormalProcess.text = textManager.GetText("ClickClearGameTaskProcess", normalHeadCount, normalHeadTarCount)
    self.TextSpecialProcess.text = textManager.GetText("ClickClearGameTaskProcess", specialHeadCount, specialHeadTarCount)
end

return XUiClickClearPanelGameTask