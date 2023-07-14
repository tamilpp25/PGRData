local CSXTextManagerGetText = CS.XTextManager.GetText
local CSFormatTime = function(timestamp)
    return CS.XDateUtil.GetLocalDateTime(timestamp):ToString("yyyy-MM-dd HH:mm:ss")
end

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
        if isPrix then
            self.GridLogHigh.gameObject:SetActiveEx(true)
            self.GridLogLow.gameObject:SetActiveEx(false)
            self.TxtNameHigh.text = CSXTextManagerGetText("SlotMachineLogNameText", XSlotMachineConfigs.GetIconNameById(iconList[1]), XSlotMachineConfigs.GetIconNameById(iconList[2]), XSlotMachineConfigs.GetIconNameById(iconList[3]))
            self.TxtScoreHigh.text = CSXTextManagerGetText("SlotMachineLogScoreText", data.Score)
            self.TxtTimeHigh.text = CSFormatTime(data.Timestamp)
        else
            self.GridLogHigh.gameObject:SetActiveEx(false)
            self.GridLogLow.gameObject:SetActiveEx(true)
            self.TxtNameLow.text = CSXTextManagerGetText("SlotMachineLogNameText", XSlotMachineConfigs.GetIconNameById(iconList[1]), XSlotMachineConfigs.GetIconNameById(iconList[2]), XSlotMachineConfigs.GetIconNameById(iconList[3]))
            self.TxtScoreLow.text = CSXTextManagerGetText("SlotMachineLogScoreText", data.Score)
            self.TxtTimeLow.text = CSFormatTime(data.Timestamp)
        end
    end
end

function XUiSlotMachineRulesResearchLogItem:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

return XUiSlotMachineRulesResearchLogItem