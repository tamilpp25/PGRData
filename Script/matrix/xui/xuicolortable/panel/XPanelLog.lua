-- Boss关卡详情

local XPanelLog = XClass(nil, "XPanelLog")

function XPanelLog:Ctor(root, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root

    self:InitUiObject()
    self:CloseLog()
end

function XPanelLog:InitUiObject()
    XTool.InitUiObject(self)
end

function XPanelLog:Refresh(effectIds)
    if XTool.IsTableEmpty(effectIds) then
        return
    end
    for _, effectId in ipairs(effectIds) do
        self.TxtLogTitle.text = XColorTableConfigs.GetEffectName(effectId)
        self.TxtLog.text = XColorTableConfigs.GetEffectShowDesc(effectId)
    end
    self:PlayLog()
end

function XPanelLog:PlayLog()
    self.GameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function ()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:CloseLog()
    end, 2000)
end

function XPanelLog:CloseLog()
    self.GameObject:SetActiveEx(false)
end

function XPanelLog:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_EFFECTTAKEEFFECT, self.Refresh, self)
end

function XPanelLog:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_EFFECTTAKEEFFECT, self.Refresh, self)
end

-- private
------------------------------------------------------------------



------------------------------------------------------------------

return XPanelLog