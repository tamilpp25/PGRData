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
        self.TxtMemberLevel.text = source:GetStarLevel()
        self.RImgMemberIcon:SetRawImage(source:GetIcon())
        self.MemberTag.gameObject:SetActiveEx(source:GetIsActive() and source:GetEntityType() == XReformConfigs.EntityType.Entity)
        self.MemberTagNew.gameObject:SetActiveEx(source:GetIsActive() and source:GetEntityType() == XReformConfigs.EntityType.Add)
    elseif reformType == XReformConfigs.EvolvableGroupType.Enemy then
        self.TxtLevel.text = source:GetShowLevel()
        self.RImgIcon:SetRawImage(source:GetIcon())
        self.Tag.gameObject:SetActiveEx(source:GetIsActive() and source:GetEntityType() == XReformConfigs.EntityType.Entity)
        self.TagNew.gameObject:SetActiveEx(source:GetIsActive() and source:GetEntityType() == XReformConfigs.EntityType.Add)
    end
    if self.GridBuff then
        self.GridBuff.gameObject:SetActiveEx(reformType == XReformConfigs.EvolvableGroupType.Buff)
    end
    if self.GridChar then
        self.GridChar.gameObject:SetActiveEx(reformType == XReformConfigs.EvolvableGroupType.Member)
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
    self.TxtNone.gameObject:SetActiveEx(value)
end

function XUiReformPreviewPanel:SetScoreTips(currentScore, maxScore)
    if maxScore ~= nil then
        self.TxtScoreTip.text = string.format( "<color=#3B9FFF>%s</color> / %s", currentScore, maxScore)
    else
        self.TxtScoreTip.text = string.format( "<color=#F15764>%s</color>", currentScore)
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
    -- 敌人
    self.UiReformPreviewEnemyPanel = XUiReformPreviewPanel.New(self.PanelEnemy)
    -- -- 成员
    -- self.UiReformPreviewMemberPanel = XUiReformPreviewPanel.New(self.PanelChar)
    -- -- 环境和buff
    -- self.UiReformPreviewEffectPanel = XUiReformPreviewPanel.New(self.PanelBuff)
    -- 环境
    self.UiReformPreviewEnvPanel = XUiReformPreviewPanel.New(self.PanelEnv)
    -- 成员和buff
    self.UiReformPreviewMemberAndBuffPanel = XUiReformPreviewPanel.New(self.PanelMemberAndBuff)
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
    -- 敌人预览
    local enemyGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Enemy)
    local enemies = enemyGroup:GetSourcesWithEntity(false)
    self.UiReformPreviewEnemyPanel:SetData(enemies, CsXTextManager.GetText("ReformEvolvableEnemyNameText"))
    self.UiReformPreviewEnemyPanel:SetScoreTips(enemyGroup:GetChallengeScore(), enemyGroup:GetMaxChallengeScore())
    self.UiReformPreviewEnemyPanel:SetNoneTextActive(#enemies <= 0)
    -- 环境预览
    local envIds = evolvableStage:GetEnvIds()
    local environmentGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Environment)
    local environments = {}
    for _, envId in ipairs(envIds) do
        table.insert(environments, environmentGroup:GetEnvironmentById(envId))
    end
    self.UiReformPreviewEnvPanel:SetData(environments, CsXTextManager.GetText("ReformEvolvableEnvNameText"))
    if environmentGroup then
        self.UiReformPreviewEnvPanel:SetScoreTips(environmentGroup:GetChallengeScore(), environmentGroup:GetMaxChallengeScore())
    else
        self.UiReformPreviewEnvPanel:SetScoreTips(0, 0)
    end
    self.UiReformPreviewEnvPanel:SetNoneTextActive(#environments <= 0)
    -- 成员和buff
    local memberGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
    local buffGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Buff)
    local entities = memberGroup:GetSourcesWithEntity(false)
    local buffIds = evolvableStage:GetBuffIds()
    for _, buffId in ipairs(buffIds) do
        table.insert(entities, buffGroup:GetBuffById(buffId))
    end
    self.UiReformPreviewMemberAndBuffPanel:SetData(entities, string.format("%s/%s", CsXTextManager.GetText("ReformEvolvableMemberNameText"), CsXTextManager.GetText("ReformEvolvableBuffNameText")))
    self.UiReformPreviewMemberAndBuffPanel:SetScoreTips(memberGroup:GetChallengeScore() 
        + (buffGroup and buffGroup:GetChallengeScore() or 0))
    self.UiReformPreviewMemberAndBuffPanel:SetNoneTextActive(#entities <= 0)
    -- 分数提示
    self.TxtScoreTip.text = string.format( "<color=#3B9FFF>%s</color> / %s"
        , evolvableStage:GetChallengeScore()
        , evolvableStage:GetMaxChallengeScore())
end

--######################## 私有方法 ########################

function XUiReformPreview:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
end

return XUiReformPreview