--成员列表装备详情
local XUiSimulatedCombatEquipDetail = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatEquipDetail")
local CSTextManager = CS.XTextManager
function XUiSimulatedCombatEquipDetail:OnAwake()
    self:InitAutoScript()
    XUiSimulatedCombatEquipDetail.BtnTabIndex = XEquipConfig.EquipDetailBtnTabIndex
    self.PanelAsset.gameObject:SetActiveEx(false)
end

--参数isPreview为true时是装备详情预览，传templateId进来
--characterId只有需要判断武器共鸣特效时才传
function XUiSimulatedCombatEquipDetail:OnStart(templateId, breakthroughTimes, level)
    self.TemplateId = templateId
    self.BreakThroughTime = breakthroughTimes
    self.Level = level
    local sceneRoot = self.UiSceneInfo.Transform
    local root = self.UiModelGo.transform
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.PanelWeaponPlane = sceneRoot:FindTransform("Plane")
    self.PanelWeaponPlane.gameObject:SetActiveEx(false)
    
    self:InitTabBtnState()
    
    self.BtnStrengthenMax.CallBack = function()
        XUiManager.TipMsg(CSTextManager.GetText("EquipStrengthenMaxLevel"))
    end
    self:ShowPanelRole(true)
    self:OpenOneChildUi("UiSimulatedCombatEquipDetailChild", self.TemplateId, self.BreakThroughTime, self.Level)
    self:RegisterHelpBtn()
end

function XUiSimulatedCombatEquipDetail:OnEnable()
    self:InitClassifyPanel()
end

function XUiSimulatedCombatEquipDetail:OnDestroy()
    self.PanelWeaponPlane.gameObject:SetActiveEx(true)
    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
        self.Resource = nil
    end
end

function XUiSimulatedCombatEquipDetail:InitClassifyPanel()
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Weapon) then
        local resonanceCount =  0
        local modelConfig = XDataCenter.EquipManager.GetWeaponModelCfg(self.TemplateId, "UiEquipDetail", self.BreakThroughTime, resonanceCount)
        if modelConfig then
            XModelManager.LoadWeaponModel(modelConfig.ModelId, self.PanelWeapon, modelConfig.TransformConfig, "UiEquipDetail", nil, { gameObject = self.GameObject })
        end
        self.PanelWeapon.gameObject:SetActiveEx(true)
        self.ImgLihuiMask.gameObject:SetActiveEx(false)
    elseif XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Awareness) then
        local resource = CS.XResourceManager.Load(XDataCenter.EquipManager.GetEquipLiHuiPath(self.TemplateId, self.BreakThroughTime))
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

function XUiSimulatedCombatEquipDetail:InitTabBtnState()
    self.PanelTabGroup.gameObject:SetActiveEx(false)
end

function XUiSimulatedCombatEquipDetail:InitAutoScript()
    self:AutoAddListener()
end

function XUiSimulatedCombatEquipDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
end

function XUiSimulatedCombatEquipDetail:OnBtnBackClick()
    self:Close()
end

function XUiSimulatedCombatEquipDetail:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiSimulatedCombatEquipDetail:RegisterHelpBtn()
    --local isClassifyEqual = XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Weapon)
    --local keyStr = isClassifyEqual and "EquipWeapon" or "EquipAwareness"
    self:BindHelpBtn(self.BtnHelp, "SimulatedCombat")
end

function XUiSimulatedCombatEquipDetail:SetPanelRole()
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

function XUiSimulatedCombatEquipDetail:ShowPanelRole(IsShow)
    if XArrangeConfigs.GetType(self.TemplateId) == XArrangeConfigs.Types.Weapon and self.IsPreview then
        self.PanelRole.gameObject:SetActiveEx(IsShow and self.IsPanelRoleCanShow)
    else
        self.PanelRole.gameObject:SetActiveEx(false)
    end
end

function XUiSimulatedCombatEquipDetail:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET }
end

function XUiSimulatedCombatEquipDetail:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.Expedition then return end
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
    end
end