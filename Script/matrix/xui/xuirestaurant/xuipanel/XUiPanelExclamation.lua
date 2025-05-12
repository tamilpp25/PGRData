
---@class XUiPanelExclamation : XUiNode 提示类
---@field _Control XRestaurantControl
local XUiPanelExclamation = XClass(XUiNode, "XUiPanelExclamation")

function XUiPanelExclamation:OnStart(isIndent)
    self.IsIndent = isIndent
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
end

function XUiPanelExclamation:OnEnable()
    self.ViewModel = self.IsIndent and self._Control:GetRunningIndent() or self._Control:GetRunningPerform()
    self:RefreshView()
end

function XUiPanelExclamation:RefreshView()
    if not self.ViewModel then
        self:Close()
        return
    end
    local finish = self.ViewModel:CheckPerformFinish()
    local going = self.ViewModel:IsOnGoing()
    local notStart = self.ViewModel:IsNotStart()
    self.PanelComplete.gameObject:SetActiveEx(finish)
    self.PanelOnGoing.gameObject:SetActiveEx(not finish and going)
    self.PanelNotStart.gameObject:SetActiveEx(not finish and notStart)
end

function XUiPanelExclamation:OnBtnClick()
    if not self.ViewModel then
        self:Close()
        return
    end
    local cameraMd = self._Control:GetRoom():GetCameraModel()
    local areaType = cameraMd:GetAreaType()

    local performId = self.ViewModel:GetPerformId()
    if self._Control:IsSaleArea(areaType) then
        self._Control:OpenPerformUi(performId)
        return
    end
    
    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_CHANGE_MAIN_VIEW_CAMERA_AREA_TYPE, 
            XMVCA.XRestaurant.AreaType.SaleArea)
    
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        if not self.ViewModel or not self._Control then
            return
        end
        self._Control:OpenPerformUi(performId)
    end, cameraMd:GetMoveDuration() * XScheduleManager.SECOND)
    
end

return XUiPanelExclamation