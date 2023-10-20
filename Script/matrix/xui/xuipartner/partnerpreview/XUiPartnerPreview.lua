local XUiPartnerPreview = XLuaUiManager.Register(XLuaUi, "UiPartnerPreview")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local CSUnityEngineGameObject = CS.UnityEngine.GameObject
function XUiPartnerPreview:OnEnable()

end

function XUiPartnerPreview:OnDisable()
    self.RoleModelPanel:HideAllEffects()
end

function XUiPartnerPreview:OnStart(data)
    self.Data = data
    if not self.Data then
        return
    end

    self.ModelEffect = {}
    self.CurPartnerState = XPartnerConfigs.PartnerState.Combat
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:Init()

end

function XUiPartnerPreview:Init()
    self.MosterEffects = {}
    self:InitScene3DRoot()
    self:SetButtonCallBack()
    self:UpdateRoleModel(self.Data:GetCombatModel(), self.Data, true)
    self:UpdateCamera()
    self:UpdatePartnerInfo()
end

function XUiPartnerPreview:InitScene3DRoot()
    local root = self.UiModelGo.transform

    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")

    self.CameraFar = {
        [XPartnerConfigs.CameraType.Standby] = root:FindTransform("UiCamFarStandby"),
        [XPartnerConfigs.CameraType.Combat] = root:FindTransform("UiCamFarCombat"),
    }
    self.CameraNear = {
        [XPartnerConfigs.CameraType.Standby] = root:FindTransform("UiCamNearStandby"),
        [XPartnerConfigs.CameraType.Combat] = root:FindTransform("UiCamNearCombat"),
    }

    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiPartnerPreview:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnChange.CallBack = function()
        self:ChangePartnerState()
    end
end

function XUiPartnerPreview:DoPartnerStateChange(state)
    if state == self.CurPartnerState then
        return
    end

    local partner = self.Data

    XLuaUiManager.SetMask(true)
    local closeMask = function()
        XLuaUiManager.SetMask(false)
    end

    if self:IsPartnerStandby() then

        local voiceId = partner:GetSToCVoice()
        if voiceId and voiceId > 0 then
            XSoundManager.PlaySoundByType(voiceId, XSoundManager.SoundType.Sound)
        end

        self.CurPartnerState = state
        self:UpdateCamera()
        self.RoleModelPanel:LoadEffect(partner:GetSToCEffect(), "ModelOffEffect", true, true)
        self:PlayPartnerAnima(partner:GetSToCAnime(), true, function()
            self:UpdateRoleModel(partner:GetCombatModel(), partner, false)
            self.RoleModelPanel:LoadEffect(partner:GetCombatBornEffect(), "ModelOnEffect", true, true)
            self:PlayPartnerAnima(partner:GetCombatBornAnime(), true, closeMask)
        end)

    elseif self:IsPartnerCombat() then

        local voiceId = partner:GetCToSVoice()
        if voiceId and voiceId > 0 then
            XSoundManager.PlaySoundByType(voiceId, XSoundManager.SoundType.Sound)
        end
        self.RoleModelPanel:LoadEffect(partner:GetCToSEffect(), "ModelOnEffect", true, true)

        self:PlayPartnerAnima(partner:GetCToSAnime(), true, function()
            self.CurPartnerState = state
            self:UpdateCamera()
            self:UpdateRoleModel(partner:GetStandbyModel(), partner, false)
            self.RoleModelPanel:LoadEffect(partner:GetStandbyBornEffect(), "ModelOffEffect", true, true)
            self:PlayPartnerAnima(partner:GetStandbyBornAnime(), true, closeMask)
        end)

    else
        closeMask()
    end
end

function XUiPartnerPreview:PlayPartnerAnima(animaName, fromBegin, callBack)
    local IsCanPlay = self.RoleModelPanel:PlayAnima(animaName, fromBegin, callBack)
    if not IsCanPlay then
        if callBack then callBack() end
    end
end

--更新模型
function XUiPartnerPreview:UpdateRoleModel(modelId, partner, IsShowEffect)
    self.RoleModelPanel:UpdatePartnerModel(modelId, XModelManager.MODEL_UINAME.XUiPartnerMain, nil, function(model)
        self.PanelDrag.Target = model.transform
        if IsShowEffect then
            self.ImgEffectHuanren.gameObject:SetActiveEx(false)
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        end
    end, false, true)

end

function XUiPartnerPreview:SetCameraType(type)
    for k, _ in pairs(self.CameraFar) do
        self.CameraFar[k].gameObject:SetActiveEx(k == type)
    end

    for k, _ in pairs(self.CameraNear) do
        self.CameraNear[k].gameObject:SetActiveEx(k == type)
    end
end

function XUiPartnerPreview:UpdateCamera()
    if self:IsPartnerCombat() then
        self:SetCameraType(XPartnerConfigs.CameraType.Combat)
    elseif self:IsPartnerStandby() then
        self:SetCameraType(XPartnerConfigs.CameraType.Standby)
    end
end

function XUiPartnerPreview:UpdatePartnerInfo()
    local qualityIcon = XMVCA.XCharacter:GetCharacterQualityIcon(self.Data:GetInitQuality())

    self.TxtPartnerMainName.text = self.Data:GetOriginalName()
    self.RawQuality:SetRawImage(qualityIcon)
    self.TxtAbility.text = self.Data:GetAbility()
    self.TxtDesc.text = self.Data:GetDesc()

    local strElement = ""
    for index, element in pairs(self.Data:GetRecommendElement() or {}) do
        if element > 0 then
            local elementConfig = XCharacterConfigs.GetCharElement(element)
            local strFormat = index > 1 and "%s, %s" or "%s%s"
            strElement = string.format(strFormat, strElement, elementConfig.ElementName)
        end
    end
    self.TxtElement.text = strElement
    self.TxtElement.gameObject:SetActiveEx(not string.IsNilOrEmpty(strElement))
end

function XUiPartnerPreview:IsPartnerStandby()
    return self.CurPartnerState == XPartnerConfigs.PartnerState.Standby
end

function XUiPartnerPreview:IsPartnerCombat()
    return self.CurPartnerState == XPartnerConfigs.PartnerState.Combat
end

function XUiPartnerPreview:OnBtnBackClick()
    self:Close()
end

function XUiPartnerPreview:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPartnerPreview:ChangePartnerState()
    if self:IsPartnerStandby() then
        self:DoPartnerStateChange(XPartnerConfigs.PartnerState.Combat)
    elseif self:IsPartnerCombat() then
        self:DoPartnerStateChange(XPartnerConfigs.PartnerState.Standby)
    end
end