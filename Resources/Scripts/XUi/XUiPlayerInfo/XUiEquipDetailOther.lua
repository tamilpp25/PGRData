local XUiEquipDetailOther = XLuaUiManager.Register(XLuaUi, "UiEquipDetailOther")

function XUiEquipDetailOther:OnAwake()
    self:InitAutoScript()
end

-- equip : XEquip | XEquipViewModel
-- character : XCharacter | XCharacterViewModel
function XUiEquipDetailOther:OnStart(equip, character)
    self.Equip = equip
    self.Character = character
    self.EquipId = equip.Id
    self.CharacterId = character.Id
    self.TemplateId = equip.TemplateId

    local sceneRoot = self.UiSceneInfo.Transform
    local root = self.UiModelGo.transform
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.PanelWeaponPlane = sceneRoot:FindTransform("Plane")
    self.PanelWeaponPlane.gameObject:SetActiveEx(false)
end

function XUiEquipDetailOther:OnEnable()
    self:InitClassifyPanel()

    self:OpenOneChildUi("UiEquipDetailChildOther", self.Equip, self.Character)
    self.ImgLihuiMask.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.PanelTabGroup.gameObject:SetActiveEx(false)
    self.PanelRole.gameObject:SetActiveEx(false)
    self.PanelAsset.gameObject:SetActiveEx(false)
end

function XUiEquipDetailOther:OnDestroy()
    self.PanelWeaponPlane.gameObject:SetActiveEx(true)
    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
        self.Resource = nil
    end
end

function XUiEquipDetailOther:InitClassifyPanel()
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Weapon) then
        local breakthroughTimes = self.Equip.Breakthrough
        local resonanceCount =  self.Equip.ResonanceInfo and (self.Equip.ResonanceInfo.Count or XTool.GetTableCount(self.Equip.ResonanceInfo)) or 0
        local modelConfig = XDataCenter.EquipManager.GetWeaponModelCfg(self.TemplateId, "UiEquipDetail", breakthroughTimes, resonanceCount)

        if modelConfig then
            XModelManager.LoadWeaponModel(modelConfig.ModelId, self.PanelWeapon, modelConfig.TransformConfig, "UiEquipDetail", nil, { gameObject = self.GameObject })
        end

        self.PanelWeapon.gameObject:SetActiveEx(true)
        self.ImgLihuiMask.gameObject:SetActiveEx(false)
    elseif XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Awareness) then
        local breakthroughTimes = XDataCenter.EquipManager.GetBreakthroughTimes(self.EquipId)

        local resource = CS.XResourceManager.Load(XDataCenter.EquipManager.GetEquipLiHuiPath(self.TemplateId, breakthroughTimes))
        local texture = resource.Asset
        self.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)
        if self.Resource then
            CS.XResourceManager.Unload(self.Resource)
        end
        self.Resource = resource
        XScheduleManager.ScheduleOnce(function()
            self.FxUiLihuiChuxian01.gameObject:SetActiveEx(true)
        end,  500)

        self.PanelWeapon.gameObject:SetActiveEx(false)
    end
end

function XUiEquipDetailOther:InitAutoScript()
    self:AutoAddListener()
end

function XUiEquipDetailOther:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
end

function XUiEquipDetailOther:OnBtnBackClick()
    self:Close()
end

function XUiEquipDetailOther:OnBtnMainClick()
    XLuaUiManager.RunMain()
end