local XUiPanelEasterEgg = XClass(nil, "XUiPanelEasterEgg")

function XUiPanelEasterEgg:Ctor(ui)
    self.GameObject= ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    self:LoadLocalData()
end

---@param egg XDiceGameEasterEgg
function XUiPanelEasterEgg:Open(egg)
    if egg:HasTriggered() then
        return false
    end

    egg:SetTriggered(true)
    --self.RImgIcon:SetRawImage(egg:GetIcon())
    self.TxtTitleZh.text = egg:GetName()
    self.TxtContent.text = egg:GetText()
    self.GameObject:SetActiveEx(true)
    return true
end

function XUiPanelEasterEgg:Close()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelEasterEgg:LoadLocalData()
    local triggeredListData = XSaveTool.GetData(self:GetLocalDataKey())
    if triggeredListData then
        local triggeredList = string.Split(triggeredListData, "|")
        local eggEntityDict = XDataCenter.DiceGameManager.GetEasterEggEntityDict()
        for i = 1, #triggeredList do
            if triggeredList[i] ~= "" then
                eggEntityDict[tonumber(triggeredList[i])]:SetTriggered(true)
            end
        end
    end
    XLog.Debug("DiceGame.PanelEasterEgg.LoadLocalData()")
end

function XUiPanelEasterEgg:SaveLocalData()
    local triggeredListData = ""
    local eggEntityDict = XDataCenter.DiceGameManager.GetEasterEggEntityDict()
    for i, v in pairs(eggEntityDict) do
        if v:HasTriggered() then
            triggeredListData = triggeredListData .. tostring(i) .. "|"
        end
    end
    XSaveTool.SaveData(self:GetLocalDataKey(), triggeredListData)
end

function XUiPanelEasterEgg:RemoveLocalData()
    XSaveTool.RemoveData(XUiPanelEasterEgg.GetLocalDataKey())
end

function XUiPanelEasterEgg.GetLocalDataKey()
    return string.format("%sDiceGame%d_EasterEggTriggeredList", XPlayer.Id, XDataCenter.DiceGameManager.GetActivityId())
end

return XUiPanelEasterEgg
