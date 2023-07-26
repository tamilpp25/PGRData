--队伍提升面板
local XUiRpgTowerLevelUp = XLuaUiManager.Register(XLuaUi, "UiRpgTowerLevelUp")

function XUiRpgTowerLevelUp:OnAwake()
    XTool.InitUiObject(self)
end

function XUiRpgTowerLevelUp:OnStart()
    self.LevelCfg = XDataCenter.RpgTowerManager.GetCurrentLevelCfg()
    self:InitPanels()
end

function XUiRpgTowerLevelUp:InitPanels()
    if not self.LevelCfg then return end
    self.TxtPreLevel.text = self.LevelCfg.PreLevel
    self.TxtCurrentLevel.text = self.LevelCfg.Level
    local allLayer = XRpgTowerConfig.GetAllTalentLayerCfgs()
    local newLayer = false
    for _, layer in pairs(allLayer) do
        if layer.NeedTeamLevel == self.LevelCfg.Level then
            newLayer = true
            break
        end
    end
    self.ObjNewLayerUnlockTips.gameObject:SetActiveEx(newLayer)
    self.ObjNoLayerUnlockTips.gameObject:SetActiveEx(not newLayer)
    self.TxtLevelUpCount.text = "+" .. self.LevelCfg.AddRoleLevel
    local talentId = XDataCenter.RpgTowerManager.GetTalentItemId()
    local itemCfg = XRpgTowerConfig.GetRItemConfigByRItemId(talentId)
    self.RImgTalentPointIcon:SetRawImage(itemCfg.Icon)
    self.TxtGetTalentPoint.text = self.LevelCfg.AddTalentPoint
    self.TxtSkillUpCount.text = "+" .. self.LevelCfg.AddSkillLv
    XUiHelper.RegisterClickEvent(self, self.BtnDarkBg, function()
            self:Close()
            XDataCenter.GuideManager.CheckGuideOpen()
            end)
end