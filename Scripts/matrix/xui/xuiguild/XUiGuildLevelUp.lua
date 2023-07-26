local XUiGuildLevelUp = XLuaUiManager.Register(XLuaUi, "UiGuildLevelUp")

function XUiGuildLevelUp:OnStart(lastLevel, curLevel, cb)
    self.LastLevel = lastLevel
    self.CurLevel = curLevel
    self.Cb = cb
    self.PresentList = {}
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnViewSkill.CallBack = function() self:OnBtnViewSkillClick() end
    self:RefreshLevel()
end

function XUiGuildLevelUp:RefreshLevel()
    -- local curLevel = XDataCenter.GuildManager.GetGuildLevel()
    -- local lastLevel = XDataCenter.GuildManager.GetLastLevel() or curLevel-1
    -- if lastLevel == -1 or lastLevel >= curLevel then 
    --     lastLevel = curLevel-1
    -- end
    self.TxtLastLevel.text = self.LastLevel
    self.TxtCurrentLevel.text = self.CurLevel
    self.TxtLevelUp.text = CS.XTextManager.GetText("GuildLevelUpHint", self.CurLevel)
    self.BtnViewSkill.gameObject:SetActiveEx(XDataCenter.GuildManager.IsGuildAdminister())
    self.ImgHead:SetRawImage(XDataCenter.GuildManager.GetGuildIconId())
end

function XUiGuildLevelUp:OnBtnCloseClick()
    self:Close()
end

function XUiGuildLevelUp:OnBtnViewSkillClick()
    self:Close()
    XDataCenter.GuildManager.EnterGuildTalent()
end

function XUiGuildLevelUp:OnDestroy()
    if self.Cb then
        self.Cb()
    end
    XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
end

return XUiGuildLevelUp