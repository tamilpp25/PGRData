local XUiSceneMainPreview = XLuaUiManager.Register(XLuaUi, "UiSceneMainPreview")

local ShowCD = CS.XGame.ClientConfig:GetFloat("ScenePreviewUiHideCD")
local HideDelayCD = CS.XGame.ClientConfig:GetFloat("ScenePreviewUiHideDelay")


function XUiSceneMainPreview:OnAwake()
    self:AddClickListener()
end

function XUiSceneMainPreview:OnStart(sceneId,openType)
    self.SceneId = sceneId
    self:AutoSetUi()
    self.OpenType=openType
    self.CloseByHand = false
end

function XUiSceneMainPreview:OnEnable()
    self:StartScheduleToHideUi(HideDelayCD)
    self:Refresh()

    XEventManager.DispatchEvent(XEventId.EVENT_SCENE_PREVIEW)
    XEventManager.DispatchEvent(XEventId.EVENT_SCENE_UIMAIN_STATE_CHANGE)

    self:AddEventListener()
end

function XUiSceneMainPreview:OnDisable()
    self:StopScheduleToHideUi()
    self:RemoveEventListener()
end

function XUiSceneMainPreview:OnDestroy()
    if not self.CloseByHand then
        self.CloseByHand = true
        XDataCenter.PhotographManager.ClearPreviewSceneId()
        if self.OpenType ~= XPhotographConfigs.PreviewOpenType.SceneSetting then
            XDataCenter.GuideManager.SetDisableGuide(false)
        end
    end
end

function XUiSceneMainPreview:Refresh()
    self.TogPreview.isOn = true
    local isFirst = XDataCenter.PhotographManager.GetPreviewState() == XPhotographConfigs.BackGroundState.Full
    if self.BtnSwitch then
        self.BtnSwitch:RefreshSelect(isFirst)
    end
    -- Todo 角色特效
end

function XUiSceneMainPreview:StartScheduleToHideUi(time)
    self:StopScheduleToHideUi()
    self.HideTimer = XScheduleManager.ScheduleAtTimestamp(function()
        self:PlayAnimationWithMask("UiDisable")
        self.InTimer = false
    end, XTime.GetServerNowTimestamp() + time)
    self.InTimer = true
end

function XUiSceneMainPreview:StopScheduleToHideUi()
    if XTool.IsNumberValid(self.HideTimer) then
        XScheduleManager.UnSchedule(self.HideTimer)
    end
    self.InTimer = false
end

-- 播放Ui渐显动画
function XUiSceneMainPreview:PlayUiShowAnim()
    self:PlayAnimationWithMask("UiEnable", function ()
        -- 开启自动重启倒计时
        self:StartScheduleToHideUi(ShowCD)
    end)
end

function XUiSceneMainPreview:AutoSetUi()
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
    self.TogPreview.isOn = true
    self.Scene.gameObject:SetActiveEx(false)
    self.SceneText.gameObject:SetActiveEx(false)

    if self.SwitchBtn == nil then return end
    if not XTool.IsTableEmpty(XPhotographConfigs.GetBackgroundSwitchDescById(self.SceneId)) then
        local btn = require("XUi/XUiSceneTip/XUiSwitchBtn")
        local isFirst = XDataCenter.PhotographManager.GetPreviewState() == XPhotographConfigs.BackGroundState.Full
        self.BtnSwitch = btn.New(self.SwitchBtn, isFirst, self.SceneId, function ()
            self:OnBtnUiClick()
        end)
    else
        self.SwitchBtn.gameObject:SetActiveEx(false)
    end
    self.SceneText.gameObject:SetActiveEx(false)
end

function XUiSceneMainPreview:AddClickListener()
    self:RegisterClickEvent(self.TogPreview, self.OnTogPreviewClick)
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnUiAwake, self.OnBtnUiClick)
end

-- 唤醒Ui
function XUiSceneMainPreview:OnBtnUiClick()
    if not self.InTimer then
        self:PlayUiShowAnim()
    else
        self:StartScheduleToHideUi(ShowCD)
    end
end

function XUiSceneMainPreview:OnTogPreviewClick()
    if not self.InTimer then 
        self:PlayUiShowAnim()
        self.TogPreview.isOn = true
    else
        XDataCenter.PhotographManager.ClearPreviewSceneId()
        XLuaUiManager.Open("UiSceneTip", self.SceneId,self.OpenType)
        --self.Super.Close(self)
        -- XLuaUiManager.Close("UiMain")
        XDataCenter.GuideManager.SetDisableGuide(false)
    end
end

function XUiSceneMainPreview:Close()
    if not self.InTimer then 
        self:PlayUiShowAnim()
    else
        self:ClearPreviewData()
    end
    self.CloseByHand = true
end

function XUiSceneMainPreview:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_PREVIEW_STATE_CHANGE, self.PlayChangeModeAnim, self)
end

function XUiSceneMainPreview:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_PREVIEW_STATE_CHANGE, self.PlayChangeModeAnim, self)
end

function XUiSceneMainPreview:PlayChangeModeAnim()
    self:PlayAnimationWithMask("DarkEnable", function ()
        XEventManager.DispatchEvent(XEventId.EVENT_SCENE_UIMAIN_STATE_CHANGE)
        self:Refresh()
        self:PlayAnimationWithMask("DarkDisable")
    end)
end

function XUiSceneMainPreview:ClearPreviewData()
    XDataCenter.PhotographManager.ClearPreviewSceneId()
    --XLuaUiManager.Remove("UiSceneTip")
    self.Super.Close(self)
    if self.OpenType == XPhotographConfigs.PreviewOpenType.SceneSetting then
        XLuaUiManager.CloseWithCallback("UiMain", function()
            XDataCenter.GuideManager.SetDisableGuide(false)
        end)
    end
    
end 