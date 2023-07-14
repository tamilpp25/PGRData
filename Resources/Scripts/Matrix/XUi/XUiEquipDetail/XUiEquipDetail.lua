local CSTextManager = CS.XTextManager

local XUiEquipDetail = XLuaUiManager.Register(XLuaUi, "UiEquipDetail")

function XUiEquipDetail:OnAwake()
    self:InitAutoScript()

    XUiEquipDetail.BtnTabIndex = XEquipConfig.EquipDetailBtnTabIndex

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
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

    self:InitTabBtnState()
    self:UpdateStrengthenBtn()

    local btnIndex = self.TabIndex or childUiIndex or XUiEquipDetail.BtnTabIndex.Detail
    self.TabGroup = {
        self.BtnDetail,
        self.BtnStrengthen,
        self.BtnResonance,
    }
    self.PanelTabGroup:Init(self.TabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end, btnIndex)
    self.PanelTabGroup:SelectIndex(btnIndex)

    self.BtnStrengthenMax.CallBack = function()
        XUiManager.TipMsg(CSTextManager.GetText("EquipStrengthenMaxLevel"))
    end

    if not XDataCenter.VoteManager.IsInit() then
        XDataCenter.VoteManager.GetVoteGroupListRequest(function()
            self:SetPanelRole()
            self:ShowPanelRole(true)
        end)
    else
        self:SetPanelRole()
        self:ShowPanelRole(true)
    end
    --self.PanelAsset.gameObject:SetActiveEx(not isPreview)
    self:RegisterHelpBtn()
end

function XUiEquipDetail:OnEnable()
    self:InitClassifyPanel()
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
    }
end

function XUiEquipDetail:OnNotify(evt, ...)
    local args = { ... }
    if self.IsPreview then return end

    if evt == XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY then
        local equipId = args[1]
        if equipId ~= self.EquipId then return end
        if XDataCenter.EquipManager.IsReachBreakthroughLevel(equipId) and XDataCenter.EquipManager.IsMaxBreakthrough(equipId) then
            self.PanelTabGroup:SelectIndex(XUiEquipDetail.BtnTabIndex.Detail)
            self:UpdateStrengthenBtn()
            return
        end
    elseif evt == XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY then
        local equipId = args[1]
        if equipId ~= self.EquipId then return end
        self:UpdateStrengthenBtn()
        self:InitClassifyPanel()
    elseif evt == XEventId.EVENT_EQUIP_CAN_BREAKTHROUGH_TIP_CLOSE then
        local equipId = args[1]
        if equipId ~= self.EquipId then return end
        if not equipId then return end
        self:UpdateStrengthenBtn()
        self:OpenOneChildUi("UiEquipBreakThrough", self.EquipId, self)
    elseif evt == XEventId.EVENT_EQUIP_RECYCLE_NOTIFY then
        self:Close()
    end
end

function XUiEquipDetail:InitClassifyPanel()
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Weapon) then
        local breakthroughTimes = not self.IsPreview and XDataCenter.EquipManager.GetBreakthroughTimes(self.EquipId) or 0
        local resonanceCount = not self.IsPreview and XDataCenter.EquipManager.GetResonanceCount(self.EquipId) or 0
        local modelConfig = XDataCenter.EquipManager.GetWeaponModelCfg(self.TemplateId, self.Name, breakthroughTimes, resonanceCount)
        if modelConfig then
            XModelManager.LoadWeaponModel(modelConfig.ModelId, self.PanelWeapon, modelConfig.TransformConfig, self.Name, nil
            , { gameObject = self.GameObject, usage = XEquipConfig.WeaponUsage.Show })
        end
        self.PanelWeapon.gameObject:SetActiveEx(true)
        self.ImgLihuiMask.gameObject:SetActiveEx(false)
    elseif XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Awareness) then
        local breakthroughTimes = not self.IsPreview and XDataCenter.EquipManager.GetBreakthroughTimes(self.EquipId) or 0

        local resource = CS.XResourceManager.Load(XDataCenter.EquipManager.GetEquipLiHuiPath(self.TemplateId, breakthroughTimes))
        local texture = resource.Asset
        self.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)
        if self.Resource then
            CS.XResourceManager.Unload(self.Resource)
        end
        self.Resource = resource
        XScheduleManager.ScheduleOnce(function()
            self.FxUiLihuiChuxian01.gameObject:SetActiveEx(true)
        end, 500)

        self.PanelWeapon.gameObject:SetActiveEx(false)
    end
end

function XUiEquipDetail:InitTabBtnState()
    if self.IsPreview then
        self.PanelTabGroup.gameObject:SetActiveEx(false)
        return
    end

    self.BtnStrengthen.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.EquipStrengthen))
    self.BtnResonance.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.EquipResonance) and XDataCenter.EquipManager.CanResonanceByTemplateId(self.TemplateId))

    self.BtnStrengthen:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipStrengthen))
    self.BtnResonance:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipResonance))
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

    local isMaxLevel = XDataCenter.EquipManager.IsMaxBreakthrough(equipId) and XDataCenter.EquipManager.IsReachBreakthroughLevel(equipId)
    self.BtnStrengthen.gameObject:SetActiveEx(not isMaxLevel)
    self.BtnStrengthenMax.gameObject:SetActiveEx(isMaxLevel)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiEquipDetail:InitAutoScript()
    self:AutoAddListener()
end

function XUiEquipDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
end
-- auto
function XUiEquipDetail:OnBtnBackClick()
    if XLuaUiManager.IsUiShow("UiEquipResonanceSelect") or XLuaUiManager.IsUiShow("UiEquipResonanceAwake") then
        self:OpenOneChildUi("UiEquipResonanceSkill", self.EquipId, self)
    else
        self:Close()
    end
end

function XUiEquipDetail:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiEquipDetail:OnClickTabCallBack(tabIndex)
    if tabIndex == XUiEquipDetail.BtnTabIndex.Detail then
        self:OpenOneChildUi("UiEquipDetailChild", self.EquipId, self.IsPreview, self.OpenUiType)
        self.ImgLihuiMask.gameObject:SetActiveEx(false)
        self:ShowPanelRole(true)
    elseif tabIndex == XUiEquipDetail.BtnTabIndex.Strengthen then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipStrengthen) then
            return
        end

        if XDataCenter.EquipManager.CanBreakThrough(self.EquipId) then
            self:OpenOneChildUi("UiEquipBreakThrough", self.EquipId, self)
        else
            self:OpenOneChildUi("UiEquipStrengthen", self.EquipId, self)
        end
        self:ShowPanelRole(false)
        self.ImgLihuiMask.gameObject:SetActiveEx(true)
    elseif tabIndex == XUiEquipDetail.BtnTabIndex.Resonance then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipResonance) then
            return
        end

        self:OpenOneChildUi("UiEquipResonanceSkill", self.EquipId, self)
        self.ImgLihuiMask.gameObject:SetActiveEx(false)
        self:ShowPanelRole(false)
    end

    self.TabIndex = tabIndex
end

function XUiEquipDetail:RegisterHelpBtn()
    local isClassifyEqual = XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Weapon)
    local keyStr = isClassifyEqual and "EquipWeapon" or "EquipAwareness"
    self:BindHelpBtn(self.BtnHelp, keyStr)
end

function XUiEquipDetail:SetPanelRole()
    if XArrangeConfigs.GetType(self.TemplateId) == XArrangeConfigs.Types.Weapon then
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
    local tabMap = XCharacterConfigs.GetRecommendTabMap(Id, XCharacterConfigs.RecommendType.Equip)
    for _, v in pairs(tabMap or {}) do
        if v.GroupId then
            local voteIds = XDataCenter.VoteManager.GetVoteIdListByGroupId(v.GroupId)
            for _, v2 in pairs(voteIds or {}) do
                local template = XCharacterConfigs.GetCharDetailEquipTemplate(v2)
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