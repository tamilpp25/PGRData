--================
--
--================
local XUiSSBSelectStagePanelEnviro = XClass(nil, "XUiSSBSelectStagePanelEnviro")

function XUiSSBSelectStagePanelEnviro:Ctor(panel, rootUi)
    self.RootUi = rootUi
    self.Mode = self.RootUi.Mode
    XTool.InitUiObjectByUi(self, panel)
    self:InitPanel()
end

function XUiSSBSelectStagePanelEnviro:InitPanel()
    local environmentId = self.Mode:GetEnvLibraryId()
    local environments = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Group2EnvironmentDic, environmentId)
    local script = require("XUi/XUiSuperSmashBros/SelectStage/Grids/XUiSSBPanelEnviroGrid")
    local btns = {}
    self.Grids = {}
    for index, environ in pairs(environments or {}) do
        local prefab = CS.UnityEngine.Object.Instantiate(self.GridEnvironment, self.EnvirGridsContent)
        local grid = script.New(prefab, environ, self.RootUi)
        table.insert(btns, grid:GetButton())
        self.Grids[index] = grid
    end
    self.EnvirButtonGroup.CurSelectId = -1
    self.EnvirButtonGroup.CanDisSelect = true --环境可以不选，这里要允许反选
    self.EnvirButtonGroup:Init(btns, function(index) self:OnSelectGrid(index) end)
    self.GridEnvironment.gameObject:SetActiveEx(false)
end

function XUiSSBSelectStagePanelEnviro:OnSelectGrid(index)
    for i, grid in pairs(self.Grids) do
        grid:OnSelect(i == index)
    end
    if self.CurIndex == index then
        self.RootUi:SetSelectEnvironment(nil)
        self.CurIndex = -1
    else
        self.RootUi:SetSelectEnvironment(self.Grids[index]:GetEnvironment())
        self.CurIndex = index
    end
end

function XUiSSBSelectStagePanelEnviro:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiSSBSelectStagePanelEnviro:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiSSBSelectStagePanelEnviro