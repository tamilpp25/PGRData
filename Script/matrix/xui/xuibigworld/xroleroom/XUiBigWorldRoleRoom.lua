local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
---@class XUiBigWorldRoleRoom : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Proxy XBigWorldBattleRoomProxy
---@field _Control XBigWorldControl
---@field _PanelRoleList XUiPanelBWRoleSheet
---@field _PanelRoleInfo XUiPanelBWRoleInfo
---@field _PanelRoleVList XUiPanelBWRoleList
local XUiBigWorldRoleRoom = XLuaUiManager.Register(XLuaUi, "UiBigWorldRoleRoom")

local XUiModelDisplayController = require("XUi/XUiCommon/XUiModelDisplay/XUiModelDisplayController")

local XDlcEventId = XMVCA.XBigWorldService.DlcEventId

local MaxTeamPos = 3

local VirtualCamera = {
    Main = 1,
    Role = 2,
}

function XUiBigWorldRoleRoom:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldRoleRoom:OnStart(teamIndex, proxy)
    self._DefaultIndex = teamIndex or XMVCA.XBigWorldCharacter:GetCurrentTeamId()
    self._Proxy = proxy and proxy.New() or require("XModule/XBigWorldCharacter/Proxy/XBigWorldBattleRoomProxy").New()
    self:InitView()
end

function XUiBigWorldRoleRoom:OnEnable()
end

function XUiBigWorldRoleRoom:OnDisable()
    self._DefaultIndex = self._TabIndex
    self._TabIndex = nil
    self:HideAllModel()
end

function XUiBigWorldRoleRoom:OnDestroy()
    XMVCA.XBigWorldMap:OpenBigWorldLittleMapUi()

    self._LongClick1:Destroy()
    self._LongClick2:Destroy()
    self._LongClick3:Destroy()

    XEventManager.RemoveEventListener(XDlcEventId.EVENT_LOCAL_PLAYER_NPC_LOAD_COMPLETED, self.Close, self)
end

function XUiBigWorldRoleRoom:InitUi()
    self._PanelRoleList = require("XUi/XUiBigWorld/XRoleRoom/Panel/XUiPanelBWRoleSheet").New(self.PlayerInfoBaseNew, self)
    self._PanelRoleList:Close()
    self.FullscreenClose.gameObject:SetActiveEx(false)
    self.BtnBuffDetailClose.gameObject:SetActiveEx(false)
    self.MaskWaiting.gameObject:SetActiveEx(false)
    self._EntityIds = { 0, 0, 0 }

    self._PanelRoleInfo = require("XUi/XUiBigWorld/XRoleRoom/Panel/XUiPanelBWRoleInfo").New(self.PanelOwned, self)
    self._PanelRoleInfo:Close()
    self:InitTab()
    self:InitCharBtn()

    self._LongClickTime = 0
    self._LongClickInterval = 1
    self._Camera = CS.XUiManager.Instance.UiCamera
end

function XUiBigWorldRoleRoom:InitTab()
    local tab = {}
    local index = 1
    while true do
        local btn = self["BtnRank" .. index]
        if not btn then
            break
        end
        tab[#tab + 1] = btn
        index = index + 1
    end

    self.BtnGroup:Init(tab, function(tabIndex)
        self:OnSelectTab(tabIndex)
    end)
end

function XUiBigWorldRoleRoom:InitCharBtn()
    local uiModelRoot = self.UiModelGo.transform
    self._DisplayControllers = {
        XUiModelDisplayController.New(uiModelRoot:FindTransform("PanelRoleModel1"), true),
        XUiModelDisplayController.New(uiModelRoot:FindTransform("PanelRoleModel2"), true),
        XUiModelDisplayController.New(uiModelRoot:FindTransform("PanelRoleModel3"), true),
    }
    
    self._FxChangeRoles = {
        uiModelRoot:Find("UiNearRoot/PanelRoleModel1/PanelEffectHuanren"),
        uiModelRoot:Find("UiNearRoot/PanelRoleModel2/PanelEffectHuanren"),
        uiModelRoot:Find("UiNearRoot/PanelRoleModel3/PanelEffectHuanren"),
    }
    
    self._FxRoleAvailable = {
        uiModelRoot:Find("UiNearRoot/PanelRoleEffect1"),
        uiModelRoot:Find("UiNearRoot/PanelRoleEffect2"),
        uiModelRoot:Find("UiNearRoot/PanelRoleEffect3"),
    }

    local vRoot = uiModelRoot:FindTransform("VirtualCameraRoot")
    self._VirtualCameraDict = {
        [VirtualCamera.Main] = vRoot.transform:Find("VCameraMain"),
        [VirtualCamera.Role] = vRoot.transform:Find("VCameraRole"),
    }

    self._RoleCameraPoints = {}
    local rolePoint = uiModelRoot:FindTransform("RoleCameraPoint")
    local index = 1
    while true do
        local t = rolePoint.transform:Find("Point" .. index)
        if not t then
            break
        end
        self._RoleCameraPoints[index] = {
            Point = t.transform.localPosition,
            Rotation =  t.transform.localRotation
        }
        index = index + 1
    end

    self._LongClick1 = XUiButtonLongClick.New(self.PointerChar1, 10, self, nil, self.OnBtnChar1LongClicked, self.OnBtnChar1LongPressUp, false)
    self._LongClick2 = XUiButtonLongClick.New(self.PointerChar2, 10, self, nil, self.OnBtnChar2LongClicked, self.OnBtnChar2LongPressUp, false)
    self._LongClick3 = XUiButtonLongClick.New(self.PointerChar3, 10, self, nil, self.OnBtnChar3LongClicked, self.OnBtnChar3LongPressUp, false)

    self:RegisterClickEvent(self.BtnChar1, self.OnBtnChar1Clicked)
    self:RegisterClickEvent(self.BtnChar2, self.OnBtnChar2Clicked)
    self:RegisterClickEvent(self.BtnChar3, self.OnBtnChar3Clicked)

    self:UpdateCamera(VirtualCamera.Main)
end

function XUiBigWorldRoleRoom:InitCb()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end

    self.BtnEnterFight.CallBack = function()
        self:OnBtnEnterFight()
    end

    self.BtnBuffDetailClose.CallBack = function()
        self:OnBtnDetailClicked()
    end

    self.BtnQuick.CallBack = function()
        self:OnBtnQuickClick()
    end
    
    self:RegisterClickEvent(self.FullscreenClose, self.OnBtnDetailClicked)
end

function XUiBigWorldRoleRoom:InitView()
    self.BtnGroup:SelectIndex(self._DefaultIndex)
    XMVCA.XBigWorldMap:CloseBigWorldLittleMapUi()

    XEventManager.AddEventListener(XDlcEventId.EVENT_LOCAL_PLAYER_NPC_LOAD_COMPLETED, self.Close, self)
end

function XUiBigWorldRoleRoom:UpdateView()
    for i = 1, MaxTeamPos do
        self:UpdateSingleModel(i, self._Team:GetEntityId(i))
    end
    self:UpdateCurrentTeam()
end

function XUiBigWorldRoleRoom:HideAllModel()
    for _, display in pairs(self._DisplayControllers) do
        display:HideAllModel()
    end
end

function XUiBigWorldRoleRoom:UpdateSingleModel(index, entityId)
    local isValid = XTool.IsNumberValid(entityId)
    self["ImgAdd" .. index].gameObject:SetActiveEx(not isValid)
    self["PanelName" .. index].gameObject:SetActiveEx(isValid)
    local display = self._DisplayControllers[index]
    local oldId = self._EntityIds[index]
    local oldModelId
    if oldId and oldId > 0 then
        oldModelId = self._Proxy:GetUiModelId(oldId)
    end

    if oldModelId then
        display:SetModelActive(oldModelId, false)
    end
    self._FxRoleAvailable[index].gameObject:SetActiveEx(isValid)
    if isValid then
        self["TxtRank" .. index].text = string.format("%02d", index)
        self["TxtName" .. index].text = XMVCA.XBigWorldCharacter:GetCharacterLogName(entityId)
        self["UiBigWorldPanelStory" .. index].gameObject:SetActiveEx(XMVCA.XBigWorldCharacter:CheckCharacterTrial(entityId))
        local modelId = self._Proxy:GetUiModelId(entityId)
        local modelUrl = self._Proxy:GetModelUrl(entityId)
        local controllerUrl = self._Proxy:GetModelController(entityId)

        if self._Proxy:IsCommandant(entityId) then
            XMVCA.XBigWorldCommanderDIY:LoadCurrentModel(display)
        else
            if display:IsModelExist(modelId) then
                display:ChangeModelComponent(modelId, 0, modelUrl, controllerUrl)
            else
                display:AddSingleModel(modelId, modelUrl, controllerUrl)
            end
        end
        local animaName = self._Proxy:GetDefaultAnimName(entityId)
        display:PlayAnimation(modelId, animaName)
    end
    self._EntityIds[index] = entityId
end

function XUiBigWorldRoleRoom:UpdateCurrentTeam()
    local currentTeamId = XMVCA.XBigWorldCharacter:GetCurrentTeamId()
    local index = 1
    while true do
        local btn = self["BtnRank" .. index]
        if not btn then
            break
        end
        local teamId = XMVCA.XBigWorldCharacter:GetCommonTeamId(index)
        btn:ShowTag(teamId == currentTeamId)
        index = index + 1
    end
    local isCurrent = self._TeamId == currentTeamId
    self.BtnEnterFight:SetDisable(isCurrent, not isCurrent)
end

function XUiBigWorldRoleRoom:OnSelectTab(tabIndex)
    if self._TabIndex == tabIndex then
        return
    end
    self._TabIndex = tabIndex
    self._TeamId = XMVCA.XBigWorldCharacter:GetCommonTeamId(tabIndex)
    self._Team = XMVCA.XBigWorldCharacter:GetDlcTeam(self._TeamId)
    self:UpdateView()
end

function XUiBigWorldRoleRoom:OnBtnDetailClicked()
    --直接关闭界面时，恢复原队伍数据
    --self._Team:Restore()
    if self._PanelRoleList and self._PanelRoleList:IsNodeShow() then
        self._PanelRoleList:Close()
        self.FullscreenClose.gameObject:SetActiveEx(false)
    end

    if self._PanelRoleVList and self._PanelRoleVList:IsNodeShow() then
        self:UpdateCamera(VirtualCamera.Main)
        self._PanelRoleVList:Close()
        self._PanelRoleInfo:Close()
        self.PanelRoom.gameObject:SetActiveEx(true)
    end
    self.BtnBuffDetailClose.gameObject:SetActiveEx(false)
    self.PanelUnder.gameObject:SetActiveEx(true)
    self:UpdateView()
end

function XUiBigWorldRoleRoom:OnBtnChar1Clicked()
    self:OnClickRole(1)
end

function XUiBigWorldRoleRoom:OnBtnChar2Clicked()
    self:OnClickRole(2)
end

function XUiBigWorldRoleRoom:OnBtnChar3Clicked()
    self:OnClickRole(3)
end

function XUiBigWorldRoleRoom:OnClickRole(index)
    if not self._PanelRoleVList then
        self.PanelCharacterFilter.gameObject:SetActiveEx(true)
        local url = XMVCA.XBigWorldResource:GetAssetUrl("PanelVList")
        local ui = self.PanelCharacterFilter:LoadPrefab(url)
        self._PanelRoleVList = require("XUi/XUiBigWorld/XRoleRoom/Panel/XUiPanelBWRoleList").New(ui, self, true)
    end

    local data = self._RoleCameraPoints[index]
    if data then
        self._VirtualCameraDict[VirtualCamera.Role].transform.localPosition = data.Point
        self._VirtualCameraDict[VirtualCamera.Role].transform.localRotation = data.Rotation
    end

    self.PanelRoom.gameObject:SetActiveEx(false)
    self.PanelUnder.gameObject:SetActiveEx(false)
    self._PanelRoleVList:RefreshView(self._TeamId, self._EntityIds[index], index)
    self.BtnBuffDetailClose.gameObject:SetActiveEx(true)
    self:UpdateCamera(VirtualCamera.Role)
end

function XUiBigWorldRoleRoom:OnBtnChar1LongClicked(time)
    self:OnBtnCharLongClicked(1, time)
end

function XUiBigWorldRoleRoom:OnBtnChar1LongPressUp()
    self:OnBtnCharLongPressUp(1)
end

function XUiBigWorldRoleRoom:OnBtnChar2LongClicked(time)
    self:OnBtnCharLongClicked(2, time)
end

function XUiBigWorldRoleRoom:OnBtnChar2LongPressUp()
    self:OnBtnCharLongPressUp(2)
end

function XUiBigWorldRoleRoom:OnBtnChar3LongClicked(time)
    self:OnBtnCharLongClicked(3, time)
end

function XUiBigWorldRoleRoom:OnBtnChar3LongPressUp()
    self:OnBtnCharLongPressUp(3)
end

function XUiBigWorldRoleRoom:OnBtnCharLongClicked(index, time)
    if not self._Proxy:DragEnable() then
        return
    end
    local entityId = self._Team:GetEntityId(index)
    if entityId <= 0 then
        return
    end
    self._LongClickTime = self._LongClickTime + time / 1000
    if self._LongClickTime < self._LongClickInterval then
        return
    end

    self.ImgRoleRepace.gameObject:SetActiveEx(true)
    self.ImgRoleRepace.transform.localPosition = self:GetClickPosition()
end

function XUiBigWorldRoleRoom:OnBtnCharLongPressUp(index)
    if not self.ImgRoleRepace or not self.ImgRoleRepace.gameObject.activeSelf then
        return
    end

    self._LongClickTime = 0
    self.ImgRoleRepace.gameObject:SetActiveEx(false)
    local transformWidth = self.Transform.rect.width
    local targetX = math.floor(self:GetClickPosition().x + transformWidth / 2)
    local oneThirdWidth = transformWidth / 3
    local switchPos = index
    if targetX <= oneThirdWidth then
        switchPos = 1
    elseif targetX > oneThirdWidth and targetX <= oneThirdWidth * 2 then
        switchPos = 2
    else
        switchPos = 3
    end

    if index == switchPos then
        return
    end

    self._Team:SwitchPos(index, switchPos)
    --不同步给服务器
    self:UpdateView()
    --同步给服务器
    --XMVCA.XBigWorldCharacter:RequestUpdateTeam(self._TeamId, function()
    --    self:UpdateView()
    --end)
end

function XUiBigWorldRoleRoom:GetClickPosition()
    return XUiHelper.GetScreenClickPosition(self.Transform, self._Camera)
end

function XUiBigWorldRoleRoom:OnSelectSingle(index, entityId)
    self:UpdateSingleModel(index, entityId)
    if entityId and entityId > 0 then
        self._PanelRoleInfo:RefreshView(self._TeamId, entityId, index)
    end
    self:PlayChangeRoleEffect(index)
end

function XUiBigWorldRoleRoom:OnBtnQuickClick()
    self.BtnBuffDetailClose.gameObject:SetActiveEx(true)
    self.PanelUnder.gameObject:SetActiveEx(false)
    self._PanelRoleList:Open()
    self._PanelRoleList:RefreshView(self._TeamId)
    self.FullscreenClose.gameObject:SetActiveEx(true)
end

function XUiBigWorldRoleRoom:OnBtnEnterFight()
    local team = XMVCA.XBigWorldCharacter:GetDlcTeam(self._TeamId)
    if team:IsEmpty() then
        local text = XMVCA.XBigWorldService:GetText("EmptyTeamTip")
        XUiManager.TipMsg(text)
        return
    end

    XMVCA.XBigWorldCharacter:RequestSetFightingTeam(self._TeamId, function()
        self:UpdateCurrentTeam()
    end)
end

function XUiBigWorldRoleRoom:OnBtnBackClick()
    self.MaskWaiting.gameObject:SetActiveEx(true)
    XMVCA.XBigWorldCharacter:SyncTeamDataToServer()
    
    --XMVCA.XBigWorldCharacter:SyncTeamData(XMVCA.XBigWorldCharacter:GetCurrentTeamId())
end

function XUiBigWorldRoleRoom:UpdateCamera(state)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    for s, vCamera in pairs(self._VirtualCameraDict) do
        vCamera.gameObject:SetActiveEx(s == state)
    end
end

function XUiBigWorldRoleRoom:PlayChangeRoleEffect(index)
    local effect= self._FxChangeRoles[index]
    if not effect then
        return
    end
    effect.gameObject:SetActiveEx(false)
    effect.gameObject:SetActiveEx(true)
end