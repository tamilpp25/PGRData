local CSXUiPlayTimelineAnimation = CS.XUiPlayTimelineAnimation

local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")

local XUiEquipDetailChildV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipDetailChildV2P6")
function XUiEquipDetailChildV2P6:OnAwake()
    -- UI初始化
    self.PanelTab.gameObject:SetActiveEx(false)
    self.PanelPainter.gameObject:SetActiveEx(false)
    self.PaneOverrun.gameObject:SetActiveEx(false)
    self.PaneEquipResonance.gameObject:SetActiveEx(false)
    self.PanelAwarenessResonance.gameObject:SetActiveEx(false)
    self.PanelExtend.gameObject:SetActiveEx(false)
    self.PanelAddEffect = self.PanelAdd.transform:Find("Effect")
    self.PanelAdd2Effect = self.PanelAdd2.transform:Find("Effect")
    self.GridEquipResonanceEffect1 = self.GridEquipResonance1.transform:Find("Effect")
    self.GridEquipResonanceEffect2 = self.GridEquipResonance2.transform:Find("Effect")
    self.GridEquipResonanceEffect3 = self.GridEquipResonance3.transform:Find("Effect")
    self.GridEquipResonanceEffect1.gameObject:SetActiveEx(false)
    self.GridEquipResonanceEffect2.gameObject:SetActiveEx(false)
    self.GridEquipResonanceEffect3.gameObject:SetActiveEx(false)
    self.OverrunBlindEffect = self.BtnOverrunBlind.transform:Find("Normal/Effect")

    -- 场景初始化
    local sceneRoot = self.UiSceneInfo.Transform
    local root = self.UiModelGo.transform
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.PanelWeaponPlane = sceneRoot:FindTransform("Plane")
    self.ImgEffectOverrun = root:FindTransform("ImgEffectOverrun")

    self:SetButtonCallBack()
    self:InitPanelAsset()
end

--参数isPreview为true时是装备详情预览，传templateId进来
--characterId只有需要判断武器共鸣特效时才传
function XUiEquipDetailChildV2P6:OnStart(equipId, isPreview, characterId, forceShowBindCharacter, childUiIndex, openUiType, isShowExtendPanel)
    self.IsPreview = isPreview
    self.EquipId = equipId
    self.CharacterId = characterId
    self.ForceShowBindCharacter = forceShowBindCharacter
    self.TemplateId = isPreview and self.EquipId or XDataCenter.EquipManager.GetEquipTemplateId(equipId)
    self.OpenUiType = openUiType
    self.IsShowExtend = isShowExtendPanel == true
    self.IsWeapon = XDataCenter.EquipManager.IsWeaponByTemplateId(self.TemplateId)
    self.IsAwareness = XDataCenter.EquipManager.IsAwarenessByTemplateId(self.TemplateId)
    if self.IsAwareness then
        self.SelectAwarenessIndex = XDataCenter.EquipManager.GetEquipSite(equipId)
    end
    self:RegisterHelpBtn()

    if not XDataCenter.VoteManager.IsInit() then
        XDataCenter.VoteManager.GetVoteGroupListRequest()
    end
end

function XUiEquipDetailChildV2P6:OnEnable()
    -- 播放扩展面板动画，动画切到最后一帧
    local anim = self.IsShowExtend and self.AnimFold or self.AnimUnFold
    anim:Play()
    anim.time = anim.duration
    anim:Evaluate()
    anim:Stop()

    self.PanelAddEffect.gameObject:SetActiveEx(false)
    self.PanelAdd2Effect.gameObject:SetActiveEx(false)
    self:UpdateView()
end

function XUiEquipDetailChildV2P6:OnDestroy()
    self.PanelWeaponPlane.gameObject:SetActiveEx(true)
    self:ReleaseModel()
    self:ReleaseLihuiTimer()
end

function XUiEquipDetailChildV2P6:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY, 
        XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY,
        XEventId.EVENT_EQUIP_RESONANCE_NOTYFY,
        XEventId.EVENT_EQUIP_SELECT_EQUIP,
    }
end

function XUiEquipDetailChildV2P6:OnNotify(evt, ...)
    local args = { ... }
    local equipId = args[1]
    
    -- 切换当前选择的装备
    if evt == XEventId.EVENT_EQUIP_SELECT_EQUIP then
        if equipId ~= self.EquipId then
            local equips = self._Control:GetCharacterWearingAwarenesss(self.CharacterId)
            for _, equip in ipairs(equips) do
                if equip.Id == equipId then
                    local site = equip:GetEquipSite()
                    self:OnClickSwitchAwareness(site)
                end
            end
        end
        return
    end

    if self.IsPreview or equipId ~= self.EquipId then 
        return 
    end

    if evt == XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY then
        self:UpdateEquipLock()
        self:UpdateEquipRecycle()
    elseif evt == XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY then
        self:UpdateEquipRecycle()
    elseif evt == XEventId.EVENT_EQUIP_RESONANCE_NOTYFY then
        XMVCA:GetAgency(ModuleId.XEquip):TipEquipOperation(nil, XUiHelper.GetText("DormTemplateSelectSuccess"))
        self:UpdateEquipResonance()
        
        local slots = args[2]
        for _, pos in ipairs(slots) do
            self["GridEquipResonanceEffect"..pos].gameObject:SetActiveEx(true)
        end
    end
end

function XUiEquipDetailChildV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
    self:RegisterClickEvent(self.BtnLock, self.OnBtnLockClick)
    self:RegisterClickEvent(self.BtnUnlock, self.OnBtnUnlockClick)
    self:RegisterClickEvent(self.BtnLaJi, self.OnBtnLaJiClick)
    self:RegisterClickEvent(self.BtnUnLaJi, self.OnBtnUnLaJiClick)
    self:RegisterClickEvent(self.PanelAdd, self.ShowPanelSkill)
    self:RegisterClickEvent(self.PanelAdd2, self.ShowPanelExtend)

    -- 强化
    self:RegisterClickEvent(self.BtnStrengthen, self.OnBtnStrengthen)

    -- 武器共鸣
    self:RegisterClickEvent(self.GridEquipResonance1, function() self:OnBtnResonanceSkill(1) end)
    self:RegisterClickEvent(self.GridEquipResonance2, function() self:OnBtnResonanceSkill(2) end)
    self:RegisterClickEvent(self.GridEquipResonance3, function() self:OnBtnResonanceSkill(3) end)
    self:RegisterClickEvent(self.BtnResonance, function() self:OnBtnResonanceSkill() end)

    -- 武器超限
    self:RegisterClickEvent(self.BtnOverrun, self.OnBtnOverrun)
    self:RegisterClickEvent(self.BtnOverrunBlind, self.OnBtnOverrunClick)
    self:RegisterClickEvent(self.BtnOverrunEmpty, self.OnBtnOverrunClick)

    -- 意识切换
    self:RegisterAwarenessSwitch()

    -- 意识共鸣
    self:RegisterClickEvent(self.GridAwarenessResonance1:GetObject("PanelEmptySkill"):GetObject("BtnClick"), function() self:OnBtnResonanceSkill(1) end)
    self:RegisterClickEvent(self.GridAwarenessResonance2:GetObject("PanelEmptySkill"):GetObject("BtnClick"), function() self:OnBtnResonanceSkill(2) end)
    self:RegisterClickEvent(self.BtnResonanceEquip1, function() self:OnBtnOverClocking(1) end)
    self:RegisterClickEvent(self.BtnResonanceEquip2, function() self:OnBtnOverClocking(2) end)
end


function XUiEquipDetailChildV2P6:RegisterHelpBtn()
    local keyStr = self.IsWeapon and "EquipWeapon" or "EquipAwareness"
    self:BindHelpBtn(self.BtnHelp, keyStr)
end

function XUiEquipDetailChildV2P6:OnBtnBackClick()
    self:Close()
end

function XUiEquipDetailChildV2P6:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiEquipDetailChildV2P6:OnBtnLockClick()
    XDataCenter.EquipManager.SetLock(self.EquipId, false)
end

function XUiEquipDetailChildV2P6:OnBtnUnlockClick()
    XDataCenter.EquipManager.SetLock(self.EquipId, true)
end

function XUiEquipDetailChildV2P6:OnBtnLaJiClick()
    XDataCenter.EquipManager.EquipUpdateRecycleRequest(self.EquipId, false)
end

function XUiEquipDetailChildV2P6:OnBtnUnLaJiClick()
    XDataCenter.EquipManager.EquipUpdateRecycleRequest(self.EquipId, true)
end

function XUiEquipDetailChildV2P6:OnBtnStrengthen()
    if self.IsPreview then 
        return
    end
    XLuaUiManager.Open("UiEquipDetailV2P6", self.EquipId, nil, self.CharacterId, self.ForceShowBindCharacter, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.STRENGTHEN)
end

function XUiEquipDetailChildV2P6:OnBtnResonanceSkill(pos)
    if self.IsPreview then 
        return
    end

    local equip = XMVCA:GetAgency(ModuleId.XEquip):GetEquip(self.EquipId)
    local star = XMVCA:GetAgency(ModuleId.XEquip):GetEquipQuality(equip.TemplateId)
    local characterId = self.CharacterId or equip.CharacterId

    -- 共鸣技能替换界面，武器且选中位置与当前角色是共鸣
    if equip:IsWeapon() and pos and equip:GetResonanceBindCharacterId(pos) == characterId and characterId and characterId ~= 0 then
        XLuaUiManager.Open("UiEquipResonanceSkillChangeV2P6", characterId, self.EquipId)

    -- 5星武器只能共鸣一次
    elseif equip:IsWeapon() and equip:GetResonanceInfo(pos) and star == XEnumConst.EQUIP.FIVE_STAR then
        XLuaUiManager.Open("UiEquipDetailV2P6", self.EquipId, nil, self.CharacterId, self.ForceShowBindCharacter, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE)
    else
        XLuaUiManager.Open("UiEquipDetailV2P6", self.EquipId, nil, self.CharacterId, self.ForceShowBindCharacter, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE, nil, pos)
    end
end

function XUiEquipDetailChildV2P6:OnBtnOverrun()
    if self.IsPreview then 
        return
    end

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun) then 
        local tips = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.EquipOverrun)
        XUiManager.TipError(tips)
        return
    end
        
    XLuaUiManager.Open("UiEquipDetailV2P6", self.EquipId, nil, self.CharacterId, self.ForceShowBindCharacter, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERRUN)
end

function XUiEquipDetailChildV2P6:OnBtnOverClocking(pos)
    if self.IsPreview then
        return
    end

    local canAwake = false
    for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        if XDataCenter.EquipManager.CheckEquipCanAwake(self.EquipId, pos) then
            canAwake = true
            break
        end
    end
    if not canAwake then
        XUiManager.TipText("SuperAwareness")
        return
    end

    -- 默认跳转到对应位置超频界面
    local canAwake = XDataCenter.EquipManager.CheckEquipCanAwake(self.EquipId, pos)
    local isAwake = XDataCenter.EquipManager.IsEquipPosAwaken(self.EquipId, pos)
    if isAwake or not canAwake then
        pos = nil
    end
    XLuaUiManager.Open("UiEquipDetailV2P6", self.EquipId, nil, self.CharacterId, self.ForceShowBindCharacter, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING, nil, pos)
end

-- 显示技能面板
function XUiEquipDetailChildV2P6:ShowPanelSkill()
    self.IsShowExtend = false
    self:PlayAnimation("AnimUnFold")
    self.PanelAddEffect.gameObject:SetActiveEx(false)
    self.PanelAdd2Effect.gameObject:SetActiveEx(true)
    self.GridEquipResonanceEffect1.gameObject:SetActiveEx(false)
    self.GridEquipResonanceEffect2.gameObject:SetActiveEx(false)
    self.GridEquipResonanceEffect3.gameObject:SetActiveEx(false)
    self.OverrunBlindEffect.gameObject:SetActiveEx(false)
end

-- 显示扩展面板
function XUiEquipDetailChildV2P6:ShowPanelExtend()
    self.IsShowExtend = true
    self:PlayAnimation("AnimFold")
    self.PanelAddEffect.gameObject:SetActiveEx(true)
    self.PanelAdd2Effect.gameObject:SetActiveEx(false)
end

function XUiEquipDetailChildV2P6:OnBtnOverrunClick()
    if self.OverrunIconTips then
        XUiManager.TipError(self.OverrunIconTips)
        return
    end

    XLuaUiManager.Open("UiEquipOverrunSelect", self.EquipId, function()
        self:UpdateOverrun()
        self.OverrunBlindEffect.gameObject:SetActiveEx(true)
    end)
end

function XUiEquipDetailChildV2P6:InitPanelAsset()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin
    )
end

-- 初始化武器模型/意识立绘
function XUiEquipDetailChildV2P6:InitModel()
    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.PanelWeaponPlane.gameObject:SetActiveEx(false)
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    if self.IsWeapon then
        self.PanelWeapon.gameObject:SetActiveEx(true)
        local breakthroughTimes = not self.IsPreview and XDataCenter.EquipManager.GetBreakthroughTimes(self.EquipId) or 0
        local resonanceCount = not self.IsPreview and XDataCenter.EquipManager.GetResonanceCount(self.EquipId) or 0
        local modelTransformName = "UiEquipDetail"
        local modelConfig = XDataCenter.EquipManager.GetWeaponModelCfg(self.TemplateId, modelTransformName, breakthroughTimes, resonanceCount)
        if modelConfig then
            XModelManager.LoadWeaponModel(
                modelConfig.ModelId,
                self.PanelWeapon,
                modelConfig.TransformConfig,
                modelTransformName,
                nil,
                {gameObject = self.GameObject, usage = XEnumConst.EQUIP.WEAPON_USAGE.SHOW, IsDragRotation = true, AntiClockwise = true},
                self.PanelDrag
            )
        end
    elseif self.IsAwareness then
        self:ReleaseModel()
        local breakthroughTimes = not self.IsPreview and XDataCenter.EquipManager.GetBreakthroughTimes(self.EquipId) or 0
        self.Resource = CS.XResourceManager.Load(XDataCenter.EquipManager.GetEquipLiHuiPath(self.TemplateId, breakthroughTimes))
        local texture = self.Resource.Asset
        self.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)

        self:ReleaseLihuiTimer()
        self.LihuiTimer = XScheduleManager.ScheduleOnce(function()
            self.FxUiLihuiChuxian01.gameObject:SetActiveEx(true)
            self.LihuiTimer = nil
        end,500)
    end
end

-- 释放模型
function XUiEquipDetailChildV2P6:ReleaseModel()
    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
        self.Resource = nil
    end
end

-- 释放定时器
function XUiEquipDetailChildV2P6:ReleaseLihuiTimer()
    if self.LihuiTimer then
        XScheduleManager.UnSchedule(self.LihuiTimer)
        self.LihuiTimer = nil
    end
end

-- 刷新界面
function XUiEquipDetailChildV2P6:UpdateView()
    self:InitModel()
    self:UpdateEquipLock()
    self:UpdateEquipRecycle()
    self:UpdateCharacterInfo()
    self:UpdateEquipInfo()
    self:UpdateEquipLevel()
    self:UpdateEquipBreakThrough()
    self:UpdateEquipAttr()
    if self.IsWeapon then
        self:UpdateEquipSkillDesc()
        self:UpdateEquipResonance()
        self:UpdateOverrun()
        self:UpdateOverrunSceneEffect()
    end

    if self.IsAwareness then
        self:UpdateAwarenessSwitchBtn()
        self:UpdatePainter()
        self:UpdateSuitSkillDesc()
        self:UpdateAwarenessResonance()
    end

    -- 刷新技能和能力扩展栏状态
    local isShow = self.PaneEquipResonance.gameObject.activeSelf or self.PaneOverrun.gameObject.activeSelf or self.PanelAwarenessResonance.gameObject.activeSelf
    self.PanelExtendTitle.gameObject:SetActiveEx(isShow)
    if isShow then
        self:UpdateExtendName()
    end
    if not isShow and self.IsShowExtend then
        self:ShowPanelSkill()
    end
end

-- 刷新锁按钮
function XUiEquipDetailChildV2P6:UpdateEquipLock()
    if self.IsPreview then
        self.BtnUnlock.gameObject:SetActive(false)
        self.BtnLock.gameObject:SetActive(false)
        return
    end

    local isLock = XDataCenter.EquipManager.IsLock(self.EquipId)
    self.BtnUnlock.gameObject:SetActive(not isLock)
    self.BtnLock.gameObject:SetActive(isLock)
end

-- 刷新回收按钮
function XUiEquipDetailChildV2P6:UpdateEquipRecycle()
    if self.IsPreview then
        self.BtnLaJi.gameObject:SetActive(false)
        self.BtnUnLaJi.gameObject:SetActive(false)
        return
    end

    local isCanRecycle = XDataCenter.EquipManager.IsEquipCanRecycle(self.EquipId)
    local isRecycle = XDataCenter.EquipManager.IsRecycle(self.EquipId)
    self.BtnLaJi.gameObject:SetActiveEx(isCanRecycle and isRecycle)
    self.BtnUnLaJi.gameObject:SetActiveEx(isCanRecycle and not isRecycle)
end

-- 刷新穿戴武器信息
function XUiEquipDetailChildV2P6:UpdateCharacterInfo()
    if self.IsPreview then 
        self.PanelCharacterInfo.gameObject:SetActiveEx(false)
        return
    end

    local equip = XDataCenter.EquipManager.GetEquip(self.EquipId)
    local isWearing = equip:IsWearing()
    self.PanelCharacterInfo.gameObject:SetActiveEx(isWearing)
    if isWearing then
        local icon = XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(equip.CharacterId)
        self.RImgCharHead:SetRawImage(icon)
    end
end

-- 刷新武器信息
function XUiEquipDetailChildV2P6:UpdateEquipInfo()
    local star = XDataCenter.EquipManager.GetEquipStar(self.TemplateId)
    for i = 1, XEnumConst.EQUIP.MAX_STAR_COUNT do
        self["ImgStar" .. i].gameObject:SetActiveEx(i <= star)
    end
    self.TxtEquipName.text = XDataCenter.EquipManager.GetEquipName(self.TemplateId)

    self.TxtWeaponType.gameObject:SetActiveEx(self.IsWeapon)
    if self.IsWeapon then 
        local equipType = XMVCA:GetAgency(ModuleId.XEquip):GetEquipType(self.TemplateId)
        local weaponGroupCfg = XMVCA.XArchive:GetWeaponGroupByType(equipType)
        self.TxtWeaponType.text = weaponGroupCfg and weaponGroupCfg.GroupName or ""
    end
end

-- 刷新武器等级
function XUiEquipDetailChildV2P6:UpdateEquipLevel()
    local level, levelLimit
    local equipId = self.EquipId

    if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
        local character = XDataCenter.NieRManager.GetSelNieRCharacter()
        level = character:GetNieRWeaponLevel()
        local equipSite = XDataCenter.EquipManager.GetEquipSiteByTemplateId(self.TemplateId)
        local breakTimes = character:GetNieRWeaponBreakThrough()
        if equipSite and equipSite ~= XEnumConst.EQUIP.EQUIP_SITE.WEAPON then
            level = character:GetNieRWaferLevel(equipId)
            breakTimes = character:GetNieRWaferBreakThroughById(equipId)
        end
        levelLimit = XDataCenter.EquipManager.GetBreakthroughLevelLimitByTemplateId(self.TemplateId, breakTimes)
        local isMaxLevel = XDataCenter.EquipManager.IsMaxLevelByTemplateId(self.TemplateId, breakTimes, level) and not XDataCenter.EquipManager.CanBreakThroughByTemplateId(equipId, breakTimes, level)
        self.PanelMaxLevel.gameObject:SetActiveEx(isMaxLevel)
        self.PanelMaxStrengthen.gameObject:SetActiveEx(isMaxLevel)
        self.BtnStrengthen.gameObject:SetActive(not isMaxLevel)
    elseif self.IsPreview then
        level = 1
        levelLimit = XDataCenter.EquipManager.GetBreakthroughLevelLimitByTemplateId(self.TemplateId)
        self.PanelMaxLevel.gameObject:SetActive(false)
        self.PanelMaxStrengthen.gameObject:SetActiveEx(false)
        self.BtnStrengthen.gameObject:SetActive(false)
    else
        local equip = XDataCenter.EquipManager.GetEquip(equipId)
        level = equip.Level
        levelLimit = XDataCenter.EquipManager.GetBreakthroughLevelLimit(equipId)
        local isMaxLevel = XDataCenter.EquipManager.IsMaxLevelAndBreakthrough(equipId)
        self.PanelMaxLevel.gameObject:SetActive(isMaxLevel)
        self.PanelMaxStrengthen.gameObject:SetActiveEx(isMaxLevel)
        self.BtnStrengthen.gameObject:SetActive(not isMaxLevel)
    end

    self.TxtLevel.text = level
    self.TxtLevel2.text = levelLimit
end

-- 刷新武器突破
function XUiEquipDetailChildV2P6:UpdateEquipBreakThrough()
    if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
        local character = XDataCenter.NieRManager.GetSelNieRCharacter()
        local equipSite = XDataCenter.EquipManager.GetEquipSiteByTemplateId(self.TemplateId)
        local breakTimes = character:GetNieRWeaponBreakThrough()
        if equipSite and equipSite ~= XEnumConst.EQUIP.EQUIP_SITE.WEAPON then
            breakTimes = character:GetNieRWaferBreakThroughById(self.EquipId)
        end
        self:SetUiSprite(self.ImgBreak, self._Control:GetEquipBreakThroughIcon(breakTimes))
        return
    elseif self.IsPreview then
        self:SetUiSprite(self.ImgBreak, self._Control:GetEquipBreakThroughIcon(0))
        return
    end

    local equip = XDataCenter.EquipManager.GetEquip(self.EquipId)
    self:SetUiSprite(self.ImgBreak, self._Control:GetEquipBreakThroughIcon(equip.Breakthrough))
end

-- 刷新装备属性
function XUiEquipDetailChildV2P6:UpdateEquipAttr()
    local attrMap
    if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
        local equipLevel = XDataCenter.NieRManager.GetSelNieRCharacter():GetNieRWeaponLevel()
        local equipSite = XDataCenter.EquipManager.GetEquipSiteByTemplateId(self.TemplateId)
        if equipSite and equipSite ~= XEnumConst.EQUIP.EQUIP_SITE.WEAPON then
            equipLevel = XDataCenter.NieRManager.GetSelNieRCharacter():GetNieRWaferLevel(self.EquipId)
        end
        attrMap = XDataCenter.EquipManager.GetTemplateEquipAttrMap(self.EquipId, equipLevel)
    elseif self.IsPreview then
        attrMap = XDataCenter.EquipManager.GetTemplateEquipAttrMap(self.EquipId)
    else
        attrMap = XMVCA:GetAgency(ModuleId.XEquip):GetEquipAttrMap(self.EquipId)
    end

    for i = 1, XEnumConst.EQUIP.MAX_ATTR_COUNT do
        local attrInfo = attrMap[i]
        local isShow = attrInfo ~= nil
        self["PanelAttr" .. i].gameObject:SetActiveEx(isShow)
        if isShow then
            self["TxtName" .. i].text = attrInfo.Name
            self["TxtAttr" .. i].text = attrInfo.Value
        end
    end
end

-- 刷新扩展按钮名称
function XUiEquipDetailChildV2P6:UpdateExtendName()
    local nameKey = "EquipResonanceName"
    if self.IsWeapon and self.CanOverrun then
        nameKey = "EquipWeaponBtnName"
    elseif self.IsAwareness and self.CanAwake then
        nameKey = "EquipAwarenessBtnName"
    end
    local btnName = XUiHelper.GetText(nameKey)
    self.PanelAdd2:SetName(btnName)
    self.TxtExtendTitleNormal.text = btnName
end

--------------------#region 武器 --------------------
-- 刷新技能详情
function XUiEquipDetailChildV2P6:UpdateEquipSkillDesc()
    local weaponSkillInfo = XDataCenter.EquipManager.GetOriginWeaponSkillInfo(self.TemplateId)
    self.TxtSkillName.text = weaponSkillInfo.Name
    self.TxtSkillDes.text = weaponSkillInfo.Description

    local noWeaponSkill = not weaponSkillInfo.Name and not weaponSkillInfo.Description
    self.PanelAwarenessSkillDes.gameObject:SetActiveEx(false)
    self.PanelNoAwarenessSkill.gameObject:SetActiveEx(false)
    self.PanelWeaponSkillDes.gameObject:SetActiveEx(not noWeaponSkill)
    self.PanelNoWeaponSkill.gameObject:SetActiveEx(noWeaponSkill)
end

-- 刷新装备共鸣
function XUiEquipDetailChildV2P6:UpdateEquipResonance()
    local canResonance = XDataCenter.EquipManager.CanResonanceByTemplateId(self.TemplateId) or (self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI)
    self.PaneEquipResonance.gameObject:SetActive(canResonance)
    if not canResonance then
        return
    end

    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        self:UpdateEquipResonanceSkill(pos)
    end
end

-- 刷新单个装备共鸣
function XUiEquipDetailChildV2P6:UpdateEquipResonanceSkill(pos)
    local isEquip = not self.IsPreview and XDataCenter.EquipManager.CheckEquipPosResonanced(self.EquipId, pos) ~= nil
    local uiObj = self["GridEquipResonance" .. pos]
    uiObj:GetComponent("XUiButton"):SetDisable(not isEquip)
    self["GridEquipResonanceEffect"..pos].gameObject:SetActiveEx(false)
    if isEquip then
        if not self.ResonanceSkillDic then 
            self.ResonanceSkillDic = {} 
        end

        -- 按钮每个状态对应创建一个XUiGridResonanceSkill
        local stateNameList = {"Normal", "Press"}
        if not self.ResonanceSkillDic[pos] then 
            self.ResonanceSkillDic[pos] = {}
            for _, stateName in ipairs(stateNameList) do
                local stateGo = uiObj:GetObject(stateName)
                self.ResonanceSkillDic[pos][stateName] = XUiGridResonanceSkill.New(stateGo, self.EquipId, pos, self.CharacterId, function()
                    self:OnBtnResonanceSkill(pos)
                end, nil, self.ForceShowBindCharacter, true)
            end
        end
        
        -- 刷新所有状态的XUiGridResonanceSkill
        for _, stateName in ipairs(stateNameList) do
            local grid = self.ResonanceSkillDic[pos][stateName]
            grid:SetEquipIdAndPos(self.EquipId, pos)
            grid:Refresh()
        end
    end
end

-- 刷新武器超限
function XUiEquipDetailChildV2P6:UpdateOverrun()
    self.OverrunIconTips = nil
    local templateId = XDataCenter.EquipManager.GetEquipTemplateId(self.EquipId)
    self.CanOverrun = self._Control:CanOverrunByTemplateId(templateId)
    self.PaneOverrun.gameObject:SetActiveEx(self.CanOverrun)
    if not self.CanOverrun then 
        return
    end

    XDataCenter.EquipManager.CheckOverrunGuide(self.EquipId)
    local equip = XDataCenter.EquipManager.GetEquip(self.EquipId)
    local lv = equip:GetOverrunLevel()
    local btnName = XUiHelper.GetText("EquipOverrun")
    if lv > 0 then
        btnName = self._Control:GetWeaponDeregulateUIName(lv)
    elseif not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun) then
        btnName = XUiHelper.GetText("EquipOverrunUnlockTips")
    end
    self.BtnOverrun:SetName(btnName)

    self.BtnOverrunBlind.gameObject:SetActiveEx(false)
    self.BtnOverrunEmpty.gameObject:SetActiveEx(false)

    -- 未解锁
    local canBind = equip:IsOverrunCanBlindSuit()
    if not canBind then
        self.BtnOverrunBlind.gameObject:SetActiveEx(true)
        self.BtnOverrunBlind:SetDisable(true)
        self.OverrunIconTips = XUiHelper.GetText("EquipOverrunClickTips")
        return 
    end

    -- 解锁未绑定
    local choseSuitId = equip:GetOverrunChoseSuit()
    local isChoose = choseSuitId ~= 0
    if not isChoose then 
        self.BtnOverrunEmpty.gameObject:SetActiveEx(true)
        return
    end

    -- 解锁并且有绑定
    self.BtnOverrunBlind.gameObject:SetActiveEx(true)
    self.BtnOverrunBlind:SetDisable(false)
    local stateList = { "Normal", "Press"}
    local iconPath = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitIconPath(choseSuitId)
    local isMatch = equip:IsOverrunBlindMatch()
    local uiObj = self.BtnOverrunBlind:GetComponent("UiObject")
    for _, stateName in ipairs(stateList) do
        local stateObj = uiObj:GetObject(stateName)
        stateObj:GetObject("RImgSuit"):SetRawImage(iconPath)
        stateObj:GetObject("ImgNotMatching").gameObject:SetActiveEx(not isMatch)
    end
    self.OverrunBlindEffect.gameObject:SetActiveEx(false)
end

-- 刷新超限场景特效
function XUiEquipDetailChildV2P6:UpdateOverrunSceneEffect()
    self.ImgEffectOverrun.gameObject:SetActiveEx(false)
    if self.IsPreview then
        return
    end

    local equip = XDataCenter.EquipManager.GetEquip(self.EquipId)
    local level = equip:GetOverrunLevel()
    if level < 1 then
        return
    end

    self.ImgEffectOverrun.gameObject:SetActiveEx(true)
    local sceneLoopEffectPath = self._Control:GetWeaponDeregulateUISceneLoopEffectPath(level)
    if sceneLoopEffectPath then
        self.ImgEffectOverrun:LoadPrefab(sceneLoopEffectPath)
    end
end
--------------------#endregion 装备 --------------------


--------------------#region 意识 --------------------

-- 注册切换意识事件
function XUiEquipDetailChildV2P6:RegisterAwarenessSwitch()
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeft)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRight)

    local btns = {}
    for index = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        table.insert(btns, self["BtnNumber" .. index])
    end
    self.BtnGridGroup:Init(btns, function(index)
        self:OnClickSwitchAwareness(index)
    end)
end

function XUiEquipDetailChildV2P6:OnBtnLeft()
    local index = self.SelectAwarenessIndex
    while(index > 1) do
        index = index - 1
        local canSwitch = self:CheckCanSwitchAwareness(index)
        if canSwitch then
            self:OnClickSwitchAwareness(index)
            return
        end
    end
end

function XUiEquipDetailChildV2P6:OnBtnRight()
    local index = self.SelectAwarenessIndex
    while(index < XEnumConst.EQUIP.WEAR_AWARENESS_COUNT) do
        index = index + 1
        local canSwitch = self:CheckCanSwitchAwareness(index)
        if canSwitch then
            self:OnClickSwitchAwareness(index)
            return
        end
    end
end

-- 点击切换意识
function XUiEquipDetailChildV2P6:OnClickSwitchAwareness(index)
    if self.SelectAwarenessIndex == index then
        return
    end

    local canSwitch = self:CheckCanSwitchAwareness(index)
    if not canSwitch then
        return
    end

    self.SelectAwarenessIndex = index
    self.EquipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(self.CharacterId, index)
    self.TemplateId = XDataCenter.EquipManager.GetEquipTemplateId(self.EquipId)
    self:UpdateView()
    self:PlayAnimation("QieHuan")
end

-- 检查是否可以切换到对应位置的意识
function XUiEquipDetailChildV2P6:CheckCanSwitchAwareness(index)
    local equipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(self.CharacterId, index)
    local canSwitch = equipId ~= nil
    return canSwitch
end

-- 刷新意识切换按钮
function XUiEquipDetailChildV2P6:UpdateAwarenessSwitchBtn()
    local isShow = self.CharacterId and (XDataCenter.EquipManager.GetCharacterWearingAwarenessIdCount(self.CharacterId) > 1) 
        and XDataCenter.EquipManager.IsEquipWearingByCharacterId(self.EquipId, self.CharacterId)

    self.PanelTab.gameObject:SetActiveEx(isShow)
    if not isShow then return end

    local canLast = false
    local canNext = false
    for index = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local canSwitch = self:CheckCanSwitchAwareness(index)
        if canSwitch then
            if index < self.SelectAwarenessIndex then
                canLast = true
            end
            if index > self.SelectAwarenessIndex then
                canNext = true
            end

            local state = index == self.SelectAwarenessIndex and CS.UiButtonState.Select or CS.UiButtonState.Normal
            self["BtnNumber" .. index]:SetButtonState(state)
        else
            self["BtnNumber" .. index]:SetButtonState(CS.UiButtonState.Disable)
        end
    end

    self.BtnLeft.gameObject:SetActiveEx(canLast)
    self.BtnRight.gameObject:SetActiveEx(canNext)
end

-- 更新画师
function XUiEquipDetailChildV2P6:UpdatePainter()
    local breakthroughTimes = self.IsPreview and 0 or XDataCenter.EquipManager.GetBreakthroughTimes(self.EquipId)
    self.TxtPainter.text = XDataCenter.EquipManager.GetEquipPainterName(self.TemplateId, breakthroughTimes)
    self.PanelPainter.gameObject:SetActive(true)
end

-- 刷新意识套装技能详情
function XUiEquipDetailChildV2P6:UpdateSuitSkillDesc()
    local suitId = XDataCenter.EquipManager.GetSuitIdByTemplateId(self.TemplateId)
    local skillDesList = XDataCenter.EquipManager.GetSuitSkillDesList(suitId)

    local noSuitSkill = true
    for i = 1, XEnumConst.EQUIP.SUIT_MAX_SKILL_COUNT do
        if skillDesList[i * 2] then
            self["TxtSkillDes" .. i].text = skillDesList[i * 2]
            self["TxtPos" .. i].text = XUiHelper.GetText("EquipSuitSkillPrefix" .. i * 2)
            self["TxtSkillDes" .. i].gameObject:SetActiveEx(true)
            noSuitSkill = false
        else
            self["TxtSkillDes" .. i].gameObject:SetActiveEx(false)
        end
    end

    self.PanelWeaponSkillDes.gameObject:SetActiveEx(false)
    self.PanelNoWeaponSkill.gameObject:SetActiveEx(false)
    self.PanelAwarenessSkillDes.gameObject:SetActiveEx(not noSuitSkill)
    self.PanelNoAwarenessSkill.gameObject:SetActiveEx(noSuitSkill)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelAwarenessSkillDes:FindTransform("PaneContent"))
end

-- 刷新意识共鸣
function XUiEquipDetailChildV2P6:UpdateAwarenessResonance()
    local canResonance = XDataCenter.EquipManager.CanResonanceByTemplateId(self.TemplateId) or (self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI)
    self.PanelAwarenessResonance.gameObject:SetActive(canResonance)
    if not canResonance then
        return
    end

    for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        self:UpdateAwarenessResonanceSkill(pos)
    end

    self.CanAwake = XDataCenter.EquipManager.CheckEquipStarCanAwake(self.EquipId)
    self.BtnResonanceEquip1.gameObject:SetActiveEx(self.CanAwake)
    self.BtnResonanceEquip2.gameObject:SetActiveEx(self.CanAwake)
end

-- 刷新单个意识共鸣
function XUiEquipDetailChildV2P6:UpdateAwarenessResonanceSkill(pos)
    local isEquip = not self.IsPreview and XDataCenter.EquipManager.CheckEquipPosResonanced(self.EquipId, pos) ~= nil
    local uiObj = self["GridAwarenessResonance" .. pos]
    local skillGo = uiObj:GetObject("GridResonanceSkill")
    skillGo.gameObject:SetActive(isEquip)
    uiObj:GetObject("PanelEmptySkill").gameObject:SetActive(not isEquip)

    if isEquip then
        self.ResonanceSkillDic = self.ResonanceSkillDic or {}
        local grid = self.ResonanceSkillDic[pos]
        if not grid then
            grid = XUiGridResonanceSkill.New(skillGo, self.EquipId, pos, self.CharacterId, function()
                self:OnBtnResonanceSkill(pos)
            end, nil, self.ForceShowBindCharacter, true)
            self.ResonanceSkillDic[pos] = grid
        end
        grid:SetEquipIdAndPos(self.EquipId, pos)
        grid:Refresh()
    end
end

--------------------#endregion 意识 --------------------

return XUiEquipDetailChildV2P6