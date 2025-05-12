local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local XUiDoubleTowersGridInfo = require("XUi/XUiDoubleTowers/XUiDoubleTowersGridInfo")

---@class XUiDoubleTowersDetail:XLuaUi
local XUiDoubleTowersDetail = XLuaUiManager.Register(XLuaUi, "UiDoubleTowersDetail")

function XUiDoubleTowersDetail:Ctor()
    self._StageId = false
    self._InfoGrids = {}
    self._RewardGrids = {}
    self.DynamicTable = false
end

function XUiDoubleTowersDetail:OnAwake()
    self:RegisterButtonClick()

    if not self.PanelScrollView then
        self.PanelScrollView = XUiHelper.TryGetComponent(self.Transform,"SafeAreaContentPane/PanelDropList/PanelScrollView")
    end
    self.DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self.DynamicTable:SetProxy(XUiDoubleTowersGridInfo)
    self.DynamicTable:SetDelegate(self)
    self.GridCommon.gameObject:SetActiveEx(false)

    XUiPanelAsset.New(
        self,
        self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint
    )
end

function XUiDoubleTowersDetail:OnEnable()
end

function XUiDoubleTowersDetail:OnDisable()
end

function XUiDoubleTowersDetail:SetStage(stageId)
    if self._StageId == stageId then
        return
    end
    self._StageId = stageId
    self:Refresh()
end

function XUiDoubleTowersDetail:Refresh()
    if not self._StageId then
        self:CloseDetailWithAnimation()
        return
    end
    -- 标题
    local stageName = XDoubleTowersConfigs.GetStageName(self._StageId)
    self.TxtTitle.text = stageName

    -- 场地提示
    local stageTip = XDoubleTowersConfigs.GetStageTip(self._StageId)
    self.TextDescribe.text = stageTip

    -- 敌人情报
    self:UpdateEnemyInfo()

    -- 奖励
    self:UpdateRewards()
end

function XUiDoubleTowersDetail:UpdateEnemyInfo()
    local infoIds = XDoubleTowersConfigs.GetInfoIdGroup(self._StageId)
    self.DynamicTable:SetDataSource(infoIds)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiDoubleTowersDetail:UpdateRewards()
    local stageId = self._StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if not stageInfo then
        return
    end
    local firstRewardShow = XFubenConfigs.GetFirstRewardShow(stageId)
    local finishRewardShow = XFubenConfigs.GetFinishRewardShow(stageId)

    -- 获取显示奖励Id
    local rewardId = 0
    local IsFirst = false
    local cfg = XDataCenter.FubenManager.GetStageCfg(stageId)

    local isStageClear = XDataCenter.DoubleTowersManager.IsStageClear(stageId)
    if not isStageClear or finishRewardShow == 0 then
        rewardId = cfg and cfg.FirstRewardShow or firstRewardShow
        if cfg and cfg.FirstRewardShow > 0 or firstRewardShow > 0 then
            IsFirst = true
        end
    end
    if rewardId == 0 then
        rewardId = cfg and cfg.FinishRewardShow or finishRewardShow
    end
    if not self._RewardGrids[1] then
        self._RewardGrids[1] = XUiGridCommon.New(self, self.GridCommonPopUp1)
    end
    if not self._RewardGrids[2] then
        self._RewardGrids[2] = XUiGridCommon.New(self, self.GridCommonPopUp2)
    end

    if rewardId == 0 then
        for j = 1, #self._RewardGrids do
            self._RewardGrids[j].GameObject:SetActive(false)
        end
        return
    end

    local rewards = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self._RewardGrids[i] then
                grid = self._RewardGrids[i]
            else
                local ui = CSUnityEngineObjectInstantiate(self.GridCommonPopUp1, self.GridCommonPopUp1.parent)
                grid = XUiGridCommon.New(self, ui)
                self._RewardGrids[i] = grid
            end
            grid:Refresh(item, {ShowReceived = isStageClear})
            grid.GameObject:SetActive(true)
        end
    end

    local rewardsCount = rewards and #rewards or 0
    for j = 1, #self._RewardGrids do
        if j > rewardsCount then
            self._RewardGrids[j].GameObject:SetActive(false)
        end
    end
end

function XUiDoubleTowersDetail:RegisterButtonClick()
    self:RegisterClickEvent(
        self.BtnEnter,
        function()
            self:EnterFight()
        end
    )
end

function XUiDoubleTowersDetail:EnterFight()
    local stageId = self._StageId
    if
        XDataCenter.DoubleTowersManager.IsStageCanChallenge(self._StageId) and
            XDataCenter.FubenManager.CheckPreFight(XDataCenter.FubenManager.GetStageCfg(stageId))
     then
        XEventManager.DispatchEvent(XEventId.EVENT_DOUBLE_TOWERS_ON_OPENED_ROOM)
        XLuaUiManager.Open("UiDoubleTowersRoom", stageId)
    end
end

function XUiDoubleTowersDetail:CloseDetailWithAnimation()
    self:Close()
end

function XUiDoubleTowersDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local infoIds = XDoubleTowersConfigs.GetInfoIdGroup(self._StageId)
        grid:Refresh(infoIds[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end
