--净化等级变更弹窗
local XUiAreaWarJingHuaTips = XLuaUiManager.Register(XLuaUi, "UiAreaWarJingHuaTips")

function XUiAreaWarJingHuaTips:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiAreaWarJingHuaTips:OnStart(closeCb)
    self.CloseCb = closeCb
    self:Refresh()
end

function XUiAreaWarJingHuaTips:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiAreaWarJingHuaTips:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_PURIFICATION_LEVEL_CHANGE
    }
end

function XUiAreaWarJingHuaTips:OnNotify(evt, ...)
    local args = {...}
    if evt == XEventId.EVENT_AREA_WAR_PURIFICATION_LEVEL_CHANGE then
        self:Refresh()
    end
end

function XUiAreaWarJingHuaTips:Refresh()
    local oldLevel, newLevel = XDataCenter.AreaWarManager.GetRecordPurificationLevel()
    self.TxtOldLevel.text = oldLevel
    self.TxtCurLevel.text = newLevel

    local oldAddAttrs = XAreaWarConfigs.GetPfLevelAddAttrs(oldLevel)
    self.TxtOldLife.text = oldAddAttrs[1]
    self.TxtOldAttack.text = oldAddAttrs[2]
    self.TxtOldDefense.text = oldAddAttrs[3]
    self.TxtOldCrit.text = oldAddAttrs[4]

    local newAddAttrs = XAreaWarConfigs.GetPfLevelAddAttrs(newLevel)
    self.TxtCurLife.text = newAddAttrs[1]
    self.TxtCurAttack.text = newAddAttrs[2]
    self.TxtCurDefense.text = newAddAttrs[3]
    self.TxtCurCrit.text = newAddAttrs[4]
end
