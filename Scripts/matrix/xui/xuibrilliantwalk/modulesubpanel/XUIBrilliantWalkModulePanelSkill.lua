--模块界面XUIBrilliantWalkModule 的子界面PanelModule 选择模块技能界面
local XUIBrilliantWalkModulePanelSkill = XClass(nil, "XUIBrilliantWalkModulePanelSkill")
local XUIBrilliantWalkStageSkillPanelSkillGrid = require("XUi/XUiBrilliantWalk/XUIGrid/XUIBrilliantWalkStageSkillPanelSkillGrid")--技能grid


function XUIBrilliantWalkModulePanelSkill:Ctor(perfabObject, rootUi)
    self.GameObject = perfabObject.gameObject
    self.Transform = perfabObject.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    --技能Grid
    self.SkillGrid = {}
    local index = 1
    while self["PanelDependSkill"..index] do
        table.insert(self.SkillGrid,XUIBrilliantWalkStageSkillPanelSkillGrid.New(self["PanelDependSkill"..index],self))
        index = index + 1
    end
    --启用模块按钮
    self.BtnSelect.CallBack = function()
        self:OnBtnActiveModule()
    end
    --取消启用模块按钮
    self.BtnDisactive.CallBack = function()
        self:OnBtnDisactiveModule()
    end
end


function XUIBrilliantWalkModulePanelSkill:UpdateView(trenchId, moduleId)
    self.TrenchId = trenchId
    self.ModuleId = moduleId
    --能量点
    self.TxtPoint.text = XDataCenter.BrilliantWalkManager.GetCurPluginEnergy() .. "/" .. XDataCenter.BrilliantWalkManager.GetPluginMaxEnergy()
    --模块名字
    self.TxtModuleName.text = XBrilliantWalkConfigs.GetBuildPluginName(moduleId)
    --技能grid
    local skillIds = XBrilliantWalkConfigs.ListSkillListInModule[self.ModuleId]
    for index,grid in pairs(self.SkillGrid) do
        grid:UpdateView(self.TrenchId,skillIds[index])
    end
    local ModuleEnable =  XDataCenter.BrilliantWalkManager.CheckPluginEquipedInTrench(self.TrenchId,self.ModuleId)
    self.BtnSelect.gameObject:SetActiveEx(not ModuleEnable)
    self.BtnDisactive.gameObject:SetActiveEx(ModuleEnable)
end

--点击启用按钮
function XUIBrilliantWalkModulePanelSkill:OnBtnActiveModule()
    local equipedModule = XDataCenter.BrilliantWalkManager.CheckTrenchEquipModule(self.TrenchId)
    if equipedModule then
        local equipedName = XBrilliantWalkConfigs.GetBuildPluginName(equipedModule) 
        local trenchName = XBrilliantWalkConfigs.GetTrenchName(self.TrenchId)
        XUiManager.DialogTip(
            CS.XTextManager.GetText("TipTitle"), 
            CS.XTextManager.GetText("BrilliantWalkModuleActiveWarning",equipedName,trenchName),
            XUiManager.DialogType.Normal,
            nil,
            function()
                self.RootUi:OnBtnActiveModule(self.ModuleId)
                self:UpdateView(self.TrenchId,self.ModuleId)
            end
        )
    else
        self.RootUi:OnBtnActiveModule(self.ModuleId)
        self:UpdateView(self.TrenchId,self.ModuleId)
    end
end
--点击取消启用按钮
function XUIBrilliantWalkModulePanelSkill:OnBtnDisactiveModule()
    if XDataCenter.BrilliantWalkManager.CheckModuleActiveSkill(self.TrenchId,self.ModuleId) then
        XUiManager.DialogTip(
            CS.XTextManager.GetText("TipTitle"), 
            CS.XTextManager.GetText("BrilliantWalkModuleDisactiveWarning"),
            XUiManager.DialogType.Normal,
            nil,
            function()
                self.RootUi:OnBtnDisactiveModule(self.ModuleId)
                self:UpdateView(self.TrenchId,self.ModuleId)
            end
        )
    else
        self.RootUi:OnBtnDisactiveModule(self.ModuleId)
        self:UpdateView(self.TrenchId,self.ModuleId)
    end
end
--点击激活按钮(技能Grid)
function XUIBrilliantWalkModulePanelSkill:OnBtnActiveSkill(skillId)
    --XLog.Log("CheckPluginEquipedInTrench T:"..self.TrenchId .. "  M:"..self.ModuleId)
    if XDataCenter.BrilliantWalkManager.CheckPluginEquipedInTrench(self.TrenchId,self.ModuleId) then
        self.RootUi:OnBtnActiveSkill(skillId)
    else
        XUiManager.DialogTip(
            CS.XTextManager.GetText("TipTitle"), 
            CS.XTextManager.GetText("BrilliantWalkStageModuleActiveTipContent"),
            XUiManager.DialogType.Normal, 
            nil, 
            function()
                if self.RootUi:OnBtnActiveModule(self.ModuleId) then
                    self.RootUi:OnBtnActiveSkill(skillId)
                end
            end
        )
    end
end
--点击取消激活按钮(技能Grid)
function XUIBrilliantWalkModulePanelSkill:OnBtnDisactiveSkill(skillId)
    self.RootUi:OnBtnDisactiveSkill(skillId)
    self:UpdateView(self.TrenchId,self.ModuleId)
end

return XUIBrilliantWalkModulePanelSkill