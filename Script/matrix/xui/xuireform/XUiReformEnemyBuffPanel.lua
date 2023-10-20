--######################## XUiReformEnemyBuffDetailGrid ########################
local XUiReformEnemyBuffDetailGrid = XClass(nil, "XUiReformEnemyBuffDetailGrid")

function XUiReformEnemyBuffDetailGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnSelf, self.OnBtnSelfClicked)
    self.ViewModel = nil
end

function XUiReformEnemyBuffDetailGrid:SetData(viewModel)
    self.ViewModel = viewModel
    self.Have.gameObject:SetActiveEx(viewModel ~= nil)
    self.None.gameObject:SetActiveEx(viewModel == nil)
    if viewModel == nil then return end
    self.RImgBuff:SetRawImage(viewModel.Icon)
end

function XUiReformEnemyBuffDetailGrid:SetReformPanelData(viewModel)
    self.ViewModel = viewModel
    self.TxtName.text = viewModel.Name
    if not string.IsNilOrEmpty(viewModel.SimpleDes) then
        self.TxtDesc.text = viewModel.SimpleDes
    else
        self.TxtDesc.text = viewModel.Description
    end
    self.TxtScore.text = viewModel.Score
    self.RImgIcon:SetRawImage(viewModel.Icon)
end

function XUiReformEnemyBuffDetailGrid:OnBtnSelfClicked()
    if self.ViewModel then
        XLuaUiManager.Open("UiReformBuffTips", { self.ViewModel }, XUiHelper.GetText("ReformEnemyBuffTipsTitle"))
    end
end

function XUiReformEnemyBuffDetailGrid:SetSelectStatus(value)
    self.Select.gameObject:SetActiveEx(value)
end

--######################## XUiReformPanel ########################
local XUiReformPanel = XClass(nil, "XUiReformPanel")

function XUiReformPanel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClicked)
    -- 动态列表
    self.GridBuff.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelReformList)
    self.DynamicTable:SetProxy(XUiReformEnemyBuffDetailGrid)
    self.DynamicTable:SetDelegate(self)
    self.EnemySource = nil
    self.StageId = nil
    self.Difficulty = nil
    self.EnemyGroup = nil
    self.Index = nil
end

function XUiReformPanel:Open(source, stageId, difficulty, enemyGroup, index)
    self.EnemySource = source
    self.StageId = stageId
    self.Difficulty = difficulty
    self.EnemyGroup = enemyGroup
    self.Index = index
    self.GameObject:SetActiveEx(true)
    self.BtnClose.gameObject:SetActiveEx(true)
    self:Refresh()
end

function XUiReformPanel:Refresh()
    local target = self.EnemySource:GetCurrentTarget() or self.EnemySource:GetDefaultTarget()
    self.TxtTip.text = XUiHelper.GetText("ReformEnemyBuffTipsTitle2", #target:GetBuffGroup():GetActiveBuffIds()
        , target:GetMaxReformBuffCount())
    self.DynamicTable:SetDataSource(target:GetAllReformBuffViewModels())
    self.DynamicTable:ReloadDataSync(1)
end

function XUiReformPanel:OnBtnCloseClicked()
    self.GameObject:SetActiveEx(false)
    self.BtnClose.gameObject:SetActiveEx(false)
end

function XUiReformPanel:OnDynamicTableEvent(event, index, grid)
    local buffViewModel = self.DynamicTable.DataSource[index]
    local target = self.EnemySource:GetCurrentTarget() or self.EnemySource:GetDefaultTarget()
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetReformPanelData(buffViewModel)
        grid:SetSelectStatus(target:GetBuffGroup():CheckBuffIsActive(buffViewModel.Id))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnEnemyBuffClicked(buffViewModel)
    end
end

function XUiReformPanel:OnEnemyBuffClicked(data)
    local buffIds = XTool.Clone(self.EnemyGroup:GetEnemyReformBuffIds(self.EnemySource:GetId()))
    local isHave = false
    for i = #buffIds, 1, -1 do
        if buffIds[i] == data.Id then
            isHave = true
            table.remove(buffIds, i)
            break
        end
    end
    if not isHave then
        table.insert(buffIds, data.Id)
    end
    XDataCenter.ReformActivityManager.EnemyBuffReplaceRequest(self.StageId, self.Difficulty
        , self.EnemyGroup:GetId(), self.EnemyGroup:GetEnemyGroupType(), self.EnemySource:GetId(), buffIds, function()
            self:Refresh()
        end, self.Index)
end

--######################## XUiReformEnemyBuffGrid ########################
local XUiReformEnemyBuffGrid = XClass(nil, "XUiReformEnemyBuffGrid")

function XUiReformEnemyBuffGrid:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnReform, self.BtnReformClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnHead, self.BtnHeadClicked)
    self.EnemySource = nil
    self.RootUi = rootUi
    self.Index = nil
end

function XUiReformEnemyBuffGrid:SetData(source, index)
    self.EnemySource = source
    self.Index = index
    local target = source:GetCurrentTarget() or source:GetDefaultTarget()
    self.TxtLevel.text = XUiHelper.GetText("ReformEnemyLevelText"
        , target:GetShowLevel())
    self.RImgIcon:SetRawImage(target:GetIcon())
    self.Tab1.gameObject:SetActiveEx(source:GetIsActive() and source:GetEntityType() == XReformConfigs.EntityType.Add)
    self.Tab2.gameObject:SetActiveEx(source:GetIsActive() and source:GetEntityType() == XReformConfigs.EntityType.Entity)
    self.TxtScore.text = target:GetReformedBuffTotalScore()
    -- 刷新buff
    local buffViewModels = target:GetReformBuffDetailViewModels()
    XUiHelper.RefreshCustomizedList(self.PanelBuff, self.BtnBuff, target:GetMaxReformBuffCount(), function(index, gridGo)
        if self.__BuffGridDic == nil then
            self.__BuffGridDic = {}
        end
        local grid = self.__BuffGridDic[index]
        if grid == nil then
            grid = XUiReformEnemyBuffDetailGrid.New(gridGo)
            self.__BuffGridDic[index] = grid
        end
        grid:SetData(buffViewModels[index])
    end)
end

function XUiReformEnemyBuffGrid:SetSelectStatus(value)
    self.PanelSelect.gameObject:SetActiveEx(value)
end

function XUiReformEnemyBuffGrid:BtnReformClicked()
    self.RootUi:OpenReformPanel(self.EnemySource, self.Index)
end

function XUiReformEnemyBuffGrid:BtnHeadClicked()
    -- 检查图鉴是否已经开放
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Archive, false, true) then
        XUiManager.TipError(CsXTextManager.GetText("ReformMonsterOpenTip"))
        return
    end
    local monsterEntity = self.EnemySource:GetMonsterEntity()
    if monsterEntity == nil then return end
    if monsterEntity:GetIsLockMain() then
        XUiManager.TipText("ArchiveMonsterLock")
        return
    end
    XMVCA.XArchive:GetMonsterEvaluateFromSever(monsterEntity:GetNpcId(), function()
        XLuaUiManager.Open("UiArchiveMonsterDetail", { monsterEntity }, 1, XEnumConst.Archive.MonsterDetailUiType.Show)
    end)
end

--######################## XUiReformEnemyBuffPanel ########################
local XUiReformEnemyGroupGrid = require("XUi/XUiReform/XUiReformEnemyGroupGrid")
local XUiReformEnemyBuffPanel = XClass(XSignalData, "XUiReformEnemyBuffPanel")

function XUiReformEnemyBuffPanel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.BaseStage = nil
    self.EvolvableStage = nil
    self.EvolvableGroups = nil
    self.CurrentEvolvableGroupIndex = 1
    -- 动态列表
    self.GirdEnemy.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEnemyList)
    self.DynamicTable:SetProxy(XUiReformEnemyBuffGrid, self)
    self.DynamicTable:SetDelegate(self)
    -- 改造面板
    self.ReformPanel = XUiReformPanel.New(self.PanelReform)
    self.GridDic = {}
end

function XUiReformEnemyBuffPanel:SetData(baseStage, evolvableStage)
    self.BaseStage = baseStage
    self.EvolvableStage = evolvableStage
    self.EvolvableGroups = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.EnemyBuff)
    for index, group in ipairs(self.EvolvableGroups) do
        if group:GetIsActive(false) then
            self.CurrentEvolvableGroupIndex = index
            break
        end
    end
    -- 顶部提示
    self.TxtTopTip.text = XUiHelper.GetText("ReformEnemyBuffPanelTopTip")
    -- 刷新顶部按钮组
    self:RefreshEnemyGroupInfo()
    -- 刷新列表
    self:RefreshDynamicTable()
end

function XUiReformEnemyBuffPanel:RefreshDynamicTable(index)
    local currentEvolvableGroup = self.EvolvableGroups[self.CurrentEvolvableGroupIndex]
    self.DynamicTable:SetDataSource(currentEvolvableGroup:GetSourcesWithEntity(false))
    self.DynamicTable:ReloadDataSync(index or 1)
end

function XUiReformEnemyBuffPanel:OnDynamicTableEvent(event, index, grid)
    self.GridDic[index] = grid
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.DynamicTable.DataSource[index], index)
    end
end

function XUiReformEnemyBuffPanel:SetCurrentGroupIndex(value)
    self.CurrentEvolvableGroupIndex = value
    self:EmitSignal("RefreshChallengeScore", false, value)
    self.AnimSwitch:Play()
end

function XUiReformEnemyBuffPanel:GetCurrentGroupIndex()
    return self.CurrentEvolvableGroupIndex
end

function XUiReformEnemyBuffPanel:RefreshEvolvableData(index)
    -- 刷新列表
    if index == nil then
        self:RefreshDynamicTable(index)
    elseif self.GridDic[index] then
        self.GridDic[index]:SetData(self.DynamicTable.DataSource[index], index)
    end
    
    self:RefreshEnemyGroupInfo()
end

-- 刷新敌人波次改造信息
function XUiReformEnemyBuffPanel:RefreshEnemyGroupInfo()
    if self.__ReformEnemyGroupGridDic == nil then
        self.__ReformEnemyGroupGridDic = {}
    end
    local group = nil
    XUiHelper.RefreshCustomizedList(self.PanelTabTop, self.ReformGroup, #self.EvolvableGroups, function(index, grid)
        local groupGrid = self.__ReformEnemyGroupGridDic[index]
        if groupGrid == nil then
            groupGrid = XUiReformEnemyGroupGrid.New(grid, self)
            self.__ReformEnemyGroupGridDic[index] = groupGrid
        end
        group = self.EvolvableGroups[index]
        groupGrid:SetData(index, group)
        groupGrid:SetSelectedIndex(self.CurrentEvolvableGroupIndex)
        grid.gameObject:SetActiveEx(group:GetIsActive())
    end)
end

function XUiReformEnemyBuffPanel:OpenReformPanel(source, index)
    self.ReformPanel:Open(source, self.BaseStage:GetId(), self.EvolvableStage:GetDifficulty(), self.EvolvableGroups[self.CurrentEvolvableGroupIndex]
        , index)
end

return XUiReformEnemyBuffPanel