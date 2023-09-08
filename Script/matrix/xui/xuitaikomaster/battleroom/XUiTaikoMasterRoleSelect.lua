local XUiTaikoMasterGridRoleSelect = require("XUi/XUiTaikoMaster/BattleRoom/XUiTaikoMasterGridRoleSelect")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiTaikoMasterRoleSelect : XLuaUi
---@field _Control XTaikoMasterControl
local XUiTaikoMasterRoleSelect = XLuaUiManager.Register(XLuaUi, "UiTaikoMasterRoleSelect")

function XUiTaikoMasterRoleSelect:OnAwake()
    if not self.BtnBack then
        self.BtnBack = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/TopControl/BtnBack")
        self.BtnMainUi = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/TopControl/BtnMainUi")
    end
    self:AddBtnListener()
end

function XUiTaikoMasterRoleSelect:OnStart(pos)
    local team = self._Control:GetTeam()
    self._SelectTeamPos = pos
    self._SelectCharRobotId = team:GetEntityId(pos)
    
    self:InitAutoClose()
    self:InitRoleList()
    self:InitModel()
end

function XUiTaikoMasterRoleSelect:OnEnable()
    self:RefreshRoleList()
    self:RefreshModel()
end

function XUiTaikoMasterRoleSelect:OnDisable()
    if self._ModelAnimatorRandom then
        self._ModelAnimatorRandom:Stop()
    end
end

--region Ui - AutoClose
function XUiTaikoMasterRoleSelect:InitAutoClose()
    local uiData = self._Control:GetUiData()
    self:SetAutoCloseInfo(XFunctionManager.GetEndTimeByTimeId(uiData and uiData.TimeId), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end
--endregion

--region Ui - RoleList
function XUiTaikoMasterRoleSelect:InitRoleList()
    self._RobotIdList = self._Control:GetCharacterIdList()
    ---@type XUiTaikoMasterGridRoleSelect[]
    self._GridList = {}
    self._DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self._DynamicTable:SetProxy(XUiTaikoMasterGridRoleSelect, self)
    self._DynamicTable:SetDelegate(self)
    self.GridCharacterNew.gameObject:SetActiveEx(false)
    if not XTool.IsNumberValid(self._SelectCharRobotId) then
        self._SelectCharRobotId = self._RobotIdList[1]
    end
end

function XUiTaikoMasterRoleSelect:RefreshRoleList()
    self._DynamicTable:SetDataSource(self._RobotIdList)
    self._DynamicTable:ReloadDataASync(1)
end

---@param grid XUiTaikoMasterGridRoleSelect
function XUiTaikoMasterRoleSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetData(self._RobotIdList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._SelectCharRobotId, self._SelectTeamPos)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:SelectRole(index)
    end
end

function XUiTaikoMasterRoleSelect:SelectRole(index)
    self._SelectCharRobotId = self._RobotIdList[index]
    self:RefreshModel()
    for _, grid in ipairs(self._DynamicTable:GetGrids()) do
        grid:Refresh(self._SelectCharRobotId, self._SelectTeamPos)
    end
end
--endregion

--region Model
function XUiTaikoMasterRoleSelect:InitModel()
    self.PanelModel = self.UiModelGo.transform:FindTransform("PanelRoleModel1")
    ---@type XUiPanelRoleModel
    self._RoleModel = XUiPanelRoleModel.New(self.PanelModel, self.Name, false, true, true, true, false)
    ---@type XSpecialTrainActionRandom
    self._ModelAnimatorRandom = XSpecialTrainActionRandom.New()
end

function XUiTaikoMasterRoleSelect:RefreshModel()
    if not self._RoleModel or not XTool.IsNumberValid(self._SelectCharRobotId) then
        return
    end
    self._ModelAnimatorRandom:Stop()
    self._RoleModel:UpdateCuteModel(self._SelectCharRobotId, nil, nil, nil,
            nil, nil, true,
            nil,nil,true)
    self._ModelAnimatorRandom:SetAnimator(self._RoleModel:GetAnimator(), { }, self._RoleModel)
    self._ModelAnimatorRandom:Play()
end
--endregion

--region Ui - BtnListener
function XUiTaikoMasterRoleSelect:AddBtnListener()
    if self.BtnBack then
        self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    end
    if self.BtnCancel then
        self.BtnCancel.gameObject:SetActiveEx(false)
        --XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnBtnBackClick)
    end
    XUiHelper.RegisterClickEvent(self, self.BtnTongBlack, self.OnBtnJoinTeamClick)
end

function XUiTaikoMasterRoleSelect:OnBtnBackClick()
    self:Close()
end

function XUiTaikoMasterRoleSelect:OnBtnJoinTeamClick()
    if not XTool.IsNumberValid(self._SelectTeamPos) then
        return
    end
    self._Control:SetEntityPos(self._SelectTeamPos, self._SelectCharRobotId, true)
    self:Close()
end
--endregion

return XUiTaikoMasterRoleSelect