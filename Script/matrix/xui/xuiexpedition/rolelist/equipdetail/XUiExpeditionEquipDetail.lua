local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
--虚像地平线成员列表装备详情
local XUiExpeditionEquipDetail = XLuaUiManager.Register(XLuaUi, "UiExpeditionEquipDetail")
local CSTextManager = CS.XTextManager
function XUiExpeditionEquipDetail:OnAwake()
    self:InitAutoScript()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

--参数isPreview为true时是装备详情预览，传templateId进来
--characterId只有需要判断武器共鸣特效时才传
function XUiExpeditionEquipDetail:OnStart(templateId, breakthroughTimes, level)
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
    self:OpenOneChildUi("UiExpeditionEquipDetailChild", self.TemplateId, self.BreakThroughTime, self.Level)
    self:RegisterHelpBtn()
end

function XUiExpeditionEquipDetail:OnEnable()
    self:InitClassifyPanel()
end

function XUiExpeditionEquipDetail:OnDestroy()
    self.PanelWeaponPlane.gameObject:SetActiveEx(true)
end

function XUiExpeditionEquipDetail:InitClassifyPanel()
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    if XMVCA.XEquip:IsClassifyEqualByTemplateId(self.TemplateId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
        local resonanceCount =  0
        local modelConfig = XMVCA.XEquip:GetWeaponModelCfg(self.TemplateId, "UiEquipDetail", self.BreakThroughTime, resonanceCount)
        if modelConfig then
            XModelManager.LoadWeaponModel(modelConfig.ModelId, self.PanelWeapon, modelConfig.TransformConfig, "UiEquipDetail", nil, { gameObject = self.GameObject })
        end
        self.PanelWeapon.gameObject:SetActiveEx(true)
        self.ImgLihuiMask.gameObject:SetActiveEx(false)
    elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(self.TemplateId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
        local resPath = XMVCA.XEquip:GetEquipLiHuiPath(self.TemplateId, self.BreakThroughTime)
        self.Loader = self.Loader or self.Transform:GetLoader()
        local texture = self.Loader:Load(resPath)
        self.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)
        XScheduleManager.ScheduleOnce(function()
                self.FxUiLihuiChuxian01.gameObject:SetActiveEx(true)
            end, 500)
        self.PanelWeapon.gameObject:SetActiveEx(false)
    end
end

function XUiExpeditionEquipDetail:InitTabBtnState()
    self.PanelTabGroup.gameObject:SetActiveEx(false)
    self.PanelTab.gameObject:SetActiveEx(false)
end

function XUiExpeditionEquipDetail:InitAutoScript()
    self:AutoAddListener()
end

function XUiExpeditionEquipDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
end

function XUiExpeditionEquipDetail:OnBtnBackClick()
    self:Close()
end

function XUiExpeditionEquipDetail:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiExpeditionEquipDetail:RegisterHelpBtn()
    local isClassifyEqual = XMVCA.XEquip:IsClassifyEqualByTemplateId(self.TemplateId, XEnumConst.EQUIP.CLASSIFY.WEAPON)
    local keyStr = isClassifyEqual and "EquipWeapon" or "EquipAwareness"
    self:BindHelpBtn(self.BtnHelp, keyStr)
end

function XUiExpeditionEquipDetail:SetPanelRole()
    if XArrangeConfigs.GetType(self.TemplateId) == XArrangeConfigs.Types.Weapon then
        local weaponUsers = XMVCA.XEquip:GetWeaponUserTemplateIds(self.TemplateId)
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

function XUiExpeditionEquipDetail:ShowPanelRole(IsShow)
    if XArrangeConfigs.GetType(self.TemplateId) == XArrangeConfigs.Types.Weapon and self.IsPreview then
        self.PanelRole.gameObject:SetActiveEx(IsShow and self.IsPanelRoleCanShow)
    else
        self.PanelRole.gameObject:SetActiveEx(false)
    end
end

function XUiExpeditionEquipDetail:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET }
end

function XUiExpeditionEquipDetail:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.Expedition then return end
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
    end
end