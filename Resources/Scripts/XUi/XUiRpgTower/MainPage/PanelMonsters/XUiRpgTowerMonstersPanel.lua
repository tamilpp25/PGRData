-- 兵法蓝图主页面怪物面板控件
local XUiRpgTowerMonstersPanel = XClass(nil, "XUiRpgTowerMonstersPanel")
local XUiRpgTowerMonsterGrid = require("XUi/XUiRpgTower/MainPage/PanelMonsters/XUiRpgTowerMonsterGrid")
function XUiRpgTowerMonstersPanel:Ctor(ui, uiModelRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MonsterGrids = {}
    XTool.InitUiObject(self)
    self:InitMonstersModel(uiModelRoot)
    self:InitPanel()
end
--================
--初始化怪物模型控件
--================
function XUiRpgTowerMonstersPanel:InitMonstersModel(uiModelRoot)
    self.MonsterModels = {
        [1] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase1"), self.Name, nil, true, nil, true, true),
        [2] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase2"), self.Name, nil, true, nil, true, true),
        [3] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase3"), self.Name, nil, true, nil, true, true),
    }
end
--================
--初始化面板
--================
function XUiRpgTowerMonstersPanel:InitPanel()
    self.GridMonster.gameObject:SetActiveEx(false)
    for i = 1, 3 do
        local roomCharCase = self.MonsterModels[i]
        if roomCharCase then
            local prefab = CS.UnityEngine.Object.Instantiate(self.GridMonster.gameObject)
            prefab.transform:SetParent(self["RoomMonsterCase" .. i], false)
            prefab.gameObject:SetActiveEx(true)
            self.MonsterGrids[i] = XUiRpgTowerMonsterGrid.New(prefab, self.MonsterModels[i])
            self.MonsterGrids[i]:RefreshData(nil)
        end
    end
end
--================
--刷新怪物模型
--================
function XUiRpgTowerMonstersPanel:RefreshMonsters(rStage)
    local monsterIds = rStage:GetMonsters()
    for i = 1, 3 do
        local isBoss = XRpgTowerConfig.GetMonsterIsBossByRMonsterId(monsterIds[i])
        self.MonsterGrids[i]:RefreshData(monsterIds[i], isBoss)
    end
end

return XUiRpgTowerMonstersPanel