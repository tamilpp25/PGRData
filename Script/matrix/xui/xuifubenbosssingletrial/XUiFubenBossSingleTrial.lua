local XUiFubenBossSingleTrial = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleTrial")

local XUiGridBossEXSection = require("XUi/XUiFubenBossSingleTrial/XUiGridBossTrialSection")
local XUiPanelBossDetail = require("XUi/XUiFubenBossSingleTrial/XUiPanelBossTrialDetail")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

-- 体验版囚笼
function XUiFubenBossSingleTrial:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()
    self:InitTabGroup()
    local root = self.UiModelGo.transform
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanrenHideBoss = root:FindTransform("ImgEffectHuanren1")
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanrenHideBoss.gameObject:SetActiveEx(false)
    self.RoleModelPanel = XUiPanelRoleModel.New(root:FindTransform("PanelRoleModel"), self.Name, nil, true)
end

function XUiFubenBossSingleTrial:OnStart()
    XDataCenter.FubenBossSingleManager.SetBossSingleTrial(false)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA, self.OnSyncBossData, self)

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BossDetail = XUiPanelBossDetail.New(self, self.PanelBossDetail)
end

function XUiFubenBossSingleTrial:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA, self.OnSyncBossData, self)
end

function XUiFubenBossSingleTrial:OnEnable()
    self:PlayAnimation("AnimEnable")
end

function XUiFubenBossSingleTrial:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "BossSingle")
end

--初始化难度区域选择按钮
function XUiFubenBossSingleTrial:InitTabGroup()
    self.BtnTabList = 
    {
        self.BtnTog1,
        self.BtnTog2,
        self.BtnTog3,
        self.BtnTog4,
    }

    --设置Togge按钮
    self.GroupTab:Init(self.BtnTabList, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    local defaultSelectIndex = #self.BtnTabList
    self.GroupTab:SelectIndex(defaultSelectIndex)

    -- 检查是否有配置该区域 并隐藏按钮
    for index = 1, #self.BtnTabList do
        local currSingeExGradeConfig = XDataCenter.FubenBossSingleManager.GetBossSingleTrialGradeCfg()[index]
        if not currSingeExGradeConfig then
            self.BtnTabList[index].gameObject:SetActive(false)
        end
    end
end

function XUiFubenBossSingleTrial:OnClickTabCallBack(index)
    if self.CurrSelectIndex == index then
        return
    end
    -- 选择读取不同区域关卡数据刷新列表
    local currSingeExGradeConfig = XDataCenter.FubenBossSingleManager.GetBossSingleTrialGradeCfg()[index]
    local currSectionConfig = currSingeExGradeConfig.SectionId
    self.CurrSelectAreaSectionData = {}
    -- 排序
    for i = 1, #currSectionConfig do
        table.insert(self.CurrSelectAreaSectionData , {SectionId = currSectionConfig[i], Order = currSingeExGradeConfig.Order[i]})
    end
    table.sort(self.CurrSelectAreaSectionData, function (a, b)
        return a.Order < b.Order
    end)

    -- 刷新列表
    self.DynamicTable:SetDataSource(self.CurrSelectAreaSectionData)
    self.DynamicTable:ReloadDataSync()
    self.CurrSelectIndex = index
end

--初始化关卡入口动态列表
function XUiFubenBossSingleTrial:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewStage)
    self.DynamicTable:SetProxy(XUiGridBossEXSection)
    self.DynamicTable:SetDelegate(self)
    self.GridSectionBoss.gameObject:SetActive(false)
end

--动态列表事件
function XUiFubenBossSingleTrial:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local sectionId = self.CurrSelectAreaSectionData[index].SectionId
        grid:Refresh(sectionId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local sectionId = self.CurrSelectAreaSectionData[index].SectionId
        self:ShowBossDetail(sectionId)
    end
end

function XUiFubenBossSingleTrial:OnSyncBossData()
end

function XUiFubenBossSingleTrial:OnBtnBackClick()
    XDataCenter.FubenBossSingleManager.SetBossSingleTrial(false)
    if self.BossDetail.GameObject.activeSelf then
        self:PlayAnimation("AnimEnable")
        self.RoleModelPanel:HideRoleModel()
        self.BossDetail:HidePanel()
        self.PanelShowInfo.gameObject:SetActiveEx(true)
        self.PanelContent.gameObject:SetActiveEx(true)
    else
        self:Close()
    end
end

function XUiFubenBossSingleTrial:OnBtnMainUiClick()
    XDataCenter.FubenBossSingleManager.SetBossSingleTrial(false)
    XLuaUiManager.RunMain()
end

function XUiFubenBossSingleTrial:ShowBossDetail(sectionId, grid)
    self.BossDetail:ShowPanel(self.BossSingleEXData, sectionId)
    self.PanelShowInfo.gameObject:SetActiveEx(false)
    self.PanelContent.gameObject:SetActiveEx(false)
    self.RoleModelPanel:ShowRoleModel()
end

function XUiFubenBossSingleTrial:RefreshModel(modelId, isHideBoss)
    self.RoleModelPanel:UpdateBossModel(modelId, XModelManager.MODEL_UINAME.XUiBossSingle)
    self.RoleModelPanel:ShowRoleModel()
    if isHideBoss then
        self.ImgEffectHuanrenHideBoss.gameObject:SetActiveEx(false)
        self.ImgEffectHuanrenHideBoss.gameObject:SetActiveEx(true)
    else
        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end
end
