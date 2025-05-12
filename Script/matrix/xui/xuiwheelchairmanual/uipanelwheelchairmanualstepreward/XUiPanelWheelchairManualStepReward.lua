local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelWheelchairManualStepReward: XUiNode
---@field _Control XWheelchairManualControl
local XUiPanelWheelchairManualStepReward = XClass(XUiNode, "XUiPanelWheelchairManualStepReward")
local XUiGridWheelchairManualStepRewardPlan = require('XUi/XUiWheelchairManual/UiPanelWheelchairManualStepReward/XUiGridWheelchairManualStepRewardPlan')
local XUiGridWheelchairManualStepRewardGet = require('XUi/XUiWheelchairManual/UiPanelWheelchairManualStepReward/XUiGridWheelchairManualStepRewardGet')

function XUiPanelWheelchairManualStepReward:OnStart()
    self.TabId = XMVCA.XWheelchairManual:GetCurActivityTabIdAndPanelUrlByTabType(XEnumConst.WheelchairManual.TabType.StepReward)
    self.DynamicTable = XDynamicTableNormal.New(self.ListStep)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridWheelchairManualStepRewardPlan, self, self.Parent)
    self.GridStep.gameObject:SetActiveEx(false)
    self:InitCharacterAndWeaponShow()
    self.BtnTask.CallBack = handler(self, self.OnBtnGetClick)
    XMVCA.XWheelchairManual:SetSubActivityIsOld(XEnumConst.WheelchairManual.ReddotKey.StepRewardNew)
end

function XUiPanelWheelchairManualStepReward:OnEnable()
    self:RefreshPlanShow()
    self:RefreshCharacterAndWeaponShow()
end

function XUiPanelWheelchairManualStepReward:OnDisable()
    self.DynamicTable:RecycleAllTableGrid()
end

function XUiPanelWheelchairManualStepReward:InitCharacterAndWeaponShow()
    local cfg = self._Control:GetCurActivityCharacterPlanCfg()
    local planIds = self._Control:GetCurActivityPlanIds()
    self._BtnCharacter = XUiGridWheelchairManualStepRewardGet.New(self.BtnCharacter, self, 'UiCharacterDetail', cfg.CharacterId, XMVCA.XCharacter:GetCharacterFullNameStr(cfg.CharacterId), planIds[cfg.CharacterPlanIndex], cfg.CharacterPlanIndex)
    self._BtnCharacter:Open()

    self._BtnWeapon = XUiGridWheelchairManualStepRewardGet.New(self.BtnWeapon, self, 'UiEquipPreviewV2P6', cfg.WeaponId, XMVCA.XEquip:GetEquipName(cfg.WeaponId), planIds[cfg.WeaponPlanIndex], cfg.WeaponPlanIndex)
    self._BtnWeapon:Open()
end

function XUiPanelWheelchairManualStepReward:RefreshPlanShow()
    local planIds = self._Control:GetCurActivityPlanIds()
    
    -- 优先索引到最早可领取的阶段
    local currentPlanIndex = self._Control:GetCurActivityMinPlanCanGetIndex()
    
    -- 如果没有可领取的，那么显示当前进行的阶段
    if not XTool.IsNumberValid(currentPlanIndex) then
        currentPlanIndex = self._Control:GetCurActivityCurrentPlanIndex()
    end
    
    if not XTool.IsTableEmpty(planIds) then
        self.DynamicTable:SetDataSource(planIds)
        self.DynamicTable:ReloadDataASync(currentPlanIndex)
    end
    self._IsAllPlanRewardGot = XMVCA.XWheelchairManual:CheckAllPlanRewardIsGot()
    self.BtnTask:SetButtonState(self._IsAllPlanRewardGot and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiPanelWheelchairManualStepReward:RefreshCharacterAndWeaponShow()
    self._BtnCharacter:RefreshState()
    self._BtnWeapon:RefreshState()
end

function XUiPanelWheelchairManualStepReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Open()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshData(self.DynamicTable.DataSource[index], index)    
    end
end

function XUiPanelWheelchairManualStepReward:OnBtnGetClick()
    if self._IsAllPlanRewardGot then
        return
    end
    
    local tabId = XMVCA.XWheelchairManual:GetCurActivityTabIdAndPanelUrlByTabType(XEnumConst.WheelchairManual.TabType.StepTask)
    if XTool.IsNumberValid(tabId) then
        local tabIndex = XMVCA.XWheelchairManual:GetCurActivityTabIndexByTabType(tabId)

        if XTool.IsNumberValid(tabIndex) then
            XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_TAB_GOTO, tabIndex)
        end
    end
end

return XUiPanelWheelchairManualStepReward