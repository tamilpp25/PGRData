local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiTaikoMasterGridRole : XUiNode
---@field _Control XTaikoMasterControl
---@field Parent XUiTaikoMasterBattleRoom
local XUiTaikoMasterGridRole = XClass(XUiNode, "XUiTaikoMasterGridRole")

function XUiTaikoMasterGridRole:OnStart(index, panelRole, stageId)
    self._Index = index
    self._PanelRole = panelRole
    self._StageId = stageId
    self:InitModel()
    self:AddBtnListener()
    self.Normal = XUiHelper.TryGetComponent(self.Transform, "PanelTitle/Normal")
    self.Press = XUiHelper.TryGetComponent(self.Transform, "PanelTitle/Press")
    self.TxtPos = XUiHelper.TryGetComponent(self.Transform, "PanelTitle/Txt", "Text")
    self.TxtPos1 = XUiHelper.TryGetComponent(self.Transform, "PanelTitle/Normal/Txt", "Text")
    self.ImgAdd2 = XUiHelper.TryGetComponent(self.Transform, "ImgAdd2")
end

function XUiTaikoMasterGridRole:OnEnable()
    self:Refresh()
end

function XUiTaikoMasterGridRole:OnDisable()
    self._ModelAnimatorRandom:Stop()
end

function XUiTaikoMasterGridRole:Refresh()
    local robotId = self._Control:GetTeam():GetEntityId(self._Index)
    local hasRobot = not XTool.IsNumberValid(robotId)
    local positionNum = self._Control:GetStagePositionNum(self._StageId)
    self:RefreshModel(robotId)
    self.ImgAdd.gameObject:SetActiveEx(hasRobot and self._Index <= positionNum)
    if self.ImgAdd2 then
        self.ImgAdd2.gameObject:SetActiveEx(hasRobot and self._Index > positionNum)
    end
    if self.Normal then
        self.TxtPos.text = XUiHelper.GetText("AwarenessTfPos", self._Index)
        self.TxtPos1.text = XUiHelper.GetText("AwarenessTfPos", self._Index)
        self.Normal.gameObject:SetActiveEx(hasRobot)
        self.Press.gameObject:SetActiveEx(not hasRobot)
    end
end

--region Model - PanelRole
function XUiTaikoMasterGridRole:InitModel()
    if self._PanelRole then
        ---@type XUiPanelRoleModel
        self._RoleModel = XUiPanelRoleModel.New(self._PanelRole, self.Parent.Name, false, true, true, true, false)
        ---@type XSpecialTrainActionRandom
        self._ModelAnimatorRandom = XSpecialTrainActionRandom.New()
    end
end

function XUiTaikoMasterGridRole:RefreshModel(robotId)
    if not self._PanelRole then
        return
    end
    if not XTool.IsNumberValid(robotId) then
        if self._RoleModel then
            self._RoleModel:HideRoleModel()
            self._ModelAnimatorRandom:Stop()
        end
        return
    end
    self._ModelAnimatorRandom:Stop()
    self._RoleModel:ShowRoleModel()
    self._RoleModel:UpdateCuteModel(robotId, nil, nil, nil,
            nil, nil, true,
            nil,nil,true)
    self._ModelAnimatorRandom:SetAnimator(self._RoleModel:GetAnimator(), { }, self._RoleModel)
    self._ModelAnimatorRandom:Play()
end
--endregion

--region Ui - BtnListener
function XUiTaikoMasterGridRole:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnChar, self.OnBtnClick, true)
end

function XUiTaikoMasterGridRole:OnBtnClick()
    if XTool.IsNumberValid(self._StageId) then
        local positionNum = self._Control:GetStagePositionNum(self._StageId)
        if self._Index > positionNum then
            XUiManager.TipErrorWithKey("TaikoMasterFightTeamCountTip", positionNum)
            return
        end
    end
    self._Control:OpenUiRoleSelect(self._Index)
end
--endregion

return XUiTaikoMasterGridRole