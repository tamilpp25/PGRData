local XUiEquipDetailV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipDetailV2P6")
function XUiEquipDetailV2P6:OnAwake()
    -- UI初始化
    self.PanelTab.gameObject:SetActiveEx(false)

    -- 场景初始化
    local sceneRoot = self.UiSceneInfo.Transform
    local root = self.UiModelGo.transform
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.PanelWeaponPlane = sceneRoot:FindTransform("Plane")
    self.PanelWeaponPlane.gameObject:SetActiveEx(false)
    self.ImgEffectOverrun = root:FindTransform("ImgEffectOverrun")

    self:SetButtonCallBack()
    self:InitPanelAsset()
    self:InitTabGroup()
end

--参数isPreview为true时是装备详情预览，传templateId进来
--characterId只有需要判断武器共鸣特效时才传
function XUiEquipDetailV2P6:OnStart(equipId, isPreview, characterId, forceShowBindCharacter, childUiIndex, openUiType, openResonanceSkillPos)
    self.IsPreview = isPreview
    self.EquipId = equipId
    self.CharacterId = characterId
    self.ForceShowBindCharacter = forceShowBindCharacter
    self.TabIndex = childUiIndex
    self.TemplateId = isPreview and self.EquipId or XDataCenter.EquipManager.GetEquipTemplateId(equipId)
    self.OpenUiType = openUiType
    self.OpenResonanceSkillPos = openResonanceSkillPos
    self.IsWeapon = XDataCenter.EquipManager.IsWeaponByTemplateId(self.TemplateId)
    self.IsAwareness = XDataCenter.EquipManager.IsAwarenessByTemplateId(self.TemplateId)
    if self.IsAwareness then
        self.SelectAwarenessIndex = XDataCenter.EquipManager.GetEquipSite(equipId)
    end

    if not XDataCenter.VoteManager.IsInit() then
        XDataCenter.VoteManager.GetVoteGroupListRequest()
    end
end

function XUiEquipDetailV2P6:OnEnable()
    self:UpdateView()
end

function XUiEquipDetailV2P6:OnDestroy()
    self.PanelWeaponPlane.gameObject:SetActiveEx(true)
    self:ReleaseModel()
    self:ReleaseLihuiTimer()
end

function XUiEquipDetailV2P6:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_OVERRUN_CHANGE_NOTYFY,
    }
end

function XUiEquipDetailV2P6:OnNotify(evt, ...)
    local args = {...}
    if evt == XEventId.EVENT_EQUIP_OVERRUN_CHANGE_NOTYFY then
        self:UpdateBtnOverrunRed()
    end
end

function XUiEquipDetailV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self:RegisterClickEvent(self.BtnStrengthenMax, self.OnBtnStrengthenMax)

    -- 意识切换
    self:RegisterAwarenessSwitch()
end

function XUiEquipDetailV2P6:OnBtnBackClick()
    if XLuaUiManager.IsUiShow("UiEquipResonanceSelectV2P6") then
        self.PanelTabGroup:SelectIndex(XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE)
    elseif XLuaUiManager.IsUiShow("UiEquipResonanceAwakeV2P6") then
        self.PanelTabGroup:SelectIndex(XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING)
    else
        self:Close()
    end
end

function XUiEquipDetailV2P6:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiEquipDetailV2P6:OnBtnStrengthenMax()
    XUiManager.TipText("EquipStrengthenMaxLevel")
end

function XUiEquipDetailV2P6:OnBtnHelpClick()
    local keyStr = self.IsWeapon and "EquipWeapon" or "EquipAwareness"

    local indexKey
    if self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.STRENGTHEN then
        indexKey = self.IsWeapon and "WeaponHelpStrength" or "AwarenessHelpStrength"
    elseif self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE then
        indexKey = self.IsWeapon and "WeaponHelpResonance" or "AwarenessHelpResonance"
    elseif self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING then
        indexKey = "AwarenessHelpOverclocking"
    elseif self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERRUN then
        indexKey = "WeaponHelpOverrun"
    end
    local index = CS.XGame.ClientConfig:GetInt(indexKey)

    XUiManager.ShowHelpTip(keyStr, nil, index)
end

function XUiEquipDetailV2P6:InitPanelAsset()
    self.AssetPanel = XUiPanelAsset.New(
        self,
        self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin
    )
end

-- 初始化武器模型/意识立绘
function XUiEquipDetailV2P6:InitModel()
    self.PanelWeapon.gameObject:SetActiveEx(false)
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
function XUiEquipDetailV2P6:ReleaseModel()
    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
        self.Resource = nil
    end
end

-- 释放定时器
function XUiEquipDetailV2P6:ReleaseLihuiTimer()
    if self.LihuiTimer then
        XScheduleManager.UnSchedule(self.LihuiTimer)
        self.LihuiTimer = nil
    end
end

function XUiEquipDetailV2P6:InitTabGroup()
    self.TabGroup = {
        self.BtnStrengthen,
        self.BtnResonance,
        self.BtnOverclocking,
        self.BtnOverrun,
    }

    self.PanelTabGroup:Init(self.TabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiEquipDetailV2P6:OnClickTabCallBack(tabIndex)
    if tabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.STRENGTHEN then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipStrengthen) then
            return
        end
        self:OpenChildUiByName("UiEquipStrengthenV2P6", self)
    elseif tabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipResonance) then
            return
        end
        if self.OpenResonanceSkillPos then 
            self:OpenChildUiResonanceSelect(self.OpenResonanceSkillPos)
            self.OpenResonanceSkillPos = nil
        else
            self:OpenChildUiByName("UiEquipResonanceSkillV2P6", self, self.CharacterId, self.ForceShowBindCharacter)
        end
        
    elseif tabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING then
        if not self:CheckCanOverclocking(self.EquipId) then
            XUiManager.TipText("SuperAwareness")
            return
        end
        if self.OpenResonanceSkillPos then
            self:OpenChildUiResonanceAwake(self.OpenResonanceSkillPos)
            self.OpenResonanceSkillPos = nil
        else
            self:OpenChildUiByName("UiExhibitionOverclockingV2P6", self, self.CharacterId, self.ForceShowBindCharacter)
        end
    elseif tabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERRUN then
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun) then 
            local tips = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.EquipOverrun)
            XUiManager.TipError(tips)
            return
        end
        self:SaveEnterOverrunRedData()
        self:UpdateBtnOverrunRed()
        self:OpenChildUiByName("UiEquipOverrunV2P6", self)
    end

    self.TabIndex = tabIndex
    if self.IsAwareness then
        self:UpdateAwarenessSwitchBtn()
    end
end

-- 在该类内自己打开ui
function XUiEquipDetailV2P6:OpenChildUiByName(uiname, ...)
    self.CurChildName = uiname
    self:OpenOneChildUi(uiname, ...)
end

-- 打开共鸣对应位置界面
function XUiEquipDetailV2P6:OpenChildUiResonanceSelect(pos)
    self:OpenOneChildUi("UiEquipResonanceSelectV2P6", self, self.CharacterId, self.ForceShowBindCharacter)
    self.ChildUiEquipResonanceSelectV2P6:SetPos(self.EquipId, pos)
    self:UpdateAwarenessSwitchBtn()
end

-- 打开超频对应位置界面
function XUiEquipDetailV2P6:OpenChildUiResonanceAwake(pos)
    self:OpenOneChildUi("UiEquipResonanceAwakeV2P6", self, self.CharacterId, self.ForceShowBindCharacter)
    self.ChildUiEquipResonanceAwakeV2P6:SetPos(self.EquipId, pos)
    self:UpdateAwarenessSwitchBtn()
end

-- 共鸣成功
function XUiEquipDetailV2P6:OnResonanceSuccess()
    self:UpdateOverclockingBtn()
    self.PanelTabGroup:SelectIndex(XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE)
end

-- 超频成功
function XUiEquipDetailV2P6:OnOverClockingSuccess()
    self.PanelTabGroup:SelectIndex(XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING)
end

-- 跳转到共鸣页签，对应位置共鸣界面
function XUiEquipDetailV2P6:JumpToEquipResonanceSelect(pos)
    if self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE then
        self:OpenChildUiResonanceSelect(pos)
    else
        self.OpenResonanceSkillPos = pos
        self.PanelTabGroup:SelectIndex(XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE)
    end
end

function XUiEquipDetailV2P6:UpdateTabBtnState()
    if self.IsPreview then
        self.PanelTabGroup.gameObject:SetActiveEx(false)
        return
    end

    -- 强化
    self:UpdateStrengthenBtn()

    -- 共鸣
    local isShowResonance = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.EquipResonance) and
        XDataCenter.EquipManager.CanResonanceByTemplateId(self.TemplateId)
    self.BtnResonance.gameObject:SetActiveEx(isShowResonance)
    if isShowResonance then
        self.BtnResonance:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipResonance))
    end

    -- 超频
    self:UpdateOverclockingBtn()

    -- 超限
    local canOverrun = self._Control:CanOverrunByTemplateId(self.TemplateId)
    self.BtnOverrun.gameObject:SetActiveEx(canOverrun)
    if canOverrun then
        self.BtnOverrun:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun))
        self:UpdateBtnOverrunRed()
    end
end

-- 刷新界面
function XUiEquipDetailV2P6:UpdateView()
    self:InitModel()
    self:UpdateOverrunSceneEffect()
    self:UpdateTabBtnState()
    self.PanelTabGroup:SelectIndex(self.TabIndex)
end

-- 刷新强化按钮
function XUiEquipDetailV2P6:UpdateStrengthenBtn()
    if self.IsPreview then
        return
    end
    local equipId = self.EquipId

    if XDataCenter.EquipManager.CanBreakThrough(equipId) then
        self.BtnStrengthen:SetNameByGroup(0, XUiHelper.GetText("EquipBreakthroughBtnTxt1"))
        self.BtnStrengthen:SetNameByGroup(1, XUiHelper.GetText("EquipBreakthroughBtnTxt2"))
    else
        self.BtnStrengthen:SetNameByGroup(0, XUiHelper.GetText("EquipStrengthenBtnTxt1"))
        self.BtnStrengthen:SetNameByGroup(1, XUiHelper.GetText("EquipStrengthenBtnTxt2"))
    end

    local isMaxLevel = XDataCenter.EquipManager.IsMaxLevelAndBreakthrough(equipId)
    self.BtnStrengthenMax.gameObject:SetActiveEx(isMaxLevel)
    self.BtnStrengthen.gameObject:SetActiveEx(not isMaxLevel)
    if not isMaxLevel then 
        self.BtnStrengthen:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipStrengthen))
    end
end

-- 刷新超频按钮
function XUiEquipDetailV2P6:UpdateOverclockingBtn()
    local isShowOverclocking = self.IsAwareness and XDataCenter.EquipManager.CheckEquipStarCanAwake(self.EquipId)
    self.BtnOverclocking.gameObject:SetActiveEx(isShowOverclocking)
    if isShowOverclocking then
        self.BtnOverclocking:SetDisable(not self:CheckCanOverclocking(self.EquipId))
    end
end

--------------------#region 武器 --------------------

-- 刷新超限按钮红点
function XUiEquipDetailV2P6:UpdateBtnOverrunRed()
    if self.IsPreview then
        return
    end

    -- 未解锁，不显示蓝点
    local isUnlock = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun)
    if not isUnlock then
        self.BtnOverrun:ShowReddot(false)
        return
    end

    -- 解锁后，未点开过，显示蓝点
    local saveKey = self:GetEnterOverrunSaveKey()
    local isEnter = XSaveTool.GetData(saveKey) == true
    if not isEnter then
        self.BtnOverrun:ShowReddot(true)
        return
    end

    -- 超限可绑定意识套装，但未绑定意识套装，显示蓝点
    local equip = XDataCenter.EquipManager.GetEquip(self.EquipId)
    if equip:IsShowOverrunRed() then 
        self.BtnOverrun:ShowReddot(true)
        return
    end

    self.BtnOverrun:ShowReddot(false)
end

function XUiEquipDetailV2P6:GetEnterOverrunSaveKey()
    return "XUiEquipDetail:GetEnterOverrunSaveKey()  XPlayer.Id" .. tostring(XPlayer.Id) 
end

-- 保存进入过超限界面的红点数据
function XUiEquipDetailV2P6:SaveEnterOverrunRedData()
    local saveKey = self:GetEnterOverrunSaveKey()
    XSaveTool.SaveData(saveKey, true)
end

-- 刷新超限场景特效
function XUiEquipDetailV2P6:UpdateOverrunSceneEffect()
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

-- 播放超限升级特效
function XUiEquipDetailV2P6:PlayOverrunLevelUpEffect()
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
    local sceneStartEffectPath = self._Control:GetWeaponDeregulateUISceneStartEffectPath(level)
    if sceneStartEffectPath then
        self.ImgEffectOverrun:LoadPrefab(sceneStartEffectPath)
    end
end

--------------------#endregion 武器 --------------------

--------------------#region 意识 --------------------

-- 注册切换意识事件
function XUiEquipDetailV2P6:RegisterAwarenessSwitch()
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

function XUiEquipDetailV2P6:OnBtnLeft()
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

function XUiEquipDetailV2P6:OnBtnRight()
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
function XUiEquipDetailV2P6:OnClickSwitchAwareness(index)
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
end

-- 检查是否可以切换到对应位置的意识
function XUiEquipDetailV2P6:CheckCanSwitchAwareness(index)
    local equipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(self.CharacterId, index)
    if not equipId then
        return false
    end

    -- 强化页签
    if self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.STRENGTHEN then 
        local isMaxLevel = XDataCenter.EquipManager.IsMaxLevelAndBreakthrough(equipId)
        return not isMaxLevel

    -- 共鸣页签
    elseif self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE then  
        local canResonance = XDataCenter.EquipManager.CanResonance(equipId)
        return canResonance

    -- 超频页签
    elseif self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING then
        local canOverlocking = self:CheckCanOverclocking(equipId)
        return canOverlocking
    end

    return false
end

-- 刷新意识切换按钮
function XUiEquipDetailV2P6:UpdateAwarenessSwitchBtn()
    local isShow = not XLuaUiManager.IsUiShow("UiEquipResonanceSelectV2P6")
        and not XLuaUiManager.IsUiShow("UiEquipResonanceAwakeV2P6")
        and self.CharacterId and (XDataCenter.EquipManager.GetCharacterWearingAwarenessIdCount(self.CharacterId) > 1)
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

-- 检查是否可超频
function XUiEquipDetailV2P6:CheckCanOverclocking(equipId)
    if not XTool.IsNumberValid(equipId) then
        return
    end 
    for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        if XDataCenter.EquipManager.CheckEquipCanAwake(equipId, pos) then
            return true
        end
    end

    return false
end
--------------------#endregion 意识 --------------------

return XUiEquipDetailV2P6