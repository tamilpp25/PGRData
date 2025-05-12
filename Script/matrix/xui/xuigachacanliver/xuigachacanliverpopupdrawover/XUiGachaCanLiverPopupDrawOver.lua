---@class XUiGachaCanLiverPopupDrawOver: XLuaUi
---@field _Control XGachaCanLiverControl
local XUiGachaCanLiverPopupDrawOver = XLuaUiManager.Register(XLuaUi, 'UiGachaCanLiverPopupDrawOver')

function XUiGachaCanLiverPopupDrawOver:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.DoClose)
end

function XUiGachaCanLiverPopupDrawOver:OnStart(doneGachaId)
    self.DoneGachaId = doneGachaId
    self.NextGachaId = self._Control:GetCurActivityLatestTimelimitGachaId()
    
    self:Refresh()
    self:PlayAnimation('Enable', handler(self, self.DoClose))
end

function XUiGachaCanLiverPopupDrawOver:DoClose()
    if not self._IsClose then
        self._IsClose = true
        self:Close()
    end
end

function XUiGachaCanLiverPopupDrawOver:Refresh()
    self.PanelUnlock.gameObject:SetActiveEx(self.NextGachaId ~= self.DoneGachaId)
    self.TxtLockNum.text = self._Control:GetCurActivityTimelimitGachaLockCount()
    -- 显示研发完毕的卡池
    local index = self._Control:GetCurActivityLatestTimelimitGachaIndexById(self.DoneGachaId)
    self.TxtDoneGachaName.text = XUiHelper.FormatText(XGachaConfigs.GetClientConfig('LilithTimelimitDrawOverTipsTitle', 1), string.format('%02d', index))
    -- 显示新解锁的卡池
    if self.NextGachaId ~= self.DoneGachaId then
        local nextIndex = self._Control:GetCurActivityLatestTimelimitGachaIndex()
        self.TxtNewGachaName.text = XUiHelper.FormatText(XGachaConfigs.GetClientConfig('LilithTimelimitDrawOverTipsTitle', 1), string.format('%02d', nextIndex))
    end
end

return XUiGachaCanLiverPopupDrawOver