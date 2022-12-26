local CsXTextManager = CS.XTextManager

--######################## XUiReformPreviewGrid ########################
local XUiReformPreviewGrid = XClass(nil, "XUiReformPreviewGrid")

function XUiReformPreviewGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    -- XReformEnemySource | XReformMemberSource
    -- | XReformEnvironment | XReformBuff
    self.Source = nil
end

-- source : XReformEnemySource | XReformMemberSource
-- | XReformEnvironment | XReformBuff
function XUiReformPreviewGrid:SetData(source)
    self.Source = source
    local reformType = source:GetReformType()
    if reformType == XReformConfigs.EvolvableGroupType.Buff then
        self.TxtBuffLevel.text = source:GetStarLevel()
        self.RImgBuffIcon:SetRawImage(source:GetIcon())
        -- self.BuffTag.gameObject:SetActiveEx(source:GetIsActive())
        self.BuffTag.gameObject:SetActiveEx(false)
    elseif reformType == XReformConfigs.EvolvableGroupType.Environment then
        self.ImgEnvIcon:SetSprite(source:GetPreviewIcon())
        -- self.EnvTag.gameObject:SetActiveEx(source:GetIsActive())
        self.EnvTag.gameObject:SetActiveEx(false)
        self.TxtScene.text = source:GetPreviewText()
    elseif reformType == XReformConfigs.EvolvableGroupType.Member then
        self.TxtLevel.text = source:GetStarLevel()
        self.RImgIcon:SetRawImage(source:GetIcon())
        self.Tag.gameObject:SetActiveEx(source:GetIsActive() and source:GetEntityType() == XReformConfigs.EntityType.Entity)
        self.TagNew.gameObject:SetActiveEx(source:GetIsActive() and source:GetEntityType() == XReformConfigs.EntityType.Add)
    elseif reformType == XReformConfigs.EvolvableGroupType.Enemy then
        self.TxtLevel.text = source:GetShowLevel()
        self.RImgIcon:SetRawImage(source:GetIcon())
        self.Tag.gameObject:SetActiveEx(source:GetIsActive() and source:GetEntityType() == XReformConfigs.EntityType.Entity)
        self.TagNew.gameObject:SetActiveEx(source:GetIsActive() and source:GetEntityType() == XReformConfigs.EntityType.Add)
    end
    if self.GridBuff then
        self.GridBuff.gameObject:SetActiveEx(reformType == XReformConfigs.EvolvableGroupType.Buff)
    end
    if self.GridScene then
        self.GridScene.gameObject:SetActiveEx(reformType == XReformConfigs.EvolvableGroupType.Environment)
    end
end

--######################## XUiReformPreviewPanel ########################
local XUiReformPreviewPanel = XClass(nil, "XUiReformPreviewPanel")

function XUiReformPreviewPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    -- XReformEnemySource | XReformMemberSource
    -- | XReformEnvironment | XReformBuff
    self.Sources = nil
    XTool.InitUiObject(self)
    self.DynamicTable = XDynamicTableNormal.New(self.DataList)
    self.DynamicTable:SetProxy(XUiReformPreviewGrid)
    self.DynamicTable:SetDelegate(self)
end

-- sources : XReformEnemySource | XReformMemberSource
-- | XReformEnvironment | XReformBuff
function XUiReformPreviewPanel:SetData(sources, title)
    self.TxtTitle.text = title
    self.Sources = sources
    self:RefreshDynamicTable()
end

function XUiReformPreviewPanel:SetNoneTextActive(value)
    if self.TxtNone then
        self.TxtNone.gameObject:SetActiveEx(value)
    end
end

function XUiReformPreviewPanel:RefreshDynamicTable()
    self.DynamicTable:SetDataSource(self.Sources)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiReformPreviewPanel:OnDynamicTableEvent(event, index, grid)
    local source = self.Sources[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(source)
    end
end

--######################## XUiReformPreview ########################
local XUiReformPreview = XLuaUiManager.Register(XLuaUi, "UiReformPreview")

function XUiReformPreview:OnAwake()
    -- XReformEvolvableStage
    self.EvolvableStage = nil
    self:RegisterUiEvents()
    self.UiReformPreviewEnemyPanel = XUiReformPreviewPanel.New(self.PanelEnemy)
    self.UiReformPreviewMemberPanel = XUiReformPreviewPanel.New(self.PanelChar)
    self.UiReformPreviewEffectPanel = XUiReformPreviewPanel.New(self.PanelBuff)
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem
        , XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    -- 自动关闭
    local endTime = XDataCenter.ReformActivityManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.ReformActivityManager.HandleActivityEndTime()
        end
    end)
end

-- evolvableStage : XReformEvolvableStage
function XUiReformPreview:OnStart(evolvableStage)
    self.EvolvableStage = evolvableStage
    local enemyGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Enemy)
    self.UiReformPreviewEnemyPanel:SetData(enemyGroup:GetSourcesWithEntity(false), CsXTextManager.GetText("ReformEvolvableEnemyNameText"))
    local memberGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
    self.UiReformPreviewMemberPanel:SetData(memberGroup:GetSourcesWithEntity(false), CsXTextManager.GetText("ReformEvolvableMemberNameText"))
    local envIds = evolvableStage:GetEnvIds()
    local buffIds = evolvableStage:GetBuffIds()
    local environmentGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Environment)
    local buffGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Buff)
    local effects = {}
    for _, envId in ipairs(envIds) do
        table.insert(effects, environmentGroup:GetEnvironmentById(envId))
    end
    for _, buffId in ipairs(buffIds) do
        table.insert(effects, buffGroup:GetBuffById(buffId))
    end
    self.UiReformPreviewEffectPanel:SetData(effects, string.format("%s/%s", CsXTextManager.GetText("ReformEvolvableEnvNameText"), CsXTextManager.GetText("ReformEvolvableBuffNameText")))
    self.UiReformPreviewEffectPanel:SetNoneTextActive(#effects <= 0)
end

--######################## 私有方法 ########################

function XUiReformPreview:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
end

return XUiReformPreview