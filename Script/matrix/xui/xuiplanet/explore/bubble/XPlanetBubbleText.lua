local XPlanetBubble = require("XUi/XUiPlanet/Explore/Bubble/XPlanetBubble")

---@class XPlanetBubbleText:XPlanetBubble
local XPlanetBubbleText = XClass(XPlanetBubble, "XPlanetBubbleText")

function XPlanetBubbleText:Ctor()
    self._UiHolder = self.PanelBubble
    self.PanelNum.gameObject:SetActiveEx(true)
    self.PanelBubble.gameObject:SetActiveEx(false)
    
    self._Text = false
end

function XPlanetBubbleText:Play(text)
    self._Text = text
    self:RefreshUiShow()

    local syncFun = function ()
        self:SyncPos()
    end
    syncFun()
    self:Show()
    if self.TimerForever then
        return
    end
    self.TimerForever = XScheduleManager.ScheduleForever(syncFun, 0, 0)
end

function XPlanetBubbleText:RefreshUiShow()
    if self._Text then
        self.TxtSite.text = self._Text
    end
end

return XPlanetBubbleText
