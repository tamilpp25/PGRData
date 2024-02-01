local XUiDrawActivityShow = XLuaUiManager.Register(XLuaUi, "UiDrawActivityShow")
-- local drawShowWeapon = require("XUi/XUiDraw/XUiDrawTools/XUiDrawWeapon")
local drawShowEffect = require("XUi/XUiDraw/XUiDrawTools/XUiDrawShowEffect")
local drawScene = require("XUi/XUiDraw/XUiDrawTools/XUiDrawScene")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local QualityFive = 5
local QualitySix = 6

function XUiDrawActivityShow:OnAwake()
    self:InitAutoScript()
end

function XUiDrawActivityShow:OnStart()
    self.Animation = self.Transform:GetComponent("Animation")
    self:InitImgRewards()
end

function XUiDrawActivityShow:SetData(rewardList, resultCb, backGround)
    self.BackGround = backGround
    self.RewardList = rewardList
    self.ResultCb = resultCb

    self:ResetState()
    self:InitTools()
    self.ShowIndex = 1
    self.IsOpening = false
    self.CurLight = {}
    self.PlayBoxAnim = false
    self.BtnClick.gameObject:SetActiveEx(false)
    self:InitDrawBackGround()
    XUiHelper.SetDelayPopupFirstGet(true)
end

function XUiDrawActivityShow:OnDisable()
    self:ClearLastModel()
    self:HideAllEffect()
    XUiHelper.SetDelayPopupFirstGet()
end

function XUiDrawActivityShow:Update()
    if self.PlayBoxAnim then
        if self.PlayableDirector.time >= self.PlayableDirector.duration - 0.1 then
            self:BoxAnimEnd()
        end
    end
end

function XUiDrawActivityShow:InitImgRewards()
    self.ImgRewards = {}
    self.ImgRewards[XArrangeConfigs.Types.Character] = self.ImgCharacter
    self.ImgRewards[XArrangeConfigs.Types.Fashion] = self.ImgItem
    self.ImgRewards[XArrangeConfigs.Types.Item] = self.ImgItem
    self.ImgRewards[XArrangeConfigs.Types.Wafer] = self.ImgWafer
    self.ImgRewards[XArrangeConfigs.Types.Weapon] = self.ImgEquip
    self.ImgRewards[XArrangeConfigs.Types.Furniture] = self.ImgItem
    self.ImgRewards[XArrangeConfigs.Types.HeadPortrait] = self.ImgItem
    self.ImgRewards[XArrangeConfigs.Types.ChatEmoji] = self.ImgItem
end

function XUiDrawActivityShow:ResetState()
    self.ImgCharacter.gameObject:SetActiveEx(false)
    self.ImgItem.gameObject:SetActiveEx(false)
    self.ImgWafer.gameObject:SetActiveEx(false)
    self.ImgEquip.gameObject:SetActiveEx(false)
    self.ImageItemPack.gameObject:SetActiveEx(false)
    self.ImageWeaponPack.gameObject:SetActiveEx(false)
    self.ImageCharacterPack.gameObject:SetActiveEx(false)
    self.ImageWaferPack.gameObject:SetActiveEx(false)
end

function XUiDrawActivityShow:InitTools()
    --drawScene.AddObject(self.PanelWeapon, drawScene.Types.WEAPON)
    --drawShowWeapon.SetNode(self.PanelAnim, self.PanelWeapon)
    drawScene.SetActive(drawScene.Types.BOX, false)
    drawScene.SetActive(drawScene.Types.BG, false)
    XRTextureManager.SetTextureCache(self.RImgDrawCardShow)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiDrawActivityShow:InitAutoScript()
    self:AutoAddListener()
end

function XUiDrawActivityShow:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)
end
-- auto
function XUiDrawActivityShow:OnBtnClickClick()
    if self.IsOpening then
        self:ShowResult()
    else
        self:HideAllEffect()
        self:NextPack()
    end
end

function XUiDrawActivityShow:OnBtnSkipClick()
    self:ClearLastModel()
    self:PlayEnd()
end

function XUiDrawActivityShow:ShowWeapon()
    drawScene.SetActive(drawScene.Types.WEAPON, true)
end

function XUiDrawActivityShow:ShowResult()
    XUiHelper.StopAnimation(false)

    local id = self:GetRewardId(self.ShowIndex)
    local Type = self:GetRewardType(id)
    local quality = self:GetQuality(id, Type)

    local showTable = XDataCenter.DrawManager.GetDrawShow(Type)
    local skipEffect = XDrawConfigs.GetSkipEffect(showTable.GachaEffectGroupId[quality])
    self.CurPanelOpenUpEffect = self.PanelOpenUp:LoadPrefab(skipEffect)
    self.CurPanelOpenUpEffect.gameObject.name = skipEffect
    self.CurPanelOpenUpEffect.gameObject:SetActiveEx(true)

    self.IsOpening = false
    self.Animation:Play(showTable.UiResultAnim)
    -- if Type == XArrangeConfigs.Types.Weapon then
    --     drawShowWeapon.PlayResultAnim()
    -- end
    self.ShowIndex = self.ShowIndex + 1
end

function XUiDrawActivityShow:ClearLastModel()
    if self.LastCharacterModel then
        self.LastCharacterModel.gameObject:SetActiveEx(false)
        self.LastCharacterModel = nil
    end

    if self.LastWeaponModel then
        self.LastWeaponModel.gameObject:SetActiveEx(false)
        self.LastWeaponModel = nil
    end
end

function XUiDrawActivityShow:NextPack()
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
    local reward = self.RewardList[self.ShowIndex]
    local id = self:GetRewardId(self.ShowIndex)
    local Type = self:GetRewardType(id)
    local quality = self:GetQuality(id, Type)

    local soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.Normal

    if quality then
        if quality == QualityFive then
            soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.FiveStar
        elseif quality == QualitySix then
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
            icon = XMVCA.XCharacter:GetCharHalfBodyImage(id)
            if quality < 3 then
                soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.FiveStar
            elseif quality > 2 then
                soundType = XSoundManager.UiBasicsMusic.UiDrawCard_Type.SixStar
            end
        elseif Type == XArrangeConfigs.Types.Wafer then
            icon = XDataCenter.EquipManager.GetEquipLiHuiPath(id)
        elseif Type == XArrangeConfigs.Types.Item then
            icon = XDataCenter.ItemManager.GetItemBigIcon(id)
        elseif Type == XArrangeConfigs.Types.ChatEmoji then
            icon = XDataCenter.ChatManager.GetEmojiIcon(id)
        end

        if Type ~= XArrangeConfigs.Types.Character and Type ~= XArrangeConfigs.Types.Fashion then
            self.ImgRewards[Type]:SetRawImage(icon)
            self.BtnClick.gameObject:SetActiveEx(true)
        end
    end
    local curShowNum = self.ShowIndex
    local showTable = XDataCenter.DrawManager.GetDrawShow(Type)
    self.IsOpening = true
    XUiHelper.StopAnimation(false)
    XUiHelper.PlayAnimation(self, showTable.UiAnim, nil, function()
        self.PanelCardShowOff.gameObject:SetActiveEx(true)
        if self.GameObject.activeInHierarchy then
            if curShowNum == self.ShowIndex then
                local effect = XDrawConfigs.GetOpenUpEffect(showTable.GachaEffectGroupId[quality])
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

    local effect = XDrawConfigs.GetOpenDownEffect(showTable.GachaEffectGroupId[quality])
    self.CurPanelOpenDownEffect = self.PanelOpenDown.transform:Find(effect)
    if self.CurPanelOpenDownEffect then
        self.CurPanelOpenDownEffect.gameObject:SetActiveEx(true)
    else
        self.CurPanelOpenDownEffect = self.PanelOpenDown:LoadPrefab(effect)
        self.CurPanelOpenDownEffect.gameObject.name = effect
        self.CurPanelOpenDownEffect.gameObject:SetActiveEx(true)
    end

end

function XUiDrawActivityShow:ShowWeaponModel(templateId)
    local modelConfig = XDataCenter.EquipManager.GetWeaponModelCfg(templateId, self.Name, 0)
    if modelConfig then
        XModelManager.LoadWeaponModel(modelConfig.ModelId, self.WeaponRoot, modelConfig.TransformConfig, self.Name, function(model)
            model.gameObject:SetActiveEx(true)
            self.LastWeaponModel = model
            self.BtnClick.gameObject:SetActiveEx(true)
        end, { gameObject = self.GameObject })
    end
end


function XUiDrawActivityShow:ShowWeaponFashionModel(templateId)
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

function XUiDrawActivityShow:ShowCharacterModel(templateId, fashtionId)
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

function XUiDrawActivityShow:HideAllEffect()
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
    if not XTool.UObjIsNil(self.CurStape_1) then
        self.CurStape_1.gameObject:SetActiveEx(false)
    end
    if not XTool.UObjIsNil(self.CurStape_2) then
        self.CurStape_2.gameObject:SetActiveEx(false)
    end
end

function XUiDrawActivityShow:PlayEnd()
    XUiHelper.StopAnimation()

    self.BtnClick.gameObject:SetActiveEx(true)
    drawScene.SetActive(drawScene.Types.BOX, true)
    if self.CurStape_1 and not XTool.UObjIsNil(self.CurStape_1.gameObject) then
        self.CurStape_1.gameObject:SetActiveEx(false)
    end
    if self.CurStape_2 and not XTool.UObjIsNil(self.CurStape_2.gameObject) then
        self.CurStape_2.gameObject:SetActiveEx(false)
    end
    if self.CvInfo then
        self.CvInfo:Stop()
        self.CvInfo = nil
    end
    self:Close()
    self.ResultCb()
end

function XUiDrawActivityShow:OnDestroy()
    drawScene.DestroyObject(drawScene.Types.EFFECT)
    drawScene.DestroyObject(drawScene.Types.WEAPON)
    drawScene.DestroyObject(drawScene.Types.SHOWBG)
    drawShowEffect.Dispose()
end

--wind
function XUiDrawActivityShow:InitDrawBackGround()
    self.TxtType.text = ""
    self.TxtName.text = ""
    self.TxtQuality.text = ""
    self.PanelInfo.gameObject:GetComponent("CanvasGroup").alpha = 0

    self:PlayBoxAnimStart()
end

function XUiDrawActivityShow:PlayBoxAnimStart()
    self.PanelOpenUp = self.BackGround.transform:Find("ModelRoot/UiNearRoot/EffectRoot/PanelOpenUp")
    self.PanelOpenDown = self.BackGround.transform:Find("ModelRoot/UiNearRoot/EffectRoot/PanelOpenDown")
    self.PanelCardShowOff = self.BackGround.transform:Find("ModelRoot/UiNearRoot/EffectRoot/PanelCardShowOff")
    self.WeaponRoot = self.BackGround.transform:Find("ModelRoot/UiNearRoot/WeaponRoot")
    self.CharacterRoot = self.BackGround.transform:Find("ModelRoot/UiNearRoot/CharacterRoot")

    local behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    if self.Update then
        behaviour.LuaUpdate = function() self:Update() end
    end


    self.GachaShowStape_1 = self.BackGround.transform:Find("BoxEffect/Stape1")
    self.GachaShowStape_2 = self.BackGround.transform:Find("BoxEffect/Stape2")

    local effectsName
    local effectsLevel

    effectsName, effectsLevel = self:GetMaxQualityEffectName()

    if self.GachaShowStape_1 then
        self.CurStape_1 = self.GachaShowStape_1:LoadPrefab(XUiConfigs.GetComponentUrl("UiGachaSteap1"))
        self.CurStape_1.gameObject:SetActiveEx(true)
    end
    if self.GachaShowStape_2 then
        self.CurStape_2 = self.GachaShowStape_2:LoadPrefab(effectsName)
        self.CurStape_2.gameObject:SetActiveEx(true)
    end

    self.PlayableDirector = XUiHelper.TryGetComponent(self.BackGround.transform, "TimeLine/Level" .. effectsLevel, "PlayableDirector")
    if self.PlayableDirector then
        self.PlayableDirector.gameObject:SetActiveEx(true)
        self.PlayableDirector:Play()
        self.PlayBoxAnim = true
    end
end

function XUiDrawActivityShow:BoxAnimEnd()
    self.PlayBoxAnim = false
    self:NextPack()
end

function XUiDrawActivityShow:GetQuality(id, type)
    local quality
    local templateIdData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
    if type == XArrangeConfigs.Types.Wafer then
        quality = templateIdData.Star
    elseif type == XArrangeConfigs.Types.Weapon then
        quality = templateIdData.Star
    elseif type == XArrangeConfigs.Types.Character then
        quality = XMVCA.XCharacter:GetCharMinQuality(id)
    else
        quality = XTypeManager.GetQualityById(id)
    end
    return quality
end

function XUiDrawActivityShow:GetRewardType(id)
    local IsWeaponFashion = XDataCenter.ItemManager.IsWeaponFashion(id)
    local Type = IsWeaponFashion and XArrangeConfigs.Types.WeaponFashion or XTypeManager.GetTypeById(id)

    return Type
end

function XUiDrawActivityShow:GetRewardId(showIndex)
    local reward = self.RewardList[showIndex]
    local id = reward.Id and reward.Id > 0 and reward.Id or reward.TemplateId
    if reward.ConvertFrom > 0 then
        id = reward.ConvertFrom
    end
    return id
end

--获取最高品级效果，按类型取每一类最大值，最后比较大小得出最大的类型和值
function XUiDrawActivityShow:GetMaxQualityEffectName()
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
            local effect = XDrawConfigs.GetOpenBoxEffect(showTable.GachaEffectGroupId[maxByType[k]])

            if tonumber(string.sub(effect, -8, -8)) > maxEffectLevel then
                maxEffectLevel = tonumber(string.sub(effect, -8, -8))
                maxEffectPath = effect
            end
        end
    end
    return maxEffectPath, maxEffectLevel
end

function XUiDrawActivityShow:SetWeaponPos(target, config)
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