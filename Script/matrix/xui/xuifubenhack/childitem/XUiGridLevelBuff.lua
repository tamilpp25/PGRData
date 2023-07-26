local XUiGridLevelBuff = XClass(nil, "XUiGridLevelBuff")
local Type = {
    Unlocked = 1,
    CanUnlock = 2,
    Locked = 3,
}
function XUiGridLevelBuff:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.BtnDetail.CallBack = function() self:OnBtnDetailClick() end
    self.BtnDetail2.CallBack = function() self:OnBtnDetailClick() end
    --self.TxtTitleEn.text = ""
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_HACK_CLICK, self.OnGridClick, self)
    self.IsPlayedAnim = false
    self.IsPlayingAnim = false
end

function XUiGridLevelBuff:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_HACK_CLICK, self.OnGridClick, self)
end

function XUiGridLevelBuff:Refresh(level)
    self.Index = level
    self.Cfg = XDataCenter.FubenHackManager.GetLevelCfg(level)
    if not self.Cfg then return end
    self.BuffCfg = XFubenHackConfig.GetBuffById(self.Cfg.BuffId)
    self.CurLevel = XDataCenter.FubenHackManager.GetLevel()

    if XDataCenter.FubenHackManager.IsAffixUnlock(level) then
        self.State = Type.Unlocked
    elseif self.CurLevel >= level then
        self.State = Type.CanUnlock
    else
        self.State = Type.Locked
    end

    if self.CurLevel > level then
        self.ImgProgress.fillAmount = 1
    elseif self.CurLevel == level then
        local curExp = XDataCenter.FubenHackManager.GetCurExp()
        local upExp = XDataCenter.FubenHackManager.GetNextUpExp()
        self.ImgProgress.fillAmount = curExp / upExp
    else
        self.ImgProgress.fillAmount = 0
    end

    if level >= XDataCenter.FubenHackManager.GetMaxLevel() then
        self.PanelProgress.gameObject:SetActiveEx(false)
    end

    self.ImgLvUnlock.gameObject:SetActiveEx(self.State == Type.Unlocked)
    self.ImgLvLock.gameObject:SetActiveEx(self.State ~= Type.Unlocked)
    self.TxtLvUnlock.text = string.format("Lv.%d", level)
    self.TxtLvLock.text = string.format("Lv.%d", level)
    self.RImgBuff:SetRawImage(self.BuffCfg.Icon)
    self.RImgBuffLock:SetRawImage(self.BuffCfg.Icon)
    self.ImgUnlock.gameObject:SetActiveEx(self.State == Type.Unlocked)
    self.ImgBuffUnlock.gameObject:SetActiveEx(self.State == Type.Unlocked)
    self.ImgBuffLock.gameObject:SetActiveEx(self.State ~= Type.Unlocked)
    self.TagEquip.gameObject:SetActiveEx(self.State == Type.Unlocked and XDataCenter.FubenHackManager.CheckAffixEquip(self.BuffCfg.Id))
    self.TxtEquiped.text = CSXTextManagerGetText("FubenHackEquipBuffUsed")
    self.ImgLock.gameObject:SetActiveEx(self.State == Type.Locked)
    self.PaneCanUnlock.gameObject:SetActiveEx(self.State == Type.CanUnlock)
    self.BtnDetail:SetNameByGroup(0, self.BuffCfg.Name)
    self.BtnDetail:SetButtonState(self.State == Type.Unlocked and XUiButtonState.Normal or XUiButtonState.Disable)
    self.BtnDetail2:SetNameByGroup(0, self.BuffCfg.Name)
    self.BtnDetail2:SetButtonState(self.State == Type.Unlocked and XUiButtonState.Normal or XUiButtonState.Disable)
end

function XUiGridLevelBuff:OnBtnDetailClick()
    if not self.IsPlayedAnim then
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_HACK_CLICK)
        return
    end

    if self.State == Type.CanUnlock then
        local result, desc = XDataCenter.FubenHackManager.UnlockAffix(self.Index)
        if result then
            self:Refresh(self.Index)
        end
        XUiManager.TipMsg(desc)
        return
    end

    self.RootUi:OpenPanelBuffDetail(self.Cfg.BuffId, XFubenHackConfig.PopUpPos.Right)
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_HACK_CLICK, self.Cfg.BuffId)
end

function XUiGridLevelBuff:OnGridClick(id, isPlayHighlightAnim)
    if id == 0 and self.State == Type.Unlocked and
            not XDataCenter.FubenHackManager.CheckAffixEquip(self.BuffCfg.Id) then
        self.PanelAnim.gameObject:SetActiveEx(true)
        self.SelectionTips:PlayTimelineAnimation()
    end

    if self.IsPlayedAnim then
        self.ImgSelect.gameObject:SetActiveEx(self.Cfg.BuffId == id)
        self.ImgSelect2.gameObject:SetActiveEx(self.Cfg.BuffId == id)
        if isPlayHighlightAnim and self.Cfg.BuffId == id then
            self.PanelAnim.gameObject:SetActiveEx(true)
            self.SelectionTips:PlayTimelineAnimation()
        end
    elseif self.IsPlayingAnim then
        return
    else
        self.GridBuffEnable:PlayTimelineAnimation(function()
            self.IsPlayedAnim = true
            self.IsPlayingAnim = false
        end)
        self.IsPlayingAnim = true
    end
end

return XUiGridLevelBuff