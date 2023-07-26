local CsXTextManagerGetText = CsXTextManagerGetText

local XUiGridRecord = XClass(nil, "XUiGridRecord")

function XUiGridRecord:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.OldPanel = XTool.InitUiObjectByUi({}, self.PanelOld)
    self.CurPanel = XTool.InitUiObjectByUi({}, self.PanelCur)
    self.FururePanel = XTool.InitUiObjectByUi({}, self.PanelFuture)
end

function XUiGridRecord:Refresh(record)
    self.Record = record

    local day = record.Day
    local curDay = XDataCenter.StrongholdManager.GetCurDay()
    if day < curDay then
        self.SelectPanel = self.OldPanel
        self.OldPanel.GameObject:SetActiveEx(true)
        self.CurPanel.GameObject:SetActiveEx(false)
        self.FururePanel.GameObject:SetActiveEx(false)
    elseif day == curDay then
        self.SelectPanel = self.CurPanel
        self.OldPanel.GameObject:SetActiveEx(false)
        self.CurPanel.GameObject:SetActiveEx(true)
        self.FururePanel.GameObject:SetActiveEx(false)
    else
        self.SelectPanel = self.FururePanel
        self.OldPanel.GameObject:SetActiveEx(false)
        self.CurPanel.GameObject:SetActiveEx(false)
        self.FururePanel.GameObject:SetActiveEx(true)
    end

    self:RefreshPanel()
end

function XUiGridRecord:RefreshPanel()
    local panel = self.SelectPanel
    local record = self.Record

    panel.TxtDay.text = CsXTextManagerGetText("StrongholdJournalDay", XTool.ConvertNumberString(record.Day))
    panel.TxtPeople.text = record.MinerCount
    panel.TxtMineral.text = record.MineralCount
    panel.TxtMineralTotal.text = record.TotalMineralCount
end

return XUiGridRecord