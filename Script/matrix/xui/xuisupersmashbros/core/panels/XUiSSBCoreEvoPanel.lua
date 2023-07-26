
local XUiSSBCoreEvoPanel = XClass(nil, "XUiSSBCoreEvoPanel")

function XUiSSBCoreEvoPanel:Ctor(uiPrefab, core)
    self.Core = core
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitEvolutionStarPanel()
    self:InitEvolutionEffectPanel()
    self:InitEvolutionCostPanel()
    self.BtnEvoConfirm.CallBack = function() self:OnClickConfirm() end
end

function XUiSSBCoreEvoPanel:InitEvolutionStarPanel()
    self.StarPanel = {}
    XTool.InitUiObjectByUi(self.StarPanel, self.SequenceStars)
end

function XUiSSBCoreEvoPanel:InitEvolutionEffectPanel()
    self.EffectPanel = {}
    XTool.InitUiObjectByUi(self.EffectPanel, self.SequenceTexts)
end

function XUiSSBCoreEvoPanel:InitEvolutionCostPanel()
    self.CostPanel = {}
    XTool.InitUiObjectByUi(self.CostPanel, self.PanelCost)
    XUiHelper.RegisterClickEvent(self, self.CostPanel.RImgIcon, handler(self, self.OnClickCostImage))   
end

function XUiSSBCoreEvoPanel:OnClickCostImage()
    XLuaUiManager.Open("UiTip", self.Core:GetSkillCostItemId())
end

function XUiSSBCoreEvoPanel:Refresh(core, isCoreLevelUp)
    self.Core = core or self.Core
    self:RefreshStar(self.Core:GetStar(), isCoreLevelUp)
    self:RefreshText(self.Core:GetStar())
    self:RefreshCost()
    self.BtnEvoConfirm:SetButtonState(self.Core:CheckSkillIsMax() and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiSSBCoreEvoPanel:RefreshStar(star, isCoreLevelUp)
    if not star or star < 1 then return end
    for index = 1, 5 do
        local nor = self.StarPanel["ImgNor" .. index]
        local dis = self.StarPanel["ImgDis" .. index]
        if nor then
            nor.gameObject:SetActiveEx(index <= star)
            nor.transform:Find("PanelEffect").gameObject:SetActiveEx(isCoreLevelUp and index == star) -- 刷新默认隐藏特效节点， 升星时再打开特效
        end
        if dis then
            dis.gameObject:SetActiveEx(index > star)
        end
    end
end

function XUiSSBCoreEvoPanel:RefreshText(star)
    if not star then return end
    for index = 1, 5 do
        local nor = self.EffectPanel["TxtExplainNor" .. index]
        local dis = self.EffectPanel["TxtExplainDis" .. index]
        local cfg = self.Core:GetSkillCfgByStar(index)
        local description = string.gsub(cfg.UpgradeDescription, '"', '')
        description = string.gsub(description, '\\n', '\n')
        if nor then
            nor.gameObject:SetActiveEx(index <= star)
            if cfg then
                nor.text = description
            end
        end
        if dis then
            dis.gameObject:SetActiveEx(index > star)
            if dis and cfg then
                dis.text = description
            end
        end
    end
end

function XUiSSBCoreEvoPanel:RefreshCost()
    if not self.Core or self.Core:CheckSkillIsMax() then
        self.CostPanel.GameObject:SetActiveEx(false)
        return
    end
    self.CostPanel.GameObject:SetActiveEx(true)
    self.CostPanel.RImgIcon:SetRawImage(self.Core:GetSkillCostItemIcon())
    local costItemId = self.Core:GetSkillCostItemId()
    self.CostPanel.TxtNumStr.text = XUiHelper.GetText("SSBMainPointGetText", self.Core:GetSkillCostCount(), XDataCenter.ItemManager.GetCount(costItemId))
end

function XUiSSBCoreEvoPanel:OnClickConfirm()
    if not self.Core or self.Core:CheckSkillIsMax() then
        return
    end
    XDataCenter.SuperSmashBrosManager.CoreLevelUp(self.Core)
end

return XUiSSBCoreEvoPanel