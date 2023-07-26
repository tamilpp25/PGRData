local XUiDrawShow = XLuaUiManager.Register(XLuaUi, "UiDrawShow")
-- local drawShowWeapon = require("XUi/XUiDraw/XUiDrawTools/XUiDrawWeapon")
local drawShowEffect = require("XUi/XUiDraw/XUiDrawTools/XUiDrawShowEffect")
local drawScene = require("XUi/XUiDraw/XUiDrawTools/XUiDrawScene")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiModelUtility = require("XUi/XUiCharacter/XUiModelUtility")

function XUiDrawShow:OnAwake()
    self:InitAutoScript()
end

function XUiDrawShow:OnStart(drawInfo, rewardList, resultCb, background)
    self.Animation = self.Transform:GetComponent("Animation")
    self:InitImgRewards()
    self:SetData(drawInfo, rewardList, resultCb, background)
end

function XUiDrawShow:SetData(drawInfo, rewardList, resultCb, backGround)
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
    --self:InitDrawBackGround()
    self:NextPack()
    XUiHelper.SetDelayPopupFirstGet(true)
end

function XUiDrawShow:OnDisable()
    self:HideAllEffect()
    self:ClearLastModel()
    XUiHelper.SetDelayPopupFirstGet()
end

function XUiDrawShow:Update()
    if self.PlayBoxAnim then
        if self.PlayableDirector.time >= self.PlayableDirector.duration - 0.1 then
            self:BoxAnimEnd()
        end
    end
end

function XUiDrawShow:InitImgRewards()
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

function XUiDrawShow:ResetState()
    self.ImgCharacter.gameObject:SetActiveEx(false)
    self.ImgItem.gameObject:SetActiveEx(false)
    self.ImgWafer.gameObject:SetActiveEx(false)
    self.ImgEquip.gameObject:SetActiveEx(false)
    self.ImgPartner.gameObject:SetActiveEx(false)

    self.ImageItemPack.gameObject:SetActiveEx(false)
    self.ImageWeaponPack.gameObject:SetActiveEx(false)
    self.ImageCharacterPack.gameObject:SetActiveEx(false)
    self.ImageWaferPack.gameObject:SetActiveEx(false)
    self.ImagePartnerPack.gameObject:SetActiveEx(false)
end

function XUiDrawShow:InitTools()
    --drawScene.AddObject(self.PanelWeapon, drawScene.Types.WEAPON)
    --drawShowWeapon.SetNode(self.PanelAnim, self.PanelWeapon)
    drawScene.SetActive(drawScene.Types.BOX, false)
    drawScene.SetActive(drawScene.Types.BG, false)
    XRTextureManager.SetTextureCache(self.RImgDrawCardShow)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiDrawShow:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiDrawShow:AutoInitUi()
    self.PanelOpenUp = self.UiModelGo.transform:Find("ModelRoot/UiNearRoot/EffectRoot/PanelOpenUp")
    self.PanelOpenDown = self.UiModelGo.transform:Find("ModelRoot/UiNearRoot/EffectRoot/PanelOpenDown")
    self.PanelCardShowOff = self.UiModelGo.transform:Find("ModelRoot/UiNearRoot/EffectRoot/PanelCardShowOff")
    self.WeaponRoot = self.UiModelGo.transform:Find("ModelRoot/UiNearRoot/WeaponRoot")
    self.CharacterRoot = self.UiModelGo.transform:Find("ModelRoot/UiNearRoot/CharacterRoot")
    self.PartnerRoot = self.UiModelGo.transform:Find("ModelRoot/UiNearRoot/PartnerRoot")
    self.Plane = self.UiModelGo.transform:Find("ModelRoot/UiFarRoot/Plane")
    self.AnimEnable = self.UiModelGo.transform:Find("Animation/AnimEnable"):GetComponent("PlayableDirector")
    -- self.PanelDrawBackGround = self.Transform:Find("FullScreenBackground/PanelDrawBackGround")
    -- self.PanelResult = self.Transform:Find("SafeAreaContentPane/PanelResult")
    -- self.ImgItem = self.Transform:Find("SafeAreaContentPane/PanelResult/ImgItem"):GetComponent("RawImage")
    -- self.ImgCharacter = self.Transform:Find("SafeAreaContentPane/PanelResult/ImgCharacter"):GetComponent("RawImage")
    -- self.ImgWafer = self.Transform:Find("SafeAreaContentPane/PanelResult/ImgWafer"):GetComponent("RawImage")
    -- self.RImgDrawCardShow = self.Transform:Find("SafeAreaContentPane/RImgDrawCardShow"):GetComponent("RawImage")
    -- self.PanelEffect = self.Transform:Find("SafeAreaContentPane/PanelEffect")
    -- self.BtnClick = self.Transform:Find("SafeAreaContentPane/BtnClick"):GetComponent("Button")
    -- self.PanelAnim = self.Transform:Find("SafeAreaContentPane/ModelRoot/NearRoot/PanelAnim")
    -- self.PanelInfo = self.Transform:Find("SafeAreaContentPane/PanelInfo")
    -- self.TxtType = self.Transform:Find("SafeAreaContentPane/PanelInfo/TxtType"):GetComponent("Text")
    -- self.TxtName = self.Transform:Find("SafeAreaContentPane/PanelInfo/TxtName"):GetComponent("Text")
    -- self.TxtQuality = self.Transform:Find("SafeAreaContentPane/PanelInfo/TxtQuality"):GetComponent("Text")
    -- self.ImgEquip = self.Transform:Find("SafeAreaContentPane/PanelResult/ImgEquip"):GetComponent("RawImage")
    -- self.BtnSkip = self.Transform:Find("SafeAreaContentPane/BtnSkip"):GetComponent("Button")
end

function XUiDrawShow:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)
end
-- auto
function XUiDrawShow:OnBtnClickClick()
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

function XUiDrawShow:OnBtnSkipClick()
    if self.IsPartner then
        self.PartnerIndex = self.PartnerIndex + 1
        self.IsPartner = false
    end

    self:ClearLastModel()
    self:PlayEnd()
end

function XUiDrawShow:ShowWeapon()
    drawScene.SetActive(drawScene.Types.WEAPON, true)
end

function XUiDrawShow:ShowResult()
    XUiHelper.StopAnimation(false)

    local reward = self.RewardList[self.ShowIndex]
    local id = reward.Id and reward.Id > 0 and reward.Id or reward.TemplateId
    if reward.ConvertFrom > 0 then
        id = reward.ConvertFrom
    end
    local Type = XTypeManager.GetTypeById(id)
    if XDataCenter.ItemManager.IsWeaponFashion(id) then
        Type = XArrangeConfigs.Types.Weapon
    end
    local quality
    local templateIdData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
    if Type == XArrangeConfigs.Types.Wafer then
        quality = templateIdData.Star
    elseif Type == XArrangeConfigs.Types.Weapon and (not XDataCenter.ItemManager.IsWeaponFashion(id)) then
        quality = templateIdData.Star
    elseif Type == XArrangeConfigs.Types.Character then
        quality = XCharacterConfigs.GetCharMinQuality(id)
    else
        quality = XTypeManager.GetQualityById(id)
    end
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

function XUiDrawShow:ClearLastModel()
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

function XUiDrawShow:NextPack()
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
    local id = reward.Id and reward.Id > 0 and reward.Id or reward.TemplateId
    if reward.ConvertFrom > 0 then
        id = reward.ConvertFrom
    end
    local Type = XTypeManager.GetTypeById(id)
    if XDataCenter.ItemManager.IsWeaponFashion(id) then
        Type = XArrangeConfigs.Types.Weapon
    end
    local quality
    local templateIdData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
    if Type == XArrangeConfigs.Types.Wafer then
        quality = templateIdData.Star
    elseif Type == XArrangeConfigs.Types.Weapon then
        quality = templateIdData.Star
    elseif Type == XArrangeConfigs.Types.Character then
        quality = XCharacterConfigs.GetCharMinQuality(id)
    elseif Type == XArrangeConfigs.Types.Partner then
        quality = templateIdData.Quality
    else
        quality = XTypeManager.GetQualityById(id)
    end
    if XDataCenter.ItemManager.IsWeaponFashion(id) then
        quality = XTypeManager.GetQualityById(id)
    end

    local soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.Normal
 
    if quality then
        if quality == 5 then
            soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.FiveStar
        elseif quality == 6 then
            soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.SixStar
        end
    end

    local icon
    if Type == XArrangeConfigs.Types.Weapon or Type == XArrangeConfigs.Types.Furniture or Type == XArrangeConfigs.Types.HeadPortrait then
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
        icon = goodsShowParams.BigIcon

        if Type ~= XArrangeConfigs.Types.Weapon then
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
            icon = templateIdData.Icon
            if quality < 3 then
                soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.FiveStar
            elseif quality > 2 then
                soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.SixStar
            end
        end

        if Type ~= XArrangeConfigs.Types.Character and Type ~= XArrangeConfigs.Types.Partner and Type ~= XArrangeConfigs.Types.Fashion
                and (not XDataCenter.ItemManager.IsWeaponFashion(id)) then
            self.ImgRewards[Type]:SetRawImage(icon)
            self.ImgRewards[Type].gameObject:SetActiveEx(true)
            self.BtnClick.gameObject:SetActiveEx(true)
        end
    end
    local curShowNum = self.ShowIndex
    local showTable = XDataCenter.DrawManager.GetDrawShow(Type)
    self.IsOpening = true    
    self.IsPartner = false

    XUiHelper.StopAnimation(false)
    if self.AnimEnable then
        self.AnimEnable:Play()
    end
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
                self:ShowCharacterModel(id,nil)
            elseif Type == XArrangeConfigs.Types.Fashion then
                self:ShowCharacterModel(nil,id)
            elseif Type == XArrangeConfigs.Types.Weapon and (not XDataCenter.ItemManager.IsWeaponFashion(id)) then
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
    if XDataCenter.ItemManager.IsWeaponFashion(id) then
        local table = XDataCenter.DrawManager.GetDrawShow(XArrangeConfigs.Types.WeaponFashion)
        self.TxtType.text = table.TypeText
    else
        self.TxtType.text = showTable.TypeText
    end
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

function XUiDrawShow:ShowWeaponModel(templateId)
    local modelConfig = XDataCenter.EquipManager.GetWeaponModelCfg(templateId, self.Name, 0)
    if modelConfig then
        XModelManager.LoadWeaponModel(modelConfig.ModelId, self.WeaponRoot, modelConfig.TransformConfig, self.Name, function(model)
            model.gameObject:SetActiveEx(true)
            self.LastWeaponModel = model
            self.BtnClick.gameObject:SetActiveEx(true)
        end, { gameObject = self.GameObject })
    end
end

function XUiDrawShow:ShowCharacterModel(templateId,fashionId)
    if not templateId and not fashionId then
        return
    end
    if not self.InitRoleMode then
        self.InitRoleMode = true
        self.RoleModelPanel = XUiPanelRoleModel.New(self.CharacterRoot, self.Name, true, false, false)
    end
    local curCharacterId = templateId or XDataCenter.FashionManager.GetCharacterId(fashionId)

    local curFashtionId = fashionId or XCharacterConfigs.GetCharacterTemplate(curCharacterId).DefaultNpcFashtionId
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

function XUiDrawShow:ShowWeaponFashionModel(templateId)
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

---
--- 展示伙伴模型，并且播放变形动画
--- 待机模型->战斗模型
function XUiDrawShow:ShowPartnerModel(templateId)
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

function XUiDrawShow:HideAllEffect()
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
    --if not XTool.UObjIsNil(self.CurLight) then
    --    self.CurLight.gameObject:SetActiveEx(false)
    --end
    --if not XTool.UObjIsNil(self.CurLightLock) then
    --    self.CurLightLock.gameObject:SetActiveEx(false)
    --end
    if self.PartnerModelPanel then
        self.PartnerModelPanel:HideAllEffects()
    end
end

function XUiDrawShow:PlayEnd()
    XUiHelper.StopAnimation()
    self.Plane.gameObject:SetActiveEx(true)
    self.BtnClick.gameObject:SetActiveEx(true)
    drawScene.SetActive(drawScene.Types.BOX, true)
    --if self.CurLight.gameObject then
    --    self.CurLight.gameObject:SetActiveEx(false)
    --end
    --if self.CurLightLock and not XTool.UObjIsNil(self.CurLightLock.gameObject) then
    --    self.CurLightLock.gameObject:SetActiveEx(false)
    --end
    if self.CvInfo then
        self.CvInfo:Stop()
        self.CvInfo = nil
    end
    XLuaUiManager.Remove("UiDrawShow")
    self.ResultCb()
end

function XUiDrawShow:OnDestroy()
    drawScene.DestroyObject(drawScene.Types.EFFECT)
    drawScene.DestroyObject(drawScene.Types.WEAPON)
    drawScene.DestroyObject(drawScene.Types.SHOWBG)
    drawShowEffect.Dispose()
end

--wind
function XUiDrawShow:InitDrawBackGround()
    self.TxtType.text = ""
    self.TxtName.text = ""
    self.TxtQuality.text = ""
    self.PanelInfo.gameObject:GetComponent("CanvasGroup").alpha = 0

    self:PlayBoxAnimStart()
end

function XUiDrawShow:PlayBoxAnimStart()
    self.PanelOpenUp = self.UiModelGo.transform:Find("ModelRoot/UiNearRoot/EffectRoot/PanelOpenUp")
    self.PanelOpenDown = self.UiModelGo.transform:Find("ModelRoot/UiNearRoot/EffectRoot/PanelOpenDown")
    self.PanelCardShowOff = self.UiModelGo.transform:Find("ModelRoot/UiNearRoot/EffectRoot/PanelCardShowOff")
    self.WeaponRoot = self.UiModelGo.transform:Find("ModelRoot/UiNearRoot/WeaponRoot")
    self.CharacterRoot = self.UiModelGo.transform:Find("ModelRoot/UiNearRoot/CharacterRoot")
    self.PartnerRoot = self.UiModelGo.transform:Find("ModelRoot/UiNearRoot/PartnerRoot")
    self.Plane = self.UiModelGo.transform:Find("ModelRoot/UiFarRoot/Plane")

    local behaviour = self.GameObject:GetComponent("XLuaBehaviour")
    if not behaviour then
        behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    end

    if self.Update then
        behaviour.LuaUpdate = function() self:Update() end
    end
    self.PlayableDirector = self.BackGround:GetComponent("PlayableDirector")
    self.PlayableDirector:Play()
    self.PlayBoxAnim = true
    self.PanelBoxLight = self.BackGround.transform:Find("ModelRoot/UiNearRoot/PanelBox/PanelBoxLight")
    self.PanelBoxLock = self.BackGround.transform:Find("ModelRoot/UiNearRoot/PanelBox/PanelBoxLock")
    --self.CurLight = self.PanelBoxLight:LoadPrefab(self:GetMaxQualityEffectName())
    --self.CurLight.gameObject:SetActiveEx(true)
    --if self.PanelBoxLock then
    --    self.CurLightLock = self.PanelBoxLock:LoadPrefab(XUiConfigs.GetComponentUrl("UiDrawOpenBoxPre"))
    --    self.CurLightLock.gameObject:SetActiveEx(true)
    --end
end

function XUiDrawShow:BoxAnimEnd()
    self.PlayBoxAnim = false
    self:NextPack()
end

function XUiDrawShow:GetQuality(showIndex)
    local reward = self.RewardList[showIndex]
    local id = reward.Id and reward.Id > 0 and reward.Id or reward.TemplateId
    if reward.ConvertFrom > 0 then
        id = reward.ConvertFrom
    end
    local quality
    local templateIdData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
    local Type = XTypeManager.GetTypeById(id)
    if Type == XArrangeConfigs.Types.Wafer then
        quality = templateIdData.Star
    elseif Type == XArrangeConfigs.Types.Weapon then
        quality = templateIdData.Star
    elseif Type == XArrangeConfigs.Types.Character then
        quality = XCharacterConfigs.GetCharMinQuality(id)
    else
        quality = XTypeManager.GetQualityById(id)
    end
    return quality
end

function XUiDrawShow:GetRewardType(showIndex)
    local reward = self.RewardList[showIndex]
    local id = reward.Id and reward.Id > 0 and reward.Id or reward.TemplateId
    if reward.ConvertFrom > 0 then
        id = reward.ConvertFrom
    end
    local type = XTypeManager.GetTypeById(id)
    return type
end

--获取最高品级效果，按类型取每一类最大值，最后比较大小得出最大的类型和值
function XUiDrawShow:GetMaxQualityEffectName()
    local maxByType = {}

    for k, v in pairs(XArrangeConfigs.Types) do
        local maxQuality = 0
        for i = 1, #self.RewardList do
            if self:GetRewardType(i) == v then
                local tempQuality = self:GetQuality(i)
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

function XUiDrawShow:SetWeaponPos(target, config)
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