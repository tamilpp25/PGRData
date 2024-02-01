local CSTextManager = CS.XTextManager

local XUiEquipDetail = XLuaUiManager.Register(XLuaUi, "UiEquipDetail")

local _SELECTTYPE = {
    Left = 1,
    Right = 2
}

local _SELECTBOARD = {
    LeftBoard = 1,
    RightBoard = 6
}

function XUiEquipDetail:OnAwake()
    self:InitAutoScript()

    XUiEquipDetail.BtnTabIndex = XEquipConfig.EquipDetailBtnTabIndex

    self.AssetPanel =
        XUiPanelAsset.New(
        self,
        self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin
    )

    self.TabGroup = {
        self.BtnDetail,
        self.BtnStrengthen,
        self.BtnResonance,
        self.BtnOverclocking,
        self.BtnOverrun,
    }
end

local CheckCanAwake = function (equipId)
    if not XTool.IsNumberValid(equipId) then
        return
    end 
    for pos = 1, 2 do
        if XDataCenter.EquipManager.CheckEquipCanAwake(equipId, pos) then
            return true
        end
    end

    return false
end

-- 在该类内自己打开ui
local OpenChildUiByName = function(selfUi, uiname, ...)
    selfUi.CurChildName = uiname
    selfUi:OpenOneChildUi(selfUi.CurChildName, ...)
end

--参数isPreview为true时是装备详情预览，传templateId进来
--characterId只有需要判断武器共鸣特效时才传
function XUiEquipDetail:OnStart(equipId, isPreview, characterId, forceShowBindCharacter, childUiIndex, openUiType)
    self.IsPreview = isPreview
    self.EquipId = equipId
    self.CharacterId = characterId
    self.ForceShowBindCharacter = forceShowBindCharacter
    self.TemplateId = isPreview and self.EquipId or XDataCenter.EquipManager.GetEquipTemplateId(equipId)
    self.OpenUiType = openUiType

    local sceneRoot = self.UiSceneInfo.Transform
    local root = self.UiModelGo.transform
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.PanelWeaponPlane = sceneRoot:FindTransform("Plane")
    self.PanelWeaponPlane.gameObject:SetActiveEx(false)
    self.ImgEffectOverrun = root:FindTransform("ImgEffectOverrun")

    if
        not isPreview and
            XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Awareness) and
            XDataCenter.EquipManager.IsEquipWearingByCharacterId(equipId, characterId)
     then
        self.StartAwarenessIndex = XDataCenter.EquipManager.GetEquipSite(equipId)
        self.BtnGridGroup:SelectIndex(self.StartAwarenessIndex)
    end

    local btnIndex = self.TabIndex or childUiIndex or XUiEquipDetail.BtnTabIndex.Detail
    self.PanelTabGroup:Init(
        self.TabGroup,
        function(tabIndex)
            self:OnClickTabCallBack(tabIndex)
        end,
        btnIndex
    )
    self.PanelTabGroup:SelectIndex(btnIndex)

    -- self:InitTabBtnState()

    self.BtnStrengthenMax.CallBack = function()
        XUiManager.TipMsg(CSTextManager.GetText("EquipStrengthenMaxLevel"))
    end

    if not XDataCenter.VoteManager.IsInit() then
        XDataCenter.VoteManager.GetVoteGroupListRequest(
            function()
                self:SetPanelRole()
                self:ShowPanelRole(true)
            end
        )
    else
        self:SetPanelRole()
        self:ShowPanelRole(true)
    end
    --self.PanelAsset.gameObject:SetActiveEx(not isPreview)
    self:RegisterHelpBtn()
end

function XUiEquipDetail:OnEnable()
    if not self.IsPreview and XDataCenter.EquipManager.IsMaxLevelAndBreakthrough(self.EquipId) and
        self.TabIndex == XUiEquipDetail.BtnTabIndex.Strengthen
    then
        self.PanelTabGroup:SelectIndex(XUiEquipDetail.BtnTabIndex.Detail)
    end

    self:InitClassifyPanel()

    ----刷新强化/突破界面
    if self.TabIndex == XUiEquipDetail.BtnTabIndex.Strengthen then
        if XDataCenter.EquipManager.CanBreakThrough(self.EquipId) then
            XMVCA:GetAgency(ModuleId.XEquip):TipEquipOperation(self.EquipId, nil, nil, true)
        end
    end
    self:UpdateOverrunSceneEffect()
end

function XUiEquipDetail:OnDestroy()
    self.PanelWeaponPlane.gameObject:SetActiveEx(true)
    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
        self.Resource = nil
    end
end

function XUiEquipDetail:OnReleaseInst()
    return self.TabIndex
end

function XUiEquipDetail:OnResume(value)
    self.TabIndex = value
end

function XUiEquipDetail:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY,
        XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY,
        XEventId.EVENT_EQUIP_CAN_BREAKTHROUGH_TIP_CLOSE,
        XEventId.EVENT_EQUIP_RECYCLE_NOTIFY,
        XEventId.EVENT_EQUIP_OVERRUN_CHANGE_NOTYFY,
    }
end

function XUiEquipDetail:OnNotify(evt, ...)
    local args = {...}
    if self.IsPreview then
        return
    end

    if evt == XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY then
        local equipId = args[1]
        if equipId ~= self.EquipId then
            return
        end
        if
            XDataCenter.EquipManager.IsReachBreakthroughLevel(equipId) and
                XDataCenter.EquipManager.IsMaxBreakthrough(equipId)
         then
            self.PanelTabGroup:SelectIndex(XUiEquipDetail.BtnTabIndex.Detail)
            self:UpdateStrengthenBtn()
            return
        end
    elseif evt == XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY then
        local equipId = args[1]
        if equipId ~= self.EquipId then
            return
        end
        self:UpdateStrengthenBtn()
        self:InitClassifyPanel()
    elseif evt == XEventId.EVENT_EQUIP_CAN_BREAKTHROUGH_TIP_CLOSE then
        local equipId = args[1]
        if equipId ~= self.EquipId then
            return
        end
        if not equipId then
            return
        end
        self:UpdateStrengthenBtn()
        OpenChildUiByName(self, "UiEquipBreakThrough", self.EquipId, self)
    elseif evt == XEventId.EVENT_EQUIP_RECYCLE_NOTIFY then
        self:Close()
    elseif evt == XEventId.EVENT_EQUIP_OVERRUN_CHANGE_NOTYFY then
        self:UpdateBtnOverrunRed()
    end
end

function XUiEquipDetail:InitClassifyPanel()
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Weapon) then
        local breakthroughTimes =
            not self.IsPreview and XDataCenter.EquipManager.GetBreakthroughTimes(self.EquipId) or 0
        local resonanceCount = not self.IsPreview and XDataCenter.EquipManager.GetResonanceCount(self.EquipId) or 0
        local modelConfig =
            XDataCenter.EquipManager.GetWeaponModelCfg(self.TemplateId, self.Name, breakthroughTimes, resonanceCount)
        if modelConfig then
            XModelManager.LoadWeaponModel(
                modelConfig.ModelId,
                self.PanelWeapon,
                modelConfig.TransformConfig,
                self.Name,
                nil,
                {gameObject = self.GameObject, usage = XEquipConfig.WeaponUsage.Show, IsDragRotation = true, AntiClockwise = true},
                self.PanelDrag
            )
        end
        self.PanelWeapon.gameObject:SetActiveEx(true)
        self.ImgLihuiMask.gameObject:SetActiveEx(false)
    elseif XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Awareness) then
        local breakthroughTimes =
            not self.IsPreview and XDataCenter.EquipManager.GetBreakthroughTimes(self.EquipId) or 0

        local resource =
            CS.XResourceManager.Load(XDataCenter.EquipManager.GetEquipLiHuiPath(self.TemplateId, breakthroughTimes))
        local texture = resource.Asset
        self.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)
        if self.Resource then
            CS.XResourceManager.Unload(self.Resource)
        end
        self.Resource = resource
        XScheduleManager.ScheduleOnce(
            function()
                self.FxUiLihuiChuxian01.gameObject:SetActiveEx(true)
            end,
            500
        )

        self.PanelWeapon.gameObject:SetActiveEx(false)
    end
end

function XUiEquipDetail:InitTabBtnState()
    if self.IsPreview then
        self.PanelTabGroup.gameObject:SetActiveEx(false)
        return
    end

    self.BtnStrengthen.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.EquipStrengthen))
    self.BtnResonance.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.EquipResonance) and
        XDataCenter.EquipManager.CanResonanceByTemplateId(self.TemplateId))

    self.BtnOverclocking.gameObject:SetActiveEx(not XDataCenter.EquipManager.IsWeapon(self.EquipId) and XDataCenter.EquipManager.CheckEquipStarCanAwake(self.EquipId))
    self.BtnOverclocking:SetDisable(not CheckCanAwake(self.EquipId))

    self.BtnStrengthen:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipStrengthen))
    self.BtnResonance:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipResonance))

    local canOverrun = XEquipConfig.CanOverrunByTemplateId(self.TemplateId)
    self.BtnOverrun.gameObject:SetActiveEx(canOverrun)
    if canOverrun then
        self.BtnOverrun:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun))
        self:UpdateBtnOverrunRed()
        XDataCenter.EquipManager.CheckOverrunGuide(self.EquipId)
    end

    local btn = self.TabGroup[self.TabIndex]
    if btn then
        btn:SetButtonState(CS.UiButtonState.Select)
    end
    self:UpdateStrengthenBtn()
end

function XUiEquipDetail:UpdateStrengthenBtn()
    if self.IsPreview then
        return
    end
    local equipId = self.EquipId

    if XDataCenter.EquipManager.CanBreakThrough(equipId) then
        self.BtnStrengthen:SetNameByGroup(0, CSTextManager.GetText("EquipBreakthroughBtnTxt1"))
        self.BtnStrengthen:SetNameByGroup(1, CSTextManager.GetText("EquipBreakthroughBtnTxt2"))
    else
        self.BtnStrengthen:SetNameByGroup(0, CSTextManager.GetText("EquipStrengthenBtnTxt1"))
        self.BtnStrengthen:SetNameByGroup(1, CSTextManager.GetText("EquipStrengthenBtnTxt2"))
    end

    local isMaxLevel = XDataCenter.EquipManager.IsMaxLevelAndBreakthrough(equipId)
    self.BtnStrengthen.gameObject:SetActiveEx(not isMaxLevel)
    self.BtnStrengthenMax.gameObject:SetActiveEx(isMaxLevel)
end

---=============
 --@desc 刷新强化/突破界面
---=============
function XUiEquipDetail:UpdateStrengthenPanel()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipStrengthen) then
        return
    end

    if XDataCenter.EquipManager.CanBreakThrough(self.EquipId) then
        OpenChildUiByName(self, "UiEquipBreakThrough", self.EquipId, self)
    else
        OpenChildUiByName(self, "UiEquipStrengthen", self.EquipId, self)
    end
    self:ShowPanelRole(false)
    self.ImgLihuiMask.gameObject:SetActiveEx(true)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiEquipDetail:InitAutoScript()
    self:AutoAddListener()
end

function XUiEquipDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
    self:RegisterAwarenessSwitch()
end
-- auto
function XUiEquipDetail:OnBtnBackClick()
    if XLuaUiManager.IsUiShow("UiEquipResonanceSelect") or XLuaUiManager.IsUiShow("UiEquipResonanceAwake") then
        OpenChildUiByName(self, self.CurChildName, self.EquipId, self)
        self:InitTabBtnState()
        -- self:UpdateStrengthenBtn()
    else
        self:Close()
    end
end

function XUiEquipDetail:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiEquipDetail:OnClickTabCallBack(tabIndex)
    self:ShowSwitchPanel(false)
    if tabIndex == XUiEquipDetail.BtnTabIndex.Detail then
        OpenChildUiByName(self, "UiEquipDetailChild", self.EquipId, self.IsPreview, self.OpenUiType)
        self.ChildUiEquipDetailChild.RefreshData(self.ChildUiEquipDetailChild, self.EquipId, self.IsPreview)
        self.ImgLihuiMask.gameObject:SetActiveEx(false)
        self:ShowPanelRole(true)
        if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Awareness) then
            self:ShowSwitchPanel(true)
        end
    elseif tabIndex == XUiEquipDetail.BtnTabIndex.Strengthen then
        self:UpdateStrengthenPanel()
    elseif tabIndex == XUiEquipDetail.BtnTabIndex.Resonance then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipResonance) then
            return
        end
        OpenChildUiByName(self, "UiEquipResonanceSkill", self.EquipId, self)
        self.ImgLihuiMask.gameObject:SetActiveEx(false)
        self:ShowPanelRole(false)
        --v1.28-如果装备设置意识位置按钮组显示
        if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Awareness) then
            self:ShowSwitchPanel(true)
        end
    elseif tabIndex == XUiEquipDetail.BtnTabIndex.Overclocking then
        self:ShowSwitchPanel(true)
        if not CheckCanAwake(self.EquipId) then
            XUiManager.TipError(CS.XTextManager.GetText("SuperAwareness"))
            return
        end
        OpenChildUiByName(self, "UiExhibitionOverclocking", self.EquipId, self)
    elseif tabIndex == XUiEquipDetail.BtnTabIndex.Overrun then
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun) then 
            local tips = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.EquipOverrun)
            XUiManager.TipError(tips)
            return
        end
        OpenChildUiByName(self, "UiEquipOverrun", self.EquipId, self)
        self:SaveEnterOverrunRedData()
        self:UpdateBtnOverrunRed()
    end

    self.TabIndex = tabIndex
    self:RefreshNumberBtn()
    self:InitTabBtnState()
end

function XUiEquipDetail:RegisterHelpBtn()
    local isClassifyEqual =
        XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Weapon)
    local keyStr = isClassifyEqual and "EquipWeapon" or "EquipAwareness"
    self:BindHelpBtn(self.BtnHelp, keyStr)
end

function XUiEquipDetail:SetPanelRole()
    -- 预览才显示
    if XArrangeConfigs.GetType(self.TemplateId) == XArrangeConfigs.Types.Weapon and self.IsPreview then
        local weaponUsers = XDataCenter.EquipManager.GetWeaponUserTemplateIds(self.TemplateId)
        for _, v in pairs(weaponUsers) do
            local go = CS.UnityEngine.Object.Instantiate(self.PanelText, self.PaneContent)
            local tmpObj = {}
            tmpObj.Transform = go.transform
            tmpObj.GameObject = go.gameObject
            XTool.InitUiObject(tmpObj)
            tmpObj.Text.text = v.Name .. "-" .. v.TradeName
            self:CheckShowRoleTag(v.Id, tmpObj)
            tmpObj.GameObject:SetActiveEx(true)
        end

        self.IsPanelRoleCanShow = weaponUsers and #weaponUsers > 0
    end
end

function XUiEquipDetail:ShowPanelRole(IsShow)
    if XArrangeConfigs.GetType(self.TemplateId) == XArrangeConfigs.Types.Weapon and self.IsPreview then
        self.PanelRole.gameObject:SetActiveEx(IsShow and self.IsPanelRoleCanShow)
    else
        self.PanelRole.gameObject:SetActiveEx(false)
    end
end

function XUiEquipDetail:CheckShowRoleTag(Id, obj)
    local IsShow = false
    local tabMap = XMVCA.XCharacter:GetRecommendTabMap(Id, XEnumConst.CHARACTER.RecommendType.Equip)
    for _, v in pairs(tabMap or {}) do
        if v.GroupId then
            local voteIds = XDataCenter.VoteManager.GetVoteIdListByGroupId(v.GroupId)
            for _, v2 in pairs(voteIds or {}) do
                local template = XMVCA.XEquip:GetCharDetailEquipTemplate(v2)
                if template.EquipRecomend == self.TemplateId then
                    IsShow = true
                    break
                end
            end
        end
        if IsShow then
            break
        end
    end
    obj.Image.gameObject:SetActiveEx(IsShow)
end

function XUiEquipDetail:RegisterAwarenessSwitch()
    self.BtnLeft.CallBack = function()
        self:SelectAwarenessSwitch(_SELECTTYPE.Left, self.SelectAwarenessIndex)
    end
    self.BtnRight.CallBack = function()
        self:SelectAwarenessSwitch(_SELECTTYPE.Right, self.SelectAwarenessIndex)
    end
    local btns = {}
    for equipSite = 1, XEquipConfig.EquipSite.Awareness.Six do
        table.insert(btns, self["BtnNumber" .. equipSite])
    end

    self.BtnGridGroup:Init(
        btns,
        function(index)
            if self.SelectAwarenessIndex == index then
                return
            end
            
            if self.TabIndex == XUiEquipDetail.BtnTabIndex.Overclocking then
                -- 装备可否超频
                local eqpuiId = XDataCenter.EquipManager.GetWearingEquipIdBySite(self.CharacterId, index)
                if not CheckCanAwake(eqpuiId) then
                    return
                end
            else
                -- 装备可否共鸣过滤
                if not self:CheckIsInAndCanResonance(index) then
                    return
                end
            end

            self:RefreshAwarenessSelect(index)
            self:UpdateStrengthenBtn()
        end
    )
end

function XUiEquipDetail:SelectAwarenessSwitch(type, selectIndex)
    local index = selectIndex
    if _SELECTTYPE.Left == type then
        if index > _SELECTBOARD.LeftBoard then
            if self:CheckIsInAndCanResonance(index - 1) then
                self:RefreshAwarenessSelect(index - 1)
            else
                self:SelectAwarenessSwitch(type, index - 1)
            end
        end
    else
        if index < _SELECTBOARD.RightBoard then
            if self:CheckIsInAndCanResonance(index + 1) then
                self:RefreshAwarenessSelect(index + 1)
            else
                self:SelectAwarenessSwitch(type, index + 1)
            end
        end
    end
end

function XUiEquipDetail:RefreshAwarenessSelect(equipSite)
    if not XDataCenter.EquipManager.GetWearingEquipIdBySite(self.CharacterId, equipSite) then
        return
    end
    self.EquipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(self.CharacterId, equipSite)
    self.SelectAwarenessIndex = equipSite
    self.TemplateId = self.isPreview and self.EquipId or XDataCenter.EquipManager.GetEquipTemplateId(self.EquipId)
    self:InitTabBtnState()
    -- self:UpdateStrengthenBtn()
    self:RefreshNumberBtn()
    self:RefreshSwitchBtnShow()
    self:InitClassifyPanel()
    if XLuaUiManager.IsUiShow("UiEquipDetailChild") then
        self.ChildUiEquipDetailChild.RefreshData(self.ChildUiEquipDetailChild, self.EquipId, self.IsPreview)
    end
    --v1.28-如果处于共鸣Ui刷新界面数据
    if XLuaUiManager.IsUiShow("UiEquipResonanceSkill") then
        self.ChildUiEquipResonanceSkill.RefreshData(self.ChildUiEquipResonanceSkill, self.EquipId)
    end
    --v1.28-如果处于共鸣内Ui切换意识则切换共鸣界面
    if XLuaUiManager.IsUiShow("UiEquipResonanceSelect") then
        OpenChildUiByName(self, "UiEquipResonanceSkill", self.EquipId, self)
    end

    if XLuaUiManager.IsUiShow("UiExhibitionOverclocking") then
        self.ChildUiExhibitionOverclocking:RefreshData(self.EquipId)
    end

    if XLuaUiManager.IsUiShow("UiEquipResonanceAwake") then
        OpenChildUiByName(self, "UiExhibitionOverclocking", self.EquipId, self)
    end
end

function XUiEquipDetail:ShowSwitchPanel(value)
    self.PanelTab.gameObject:SetActiveEx(value and self.CharacterId and (XDataCenter.EquipManager.GetCharacterWearingAwarenessIdCount(self.CharacterId) > 1) 
        and XDataCenter.EquipManager.IsEquipWearingByCharacterId(self.EquipId, self.CharacterId)
    )
end

function XUiEquipDetail:RefreshSwitchBtnShow() --切换按钮的表现
    local canShowBtnLeft = false
    local canShowBtnRight = false
    for i = _SELECTBOARD.LeftBoard, self.SelectAwarenessIndex - 1 do
        if XDataCenter.EquipManager.GetWearingEquipIdBySite(self.CharacterId, i) then
            canShowBtnLeft = true
            break
        end
    end
    for i = self.SelectAwarenessIndex + 1, _SELECTBOARD.RightBoard do
        if XDataCenter.EquipManager.GetWearingEquipIdBySite(self.CharacterId, i) then
            canShowBtnRight = true
            break
        end
    end
    self.BtnLeft.gameObject:SetActiveEx(canShowBtnLeft)
    self.BtnRight.gameObject:SetActiveEx(canShowBtnRight)
end

function XUiEquipDetail:RefreshNumberBtn() --为了兼容switch的按钮需要
    if self.TabIndex == XUiEquipDetail.BtnTabIndex.Overclocking then
        for i = 1, XEquipConfig.EquipSite.Awareness.Six do
            local eqpuiId = XDataCenter.EquipManager.GetWearingEquipIdBySite(self.CharacterId, i)
            if CheckCanAwake(eqpuiId) then
                local state = i == self.SelectAwarenessIndex and CS.UiButtonState.Select or CS.UiButtonState.Normal
                self["BtnNumber" .. i]:SetButtonState(state)
            else
                self["BtnNumber" .. i]:SetButtonState(CS.UiButtonState.Disable)
            end
        end
    else
        for i = 1, XEquipConfig.EquipSite.Awareness.Six do
            if self:CheckIsInAndCanResonance(i) then
                local state = i == self.SelectAwarenessIndex and CS.UiButtonState.Select or CS.UiButtonState.Normal
                self["BtnNumber" .. i]:SetButtonState(state)
            else
                self["BtnNumber" .. i]:SetButtonState(CS.UiButtonState.Disable)
            end
        end
    end
end

--v1.28-快捷选择兼容共鸣和详情页签判断
function XUiEquipDetail:CheckIsInAndCanResonance(equipSite)
    local equipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(self.CharacterId, equipSite)
    return equipId and (self.TabIndex ~= XUiEquipDetail.BtnTabIndex.Resonance or 
           self.TabIndex == XUiEquipDetail.BtnTabIndex.Resonance and XDataCenter.EquipManager.CanResonance(equipId))
end

-- 刷新超限按钮红点
function XUiEquipDetail:UpdateBtnOverrunRed()
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

function XUiEquipDetail:GetEnterOverrunSaveKey()
    return "XUiEquipDetail:GetEnterOverrunSaveKey()  XPlayer.Id" .. tostring(XPlayer.Id) 
end

-- 保存进入过超限界面的红点数据
function XUiEquipDetail:SaveEnterOverrunRedData()
    local saveKey = self:GetEnterOverrunSaveKey()
    XSaveTool.SaveData(saveKey, true)
end

-- 刷新超限场景特效
function XUiEquipDetail:UpdateOverrunSceneEffect()
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
    local deregulateUICfg = XEquipConfig.GetWeaponDeregulateUICfg(level)
    if deregulateUICfg.SceneLoopEffectPath then
        self.ImgEffectOverrun:LoadPrefab(deregulateUICfg.SceneLoopEffectPath)
    end
end

-- 播放超限升级特效
function XUiEquipDetail:PlayOverrunLevelUpEffect()
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
    local deregulateUICfg = XEquipConfig.GetWeaponDeregulateUICfg(level)
    if deregulateUICfg.SceneStartEffectPath then
        self.ImgEffectOverrun:LoadPrefab(deregulateUICfg.SceneStartEffectPath)
    end
end