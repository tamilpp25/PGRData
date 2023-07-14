----模块界面XUIBrilliantWalkModule 的子界面PanelUltimateModule 选择必杀模块界面 的模块Grid
local XUIBrilliantWalkUltimateModuleGrid = XClass(nil, "XUIBrilliantWalkUltimateModuleGrid")


function XUIBrilliantWalkUltimateModuleGrid:Ctor(perfabObject, rootUi)
    self.GameObject = perfabObject.gameObject
    self.Transform = perfabObject.transform
    XTool.InitUiObject(self)
    self.SelectState = false
    --普通状态下按钮
    self.BtnNormal.CallBack = function()
        self:ExpendPanel(true)
    end
    --展开状态下按钮
    self.BtnExpend.CallBack = function()
        self:ExpendPanel(false)
    end
    --锁定状态下按钮
    self.BtnDisable.CallBack = function()
        self:ExpendPanel(false)
    end
    --激活普通状态下按钮
    self.BtnEquipedNormal.CallBack = function()
        self:ExpendPanel(true)
    end
    --激活展开状态下按钮
    self.BtnEquipedExpend.CallBack = function()
        self:ExpendPanel(false)
    end
    --激活按钮
    self.BtnActive.CallBack = function()
        self:OnBtnActive()
    end
    --取消激活按钮
    self.BtnDisactive.CallBack = function()
        self:OnBtnDisactive()
    end
end

function XUIBrilliantWalkUltimateModuleGrid:InitRoot(root)
    self.RootUi = root
end

--刷新界面
function XUIBrilliantWalkUltimateModuleGrid:UpdateView(trenchId, moduleId)
    self.TrenchId = trenchId
    self.ModuleId = moduleId
    if (not self.ModuleId) then
        self.GameObject:SetActiveEx(false)
    else
        self.GameObject:SetActiveEx(true)
    end
    --设置模块信息
    local moduleConfig = XBrilliantWalkConfigs.GetBuildPluginConfig(moduleId)
    self.GridUltimateModule:SetNameByGroup(0,moduleConfig.Name)
    self.GridUltimateModule:SetNameByGroup(1,moduleConfig.Desc)
    --红点
    self.Red.gameObject:SetActiveEx(XDataCenter.BrilliantWalkManager.CheckBrilliantWalkPluginIsRed(self.ModuleId))
end

--设置显示状态
function XUIBrilliantWalkUltimateModuleGrid:SetSelect(state)
    if (not self.ModuleId) then
        return
    end
    self.GridUltimateModule:SetDisable(false)
    self.SelectState = state
    self.PanelEquipedExpend.gameObject:SetActiveEx(false)
    self.PanelEquipedNormal.gameObject:SetActiveEx(false)
    self.PanelExpend.gameObject:SetActiveEx(false)
    self.PanelNormal.gameObject:SetActiveEx(false)
    self.PanelDisable.gameObject:SetActiveEx(false)
    --显示装备状态中的模块
    if XDataCenter.BrilliantWalkManager.CheckPluginEquipedInTrench(self.TrenchId,self.ModuleId) then
        if self.SelectState then --显示选中的模块
            self.PanelEquipedExpend.gameObject:SetActiveEx(true)
        else --显示没被选中的模块
            self.PanelEquipedNormal.gameObject:SetActiveEx(true)
        end
    else --非装备中的模块
        if self.SelectState then --显示选中的模块
            if XDataCenter.BrilliantWalkManager.CheckPluginUnlock(self.ModuleId) then
                self.PanelExpend.gameObject:SetActiveEx(true)
            else
                self.PanelDisable.gameObject:SetActiveEx(true)
            end
        else --显示没被选中的模块
            self.PanelNormal.gameObject:SetActiveEx(true)
        end
    end
    
end

--点击展开或收缩
function XUIBrilliantWalkUltimateModuleGrid:ExpendPanel(state)
    XDataCenter.BrilliantWalkManager.UiViewPlugin(self.ModuleId)
    self.Red.gameObject:SetActiveEx(false)
    self.RootUi:OnGridExpend(self,state)
end
--点击激活按钮
function XUIBrilliantWalkUltimateModuleGrid:OnBtnActive()
    self.RootUi:OnBtnActiveModule(self,self.ModuleId)
end
--点击取消激活按钮
function XUIBrilliantWalkUltimateModuleGrid:OnBtnDisactive()
    self.RootUi:BtnDisactiveModule(self,self.ModuleId)
end

return XUIBrilliantWalkUltimateModuleGrid