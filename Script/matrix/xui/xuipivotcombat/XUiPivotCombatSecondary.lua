--===========================================================================
 ---@desc 枢纽作战--次级作战界面
--===========================================================================
local XUiPivotCombatSecondary = XLuaUiManager.Register(XLuaUi, "UiPivotCombatSecondary")
local XUiPivotCombatChapterGrid = require("XUi/XUiPivotCombat/XUiGrid/XUiPivotCombatChapterGrid")

local MAX_STAGE_MEMBER = 3 --最大的关卡数量

-- 滑动列表滑动类型
local MovementType = {
    Elastic         = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic,
    Unrestricted    = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted,
    Clamped         = CS.UnityEngine.UI.ScrollRect.MovementType.Clamped,
}

function XUiPivotCombatSecondary:OnAwake()
    self:InitUI()
    self:InitCB()
end 

function XUiPivotCombatSecondary:OnStart(region)
    self.Region = region
    --标题
    self.TxtTitle.text = self.Region:GetRegionName()
    --供能图标
    self.Btn01:SetRawImage(self.Region:GetIcon())
    self.StageGridList = {}
    
    --初始化资产
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.PivotCombatManager.GetActivityCoinId())
    --关卡数据
    self.StageList = region:GetStageList()
    
    self:SetScrollMoveType(MovementType.Elastic)
    --背景
    self.Background:SetRawImage(region:GetSecondaryRegionBg())

    XEventManager.AddEventListener(XEventId.EVENT_PIVOTCOMBAT_ENERGY_REFRESH, self.RefreshEnergy, self)

    local timeOfEnd = XDataCenter.PivotCombatManager.GetActivityEndTime()
    self:SetAutoCloseInfo(timeOfEnd, function(isClose)
        if isClose then
            XDataCenter.PivotCombatManager.OnActivityEnd()
        end
        XDataCenter.PivotCombatManager.CheckNeedClose()
    end)
end 

function XUiPivotCombatSecondary:OnEnable()
    XUiPivotCombatSecondary.Super.OnEnable(self)
    
    self.TxtTitleDate.text = self.Region:GetRegionLeftTime()
    self:RefreshEnergy()
    
    for index, stage in ipairs(self.StageList) do
        --超过了提供的最大关卡数量
        if index > MAX_STAGE_MEMBER then break end
        --关卡线 (1 ~ MAX_STAGE_MEMBER - 1)
        if index < MAX_STAGE_MEMBER then
            self["Line"..index].gameObject:SetActiveEx(stage:GetPassed())
        end
        
        local item = self.StageGridList[index]
        if not item then
            item = XUiPivotCombatChapterGrid.New(self["Stage"..index], self.Region, stage:CheckIsLockCharacterStage(), handler(self, self.OnOpenDetail))
        end
        item:Refresh(stage)
        self.StageGridList[index] = item
    end
end 

function XUiPivotCombatSecondary:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_PIVOTCOMBAT_ENERGY_REFRESH, self.RefreshEnergy, self)
end

function XUiPivotCombatSecondary:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET, XEventId.EVENT_PIVOTCOMBAT_ACTIVITY_END }
end

function XUiPivotCombatSecondary:OnNotify(evt, ...)
    local args = { ... }
    XDataCenter.PivotCombatManager.OnNotify(evt, args)
end

function XUiPivotCombatSecondary:RefreshEnergy()
    --刷新文字条显示
    local curEnergyLv = self.Region:GetCurSupplyEnergy()
    local maxEnergyLv = self.Region:GetMaxSupplyEnergy()
    self.TxtEffect.text = CS.XTextManager.GetText("PivotCombatAreaEnergy", curEnergyLv, maxEnergyLv)
    --刷新进度条显示
    self.EnergyProgressRegion.fillAmount = self.Region:GetPercentEnergy()
end

function XUiPivotCombatSecondary:InitUI()
    for idx = 1, MAX_STAGE_MEMBER do
        local stage = self.PanelStageContent:Find("Stage"..idx)
        local line = self.PanelStageContent:Find("Line"..idx)
        if stage then
            stage.gameObject:SetActiveEx(false)
        end
        if line then
            line.gameObject:SetActiveEx(false)
        end
        
        self["Stage"..idx] = stage
        self["Line"..idx] = line
    end
    self.Background = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/Bg", "RawImage")
end 

function XUiPivotCombatSecondary:InitCB()
    self.SceneBtnBack.CallBack = function() 
        self:Close()
    end
    self.SceneBtnMainUi.CallBack = function() 
        XLuaUiManager.RunMain()
    end
    self.BtnEffect.CallBack = function()
        --XLuaUiManager.Open("UiPivotCombatEffectArea", self.Region)
        self:OpenOneChildUi("UiPivotCombatEffectArea", self.Region)
    end
    self.BtnGuide.CallBack = function()
        XLuaUiManager.Open("UiBattleRoleRoom", XPivotCombatConfigs.DynamicScoreTeachStageId)
    end
    
    self:BindHelpBtn(self.BtnHelp, "PivotCombatSecondaryHelp")
end 

function XUiPivotCombatSecondary:OnOpenDetail(region, stage, gridTransform, OnRetreatCb)
    self:OpenOneChildUi("UiPivotCombatSecondaryDetail", region, stage, handler(self, self.OnScrollViewDoMoveCenter), OnRetreatCb)
    self:OnScrollViewDoMove(gridTransform)
end 

--点击chapter滑动到屏幕左侧，回调
function XUiPivotCombatSecondary:OnScrollViewDoMove(gridTransform)
    local gridRect = gridTransform:GetComponent("RectTransform")
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local targetPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridRect.localPosition.x
        local targetPos = self.PanelStageContent.localPosition
        targetPos.x = targetPosX
        XLuaUiManager.SetMask(true)
        self.LastLocalPosition = XTool.Clone(self.PanelStageContent.localPosition)
        self:SetScrollMoveType(MovementType.Unrestricted)
        XUiHelper.DoMove(self.PanelStageContent, targetPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function() 
            XLuaUiManager.SetMask(false)
        end)
    end
end

--关闭chapter详情滑动到屏幕左侧，回调
function XUiPivotCombatSecondary:OnScrollViewDoMoveCenter()
    self:SetScrollMoveType(MovementType.Elastic)
    --if self.LastLocalPosition then
    --    XLuaUiManager.SetMask(true)
    --    XUiHelper.DoMove(self.PanelStageContent, self.LastLocalPosition, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
    --        XLuaUiManager.SetMask(false)
    --        handler(self, self.SetScrollMoveType)(MovementType.Elastic)
    --    end)
    --end
end

--设置滑动列表滑动类型
function XUiPivotCombatSecondary:SetScrollMoveType(type)
    type = type or MovementType.Elastic
    if self.PaneStageList then
        self.PaneStageList.movementType = type
    end
end