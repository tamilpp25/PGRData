--######################## XUiEnemyGrid ########################
local XUiEnemyGrid = XClass(nil, "XUiEnemyGrid")

function XUiEnemyGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.EnemySource = nil
    self.RootUi = rootUi
    self.BtnClick.CallBack = function() self:OnBtnClicked() end
end

function XUiEnemyGrid:SetData(data)
    self.EnemySource = data
    self.TxtLevel.text = data:GetShowLevel()
    self.RImgIcon:SetRawImage(data:GetIcon())
    self.Tag.gameObject:SetActiveEx(data:GetIsActive() and data:GetEntityType() == XReformConfigs.EntityType.Entity)
    self.TagNew.gameObject:SetActiveEx(data:GetIsActive() and data:GetEntityType() == XReformConfigs.EntityType.Add)
end

function XUiEnemyGrid:OnBtnClicked()
    local buffDatas = self.EnemySource:GetBuffDetailViewModels()
    if #buffDatas > 0 then
        self.RootUi:StopAutoCloseTimer()
        XLuaUiManager.Open("UiReformBuffTips", buffDatas, nil, XUiHelper.GetText("ReformEnemyBuffTipsTitle")
        , function()
            self.RootUi:StartAutoCloseTimer()
        end)
    end
end

--######################## XUiEnemyGrid ########################
local XUiEnvironmentGrid = XClass(nil, "XUiEnvironmentGrid")

function XUiEnvironmentGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Environment = nil
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    self.BtnClick.CallBack = function() self:OnBtnClicked() end
end

function XUiEnvironmentGrid:SetData(data)
    self.Environment = data
    self.ImgIcon:SetSprite(data:GetPreviewIcon())
    -- self.EnvTag.gameObject:SetActiveEx(source:GetIsActive())
    self.Tag.gameObject:SetActiveEx(false)
    self.TxtScene.text = data:GetPreviewText()
end

function XUiEnvironmentGrid:OnBtnClicked()
    self.RootUi:StopAutoCloseTimer()
    local environmentViewModels = {}
    for _, env in ipairs(self.RootUi:GetEnvironments()) do
        table.insert(environmentViewModels, env:GetViewModel())
    end
    XLuaUiManager.Open("UiReformBuffTips", environmentViewModels, true, XUiHelper.GetText("ReformEnvBattlePreviewTitie")
    , function()
        self.RootUi:StartAutoCloseTimer()
    end)
end

--######################## XUiReformBattlePreview ########################
local XUiReformBattlePreview = XLuaUiManager.Register(XLuaUi, "UiReformPreview2")

local INTERVAL = 0.1

function XUiReformBattlePreview:OnAwake()
    self.Team = nil
    self.StageId = nil
    self.Time = 0
    self.ReformManager = XDataCenter.ReformActivityManager
    self.Environments = nil
end

function XUiReformBattlePreview:OnStart(team, stageId)
    self.Time = self.ReformManager.GetPreviewCloseTime()
    self.Team = team
    self.StageId = stageId
    self:RefreshTime()
    self:SetAutoCloseInfo(XTime.GetServerNowTimestamp() + self.Time, function(isClose)
        self:HandleAutoClose(isClose)
    end, INTERVAL * 1000, INTERVAL * 1000)
    -- 刷新敌人列表
    self:RefreshEnemies()
    -- 刷新环境列表
    self:RefreshEnvironments()
    local baseStage = self.ReformManager.GetBaseStage(self.StageId)
    self.TxtNameTitle.text = XUiHelper.GetText("ReformReadyTitleText", baseStage:GetName()
    , baseStage:GetCurrentEvolvableStage():GetName())
end

function XUiReformBattlePreview:GetEnvironments()
    return self.Environments
end

function XUiReformBattlePreview:StartAutoCloseTimer()
    self:SetAutoCloseInfo(XTime.GetServerNowTimestamp() + self.Time, function(isClose)
        self:HandleAutoClose(isClose)
    end, INTERVAL * 1000, INTERVAL * 1000)
    self:_StartAutoCloseTimer()
end

function XUiReformBattlePreview:StopAutoCloseTimer()
    self:_StopAutoCloseTimer()
end

function XUiReformBattlePreview:OnEnable()
    XUiReformBattlePreview.Super.OnEnable(self)
end

function XUiReformBattlePreview:OnDisable()
    XUiReformBattlePreview.Super.OnDisable(self)
end

--######################## 私有方法 ########################

function XUiReformBattlePreview:HandleAutoClose(isClose)
    -- 到期了直接回主界面
    if not self.ReformManager.GetIsOpen() then
        self.ReformManager.HandleActivityEndTime()
        return
    end
    if isClose then
        self:Remove()
        self:EnterFight()
    else
        self.Time = self.Time - INTERVAL
        self:RefreshTime()
    end
end

function XUiReformBattlePreview:RefreshEnemies()
    local evolvableStage = self.ReformManager.GetBaseStage(self.StageId):GetCurrentEvolvableStage()
    local enemyGroups = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Enemy)
    XUiHelper.RefreshCustomizedList(self.PanelEnmyContent, self.PanelEnmyGroup, #enemyGroups, function(index, go)
        local group = enemyGroups[index]
        if not group:GetIsActive() then
            go.gameObject:SetActiveEx(false)
            return
        end
        local uiObj = go.transform:GetComponent("UiObject")
        uiObj:GetObject("TxtGroup").text = XUiHelper.GetText("ReformEnemyGroupName" .. index)
        local enemies = group:GetSourcesWithEntity(false)
        XUiHelper.RefreshCustomizedList(uiObj:GetObject("PanelContent"), uiObj:GetObject("GridEnemy")
            , #enemies, function(enemyIndex, enemyGridGo)
                XUiEnemyGrid.New(enemyGridGo, self):SetData(enemies[enemyIndex])
            end)
    end)
end

function XUiReformBattlePreview:RefreshEnvironments()
    local evolvableStage = self.ReformManager.GetBaseStage(self.StageId):GetCurrentEvolvableStage()
    local envIds = evolvableStage:GetEnvIds()
    local environmentGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Environment)
    local environments = {}
    for _, envId in ipairs(envIds) do
        table.insert(environments, environmentGroup:GetEnvironmentById(envId))
    end
    self.GridScene.gameObject:SetActiveEx(false)
    local go, grid
    for i = 1, #environments do
        go = CS.UnityEngine.Object.Instantiate(self.GridScene, self.PanelEnv)
        go.gameObject:SetActiveEx(true)
        grid = XUiEnvironmentGrid.New(go, self)
        grid:SetData(environments[i])
    end
    self.PanelEnvNone.gameObject:SetActiveEx(#environments <= 0)
    self.Environments = environments
end

function XUiReformBattlePreview:RefreshTime()
    self.TxtTime.text = XUiHelper.GetText("ReformBattlePreviewTime", math.ceil(math.max(0, self.Time)))
end

function XUiReformBattlePreview:EnterFight()
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local teamId = self.Team:GetId()
    local isAssist = false 
    local challengeCount = 1
    XDataCenter.FubenManager.EnterFight(stageConfig, teamId, isAssist, challengeCount, nil, function(res)
        if res.Code == XReformConfigs.EndTimeCode then
            self.ReformManager.HandleActivityEndTime()
        end
    end)
end

return XUiReformBattlePreview
