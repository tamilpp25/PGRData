-- 兵法蓝图角色队伍等级天赋面板控件
local XUiRpgTowerRoleListTalentLevel = XClass(nil, "XUiRpgTowerRoleListTalentLevel")
local TalentScript = require("XUi/XUiRpgTower/CharacterPage/GrowPage/XUiRpgTowerGrowPageNatureItem")
function XUiRpgTowerRoleListTalentLevel:Ctor(uiGameObject, rootUi, cfg)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.RootUi = rootUi
    self.LayerCfg = cfg
    self:InitPanel()
end

function XUiRpgTowerRoleListTalentLevel:InitPanel()
    self.PanelLock.gameObject:SetActiveEx(false)
    self.Talents = {}
    local talentPrefabPath = XUiConfigs.GetComponentUrl("RpgTowerTalentComponent")
    local i = 1
    while(self["PanelSkill" .. i] ~= nil) do
        local uiGameObject = self["PanelSkill" .. i].transform:LoadPrefab(talentPrefabPath)
        table.insert(self.Talents, TalentScript.New(uiGameObject))
        self.Talents[i]:Hide()
        i = i + 1
    end
end

function XUiRpgTowerRoleListTalentLevel:RefreshData(rChara, type)
    self.TxtLevel.text = self.LayerCfg.NeedTeamLevel
    local currentLevel = XDataCenter.RpgTowerManager.GetCurrentLevel()
    local needLevel = self.LayerCfg and self.LayerCfg.NeedTeamLevel or 1
    if self.LayerCfg and currentLevel >= needLevel then
        self.PanelLock.gameObject:SetActiveEx(false)
    else
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = CS.XTextManager.GetText("RpgTowerNeedTeamLevel", needLevel)
    end
    local talents = rChara:GetTalentsByLayer(self.LayerCfg.LayerId, type)
    for index, talent in pairs(self.Talents) do
        if talents and talents[index] then
            self["PanelSkill" .. index].gameObject:SetActiveEx(true)
            talent:Show()
            talent:RefreshData(talents[index])
        else
            self["PanelSkill" .. index].gameObject:SetActiveEx(false)
            talent:Hide()
        end
    end
end

return XUiRpgTowerRoleListTalentLevel