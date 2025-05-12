local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridDrawResult = XClass(nil, "XUiGridDrawResult")

function XUiGridDrawResult:Ctor(transform, rootUi)
    self.Transform = transform
    self.RootUi = rootUi
    self:InitUiObject()
end

function XUiGridDrawResult:InitUiObject()
    ---@type UnityEngine.RectTransform
    self.PanelChip = self.Transform:FindTransform("PanelChip")
    ---@type UnityEngine.UI.RawImage
    self.RImgChip = self.Transform:FindTransform("ImgChip"):GetComponent("RawImage")
    local gridChip = self.Transform:FindTransform("GridChip")
    gridChip.gameObject:SetActiveEx(false)
    self.GridChipObj = gridChip
    self.GridChip = XUiGridCommon.New(nil, gridChip)
    ---@type UnityEngine.RectTransform
    self.PanelItem = self.Transform:FindTransform("PanelItem")
    ---@type UnityEngine.UI.RawImage
    self.RImgItem = self.Transform:FindTransform("ImgItem"):GetComponent("RawImage")
    ---@type UnityEngine.RectTransform
    self.PanelArms = self.Transform:FindTransform("PanelArms")
    ---@type UnityEngine.UI.RawImage
    self.RImgArms = self.Transform:FindTransform("ImgArms"):GetComponent("RawImage")
    ---@type UnityEngine.RectTransform
    self.PanelPets = self.Transform:FindTransform("PanelPets")
    ---@type UnityEngine.UI.RawImage
    self.RImgPets = self.Transform:FindTransform("ImgPets"):GetComponent("RawImage")
    ---@type UnityEngine.RectTransform
    self.PanelRole = self.Transform:FindTransform("PanelRole")
    ---@type UnityEngine.UI.RawImage
    self.RImgRole = self.Transform:FindTransform("ImgRole"):GetComponent("RawImage")
    ---@type UnityEngine.UI.Text
    self.TxtCount = self.Transform:FindTransform("TxtCount"):GetComponent("Text")
    ---@type UnityEngine.RectTransform
    self.PanelTrans = self.Transform:FindTransform("PanelTrans")
    self.PanelTrans.gameObject:SetActiveEx(false)
    self.PanelItem.gameObject:SetActiveEx(false)
    self.PanelRole.gameObject:SetActiveEx(false)
    self.PanelChip.gameObject:SetActiveEx(false)
    self.PanelArms.gameObject:SetActiveEx(false)
    self.PanelPets.gameObject:SetActiveEx(false)

    ---@type UnityEngine.RectTransform
    self.EffectRed = XUiHelper.TryGetComponent(self.Transform, "GridDrawShow2/Effect/EffectRed")
    ---@type UnityEngine.RectTransform
    self.EffectRedStart = XUiHelper.TryGetComponent(self.Transform, "GridDrawShow2/Effect/EffectRedStart")
    ---@type UnityEngine.UI.RawImage
    self.Bg = XUiHelper.TryGetComponent(self.Transform, "GridDrawShow2/Bg", "RawImage")
    ---@type UnityEngine.UI.RawImage
    self.HalfBg = XUiHelper.TryGetComponent(self.Transform, "GridDrawShow2/Bg2", "RawImage")
end

function XUiGridDrawResult:SetActive(isActive)
    self.Transform.gameObject:SetActiveEx(isActive)
end

local setTransform = function(target, config)
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

function XUiGridDrawResult:SetData(rewardInfo)
    self.Reward = rewardInfo
    local id = self.Reward.Id and self.Reward.Id > 0 and self.Reward.Id or self.Reward.TemplateId
    local Type = XTypeManager.GetTypeById(id)
    if self.Reward.ConvertFrom > 0 then
        Type = XTypeManager.GetTypeById(self.Reward.ConvertFrom)
        id = self.Reward.ConvertFrom
        self.PanelTrans.gameObject:SetActiveEx(true)
        self.GridChipObj.gameObject:SetActiveEx(true)
        self.GridChip:Refresh(self.Reward)
    end
    self.TxtCount.text = "x" .. self.Reward.Count
    local showTable = XDataCenter.DrawManager.GetDrawShow(Type)
    
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

    if XTool.IsNumberValid(rewardInfo.ShowQuality) then
        quality = rewardInfo.ShowQuality
    end
    
    local effectGroupId = showTable.DrawEffectGroupId[quality]
    -- 加载特效
    self:LoadEffect(effectGroupId)
    self:SetBgRawImage(showTable.DrawPictureGroupId[quality])
    self.RootUi:SetDrawEffectGroupId(effectGroupId)
    
    local icon
    if Type == XArrangeConfigs.Types.Furniture or Type == XArrangeConfigs.Types.HeadPortrait then
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
        icon = goodsShowParams.BigIcon
        self.PanelItem.gameObject:SetActiveEx(true)
        self.RImgItem:SetRawImage(icon)
    else
        if Type == XArrangeConfigs.Types.Character then
            icon = XMVCA.XCharacter:GetCharHalfBodyImage(id)
            self.PanelRole.gameObject:SetActiveEx(true)
            self.RImgRole:SetRawImage(icon)
        elseif Type == XArrangeConfigs.Types.Weapon then
            icon = XMVCA.XEquip:GetEquipLiHuiPath(id)
            self.PanelArms.gameObject:SetActiveEx(true)
            self.RImgArms:SetRawImage(icon)
        elseif Type == XArrangeConfigs.Types.Wafer then
            icon = XMVCA.XEquip:GetEquipLiHuiPath(id)
            self.PanelChip.gameObject:SetActiveEx(true)
            self.RImgChip:SetRawImage(icon)
            self.GridChipObj.gameObject:SetActiveEx(true)
            self.GridChip:Refresh(self.Reward)
            local transformConfig = XDrawConfigs.GetDrawWaferShowById(id)
            if transformConfig then
                setTransform(self.RImgChip, transformConfig)
            end
        elseif Type == XArrangeConfigs.Types.Item then
            icon = XDataCenter.ItemManager.GetItemBigIcon(id)
            self.PanelItem.gameObject:SetActiveEx(true)
            self.RImgItem:SetRawImage(icon)
        elseif Type == XArrangeConfigs.Types.Fashion then
            icon = XDataCenter.FashionManager.GetFashionIcon(id)
            self.PanelRole.gameObject:SetActiveEx(true)
            self.RImgRole:SetRawImage(icon)
        elseif Type == XArrangeConfigs.Types.ChatEmoji then
            icon = XDataCenter.ChatManager.GetEmojiIcon(id)
            self.PanelItem.gameObject:SetActiveEx(true)
            self.RImgItem:SetRawImage(icon)
        elseif Type == XArrangeConfigs.Types.Partner then
            icon = XPartnerConfigs.GetPartnerTemplateLiHuiPath(id)
            self.PanelPets.gameObject:SetActiveEx(true)
            self.RImgPets:SetRawImage(icon)
        end
    end
end

function XUiGridDrawResult:LoadEffect(id)
    local cardEffectStart = XDrawConfigs.GetCardEffectStart(id)
    self.EffectRedStart:LoadPrefab(cardEffectStart)
    local cardEffect = XDrawConfigs.GetCardEffect(id)
    self.EffectRed:LoadPrefab(cardEffect)
end

function XUiGridDrawResult:SetBgRawImage(id)
    local bg = XDrawConfigs.GetDrawCardBg(id)
    self.Bg:SetRawImage(bg)
    local halfBg = XDrawConfigs.GetDrawCardHalfBg(id)
    self.HalfBg:SetRawImage(halfBg)
end

return XUiGridDrawResult