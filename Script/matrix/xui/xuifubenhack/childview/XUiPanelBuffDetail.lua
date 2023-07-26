local XUiPanelBuffDetail = XClass(nil, "XUiPanelBuffDetail")

local Type = {
    Unlocked = 1,
    Equipped = 2,
    Locked = 3,
    Character = 4, -- 人物专属词缀
}

function XUiPanelBuffDetail:Ctor(uiRoot, ui)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:Hide()
end

function XUiPanelBuffDetail:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelBuffDetail:Show(buffId)
    self.BuffId = buffId
    self:InitUi()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelBuffDetail:InitUi()
    local buffId = self.BuffId
    local info = XFubenHackConfig.GetBuffById(buffId)
    local buffLevel = XDataCenter.FubenHackManager.GetLevelByBuffId(buffId)
    local curLevel = XDataCenter.FubenHackManager.GetLevel()

    if not buffLevel then
        self.State = Type.Character
    elseif buffLevel > curLevel then
        self.State = Type.Locked
    else
        self.State = Type.Unlocked
    end
    self.BuffBarList = XDataCenter.FubenHackManager.GetBuffBarList()
    for i, v in ipairs(self.BuffBarList) do
        if v == buffId then
            self.State = Type.Equipped
            self.EquipIndex = i
        end
    end

    self.TxtLocked.gameObject:SetActiveEx(self.State == Type.Locked)
    self.TxtLocked.text = CSXTextManagerGetText("FubenHackEquipBuffLock", buffLevel)
    self.TxtUnlocked.gameObject:SetActiveEx(self.State == Type.Unlocked)
    self.TxtUnlocked.text = CSXTextManagerGetText("FubenHackEquipBuffAvailable")
    self.TxtEquipped.gameObject:SetActiveEx(self.State == Type.Equipped)
    self.TxtEquipped.text = CSXTextManagerGetText("FubenHackEquipBuffUsed")
    self.TxtName.text = info.Name
    self.BtnEquip.gameObject:SetActiveEx(self.State == Type.Unlocked)
    self.BtnEquip:SetNameByGroup(0, XUiHelper.ReadTextWithNewLine("FubenHackEquipBuffApply"))
    self.BtnTakeOff.gameObject:SetActiveEx(self.State == Type.Equipped)
    self.TxtSimpleDesc.gameObject:SetActiveEx(self.State == Type.Character)
    self.TxtSimpleDesc.text = info.SimpleDesc
    self.RImgBuffIcon:SetRawImage(info.Icon)
    self.TxtTitle.text = CS.XTextManager.GetText("FubenHackBuffDetailTitle")
    self.TxtDesc.text = XUiHelper.ConvertLineBreakSymbol(info.Description)
end

function XUiPanelBuffDetail:AutoAddListener()
    self.UiRoot:RegisterClickEvent(self.BtnClose, function() self:OnBtnCloseClick() end)
    self.BtnEquip.CallBack = function() self:OnBtnEquipClick() end
    self.BtnTakeOff.CallBack = function() self:OnBtnTakeOffClick() end
end

function XUiPanelBuffDetail:OnBtnCloseClick()
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_HACK_CLICK)
    self:Hide()
end

function XUiPanelBuffDetail:OnBtnEquipClick()
    XDataCenter.FubenHackManager.SetBuff(0, self.BuffId, function(res, desc)
        if res then
            XUiManager.TipText("FubenHackEquipBuffSucc")
            self:Hide()
        else
            XUiManager.TipMsg(desc)
        end
    end)
end

function XUiPanelBuffDetail:OnBtnTakeOffClick()
    XDataCenter.FubenHackManager.SetBuff(self.EquipIndex, 0, function(res, desc)
        if res then
            XUiManager.TipText("FubenHackTakeOffBuffSucc")
        end
    end)

    self:Hide()
end

return XUiPanelBuffDetail