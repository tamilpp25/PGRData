local XUiGridGachaShowReward = XClass(nil, "XUiGridGachaShowReward")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiModelUtility = require("XUi/XUiCharacter/XUiModelUtility")

local LineEffect2d = "DrawShowLineCommunicationEffect2d"
local LineEffect3d = "DrawShowLineCommunicationEffect3d"
local LineEffectWeapon3d = "DrawShowLineCommunicationEffectWq3d"

function XUiGridGachaShowReward:Ctor(rootUi, modelPanel, uiPanel, farCamera, nearCamera, uiCamera)
    self.RootUi = rootUi
    self.ModelPanel = modelPanel
    self.UiPanel = uiPanel
    self.FarCamera = farCamera
    self.NearCamera = nearCamera
    self.UiCamera = uiCamera
    self:InitUiObject()
end

function XUiGridGachaShowReward:InitUiObject()
    ---@type UnityEngine.UI.Text
    self.TxtName = self.UiPanel:FindTransform("TxtName"):GetComponent("Text")
    ---@type UnityEngine.UI.Image
    self.ImgNameBg = self.UiPanel:FindTransform("ImgBg"):GetComponent("Image")
    ---@type UnityEngine.UI.Text
    self.TxtType = self.UiPanel:FindTransform("TxtType"):GetComponent("Text")
    ---@type UnityEngine.UI.Text
    self.TxtQuality = self.UiPanel:FindTransform("TxtQuality"):GetComponent("Text")
    ---@type UnityEngine.RectTransform
    self.PanelText = self.UiPanel:FindTransform("PanelText")
    ---@type UnityEngine.RectTransform
    self.PanelChip = self.UiPanel:FindTransform("PanelChip")
    ---@type UnityEngine.RectTransform
    self.ChipEffect = self.UiPanel:FindTransform("ChipEffect")
    ---@type UnityEngine.RectTransform
    self.PanelItem = self.UiPanel:FindTransform("PanelItem")
    ---@type UnityEngine.RectTransform
    self.ItemEffect = self.UiPanel:FindTransform("ItemEffect")
    ---@type UnityEngine.UI.RawImage
    self.RImgChip = self.UiPanel:FindTransform("ImgChip"):GetComponent("RawImage")
    ---@type UnityEngine.UI.RawImage
    self.RImgItem = self.UiPanel:FindTransform("ImgItem"):GetComponent("RawImage")
    ---@type UnityEngine.RectTransform
    self.PanelConvert = self.UiPanel:FindTransform("PanelConvert")
    ---@type UnityEngine.UI.Text
    self.TxtNumber = self.UiPanel:FindTransform("TxtNumber"):GetComponent("Text")
    local gridConvert = self.UiPanel:FindTransform("GridCommonPopUp")
    self.GridConvert = XUiGridCommon.New(nil, gridConvert)
    ---@type UnityEngine.RectTransform
    self.ImgEffectDizuo = self.ModelPanel:FindTransform("ImgEffectDizuo")
    ---@type UnityEngine.RectTransform
    self.ImgEffectFloor = self.ModelPanel:FindTransform("ImgEffectFloor")
    ---@type UnityEngine.RectTransform
    self.ImgEffectXuxian = self.ModelPanel:FindTransform("ImgEffectXuxian")
    ---@type UnityEngine.RectTransform
    self.ImgEffectGuang = self.ModelPanel:FindTransform("ImgEffectGuang")
    ---@type UnityEngine.RectTransform
    self.GridModel = self.ModelPanel:FindTransform("GridModel")
    ---@type UnityEngine.RectTransform
    self.GridModelCaseDisable = self.ModelPanel:FindTransform("GridModelCaseDisable")
    ---@type UnityEngine.RectTransform
    self.GridModelCaseEnable = self.ModelPanel:FindTransform("GridModelCaseEnable")
end

function XUiGridGachaShowReward:OnShow(rewardInfo)
    self.Reward = rewardInfo
    self.FarCamera.gameObject:SetActiveEx(true)
    self.NearCamera.gameObject:SetActiveEx(true)
    self.UiCamera.gameObject:SetActiveEx(true)
    self.ModelPanel.gameObject:SetActiveEx(false)
    self.UiPanel.gameObject:SetActiveEx(true)


    --获取奖励类型
    local reward = self.Reward
    local id = reward.Id and reward.Id > 0 and reward.Id or reward.TemplateId
    local Type = XTypeManager.GetTypeById(id)
    if reward.ConvertFrom > 0 then
        --有转换碎片之后显示碎片转换ui面板
        self.PanelConvert.gameObject:SetActiveEx(true)
        self.GridConvert:Refresh(reward)
        self.TxtNumber.text = "x" .. reward.Count
        Type = XTypeManager.GetTypeById(reward.ConvertFrom)
        id = reward.ConvertFrom
    end
    local showTable = XGachaConfigs.GetGachaShowByGroupId(self.RootUi.GachaCfg.GachaShowGroupId)[Type]

    if XDataCenter.ItemManager.IsWeaponFashion(id) then
        Type = XArrangeConfigs.Types.Weapon
    end

    --获取奖励品质
    local quality
    local templateIdData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
    if Type == XArrangeConfigs.Types.Wafer then
        quality = templateIdData.Star
    elseif Type == XArrangeConfigs.Types.Weapon then
        quality = templateIdData.Star
    elseif Type == XArrangeConfigs.Types.Character then
        quality = XMVCA.XCharacter:GetCharMinQuality(id)
    elseif Type == XArrangeConfigs.Types.Partner then
        quality = templateIdData.Quality
    else
        quality = XTypeManager.GetQualityById(id)
    end
    if XDataCenter.ItemManager.IsWeaponFashion(id) then
        quality = XTypeManager.GetQualityById(id)
    end
    -- 强制检测特效
    local foreceQuality = XGachaConfigs.GetGachaShowRewardConfigById(id)
    if foreceQuality then
        quality = foreceQuality.EffectQualityType
    end
    -- 加载特效
    self:LoadEffect(showTable.GachaEffectGroupId[quality])

    local templateId = id
    if XArrangeConfigs.Types.Furniture == reward.RewardType then
        local cfg = XFurnitureConfigs.GetFurnitureReward(id)
        if cfg and cfg.FurnitureId then
            templateId = cfg.FurnitureId
        end
    end
    self.TxtName.text = XTypeManager.GetNameById(templateId)
    local nameBgPath = XDrawConfigs.GetDrawCardNameBg(showTable.DrawPictureGroupId[quality])
    self.ImgNameBg:SetSprite(nameBgPath)
    if XDataCenter.ItemManager.IsWeaponFashion(id) then
        local table = XDataCenter.DrawManager.GetDrawShow(XArrangeConfigs.Types.WeaponFashion)
        self.TxtType.text = table.TypeText
    else
        self.TxtType.text = showTable.TypeText
    end
    self.TxtQuality.text = showTable.QualityText[quality]

    local soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.Normal

    --根据奖励品质播放对应音效
    if quality then
        if quality == 5 then
            soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.FiveStar
        elseif quality == 6 then
            soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.SixStar
        end
    end
    
    --获取对应的展示图片
    local icon
    if Type == XArrangeConfigs.Types.Weapon or Type == XArrangeConfigs.Types.Furniture or Type == XArrangeConfigs.Types.HeadPortrait then
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
        icon = goodsShowParams.BigIcon

        if Type ~= XArrangeConfigs.Types.Weapon then
            self:CreateItem(icon, true, Type)
        end
    else
        local isSmall = false
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
            isSmall = true
        elseif Type == XArrangeConfigs.Types.Fashion then
            icon = XDataCenter.FashionManager.GetFashionGachaIcon(id)
        elseif Type == XArrangeConfigs.Types.ChatEmoji then
            icon = XDataCenter.ChatManager.GetEmojiIcon(id)
            isSmall = true
        elseif Type == XArrangeConfigs.Types.Partner then
            icon = templateIdData.Icon
            if quality < 3 then
                soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.FiveStar
            elseif quality > 2 then
                soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.SixStar
            end
        elseif Type == XArrangeConfigs.Types.Background then
            isSmall = true
            icon = XPhotographConfigs.GetBackgroundBigIconById(id)
        end

        if Type ~= XArrangeConfigs.Types.Character and Type ~= XArrangeConfigs.Types.Partner and Type ~= XArrangeConfigs.Types.Fashion and (not XDataCenter.ItemManager.IsWeaponFashion(id)) then
            self:CreateItem(icon, isSmall, Type)
        end
    end

    self.ModelPanel.gameObject:SetActiveEx(true)
    self.RootUi.BtnClick.gameObject:SetActiveEx(false)
    -- 播放进入动画
    self.GridModelCaseEnable:PlayTimelineAnimation(function()
        --根据Type创建模型
        self:CreateModel(id, Type)
        self.RootUi.BtnClick.gameObject:SetActiveEx(true)
    end)
end

function XUiGridGachaShowReward:OnShowEnd()
    if self.CvInfo then
        self.CvInfo:Stop()
        self.CvInfo = nil
    end
    self.FarCamera.gameObject:SetActiveEx(false)
    self.NearCamera.gameObject:SetActiveEx(false)
    self.UiCamera.gameObject:SetActiveEx(false)
    -- 播放结束动画
    if self.GridModelCaseDisable then
        self.GridModelCaseDisable:PlayTimelineAnimation()
    end
end

function XUiGridGachaShowReward:CreateModel(id, rewardType)
    if rewardType == XArrangeConfigs.Types.Character then
        self:CreateCharacterModel(id, nil)
    elseif rewardType == XArrangeConfigs.Types.Fashion then
        self:CreateCharacterModel(nil, id)
    elseif rewardType == XArrangeConfigs.Types.Weapon and (not XDataCenter.ItemManager.IsWeaponFashion(id)) then
        self:CreateWeaponModel(id)
    elseif XDataCenter.ItemManager.IsWeaponFashion(id) then
        self:CreateWeaponFashionModel(id)
    elseif rewardType == XArrangeConfigs.Types.Partner then
        self:CreatePartnerModel(id)
    end
end

-- V2.0版本特殊处理 因通讯线特效影响了武器原有的效果 暂时屏蔽该武器（不死鸟）的通讯线特效
local tempFilterWeaponId = {
    2234001,
    2235001,
    2236001,
    6002505,
}

function XUiGridGachaShowReward:CreateWeaponModel(templateId)

    local modelConfig = XDataCenter.EquipManager.GetWeaponModelCfg(templateId, self.RootUi.Name, 0)
    if modelConfig then
        XModelManager.LoadWeaponModel(modelConfig.ModelId, self.GridModel.gameObject, modelConfig.TransformConfig, self.RootUi.Name, function(model)
            model.gameObject:SetActiveEx(true)
            if not table.contains(tempFilterWeaponId, templateId) then
                self:Load3dLineEffect(model, LineEffectWeapon3d)
            end
        end, { gameObject = self.RootUi.GameObject })
    end
end

function XUiGridGachaShowReward:CreateWeaponFashionModel(templateId)
    local fashionId = XDataCenter.ItemManager.GetWeaponFashionId(templateId)
    local modelConfig = XDataCenter.WeaponFashionManager.GetWeaponModelCfg(fashionId, nil, self.RootUi.Name)
    if modelConfig then
        XModelManager.LoadWeaponModel(modelConfig.ModelId, self.GridModel.gameObject, modelConfig.TransformConfig, self.RootUi.Name, function(model)
            model.gameObject:SetActiveEx(true)
            self:Load3dLineEffect(model, LineEffectWeapon3d)
        end, { gameObject = self.RootUi.GameObject })
    end
end

function XUiGridGachaShowReward:CreateCharacterModel(templateId, fashionId)
    if not templateId and not fashionId then
        return
    end
    if not self.InitRoleMode then
        self.InitRoleMode = true
        self.RoleModelPanel = XUiPanelRoleModel.New(self.GridModel, self.RootUi.Name, true, false, false)
    end
    local curCharacterId = templateId or XDataCenter.FashionManager.GetCharacterId(fashionId)

    local curFashtionId = fashionId or XMVCA.XCharacter:GetCharacterTemplate(curCharacterId).DefaultNpcFashtionId
    XDataCenter.DisplayManager.UpdateRoleModel(self.RoleModelPanel, curCharacterId, nil, curFashtionId)

    self.RoleModelPanel:UpdateCharacterModel(curCharacterId, self.GridModel, self.RootUi.Name, function(model)
        model.gameObject:SetActiveEx(true)
        if not table.contains(tempFilterWeaponId, templateId) and not table.contains(tempFilterWeaponId, fashionId) then
            self:Load3dLineEffect(model, LineEffect3d)
        end
        
        local animeID = XDataCenter.DrawManager.GetDrawShowCharacter(curCharacterId).AnimeID
        local voiceId = XDataCenter.DrawManager.GetDrawShowCharacter(curCharacterId).VoiceId

        if animeID then
            self.RoleModelPanel:PlayAnima(animeID)
        end

        if voiceId then
            self.CvInfo = CS.XAudioManager.PlayCv(voiceId)
        end
    end, nil, curFashtionId)
end

function XUiGridGachaShowReward:CreatePartnerModel(templateId)
    if not self.InitPartnerMode then
        self.InitPartnerMode = true
        self.PartnerModelPanel = XUiPanelRoleModel.New(self.GridModel, self.RootUi.Name, nil, true, nil, true)
    end

    self.CvInfo = XUiModelUtility.LoadPartnerModelSToC(templateId, self.PartnerModelPanel, self.RootUi.Name, function(SModel)
        SModel.gameObject:SetActiveEx(true)
    end, function()
        local modelConfig = XDataCenter.PartnerManager.GetPartnerModelConfigById(templateId)
        -- 战斗模型
        self.PartnerModelPanel:UpdatePartnerModel(modelConfig.CombatModel, self.RootUi.Name, nil, function(CModel)
            CModel.gameObject:SetActiveEx(true)
            self:Load3dLineEffect(CModel, LineEffect3d)
        end, false, true)
        -- 出生特效
        self.PartnerModelPanel:LoadPartnerUiEffect(modelConfig.CombatModel, XPartnerConfigs.EffectParentName.ModelOnEffect, true, true)
        -- 动画
        self.PartnerModelPanel:PlayAnima(modelConfig.CombatBornAnime, true)
    end)
end

function XUiGridGachaShowReward:CreateItem(iconPath, isSmall, type)
    self.PanelChip.gameObject:SetActiveEx(not isSmall)
    self.PanelItem.gameObject:SetActiveEx(isSmall)

    local effectPath = XUiHelper.GetClientConfig(LineEffect2d .. type, XUiHelper.ClientConfigType.String)
    local effectGo
    if isSmall then
        self.RImgItem:SetRawImage(iconPath)
        effectGo = self.ItemEffect:LoadUiEffect(effectPath)
    else
        self.RImgChip:SetRawImage(iconPath)
        effectGo = self.ChipEffect:LoadUiEffect(effectPath)
    end

    if not effectGo then
        return
    end
    -- 只修改root节点下特效主帖图
    local root = XUiHelper.TryGetComponent(effectGo.transform, "Root")
    if not root then
        return
    end
    local renderer = root.transform:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))
    self.Resource = CS.XResourceManager.Load(iconPath)
    local texture = self.Resource.Asset
    XTool.LoopArray(renderer, function(v)
        v.material:SetTexture("_MainTex", texture)
        v.trailMaterial = v.material
    end)
end

function XUiGridGachaShowReward:LoadEffect(id)
    -- 加载底座特效
    local carriageEffect = XDrawConfigs.GetCarriageEffect(id)
    self.ImgEffectDizuo:LoadPrefab(carriageEffect)
    -- 加载线特效
    local floorEffect = XDrawConfigs.GetFloorEffect(id)
    self.ImgEffectFloor:LoadPrefab(floorEffect)
    -- 加载光圈特效
    local apertureEffect = XDrawConfigs.GetApertureEffect(id)
    self.ImgEffectGuang:LoadPrefab(apertureEffect)
end

-- 加载3d 通讯线特效
function XUiGridGachaShowReward:Load3dLineEffect(model, effectKey)
    local effectPath = XUiHelper.GetClientConfig(effectKey, XUiHelper.ClientConfigType.String)
    local effectGo = self.ImgEffectXuxian:LoadPrefab(effectPath, true, false)
    if not effectGo then
        return
    end
    local binder = effectGo.transform:GetComponent(typeof(CS.XMaterialAnimation3StepBinder))
    if binder then
        binder.TargetModel = model
    end
    effectGo.gameObject:SetActiveEx(true)
end

function XUiGridGachaShowReward:OnDestroy()
    if self.Resource then
        self.Resource:Release()
        self.Resource = nil
    end
end

return XUiGridGachaShowReward