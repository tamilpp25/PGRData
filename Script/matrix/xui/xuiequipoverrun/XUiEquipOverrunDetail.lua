local XUiEquipOverrunDetail = XClass(nil, "XUiEquipOverrunDetail")

function XUiEquipOverrunDetail:Ctor(parent, ui)
    self.Parent = parent
    self.Ui = ui
    self.Transform = ui.transform
    
    XTool.InitUiObject(self)
    self.BtnPreview = self.Transform:FindTransform("BtnPreview")
    self:SetButtonCallBack()
end

function XUiEquipOverrunDetail:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnPreview, self.OnClickBtnPreview)
    XUiHelper.RegisterClickEvent(self, self.BtnUnChoice, self.OnClickChangeBind)
    XUiHelper.RegisterClickEvent(self, self.BtnChoice, self.OnClickChangeBind)
end

function XUiEquipOverrunDetail:OnClickBtnPreview()
    XLuaUiManager.Open("UiEquipOverrunSelect", self.EquipId, function()
        self:RefreshBlindSuit()
    end, true)
end

function XUiEquipOverrunDetail:OnClickChangeBind()
    if self.IsOther then
        return
    end

    if not self.Equip:IsOverrunCanBlindSuit() then
        return
    end

    XLuaUiManager.Open("UiEquipOverrunSelect", self.EquipId, function()
        self:RefreshBlindSuit()
    end)
end

-- 设置装备id
function XUiEquipOverrunDetail:SetEquipId(equipId, matchCharId)
    self.EquipId = equipId
    self.MatchCharId = matchCharId
    self.Equip = XDataCenter.EquipManager.GetEquip(self.EquipId)
    self.OverrunCfgs = XEquipConfig.GetWeaponOverrunCfgsByTemplateId(self.Equip.TemplateId)
    self:Refresh()
end

-- 设置别人的装备对象
function XUiEquipOverrunDetail:SetOtherEquip(equip)
    self.IsOther = true
    self.Equip = equip
    self.OverrunCfgs = XEquipConfig.GetWeaponOverrunCfgsByTemplateId(self.Equip.TemplateId)
    self:Refresh()
    self.BtnUnChoice.transform:Find("Normal/ImgChoice").gameObject:SetActiveEx(false)
    self.BtnUnChoice.transform:Find("Press/ImgChoice").gameObject:SetActiveEx(false)
    self.BtnChoice.transform:Find("Normal/ImgChange").gameObject:SetActiveEx(false)
    self.BtnChoice.transform:Find("Press/ImgChange").gameObject:SetActiveEx(false)
    self.BtnPreview.gameObject:SetActiveEx(false)
end

-- 刷新界面
function XUiEquipOverrunDetail:Refresh()
    self:RefreshBlindSuit()
    self:RefreshDesc()
end

-- 刷新绑定意识
function XUiEquipOverrunDetail:RefreshBlindSuit()
    self.PanelLock.gameObject:SetActiveEx(false)
    self.BtnUnChoice.gameObject:SetActiveEx(false)
    self.BtnChoice.gameObject:SetActiveEx(false)

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
        local suitCfg = XEquipConfig.GetEquipSuitCfg(choseSuit)
        self.BtnChoice:GetObject("TxtAwarenessName").text = suitCfg.Name
        self.BtnChoice:GetObject("RImgAwareness"):SetRawImage(suitCfg.BigIconPath)

        local isMatch = self.Equip:IsOverrunBlindMatch(self.MatchCharId)
        self.BtnChoice:GetObject("NoMatchTag").gameObject:SetActiveEx(not isMatch)
    end
end

-- 刷新等级
function XUiEquipOverrunDetail:RefreshLevel(uiObj, curLv)
    for i = 1, #self.OverrunCfgs do
        uiObj:GetObject("IconActiveLevel" .. i).gameObject:SetActiveEx(curLv >= i)
    end

    local deregulateUICfg = XEquipConfig.GetWeaponDeregulateUICfg(curLv)
    uiObj:GetObject("TxtLevel").text = deregulateUICfg.Name
end

-- 刷新描述
function XUiEquipOverrunDetail:RefreshDesc()
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

return XUiEquipOverrunDetail