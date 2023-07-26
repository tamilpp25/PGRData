---负责管理预览场景的加载显示的类
local XBackgroundScene=XClass(nil,"XBackgroundScene")


local XQualityManager = CS.XQualityManager.Instance
local BatteryComponent = CS.XUiBattery
local DateStartTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeStr")
local DateEndTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeEnd")
local LowPowerValue = CS.XGame.ClientConfig:GetFloat("UiMainLowPowerValue")

function XBackgroundScene:Ctor(parent)
    self.Parent=parent
end

---切换预览场景
function XBackgroundScene:ChangeScenePreview(sceneModeId,firstload)
    local scenePath,modelPath = XSceneModelConfigs.GetSceneAndModelPathById(sceneModeId)
    local _this=self
    if not firstload then
        self.Parent:PlayAnimation('Loading',function()
            _this.Parent:LoadUiScene(scenePath, modelPath, function() _this:OnUiSceneLoaded(firstload) end, false)
        end)
    else
        --第一次加载已经是从黑屏过度了，就不用在淡入淡出一次
        self.Parent:LoadUiScene(scenePath,modelPath,function() _this:OnUiSceneLoaded(firstload) end, false)
    end
end

function XBackgroundScene:OnUiSceneLoaded(firstload)
    --加载新场景要刷新电池模式
    self.CurBatteryMode=nil
    --刷新右上角信息栏显示
    self.Parent:RefreshRightTagPanel()
    --刷新同步按钮
    self.Parent:RefreshSyncBtnState()
    if not firstload then
        --执行淡出动画
        self.Parent:PlayAnimation('Loading2')
    end
    --self.Parent:SetGameObject()
    self:InitSceneRoot()
    self:UpdateCamera()
    if  self:InitBatteryUi() then
        self:UpdateBatteryMode()
    end    
    -- 开启时钟
    self.Parent:ReStartClockTime()
end

function XBackgroundScene:InitSceneRoot()
    local root = self.Parent.UiModelGo.transform
    self.CameraFar = self.Parent:FindVirtualCamera("CamFarMain")
    self.CameraNear = self.Parent:FindVirtualCamera("CamNearMain")
    self.CameraComponentFar = root:FindTransform("UiFarCamera"):GetComponent("Camera")
    self.CameraComponentNear = root:FindTransform("UiNearCamera"):GetComponent("Camera")
    self.UiModelParent = root:FindTransform("UiModelParent")
    self.ChangeActionEffect = root:FindTransform("ChangeActionEffect")
end

function XBackgroundScene:InitBatteryUi()
    self.animationRoot = self.Parent.UiSceneInfo.Transform:Find("Animations")
    if XTool.UObjIsNil(self.animationRoot) then return false end
    
    self.toChargeTimeLine = self.animationRoot:Find("ToChargeTimeLine")
    self.toFullTimeLine = self.animationRoot:Find("ToFullTimeLine")
    self.fullTimeLine = self.animationRoot:Find("FullTimeLine")
    self.chargeTimeLine = self.animationRoot:Find("ChargeTimeLine")

    self.toChargeTimeLine.gameObject:SetActiveEx(false)
    self.toFullTimeLine.gameObject:SetActiveEx(false)
    self.fullTimeLine.gameObject:SetActiveEx(false)
    self.chargeTimeLine.gameObject:SetActiveEx(false)
    
    return true
end

function XBackgroundScene:UpdateCamera()
    self.CameraFar.gameObject:SetActiveEx(true)
    self.CameraNear.gameObject:SetActiveEx(true)
end

function XBackgroundScene:UpdateBatteryMode()
    
    if XTool.UObjIsNil(self.animationRoot) then return end

    --先还原状态
    self.toChargeTimeLine.gameObject:SetActiveEx(false)
    self.toFullTimeLine.gameObject:SetActiveEx(false)
    self.fullTimeLine.gameObject:SetActiveEx(false)
    self.chargeTimeLine.gameObject:SetActiveEx(false)
    
    local curSelectSceneId = self.Parent.SceneList:GetCurDisplaySceneId()
    local particleGroupName = XDataCenter.PhotographManager.GetSceneTemplateById(curSelectSceneId).ParticleGroupName
    local chargeAnimator = nil
    if particleGroupName and particleGroupName ~= "" then
        local chargeAnimatorTrans = self.Parent.UiSceneInfo.Transform:FindTransform(particleGroupName)
        if chargeAnimatorTrans then
            chargeAnimator = chargeAnimatorTrans:GetComponent("Animator")
        else
            XLog.Error("Can't Find \"" .. particleGroupName .. "\", Plase Check \"ParticleGroupName\" In Share/PhotoMode/Background.tab")
        end
    end

    local type = XPhotographConfigs.GetBackgroundTypeById(curSelectSceneId)
    if type == XPhotographConfigs.BackGroundType.PowerSaved then
        if BatteryComponent.IsCharging then --充电状态
            self:PlayBatteryModeAnimation(false,chargeAnimator)
            XDataCenter.PhotographManager.UpdatePreviewState(true, true)
        else
            if BatteryComponent.BatteryLevel > LowPowerValue then -- 比较电量
                self:PlayBatteryModeAnimation(false,chargeAnimator)
                XDataCenter.PhotographManager.UpdatePreviewState(true, true)
            else
                self:PlayBatteryModeAnimation(true,chargeAnimator)
                XDataCenter.PhotographManager.UpdatePreviewState(false, true)
            end
        end
    else
        --时间模式判断
        local startTime = XTime.ParseToTimestamp(DateStartTime)
        local endTime = XTime.ParseToTimestamp(DateEndTime)
        local nowTime = XTime.ParseToTimestamp(CS.System.DateTime.Now:ToLocalTime():ToString())
        if startTime > nowTime and nowTime > endTime then   -- 比较时间
            self:PlayBatteryModeAnimation(false,chargeAnimator)
            XDataCenter.PhotographManager.UpdatePreviewState(true, true)
        else
            self:PlayBatteryModeAnimation(true,chargeAnimator)
            XDataCenter.PhotographManager.UpdatePreviewState(false, true)
        end
    end
end

-- 执行与电池模式Timeline动画相关逻辑
--@ IsSetLow：目标状态是否是低电量/夜晚模式
--@chargeAnimator: 传入的动画控制器
function XBackgroundScene:PlayBatteryModeAnimation(IsSetLow,chargeAnimator)
    if self.CurBatteryMode==XPhotographConfigs.BackGroundState.Full then
        if IsSetLow then
            if chargeAnimator then chargeAnimator:Play("FullToLow") end
            self.CurBatteryMode=XPhotographConfigs.BackGroundState.Low
            self.toChargeTimeLine.gameObject:SetActiveEx(true)
        else
            if chargeAnimator then chargeAnimator:Play("Full") end
            self.fullTimeLine.gameObject:SetActiveEx(true)
        end
    elseif self.CurBatteryMode==XPhotographConfigs.BackGroundState.Low then
        if IsSetLow then
            if chargeAnimator then chargeAnimator:Play("Low") end
            self.chargeTimeLine.gameObject:SetActiveEx(true)
        else
            if chargeAnimator then chargeAnimator:Play("LowToFull") end
            self.CurBatteryMode=XPhotographConfigs.BackGroundState.Full
            self.toFullTimeLine.gameObject:SetActiveEx(true)
        end
    else    --如果没有有效值，说明是第一次打开该场景，直接设置状态
        if IsSetLow then
            if chargeAnimator then chargeAnimator:Play("Low") end
            self.CurBatteryMode=XPhotographConfigs.BackGroundState.Low
            self.chargeTimeLine.gameObject:SetActiveEx(true)
        else
            if chargeAnimator then chargeAnimator:Play("Full") end
            self.CurBatteryMode=XPhotographConfigs.BackGroundState.Full
            self.fullTimeLine.gameObject:SetActiveEx(true)
        end
    end
end

return XBackgroundScene