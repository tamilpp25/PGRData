--模块界面XUIBrilliantWalkModule 的子界面PanelModule 选择模块界面
local XUIBrilliantWalkModulePanelModule = XClass(nil, "XUIBrilliantWalkModulePanelModule")



function XUIBrilliantWalkModulePanelModule:Ctor(perfabObject, rootUi)
    self.GameObject = perfabObject.gameObject
    self.Transform = perfabObject.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.PanelModule1.CallBack = function()
        self:OnBtnModuleClick(1)
    end
    self.PanelModule2.CallBack = function()
        self:OnBtnModuleClick(2)
    end
end

function XUIBrilliantWalkModulePanelModule:UpdateView(trenchId)
    self.TrenchId = trenchId
    self.ModuleList = XBrilliantWalkConfigs.ListModuleListInTrench[XBrilliantWalkConfigs.GetTrenchType(trenchId)]
    local ModuleConfig1 = XBrilliantWalkConfigs.GetBuildPluginConfig(self.ModuleList[1])
    self.PanelModule1:SetNameByGroup(0,ModuleConfig1.Name)
    self.PanelModule1:SetNameByGroup(1,ModuleConfig1.Desc)
    --是否解锁(隐藏按钮)
    if XDataCenter.BrilliantWalkManager.CheckPluginUnlock(self.ModuleList[1]) then
        self.PanelModule1:SetDisable(false)
        --是否装备
        if XDataCenter.BrilliantWalkManager.CheckPluginEquipedInTrench(self.TrenchId,self.ModuleList[1]) then
            self.PanelModule1:SetButtonState(CS.UiButtonState.Select)
        else
            self.PanelModule1:SetButtonState(CS.UiButtonState.Normal)
        end
    else
        self.PanelModule1:SetDisable(true)
    end
    self.PanelModule1:ShowReddot(XDataCenter.BrilliantWalkManager.CheckBrilliantWalkPluginIsRed(self.ModuleList[1]))

    local ModuleConfig2 = XBrilliantWalkConfigs.GetBuildPluginConfig(self.ModuleList[2])
    self.PanelModule2:SetNameByGroup(0,ModuleConfig2.Name)
    self.PanelModule2:SetNameByGroup(1,ModuleConfig2.Desc)
    --是否解锁(隐藏按钮)
    if XDataCenter.BrilliantWalkManager.CheckPluginUnlock(self.ModuleList[2]) then
        self.PanelModule2:SetDisable(false)
        --是否装备
        if XDataCenter.BrilliantWalkManager.CheckPluginEquipedInTrench(self.TrenchId,self.ModuleList[2]) then
            self.PanelModule2:SetButtonState(CS.UiButtonState.Select)
        else
            self.PanelModule2:SetButtonState(CS.UiButtonState.Normal)
        end
    else
        self.PanelModule2:SetDisable(true)
    end
    self.PanelModule2:ShowReddot(XDataCenter.BrilliantWalkManager.CheckBrilliantWalkPluginIsRed(self.ModuleList[2]))

end

--点击模块按钮
function XUIBrilliantWalkModulePanelModule:OnBtnModuleClick(index)
    local pluginId = self.ModuleList[index]
    XDataCenter.BrilliantWalkManager.UiViewPlugin(pluginId)
    if XDataCenter.BrilliantWalkManager.CheckPluginUnlock(pluginId) then
        self.RootUi:OnBtnModuleClick(pluginId)
    else
        XDataCenter.BrilliantWalkManager.ShowPluginUnlockMsg(pluginId)
    end
end

return XUIBrilliantWalkModulePanelModule