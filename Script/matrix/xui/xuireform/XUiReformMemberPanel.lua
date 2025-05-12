local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local CsXTextManager = CS.XTextManager

--######################## XUiReformAwarenessGrid ########################
local XUiReformAwarenessGrid = XClass(nil, "XUiReformAwarenessGrid")

function XUiReformAwarenessGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnClick.CallBack = function() self:OnBtnClicked() end
    -- XAwarenessViewModel
    self.Awareness = nil
    -- XCharacterViewModel
    self.CharacterViewModel = nil
end

function XUiReformAwarenessGrid:SetData(data)
    self.Awareness = data
    -- 品质
    self.ImgQuality:SetSprite(data:GetQualityIcon())
    -- 图标
    self.RImgIcon:SetRawImage(data:GetIcon())
    -- 等级
    -- self.TxtLevel.text = data:GetLevel()
    -- 位置
    self.TxtSite.text = "0" .. data:GetSite()
    -- 共鸣
    local ResonanceInfos = data:GetResonanceInfos()
    local obj = nil
    for i = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
        obj = self["ImgResonance" .. i]
        if obj then
            if ResonanceInfos and ResonanceInfos[i] then
                obj.gameObject:SetActiveEx(data:CheckPosIsAwaken(i))
            else
                obj.gameObject:SetActiveEx(false)
            end
        end
    end
    -- 突破
    local breakthrough = data:GetBreakthrough()
    if breakthrough ~= 0 then
        self.ImgBreakthrough.gameObject:SetActiveEx(true)
        local breakthroughIcon = XMVCA.XEquip:GetEquipBreakThroughSmallIcon(breakthrough)
        self.ImgBreakthrough:SetSprite(breakthroughIcon)
    else
        self.ImgBreakthrough.gameObject:SetActiveEx(false)
    end
end

function XUiReformAwarenessGrid:SetCountText(value)
    self.TxtCount.text = value
end

function XUiReformAwarenessGrid:SetCharacterViewModel(value)
    self.CharacterViewModel = value
end

function XUiReformAwarenessGrid:OnBtnClicked()
    XLuaUiManager.Open("UiEquipDetailOther", self.Awareness:GetEquip(), self.CharacterViewModel:GetCharacter())
end

--######################## XUiReformTargetGrid ########################
local XUiReformTargetGrid = XClass(nil, "XUiReformTargetGrid")

function XUiReformTargetGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Target = nil
    self.Source = nil
    self.BaseStage = nil
    self.EvolvableStage = nil
    self.TargetPanel = nil
    self.BtnClick.CallBack = function() self:OnClicked() end
    self.UiReformAwarenessGrid1 = XUiReformAwarenessGrid.New(self.GridAwareness1)
    self.UiReformAwarenessGrid2 = XUiReformAwarenessGrid.New(self.GridAwareness2)
end

-- target : XReformMemberTarget
function XUiReformTargetGrid:SetData(target, baseStage, evolvableStage, targetPanel, source)
    self.Target = target
    self.Source = source
    self.BaseStage = baseStage
    self.EvolvableStage = evolvableStage
    self.TargetPanel = targetPanel
    self.TxtName.text = target:GetLogName()
    self.RImgIcon:SetRawImage(target:GetSmallHeadIcon())
    self.TxtStar.text = target:GetStarLevel()
    self.TxtScore.text = target:GetScore()
    self.PanelSelect.gameObject:SetActiveEx(target:GetIsActive())
    -- 显示意识数据
    local showInfos = target:GetShowAwarenessViewModelInfos()
    local UiReformAwarenessGrid, showInfo
    for i = 1, 2 do
        showInfo = showInfos[i]
        UiReformAwarenessGrid = self["UiReformAwarenessGrid" .. i]
        UiReformAwarenessGrid.GameObject:SetActiveEx(showInfo ~= nil)
        if showInfo then
            UiReformAwarenessGrid:SetData(showInfo.value.showViewModel)
            UiReformAwarenessGrid:SetCountText(showInfo.value.count)
            UiReformAwarenessGrid:SetCharacterViewModel(target:GetCharacterViewModel())
        end
    end
end

function XUiReformTargetGrid:DynamicTouched(source)
    local isActive = self.Target:GetIsActive()
    if not isActive then
        -- 准备激活，检查分数够不够扣
        local subScore = self.Target:GetScore()
        if source:GetCurrentTarget() == nil and source:GetEntityType() == XReformConfigs.EntityType.Add then
            subScore = subScore + source:GetScore()
        end
        -- 已经有目标了，把目标的分数减去
        subScore = subScore - source:GetTargetScore()
        if subScore > self.EvolvableStage:GetChallengeScore() then
            XUiManager.TipError(CsXTextManager.GetText("ReformScoreLimitTip"))
            return
        end
    end
    local replaceIdDic = XTool.Clone(self.EvolvableStage:GetMemberReplaceIdDic())
    if isActive then
        replaceIdDic[self.Target:GetSourceId()] = 0
    else
        replaceIdDic[source:GetId()] = self.Target:GetId()
    end
    local replaceIdData = {}
    for sourceId, targetId in pairs(replaceIdDic) do
        table.insert(replaceIdData, {
            SourceId = sourceId,
            TargetId = targetId,
        })
    end
    XDataCenter.ReformActivityManager.MemberReplaceRequest(self.BaseStage:GetId(), self.EvolvableStage:GetDifficulty()
        , replaceIdData, function()
            -- 取消激活并且是加号来源，直接关闭改造界面
            -- if isActive and source:GetEntityType() == XReformConfigs.EntityType.Add then
            --     self.TargetPanel:Close()
            -- end
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
        end)
end

function XUiReformTargetGrid:OnClicked()
    local targets = self.Source:GetTargets()
    local index = 1
    for i, v in ipairs(targets) do
        if v == self.Target then
            index = i
            break
        end
    end
    XLuaUiManager.Open("UiReformRoleList", targets, index)
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
    self.GridMember.gameObject:SetActiveEx(false)
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
            , self.BaseStage, self.EvolvableStage, self, self.Source)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:DynamicTouched(self.Source)
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
    self.TxtCount.text = CsXTextManager.GetText("ReformMemberAddCountText", data.emptyPosCount)
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
    self.UiReformAwarenessGrid1 = XUiReformAwarenessGrid.New(self.GridAwareness1)
    self.UiReformAwarenessGrid2 = XUiReformAwarenessGrid.New(self.GridAwareness2)
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
    self.TxtName.text = source:GetLogName()
    self.RImgIcon:SetRawImage(source:GetBigHeadIcon())
    self.TxtStar.text = source:GetStarLevel()
    self.TxtCost.text = score
    -- 显示意识数据
    local showInfos = self.Data:GetShowAwarenessViewModelInfos()
    local UiReformAwarenessGrid, showInfo
    for i = 1, 2 do
        showInfo = showInfos[i]
        UiReformAwarenessGrid = self["UiReformAwarenessGrid" .. i]
        UiReformAwarenessGrid.GameObject:SetActiveEx(showInfo ~= nil)
        if showInfo then
            UiReformAwarenessGrid:SetData(showInfo.value.showViewModel)
            UiReformAwarenessGrid:SetCountText(CsXTextManager.GetText("ReformAwarenessSuitText", showInfo.value.count))
            UiReformAwarenessGrid:SetCharacterViewModel(source:GetCharacterViewModel())
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
end

function XUiReformSourceGrid:OnBtnReformClicked()
    -- 如果没有改造目标，不处理
    if #self.Data:GetTargets() <= 0 then
        return
    end
    self.SourcePanel:OpenTargetReformPanel(self.Data)
    self.SourcePanel:OnSourceGridClicked(self.Index)
end

function XUiReformSourceGrid:OnBtnClickClicked()
    local sources = self.SourcePanel:GetSources()
    local index = 1
    for i, v in ipairs(sources) do
        if v == self.Data then
            index = i
            break
        end
    end
    -- 显示角色详情
    XLuaUiManager.Open("UiReformRoleList", sources, index)
end

--######################## XUiReformMemberPanel ########################
local XUiReformMemberPanel = XClass(nil, "XUiReformMemberPanel")

function XUiReformMemberPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BaseStage = nil
    self.EvolvableStage = nil
    self.EvolvableGroup = nil
    -- 动态列表
    self.GridMember.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelMemberList)
    self.DynamicTable:SetProxy(XUiReformSourceGrid)
    self.DynamicTable:SetDelegate(self)
    -- 改造面板
    self.UiReformTargetPanel = XUiReformTargetPanel.New(self.PanelReform, self)
    self.TxtTip.text = CsXTextManager.GetText("ReformMemberPanelTopTip")
    self.BtnCloseReform.gameObject:SetActiveEx(false)
    self.TxtTip2.text = CsXTextManager.GetText("ReformMemberPanelTopEvolableTip")
    self:RegisterUiEvents()
end

function XUiReformMemberPanel:SetData(baseStage, evolvableStage)
    self.BaseStage = baseStage
    self.EvolvableStage = evolvableStage
    self.EvolvableGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
    -- 刷新源列表
    self:RefreshDynamicTable()
    self:CloseTargetReformPanel()
end

function XUiReformMemberPanel:RefreshEvolvableData()
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
    self.UiReformTargetPanel:Refresh()
end

function XUiReformMemberPanel:OpenTargetReformPanel(source)
    self.UiReformTargetPanel:Open()
    self.UiReformTargetPanel:SetData(source, self.BaseStage, self.EvolvableStage)
    self.BtnCloseReform.gameObject:SetActiveEx(true)
end

function XUiReformMemberPanel:CloseTargetReformPanel()
    self.UiReformTargetPanel:Close()
    self.BtnCloseReform.gameObject:SetActiveEx(false)
end

function XUiReformMemberPanel:SetBtnCloseReformActive(value)
    self.BtnCloseReform.gameObject:SetActiveEx(value)
end

function XUiReformMemberPanel:SetScrollListControl(value)
    if value then
        self.PanelMemberList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        self.PanelMemberList.horizontal = true
    else
        self.PanelMemberList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        self.PanelMemberList.horizontal = false
    end  
end

--######################## 私有方法 ########################

function XUiReformMemberPanel:RegisterUiEvents()
    self.BtnCloseReform.CallBack = function() self:OnBtnCloseReformClicked() end
end

function XUiReformMemberPanel:OnBtnCloseReformClicked()
    self:CloseTargetReformPanel()
end

function XUiReformMemberPanel:RefreshDynamicTable(sources)
    sources = sources or self:GetSourcesWithEntity()
    self.DynamicTable:SetDataSource(sources)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiReformMemberPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.DynamicTable.DataSource[index], index, self)
    end
end

function XUiReformMemberPanel:GetSourcesWithEntity()
    local entities, nextAddSource, emptyPosCount = self.EvolvableGroup:GetSourcesWithEntity()
    if nextAddSource then
        table.insert(entities, 1, {
            source = nextAddSource,
            emptyPosCount = emptyPosCount,
            isAddEntity = true,
            -- 引导Id
            Id = nextAddSource:GetId()
        })
    end
    return entities
end

function XUiReformMemberPanel:GetSources()
    return self.EvolvableGroup:GetSourcesWithEntity()
end

function XUiReformMemberPanel:GetSourceIndex(source)
    local sources = self:GetSources()
    for i, v in ipairs(sources) do
        if v == source then
            return i
        end
    end
    return 1
end

function XUiReformMemberPanel:OnSourceGridClicked(index)
    self:SetSelectedGrid(index)
    self:ScrollGrid(index)
end

function XUiReformMemberPanel:PlaySourceGridRefreshAnim(index)
    local grid = self.DynamicTable:GetGrids()[index]
    if not grid then return end
    grid:PlayRefreshAnim()
end

function XUiReformMemberPanel:SetSelectedGrid(index)
    for i, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetSelectStatus(i == index)
    end
end

function XUiReformMemberPanel:ScrollGrid(index)
    local grids = self.DynamicTable:GetGrids()
    local grid = grids[index]
    if not grid then 
        self.DynamicTable:ReloadDataSync(index)
        return 
    end
    self:SetScrollListControl(false)
    local distance = (grid.Transform.localPosition + self.PanelMemberListContent.localPosition).x * -1
    if distance >= XReformConfigs.MinDistance and distance <= XReformConfigs.MaxDistance then return end
    local targetPos = self.PanelMemberListContent.localPosition
    if index == 1 then
        targetPos.x = math.min(self.PanelMemberListContent.rect.width / 2 - self.PanelMemberListContent.parent.rect.width / 2)
                - self.PanelMemberListContent.rect.width / 2
    else
        targetPos.x = targetPos.x + distance - grid.Transform.rect.width / 2 - XReformConfigs.ScrollOffset
    end
    XUiHelper.DoMove(self.PanelMemberListContent, targetPos, XReformConfigs.ScrollTime, XUiHelper.EaseType.Sin)
end

return XUiReformMemberPanel