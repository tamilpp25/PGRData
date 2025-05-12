local tableInsert = table.insert

local XUiSlotMachineRulesItem = require("XUi/XUiSlotMachine/XUiSlotMachineRulesItem")
---@class XUiSlotMachineRulesPanel
local XUiSlotMachineRulesPanel = XClass(nil, "XUiSlotMachineRulesPanel")

function XUiSlotMachineRulesPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiSlotMachineRulesPanel:Init()
    self.TextPanelPool = {}
end

function XUiSlotMachineRulesPanel:Refresh(machineId)
    self.CurMachineEntity = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityById(machineId)
    local rulesIds = self.CurMachineEntity:GetRulesIds()
    local rulesDataList = {}
    for _, rulesId in ipairs(rulesIds) do
        local rulesData = XSlotMachineConfigs.GetSlotMachinesRulesTemplateById(rulesId)
        local data = {
            Title = rulesData.Title,
            Desc = rulesData.Desc,
        }
        tableInsert(rulesDataList, data)
    end

    local onCreateCb = function (item, data)
        item:SetActiveEx(true)
        item:OnCreate(data)
    end

    XUiHelper.CreateTemplates(self.RootUi, self.TextPanelPool, rulesDataList, XUiSlotMachineRulesItem.New, self.PanelTxt, self.PanelContent, onCreateCb)
end

return XUiSlotMachineRulesPanel