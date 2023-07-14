local XUiBattleRoomRoleGridCute = require("XUi/XUiSpecialTrainBreakthrough/XUiBattleRoomRoleGridCute")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XRobot = require("XEntity/XRobot/XRobot")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")

---@class XUiBattleRoomRoleDetailCute:XLuaUi@因为cute与原版ui差别巨大，所以不复用XUiBattleRoomRoleDetail
local XUiBattleRoomRoleDetailCute = XLuaUiManager.Register(XLuaUi, "UiBattleRoomRoleDetailCute")

function XUiBattleRoomRoleDetailCute:OnAwake()
    ---@type XUiBattleRoomRoleDetailDefaultProxy
    self.DefaultProxy = XUiBattleRoomRoleDetailDefaultProxy.New()
    self.Proxy = false

    ---@type XTeam
    self.Team = nil
    self.StageId = nil
    self.Pos = nil
    self.CurrentEntityId = nil

    -- 角色列表
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiBattleRoomRoleGridCute)
    self.DynamicTable:SetDelegate(self)

    -- 模型初始化
    self.PanelRoleModelGo = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = self.UiModelGo.transform:FindTransform("ImgEffectHuanren1")
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.UiPanelRoleModel = XUiPanelRoleModel.New(self.PanelRoleModelGo, self.Name, nil, true)
    self:RegisterUiEvents()

    self.SpecialTrainActionRandom = XSpecialTrainActionRandom.New()
end

function XUiBattleRoomRoleDetailCute:GetAutoCloseInfo()
    local callback = function(isClose)
        if isClose then
            XDataCenter.FubenSpecialTrainManager.HandleActivityEndTime()
        end
    end
    local endTime = XDataCenter.FubenSpecialTrainManager.GetActivityEndTime()
    return endTime, callback
end

function XUiBattleRoomRoleDetailCute:OnStart(stageId, team, pos, proxy)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
    self.Proxy = proxy

    self.DynamicTable:SetGrid(self.GridCharacterNew)
    self.GridCharacterNew.gameObject:SetActiveEx(false)

    -- 避免其他系统队伍数据错乱，预先清除
    XEntityHelper.ClearErrorTeamEntityId(
        team,
        function(entityId)
            return self.DefaultProxy:GetCharacterViewModelByEntityId(entityId) ~= nil
        end
    )
    self:UpdateCurrentEntityId(self.Team:GetEntityIdByTeamPos(self.Pos))

    -- 注册自动关闭
    local autoCloseEndTime, callback = self:GetAutoCloseInfo()
    if autoCloseEndTime then
        self:SetAutoCloseInfo(autoCloseEndTime, callback)
    end
end

function XUiBattleRoomRoleDetailCute:OnEnable()
    XUiBattleRoomRoleDetailCute.Super.OnEnable(self)
    self:InitRoleList()
end

function XUiBattleRoomRoleDetailCute:OnDisable()
    XUiBattleRoomRoleDetailCute.Super.OnDisable(self)
    self.SpecialTrainActionRandom:Stop()
end

function XUiBattleRoomRoleDetailCute:InitRoleList()
    self:RefreshRoleList(self:GetEntities())
end

function XUiBattleRoomRoleDetailCute:RegisterUiEvents()
    self:BindExitBtns()
    self:RegisterClickEvent(
        self.BtnEnterFight,
        function()
            if self:IsSameRole() then
                return
            end
            self:JoinTeam()
        end
    )
end

function XUiBattleRoomRoleDetailCute:JoinTeam()
    self.Team:UpdateEntityTeamPos(self.CurrentEntityId, self.Pos, true)
    self:Close(true)
end

function XUiBattleRoomRoleDetailCute:QuitTeam()
    self.Team:UpdateEntityTeamPos(self.CurrentEntityId, self.Pos, false)
    self:Close(true)
end

function XUiBattleRoomRoleDetailCute:RefreshRoleList(roleEntities)
    local searchEntityId = self.CurrentEntityId
    local index = 1
    if XTool.IsNumberValid(searchEntityId) then
        for i, v in ipairs(roleEntities) do
            if v:GetId() == searchEntityId then
                index = i
                break
            end
        end
    end
    self:UpdateCurrentEntityId(roleEntities[index]:GetId())
    self.DynamicTable:SetDataSource(roleEntities)
    self.DynamicTable:ReloadDataSync(index)
    self:RefreshModel()
end

function XUiBattleRoomRoleDetailCute:OnDynamicTableEvent(event, index, grid)
    if index <= 0 or index > #self.DynamicTable.DataSource then
        return
    end
    local entity = self.DynamicTable:GetData(index)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(entity, self.Team, self.StageId, self.Pos)
        grid:SetSelectStatus(self.CurrentEntityId == entity:GetId())
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:UpdateCurrentEntityId(entity:GetId())
        for _, tmpGrid in pairs(self.DynamicTable:GetGrids()) do
            tmpGrid:SetSelectStatus(false)
        end
        grid:SetSelectStatus(true)
        self:RefreshModel()
    end
end

function XUiBattleRoomRoleDetailCute:RefreshModel(robotId)
    if robotId == nil then
        robotId = self.CurrentEntityId
    end
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self:OnModelLoadBegin()
    local finishedCallback = function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        self:OnModelLoadCallback()
    end
    local characterViewModel = self.DefaultProxy:GetCharacterViewModelByEntityId(robotId)
    local sourceEntityId = characterViewModel:GetSourceEntityId()
    local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    local needDisplayController = XCharacterCuteConfig.GetNeedDisplayController(self.StageId)
    self.UiPanelRoleModel:UpdateCuteModel(
        robotId,
        characterId,
        nil,
        robotConfig.FashionId,
        robotConfig.WeaponId,
        finishedCallback,
        needDisplayController,
        self.PanelRoleModelGo,
        self.Name
    )
end

function XUiBattleRoomRoleDetailCute:UpdateCurrentEntityId(value)
    self.CurrentEntityId = value
    self.BtnEnterFight:SetDisable(self:IsSameRole())
end

function XUiBattleRoomRoleDetailCute:IsSameRole()
    return self.CurrentEntityId == self.Team:GetEntityIdByTeamPos(self.Pos)
end

function XUiBattleRoomRoleDetailCute:Close(updated)
    local isStop = self.Proxy:AOPCloseBefore(self)
    if isStop then
        return
    end
    if updated then
        self:EmitSignal("UpdateEntityId", self.CurrentEntityId)
    end
    XUiBattleRoomRoleDetailCute.Super.Close(self)
end

function XUiBattleRoomRoleDetailCute:GetEntities()
    local stageId = self.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local robotIdList = XFubenConfigs.GetStageTypeRobot(stageInfo.Type) or {}
    local robots = {}
    for _, robotId in ipairs(robotIdList) do
        robots[#robots + 1] = XRobotManager.GetRobotById(robotId)
    end
    return robots
end

function XUiBattleRoomRoleDetailCute:OnModelLoadBegin()
    self.SpecialTrainActionRandom:Stop()
end

function XUiBattleRoomRoleDetailCute:OnModelLoadCallback()
    local needDisplayController = XCharacterCuteConfig.GetNeedDisplayController(self.StageId)
    if not needDisplayController then
        return
    end
    local actionArray = XCharacterCuteConfig.GetModelRandomAction(self.UiPanelRoleModel:GetCurRoleName())
    self.SpecialTrainActionRandom:SetAnimator(self.UiPanelRoleModel:GetAnimator(), actionArray, self.UiPanelRoleModel)
    self.SpecialTrainActionRandom:Play()
end

return XUiBattleRoomRoleDetailCute
