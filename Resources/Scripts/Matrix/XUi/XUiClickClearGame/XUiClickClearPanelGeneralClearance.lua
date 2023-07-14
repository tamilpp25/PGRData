local textManager = CS.XTextManager

local XUiClickClearPanelGeneralClearance = XClass(nil, "XUiClickClearPanelGeneralClearance")

function XUiClickClearPanelGeneralClearance:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiClickClearPanelGeneralClearance:Show()
    local gameInfo = XDataCenter.XClickClearGameManager.GetGameInfo()
    if gameInfo.CurGameState == XDataCenter.XClickClearGameManager.GameState.Account then
        self.TextPassTime.text = string.format( "%.2f", gameInfo.UseTime)
        self.ItemNewRecord.gameObject:SetActiveEx(gameInfo.IsNewRecord)
        self.GameObject:SetActiveEx(true)
    end
end

function XUiClickClearPanelGeneralClearance:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiClickClearPanelGeneralClearance