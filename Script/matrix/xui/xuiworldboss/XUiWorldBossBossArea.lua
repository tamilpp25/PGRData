local XUiWorldBossBossArea = XLuaUiManager.Register(XLuaUi, "UiWorldBossBossArea")
local XUiPanelEnter = require("XUi/XUiWorldBoss/XUiPanelEnter")
local XUiPanelDetail = require("XUi/XUiWorldBoss/XUiPanelDetail")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local DefaultLevel = 1
local PanelState = {
    Enter = 1,
    Detail = 2
}

local CameraIndex = {
    Main = 1,
    Detail = 2
}

function XUiWorldBossBossArea:OnAwake()
    self:Init3DScene()
end

function XUiWorldBossBossArea:OnStart(Id)
    XDataCenter.WorldBossManager.SetBossStageLevel(DefaultLevel)
    self.PanelEnter = XUiPanelEnter.New(self.PanelEnterObj, self, Id)
    self.PanelDetail = XUiPanelDetail.New(self.PanelDetailObj, self, Id)
    self:SetPanelState(PanelState.Enter)
    self:SetButtonCallBack()
    self:RefreshModel(Id)
    self:PlayFinishStory(Id)
end

function XUiWorldBossBossArea:OnDestroy()

end

function XUiWorldBossBossArea:OnEnable()
    XDataCenter.WorldBossManager.CheckWorldBossActivityReset()
    self.PanelEnter:UpdatePanelPhasesReward()
    self.PanelDetail:UpdateActivityInfo()
    XEventManager.AddEventListener(XEventId.EVENT_WORLDBOSS_SYNCDATA, self.UpdatePhasesReward, self)
end

function XUiWorldBossBossArea:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_WORLDBOSS_SYNCDATA, self.UpdatePhasesReward, self)
end

function XUiWorldBossBossArea:Init3DScene()
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

function XUiWorldBossBossArea:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end

    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, "WorldBossHelp")
end

function XUiWorldBossBossArea:SetPanelState(state)
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

function XUiWorldBossBossArea:OnBtnBackClick()
    if self.CurPanelState == PanelState.Detail then
        self:SetPanelState(PanelState.Enter)
    else
        self:Close()
    end
end

function XUiWorldBossBossArea:UpdatePhasesReward()
    self.PanelEnter:UpdatePanelPhasesReward()
end

function XUiWorldBossBossArea:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiWorldBossBossArea:OnBtnShopClick()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        XLuaUiManager.Open("UiShop", XShopManager.ShopType.WorldBoss)
    end
end

function XUiWorldBossBossArea:RefreshModel(areaId)
    local bossArea = XDataCenter.WorldBossManager.GetBossAreaById(areaId)
    self.RoleModelPanel:UpdateBossModel(bossArea:GetModelId(), XModelManager.MODEL_UINAME.XUiWorldBossBossArea)
    self.RoleModelPanel:ShowRoleModel()
end

function XUiWorldBossBossArea:PlayFinishStory(areaId)
    local bossArea = XDataCenter.WorldBossManager.GetBossAreaById(areaId)
    if bossArea:GetIsFinish() then
        local storyId = bossArea:GetFinishStoryId()
        if storyId and #storyId > 1 then
            local IsCanPlay = XDataCenter.WorldBossManager.CheckIsNewStoryID(storyId)
            if IsCanPlay then
                XDataCenter.MovieManager.PlayMovie(storyId)--一次
                XDataCenter.WorldBossManager.MarkStoryID(storyId)
            end
        end
    end
end