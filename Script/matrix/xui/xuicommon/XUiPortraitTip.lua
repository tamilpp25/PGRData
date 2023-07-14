
local XUiPortraitTip = XLuaUiManager.Register(XLuaUi, "UiPortraitTip")

local TIP_MSG_SHOW_TIME = 2000

function XUiPortraitTip:OnAwake()
    self:InitCb()
end

--==============================
---@desc 竖屏提示
---@msg 提示信息
---@cb 关闭回调
---@hideCloseMask 隐藏关闭按钮
--==============================
function XUiPortraitTip:OnStart(msg, cb, hideCloseMark)
    self.CloseCb = cb
    self.Closed = false
    self:HideTipLayer()
    self.BtnClose.interactable = true
    self.BtnClose.gameObject:SetActive(not hideCloseMark)
    XUiHelper.StopAnimation()

    self.PanelTip.gameObject:SetActiveEx(true)
    self:PlayAnimation("PanelTip")
    self.TxtInfo.text = msg
    
    local popped = function() 
        self:Close()
    end
    local closeHook = function()
        if not XTool.UObjIsNil(self.GameObject) then
            self:PlayAnimation("PanelTipEnd", popped)
        end
    end
    
    self.CloseHook = closeHook
    self.Timer = XScheduleManager.ScheduleOnce(function()
        if not self.Closed then
            self.Closed = true
            closeHook()
        end
    end, TIP_MSG_SHOW_TIME)
end 

function XUiPortraitTip:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiPortraitTip:InitCb()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnClose)
end 

function XUiPortraitTip:HideTipLayer()
    self.PanelTip.gameObject:SetActiveEx(false)
    self.PanelError.gameObject:SetActiveEx(false)
    self.PanelSuccess.gameObject:SetActiveEx(false)
end

function XUiPortraitTip:OnBtnClose()
    if self.Closed then
        return
    end
    self.Closed = true
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
    self.BtnClose.interactable = false
    if self.CloseHook then
        self.CloseHook()
    else
        self:Close()
    end
end 