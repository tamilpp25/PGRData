local XUiSceneTip = XLuaUiManager.Register(XLuaUi, "UiSceneTip")

local UiMainMenuType = {
    Main = 1,
    Second = 2,
}

function XUiSceneTip:OnAwake()
    self:AddClickListener()
end

function XUiSceneTip:OnStart(sceneId,openType)
    self.SceneId = sceneId
    self.OpenType=openType
    local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(self.SceneId)
    local scenePath, modelPath = XSceneModelConfigs.GetSceneAndModelPathById(sceneTemplate.SceneModelId)
    self:LoadUiScene(scenePath, modelPath, function() self:SetBatteryUi() end, false)
    self:AutoSetUi()
end

function XUiSceneTip:OnEnable()
    self:Refresh()
    self:AddEventListener()

    -- 开启时钟
    self.ClockTimer = XUiHelper.SetClockTimeTempFun(self)
end

function XUiSceneTip:OnDisable()
    self:RemoveEventListener()

    -- 关闭时钟
    if self.ClockTimer then
        XUiHelper.StopClockTimeTempFun(self, self.ClockTimer)
        self.ClockTimer = nil
    end
end

function XUiSceneTip:Refresh()
    self:UpdateBatteryMode()
    self.TogPreview.isOn = false
    local isFirst = XDataCenter.PhotographManager.GetPreviewState() == XPhotographConfigs.BackGroundState.Full
    if self.BtnSwitch then self.BtnSwitch:RefreshSelect(isFirst) end
end

function XUiSceneTip:SetBatteryUi()
    --self:SetGameObject()
    -- 场景虚拟相机
    self.CamFarMain = self:FindVirtualCamera("CamFarMain")
    if self.CamFarMain then self.CamFarMain.gameObject:SetActive(true) end
    -- 场景动画
    self.AnimationRoot = self.UiSceneInfo.Transform:Find("Animations")
    if XTool.UObjIsNil(self.AnimationRoot) then return end

    self.ToChargeTimeLine = self.AnimationRoot:Find("ToChargeTimeLine")
    self.ToFullTimeLine = self.AnimationRoot:Find("ToFullTimeLine")
    self.FullTimeLine = self.AnimationRoot:Find("FullTimeLine")
    self.ChargeTimeLine = self.AnimationRoot:Find("ChargeTimeLine")

    self.ToChargeTimeLine.gameObject:SetActiveEx(false)
    self.ToFullTimeLine.gameObject:SetActiveEx(false)
    self.FullTimeLine.gameObject:SetActiveEx(false)
    self.ChargeTimeLine.gameObject:SetActiveEx(false)
end

function XUiSceneTip:UpdateBatteryMode()
    if XTool.UObjIsNil(self.AnimationRoot) then return end
    local particleGroupName = XDataCenter.PhotographManager.GetSceneTemplateById(self.SceneId).ParticleGroupName
    local chargeAnimator = nil
    if particleGroupName and particleGroupName ~= "" then
        local chargeAnimatorTrans = self.UiSceneInfo.Transform:FindTransform(particleGroupName)
        if chargeAnimatorTrans then
            chargeAnimator = chargeAnimatorTrans:GetComponent("Animator")
        else
            XLog.Error("Can't Find \"" .. particleGroupName .. "\", Plase Check \"ParticleGroupName\" In Share/PhotoMode/Background.tab")
        end
    end

    if XDataCenter.PhotographManager.GetPreviewState() == XPhotographConfigs.BackGroundState.Full then --满电状态
        if chargeAnimator then chargeAnimator:Play("Full") end
        self.FullTimeLine.gameObject:SetActiveEx(true)
        self.ChargeTimeLine.gameObject:SetActiveEx(false)
    else
        if chargeAnimator then chargeAnimator:Play("Low") end
        self.FullTimeLine.gameObject:SetActiveEx(false)
        self.ChargeTimeLine.gameObject:SetActiveEx(true)
    end
end

function XUiSceneTip:AutoSetUi()
    local tags = XPhotographConfigs.GetBackgroundTagById(self.SceneId)
    local sceneName = XPhotographConfigs.GetBackgroundNameById(self.SceneId)

    for i = 1, 2 do
        local name = "Function" .. i
        local txtName = "TxtFunction" .. i
        if not string.IsNilOrEmpty(tags[i])then
            self[name].gameObject:SetActiveEx(true)
            self[txtName].text = tags[i]
        else
            self[name].gameObject:SetActiveEx(false)
        end
    end

    self.SceneName.text = sceneName
    self.TogPreview.isOn = false
    self.BtnUiAwake.gameObject:SetActiveEx(false)

    if self.SwitchBtn == nil then return end
    if  not XTool.IsTableEmpty(XPhotographConfigs.GetBackgroundSwitchDescById(self.SceneId))  then
        local btn = require("XUi/XUiSceneTip/XUiSwitchBtn")
        self.BtnSwitch = btn.New(self.SwitchBtn, XDataCenter.PhotographManager.GetPreviewState() == XPhotographConfigs.BackGroundState.Full, self.SceneId)
    else
        self.SwitchBtn.gameObject:SetActiveEx(false)
    end
end

function XUiSceneTip:AddClickListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.TogPreview, self.OnTogPreview)
end

function XUiSceneTip:OnBtnBackClick()
    -- 清除预览场景Id避免返回主界面场景未恢复原有场景
    XDataCenter.PhotographManager.ClearPreviewSceneId()
    XLuaUiManager.Remove("UiSceneMainPreview")
    XDataCenter.GuideManager.SetDisableGuide(false)
    if self.OpenType==XPhotographConfigs.PreviewOpenType.SceneSetting then
        XLuaUiManager.RemoveTopOne('UiMain')
    end
    self:Close()
    
end

function XUiSceneTip:OnTogPreview()
    self:PlayAnimationWithMask("DarkEnable", function ()
        if self.OpenType==XPhotographConfigs.PreviewOpenType.SceneSetting then
            XDataCenter.PhotographManager.SetPreviewSceneId(self.SceneId)
            XDataCenter.GuideManager.SetDisableGuide(true)
            XEventManager.DispatchEvent(XEventId.EVENT_SCENE_UIMAIN_RIGHTMIDTYPE_CHANGE, UiMainMenuType.Main)
            self:Close()
        else
            XLuaUiManager.RemoveTopOne('UiSceneTip')
            XDataCenter.PhotographManager.OpenScenePreview(self.SceneId)
        end
    end)
end

function XUiSceneTip:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_PREVIEW_STATE_CHANGE, self.PlayChangeModeAnim, self)
end

function XUiSceneTip:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_PREVIEW_STATE_CHANGE, self.PlayChangeModeAnim, self)
end

function XUiSceneTip:PlayChangeModeAnim()
    self:PlayAnimationWithMask("DarkEnable", function ()
        self:Refresh()
        self:PlayAnimationWithMask("DarkDisable", function ()
        end)
    end)
end