local XUiFubenMaverickCharacterPanel = XClass(nil, "XUiFubenMaverickCharacterPanel")
local XUiFubenMaverickCharacterGrid = require("XUi/XUiFubenMaverick/XUiGrid/XUiFubenMaverickCharacterGrid")
local XUiFubenMaverickSkillGrid = require("XUi/XUiFubenMaverick/XUiGrid/XUiFubenMaverickSkillGrid")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

-- 3D场景相机数量
local CAMERA_NUM = 3

function XUiFubenMaverickCharacterPanel:Ctor(rootUi, uiSkills, dynamicTable, onSelect, showRedDot)
    self.RootUi = rootUi
    self.OnSelect = onSelect
    self.ShowRedDot = showRedDot
    self.GridSkills = {}
    for i, uiSkill in ipairs(uiSkills) do
        self.GridSkills[i] = XUiFubenMaverickSkillGrid.New(uiSkill)
    end

    dynamicTable.Grid.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(dynamicTable)
    self.DynamicTable:SetProxy(XUiFubenMaverickCharacterGrid)
    self.DynamicTable:SetDelegate(self)

    self.GameObject = dynamicTable.gameObject

    self:InitModel()
end

function XUiFubenMaverickCharacterPanel:Refresh(order)
    self.MemberIds = XDataCenter.MaverickManager.GetMemberIds(order)
    self.LastUsedMemberId = XDataCenter.MaverickManager.GetLastUsedMemberId()
    self.DynamicTable:SetDataSource(self.MemberIds)
    self.DynamicTable:ReloadDataSync(1)

    local member = XDataCenter.MaverickManager.GetMember(self.LastUsedMemberId)
    local robotId = XDataCenter.MaverickManager.GetRobotId(member)
    local characterId = XRobotManager.GetCharacterId(robotId)
    self:UpdateModel(robotId, characterId)
    self:UpdateSkills(self.LastUsedMemberId)
    if self.OnSelect then
        self.OnSelect(self.LastUsedMemberId)
    end
end

function XUiFubenMaverickCharacterPanel:UpdateSkills(memberId)
    local skills = XDataCenter.MaverickManager.GetSkills(memberId)
    for i, grid in ipairs(self.GridSkills) do
        grid:Refresh(skills[i])
    end
end

function XUiFubenMaverickCharacterPanel:SelectGrid(grid)
    if self.LastUsedMemberId == grid.MemberId then
        return
    end

    self.LastUsedMemberId = grid.MemberId
    XDataCenter.MaverickManager.SetLastUsedMemberId(self.LastUsedMemberId)

    local grids = self.DynamicTable:GetGrids()
    for _, g in pairs(grids) do
        g:RefreshSelect()
    end

    self:UpdateModel(grid.RobotId, grid.CharacterId)
    self:UpdateSkills(grid.MemberId)
    if self.OnSelect then
        self.OnSelect(grid.MemberId)
    end
end

function XUiFubenMaverickCharacterPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.MemberIds[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:SelectGrid(grid)
    end
end

--================
--初始化角色模型和场景相机
--================
function XUiFubenMaverickCharacterPanel:InitModel()
    local root = self.RootUi.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.ImgEffectLogoGouzao = root:FindTransform("ImgEffectLogoGouzao")
    self.ImgEffectLogoGanran = root:FindTransform("ImgEffectLogoGanran")
    self.CameraFar = {
        root:FindTransform("CamFarMain"),
        root:FindTransform("UiCamFarLv"),
        root:FindTransform("UiCamFarPrepare"),
    }
    self.CameraNear = {
        root:FindTransform("CamNearMain"),
        root:FindTransform("UiCamNearLv"),
        root:FindTransform("UiCamNearPrepare"),
    }
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end
--================
--刷新场景相机
--================
function XUiFubenMaverickCharacterPanel:UpdateCamera(cameraIndex)
    self.CurCameraIndex = cameraIndex
    for i = 1, CAMERA_NUM do
        if self.CurCameraIndex ~= i then
            self.CameraFar[i].gameObject:SetActiveEx(false)
            self.CameraNear[i].gameObject:SetActiveEx(false)
        end
    end

    if self.CameraFar[self.CurCameraIndex] then
        self.CameraFar[self.CurCameraIndex].gameObject:SetActiveEx(true)
    end

    if self.CameraNear[self.CurCameraIndex] then
        self.CameraNear[self.CurCameraIndex].gameObject:SetActiveEx(true)
    end
end
--================
--刷新模型
--================
function XUiFubenMaverickCharacterPanel:UpdateModel(robotId, characterId, updateModelCb)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    local cb = function(model)
        if self.RootUi.PanelDrag then
            self.RootUi.PanelDrag.Target = model.transform
        end
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        if updateModelCb then updateModelCb(model) end
    end
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    self.RoleModelPanel:UpdateRobotModel(robotId, characterId, nil, robotCfg and robotCfg.FashionId, robotCfg and robotCfg.WeaponId, cb)
end

return XUiFubenMaverickCharacterPanel