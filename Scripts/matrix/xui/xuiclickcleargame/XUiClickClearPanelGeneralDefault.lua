local textManager = CS.XTextManager

local XUiClickClearPanelGeneralDefault = XClass(nil, "XUiClickClearPanelGeneralDefault")

function XUiClickClearPanelGeneralDefault:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiClickClearPanelGeneralDefault:Show()
    local curDifficulty = XDataCenter.XClickClearGameManager.GetCurGameDifficulty()
    local isPass, passRecord = XDataCenter.XClickClearGameManager.CheckPass(curDifficulty)
    if isPass then
        self.PassTimePanel.gameObject:SetActiveEx(true)
        self.TextNotPass.gameObject:SetActiveEx(false)
        self.TextPassTime.text = string.format( "%.2f", passRecord)
    else
        self.PassTimePanel.gameObject:SetActiveEx(false)
        self.TextNotPass.gameObject:SetActiveEx(true)
    end

    self.GameObject:SetActiveEx(true)
end

function XUiClickClearPanelGeneralDefault:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiClickClearPanelGeneralDefault