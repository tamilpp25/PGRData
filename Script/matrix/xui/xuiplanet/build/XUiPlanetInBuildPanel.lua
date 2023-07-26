---@class XUiPlanetInBuildPanel
local XUiPlanetInBuildPanel = XClass(nil, "XUiPlanetInBuildPanel")

function XUiPlanetInBuildPanel:Ctor(rootUi, ui, isTalent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.Scene = isTalent and XDataCenter.PlanetManager.GetPlanetMainScene() or XDataCenter.PlanetManager.GetPlanetStageScene()
    self.OpenCb = nil
    self.CloseCb = nil
    self.FollowTimer = nil

    self.GameObject:SetActiveEx(false)
    self:AddBtnClickListener()
end

function XUiPlanetInBuildPanel:SetCallBack(openCb, closeCb)
    self.OpenCb = openCb
    self.CloseCb = closeCb
end


--region ui
function XUiPlanetInBuildPanel:Open()
    self:StartFollowTimer()
    self.GameObject:SetActiveEx(true)
    if self.OpenCb then self.OpenCb() end
end

function XUiPlanetInBuildPanel:Hide()
    self:StopFollowTimer()
    self.GameObject:SetActiveEx(false)
    if self.CloseCb then self.CloseCb() end
end

function XUiPlanetInBuildPanel:IsOpen()
    return self.GameObject.activeSelf
end
--endregion


--region 面板跟随
function XUiPlanetInBuildPanel:StartFollowTimer()
    self:StopFollowTimer()
    self.FollowTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:StopFollowTimer()
            return
        end
        self:FollowBuilding()
    end, 0, 0)
end

function XUiPlanetInBuildPanel:StopFollowTimer()
    if self.FollowTimer then
        XScheduleManager.UnSchedule(self.FollowTimer)
    end
    self.FollowTimer = nil
end

function XUiPlanetInBuildPanel:FollowBuilding()
    local offset = self.Bg.transform.localPosition
    
    local screenPoint = self.Scene:GetCamera():WorldToScreenPoint(self.Scene:GetCurPreBuildingListPosition())
    local screenPoint_v2 = Vector2(screenPoint.x, screenPoint.y)
    local hasValue, localPoint = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.RootUi.Transform, screenPoint_v2, CS.XUiManager.Instance.UiCamera)
    self.Transform.localPosition = Vector3(localPoint.x, localPoint.y, 0) - offset
end
--endregion


--region 按钮绑定
function XUiPlanetInBuildPanel:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnBtnCancelClick)
    XUiHelper.RegisterClickEvent(self, self.BtnOk, self.OnBtnOkClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRotate, self.OnBtnRotateClick)

    self.XUiWidget:AddDragListener(function(eventData)
        self:OnDrag(eventData)
    end)
end

function XUiPlanetInBuildPanel:OnBtnCancelClick()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
    self:Hide()
    self.Scene:RemoveCurBuildingList()
end

function XUiPlanetInBuildPanel:OnBtnOkClick()
    self:Hide()
    self.Scene:InsertCurBuildingList()
end

function XUiPlanetInBuildPanel:OnBtnRotateClick()
    self.Scene:RotateCurBuildingList()
end

function XUiPlanetInBuildPanel:OnDrag(eventData)
    local tile = self.Scene:GetCameraRayTile()
    if not tile then
        return
    end
    self.Scene:MoveCurBuildingList(tile.TileId)
end
--endregion

return XUiPlanetInBuildPanel