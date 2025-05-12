local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridResonanceSkill = require("XUi/XUiPlayerInfo/XUiGridResonanceSkillOther")

local XUiEquipDetailOther = XLuaUiManager.Register(XLuaUi, "UiEquipDetailOther")

function XUiEquipDetailOther:OnAwake()
    -- UI初始化
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.BtnLock.gameObject:SetActiveEx(false)
    self.BtnUnlock.gameObject:SetActiveEx(false)
    self.BtnLaJi.gameObject:SetActiveEx(false)
    self.BtnUnLaJi.gameObject:SetActiveEx(false)
    self.BtnStrengthen.gameObject:SetActiveEx(false)
    self.BtnResonance.gameObject:SetActiveEx(false)
    self.BtnOverrun.gameObject:SetActiveEx(false)
    self.GridAwarenessResonance1:GetObject("GridResonanceSkill"):GetObject("BtnClick").gameObject:SetActiveEx(false)
    self.GridAwarenessResonance2:GetObject("GridResonanceSkill"):GetObject("BtnClick").gameObject:SetActiveEx(false)
    self.BtnResonanceEquip1.gameObject:SetActiveEx(false)
    self.BtnResonanceEquip2.gameObject:SetActiveEx(false)
    self.PanelExtend.gameObject:SetActiveEx(false)

    self.PanelTab.gameObject:SetActiveEx(false)
    self.PanelPainter.gameObject:SetActiveEx(false)
    self.PaneOverrun.gameObject:SetActiveEx(false)
    self.PaneEquipResonance.gameObject:SetActiveEx(false)
    self.PanelAwarenessResonance.gameObject:SetActiveEx(false)

    -- 场景初始化
    local sceneRoot = self.UiSceneInfo.Transform
    local root = self.UiModelGo.transform
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.PanelWeaponPlane = sceneRoot:FindTransform("Plane")
    self.ImgEffectOverrun = root:FindTransform("ImgEffectOverrun")

    self:SetButtonCallBack()
    self:InitPanelAsset()
end

-- equip : XEquip | XEquipViewModel
-- character : XCharacter | XCharacterViewModel
function XUiEquipDetailOther:OnStart(equip, character)
    self.Equip = equip
    self.Character = character
    self.TemplateId = equip.TemplateId
    self.IsWeapon = equip:IsWeapon()
    self.IsAwareness = equip:IsAwareness()

    -- 播放扩展面板动画，动画切到最后一帧
    self.IsShowExtend = false
    local anim = self.IsShowExtend and self.AnimFold or self.AnimUnFold
    anim:Play()
    anim.time = anim.duration
    anim:Evaluate()
    anim:Stop()
end

function XUiEquipDetailOther:OnEnable()
    self:UpdateView()
end

function XUiEquipDetailOther:OnDestroy()
    self.PanelWeaponPlane.gameObject:SetActiveEx(true)
    self:ReleaseModel()
    self:ReleaseLihuiTimer()
end

function XUiEquipDetailOther:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
    self:RegisterClickEvent(self.PanelAdd, self.ShowPanelSkill)
    self:RegisterClickEvent(self.PanelAdd2, self.ShowPanelExtend)
end

function XUiEquipDetailOther:OnBtnBackClick()
    self:Close()
end

function XUiEquipDetailOther:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

-- 显示技能面板
function XUiEquipDetailOther:ShowPanelSkill()
    self.IsShowExtend = false
    self:PlayAnimation("AnimUnFold")
end

-- 显示扩展面板
function XUiEquipDetailOther:ShowPanelExtend()
    self.IsShowExtend = true
    self:PlayAnimation("AnimFold")
end

function XUiEquipDetailOther:InitPanelAsset()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin
    )
end

-- 初始化武器模型/意识立绘
function XUiEquipDetailOther:InitModel()
    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.PanelWeaponPlane.gameObject:SetActiveEx(false)
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    if self.IsWeapon then
        local breakthroughTimes = self.Equip.Breakthrough
        local resonanceCount = self.Equip:GetResonanceCount()
        local modelTransformName = "UiEquipDetail"
        local modelConfig = XMVCA.XEquip:GetWeaponModelCfg(self.TemplateId, modelTransformName, breakthroughTimes, resonanceCount)
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
        self.PanelWeapon.gameObject:SetActiveEx(true)
    elseif self.IsAwareness then
        self:ReleaseModel()
        local breakthroughTimes = self.Equip.Breakthrough
        local resPath = XMVCA.XEquip:GetEquipLiHuiPath(self.TemplateId, breakthroughTimes)
        self.Loader = self.Loader or self.Transform:GetLoader()
        local texture = self.Loader:Load(resPath)
        self.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)

        self:ReleaseLihuiTimer()
        self.LihuiTimer = XScheduleManager.ScheduleOnce(function()
            self.FxUiLihuiChuxian01.gameObject:SetActiveEx(true)
            self.LihuiTimer = nil
        end,500)
    end
end

-- 释放模型
function XUiEquipDetailOther:ReleaseModel()
    
end

-- 释放定时器
function XUiEquipDetailOther:ReleaseLihuiTimer()
    if self.LihuiTimer then
        XScheduleManager.UnSchedule(self.LihuiTimer)
        self.LihuiTimer = nil
    end
end

function XUiEquipDetailOther:UpdateView()
    self:InitModel()
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

-- 刷新穿戴武器信息
function XUiEquipDetailOther:UpdateCharacterInfo()
    local equip = self.Equip
    local isWearing = equip:IsWearing()
    self.PanelCharacterInfo.gameObject:SetActiveEx(isWearing)
    if isWearing then
        local icon = XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(equip.CharacterId)
        self.RImgCharHead:SetRawImage(icon)
    end
end

-- 刷新武器信息
function XUiEquipDetailOther:UpdateEquipInfo()
    local star = XMVCA.XEquip:GetEquipStar(self.TemplateId)
    for i = 1, XEnumConst.EQUIP.MAX_STAR_COUNT do
        self["ImgStar" .. i].gameObject:SetActiveEx(i <= star)
    end
    self.TxtEquipName.text = XMVCA.XEquip:GetEquipName(self.TemplateId)

    self.TxtWeaponType.gameObject:SetActiveEx(self.IsWeapon)
    if self.IsWeapon then 
        local equipType = XMVCA:GetAgency(ModuleId.XEquip):GetEquipType(self.TemplateId)
        local weaponGroupCfg = XMVCA.XArchive:GetWeaponGroupByType(equipType)
        self.TxtWeaponType.text = weaponGroupCfg and weaponGroupCfg.GroupName or ""
    end
end

-- 刷新武器等级
function XUiEquipDetailOther:UpdateEquipLevel()
    local equip = self.Equip
    local levelLimit = self._Control:GetBreakthroughLevelLimit(equip.TemplateId, equip.Breakthrough)
    self.TxtLevel.text = equip.Level
    self.TxtLevel2.text = levelLimit

    local isMaxLevel = equip.Level >= levelLimit
    local isMaxBreakthrough = self._Control:GetEquipMaxBreakthrough(equip.TemplateId)
    local isMax = isMaxLevel and isMaxBreakthrough
    self.PanelMaxLevel.gameObject:SetActive(isMax)
    self.PanelMaxStrengthen.gameObject:SetActiveEx(isMax)
end

-- 刷新武器突破
function XUiEquipDetailOther:UpdateEquipBreakThrough()
    local iconPath = self._Control:GetEquipBreakThroughIcon(self.Equip.Breakthrough)
    self:SetUiSprite(self.ImgBreak, iconPath)
end

-- 刷新装备属性
function XUiEquipDetailOther:UpdateEquipAttr()
    local attrMap = XMVCA.XEquip:GetEquipAttrMapByEquipData(self.Equip)
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
function XUiEquipDetailOther:UpdateExtendName()
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
function XUiEquipDetailOther:UpdateEquipSkillDesc()
    local weaponSkillInfo = XMVCA.XEquip:GetEquipWeaponSkillInfo(self.TemplateId)
    self.TxtSkillName.text = weaponSkillInfo.Name
    self.TxtSkillDes.text = weaponSkillInfo.Description

    local noWeaponSkill = not weaponSkillInfo.Name and not weaponSkillInfo.Description
    self.PanelAwarenessSkillDes.gameObject:SetActiveEx(false)
    self.PanelNoAwarenessSkill.gameObject:SetActiveEx(false)
    self.PanelWeaponSkillDes.gameObject:SetActiveEx(not noWeaponSkill)
    self.PanelNoWeaponSkill.gameObject:SetActiveEx(noWeaponSkill)
end

-- 刷新装备共鸣
function XUiEquipDetailOther:UpdateEquipResonance()
    local canResonance = XMVCA.XEquip:CanResonanceByTemplateId(self.TemplateId)
    self.PaneEquipResonance.gameObject:SetActive(canResonance)
    if not canResonance then
        return
    end

    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        self:UpdateEquipResonanceSkill(pos)
    end
end

-- 刷新单个装备共鸣
function XUiEquipDetailOther:UpdateEquipResonanceSkill(pos)
    local isEquip = self.Equip:GetResonanceInfo(pos) ~= nil
    local uiObj = self["GridEquipResonance" .. pos]
    uiObj:GetComponent("XUiButton"):SetDisable(not isEquip)
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
                self.ResonanceSkillDic[pos][stateName] = XUiGridResonanceSkill.New(stateGo, self.Equip, pos, nil, self.Character)
            end
        end
        
        -- 刷新所有状态的XUiGridResonanceSkill
        for _, stateName in ipairs(stateNameList) do
            local grid = self.ResonanceSkillDic[pos][stateName]
            grid:Refresh()
        end
    end
end

-- 刷新武器超限
function XUiEquipDetailOther:UpdateOverrun()
    self.CanOverrun = self._Control:CanOverrunByTemplateId(self.TemplateId)
    self.PaneOverrun.gameObject:SetActiveEx(self.CanOverrun)
    if not self.CanOverrun then 
        return
    end

    local equip = self.Equip
    local lv = equip:GetOverrunLevel()
    local btnName = XUiHelper.GetText("EquipOverrun")
    if lv > 0 then
        btnName = self._Control:GetWeaponDeregulateUIName(lv)
    elseif not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun) then
        btnName = XUiHelper.GetText("NotUnlock")
    end
    self.BtnOverrun:SetName(btnName)

    self.BtnOverrunBlind.gameObject:SetActiveEx(false)
    self.BtnOverrunEmpty.gameObject:SetActiveEx(false)

    -- 未解锁
    local canBind = equip:IsOverrunCanBlindSuit()
    if not canBind then
        self.BtnOverrunBlind.gameObject:SetActiveEx(true)
        self.BtnOverrunBlind:SetDisable(true)
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
end

-- 刷新超限场景特效
function XUiEquipDetailOther:UpdateOverrunSceneEffect()
    self.ImgEffectOverrun.gameObject:SetActiveEx(false)
    local equip = self.Equip
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

-- 更新画师
function XUiEquipDetailOther:UpdatePainter()
    local breakthroughTimes = self.Equip.Breakthrough
    self.TxtPainter.text = XMVCA.XEquip:GetEquipPainterName(self.TemplateId, breakthroughTimes)
    self.PanelPainter.gameObject:SetActive(true)
end

-- 刷新意识套装技能详情
function XUiEquipDetailOther:UpdateSuitSkillDesc()
    local suitId = XMVCA.XEquip:GetEquipSuitId(self.TemplateId)
    local skillDesList = XMVCA.XEquip:GetEquipSuitSkillDescription(suitId)

    local noSuitSkill = true
    for i = 1, XEnumConst.EQUIP.SUIT_MAX_SKILL_COUNT do
        if skillDesList[i * 2] then
            self["TxtSkillDes" .. i].text = skillDesList[i * 2]
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
function XUiEquipDetailOther:UpdateAwarenessResonance()
    local canResonance = XMVCA.XEquip:CanResonanceByTemplateId(self.TemplateId)
    self.PanelAwarenessResonance.gameObject:SetActive(canResonance)
    if not canResonance then
        return
    end

    for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        self:UpdateAwarenessResonanceSkill(pos)
    end

    self.CanAwake = self._Control:IsEquipCanAwake(self.TemplateId)
end

-- 刷新单个意识共鸣
function XUiEquipDetailOther:UpdateAwarenessResonanceSkill(pos)
    local isEquip = self.Equip:GetResonanceInfo(pos) ~= nil
    local uiObj = self["GridAwarenessResonance" .. pos]
    local skillGo = uiObj:GetObject("GridResonanceSkill")
    skillGo.gameObject:SetActive(isEquip)
    uiObj:GetObject("PanelEmptySkill").gameObject:SetActive(false)
    uiObj:GetObject("PanelNoSkill").gameObject:SetActive(not isEquip)

    if isEquip then
        self.ResonanceSkillDic = self.ResonanceSkillDic or {}
        local grid = self.ResonanceSkillDic[pos]
        if not grid then
            grid = XUiGridResonanceSkill.New(skillGo, self.Equip, pos, nil, self.Character)
            self.ResonanceSkillDic[pos] = grid
        end
        grid:Refresh()
    end
end

--------------------#endregion 意识 --------------------

return XUiEquipDetailOther
