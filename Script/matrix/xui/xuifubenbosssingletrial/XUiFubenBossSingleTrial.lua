---@class XUiFubenBossSingleTrial : XLuaUi
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleTrial = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleTrial")

local XUiGridBossEXSection = require("XUi/XUiFubenBossSingleTrial/XUiGridBossTrialSection")
local ACHIEVEMENT_FIGHT = 1
local FUBEN_BOSS_SINGLE_TAG = 2
-- 体验版囚笼
function XUiFubenBossSingleTrial:OnAwake()
    self:_RegisterButtonClicks()
    self:_InitDynamicTable()
    self:_InitTabGroup()
    self:_HideEffect()
end

function XUiFubenBossSingleTrial:OnStart()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiFubenBossSingleTrial:OnEnable()
    self:PlayAnimation("AnimEnable")
    self.BtnTrial:ShowReddot(XDataCenter.AchievementManager.CheckHasRewardByType(FUBEN_BOSS_SINGLE_TAG))
end

function XUiFubenBossSingleTrial:_HideEffect()
    local root = self.UiModelGo.transform
    local imgEffect = root:FindTransform("ImgEffectHuanren")
    local imgEffectHide = root:FindTransform("ImgEffectHuanren1")

    if imgEffect then
        imgEffect.gameObject:SetActiveEx(false)
    end
    if imgEffectHide then
        imgEffectHide.gameObject:SetActiveEx(false)
    end
end

function XUiFubenBossSingleTrial:_RegisterButtonClicks()
    self:RegisterClickEvent(self.BtnTrial, self.OnBtnTrialClick, true)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick, true)
    self:BindHelpBtn(self.BtnHelp, "BossSingle")
end

--初始化关卡入口动态列表
function XUiFubenBossSingleTrial:_InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewStage)
    self.DynamicTable:SetProxy(XUiGridBossEXSection, self)
    self.DynamicTable:SetDelegate(self)
    self.GridSectionBoss.gameObject:SetActive(false)
end

--初始化难度区域选择按钮
function XUiFubenBossSingleTrial:_InitTabGroup()
    self._BtnTabList = {
        self.BtnTog1,
        self.BtnTog2,
        self.BtnTog3,
        self.BtnTog4,
    }

    --设置Togge按钮
    local defaultSelectIndex = #self._BtnTabList

    self.GroupTab:Init(self._BtnTabList, Handler(self, self.OnClickTabCallBack))
    self.GroupTab:SelectIndex(defaultSelectIndex)

    -- 检查是否有配置该区域 并隐藏按钮
    for index = 1, #self._BtnTabList do
        local isHide = self._Control:CheckHasTrialGradeConfigByType(index)
        if not isHide then
            self._BtnTabList[index].gameObject:SetActive(false)
        end
    end
end

function XUiFubenBossSingleTrial:_ShowBossDetail(bossId)
    XLuaUiManager.Open("UiFubenBossSingleTrialDetail", bossId)
end

function XUiFubenBossSingleTrial:OnBtnTrialClick()
    XLuaUiManager.Open("UiAchievement", ACHIEVEMENT_FIGHT)
    XEventManager.DispatchEvent(XEventId.EVENT_ACHIEVEMENT_CHANGE_INDEX, FUBEN_BOSS_SINGLE_TAG)
end

function XUiFubenBossSingleTrial:OnClickTabCallBack(index)
    if self._CurrSelectIndex == index then
        return
    end
    -- 选择读取不同区域关卡数据刷新列表
    local currSingeExGradeConfig = self._Control:GetBossSingleTrialGradeConfigByType(index)
    local currSectionConfig = currSingeExGradeConfig.SectionId
    self._CurrSelectAreaSectionData = {}
    -- 排序
    for i = 1, #currSectionConfig do
        table.insert(self._CurrSelectAreaSectionData,
            { SectionId = currSectionConfig[i], Order = currSingeExGradeConfig.Order[i] })
    end
    table.sort(self._CurrSelectAreaSectionData, function(a, b)
        return a.Order < b.Order
    end)

    -- 刷新列表
    self.DynamicTable:SetDataSource(self._CurrSelectAreaSectionData)
    self.DynamicTable:ReloadDataSync()
    self._CurrSelectIndex = index
end

--动态列表事件
function XUiFubenBossSingleTrial:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local sectionId = self._CurrSelectAreaSectionData[index].SectionId
        grid:Refresh(sectionId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local sectionId = self._CurrSelectAreaSectionData[index].SectionId
        self:_ShowBossDetail(sectionId)
    end
end

function XUiFubenBossSingleTrial:OnBtnBackClick()
    self:Close()
end

function XUiFubenBossSingleTrial:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiFubenBossSingleTrial
