--兵法蓝图
local XUiRpgTowerRolePanel = XClass(nil, "XUiRpgTowerRolePanel")
local XUiRpgTowerCharaItem = require("XUi/XUiRpgTower/Common/XUiRpgTowerCharaItem")
function XUiRpgTowerRolePanel:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.GridRole.gameObject:SetActiveEx(false)
    self.RoleGrid = {}
end

function XUiRpgTowerRolePanel:RefreshRole()
    local team = XDataCenter.RpgTowerManager.GetTeam()
    self:ResetRoleGrid()
    local gridIndex = 0
    for _, rChara in pairs(team) do
        gridIndex = gridIndex + 1
        if not self.RoleGrid[gridIndex] then
            local ui = CS.UnityEngine.GameObject.Instantiate(self.GridRole)
            ui.transform:SetParent(self.Transform, false)
            self.RoleGrid[gridIndex] = XUiRpgTowerCharaItem.New(ui,
                XDataCenter.RpgTowerManager.CharaItemShowType.OnlyIconAndStar,
                self.OnClickRole)
        end
        self.RoleGrid[gridIndex]:RefreshData(rChara)
        self.RoleGrid[gridIndex].GameObject:SetActiveEx(true)
    end
end

function XUiRpgTowerRolePanel:ResetRoleGrid()
    for _, grid in pairs(self.RoleGrid) do
        grid.GameObject:SetActiveEx(false)
    end
end

function XUiRpgTowerRolePanel:OnClickRole()
    XLuaUiManager.Open("UiRpgTowerRoleList")
end
return XUiRpgTowerRolePanel