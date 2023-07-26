-------------XUiChooseGrid begin-----------------
local Normal = CS.UiButtonState.Normal
local Select = CS.UiButtonState.Select
local Disable = CS.UiButtonState.Disable
local XUiChooseGrid = XClass(nil, "XUiChooseGrid")

function XUiChooseGrid:Ctor(ui, selectCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.SelectCallback = selectCb
    self.BaseInfo = XDataCenter.DoubleTowersManager.GetBaseInfo()
    self.TeamDb = self.BaseInfo:GetTeamDb()
    self:AutoAddListener()
end

function XUiChooseGrid:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnBtnSelectClick)
    --XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick)
end


function XUiChooseGrid:Refresh(index, pluginBaseId)
    self.Index = index
    self.PluginBaseId = pluginBaseId
    local preStageId = XDoubleTowersConfigs.GetGuardPreStageId(index)

    --图标
    local icon = XDoubleTowersConfigs.GetGuardSmallIcon(index)
    self.BtnSelect:SetRawImage(icon)
    --名称
    local name = XDoubleTowersConfigs.GetPluginLevelName(pluginBaseId)
    self.BtnSelect:SetNameByGroup(0, name)
    --描述
    local desc = XDoubleTowersConfigs.GetPluginLevelDesc(pluginBaseId)
    self.BtnSelect:SetNameByGroup(1, desc)
    --状态
    local isUnlock = not XTool.IsNumberValid(preStageId) and true or self.BaseInfo:IsStagePassed(preStageId)
    local isSelect = self.TeamDb:IsGuardBasePluginId(pluginBaseId)
    local btnState = isUnlock and (isSelect and Select or Normal) or Disable
    self.BtnSelect:SetButtonState(btnState)
end

function XUiChooseGrid:OnBtnSelectClick()
    if not XTool.IsNumberValid(self.Index) then
        return
    end
    local preStageId = XDoubleTowersConfigs.GetGuardPreStageId(self.Index)
    local isUnlock = not XTool.IsNumberValid(preStageId) and true or self.BaseInfo:IsStagePassed(preStageId)
    if not isUnlock then
        local stageName = XTool.IsNumberValid(preStageId) and XDoubleTowersConfigs.GetStageName(preStageId) or ""
        XUiManager.TipMsg(XUiHelper.GetText("DoubleTowersStageLockCondition", stageName))
        return
    end
    self.TeamDb:RefreshGuardIndex(self.Index)
    if self.SelectCallback then
        self.SelectCallback()
    end
end
-------------XUiChooseGrid end-------------------
local XUiChooseGuardPanel = XClass(nil, "XUiChooseGuardPanel")

--动作塔防养成的选择守卫面板
function XUiChooseGuardPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitDynamicTable()
end

function XUiChooseGuardPanel:InitDynamicTable()
    local selectCb = handler(self, self.Refresh)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSkillOptionGroup)
    self.DynamicTable:SetProxy(XUiChooseGrid, selectCb)
    self.DynamicTable:SetDelegate(self)
    self.GridSkillOption.gameObject:SetActiveEx(false)
end

function XUiChooseGuardPanel:Refresh()
    self.GuardIdList = XDoubleTowersConfigs.GetGuardBasePluginIdList()
    self.DynamicTable:SetDataSource(self.GuardIdList)
    self.DynamicTable:ReloadDataASync()
end

function XUiChooseGuardPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index, self.GuardIdList[index])
    end
end

return XUiChooseGuardPanel