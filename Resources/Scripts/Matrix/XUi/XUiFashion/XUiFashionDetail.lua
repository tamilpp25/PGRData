local CSXTextManagerGetText = CS.XTextManager.GetText
local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform
local CameraIndex = {
    Normal = 1,
    Near = 2,
}

local ViewType = {
    Character = 1,
    Weapon = 2,
}

local TitleName = {
    Title = {
        [ViewType.Character] = CSXTextManagerGetText("UiFashionDetailTitleCharacter"),
        [ViewType.Weapon] = CSXTextManagerGetText("UiFashionDetailTitleWeapon"),
    },
    TipTitle = {
        [ViewType.Character] = CSXTextManagerGetText("UiFashionDetailTipTitleCharacter"),
        [ViewType.Weapon] = CSXTextManagerGetText("UiFashionDetailTipTitleWeapon"),
    },
}

local XUiFashionDetail = XLuaUiManager.Register(XLuaUi, "UiFashionDetail")

function XUiFashionDetail:OnAwake()
    self:AutoAddListener()
    self.BtnLensOut.gameObject:SetActiveEx(true)
    self.BtnLensIn.gameObject:SetActiveEx(false)
    self.PanelBtnSwich.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.OnUiSceneLoadedCB = function() self:OnUiSceneLoaded() end
end

function XUiFashionDetail:OnStart(fashionId, isWeaponFashion,buyData)
    self:InitSceneRoot() --设置摄像机
    self.FashionId = fashionId
    self.IsWeaponFashion = isWeaponFashion
    self.BuyData = buyData
    self:SetDetailData()
end

function XUiFashionDetail:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    if self.IsWeaponFashion then
        self:LoadModelScene(true)
        self:UpdateWeaponModel()
    else
        self:LoadModelScene(false)
        self:UpdateCharacterModel()
    end
    self:InitBuyData()
end

function XUiFashionDetail:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiFashionDetail:OnUiSceneLoaded()
    self:SetGameObject()
end

function XUiFashionDetail:InitBuyData()
    self.BtnBuy.gameObject:SetActiveEx(false)
    if not self.BuyData then
        return
    end

    self.BtnBuy.gameObject:SetActiveEx(true)
    self.TxtHave.gameObject:SetActiveEx(self.BuyData.IsHave)
    self.BtnBuy:SetDisable(self.BuyData.IsHave, not self.BuyData.IsHave)
    self.PanelInformation.gameObject:SetActiveEx(self.BuyData.LimitText ~= nil or self.BuyData.IsHave)

    if self.BuyData.PayKeySuffix then
        self.RawImageConsume.gameObject:SetActiveEx(false)
        self.ImageYuan.gameObject:SetActiveEx(true)
        self.BtnBuy:SetName(self:GetPayAmount(self.BuyData.PayKeySuffix))
        if self.BuyData.IsHave then
            local path = CS.XGame.ClientConfig:GetString("LBBuyRiYuanIconPath1")
            self.ImageYuan:SetRawImage(path)
        else
            local path = CS.XGame.ClientConfig:GetString("LBBuyRiYuanIconPath")
            self.ImageYuan:SetRawImage(path)
        end
    else
        self.BtnBuy:SetName(self.BuyData.ItemCount)
        self.RawImageConsume.gameObject:SetActiveEx(true)
        self.ImageYuan.gameObject:SetActiveEx(false)
        self.RawImageConsume:SetRawImage(self.BuyData.ItemIcon)
    end
    
    self.TxtLimitBuy.text = self.BuyData.LimitText or ""

    self.BtnBuy.CallBack = function()
        self.BuyData.BuyCallBack()
        self:OnBtnBackClick()
    end

    --BuyData={
    --    IsHave --------是否已经拥有
    --    LimitText -------------限购提示字符串
    --    ItemIcon -------------货币Icon
    --    ItemCount-------------货币数量
    --    BuyCallBack-----------购买时调用的接口
    --    }
end

function XUiFashionDetail:GetPayAmount(PayKeySuffix)
    local key
    if Platform == RuntimePlatform.Android then
        key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), PayKeySuffix)
    else
        key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), PayKeySuffix)
    end

    local payConfig = XPayConfigs.GetPayTemplate(key)
    return payConfig and payConfig.Amount or 0
end

function XUiFashionDetail:OnSliderCharacterHightChanged()
    local pos = self.CameraNear[CameraIndex.Near].position
    self.CameraNear[CameraIndex.Near].position = CS.UnityEngine.Vector3(pos.x, 1.7 - self.SliderCharacterHight.value, pos.z)
end

--初始化摄像机
function XUiFashionDetail:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.RoleModelPanel = XUiPanelRoleModel.New(root:FindTransform("UiModelParent"), self.Name, nil, true, nil, true)
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.CameraNear = {
        [CameraIndex.Normal] = root:FindTransform("FashionCamNearMain"),
        [CameraIndex.Near] = root:FindTransform("FashionCamNearest"),
    }
end

function XUiFashionDetail:UpdateCamera(camera)
    for _, cameraIndex in pairs(CameraIndex) do
        self.CameraNear[cameraIndex].gameObject:SetActiveEx(cameraIndex == camera)
    end
end

function XUiFashionDetail:OnBtnLensOut()
    self.BtnLensOut.gameObject:SetActiveEx(false)
    self.BtnLensIn.gameObject:SetActiveEx(true)
    self:UpdateCamera(CameraIndex.Near)
end

function XUiFashionDetail:OnBtnLensIn()
    self.BtnLensOut.gameObject:SetActiveEx(true)
    self.BtnLensIn.gameObject:SetActiveEx(false)
    self:UpdateCamera(CameraIndex.Normal)
end

function XUiFashionDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterSliderChangeEvent(self, self.SliderCharacterHight, self.OnSliderCharacterHightChanged)
    self.BtnLensOut.CallBack = function() self:OnBtnLensOut() end
    self.BtnLensIn.CallBack = function() self:OnBtnLensIn() end
end

function XUiFashionDetail:SetDetailData()
    if (self.BuyData or {}).GiftRewardId then
        if self.BuyData.GiftRewardId == 0 then
            self.GridItem.gameObject:SetActiveEx(false)
            self.Title.gameObject:SetActiveEx(false)
        else
            local rewardGood = XRewardManager.GetRewardList(self.BuyData.GiftRewardId)[1]
            self.CommonGrid = XUiGridCommon.New(self, self.GridItem)
            self.CommonGrid:Refresh(rewardGood)
            self.Title.text = CS.XTextManager.GetText("SpecialFashionShopGiftTitle")
            self.BtnClick.gameObject:SetActiveEx(true)
        end
    else
        self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.FashionId)
        if self.DetailRImgIcon then
            local icon = self.GoodsShowParams.Icon
            if icon and #icon > 0 then
                self.DetailRImgIcon:SetRawImage(icon)
            end
        end
        if self.DetailImgQuality and self.GoodsShowParams.Quality then
            XUiHelper.SetQualityIcon(self, self.DetailImgQuality, self.GoodsShowParams.Quality)
        end
    end

    if self.WorldDesc then
        local worldDesc = XGoodsCommonManager.GetGoodsWorldDesc(self.FashionId)
        if worldDesc and #worldDesc then
            self.WorldDesc.text = worldDesc
        end
    end
    if self.Desc then
        local desc = XGoodsCommonManager.GetGoodsDescription(self.FashionId)
        if desc and #desc > 0 then
            self.Desc.text = desc
        end
    end
end

function XUiFashionDetail:UpdateCharacterModel()
    local template = XDataCenter.FashionManager.GetFashionTemplate(self.FashionId)
    local func = function(model)
        self.PanelDrag:GetComponent("XDrag").Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end


    self.TxtTitle.text = TitleName.Title[ViewType.Character]
    self.TxtTipTitle.text = TitleName.TipTitle[ViewType.Character]
    self.TxtFashionName.text = template.Name
    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.RoleModelPanel.GameObject:SetActiveEx(true)
    self.PanelBtnLens.gameObject:SetActiveEx(true)
    self.RoleModelPanel:UpdateCharacterResModel(template.ResourcesId, template.CharacterId, XModelManager.MODEL_UINAME.XUiFashionDetail, func)
end

function XUiFashionDetail:UpdateWeaponModel()
    local weaponFashionId = self.FashionId
    local uiName = XModelManager.MODEL_UINAME.XUiFashionDetail
    local modelConfig = XDataCenter.WeaponFashionManager.GetWeaponModelCfg(weaponFashionId, nil, uiName)
    local fashionName = XDataCenter.WeaponFashionManager.GetWeaponFashionName(weaponFashionId)

    self.TxtTitle.text = TitleName.Title[ViewType.Weapon]
    self.TxtTipTitle.text = TitleName.TipTitle[ViewType.Weapon]
    self.TxtFashionName.text = fashionName
    self.RoleModelPanel.GameObject:SetActiveEx(false)
    self.PanelWeapon.gameObject:SetActiveEx(true)
    self.PanelBtnLens.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    XModelManager.LoadWeaponModel(modelConfig.ModelId, self.PanelWeapon, modelConfig.TransformConfig, uiName, nil, { gameObject = self.GameObject })
end

function XUiFashionDetail:OnBtnBackClick()
    self:Close()
end

function XUiFashionDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFashionDetail:LoadModelScene(isDefault)
    local sceneUrl = self:GetSceneUrl(isDefault)
    local modelUrl = self:GetDefaultUiModelUrl()
    self:LoadUiScene(sceneUrl, modelUrl, self.OnUiSceneLoadedCB, false)
end

function XUiFashionDetail:GetSceneUrl(isDefault)
    if isDefault then
        return self:GetDefaultSceneUrl()
    end

    local sceneUrl = XDataCenter.FashionManager.GetFashionSceneUrl(self.FashionId)
    if sceneUrl and sceneUrl ~= "" then
        return sceneUrl
    else
        return self:GetDefaultSceneUrl()
    end
end