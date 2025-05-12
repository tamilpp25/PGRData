local XUiEquipOverrunDetailV2P6 = XClass(XUiNode, "XUiEquipOverrunDetailV2P6")

function XUiEquipOverrunDetailV2P6:OnStart()
    self.BtnPreview = self.Transform:FindTransform("BtnPreview")
    self.ChoiceEffect = self.BtnChoice.transform:Find("RImgBg/Effect")
    self:SetButtonCallBack()
end

function XUiEquipOverrunDetailV2P6:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnPreview, self.OnClickBtnPreview)
    XUiHelper.RegisterClickEvent(self, self.BtnUnChoice, self.OnClickChangeBind)
    XUiHelper.RegisterClickEvent(self, self.BtnChoice, self.OnClickChangeBind)
end

function XUiEquipOverrunDetailV2P6:OnClickBtnPreview()
    XLuaUiManager.Open("UiEquipOverrunSelect", self.EquipId, function()
        self:RefreshBlindSuit()
    end, true)
end

function XUiEquipOverrunDetailV2P6:OnClickChangeBind()
    if self.IsOther then
        return
    end

    if not self.Equip:IsOverrunCanBlindSuit() then
        return
    end

    XLuaUiManager.Open("UiEquipOverrunSelect", self.EquipId, function()
        self:RefreshBlindSuit()
        self.ChoiceEffect.gameObject:SetActive(false)
        self.ChoiceEffect.gameObject:SetActive(true)
    end)
end

-- 设置装备id
function XUiEquipOverrunDetailV2P6:SetEquipId(equipId, matchCharId)
    self.EquipId = equipId
    self.MatchCharId = matchCharId
    self.Equip = XMVCA.XEquip:GetEquip(self.EquipId)
    self.OverrunCfgs = self.Parent._Control:GetWeaponOverrunCfgsByTemplateId(self.Equip.TemplateId)
    self:Refresh()
end

-- 设置别人的装备对象
function XUiEquipOverrunDetailV2P6:SetOtherEquip(equip)
    self.IsOther = true
    self.Equip = equip
    self.OverrunCfgs = self.Parent._Control:GetWeaponOverrunCfgsByTemplateId(self.Equip.TemplateId)
    self:Refresh()
    self.BtnChoice.transform:Find("Normal/ImgChange").gameObject:SetActiveEx(false)
    self.BtnChoice.transform:Find("Press/ImgChange").gameObject:SetActiveEx(false)
    self.BtnPreview.gameObject:SetActiveEx(false)
end

-- 刷新界面
function XUiEquipOverrunDetailV2P6:Refresh()
    self:RefreshBlindSuit()
    self:RefreshDesc()
end

-- 刷新绑定意识
function XUiEquipOverrunDetailV2P6:RefreshBlindSuit()
    self.PanelLock.gameObject:SetActiveEx(false)
    self.BtnUnChoice.gameObject:SetActiveEx(false)
    self.BtnChoice.gameObject:SetActiveEx(false)
    self.ChoiceEffect.gameObject:SetActive(false)

    local canBind = self.Equip:IsOverrunCanBlindSuit()
    local lv = self.Equip:GetOverrunLevel()
    local choseSuit = self.Equip:GetOverrunChoseSuit()

    -- 未解锁
    if not canBind then
        self.PanelLock.gameObject:SetActiveEx(true)

    -- 解锁未绑定
    elseif choseSuit == 0 then
        self.BtnUnChoice.gameObject:SetActiveEx(true)
        self:RefreshLevel(self.BtnUnChoice, lv)

    -- 解锁已绑定
    else
        self.BtnChoice.gameObject:SetActiveEx(true)
        self:RefreshLevel(self.BtnChoice, lv)
        local suitName = XMVCA:GetAgency(ModuleId.XEquip):GetSuitName(choseSuit)
        local bigIconPath = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitBigIconPath(choseSuit)
        self.BtnChoice:GetObject("TxtAwarenessName").text = suitName
        self.BtnChoice:GetObject("RImgAwareness"):SetRawImage(bigIconPath)

        local isMatch = self.Equip:IsOverrunBlindMatch(self.MatchCharId)
        self.BtnChoice:GetObject("NoMatchTag").gameObject:SetActiveEx(not isMatch)
    end
end

-- 刷新等级
function XUiEquipOverrunDetailV2P6:RefreshLevel(uiObj, curLv)
    for i = 1, #self.OverrunCfgs do
        uiObj:GetObject("IconActiveLevel" .. i).gameObject:SetActiveEx(curLv >= i)
    end

    uiObj:GetObject("TxtLevel").text = self.Parent._Control:GetWeaponDeregulateUIName(curLv)
end

-- 刷新描述
function XUiEquipOverrunDetailV2P6:RefreshDesc()
    local curLv = self.Equip:GetOverrunLevel()
    for i, cfg in ipairs(self.OverrunCfgs) do
        local uiObj = self["PanelLevel" ..i]
        if not uiObj then
            XLog.Error(string.format("请检查Share/Equip/WeaponOverrun.tab, WeaponId = %s, 配置数量为%s, 预制体预留数量为%s", cfg.WeaponId, #self.OverrunCfgs, i-1))
            break
        end
        local isUnlock = curLv >= cfg.Level 
        uiObj:GetObject("PaneUnlock").gameObject:SetActiveEx(isUnlock)
        uiObj:GetObject("PaneLock").gameObject:SetActiveEx(not isUnlock)
        if isUnlock then
            uiObj:GetObject("TxtDetailUnlock").text = cfg.Desc
        else
            uiObj:GetObject("TxtDetailLock").text = cfg.Desc
        end
    end
end

return XUiEquipOverrunDetailV2P6