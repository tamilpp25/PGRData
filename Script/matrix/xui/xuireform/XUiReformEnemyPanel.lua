local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local CsXTextManager = CS.XTextManager

--######################## XUiReformTargetGrid ########################
local XUiReformTargetGrid = XClass(nil, "XUiReformTargetGrid")

function XUiReformTargetGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Target = nil
    self.BaseStage = nil
    self.EvolvableStage = nil
    self.TargetPanel = nil
    self.BtnBuff1.CallBack = function() self:OnBtnBuffClicked() end
    self.BtnBuff2.CallBack = function() self:OnBtnBuffClicked() end
    self.BtnClick.CallBack = function() self:OnClicked() end
end

-- target : XReformEnemyTarget
function XUiReformTargetGrid:SetData(target, baseStage, evolvableStage, targetPanel)
    self.Target = target
    self.BaseStage = baseStage
    self.EvolvableStage = evolvableStage
    self.TargetPanel = targetPanel
    self.TxtName.text = target:GetName()
    self.RImgIcon:SetRawImage(target:GetIcon())
    self.TxtLevel.text = target:GetShowLevel()
    self.TxtScore.text = target:GetScore()
    self.PanelSelect.gameObject:SetActiveEx(target:GetIsActive())
    local buffViewModels = target:GetReformBuffDetailViewModels()
    for i = 1, 3 do
        if buffViewModels[i] then
            self["RImgBuff" .. i].gameObject:SetActiveEx(true)
            self["RImgBuff" .. i]:SetRawImage(buffViewModels[i].Icon)
            if self["TextNone" .. i] then 
                self["TextNone" .. i].gameObject:SetActiveEx(false)
            end
        else
            self["RImgBuff" .. i].gameObject:SetActiveEx(false)
            if self["TextNone" .. i] then
                self["TextNone" .. i].gameObject:SetActiveEx(true)
            end
        end
    end
end

function XUiReformTargetGrid:OnBtnBuffClicked()
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    local buffDatas = self.Target:GetBuffDetailViewModels()
    if #buffDatas > 0 then
        XLuaUiManager.Open("UiReformBuffTips", buffDatas, CsXTextManager.GetText("ReformEnemyBuffTipsTitle"))
    end
end

function XUiReformTargetGrid:DynamicTouched(source, groupIndex)
    local isActive = self.Target:GetIsActive()
    if isActive then
        -- 取消激活，检查取消后是否能够继续满足分数
        local subScore = self.Target:GetScore()
        if source:GetEntityType() == XReformConfigs.EntityType.Add then
            subScore = subScore + source:GetScore()
        end
        if subScore > self.EvolvableStage:GetChallengeScore() then
            XUiManager.TipError(CsXTextManager.GetText("ReformScoreCancelLimitTip"))
            return
        end
    end
    local replaceIdDic = XTool.Clone(self.EvolvableStage:GetEnemyReplaceIdDic(groupIndex))
    if isActive then
        replaceIdDic[self.Target:GetSourceId()] = 0
    else
        replaceIdDic[source:GetId()] = self.Target:GetId()
    end
    local replaceIdData = {}
    local enemyGroup = self.EvolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Enemy)[groupIndex]
    local buffIds = nil
    for sourceId, targetId in pairs(replaceIdDic) do
        if targetId > 0 then
            buffIds = enemyGroup:GetEnemyReformBuffIdsByTargetId(sourceId, targetId)
        else
            buffIds = enemyGroup:GetDefaultTargetBuffIds(sourceId)
        end
        table.insert(replaceIdData, {
            SourceId = sourceId,
            TargetId = targetId,
            EnemyGroupId = enemyGroup:GetId(),
            EnemyType = enemyGroup:GetEnemyGroupType(),
            AffixSourceId = buffIds
        })
    end
    XDataCenter.ReformActivityManager.EnemyReplaceRequest(self.BaseStage:GetId(), self.EvolvableStage:GetDifficulty()
        , replaceIdData, function()
            local selectedIndex = self.TargetPanel.RootPanel:GetSourceIndex(source)
            if source:GetEntityType() == XReformConfigs.EntityType.Add then
                self.TargetPanel.RootPanel:OnSourceGridClicked(selectedIndex)
            end
            self.TargetPanel:Close()
            self.TargetPanel.RootPanel:SetBtnCloseReformActive(false)
            -- 激活，播放选中的格子动画
            if not isActive then
                self.TargetPanel.RootPanel:PlaySourceGridRefreshAnim(selectedIndex)
            end
        end, enemyGroup:GetId(), enemyGroup:GetEnemyGroupType())
end

function XUiReformTargetGrid:OnClicked()
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    -- 检查图鉴是否已经开放
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Archive, false, true) then
        XUiManager.TipError(CsXTextManager.GetText("ReformMonsterOpenTip"))
        return
    end
    local monsterEntity = self.Target:GetMonsterEntity()
    if monsterEntity == nil then return end
    if monsterEntity:GetIsLockMain() then
        XUiManager.TipText("ArchiveMonsterLock")
        return
    end
    XMVCA.XArchive:GetMonsterEvaluateFromSever(monsterEntity:GetNpcId(), function()
        XLuaUiManager.Open("UiArchiveMonsterDetail", { monsterEntity }, 1, XEnumConst.Archive.MonsterDetailUiType.Show)
    end)
end

--######################## XUiReformTargetPanel ########################
local XUiReformTargetPanel = XClass(nil, "XUiReformTargetPanel")

function XUiReformTargetPanel:Ctor(ui, rootPanel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Source = nil
    self.BaseStage = nil
    self.EvolvableStage = nil
    self.RootPanel = rootPanel
    self:RegisterUiEvents()
    -- 动态列表
    self.GridEnemy.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelReformList)
    self.DynamicTable:SetProxy(XUiReformTargetGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiReformTargetPanel:SetData(source, baseStage, evolvableStage)
    self.Source = source
    self.BaseStage = baseStage
    self.EvolvableStage = evolvableStage
    self:RefreshDynamicTable()
end

function XUiReformTargetPanel:Refresh()
    self:RefreshDynamicTable()
end

function XUiReformTargetPanel:Open()
    self.RootPanel.PanelReformEnable:Play()
    self.GameObject:SetActiveEx(true)
end

function XUiReformTargetPanel:GetIsShow()
    return self.GameObject.activeSelf
end

function XUiReformTargetPanel:Close()
    self.RootPanel.PanelReformEnable:Stop()
    self.GameObject:SetActiveEx(false)
    self.RootPanel:SetScrollListControl(true)
    self.RootPanel:SetSelectedGrid(nil)
end

--######################## 私有方法 ########################

function XUiReformTargetPanel:RegisterUiEvents()
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiReformTargetPanel:RefreshDynamicTable()
    self.DynamicTable:SetDataSource(self.Source:GetTargets())
    self.DynamicTable:ReloadDataSync(1)
end

function XUiReformTargetPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.DynamicTable.DataSource[index]
            , self.BaseStage, self.EvolvableStage, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:DynamicTouched(self.Source, self.RootPanel.CurrentEvolvableGroupIndex)
    end
end

--######################## XUiReformAddGrid ########################
local XUiReformAddGrid = XClass(nil, "XUiReformAddGrid")

function XUiReformAddGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Source = nil
    self.EmptyPosCount = nil
    self.SourcePanel = nil
    self.Index = nil
    self:RegisterUiEvents()
end

function XUiReformAddGrid:SetData(data, index, sourcePanel)
    self.Source = data.source
    self.EmptyPosCount = data.emptyPosCount
    self.SourcePanel = sourcePanel
    self.Index = index
    self.TxtCount.text = CsXTextManager.GetText("ReformEnemyAddCountText", data.emptyPosCount)
    self.TxtScore.text = data.source:GetScore()
end

--######################## 私有方法 ########################

function XUiReformAddGrid:RegisterUiEvents()
    self.BtnAdd.CallBack = function() self:OnBtnAddClicked() end
end

function XUiReformAddGrid:OnBtnAddClicked()
    self.SourcePanel:OpenTargetReformPanel(self.Source)
    self.SourcePanel:OnSourceGridClicked(self.Index)
end

--######################## XUiReformSourceGrid ########################
local XUiReformSourceGrid = XClass(nil, "XUiReformSourceGrid")

function XUiReformSourceGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Data = nil
    self.SourcePanel = nil
    self.Index = nil
    self.UiGridAdd = XUiReformAddGrid.New(self.GridAdd)
    self:RegisterUiEvents()
end

function XUiReformSourceGrid:SetData(data, index, sourcePanel)
    self.Data = data
    self.Index = index
    self.SourcePanel = sourcePanel
    local isAdd = data.isAddEntity == true and true or false
    self.GridAdd.gameObject:SetActiveEx(isAdd)
    self.GridEntity.gameObject:SetActiveEx(not isAdd)
    if isAdd then
        self:SetAddData(data)
    else
        self:SetEntityData(data)
    end
end

function XUiReformSourceGrid:SetEntityData(source)
    local score = 0
    if source:GetEntityType() == XReformConfigs.EntityType.Add then
        self.Tab1.gameObject:SetActiveEx(source:GetIsActive())
        self.Tab2.gameObject:SetActiveEx(false)
        score = score + source:GetScore()
    else
        self.Tab1.gameObject:SetActiveEx(false)
        -- self.Tab2.gameObject:SetActiveEx(source:GetIsActive())    
        self.Tab2.gameObject:SetActiveEx(false)
    end
    score = score + source:GetTargetScore()
    self.TxtName.text = source:GetName()
    self.RImgIcon:SetRawImage(source:GetIcon())
    self.TxtLevel.text = CsXTextManager.GetText("ReformEnemyLevelText", source:GetShowLevel())
    self.TxtCost.text = score
    local buffViewModels = self.Data:GetBuffDetailViewModels()
    for i = 1, 3 do
        self["BtnBuff" .. i].gameObject:SetActiveEx(true)
        self["RImgBuff" .. i].gameObject:SetActiveEx(buffViewModels[i] ~= nil)
        if self["TextNone" .. i] then 
            self["TextNone" .. i].gameObject:SetActiveEx(buffViewModels[i] == nil)
        end
        if buffViewModels[i] then
            self["RImgBuff" .. i]:SetRawImage(buffViewModels[i].Icon)
        end
    end
end

function XUiReformSourceGrid:SetAddData(data)
    self.UiGridAdd:SetData(data, self.Index, self.SourcePanel)
end

function XUiReformSourceGrid:SetSelectStatus(value)
    self.PanelSelect.gameObject:SetActiveEx(value)
end

function XUiReformSourceGrid:PlayRefreshAnim()
    self.PlayableDirector:Play()
end

--######################## 私有方法 ########################

function XUiReformSourceGrid:RegisterUiEvents()
    self.BtnReform.CallBack = function() self:OnBtnReformClicked() end
    self.BtnClick.CallBack = function() self:OnBtnClickClicked() end
    self.BtnBuff1.CallBack = function() self:OnBtnBuffClicked() end
    self.BtnBuff2.CallBack = function() self:OnBtnBuffClicked() end
end

function XUiReformSourceGrid:OnBtnBuffClicked()
    local buffDatas = self.Data:GetBuffDetailViewModels()
    if #buffDatas > 0 then
        XLuaUiManager.Open("UiReformBuffTips", buffDatas, CsXTextManager.GetText("ReformEnemyBuffTipsTitle"))
    end
end

function XUiReformSourceGrid:OnBtnReformClicked()
    self.SourcePanel:OpenTargetReformPanel(self.Data)
    self.SourcePanel:OnSourceGridClicked(self.Index)
end

function XUiReformSourceGrid:OnBtnClickClicked()
    -- 检查图鉴是否已经开放
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Archive, false, true) then
        XUiManager.TipError(CsXTextManager.GetText("ReformMonsterOpenTip"))
        return
    end
    local monsterEntity = self.Data:GetMonsterEntity()
    if monsterEntity == nil then return end
    if monsterEntity:GetIsLockMain() then
        XUiManager.TipText("ArchiveMonsterLock")
        return
    end
    -- local sourcesWithEntity = self.SourcePanel:GetSources()
    -- local monsterEntities = {}
    -- local tempMonsterEntity = nil
    -- local selfIndex = 1
    -- for i, source in ipairs(sourcesWithEntity) do
    --     tempMonsterEntity = source:GetMonsterEntity()
    --     if tempMonsterEntity and not tempMonsterEntity:GetIsLockMain() then
    --         table.insert(monsterEntities, tempMonsterEntity)
    --     end
    --     if source:GetId() == self.Data:GetId() then
    --         selfIndex = i
    --     end
    -- end
    -- XDataCenter.ArchiveManager.GetMonsterEvaluateFromSever(monsterEntity:GetNpcId(), function()
    --     XLuaUiManager.Open("UiArchiveMonsterDetail", monsterEntities, selfIndex, XEnumConst.Archive.MonsterDetailUiType.Show)
    -- end)
    XMVCA.XArchive:GetMonsterEvaluateFromSever(monsterEntity:GetNpcId(), function()
        XLuaUiManager.Open("UiArchiveMonsterDetail", { monsterEntity }, 1, XEnumConst.Archive.MonsterDetailUiType.Show)
    end)
end

--######################## XUiReformEnemyPanel ########################
local XUiReformEnemyGroupGrid = require("XUi/XUiReform/XUiReformEnemyGroupGrid")
local XUiReformEnemyPanel = XClass(XSignalData, "XUiReformEnemyPanel")

function XUiReformEnemyPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BaseStage = nil
    self.EvolvableStage = nil
    self.EvolvableGroups = nil
    self.CurrentEvolvableGroupIndex = 1
    -- 动态列表
    self.GridEnemy.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEnemyList)
    self.DynamicTable:SetProxy(XUiReformSourceGrid)
    self.DynamicTable:SetDelegate(self)
    -- 改造面板
    self.UiReformTargetPanel = XUiReformTargetPanel.New(self.PanelReform, self)
    self.TxtTip.text = CsXTextManager.GetText("ReformEnemyPanelTopTip")
    self.BtnCloseReform.gameObject:SetActiveEx(false)
    self.TxtTip2.text = CsXTextManager.GetText("ReformMemberPanelTopEvolableTip")
    self:RegisterUiEvents()
end

function XUiReformEnemyPanel:SetData(baseStage, evolvableStage)
    self.CurrentEvolvableGroupIndex = 1
    self.BaseStage = baseStage
    self.EvolvableStage = evolvableStage
    self.EvolvableGroups = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Enemy)
    -- 刷新源列表
    self:RefreshDynamicTable()
    self:CloseTargetReformPanel()
    self:RefreshEnemyGroupInfo()
end

function XUiReformEnemyPanel:SetCurrentGroupIndex(value)
    self.CurrentEvolvableGroupIndex = value
    self:EmitSignal("RefreshChallengeScore", false, value)
    self.AnimSwitch:Play()
end

function XUiReformEnemyPanel:GetCurrentGroupIndex()
    return self.CurrentEvolvableGroupIndex
end

function XUiReformEnemyPanel:RefreshEvolvableData()
    local sources = self:GetSourcesWithEntity()
    local grids = self.DynamicTable:GetGrids()
    if #self.DynamicTable.DataSource == #sources then
        for i, v in ipairs(sources) do
            if grids[i] then
                grids[i]:SetData(sources[i], i, self)
            end
        end
        self.DynamicTable:SetDataSource(sources)
    else
        self:RefreshDynamicTable(sources)
    end
    if self.UiReformTargetPanel:GetIsShow() then
        self.UiReformTargetPanel:Refresh()
    end
    self:RefreshEnemyGroupInfo()
end

function XUiReformEnemyPanel:OpenTargetReformPanel(source)
    self.UiReformTargetPanel:Open()
    self.UiReformTargetPanel:SetData(source, self.BaseStage, self.EvolvableStage)
    self.BtnCloseReform.gameObject:SetActiveEx(true)
end

function XUiReformEnemyPanel:CloseTargetReformPanel()
    self.UiReformTargetPanel:Close()
    self.BtnCloseReform.gameObject:SetActiveEx(false)
end

function XUiReformEnemyPanel:SetBtnCloseReformActive(value)
    self.BtnCloseReform.gameObject:SetActiveEx(value)
end

function XUiReformEnemyPanel:SetScrollListControl(value)
    if value then
        self.PanelEnemyList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        self.PanelEnemyList.horizontal = true
    else
        self.PanelEnemyList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        self.PanelEnemyList.horizontal = false
    end  
end

--######################## 私有方法 ########################

function XUiReformEnemyPanel:RegisterUiEvents()
    self.BtnCloseReform.CallBack = function() self:OnBtnCloseReformClicked() end
end

function XUiReformEnemyPanel:OnBtnCloseReformClicked()
    self:CloseTargetReformPanel()
end

function XUiReformEnemyPanel:RefreshDynamicTable(sources)
    sources = sources or self:GetSourcesWithEntity()
    self.DynamicTable:SetDataSource(sources)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiReformEnemyPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.DynamicTable.DataSource[index], index, self)
    end
end

function XUiReformEnemyPanel:GetSourcesWithEntity()
    local entities, nextAddSource, emptyPosCount = self.EvolvableGroups[self.CurrentEvolvableGroupIndex]:GetSourcesWithEntity()
    if nextAddSource then
        table.insert(entities, 1, {
            source = nextAddSource,
            emptyPosCount = emptyPosCount,
            isAddEntity = true,
            Id = nextAddSource:GetId()
        })
    end
    return entities
end

function XUiReformEnemyPanel:GetSources()
    return self.EvolvableGroups[self.CurrentEvolvableGroupIndex]:GetSourcesWithEntity()
end

function XUiReformEnemyPanel:GetSourceIndex(source)
    local sources = self:GetSources()
    for i, v in ipairs(sources) do
        if v == source then
            return i
        end
    end
    return 1
end

function XUiReformEnemyPanel:OnSourceGridClicked(index)
    self:SetSelectedGrid(index)
    self:ScrollGrid(index)
end

function XUiReformEnemyPanel:SetSelectedGrid(index)
    for i, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetSelectStatus(i == index)
    end
end

function XUiReformEnemyPanel:ScrollGrid(index)
    local grids = self.DynamicTable:GetGrids()
    local grid = grids[index]
    if not grid then 
        self.DynamicTable:ReloadDataSync(index)
        return 
    end
    self:SetScrollListControl(false)
    local distance = (grid.Transform.localPosition + self.PanelEnemyListContent.localPosition).x * -1
    if distance >= XReformConfigs.MinDistance and distance <= XReformConfigs.MaxDistance then return end
    local targetPos = self.PanelEnemyListContent.localPosition
    if index == 1 then
        targetPos.x = math.min(self.PanelEnemyListContent.rect.width / 2 - self.PanelEnemyListContent.parent.rect.width / 2) 
            - self.PanelEnemyListContent.rect.width / 2
    else
        targetPos.x = targetPos.x + distance - grid.Transform.rect.width / 2 - XReformConfigs.ScrollOffset
    end
    XUiHelper.DoMove(self.PanelEnemyListContent, targetPos, 0.3, XUiHelper.EaseType.Sin)
end

function XUiReformEnemyPanel:PlaySourceGridRefreshAnim(index)
    local grid = self.DynamicTable:GetGrids()[index]
    if not grid then return end
    grid:PlayRefreshAnim()
end

-- 刷新敌人波次改造信息
function XUiReformEnemyPanel:RefreshEnemyGroupInfo()
    if self.__ReformEnemyGroupGridDic == nil then
        self.__ReformEnemyGroupGridDic = {}
    end
    local enemyGroup = nil
    local isActive = false
    local isFirstAdd = true
    XUiHelper.RefreshCustomizedList(self.PanelTabTop, self.ReformGroup, #self.EvolvableGroups, function(index, grid)
        local groupGrid = self.__ReformEnemyGroupGridDic[index]
        if groupGrid == nil then
            groupGrid = XUiReformEnemyGroupGrid.New(grid, self)
            self.__ReformEnemyGroupGridDic[index] = groupGrid
        end
        enemyGroup = self.EvolvableGroups[index]
        groupGrid:SetData(index, enemyGroup)
        groupGrid:SetSelectedIndex(self.CurrentEvolvableGroupIndex)
        isActive = enemyGroup:GetIsActive()
        if enemyGroup:GetEnemyGroupType() == XReformConfigs.EnemyGroupType.ExtraEnemy then
            if not isActive and isFirstAdd then
                grid.gameObject:SetActiveEx(true)
                isFirstAdd = false
                return
            end
            grid.gameObject:SetActiveEx(isFirstAdd)
        end
    end)
end

return XUiReformEnemyPanel