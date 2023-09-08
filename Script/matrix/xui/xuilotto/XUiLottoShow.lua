local XUiLottoShow = XLuaUiManager.Register(XLuaUi, "UiLottoShow")
-- local drawShowWeapon = require("XUi/XUiDraw/XUiDrawTools/XUiDrawWeapon")
local drawShowEffect = require("XUi/XUiDraw/XUiDrawTools/XUiDrawShowEffect")
local drawScene = require("XUi/XUiDraw/XUiDrawTools/XUiDrawScene")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiModelUtility = require("XUi/XUiCharacter/XUiModelUtility")

function XUiLottoShow:OnAwake()
    self:InitAutoScript()
end

function XUiLottoShow:OnStart()
    self.Animation = self.Transform:GetComponent("Animation")
    self:InitImgRewards()
end

function XUiLottoShow:SetData(rewardList, resultCb, backGround)
    self.BackGround = backGround
    self.RewardList = rewardList
    self.ResultCb = resultCb

    self:ResetState()
    self:InitTools()
    self.ShowIndex = 1
    self.PartnerIndex = 1
    self.IsOpening = false
    self.CurLight = {}
    self.PlayBoxAnim = false
    self.BtnClick.gameObject:SetActiveEx(false)
    self:InitDrawBackGround()
    XUiHelper.SetDelayPopupFirstGet(true)
end

function XUiLottoShow:OnDisable()
    self:ClearLastModel()
    self:HideAllEffect()
    XUiHelper.SetDelayPopupFirstGet()
end

function XUiLottoShow:Update()
    if self.PlayBoxAnim then
        if self.PlayableDirector.time >= self.PlayableDirector.duration - 0.1 then
            self:BoxAnimEnd()
        end
    end
end

function XUiLottoShow:InitImgRewards()
    self.ImgRewards = {}
    self.ImgRewards[XArrangeConfigs.Types.Character] = self.ImgCharacter
    self.ImgRewards[XArrangeConfigs.Types.Fashion] = self.ImgItem
    self.ImgRewards[XArrangeConfigs.Types.Item] = self.ImgItem
    self.ImgRewards[XArrangeConfigs.Types.Wafer] = self.ImgWafer
    self.ImgRewards[XArrangeConfigs.Types.Weapon] = self.ImgEquip
    self.ImgRewards[XArrangeConfigs.Types.Furniture] = self.ImgItem
    self.ImgRewards[XArrangeConfigs.Types.HeadPortrait] = self.ImgItem
    self.ImgRewards[XArrangeConfigs.Types.ChatEmoji] = self.ImgItem
    self.ImgRewards[XArrangeConfigs.Types.Partner] = self.ImgPartner
end

function XUiLottoShow:ResetState()
    self.ImgCharacter.gameObject:SetActiveEx(false)
    self.ImgItem.gameObject:SetActiveEx(false)
    self.ImgWafer.gameObject:SetActiveEx(false)
    self.ImgEquip.gameObject:SetActiveEx(false)
    self.ImageItemPack.gameObject:SetActiveEx(false)
    self.ImageWeaponPack.gameObject:SetActiveEx(false)
    self.ImageCharacterPack.gameObject:SetActiveEx(false)
    self.ImageWaferPack.gameObject:SetActiveEx(false)
    self.ImagePartnerPack.gameObject:SetActiveEx(false)
end

function XUiLottoShow:InitTools()
    --drawScene.AddObject(self.PanelWeapon, drawScene.Types.WEAPON)
    --drawShowWeapon.SetNode(self.PanelAnim, self.PanelWeapon)
    drawScene.SetActive(drawScene.Types.BOX, false)
    drawScene.SetActive(drawScene.Types.BG, false)
    XRTextureManager.SetTextureCache(self.RImgDrawCardShow)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiLottoShow:InitAutoScript()
    self:AutoAddListener()
end

function XUiLottoShow:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)
end
-- auto
function XUiLottoShow:OnBtnClickClick()
    if self.IsOpening then
        self:ShowResult()
    else
        if self.IsPartner then
            self.PartnerIndex = self.PartnerIndex + 1
            self.IsPartner = false
        end
        self:HideAllEffect()
        self:NextPack()
    end
end

function XUiLottoShow:OnBtnSkipClick()
    if self.IsPartner then
        self.PartnerIndex = self.PartnerIndex + 1
        self.IsPartner = false
    end

    self:ClearLastModel()
    self:PlayEnd()
end

function XUiLottoShow:ShowWeapon()
    drawScene.SetActive(drawScene.Types.WEAPON, true)
end

function XUiLottoShow:ShowResult()
    XUiHelper.StopAnimation(false)

    local id = self:GetRewardId(self.ShowIndex)
    local Type = self:GetRewardType(id)
    local quality = self:GetQuality(id, Type)

    local showTable = XDataCenter.DrawManager.GetDrawShow(Type)
    local skipEffect = XDrawConfigs.GetSkipEffect(showTable.DrawEffectGroupId[quality])
    self.CurPanelOpenUpEffect = self.PanelOpenUp:LoadPrefab(skipEffect)
    self.CurPanelOpenUpEffect.gameObject.name = skipEffect
    self.CurPanelOpenUpEffect.gameObject:SetActiveEx(true)

    self.Plane.gameObject:SetActiveEx(false)

    self.IsOpening = false
    self.Animation:Play(showTable.UiResultAnim)
    -- if Type == XArrangeConfigs.Types.Weapon then
    --     drawShowWeapon.PlayResultAnim()
    -- end
    self.ShowIndex = self.ShowIndex + 1
end

function XUiLottoShow:ClearLastModel()
    if self.LastCharacterModel then
        self.LastCharacterModel.gameObject:SetActiveEx(false)
        self.LastCharacterModel = nil
    end

    if self.LastWeaponModel then
        self.LastWeaponModel.gameObject:SetActiveEx(false)
        self.LastWeaponModel = nil
    end

    if self.LastPartnerModel then
        self.LastPartnerModel.gameObject:SetActiveEx(false)
        self.LastPartnerModel = nil
    end
end

function XUiLottoShow:NextPack()
    self.BtnClick.gameObject:SetActiveEx(false)
    self:ClearLastModel()
    if self.ShowIndex > #self.RewardList then
        self:PlayEnd()
        return
    end

    if self.CvInfo then
        self.CvInfo:Stop()
        self.CvInfo = nil
    end
    self.Plane.gameObject:SetActiveEx(false)
    local reward = self.RewardList[self.ShowIndex]
    local id = self:GetRewardId(self.ShowIndex)
    local Type = self:GetRewardType(id)
    local quality = self:GetQuality(id, Type)

    local soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.Normal

    if quality then
        if quality == 5 then
            soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.FiveStar
        elseif quality == 6 then
            soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.SixStar
        end
    end

    local icon
    if Type == XArrangeConfigs.Types.Weapon or
    Type == XArrangeConfigs.Types.Furniture or
    Type == XArrangeConfigs.Types.HeadPortrait or
    XDataCenter.ItemManager.IsWeaponFashion(id) then

        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
        icon = goodsShowParams.BigIcon

        if Type ~= XArrangeConfigs.Types.Weapon and not XDataCenter.ItemManager.IsWeaponFashion(id) then
            self.ImgRewards[Type]:SetRawImage(icon)
            self.BtnClick.gameObject:SetActiveEx(true)
        end
    else
        if Type == XArrangeConfigs.Types.Character then
            icon = XDataCenter.CharacterManager.GetCharHalfBodyImage(id)
            if quality < 3 then
                soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.FiveStar
            elseif quality > 2 then
                soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.SixStar
            end
        elseif Type == XArrangeConfigs.Types.Wafer then
            icon = XDataCenter.EquipManager.GetEquipLiHuiPath(id)
        elseif Type == XArrangeConfigs.Types.Item then
            icon = XDataCenter.ItemManager.GetItemBigIcon(id)
        elseif Type == XArrangeConfigs.Types.Fashion then
            icon = XDataCenter.FashionManager.GetFashionIcon(id)
        elseif Type == XArrangeConfigs.Types.ChatEmoji then
            icon = XDataCenter.ChatManager.GetEmojiIcon(id)
        elseif Type == XArrangeConfigs.Types.Partner then
            local templateIdData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
            icon = templateIdData.Icon
            if quality < 3 then
                soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.FiveStar
            elseif quality > 2 then
                soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.SixStar
            end
        end

        if Type ~= XArrangeConfigs.Types.Character and Type ~= XArrangeConfigs.Types.Fashion then
            self.ImgRewards[Type]:SetRawImage(icon)
            self.BtnClick.gameObject:SetActiveEx(true)
        end
    end
    local curShowNum = self.ShowIndex
    local showTable = XDataCenter.DrawManager.GetDrawShow(Type)
    self.IsOpening = true
    self.IsPartner = false
    XUiHelper.StopAnimation(false)
    XUiHelper.PlayAnimation(self, showTable.UiAnim, nil, function()
        self.PanelCardShowOff.gameObject:SetActiveEx(true)
        if self.GameObject.activeInHierarchy then
            if curShowNum == self.ShowIndex then
                local effect = XDrawConfigs.GetOpenUpEffect(showTable.DrawEffectGroupId[quality])
                self.CurPanelOpenUpEffect = self.PanelOpenUp.transform:Find(effect)
                if self.CurPanelOpenUpEffect then
                    self.CurPanelOpenUpEffect.gameObject:SetActiveEx(true)
                else
                    self.CurPanelOpenUpEffect = self.PanelOpenUp:LoadPrefab(effect)
                    self.CurPanelOpenUpEffect.gameObject.name = effect
                    self.CurPanelOpenUpEffect.gameObject:SetActiveEx(true)
                end
            end
            if Type == XArrangeConfigs.Types.Character then
                self:ShowCharacterModel(id, nil)
            elseif Type == XArrangeConfigs.Types.Fashion then
                self:ShowCharacterModel(nil, id)
            elseif Type == XArrangeConfigs.Types.Weapon then
                self:ShowWeaponModel(id)
            elseif XDataCenter.ItemManager.IsWeaponFashion(id) then
                self:ShowWeaponFashionModel(id)
            elseif Type == XArrangeConfigs.Types.Partner then
                self.IsPartner = true
                self:ShowPartnerModel(id)
            end
            XUiHelper.PlayAnimation(self, showTable.UiAnim .. "Item", nil, function()
                if curShowNum == self.ShowIndex then
                    self.IsOpening = false
                    self.ShowIndex = self.ShowIndex + 1
                end
            end)
        end

        CS.XAudioManager.PlaySound(soundType.Show)
    end)

    CS.XAudioManager.PlaySound(soundType.Start)

    local templeid = id
    if XArrangeConfigs.Types.Furniture == reward.RewardType then
        local cfg = XFurnitureConfigs.GetFurnitureReward(id)
        if cfg and cfg.FurnitureId then
            templeid = cfg.FurnitureId
        end
    end
    self.TxtName.text = XTypeManager.GetNameById(templeid)
    self.TxtType.text = showTable.TypeText
    self.TxtQuality.text = showTable.QualityText[quality]

    --effect
    self.PanelOpenUp.gameObject:SetActiveEx(true)
    self.PanelOpenDown.gameObject:SetActiveEx(true)

    local effect = XDrawConfigs.GetOpenDownEffect(showTable.DrawEffectGroupId[quality])
    self.CurPanelOpenDownEffect = self.PanelOpenDown.transform:Find(effect)
    if self.CurPanelOpenDownEffect then
        self.CurPanelOpenDownEffect.gameObject:SetActiveEx(true)
    else
        self.CurPanelOpenDownEffect = self.PanelOpenDown:LoadPrefab(effect)
        self.CurPanelOpenDownEffect.gameObject.name = effect
        self.CurPanelOpenDownEffect.gameObject:SetActiveEx(true)
    end

end

function XUiLottoShow:ShowWeaponFashionModel(templateId)
    local fashionId = XDataCenter.ItemManager.GetWeaponFashionId(templateId)
    local modelConfig = XDataCenter.WeaponFashionManager.GetWeaponModelCfg(fashionId, nil, self.Name)
    if modelConfig then
        XModelManager.LoadWeaponModel(modelConfig.ModelId, self.WeaponRoot, modelConfig.TransformConfig, self.Name, function(model)
            model.gameObject:SetActiveEx(true)
            self.LastWeaponModel = model
            self.BtnClick.gameObject:SetActiveEx(true)
        end, { gameObject = self.GameObject })
    end
end

function XUiLottoShow:ShowWeaponModel(templateId)
    local modelConfig = XDataCenter.EquipManager.GetWeaponModelCfg(templateId, self.Name, 0)
    if modelConfig then
        XModelManager.LoadWeaponModel(modelConfig.ModelId, self.WeaponRoot, modelConfig.TransformConfig, self.Name, function(model)
            model.gameObject:SetActiveEx(true)
            self.LastWeaponModel = model
            self.BtnClick.gameObject:SetActiveEx(true)
        end, { gameObject = self.GameObject })
    end
end

function XUiLottoShow:ShowCharacterModel(templateId, fashtionId)
    if not templateId and not fashtionId then
        return
    end

    if not self.InitRoleMode then
        self.InitRoleMode = true
        self.RoleModelPanel = XUiPanelRoleModel.New(self.CharacterRoot, self.Name, true, false, false)
    end

    local curCharacterId = templateId or XDataCenter.FashionManager.GetCharacterId(fashtionId)
    local curFashtionId = fashtionId or XMVCA.XCharacter:GetCharacterTemplate(curCharacterId).DefaultNpcFashtionId
    XDataCenter.DisplayManager.UpdateRoleModel(self.RoleModelPanel, curCharacterId, nil, curFashtionId)

    self.RoleModelPanel:UpdateCharacterModel(curCharacterId, self.CharacterRoot, XModelManager.MODEL_UINAME.XUiDrawShow, function(model)
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiDrawCard_Chouka_Name)
        model.gameObject:SetActiveEx(true)

        local animeID = XDataCenter.DrawManager.GetDrawShowCharacter(curCharacterId).AnimeID
        local voiceId = XDataCenter.DrawManager.GetDrawShowCharacter(curCharacterId).VoiceId

        if animeID then
            self.RoleModelPanel:PlayAnima(animeID)
        end

        if voiceId then
            self.CvInfo = CS.XAudioManager.PlayCv(voiceId)
        end

        self.LastCharacterModel = model
        self.BtnClick.gameObject:SetActiveEx(true)
    end, nil, curFashtionId)
end

function XUiLottoShow:HideAllEffect()
    if not XTool.UObjIsNil(self.PanelOpenUp) then
        self.PanelOpenUp.gameObject:SetActiveEx(false)
    end
    if not XTool.UObjIsNil(self.PanelOpenDown) then
        self.PanelOpenDown.gameObject:SetActiveEx(false)
    end
    if not XTool.UObjIsNil(self.PanelCardShowOff) then
        self.PanelCardShowOff.gameObject:SetActiveEx(false)
    end
    if not XTool.UObjIsNil(self.CurPanelOpenUpEffect) then
        self.CurPanelOpenUpEffect.gameObject:SetActiveEx(false)
    end
    if not XTool.UObjIsNil(self.CurPanelOpenDownEffect) then
        self.CurPanelOpenDownEffect.gameObject:SetActiveEx(false)
    end
    if not XTool.UObjIsNil(self.CurPanelCardShowOffEffect) then
        self.CurPanelCardShowOffEffect.gameObject:SetActiveEx(false)
    end
    if not XTool.UObjIsNil(self.CurLight) then
        self.CurLight.gameObject:SetActiveEx(false)
    end
    if not XTool.UObjIsNil(self.CurLightLock) then
        self.CurLightLock.gameObject:SetActiveEx(false)
    end
    if self.PartnerModelPanel then
        self.PartnerModelPanel:HideAllEffects()
    end
end

function XUiLottoShow:PlayEnd()
    XUiHelper.StopAnimation()
    self.Plane.gameObject:SetActiveEx(true)
    self.BtnClick.gameObject:SetActiveEx(true)
    drawScene.SetActive(drawScene.Types.BOX, true)
    if self.CurLight.gameObject then
        self.CurLight.gameObject:SetActiveEx(false)
    end
    if self.CurLightLock and not XTool.UObjIsNil(self.CurLightLock.gameObject) then
        self.CurLightLock.gameObject:SetActiveEx(false)
    end
    if self.CvInfo then
        self.CvInfo:Stop()
        self.CvInfo = nil
    end
    self:Close()
    self.ResultCb()
end

function XUiLottoShow:OnDestroy()
    drawScene.DestroyObject(drawScene.Types.EFFECT)
    drawScene.DestroyObject(drawScene.Types.WEAPON)
    drawScene.DestroyObject(drawScene.Types.SHOWBG)
    drawShowEffect.Dispose()
end

--wind
function XUiLottoShow:InitDrawBackGround()
    self.TxtType.text = ""
    self.TxtName.text = ""
    self.TxtQuality.text = ""
    self.PanelInfo.gameObject:GetComponent("CanvasGroup").alpha = 0

    self:PlayBoxAnimStart()
end

function XUiLottoShow:PlayBoxAnimStart()
    self.PanelOpenUp = self.BackGround.transform:Find("ModelRoot/UiNearRoot/EffectRoot/PanelOpenUp")
    self.PanelOpenDown = self.BackGround.transform:Find("ModelRoot/UiNearRoot/EffectRoot/PanelOpenDown")
    self.PanelCardShowOff = self.BackGround.transform:Find("ModelRoot/UiNearRoot/EffectRoot/PanelCardShowOff")
    self.WeaponRoot = self.BackGround.transform:Find("ModelRoot/UiNearRoot/WeaponRoot")
    self.CharacterRoot = self.BackGround.transform:Find("ModelRoot/UiNearRoot/CharacterRoot")
    self.PartnerRoot = self.BackGround.transform:Find("ModelRoot/UiNearRoot/PartnerRoot")
    self.Plane = self.BackGround.transform:Find("ModelRoot/UiFarRoot/Plane")

    local behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    if self.Update then
        behaviour.LuaUpdate = function() self:Update() end
    end
    self.PlayableDirector = self.BackGround:GetComponent("PlayableDirector")
    self.PlayableDirector:Play()
    self.PlayBoxAnim = true
    self.PanelBoxLight = self.BackGround.transform:Find("ModelRoot/UiNearRoot/PanelBox/PanelBoxLight")
    self.PanelBoxLock = self.BackGround.transform:Find("ModelRoot/UiNearRoot/PanelBox/PanelBoxLock")
    self.CurLight = self.PanelBoxLight:LoadPrefab(self:GetMaxQualityEffectName())
    self.CurLight.gameObject:SetActiveEx(true)

    if self.PanelBoxLock then
        self.CurLightLock = self.PanelBoxLock:LoadPrefab(XUiConfigs.GetComponentUrl("UiDrawOpenBoxPre"))
        self.CurLightLock.gameObject:SetActiveEx(true)
    end
end

function XUiLottoShow:BoxAnimEnd()
    self.PlayBoxAnim = false
    self:NextPack()
end

function XUiLottoShow:GetQuality(id, type)
    local quality
    local templateIdData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
    if type == XArrangeConfigs.Types.Wafer then
        quality = templateIdData.Star
    elseif type == XArrangeConfigs.Types.Weapon then
        quality = templateIdData.Star
    elseif type == XArrangeConfigs.Types.Character then
        quality = XMVCA.XCharacter:GetCharMinQuality(id)
    elseif type == XArrangeConfigs.Types.Partner then
        quality = templateIdData.Quality
    else
        quality = XTypeManager.GetQualityById(id)
    end
    return quality
end

function XUiLottoShow:GetRewardId(showIndex)
    local reward = self.RewardList[showIndex]
    local id = reward.Id and reward.Id > 0 and reward.Id or reward.TemplateId
    if reward.ConvertFrom > 0 then
        id = reward.ConvertFrom
    end
    return id
end

function XUiLottoShow:GetRewardType(id)
    local IsWeaponFashion = XDataCenter.ItemManager.IsWeaponFashion(id)
    local type = IsWeaponFashion and XArrangeConfigs.Types.WeaponFashion or XTypeManager.GetTypeById(id)
    return type
end

--获取最高品级效果，按类型取每一类最大值，最后比较大小得出最大的类型和值
function XUiLottoShow:GetMaxQualityEffectName()
    local maxByType = {}

    for k, v in pairs(XArrangeConfigs.Types) do
        local maxQuality = 0
        for i = 1, #self.RewardList do
            local id = self:GetRewardId(i)
            local type = self:GetRewardType(id)
            if type == v then
                local tempQuality = self:GetQuality(id, type)
                if tempQuality > maxQuality then
                    maxQuality = tempQuality
                end
            end
        end
        maxByType[k] = maxQuality
    end

    local maxEffectLevel = 1
    local maxEffectPath
    for k, v in pairs(XArrangeConfigs.Types) do
        if maxByType[k] > 0 then
            local showTable = XDataCenter.DrawManager.GetDrawShow(v)
            local effect = XDrawConfigs.GetOpenBoxEffect(showTable.DrawEffectGroupId[maxByType[k]])

            if tonumber(string.sub(effect, -8, -8)) > maxEffectLevel then
                maxEffectLevel = tonumber(string.sub(effect, -8, -8))
                maxEffectPath = effect
            end
        end
    end
    return maxEffectPath
end

function XUiLottoShow:SetWeaponPos(target, config)
    if not target or not config then
        return
    end
    target.transform.localPosition = CS.UnityEngine.Vector3(config.PositionX, config.PositionY, config.PositionZ)
    --检查数据 模型旋转
    target.transform.localEulerAngles = CS.UnityEngine.Vector3(config.RotationX, config.RotationY, config.RotationZ)
    --检查数据 模型大小
    target.transform.localScale = CS.UnityEngine.Vector3(
    config.ScaleX == 0 and 1 or config.ScaleX,
    config.ScaleY == 0 and 1 or config.ScaleY,
    config.ScaleZ == 0 and 1 or config.ScaleZ
    )
end
--windEnd
--- 展示伙伴模型，并且播放变形动画
--- 待机模型->战斗模型
function XUiLottoShow:ShowPartnerModel(templateId)
    if not self.InitPartnerMode then
        self.InitPartnerMode = true
        self.PartnerModelPanel = XUiPanelRoleModel.New(self.PartnerRoot, self.Name, nil, true, nil, true)
    end

    local partnerCurShowNum = self.PartnerIndex

    self.CvInfo = XUiModelUtility.LoadPartnerModelSToC(templateId, self.PartnerModelPanel, XModelManager.MODEL_UINAME.XUiDrawShow, function(SModel)
        SModel.gameObject:SetActiveEx(true)
        self.LastPartnerModel = SModel
        self.BtnClick.gameObject:SetActiveEx(true)
    end, function()
        local modelConfig = XDataCenter.PartnerManager.GetPartnerModelConfigById(templateId)
        if partnerCurShowNum == self.PartnerIndex then
            -- 战斗模型
            self.PartnerModelPanel:UpdatePartnerModel(modelConfig.CombatModel, XModelManager.MODEL_UINAME.XUiDrawShow, nil, function(CModel)
                CModel.gameObject:SetActiveEx(true)
                self.LastPartnerModel = CModel
            end, false, true)
            -- 出生特效
            self.PartnerModelPanel:LoadPartnerUiEffect(modelConfig.CombatModel, XPartnerConfigs.EffectParentName.ModelOnEffect, true, true)
            -- 动画
            self.PartnerModelPanel:PlayAnima(modelConfig.CombatBornAnime, true, function()
                if partnerCurShowNum == self.PartnerIndex then
                    self.PartnerIndex = self.PartnerIndex + 1
                end
            end)
        end
    end)
end