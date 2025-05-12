---@class XUiSlotMachineRulesResearchLogItem
local XUiSlotMachineRulesResearchLogItem = XClass(nil, "XUiSlotMachineRulesResearchLogItem")

function XUiSlotMachineRulesResearchLogItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiSlotMachineRulesResearchLogItem:OnCreate(data)
    if data then
        local iconList = data.IconList
        local isPrix = XDataCenter.SlotMachineManager.CheckIconListIsPrix(iconList)
        local nameText1 = XTool.IsNumberValid(iconList[1]) and XSlotMachineConfigs.GetIconNameById(iconList[1]) or ""
        local nameText2 = XTool.IsNumberValid(iconList[2]) and XSlotMachineConfigs.GetIconNameById(iconList[2]) or ""
        local nameText3 = XTool.IsNumberValid(iconList[3]) and XSlotMachineConfigs.GetIconNameById(iconList[3]) or ""
        local nameText = XUiHelper.GetText("SlotMachineLogNameText", nameText1, nameText2, nameText3)
        local scoreText = XUiHelper.GetText("SlotMachineLogScoreText", data.Score)
        local timeText = XTime.TimestampToLocalDateTimeString(data.Timestamp)
        if isPrix then
            self.GridLogHigh.gameObject:SetActiveEx(true)
            self.GridLogLow.gameObject:SetActiveEx(false)
            self.TxtNameHigh.text = nameText
            self.TxtScoreHigh.text = scoreText
            self.TxtTimeHigh.text = XUiHelper.ReplaceUnicodeSpace(timeText)
        else
            self.GridLogHigh.gameObject:SetActiveEx(false)
            self.GridLogLow.gameObject:SetActiveEx(true)
            self.TxtNameLow.text = nameText
            self.TxtScoreLow.text = scoreText
            self.TxtTimeLow.text = XUiHelper.ReplaceUnicodeSpace(timeText)
        end
    end
end

function XUiSlotMachineRulesResearchLogItem:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

return XUiSlotMachineRulesResearchLogItem