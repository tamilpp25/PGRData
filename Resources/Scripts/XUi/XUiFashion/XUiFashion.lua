local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiPanelFashionList = require("XUi/XUiFashion/XUiPanelFashionList")
local stringFormat = string.format
local tableInsert = table.insert
local tableRemove = table.remove
local CameraIndex = {
    Normal = 1,
    Near = 2,
}
local BtnTabIndex = {
    Character = 1,
    Weapon = 2,
}
local LastSelectedTabIndex = BtnTabIndex.Character
local WeaponViewType = {
    WithCharacter = 1,
    OnlyWeapon = 2,
}
local SwitchWeaponViewType = {
    [WeaponViewType.OnlyWeapon] = WeaponViewType.WithCharacter,
    [WeaponViewType.WithCharacter] = WeaponViewType.OnlyWeapon,
}
local SwitchBtnName = {
    [WeaponViewType.OnlyWeapon] = CSXTextManagerGetText("UiFashionBtnNameCharacter"),
    [WeaponViewType.WithCharacter] = CSXTextManagerGetText("UiFashionBtnNameWeapon"),
}

local XUiFashion = XLuaUiManager.Register(XLuaUi, "UiFashion")

function XUiFashion:OnAwake()
    self.ExpiredRefreshNameList = {}

    self.BtnLensOut.gameObject:SetActiveEx(true)
    self.BtnLensIn.gameObject:SetActiveEx(false)
    self.PanelUnlockShow.gameObject:SetActiveEx(false)
    self.PanelAssistDistanceTip.gameObject:SetActiveEx(false)
    self.GridFashion.gameObject:SetActiveEx(false)
    self.GridWeapon.gameObject:SetActiveEx(false)

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.PanelCharacterFashionList = XUiPanelFashionList.New(XPlayerInfoConfigs.FashionType.Character, self.ScrollFashionList, function(fashionId)
        self:OnSelectCharacterFashion(fashionId)
    end, self)
    self.PanelWeaponFashionList = XUiPanelFashionList.New(XPlayerInfoConfigs.FashionType.Weapon, self.ScrollWeaponList, function(fashionId)
        self:OnSelectWeaponFashion(fashionId)
    end, self)
    self.PanelTagGroup:Init({
        self.BtnTogCharacter,
        self.BtnTogWeapon,
    }, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    
    self.OnUiSceneLoadedCB = function(lastSceneUrl) self:OnUiSceneLoaded(lastSceneUrl) end

    self:AutoAddListener()
end

function XUiFashion:OnStart(defaultCharacterId, isOnlyOneCharacter, notShowWeapon, openUiType)
    self:InitSceneRoot() --设置摄像机

    local defaultCharacterIndex = 1
    local characterList = XDataCenter.CharacterManager.GetCharacterList()
    if defaultCharacterId then
        self.CharacterId = defaultCharacterId
        for index, character in pairs(characterList) do
            if defaultCharacterId == character.Id then
                defaultCharacterIndex = index
                break
            end
        end
    end
    self.CharacterList = characterList
    self.DefaultCharacterIndex = defaultCharacterIndex
    self.CurWeaponViewType = WeaponViewType.WithCharacter
    self.LastCharacterFashionSceneUrl = nil
    self.IsOnlyOneCharacter = isOnlyOneCharacter
    self.NotShowWeapon = notShowWeapon
    self.OpenUiType = openUiType
end

function XUiFashion:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    if self.NotShowWeapon then
        self.PanelTagGroup.gameObject:SetActiveEx(false)
        self.PanelTagGroup:SelectIndex(BtnTabIndex.Character)
    else
        self.PanelTagGroup.gameObject:SetActiveEx(true)
    end
    self.PanelTagGroup:SelectIndex(LastSelectedTabIndex)
end

function XUiFashion:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiFashion:OnGetEvents()
    return { XEventId.EVENT_FASHION_WEAPON_EXPIRED_REFRESH }
end

function XUiFashion:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FASHION_WEAPON_EXPIRED_REFRESH then
        --过期刷新
        self:UpdateFashionList()
        self:AddExpiredRefresh(...)
        self:OpenTipMsg()
    end
end

function XUiFashion:AddExpiredRefresh(fashionIds)
    if LastSelectedTabIndex ~= BtnTabIndex.Weapon then return end

    local characterId = self.CharacterList[self.CharacterIndex].Id
    local fashionName
    for _, weaponFashionId in pairs(fashionIds) do
        if XDataCenter.WeaponFashionManager.IsCharacterFashion(weaponFashionId, characterId) then
            fashionName = XDataCenter.WeaponFashionManager.GetWeaponFashionName(weaponFashionId)
            if fashionName then
                tableInsert(self.ExpiredRefreshNameList, fashionName) 
            end
        end
    end
end

function XUiFashion:OpenTipMsg()
    if next(self.ExpiredRefreshNameList) then
        XUiManager.TipMsg(CSXTextManagerGetText("WeaponFashionNotOwnTipMsg", self.ExpiredRefreshNameList[1]), nil, function()
            tableRemove(self.ExpiredRefreshNameList, 1)
            self:OpenTipMsg()
        end)
    end
end

function XUiFashion:OnUiSceneLoaded(lastSceneUrl)
    if lastSceneUrl ~= self.LastCharacterFashionSceneUrl then
        self:SetGameObject()
        self:InitSceneRoot()
        self.LastCharacterFashionSceneUrl = lastSceneUrl
    end
end

function XUiFashion:OnSelectCharacter(characterIndex)
    self.CharacterIndex = characterIndex
    self.CharacterId = self.CharacterList[self.CharacterIndex].Id

    local hasLast = characterIndex > 1
    self.BtnLast.interactable = hasLast

    local hasNext = self.CharacterList[characterIndex + 1] and true or false
    self.BtnNext.interactable = hasNext

    self:UpdateFashionList()
end

function XUiFashion:UpdateFashionList(selectDressing, doNotReset)
    local defaultSelectId, dressedId
    local haveCount, totalCount = 0, 0

    local characterId = self.CharacterList[self.CharacterIndex].Id
    if LastSelectedTabIndex == BtnTabIndex.Character then
        local fashionStatus = XDataCenter.FashionManager.FashionStatus
        local fashionList 
        if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
            local nierCharacter = XDataCenter.NieRManager.GetSelNieRCharacter()
            fashionList = nierCharacter:GetNieRFashionList()
            dressedId = nierCharacter:GetNieRFashionId()
            haveCount = #fashionList
        else
            fashionList = XDataCenter.FashionManager.GetCurrentTimeFashionByCharId(characterId)
            for _, fashionId in pairs(fashionList) do
                local status = XDataCenter.FashionManager.GetFashionStatus(fashionId)
                if status ~= fashionStatus.UnOwned then
                    haveCount = haveCount + 1
                end

                if status == fashionStatus.Dressed then
                    dressedId = fashionId
                end
            end
        end
        totalCount = #fashionList
        defaultSelectId = not selectDressing and dressedId or fashionList[1]
        defaultSelectId = not doNotReset and defaultSelectId or nil

        self.PanelCharacterFashionList:UpdateViewList(fashionList, defaultSelectId)
        self.PanelCharacterFashionList.GameObject:SetActiveEx(true)
        self.PanelWeaponFashionList.GameObject:SetActiveEx(false)
    elseif LastSelectedTabIndex == BtnTabIndex.Weapon then
        local fashionStatus = XDataCenter.WeaponFashionManager.FashionStatus
        local fashionList = XDataCenter.WeaponFashionManager.GetSortedWeaponFashionIdsByCharacterId(characterId)
        for _, fashionId in pairs(fashionList) do
            local status = XDataCenter.WeaponFashionManager.GetFashionStatus(fashionId, characterId)
            if status ~= fashionStatus.UnOwned then
                haveCount = haveCount + 1
            end

            -- if status == fashionStatus.Dressed then
            --     defaultSelectId = fashionId
            -- end
        end
        totalCount = #fashionList
        defaultSelectId = fashionList[1]
        defaultSelectId = not doNotReset and defaultSelectId or nil

        self:UpdateSceneAndModel()

        self.PanelWeaponFashionList:UpdateViewList(fashionList, defaultSelectId, characterId)
        self.PanelWeaponFashionList.GameObject:SetActiveEx(true)
        self.PanelCharacterFashionList.GameObject:SetActiveEx(false)
    end

    self.TxtUseNumber.text = haveCount
    self.TxtAllNumber.text = stringFormat("/%d", totalCount)
    if self.BtnFashion then
        self.BtnFashion:SetNameByGroup(0, CSXTextManagerGetText("UiFashionBtnNameFashion", haveCount, totalCount))
    end
end

function XUiFashion:OnSelectCharacterFashion(fashionId)
    self.CurFashionId = fashionId
    self:UpdateSceneAndModel()
    self:UpdateCamera(CameraIndex.Normal)
    self:UpdateButtonState()
end

function XUiFashion:UpdateSceneAndModel()
    self:LoadModelScene()
    self:UpdateCharacterModel()
end

function XUiFashion:LoadModelScene(isDefault)
    local sceneUrl = self:GetSceneUrl(isDefault)
    local modelUrl = self:GetDefaultUiModelUrl()
    self:LoadUiScene(sceneUrl, modelUrl, self.OnUiSceneLoadedCB, false)
end

function XUiFashion:GetSceneUrl(isDefault)
    if isDefault then
        return self:GetDefaultSceneUrl()
    end

    local sceneUrl
    
    if LastSelectedTabIndex == BtnTabIndex.Character then
        sceneUrl = XDataCenter.FashionManager.GetFashionSceneUrl(self.CurFashionId)
    elseif LastSelectedTabIndex == BtnTabIndex.Weapon then
        sceneUrl = XDataCenter.CharacterManager.GetCharShowFashionSceneUrl(self.CharacterId)
    end

    if sceneUrl and sceneUrl ~= "" then
        return sceneUrl
    else
        return self:GetDefaultSceneUrl()
    end
end

function XUiFashion:UpdateCharacterModel()
    local characterId
    local func = function(model)
        self.PanelDrag:GetComponent("XDrag").Target = model.transform
        self:ShowImgEffectHuanren(characterId)
    end

    if self.CurFashionId then
        local template = XDataCenter.FashionManager.GetFashionTemplate(self.CurFashionId)
        characterId = template.CharacterId
        self.TxtFashionName.text = template.Name
        self.RoleModelPanel:UpdateCharacterResModel(template.ResourcesId, template.CharacterId, XModelManager.MODEL_UINAME.XUiFashion, func)
        self.PanelWeapon.gameObject:SetActiveEx(false)
        self.RoleModelPanel.GameObject:SetActiveEx(true)
        if self.IsOnlyOneCharacter then
            self.BtnNext.gameObject:SetActiveEx(false)
            self.BtnLast.gameObject:SetActiveEx(false)
        else
            self.BtnNext.gameObject:SetActiveEx(true)
            self.BtnLast.gameObject:SetActiveEx(true)
        end
        self.PanelBtnSwitch.gameObject:SetActiveEx(false)
        self:ResetPanelBtnLens()
        self:UpdateFashionIntro(self.CurFashionId)
    else
        self.TxtFashionName.text = ""
        self.PanelWeapon.gameObject:SetActiveEx(false)
        self.RoleModelPanel.GameObject:SetActiveEx(false)
        self.PanelBtnSwitch.gameObject:SetActiveEx(false)
        self.PanelBtnLens.gameObject:SetActiveEx(false)
        self.BtnNext.gameObject:SetActiveEx(false)
        self.BtnLast.gameObject:SetActiveEx(false)
        self.BtnUsed.gameObject:SetActiveEx(false)
        self.PanelUnOwed.gameObject:SetActiveEx(false)
        self.BtnUse.gameObject:SetActiveEx(false)
    end
end

function XUiFashion:UpdateButtonState()
    if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
        local nierCharacter = XDataCenter.NieRManager.GetSelNieRCharacter()
        local dressedId = nierCharacter:GetNieRFashionId()
        if self.CurFashionId == dressedId then
            self.PanelUnOwed.gameObject:SetActiveEx(false)
            self.BtnUse.gameObject:SetActiveEx(false)
            self.BtnUsed.gameObject:SetActiveEx(true)
            self.BtnFashionUnLock.gameObject:SetActiveEx(false)
        else
            self.PanelUnOwed.gameObject:SetActiveEx(false)
            self.BtnUse.gameObject:SetActiveEx(true)
            self.BtnUsed.gameObject:SetActiveEx(false)
            self.BtnFashionUnLock.gameObject:SetActiveEx(false)
        end
    else
        local status = XDataCenter.FashionManager.GetFashionStatus(self.CurFashionId)
        local fashionStatus = XDataCenter.FashionManager.FashionStatus
        if status == fashionStatus.Dressed then
            self.PanelUnOwed.gameObject:SetActiveEx(false)
            self.BtnUse.gameObject:SetActiveEx(false)
            self.BtnUsed.gameObject:SetActiveEx(true)
            self.BtnFashionUnLock.gameObject:SetActiveEx(false)
        elseif status == fashionStatus.UnLock then
            self.PanelUnOwed.gameObject:SetActiveEx(false)
            self.BtnUse.gameObject:SetActiveEx(true)
            self.BtnUsed.gameObject:SetActiveEx(false)
            self.BtnFashionUnLock.gameObject:SetActiveEx(false)
        elseif status == fashionStatus.Lock then
            self.PanelUnOwed.gameObject:SetActiveEx(false)
            self.BtnUse.gameObject:SetActiveEx(false)
            self.BtnUsed.gameObject:SetActiveEx(false)
            self.BtnFashionUnLock.gameObject:SetActiveEx(true)
        elseif status == fashionStatus.UnOwned then
            self.PanelUnOwed.gameObject:SetActiveEx(true)
            self.BtnUse.gameObject:SetActiveEx(false)
            self.BtnUsed.gameObject:SetActiveEx(false)
            self.BtnFashionUnLock.gameObject:SetActiveEx(false)
        end
    end
end

function XUiFashion:OnSelectWeaponFashion(weaponFashionId)
    self.CurWeaponFashionId = weaponFashionId
    self:OnSwitchWeaponViewType(true)
    self:UpdateWeaponButtonState()
end

function XUiFashion:OnSwitchWeaponViewType(doNotReset)
    local oldType = self.CurWeaponViewType
    local newType = not doNotReset and SwitchWeaponViewType[self.CurWeaponViewType] or oldType
    self.CurWeaponViewType = newType

    if newType == WeaponViewType.WithCharacter then
        self.BtnNext.gameObject:SetActiveEx(true)
        self.BtnLast.gameObject:SetActiveEx(true)

        self:ResetPanelBtnLens()
        self:LoadModelScene()
        self:UpdateWeaponWithCharacterModel()
    elseif newType == WeaponViewType.OnlyWeapon then
        self.PanelBtnLens.gameObject:SetActiveEx(false)
        self.BtnNext.gameObject:SetActiveEx(false)
        self.BtnLast.gameObject:SetActiveEx(false)
        self:LoadModelScene(true)
        self:UpdateWeaponModel()
    end
    self:UpdateWeaponInfo()

    self.BtnSwitch:SetNameByGroup(0, SwitchBtnName[newType])
    self.PanelBtnSwitch.gameObject:SetActiveEx(true)
    self.BtnFashionUnLock.gameObject:SetActiveEx(false)

    self:UpdateCamera(CameraIndex.Normal)
end

function XUiFashion:UpdateWeaponInfo()
    local characterId = self.CharacterList[self.CharacterIndex].Id
    local fashionName = XDataCenter.WeaponFashionManager.GetWeaponFashionName(self.CurWeaponFashionId, characterId)
    self.TxtFashionName.text = fashionName
    self:UpdateFashionIntro(self.CurWeaponFashionId, characterId)
end

function XUiFashion:UpdateFashionIntro(fashionId, characterId)
    local isDefaultId = XWeaponFashionConfigs.IsDefaultId(fashionId)
    if isDefaultId then
        if not XDataCenter.CharacterManager.IsOwnCharacter(characterId) then
            fashionId = XCharacterConfigs.GetCharacterDefaultEquipId(characterId)
        else
            local equipId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
            fashionId = XDataCenter.EquipManager.GetEquipTemplateId(equipId)
        end
    end

    local desc = XGoodsCommonManager.GetGoodsDescription(fashionId)
    local worldDesc = XGoodsCommonManager.GetGoodsWorldDesc(fashionId)

    if isDefaultId then
        worldDesc = desc
        if string.IsNilOrEmpty(worldDesc) then
            local archiveCfg = XArchiveConfigs.GetWeaponSettingList(fashionId, XArchiveConfigs.SettingType.Setting)
            if next(archiveCfg) then
                worldDesc = archiveCfg[1].Text
            end
        end
        desc = nil
    end

    self.TxtIntroTitle.gameObject:SetActiveEx(not string.IsNilOrEmpty(desc))
    self.TxtIntroTitle.text = desc

    self.TxtIntroDesc.gameObject:SetActiveEx(not string.IsNilOrEmpty(worldDesc))
    self.TxtIntroDesc.text = worldDesc
end

function XUiFashion:UpdateWeaponModel()
    local characterId = self.CharacterList[self.CharacterIndex].Id
    local uiName = XModelManager.MODEL_UINAME.XUiFashion
    local modelConfig = XDataCenter.WeaponFashionManager.GetWeaponModelCfg(self.CurWeaponFashionId, characterId, uiName)

    self.RoleModelPanel.GameObject:SetActiveEx(false)
    self.PanelWeapon.gameObject:SetActiveEx(true)
    XModelManager.LoadWeaponModel(modelConfig.ModelId, self.PanelWeapon, modelConfig.TransformConfig, uiName, nil, { gameObject = self.GameObject })
end

function XUiFashion:UpdateWeaponWithCharacterModel()
    local characterId = self.CharacterList[self.CharacterIndex].Id
    local resourcesId = XDataCenter.FashionManager.GetFashionResourceIdByCharId(characterId)
    local func = function(model)
        self.PanelDrag:GetComponent("XDrag").Target = model.transform
        self:ShowImgEffectHuanren(characterId)
    end

    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.RoleModelPanel.GameObject:SetActiveEx(true)
    self.RoleModelPanel:UpdateCharacterResModel(resourcesId, characterId, XModelManager.MODEL_UINAME.XUiFashion, func, nil, self.CurWeaponFashionId)
end

function XUiFashion:UpdateWeaponButtonState()
    local characterId = self.CharacterList[self.CharacterIndex].Id
    local status = XDataCenter.WeaponFashionManager.GetFashionStatus(self.CurWeaponFashionId, characterId)
    local fashionStatus = XDataCenter.WeaponFashionManager.FashionStatus
    if status == fashionStatus.Dressed then
        self.PanelUnOwed.gameObject:SetActiveEx(false)
        self.BtnUse.gameObject:SetActiveEx(false)
        self.BtnUsed.gameObject:SetActiveEx(true)
    elseif status == fashionStatus.UnLock then
        self.PanelUnOwed.gameObject:SetActiveEx(false)
        self.BtnUse.gameObject:SetActiveEx(true)
        self.BtnUsed.gameObject:SetActiveEx(false)
    elseif status == fashionStatus.UnOwned then
        self.PanelUnOwed.gameObject:SetActiveEx(true)
        self.BtnUse.gameObject:SetActiveEx(false)
        self.BtnUsed.gameObject:SetActiveEx(false)
    end
end

function XUiFashion:AutoAddListener()
    self:RegisterClickEvent(self.BtnNext, self.OnBtnNextClick)
    self:RegisterClickEvent(self.BtnLast, self.OnBtnLastClick)
    self:RegisterClickEvent(self.BtnUse, self.OnBtnUseClick)
    self:RegisterClickEvent(self.BtnFashionUnLock, self.OnBtnFashionUnLockClick)
    self:RegisterClickEvent(self.BtnGet, self.OnBtnGetClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self.BtnLensOut.CallBack = function() self:OnBtnLensOut() end
    self.BtnLensIn.CallBack = function() self:OnBtnLensIn() end
    self.BtnSwitch.CallBack = function() self:OnSwitchWeaponViewType() end
    XUiHelper.RegisterSliderChangeEvent(self, self.SliderCharacter, self.OnSliderCharacterChanged)
end

function XUiFashion:OnBtnFashionUnLockClick()
    local fashionId = self.CurFashionId
    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)

    self.TxtUnlockFashionName.text = CSXTextManagerGetText("UiFashionUnlockName", template.Name)
    self.RImgFashionIcon:SetRawImage(template.Icon)
    self.ImgUnlockShowIcon.fillAmount = 0

    local animGo = self.PanelUnlockShow
    animGo.gameObject:SetActiveEx(true)
    self:PlayAnimationWithMask("AniPanelUnlockShowBegin", function()
        if XTool.UObjIsNil(animGo) then return end
        animGo.gameObject:SetActiveEx(false)

        XDataCenter.FashionManager.UnlockFashion(fashionId, function()
            local characterId = XDataCenter.FashionManager.GetCharacterId(fashionId)
            local isOwnCharacter = XDataCenter.CharacterManager.IsOwnCharacter(characterId)
            if isOwnCharacter then
                -- 拥有该角色，替换新涂装
                XDataCenter.FashionManager.UseFashion(fashionId,
                        function()
                            XUiManager.TipText("UseSuccess")
                            self:UpdateFashionList(true)
                        end,
                        function()
                            self:UpdateFashionList(nil, true)
                        end, true)
            end
            if XTool.UObjIsNil(self.GameObject) then return end

            self:ShowImgEffectHuanren(template.CharacterId)

            self:PlayUnLockAnimation()
            -- 拥有角色时，在穿戴涂装的协议回调中进行刷新
            if not isOwnCharacter then
                self:UpdateFashionList(nil, true)
            end
        end)
    end)
end

function XUiFashion:OnBtnBackClick()
    self:Close()
end

function XUiFashion:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFashion:OnBtnUseClick()
    if LastSelectedTabIndex == BtnTabIndex.Character then
        if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
            XDataCenter.NieRManager.NieRCharacterChangeFashion(XDataCenter.NieRManager.GetSelNieRCharacter():GetNieRCharacterId(), self.CurFashionId, function()
                XUiManager.TipText("UseSuccess")
                self:UpdateFashionList(true)
            end)
        else
            XDataCenter.FashionManager.UseFashion(self.CurFashionId, function()
                XUiManager.TipText("UseSuccess")
                self:UpdateFashionList(true)
            end)
        end
    elseif LastSelectedTabIndex == BtnTabIndex.Weapon then
        local characterId = self.CharacterList[self.CharacterIndex].Id
        XDataCenter.WeaponFashionManager.UseFashion(self.CurWeaponFashionId, characterId, function()
            XUiManager.TipText("UseSuccess")
            self:UpdateFashionList(true)
        end)
    end
end

function XUiFashion:OnBtnLastClick()
    local characterIndex = self.CharacterIndex
    if characterIndex > 1 then
        characterIndex = characterIndex - 1
        self:OnSelectCharacter(characterIndex)
        self:PlayAnimation("Qiehuan")
    end
end

function XUiFashion:OnBtnNextClick()
    local characterIndex = self.CharacterIndex
    if characterIndex < #self.CharacterList then
        characterIndex = characterIndex + 1
        self:OnSelectCharacter(characterIndex)
        self:PlayAnimation("Qiehuan")
    end
end

function XUiFashion:OnBtnGetClick()
    local templateId
    if LastSelectedTabIndex == BtnTabIndex.Character then
        templateId = self.CurFashionId
    elseif LastSelectedTabIndex == BtnTabIndex.Weapon then
        templateId = self.CurWeaponFashionId
    end
    if not templateId then
        return
    end

    local showSkipList = XGoodsCommonManager.GetGoodsShowSkipId(templateId)
    if showSkipList and next(showSkipList) then
        XLuaUiManager.Open("UiSkip", templateId, nil, nil, showSkipList)
    else
        XLuaUiManager.Open("UiTip", templateId)
    end
end

function XUiFashion:OnClickTabCallBack(tabIndex)
    LastSelectedTabIndex = tabIndex
    self:OnSelectCharacter(self.CharacterIndex or self.DefaultCharacterIndex)
end

function XUiFashion:OnBtnLensOut()
    self.BtnLensOut.gameObject:SetActiveEx(false)
    self.BtnLensIn.gameObject:SetActiveEx(true)
    self:UpdateCamera(CameraIndex.Near)
end

function XUiFashion:OnBtnLensIn()
    self.BtnLensOut.gameObject:SetActiveEx(true)
    self.BtnLensIn.gameObject:SetActiveEx(false)
    self:UpdateCamera(CameraIndex.Normal)
end

function XUiFashion:OnSliderCharacterChanged()
    local pos = self.CameraNear[CameraIndex.Near].position
    self.CameraNear[CameraIndex.Near].position = CS.UnityEngine.Vector3(pos.x, 1.7 - self.SliderCharacter.value, pos.z)
end

function XUiFashion:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.RoleModelPanel = XUiPanelRoleModel.New(root:FindTransform("UiModelParent"), self.Name, nil, true, nil, true)
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.CameraNear = {
        [CameraIndex.Normal] = root:FindTransform("FashionCamNearMain"),
        [CameraIndex.Near] = root:FindTransform("FashionCamNearest"),
    }
end

function XUiFashion:UpdateCamera(camera)
    for _, cameraIndex in pairs(CameraIndex) do
        self.CameraNear[cameraIndex].gameObject:SetActiveEx(cameraIndex == camera)
    end
end

function XUiFashion:PlayUnLockAnimation()
    local template = XDataCenter.FashionManager.GetFashionTemplate(self.CurFashionId)
    self.TxtDistanceDesc.text = template.Name

    local animGo = self.PanelAssistDistanceTip
    animGo.gameObject:SetActiveEx(true)
    self:PlayAnimation("AniPanelAssistDistanceTip", function()
        if XTool.UObjIsNil(animGo) then return end
        animGo.gameObject:SetActiveEx(false)
    end)
end

function XUiFashion:ResetPanelBtnLens()
    self.BtnLensIn.gameObject:SetActiveEx(false)
    self.BtnLensOut.gameObject:SetActiveEx(true)
    self.PanelBtnLens.gameObject:SetActiveEx(true)
end

function XUiFashion:ShowImgEffectHuanren(templateId)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    if templateId and XCharacterConfigs.IsIsomer(templateId) then
        self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
    else
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end
end