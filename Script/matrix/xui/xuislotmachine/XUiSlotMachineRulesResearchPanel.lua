local tableInsert = table.insert

local XUiSlotMachineRulesResearchLogItem = require("XUi/XUiSlotMachine/XUiSlotMachineRulesResearchLogItem")
---@class XUiSlotMachineRulesResearchPanel
local XUiSlotMachineRulesResearchPanel = XClass(nil, "XUiSlotMachineRulesResearchPanel")

function XUiSlotMachineRulesResearchPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiSlotMachineRulesResearchPanel:Init()
    self.LogGridPool = {}
end

function XUiSlotMachineRulesResearchPanel:Refresh(machineId)
    self.CurMachineEntity = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityById(machineId)
    self:RefreshLogPanel()
end

function XUiSlotMachineRulesResearchPanel:RefreshLogPanel()
    if self.CurMachineEntity then
        local researchLogs = self.CurMachineEntity:GetSlotMachineRecords()
        local logDataList = {}
        for _, logData in ipairs(researchLogs) do
            local data = {
                IconList = logData.IconList,
                Timestamp = logData.Timestamp,
                Score = logData.Score,
            }
            tableInsert(logDataList, data)
        end

        local onCreateCb = function(item, data)
            item:SetActiveEx(true)
            item:OnCreate(data)
        end

        XUiHelper.CreateTemplates(self.RootUi, self.LogGridPool, logDataList, XUiSlotMachineRulesResearchLogItem.New, self.GridLog, self.PanelContent, onCreateCb)
    end
end

return XUiSlotMachineRulesResearchPanel