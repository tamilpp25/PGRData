local XViewModelMazeRoom = require("XEntity/XMaze/XViewModelMazeRoom")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiMazeRoleRoomGrid = require("XUi/XUiMaze/XUiMazeRoleRoomGrid")
local XUiMazeRandomTimeline = require("XUi/XUiMaze/XUiMazeRandomTimeline")

---@class XUiMazeRoleRoom:XLuaUi
local XUiMazeRoleRoom = XLuaUiManager.Register(XLuaUi, "UiMazeRoleRoom")

function XUiMazeRoleRoom:Ctor()
    ---@type XViewModelMazeRoom
    self._ViewModel = XViewModelMazeRoom.New()
    self._Timer = false
    self._IsSelectingPartner = false
    ---@type XUiMazeRandomTimeline
    self._RandomTimeline = XUiMazeRandomTimeline.New()
    self._IsJustOpen = true
end

function XUiMazeRoleRoom:OnStart()
    self:RegisterClickEvent(self.BtnBack, self.OnClickBack)
    self:RegisterClickEvent(self.BtnMainUi, function()
        XLuaUiManager.RunMain()
    end)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, self._ViewModel:GetTicketItemId())
    self:RegisterClickEvent(self.BtnEnter, self.OnClickFight)
    self:RegisterClickEvent(self.BtnSkipHelp, self.OnClickQuickPass)
    self:RegisterClickEvent(self.BtnAddClick, self.OnClickSelectPartner)
    self:BindHelpBtn(self.BtnHelp, XMazeConfig.GetHelpKey())
    self:RegisterClickEvent(self.BtnSelect, self.OnClickCloseSelectPartner)
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnClickCloseSelectPartner)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRoleList)
    self.DynamicTable:SetProxy(XUiMazeRoleRoomGrid)
    self.DynamicTable:SetDelegate(self)
    self.PanelRole.gameObject:SetActiveEx(false)
    local uiNearRootObj = self.UiModel.UiNearRoot
    local panelModelLeft = XUiHelper.TryGetComponent(uiNearRootObj, "PanelModelLeft", "Transform")
    ---@type XUiPanelRoleModel
    self._ModelPlayer = XUiPanelRoleModel.New(panelModelLeft, self.Name, nil, true, false)
    local panelModelRight = XUiHelper.TryGetComponent(uiNearRootObj, "PanelModelRight", "Transform")
    ---@type XUiPanelRoleModel
    self._ModelPartner = XUiPanelRoleModel.New(panelModelRight, self.Name, nil, true, false)

    local uiFarRootObj = self.UiModel.UiFarRoot
    self._CameraFarChoose = XUiHelper.TryGetComponent(uiFarRootObj, "UiMazeRoleRoomChoose", "Transform")
    self._CameraFarChoose.gameObject:SetActiveEx(false)
    self._CameraFarRoom = XUiHelper.TryGetComponent(uiFarRootObj, "UiMazeRoleRoom", "Transform")
    self._CameraFarRoom.gameObject:SetActiveEx(true)

    self._CameraNearChoose = XUiHelper.TryGetComponent(uiNearRootObj, "UiMazeRoleRoomChoose", "Transform")
    self._CameraNearChoose.gameObject:SetActiveEx(false)
    self._CameraNearRoom = XUiHelper.TryGetComponent(uiNearRootObj, "UiMazeRoleRoom", "Transform")
    self._CameraNearRoom.gameObject:SetActiveEx(true)
    self:HidePanelSelectPartner()

    local timelineHelper = XUiHelper.TryGetComponent(self.Transform, "Animation/Couple", "XTimelineHelper")
    self._RandomTimeline:SetTimelineHelper(timelineHelper)
end

function XUiMazeRoleRoom:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_MAZE_UPDATE_ROBOT_SELECTED, self.OnChangePartner, self)
end

function XUiMazeRoleRoom:OnDisable()
    self._RandomTimeline:Stop()
    XEventManager.RemoveEventListener(XEventId.EVENT_MAZE_UPDATE_ROBOT_SELECTED, self.OnChangePartner, self)
end

function XUiMazeRoleRoom:OnClickSelectPartner()
    self._RandomTimeline:Pause()
    self:ShowPanelSelectPartner()
end

function XUiMazeRoleRoom:ShowPanelSelectPartner()
    self._IsSelectingPartner = true
    self.PanelChooseRole.gameObject:SetActiveEx(true)
    self._CameraNearChoose.gameObject:SetActiveEx(true)
    self._CameraFarChoose.gameObject:SetActiveEx(true)
    if self.PanelShow then
        self.PanelShow.gameObject:SetActiveEx(false)
    end
    self:UpdatePartnerList()
end

function XUiMazeRoleRoom:HidePanelSelectPartner()
    self._IsSelectingPartner = false
    self.PanelChooseRole.gameObject:SetActiveEx(false)
    self._CameraNearChoose.gameObject:SetActiveEx(false)
    self._CameraFarChoose.gameObject:SetActiveEx(false)
    if self.PanelShow then
        self.PanelShow.gameObject:SetActiveEx(true)
    end
end

function XUiMazeRoleRoom:Update()
    self:UpdatePlayer()
    self:UpdatePartner()
    self:UpdateQuickPassProgress()
    self:UpdateTicket()
end

function XUiMazeRoleRoom:UpdatePartner()
    if self._ViewModel:IsSelectPartner() then
        local robotId = self._ViewModel:GetPartnerRobotId()
        self._ModelPartner:UpdateCuteModel(robotId, nil, nil, nil, nil, function()
            self:PlayRandomTimeline()
        end)
        self.TxtPartnerName.text = self._ViewModel:GetPartnerName()
        self.RImgRoleChoose.gameObject:SetActiveEx(false)
        return
    end
    self.RImgRoleChoose.gameObject:SetActiveEx(true)
    self.TxtPartnerName.text = ""
end

function XUiMazeRoleRoom:OnChangePartner()
    self:UpdatePartner()
    self:UpdateTicket()
end

function XUiMazeRoleRoom:UpdatePlayer()
    local playerName = self._ViewModel:GetPlayerName()
    local playerModelName = self._ViewModel:GetPlayerModelName()
    self._ModelPlayer:UpdateRoleModel(playerModelName, nil, nil, function()
        self:PlayRandomTimeline()
    end, nil, true)
    self.TxtPlayerName.text = playerName
end

function XUiMazeRoleRoom:OnClickFight()
    local robotId = self._ViewModel:GetPartnerRobotId()
    if not robotId or robotId <= 0 then
        XUiManager.TipText("MazeCharacterNone")
        return
    end

    local stageId = self._ViewModel:GetStageId()
    if not stageId or stageId <= 0 then
        XUiManager.TipText("MazeCharacterNone")
        return
    end

    if not self._ViewModel:IsTicketEnough() then
        XUiManager.TipText("FubenHackTicketNotEnough")
        return
    end

    local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    local isAssist = false
    local challengeCount = 1
    XDataCenter.FubenManager.EnterFight(stageConfig, nil, isAssist, challengeCount)
end

function XUiMazeRoleRoom:UpdateTicket()
    local ticketConsumeAmount = self._ViewModel:GetTicketNeedAmount()
    if ticketConsumeAmount <= 0 then
        self.RImgTicket.gameObject:SetActiveEx(false)
        return
    end
    self.RImgTicket.gameObject:SetActiveEx(true)
    self.TxtTicket.text = string.format("x%d", ticketConsumeAmount)
end

function XUiMazeRoleRoom:UpdateQuickPassProgress()
    local passedAmount = self._ViewModel:GetPassStageAmount()
    local needPassedAmount = self._ViewModel:GetPassStageAmount2QuickPass()
    if passedAmount >= needPassedAmount then
        self.TxtSkip.text = XUiHelper.GetText("MazeQuickPass")
        return
    end
    local text = self.TxtSkip.text
    local strProgress = string.match(text, "%d+/%d+")
    local toReplace = string.format("%d/%d", passedAmount, needPassedAmount)
    if strProgress and toReplace then
        text = string.gsub(text, strProgress, toReplace)
        self.TxtSkip.text = text
    end
end

function XUiMazeRoleRoom:OnClickQuickPass()
    XLuaUiManager.Open("UiMazeSkipTips")
end

function XUiMazeRoleRoom:UpdatePartnerList()
    local dataSource = self._ViewModel:GetAllPartnerRobot()
    self.DynamicTable:SetDataSource(dataSource)
    local index = 1
    local robotIdSelected = self._ViewModel:GetPartnerRobotId()
    for i = 1, #dataSource do
        local robotId = dataSource[i]
        if robotId == robotIdSelected then
            index = i
            break
        end
    end
    self.DynamicTable:ReloadDataASync(index)
end

function XUiMazeRoleRoom:OnClickCloseSelectPartner()
    self:HidePanelSelectPartner()
    self._RandomTimeline:Play()
end

---@param grid XUiMazeRoleRoomGrid
function XUiMazeRoleRoom:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable.DataSource[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local robotId = self.DynamicTable.DataSource[index]
        XDataCenter.MazeManager.RequestSetPartnerRobotId(robotId)
        self:UpdateSelected(robotId)
    end
end

function XUiMazeRoleRoom:UpdateSelected(robotId)
    robotId = robotId or self._ViewModel:GetPartnerRobotId()
    local grids = self.DynamicTable:GetGrids()
    for i, grid in pairs(grids) do
        grid:UpdateSelected(robotId)
    end
end

function XUiMazeRoleRoom:OnClickBack()
    if self._IsSelectingPartner then
        self:HidePanelSelectPartner()
        return
    end
    self:Close()
end

function XUiMazeRoleRoom:PlayRandomTimeline()
    if not self._RandomTimeline then
        return
    end
    local animatorPlayer = self._ModelPlayer:GetAnimator()
    if not animatorPlayer then
        return
    end
    local animatorPartner = self._ModelPartner:GetAnimator()
    if not animatorPartner then
        return
    end
    self._RandomTimeline:ClearObjectBind()
    self._RandomTimeline:BindObject("Player", animatorPlayer)
    self._RandomTimeline:BindObject("Partner", animatorPartner)

    local facePlayer = self._ModelPlayer:GetComponent("XFaceAnimation")
    local facePartner = self._ModelPartner:GetComponent("XFaceAnimation")
    self._RandomTimeline:BindObject("FacePlayer", facePlayer)
    self._RandomTimeline:BindObject("FacePartner", facePartner)

    local modelName = self._ModelPartner:GetCurRoleName()
    local randomData = XMazeConfig.GetRandomTimeline(modelName)
    self._RandomTimeline:SetRandomArray(randomData)
    if self._IsJustOpen then
        self._RandomTimeline:PlayDelay()
    else
        self._RandomTimeline:Play()
    end
end

return XUiMazeRoleRoom
