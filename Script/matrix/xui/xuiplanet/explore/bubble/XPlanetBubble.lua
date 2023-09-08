---@class XPlanetBubble
local XPlanetBubble = XClass(nil, "XPlanet")
local V3 = CS.UnityEngine.Vector3.zero -- 临时变量
local V3_2 = CS.UnityEngine.Vector3.zero

function XPlanetBubble:Ctor(rootProxy, rootUi, camera, scene, parentBubbleRootTrans, followTransform)
    self.RootProxy = rootProxy
    self.RootUi = rootUi
    self.Camera = camera
    self.Scene = scene
    self.ParentBubbleRootTrans = parentBubbleRootTrans
    self.FollowTransform = followTransform
    
    local resource = CS.XResourceManager.Load(XPlanetConfigs.GetUiPlanet2DObj())
    self.Resource = resource
    local ui = CS.UnityEngine.Object.Instantiate(resource.Asset, parentBubbleRootTrans)
    XTool.InitUiObjectByUi(self, ui)
    self.Transform:SetAsFirstSibling()
    self.PanelNum.gameObject:SetActiveEx(false)
    self.PanelBubble.gameObject:SetActiveEx(true)
    
    -- for rewrite
    self._UiHolder = self.PanelBubble

    self:Hide()
end

function XPlanetBubble:SyncPos()
    if not self.Transform or XTool.UObjIsNil(self.Transform) then
        self:Stop()
        return
    end
    if not self.FollowTransform or XTool.UObjIsNil(self.FollowTransform) then
        self:Stop()
        return
    end
    -- 同步位置 (原始偏移)
    local rootUiCanvasTrans = self.RootUi.Transform
    local worldCamera = self.Camera
    local targetPos = self.FollowTransform.localPosition + self.FollowTransform.up * 2

    local v2 = XUiHelper.ObjPosToUguiPos(rootUiCanvasTrans, targetPos, worldCamera)
    V3.x = v2.x
    V3.y = v2.y
    self.Transform.localPosition  = V3
    
    -- 自由视角后偏移
    if self.Scene then
        if self.Scene:CheckCameraIsFreeMode() then
            -- 南北半球后偏移
            V3_2 = self._UiHolder.localPosition
            if V3.y > 0 then -- 北半球
                V3_2.y = 50
            else
                V3_2.y = 100
            end
            -- 东西半球后偏移
            if V3.x < 0 then -- 西半球
                V3_2.x = 70
            else
                V3_2.x = 25
            end
    
        else -- 非自由视角 归位
            V3_2.y = 0
            V3_2.x = 25
        end
        -- 判断看不看得见人
        self:CheckIsInViewToShow()

        self._UiHolder.localPosition = Vector3.Lerp(self._UiHolder.localPosition, V3_2, 0.1) -- 顺滑移动
    end
end

function XPlanetBubble:CheckIsInViewToShow()
    local ballCenterPos = self.Scene:GetPlanetPosition()
    local ballEntityV3 = (self.FollowTransform.position - ballCenterPos).normalized
    local ballCameraV3 = (self.Camera.transform.position - ballCenterPos).normalized
    local angle = XUiHelper.GetAngleByVector3(ballEntityV3, ballCameraV3)
    if angle >= 110 then
        self:Hide()
    else
        self:Show()
    end
end

-- 带生命周期控制的开始播放
function XPlanetBubble:PlayRound(controllerBubbleId)
    if not self.FollowTransform or XTool.UObjIsNil(self.FollowTransform) then
        XLog.Error("角色模型实体已销毁 无法播放气泡")
        return
    end

    self.CurControllerConfig = XPlanetExploreConfigs.GetBubbleController(controllerBubbleId)
    local bubbleId = self.CurControllerConfig.BubbleResId
    self.CurConfig = XPlanetExploreConfigs.GetBubbleRes(bubbleId)
    self:RefreshUiShow()
    
    local now = XTime.GetServerNowTimestamp()
    local stopTimeStamp = now + self.CurControllerConfig.Duration

    local syncFun = function ()
        self:SyncPos()
        if XTime.GetServerNowTimestamp() >= stopTimeStamp then
            self:Stop()
        end
    end
    syncFun()
    self:CheckIsInViewToShow()

    self:StopTimer()
    self.TimerRound = XScheduleManager.ScheduleForever(syncFun, 0, 0)
end

function XPlanetBubble:Play(bubbleId)
    self.CurConfig = XPlanetExploreConfigs.GetBubbleRes(bubbleId)
    self:RefreshUiShow()
    
    local syncFun = function ()
        self:SyncPos()
    end
    syncFun()
    self:Show()

    self:StopTimer()
    self.TimerNormal = XScheduleManager.ScheduleForever(syncFun, 0, 0)
end

function XPlanetBubble:RefreshUiShow()
    if not self.CurConfig then
        return
    end
    self.RImgIcon.gameObject:SetActiveEx(not string.IsNilOrEmpty(self.CurConfig.IconEmoji))
    self.ImgBuble.gameObject:SetActiveEx(not string.IsNilOrEmpty(self.CurConfig.IconSymbol))

    self.RImgIcon:SetRawImage(self.CurConfig.IconEmoji)
    self.ImgBuble:SetRawImage(self.CurConfig.IconSymbol)
end

function XPlanetBubble:StopTimer()
    if self.TimerRound then
        XScheduleManager.UnSchedule(self.TimerRound)
    end
    if self.TimerNormal then
        XScheduleManager.UnSchedule(self.TimerNormal)
    end
end

function XPlanetBubble:Stop()
    self:StopTimer()
    self:Hide()
end

function XPlanetBubble:Hide()
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.GameObject:SetActiveEx(false)
end

function XPlanetBubble:Show()
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.GameObject:SetActiveEx(true)
end

function XPlanetBubble:HideText()
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.PanelNum.gameObject:SetActiveEx(false)
end

function XPlanetBubble:ShowText()
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.PanelNum.gameObject:SetActiveEx(true)
end

function XPlanetBubble:OnDestroy()
    self:Stop()
    self.RootProxy = nil
    self.RootUi = nil
    self.Camera = nil
    self.Scene = nil
    self.FollowTransform = nil
    self.ParentBubbleRootTrans = nil
    self._UiHolder = nil

    CS.XResourceManager.Unload(self.Resource)
end

function XPlanetBubble:UpdateFollowTransform(transform)
    self.FollowTransform = transform
end

return XPlanetBubble