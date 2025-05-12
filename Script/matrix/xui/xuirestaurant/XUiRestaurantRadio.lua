
---@class XUiRestaurantRadio : XLuaUi
local XUiRestaurantRadio = XLuaUiManager.Register(XLuaUi, "UiRestaurantRadio")

local TIP_MSG_SHOW_TIME = 3000

function XUiRestaurantRadio:OnAwake()
    self:InitUi()
end

function XUiRestaurantRadio:OnStart(txtTip)
    self.TxtTip = txtTip
    self.OnDestroyUiMap = {
        UiRestaurantMain    = true,
        UiRestaurantCommon  = true
    }
    self.InView = true
    self:InitView()
end

function XUiRestaurantRadio:OnGetEvents()
    return {
        CS.XEventId.EVENT_UI_DESTROY,
    }
end

function XUiRestaurantRadio:OnNotify(evt, ...)
    if evt == CS.XEventId.EVENT_UI_DESTROY then
        self:OnUiDestroy(...)
    end
end

function XUiRestaurantRadio:OnRelease()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
    self.Super.OnRelease(self)
end

function XUiRestaurantRadio:Close()
    self.Super.Close(self)
end

function XUiRestaurantRadio:InitUi()
    self.PanelText.gameObject:SetActiveEx(false)
end

function XUiRestaurantRadio:InitView()
    self.TxtDesc.text = self.TxtTip
    self.PanelText.gameObject:SetActiveEx(true)
    self.Timer = XScheduleManager.ScheduleOnce(function()
        self:Close()
    end, TIP_MSG_SHOW_TIME)
end

--- 监听界面销毁事件
---@param ui XUi
---@return void
--------------------------
function XUiRestaurantRadio:OnUiDestroy(ui)
    if not ui or not ui.UiData then
        return
    end
    local uiName = ui.UiData.UiName
    if self.OnDestroyUiMap[uiName] and self.InView then
        self.InView = false
        self:Close()
    end
end
