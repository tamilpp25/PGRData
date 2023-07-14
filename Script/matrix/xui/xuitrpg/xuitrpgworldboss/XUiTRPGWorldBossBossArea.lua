local XUiTRPGWorldBossBossArea = XLuaUiManager.Register(XLuaUi, "UiTRPGWorldBossBossArea")
local XUiTRPGPanelEnter = require("XUi/XUiTRPG/XUiTRPGWorldBoss/XUiTRPGPanelEnter")
local XUiTRPGPanelDetail = require("XUi/XUiTRPG/XUiTRPGWorldBoss/XUiTRPGPanelDetail")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local PanelState = {
    Enter = 1,
    Detail = 2
}

local CameraIndex = {
    Main = 1,
    Detail = 2
}

local TRPGWorldBossFirstStoryKey = "TRPGWorldBossFirstStoryKey"

function XUiTRPGWorldBossBossArea:OnAwake()
    self:Init3DScene()
end

function XUiTRPGWorldBossBossArea:OnStart()
    self.PanelEnter = XUiTRPGPanelEnter.New(self.PanelEnterObj, function(panelState) self:SetPanelState(panelState) end)
    self.PanelDetail = XUiTRPGPanelDetail.New(self.PanelDetailObj, self)
    self:SetPanelState(PanelState.Enter)
    self:SetButtonCallBack()
    self:RefreshModel()
    self:PlayStartStory()
end

function XUiTRPGWorldBossBossArea:OnEnable()
    self.Schedule = XScheduleManager.ScheduleForever(function() self:CheckCloseWorldBossArea() end, XScheduleManager.SECOND)
    XDataCenter.TRPGManager.RequestTRPGBossDetailSend(function() self:Refresh() end)
end

function XUiTRPGWorldBossBossArea:OnDisable()
    XScheduleManager.UnSchedule(self.Schedule)
end

function XUiTRPGWorldBossBossArea:Refresh()
    self.PanelEnter:UpdatePanelPhasesReward()
    self.PanelDetail:UpdateActivityInfo()
end

function XUiTRPGWorldBossBossArea:CheckCloseWorldBossArea()
    local openState = XDataCenter.TRPGManager.GetWorldBossOpenState()
    if openState == XTRPGConfigs.AreaStateType.NotOpen or openState == XTRPGConfigs.AreaStateType.Over then
        local msg = CS.XTextManager.GetText("TRPGWorldBossOver")
        XUiManager.TipMsg(msg, nil, function() self:Close() end)
    end
end

function XUiTRPGWorldBossBossArea:Init3DScene()
    local root = self.UiModelGo.transform
    self.RoleModelPanel = XUiPanelRoleModel.New(root:FindTransform("PanelModel"), self.Name, nil, true, nil, true)
    self.CameraNear = {
        [CameraIndex.Main] = root:FindTransform("NearCameraMain"),
        [CameraIndex.Detail] = root:FindTransform("NearCameraDetail"),
    }
    self.CameraFar = {
        [CameraIndex.Main] = root:FindTransform("FarCameraMain"),
        [CameraIndex.Detail] = root:FindTransform("FarCameraDetail"),
    }
end

function XUiTRPGWorldBossBossArea:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end

    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, "TRPGMainLine")
end

function XUiTRPGWorldBossBossArea:SetPanelState(state)
    if state == PanelState.Enter then
        self.PanelEnter:SetShow(true)
        self.PanelDetail:SetShow(false)
        self.CameraNear[CameraIndex.Main].gameObject:SetActiveEx(true)
        self.CameraNear[CameraIndex.Detail].gameObject:SetActiveEx(false)
        self.CameraFar[CameraIndex.Main].gameObject:SetActiveEx(true)
        self.CameraFar[CameraIndex.Detail].gameObject:SetActiveEx(false)
        self:PlayAnimation("PanelEnterAnimEnable")
    elseif state == PanelState.Detail then
        self.PanelEnter:SetShow(false)
        self.PanelDetail:SetShow(true)
        self.CameraNear[CameraIndex.Main].gameObject:SetActiveEx(false)
        self.CameraNear[CameraIndex.Detail].gameObject:SetActiveEx(true)
        self.CameraFar[CameraIndex.Main].gameObject:SetActiveEx(false)
        self.CameraFar[CameraIndex.Detail].gameObject:SetActiveEx(true)
        self:PlayAnimation("PanlDetailAnimEnable2")
    end
    self.CurPanelState = state
end

function XUiTRPGWorldBossBossArea:OnBtnBackClick()
    if self.CurPanelState == PanelState.Detail then
        self:SetPanelState(PanelState.Enter)
    else
        self:Close()
    end
end

function XUiTRPGWorldBossBossArea:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTRPGWorldBossBossArea:RefreshModel()
    local modelId = XTRPGConfigs.GetBossModelId()
    self.RoleModelPanel:UpdateBossModel(modelId, XModelManager.MODEL_UINAME.XUiTRPGWorldBossBossArea, nil, nil, true)
    self.RoleModelPanel:ShowRoleModel()
end

function XUiTRPGWorldBossBossArea:PlayStartStory()
    local startStroy = XTRPGConfigs.GetBossStartStoryId()
    if not startStroy then return end

    local IsCanPlay = XDataCenter.TRPGManager.CheckIsNewStoryID(startStroy, TRPGWorldBossFirstStoryKey)
    if IsCanPlay then
        XDataCenter.MovieManager.PlayMovie(startStroy)
        XDataCenter.TRPGManager.MarkStoryID(startStroy, TRPGWorldBossFirstStoryKey)
    end
end

function XUiTRPGWorldBossBossArea:OnGetEvents()
    return { XEventId.EVENT_TRPG_WORLDBOSS_SYNCDATA }
end

function XUiTRPGWorldBossBossArea:OnNotify(evt)
    if evt == XEventId.EVENT_TRPG_WORLDBOSS_SYNCDATA then
        self:Refresh()
    end
end