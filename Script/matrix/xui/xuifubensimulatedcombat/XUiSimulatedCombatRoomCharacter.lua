local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--角色选择界面
local XUiSimulatedCombatRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatRoomCharacter")
local XUiSimulatedCombatRoomCharListGrid = require("XUi/XUiFubenSimulatedCombat/ChildItem/XUiRoomCharListGrid")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiSimulatedCombatRoomCharacter:OnAwake()
    XTool.InitUiObject(self)
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self, true)
    self.AssetActivityPanel:SetQueryFunc(XDataCenter.FubenSimulatedCombatManager.GetCurrencyByItem)
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiSimulatedCombatRoomCharListGrid)
    self.DynamicTable:SetDelegate(self)

    self:AddListener()
end

function XUiSimulatedCombatRoomCharacter:OnStart(teamData, changePos, cb)
    self.TeamData = teamData
    self.ChangePos = changePos
    self.ActTemplate = XDataCenter.FubenSimulatedCombatManager.GetCurrentActTemplate()
    self.MemberList = XDataCenter.FubenSimulatedCombatManager.GetRoomMemberList()
    -- XLog.Warning("RoomCharacter", teamData, "- split - ", self.MemberList)
    local charId = teamData[changePos]
    if charId ~= 0 then
        for i, v in pairs(self.MemberList) do
            if v == charId then
                self.CurrentSelect = i
            end
        end
        self.CurrentSelect = self.CurrentSelect or 1
    else
        self.CurrentSelect = 1
    end
    self:UpdateList()
    self.CallBack = cb
end

function XUiSimulatedCombatRoomCharacter:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    self:UpdateList()
end

function XUiSimulatedCombatRoomCharacter:Refresh(charId, robotId)
    if not self.ActTemplate then return end
    self.RobotId = robotId
    self:UpdateModel(charId, robotId)
    self:SetTeamBtns(charId)

    self.AssetActivityPanel:Refresh(self.ActTemplate.ConsumeIds)
end

function XUiSimulatedCombatRoomCharacter:UpdateModel(characterId, robotId)
    if not characterId then return end
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    local callback = function()
        self.ModelReady = true
    end
    self.ModelReady = false
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    if not robotCfg then return end
    self.RoleModelPanel:UpdateRobotModel(robotId, characterId, callback, robotCfg and robotCfg.FashionId, robotCfg and robotCfg.WeaponId)
end

function XUiSimulatedCombatRoomCharacter:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiSimulatedCombatRoomCharacter:OnDestroy()
    if self.CallBack then
        self.CallBack(self.TeamData)
        self.CallBack = nil
    end
end
function XUiSimulatedCombatRoomCharacter:SetTeamBtns(charId)
    local isInTeam = self:IsInTeam(charId)
    self.BtnJoinTeam.gameObject:SetActiveEx(not isInTeam)
    self.BtnQuitTeam.gameObject:SetActiveEx(isInTeam)
end

function XUiSimulatedCombatRoomCharacter:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET }
end

function XUiSimulatedCombatRoomCharacter:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.SimulatedCombat then return end
        XDataCenter.FubenSimulatedCombatManager.OnActivityEnd()
    end
end
function XUiSimulatedCombatRoomCharacter:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnJoinTeam, self.OnBtnJoinClick)
    self:RegisterClickEvent(self.BtnQuitTeam, self.OnBtnQuitClick)
end

function XUiSimulatedCombatRoomCharacter:OnBtnBackClick()
    self:Close()
end

function XUiSimulatedCombatRoomCharacter:OnBtnMainUiClick()
    local title = CSXTextManagerGetText("TipTitle")
    local content = CSXTextManagerGetText("SimulatedCombatBackConfirm")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        XLuaUiManager.RunMain()
    end)
end

function XUiSimulatedCombatRoomCharacter:OnBtnJoinClick()
    local id = self.MemberList[self.CurrentSelect]
    for k, v in pairs(self.TeamData) do
        if v == id then
            self.TeamData[k] = 0
            break
        end
    end

    self.TeamData[self.ChangePos] = id
    if self.CallBack then
        self.CallBack(self.TeamData)
        self.CallBack = nil
    end
    self:Close()
end

function XUiSimulatedCombatRoomCharacter:OnBtnQuitClick()
    local count = 0
    for _, v in pairs(self.TeamData) do
        if v > 0 then
            count = count + 1
        end
    end

    local id = self.MemberList[self.CurrentSelect]
    for k, v in pairs(self.TeamData) do
        if v == id then
            self.TeamData[k] = 0
            break
        end
    end

    if self.CallBack then
        self.CallBack(self.TeamData)
        self.CallBack = nil
    end
    self:Close()
end

function XUiSimulatedCombatRoomCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
        if self.CurrentSelect == index then
            self:SetSelectCharacter(grid)
        end
        local charId = self.MemberList[index]
        grid:SetInTeam(self:IsInTeam(charId))
        grid:Refresh(charId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetSelect(false)
        grid:SetInTeam(false)
        if self.CurrentSelect == index then
            self:SetSelectCharacter(grid)
        end
        local charId = self.MemberList[index]
        grid:SetInTeam(self:IsInTeam(charId))
        grid:Refresh(charId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurrentSelect = index
        self:SetSelectCharacter(grid)
    end
end

function XUiSimulatedCombatRoomCharacter:UpdateList()
    self.DynamicTable:SetDataSource(self.MemberList)
    if #self.MemberList > 0 then
        self.DynamicTable:ReloadDataSync(self.CurrentSelect)
    end
end

--选中
function XUiSimulatedCombatRoomCharacter:SetSelectCharacter(grid)
    if self.CurCharacterGrid then
        self.CurCharacterGrid:SetSelect(false)
    end
    self.CurCharacterGrid = grid
    self.CurCharacterGrid:SetSelect(true)
end

function XUiSimulatedCombatRoomCharacter:IsInTeam(id)
    for _, v in pairs(self.TeamData) do
        if v == id then
            return true
        end
    end
    return false
end

return XUiSimulatedCombatRoomCharacter