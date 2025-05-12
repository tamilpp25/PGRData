local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelAction : XUiNode 拍照前动作和其他的选择列表
---@field Parent XUiFightCaptureV217
---@field _Control XFightCaptureV217Control
local XUiPanelAction = XClass(XUiNode, "XUiPanelAction")
local XUiGridAction = require("XUi/XUiFight/FightCaptureV217/XUiGridAction")
local CSXDofManager = CS.XDofManager.Instance

function XUiPanelAction:OnStart()
    XTool.InitUiObject(self)

    XUiHelper.RegisterSliderChangeEvent(self, self.SliderFov, self.OnSliderChanged)
    XUiHelper.RegisterClickEvent(self, self.BtnFov, self.OnBtnFovClick)
    XUiHelper.RegisterClickEvent(self, self.BtnShowRole, self.OnBtnShowRoleClick)
    self.ToggleFov.onValueChanged:AddListener(handler(self, self.OnToggleFovValueChanged))
    self.ToggleRole.onValueChanged:AddListener(handler(self, self.OnToggleRoleValueChanged))
    
    self.DynamicTableAction = XDynamicTableNormal.New(self.ActionList.gameObject)
    self.DynamicTableAction:SetProxy(XUiGridAction, self)
    self.DynamicTableAction:SetDelegate(self)

    self.CustomDofInfo = CS.XDofInfo()
    self.CustomDofInfo.XDofAperture = 0  -- 孔径比，值越小，景深越浅。范围：0~100

    self._Control:SetIsToggleFovOn(false)
    self._Control:SetIsToggleRoleOn(true)
end

function XUiPanelAction:Refresh()
    -- 刷新动作选项列表
    if self.Parent.BtnIndex == self.Parent.BtnIndexEnum.Action then
        self.ActionList.gameObject:SetActiveEx(true)
        self.ActionIdList = self._Control._Model:GetActionIdList(self.GroupId)
        self.DynamicTableAction:SetDataSource(self.ActionIdList)
        self.DynamicTableAction:ReloadDataASync()
    else
        self.ActionList.gameObject:SetActiveEx(false)
    end
    
    -- 刷新其他选项列表
    if self.Parent.BtnIndex == self.Parent.BtnIndexEnum.Other then
        self.OtherList.gameObject:SetActiveEx(true)
        self.ToggleFov.isOn = self._Control.IsToggleDofOn
        self.ToggleRole.isOn = self._Control.IsToggleRoleOn
    else
        self.OtherList.gameObject:SetActiveEx(false)
    end
end

function XUiPanelAction:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local actionId = self.ActionIdList[index]
        grid:SetData(actionId, self.UnlockActionIdDic[actionId] or false)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local actionId = self.ActionIdList[index]
        if not self.UnlockActionIdDic[actionId] then
            XUiManager.TipSuccess(self._Control._Model:GetActionUnlockDesc(actionId))
            return
        end
        self:SetSelectActionId(actionId, index)
        self._Control:PlayNpcAction(actionId, true)
    end
end

--- 设置数据
---@param groupId - CaptureV217NpcAction表的GroupId
---@param unlockActionIdList - 解锁的动作id列表
function XUiPanelAction:SetData(groupId, unlockActionIdList)
    self.GroupId = groupId
    self.UnlockActionIdDic = {}
    for _, id in pairs(unlockActionIdList) do
        self.UnlockActionIdDic[FixToInt(id)] = true
    end
end

function XUiPanelAction:SetSelectActionId(actionId, gridIndex)
    self.SelectActionId = actionId
    
    local grid
    if self.SelectGridIndex then
        grid = self.DynamicTableAction:GetGridByIndex(self.SelectGridIndex)
        if grid then
            grid:Refresh()
        end
    end

    grid = self.DynamicTableAction:GetGridByIndex(gridIndex)
    if grid then
        grid:Refresh()
    end

    self.SelectGridIndex = gridIndex
end

function XUiPanelAction:OnBtnFovClick()
    self.ToggleFov.isOn = not self._Control.IsToggleDofOn
end

function XUiPanelAction:OnBtnShowRoleClick()
    local isOn = not self._Control.IsToggleRoleOn
    self.ToggleRole.isOn = isOn
end

function XUiPanelAction:OnToggleFovValueChanged(value)
    self._Control:SetIsToggleFovOn(value)
    CSXDofManager:SetCustomDofParams(value, self.CustomDofInfo)
end

function XUiPanelAction:OnToggleRoleValueChanged(value)
    self._Control:SetIsToggleRoleOn(value)
end

--景深孔径比设置
function XUiPanelAction:OnSliderChanged(value)
    self.CustomDofInfo.XDofAperture = value * 100

    if not CSXDofManager or not CSXDofManager:GetDofFocus() then
        return
    end
    CSXDofManager:SetCustomDofParams(true, self.CustomDofInfo)
end

function XUiPanelAction:PlayNpcAction()
    if not self.SelectActionId then
        return
    end
    self._Control:PlayNpcAction(self.SelectActionId, true)
end

function XUiPanelAction:OnSelected(isSelected)
    if isSelected then
        self:Open()
        self:Refresh()
    else
        self:Close()
    end
end

return XUiPanelAction