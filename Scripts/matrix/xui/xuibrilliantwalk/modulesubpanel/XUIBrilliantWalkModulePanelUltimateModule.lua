--模块界面XUIBrilliantWalkModule 的子界面PanelModule 选择必杀模块界面
local XUIBrilliantWalkModulePanelUltimateModule = XClass(nil, "XUIBrilliantWalkModulePanelUltimateModule")
local XUIBrilliantWalkUltimateModuleGrid = require("XUi/XUiBrilliantWalk/XUIGrid/XUIBrilliantWalkUltimateModuleGrid")--必杀模块Grid


function XUIBrilliantWalkModulePanelUltimateModule:Ctor(perfabObject, rootUi)
    self.GameObject = perfabObject.gameObject
    self.Transform = perfabObject.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    --必杀模块部分UI
    self.TransformContent = self.Content.transform
    self.UltimateModuleGridPool = XStack.New() --插件解锁预览 UI内存池
    self.UltimateModuleGridList = XStack.New() --正在使用的插件解锁预览UI
    self.GridUltimateModule.gameObject:SetActiveEx(false)
end

--刷新界面
function XUIBrilliantWalkModulePanelUltimateModule:UpdateView(trenchId)
    self.TrenchId = trenchId
    local selectedModuleId
    if self.SelectedModule then
        selectedModuleId = self.SelectedModule.ModuleId
    end
    self.SelectedModule = nil
    self:UltimateModuleGridReturnPool()
    self.ModuleList = XBrilliantWalkConfigs.ListModuleListInTrench[XBrilliantWalkConfigs.GetTrenchType(trenchId)]
    for _,moduleId in ipairs(self.ModuleList) do
        local grid = self:GetUltimateModuleGrid()
        grid:UpdateView(self.TrenchId,moduleId)
        if selectedModuleId == moduleId then
            grid:SetSelect(true)
            self.SelectedModule = grid
        else
            grid:SetSelect(false)
        end
    end
    XUiHelper.MarkLayoutForRebuild(self.TransformContent)
end

--从Item内存池提取Grid
function XUIBrilliantWalkModulePanelUltimateModule:GetUltimateModuleGrid()
    local grid
    if self.UltimateModuleGridPool:IsEmpty() then
        local object = CS.UnityEngine.Object.Instantiate(self.GridUltimateModule)
        object.transform:SetParent(self.Content, false)
        grid = XUIBrilliantWalkUltimateModuleGrid.New(object,grid)
        grid:InitRoot(self)
    else
        grid = self.UltimateModuleGridPool:Pop()
    end
    grid.GameObject:SetActiveEx(true)
    self.UltimateModuleGridList:Push(grid)
    return grid
end
--所有使用中插件Item回归内存池
function XUIBrilliantWalkModulePanelUltimateModule:UltimateModuleGridReturnPool()
    while (not self.UltimateModuleGridList:IsEmpty()) do
        local object = self.UltimateModuleGridList:Pop()
        object.GameObject:SetActiveEx(false)
        self.UltimateModuleGridPool:Push(object)
    end
end

--点击激活按钮
function XUIBrilliantWalkModulePanelUltimateModule:OnBtnActiveModule(grid,moduleId)
    self.RootUi:OnBtnActiveModule(moduleId)
    self:UpdateView(self.TrenchId)
end
--点击取消激活按钮
function XUIBrilliantWalkModulePanelUltimateModule:BtnDisactiveModule(grid,moduleId)
    self.RootUi:OnBtnDisactiveModule(moduleId)
    self:UpdateView(self.TrenchId)
end
--点击模块按钮 设置高亮模块
function XUIBrilliantWalkModulePanelUltimateModule:OnGridExpend(grid,expendState)
    if expendState then
        if self.SelectedModule == grid then
            return
        end
        if self.SelectedModule then
            self.SelectedModule:SetSelect(false)
        end
        self.SelectedModule = grid
        self.SelectedModule:SetSelect(true)
    else
        if self.SelectedModule then
            self.SelectedModule:SetSelect(false)
        end
        self.SelectedModule = nil
    end
    XUiHelper.MarkLayoutForRebuild(self.TransformContent)
end


return XUIBrilliantWalkModulePanelUltimateModule