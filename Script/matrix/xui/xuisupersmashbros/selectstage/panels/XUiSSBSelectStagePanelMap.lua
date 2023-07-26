--================
--
--================
local XUiSSBSelectStagePanelMap = XClass(nil, "XUiSSBSelectStagePanelMap")

function XUiSSBSelectStagePanelMap:Ctor(panel, rootUi)
    self.RootUi = rootUi
    self.Mode = self.RootUi.Mode
    XTool.InitUiObjectByUi(self, panel)
    self:InitPanel()
end

function XUiSSBSelectStagePanelMap:InitPanel()
    local sceneGroupId = self.Mode:GetMapLibraryId()
    local scenes = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Group2SceneDic, sceneGroupId)
    local script = require("XUi/XUiSuperSmashBros/SelectStage/Grids/XUiSSBPanelMapGrid")
    local btns = {}
    self.Grids = {}
    for index, scene in pairs(scenes or {}) do
        local prefab = CS.UnityEngine.Object.Instantiate(self.GridMap, self.Transform)
        local grid = script.New(prefab, scene, self.RootUi)
        table.insert(btns, grid:GetButton())
        self.Grids[index] = grid
    end
    self.MapButtonGroup:Init(btns, function(index) self:OnSelectGrid(index) end)
    self.MapButtonGroup:SelectIndex(1) --初始化后默认选择第一号
    self.GridMap.gameObject:SetActiveEx(false)
end

function XUiSSBSelectStagePanelMap:OnSelectGrid(index)
    for i, grid in pairs(self.Grids) do
        grid:OnSelect(i == index)
    end
end

function XUiSSBSelectStagePanelMap:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiSSBSelectStagePanelMap:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiSSBSelectStagePanelMap