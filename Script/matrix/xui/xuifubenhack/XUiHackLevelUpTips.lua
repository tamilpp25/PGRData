local XUiHackLevelUpTips = XLuaUiManager.Register(XLuaUi, "UiHackLevelUpTips")

function XUiHackLevelUpTips:OnStart(lastLevel, curLevel, cb)
    self.LastLevel = lastLevel
    self.CurLevel = curLevel
    self.Cb = cb
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self:RefreshLevel()
end

function XUiHackLevelUpTips:RefreshLevel()
    self.TxtLastLevel.text = "Lv." .. self.LastLevel
    self.TxtCurrentLevel.text = "Lv." .. self.CurLevel
    self.TxtTitle.text = CS.XTextManager.GetText("FubenHackLevelUpTitle")
    self.TxtDesc.text = CS.XTextManager.GetText("FubenHackLevelUpDesc")
    self.TxtUnlockBuffPos.gameObject:SetActiveEx(false)

    for pos = 1, XFubenHackConfig.BuffBarCapacity do
        local _, level = XDataCenter.FubenHackManager.IsBuffPosUnlock(pos)
        if self.LastLevel < level and self.CurLevel == level then
            self.TxtUnlockBuffPos.gameObject:SetActiveEx(true)
            break
        end
    end
end

function XUiHackLevelUpTips:OnBtnCloseClick()
    if self.Cb then
        self.Cb()
    end
    self:Close()
end

return XUiHackLevelUpTips