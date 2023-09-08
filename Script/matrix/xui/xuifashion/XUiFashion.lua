local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiPanelFashionList = require("XUi/XUiFashion/XUiPanelFashionList")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local stringFormat = string.format
local tableInsert = table.insert
local tableRemove = table.remove
local CameraIndex = {
    Normal = 1,
    Near = 2,
    Far = 3,
    FarNormal = 4,
}
local BtnTabIndex = {
    Character = 1, --成员涂装
    Weapon = 2, --武器涂装
    HeadPortrait = 3 --头像
}
local BtnTabIndexSide = {
    Fashion = 1, --涂装
    HeadPortrait = 2 --头像UiFashionDetailTitleWeapon
}
local LastSelectedTabIndex = BtnTabIndex.Character
local WeaponViewType = {
    WithCharacter = 1,
    OnlyWeapon = 2
}
local SwitchWeaponViewType = {
    [WeaponViewType.OnlyWeapon] = WeaponViewType.WithCharacter,
    [WeaponViewType.WithCharacter] = WeaponViewType.OnlyWeapon
}
local SwitchBtnName = {
    [WeaponViewType.OnlyWeapon] = CSXTextManagerGetText("UiFashionBtnNameCharacter"),
    [WeaponViewType.WithCharacter] = CSXTextManagerGetText("UiFashionBtnNameWeapon")
}

local XUiFashion = XLuaUiManager.Register(XLuaUi, "UiFashion")

function XUiFashion:OnAwake()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    ag = XMVCA:GetAgency(ModuleId.XCommonCharacterFilt)
    ---@type XCommonCharacterFiltAgency
    self.FiltAgecy = ag

    self.ExpiredRefreshNameList = {}

    self.BtnLensOut.gameObject:SetActiveEx(true)
    self.BtnLensIn.gameObject:SetActiveEx(false)
    self.PanelUnlockShow.gameObject:SetActiveEx(false)
    self.PanelAssistDistanceTip.gameObject:SetActiveEx(false)
    self.GridFashion.gameObject:SetActiveEx(false)
    self.GridWeapon.gameObject:SetActiveEx(false)
    self.GridHeadPortrait.gameObject:SetActiveEx(false)

    self.AssetPanel =    XUiPanelAsset.New(
    self,
    self.PanelAsset,
    XDataCenter.ItemManager.ItemId.FreeGem,
    XDataCenter.ItemManager.ItemId.ActionPoint,
    XDataCenter.ItemManager.ItemId.Coin
    )
    self.PanelCharacterFashionList =    XUiPanelFashionList.New(
    XUiPanelFashionList.GridType.FashionCharacter,
    self.ScrollFashionList,
    function(fashionId)
        self:OnSelectCharacterFashion(fashionId)
    end,
    self
    )
    self.PanelWeaponFashionList =    XUiPanelFashionList.New(
    XUiPanelFashionList.GridType.FashionWeapon,
    self.ScrollWeaponList,
    function(fashionId)
        self:OnSelectWeaponFashion(fashionId)
    end,
    self
    )
    self.PanelHeadPortraitList =    XUiPanelFashionList.New(
    XUiPanelFashionList.GridType.HeadPortrait,
    self.ScrollHeadPortrait,
    function(headInfo)
        self:OnSelectHeadPortrait(headInfo)
    end,
    self
    )
    self.PanelTagGroup:Init(
    {
        self.BtnTogCharacter,
        self.BtnTogWeapon,
        self.BtnTogHead,
    },
    function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end
    )
    -- self.PanelTabGroup:Init(
    -- {
    --     self.BtnFashion,
    --     self.BtnHeadPortrait
    -- },
    -- function(tabIndex)
    --     self:OnCharacterTabClick(tabIndex)
    -- end
    -- )
    self.OnUiSceneLoadedCB = function(lastSceneUrl)
        self:OnUiSceneLoaded(lastSceneUrl)
    end

    self:InitFilter()

    self:AutoAddListener()
end

function XUiFashion:InitFilter()
    self.PanelFilter = self.FiltAgecy:InitFilter(self.PanelCharacterFilter, self)
    local onSeleCb = function (character, index, grid)
        if not character then
            return
        end

        if self.CharacterId == character.Id then
            return
        end

        self:OnSelectCharacter(character.Id)
    end
    self.PanelFilter:InitData(onSeleCb)
    self.PanelFilter:Close()
end

function XUiFashion:OnStart(defaultCharacterId, isOnlyOneCharacter, notShowWeapon, openUiType)
    self:InitSceneRoot() --设置摄像机

    local characterList = self.CharacterAgency:GetCharacterList()
    -- local defaultCharacterIndex = 1
    -- if defaultCharacterId then
    --     self.CharacterId = defaultCharacterId
    --     for index, character in pairs(characterList) do
    --         if defaultCharacterId == character.Id then
    --             defaultCharacterIndex = index
    --             break
    --         end
    --     end
    -- end
    self.CharacterList = characterList
    self.DefaultCharacterId = defaultCharacterId

    self.PanelFilter:ImportList(characterList)
    self.PanelFilter:RefreshList()
    self.PanelFilter:DoSelectCharacter(defaultCharacterId)

    self.CurWeaponViewType = WeaponViewType.WithCharacter
    self.LastCharacterFashionSceneUrl = nil
    self.IsOnlyOneCharacter = isOnlyOneCharacter
    self.NotShowWeapon = notShowWeapon
    self.OpenUiType = openUiType

    if self.OpenUiType and (
            self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI 
                    or self.OpenUiType == XUiConfigs.OpenUiType.RobotFashion) then
        self.HideProtraitBtn = true
    end
    -- self.BtnHeadPortrait.gameObject:SetActiveEx(not self.HideProtraitBtn)
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
        self:UpdateWeaponFashionList()
        self:AddExpiredRefresh(...)
        self:OpenTipMsg()
    end
end

function XUiFashion:AddExpiredRefresh(fashionIds)
    if LastSelectedTabIndex ~= BtnTabIndex.Weapon then
        return
    end

    local characterId = self.CharacterId
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
        XUiManager.TipMsg(
        CSXTextManagerGetText("WeaponFashionNotOwnTipMsg", self.ExpiredRefreshNameList[1]),
        nil,
        function()
            tableRemove(self.ExpiredRefreshNameList, 1)
            self:OpenTipMsg()
        end
        )
    end
end

function XUiFashion:OnUiSceneLoaded(lastSceneUrl)
    if lastSceneUrl ~= self.LastCharacterFashionSceneUrl then
        --self:SetGameObject()
        self:InitSceneRoot()
        self.LastCharacterFashionSceneUrl = lastSceneUrl
    end
end

function XUiFashion:OnClickTabCallBack(tabIndex)
    LastSelectedTabIndex = tabIndex
    self:OnSelectCharacter(self.CharacterId or self.DefaultCharacterId)
    self:PlayAnimation("QieHuan")
end

-- 右上角的buttonGroup不需要了  全部放左边
function XUiFashion:OnCharacterTabClick(tabIndex)
    -- if LastSelectedTabIndex == BtnTabIndex.Weapon then
    --     return
    -- end

    -- self.SelectedFashionHeadIndex = tabIndex
    self:UpdateFashionList()
end

function XUiFashion:UpdateRedPoint()
    local isRed = XDataCenter.FashionManager.GetCurrCharHaveCanUnlockFashion(self.CharacterId)
    self.BtnTogCharacter:ShowReddot(isRed)
end

function XUiFashion:UpdateCountForBtn()
    local characterId = self.CharacterId
    --成员头像数量
    local haveCount, totalCount = 0, #self.HeadList
    for _, headInfo in pairs(self.HeadList) do
        if XDataCenter.FashionManager.IsFashionHeadUnLock(headInfo.HeadFashionId, headInfo.HeadFashionType, characterId) then
            haveCount = haveCount + 1
        end
    end
    self.BtnTogHead:SetNameByGroup(1, haveCount.."/"..totalCount)
    
    --成员涂装数量
    local haveCount, totalCount = 0, 0
    local fashionStatus = XDataCenter.FashionManager.FashionStatus
    local fashionList = self.FashionList
    if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
        haveCount = #fashionList
    else
        for _, fashionId in pairs(fashionList) do
            local status = XDataCenter.FashionManager.GetFashionStatus(fashionId)
            if status ~= fashionStatus.UnOwned then
                haveCount = haveCount + 1
            end
        end
    end
    totalCount = #fashionList
    self.BtnTogCharacter:SetNameByGroup(1, haveCount.."/"..totalCount)

    -- 武器涂装数量
    local fashionStatus = XDataCenter.WeaponFashionManager.FashionStatus
    local fashionList = XDataCenter.WeaponFashionManager.GetSortedWeaponFashionIdsByCharacterId(characterId)
    local haveCount, totalCount = 0, 0
    for _, fashionId in pairs(fashionList) do
        local status = XDataCenter.WeaponFashionManager.GetFashionStatus(fashionId, characterId)
        if status ~= fashionStatus.UnOwned then
            haveCount = haveCount + 1
        end
    end
    totalCount = #fashionList
    self.BtnTogWeapon:SetNameByGroup(1, haveCount.."/"..totalCount)
end

function XUiFashion:UpdateFashionData()
    if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
        local nierCharacter = XDataCenter.NieRManager.GetSelNieRCharacter()
        self.FashionList = nierCharacter:GetNieRFashionList()
    else
        self.FashionList = XDataCenter.FashionManager.GetCurrentTimeFashionByCharId(self.CharacterId)
    end

    local char = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    self.ToggleRandomFashion.gameObject:SetActiveEx(false)
    self.BtnRandomFashion.gameObject:SetActiveEx(false)
    self.BtnBan.gameObject:SetActiveEx(false)

    self:UpdateRedPoint()            
    self:UpdateCountForBtn()
end

function XUiFashion:OnSelectCharacter(characterId)
    -- self.LastSelectCharacterId = characterId
    self.CharacterId = characterId
    self.HeadList = XDataCenter.FashionManager.GetFashionHeadPortraitList(self.CharacterId)
    self:UpdateFashionData()
    self.CurFashionId = self.FashionList[1]

    if LastSelectedTabIndex == BtnTabIndex.Character then
        self:OnCharacterTabClick()
        -- if not self.HideProtraitBtn then
            -- self.BtnHeadPortrait.gameObject:SetActiveEx(true)
            -- self.PanelTabGroup:SelectIndex(BtnTabIndexSide.Fashion)
        -- else
            -- self.PanelTabGroup:SelectIndex(self.SelectedFashionHeadIndex or BtnTabIndexSide.Fashion)
        -- end
    elseif LastSelectedTabIndex == BtnTabIndex.Weapon then
        -- self.BtnHeadPortrait.gameObject:SetActiveEx(false)
        -- self.BtnFashion:SetButtonState(CS.UiButtonState.Select)
        self:UpdateWeaponFashionList()
    elseif LastSelectedTabIndex == BtnTabIndex.HeadPortrait then
        self:UpdateHeadPortraitList()
    end
    self:OnBtnCloseFilterClick()
    self:RefreshRandomFashionBtns()

    local syncChar = self.CharacterAgency:GetCharacter(characterId)
    XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_CHANGE_SYNC_SYSTEM, syncChar)
end

function XUiFashion:UpdateFashionList(selectDressing, doNotReset)
    if LastSelectedTabIndex ~= BtnTabIndex.Character then
        return
    end

    local defaultSelectId, dressedId
    self:UpdateFashionData()
    local fashionStatus = XDataCenter.FashionManager.FashionStatus
    local fashionList = self.FashionList
    if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
        local nierCharacter = XDataCenter.NieRManager.GetSelNieRCharacter()
        dressedId = nierCharacter:GetNieRFashionId()
    else
        for _, fashionId in pairs(fashionList) do
            local status = XDataCenter.FashionManager.GetFashionStatus(fashionId)
            if status == fashionStatus.Dressed then
                dressedId = fashionId
            end
        end
    end
    defaultSelectId = selectDressing and dressedId or fashionList[1]
    defaultSelectId = not doNotReset and defaultSelectId or nil

    self.PanelCharacterFashionList:UpdateViewList(fashionList, defaultSelectId)
    self.PanelCharacterFashionList.GameObject:SetActiveEx(true)
    self.PanelHeadPortraitList.GameObject:SetActiveEx(false)
    self.PanelWeaponFashionList.GameObject:SetActiveEx(false)
end

function XUiFashion:UpdateWeaponFashionList(selectDressing, doNotReset)
    if LastSelectedTabIndex ~= BtnTabIndex.Weapon then
        return
    end

    local characterId = self.CharacterId
    local fashionList = XDataCenter.WeaponFashionManager.GetSortedWeaponFashionIdsByCharacterId(characterId)

    local defaultSelectId, dressedId
    defaultSelectId = fashionList[1]
    defaultSelectId = not doNotReset and defaultSelectId or nil

    self.PanelWeaponFashionList:UpdateViewList(fashionList, defaultSelectId, characterId)
    self.PanelWeaponFashionList.GameObject:SetActiveEx(true)
    self.PanelCharacterFashionList.GameObject:SetActiveEx(false)
    self.PanelHeadPortraitList.GameObject:SetActiveEx(false)
    -- self.BtnHeadPortrait.gameObject:SetActiveEx(false)
end

function XUiFashion:UpdateHeadPortraitList(refresh)
    local characterId = self.CharacterId
    if refresh then
        self.HeadList = XDataCenter.FashionManager.GetFashionHeadPortraitList(self.CharacterId)
    end
    local headList = self.HeadList

    self.PanelHeadPortraitList:UpdateViewList(headList, headList[1], characterId)
    self.PanelHeadPortraitList.GameObject:SetActiveEx(true)
    self.PanelWeaponFashionList.GameObject:SetActiveEx(false)
    self.PanelCharacterFashionList.GameObject:SetActiveEx(false)
    self.BtnFashionUnLock.gameObject:SetActiveEx(false)
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
        sceneUrl = self.CharacterAgency:GetCharShowFashionSceneUrl(self.CharacterId)
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
        self.RoleModelPanel:UpdateCharacterResModel(
        template.ResourcesId,
        template.CharacterId,
        XModelManager.MODEL_UINAME.XUiFashion,
        func
        )
        self.PanelWeapon.gameObject:SetActiveEx(false)
        self.RoleModelPanel.GameObject:SetActiveEx(true)
        self.PanelBtnSwitch.gameObject:SetActiveEx(false)
        self:ResetPanelBtnLens()
        self:UpdateFashionIntro(self.CurFashionId)
    else
        self.TxtFashionName.text = ""
        self.PanelWeapon.gameObject:SetActiveEx(false)
        self.RoleModelPanel.GameObject:SetActiveEx(false)
        self.PanelBtnSwitch.gameObject:SetActiveEx(false)
        self.PanelBtnLens.gameObject:SetActiveEx(false)
        self.BtnUsed.gameObject:SetActiveEx(false)
        self.PanelUnOwed.gameObject:SetActiveEx(false)
        self.BanParent.gameObject:SetActiveEx(true)
        self.BtnUse.gameObject:SetActiveEx(false)
    end
end

function XUiFashion:UpdateButtonState()
    local PanelUnOwed = nil
    local BtnUse = nil
    local BtnUsed = nil
    local BtnFashionUnLock = nil
    local BanParent = nil

    if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
        local nierCharacter = XDataCenter.NieRManager.GetSelNieRCharacter()
        local dressedId = nierCharacter:GetNieRFashionId()
        if self.CurFashionId == dressedId then
            PanelUnOwed = false
            BtnUse = false
            BtnUsed = true
            BtnFashionUnLock = false
        else
            PanelUnOwed = false
            BtnUse = true
            BtnUsed = false
            BtnFashionUnLock = false
        end
    else
        local status = XDataCenter.FashionManager.GetFashionStatus(self.CurFashionId)
        local fashionStatus = XDataCenter.FashionManager.FashionStatus
        if status == fashionStatus.Dressed then
            PanelUnOwed = false
            BtnUse = false
            BtnUsed = true
            BtnFashionUnLock = false
        elseif status == fashionStatus.UnLock then
            PanelUnOwed = false
            BtnUse = true
            BtnUsed = false
            BtnFashionUnLock = false
        elseif status == fashionStatus.Lock then
            PanelUnOwed = false
            BtnUse = false
            BtnUsed = false
            BtnFashionUnLock = true
        elseif status == fashionStatus.UnOwned then
            PanelUnOwed = true
            BtnUse = false
            BtnUsed = false
            BtnFashionUnLock = false
        end
    end
    BanParent = not PanelUnOwed

    self.PanelUnOwed.gameObject:SetActiveEx(PanelUnOwed)
    self.BtnUse.gameObject:SetActiveEx(BtnUse)
    self.BtnUsed.gameObject:SetActiveEx(BtnUsed)
    self.BtnFashionUnLock.gameObject:SetActiveEx(BtnFashionUnLock)
    self.BanParent.gameObject:SetActiveEx(BanParent)

    local template = XDataCenter.FashionManager.GetFashionTemplate(self.CurFashionId)
    self.TxtFashionName.text = template.Name

    self.PanelHeadLock.gameObject:SetActiveEx(false)
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
        self:ResetPanelBtnLens()
        self:LoadModelScene()
        self:UpdateWeaponWithCharacterModel()
    elseif newType == WeaponViewType.OnlyWeapon then
        self.PanelBtnLens.gameObject:SetActiveEx(false)
        self:LoadModelScene(true)
        self:UpdateWeaponModel()
    end

    local characterId = self.CharacterId
    local fashionName = XDataCenter.WeaponFashionManager.GetWeaponFashionName(self.CurWeaponFashionId, characterId)
    self.TxtFashionName.text = fashionName
    self:UpdateFashionIntro(self.CurWeaponFashionId)

    self.BtnSwitch:SetNameByGroup(0, SwitchBtnName[newType])
    self.PanelBtnSwitch.gameObject:SetActiveEx(true)
    self.BtnFashionUnLock.gameObject:SetActiveEx(false)

    self:UpdateCamera(CameraIndex.Normal)
end

function XUiFashion:UpdateFashionIntro(fashionId)
    local intro, title, content = "", "", ""
    if LastSelectedTabIndex == BtnTabIndex.HeadPortrait then
        --成员头像
        content = XDataCenter.FashionManager.GetFashionHeadUnlockConditionDesc(self.HeadInfo.HeadFashionType, self.HeadInfo.HeadFashionId)
        intro = CsXTextManagerGetText("UiFashionIntroHeadPortrait")
    else
        --武器涂装/成员涂装
        local characterId = self.CharacterId
        local isDefaultId = XWeaponFashionConfigs.IsDefaultId(fashionId)
        if isDefaultId then
            if not self.CharacterAgency:IsOwnCharacter(characterId) then
                fashionId = XMVCA.XCharacter:GetCharacterDefaultEquipId(characterId)
            else
                local equipId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
                fashionId = XDataCenter.EquipManager.GetEquipTemplateId(equipId)
            end
        end

        title = XGoodsCommonManager.GetGoodsDescription(fashionId)
        content = XGoodsCommonManager.GetGoodsWorldDesc(fashionId)

        if isDefaultId then
            content = title
            if string.IsNilOrEmpty(content) then
                local archiveCfg = XArchiveConfigs.GetWeaponSettingList(fashionId, XArchiveConfigs.SettingType.Setting)
                if next(archiveCfg) then
                    content = archiveCfg[1].Text
                end
            end
            title = nil
        end

        intro = CsXTextManagerGetText("UiFashionIntroFashion")
    end

    self.TxtTipTitle.text = intro

    self.TxtIntroTitle.gameObject:SetActiveEx(not string.IsNilOrEmpty(title))
    self.TxtIntroTitle.text = title

    self.TxtIntroDesc.gameObject:SetActiveEx(not string.IsNilOrEmpty(content))
    self.TxtIntroDesc.text = content
end

function XUiFashion:UpdateWeaponModel()
    local characterId = self.CharacterId
    local uiName = XModelManager.MODEL_UINAME.XUiFashion
    local modelConfig = XDataCenter.WeaponFashionManager.GetWeaponModelCfg(self.CurWeaponFashionId, characterId, uiName)

    self.RoleModelPanel.GameObject:SetActiveEx(false)
    self.PanelWeapon.gameObject:SetActiveEx(true)
    XModelManager.LoadWeaponModel(
    modelConfig.ModelId,
    self.PanelWeapon,
    modelConfig.TransformConfig,
    uiName,
    function()
        --v1.30版本针对涂装，临时处理 todo, CodeMoon 待优化
        if self.RoleModelPanel.CurRoleName == "R3WeilaMd019331" then
            local camera = self.ModelCamera[CameraIndex.Normal]
            camera.transform.localPosition = CS.UnityEngine.Vector3(0.4, 1.7, -26.22)
            camera.transform.localEulerAngles = CS.UnityEngine.Vector3(4.995, 0.6, 0)
        end
    end,
    { gameObject = self.GameObject, IsDragRotation = true },
    self.PanelDrag
    )
end

function XUiFashion:UpdateWeaponWithCharacterModel()
    local characterId = self.CharacterId
    local resourcesId = XDataCenter.FashionManager.GetFashionResourceIdByCharId(characterId)
    local func = function(model)
        self.PanelDrag:GetComponent("XDrag").Target = model.transform
        self:ShowImgEffectHuanren(characterId)
    end

    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.RoleModelPanel.GameObject:SetActiveEx(true)
    self.RoleModelPanel:UpdateCharacterResModel(
    resourcesId,
    characterId,
    XModelManager.MODEL_UINAME.XUiFashion,
    func,
    nil,
    self.CurWeaponFashionId
    )
end

function XUiFashion:UpdateWeaponButtonState()
    local characterId = self.CharacterId
    local status = XDataCenter.WeaponFashionManager.GetFashionStatus(self.CurWeaponFashionId, characterId)
    local fashionStatus = XDataCenter.WeaponFashionManager.FashionStatus

    local PanelUnOwed = nil
    local BtnUse = nil
    local BtnUsed = nil
    local BtnFashionUnLock = nil
    local BanParent = nil

    if status == fashionStatus.Dressed then
        PanelUnOwed = false
        BtnUse = false
        BtnUsed = true
        BtnFashionUnLock = false
    elseif status == fashionStatus.UnLock then
        PanelUnOwed = false
        BtnUse = true
        BtnUsed = false
        BtnFashionUnLock = false
    elseif status == fashionStatus.UnOwned then
        PanelUnOwed = true
        BtnUse = false
        BtnUsed = false
        BtnFashionUnLock = false
    end
    BanParent = not PanelUnOwed

    self.PanelUnOwed.gameObject:SetActiveEx(PanelUnOwed)
    self.BtnUse.gameObject:SetActiveEx(BtnUse)
    self.BtnUsed.gameObject:SetActiveEx(BtnUsed)
    self.BtnFashionUnLock.gameObject:SetActiveEx(BtnFashionUnLock)
    self.BanParent.gameObject:SetActiveEx(BanParent)
end

function XUiFashion:OnSelectHeadPortrait(headInfo)
    self.HeadInfo = headInfo
    self:UpdateSceneAndModel()
    self:UpdateHeadPortraitButtonState()
end

function XUiFashion:UpdateHeadPortraitButtonState()
    local characterId = self.CharacterId
    local headInfo = self.HeadInfo
    local isUnLock = XDataCenter.FashionManager.IsFashionHeadUnLock(headInfo.HeadFashionId, headInfo.HeadFashionType, characterId)
    local isUsing = XDataCenter.FashionManager.IsFashionHeadUsing(headInfo.HeadFashionId, headInfo.HeadFashionType, characterId)

    if isUsing then --已穿戴
        self.PanelHeadLock.gameObject:SetActiveEx(false)
        self.PanelUnOwed.gameObject:SetActiveEx(false)
        self.BtnUse.gameObject:SetActiveEx(false)
        self.BtnUsed.gameObject:SetActiveEx(true)
    elseif isUnLock then --已解锁
        self.PanelHeadLock.gameObject:SetActiveEx(false)
        self.PanelUnOwed.gameObject:SetActiveEx(false)
        self.BtnUse.gameObject:SetActiveEx(true)
        self.BtnUsed.gameObject:SetActiveEx(false)
    else -- 未获得
        self.BtnUse.gameObject:SetActiveEx(false)
        self.BtnUsed.gameObject:SetActiveEx(false)
        self.PanelUnOwed.gameObject:SetActiveEx(false)
        self.PanelHeadLock.gameObject:SetActiveEx(true)
    end

    local template = XDataCenter.FashionManager.GetFashionTemplate(self.HeadInfo.HeadFashionId)
    local str = template.Name
    if self.HeadInfo.HeadFashionType == XFashionConfigs.HeadPortraitType.Liberation then
        str = CS.XTextManager.GetText("FashionHeadLiberation")
    end
    self.TxtFashionName.text = str
end

function XUiFashion:AutoAddListener()
    self:RegisterClickEvent(self.BtnUse, self.OnBtnUseClick)
    self:RegisterClickEvent(self.BtnFashionUnLock, self.OnBtnFashionUnLockClick)
    self:RegisterClickEvent(self.BtnGet, self.OnBtnGetClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnCharacterFilter, self.OnBtnCharacterFilterClick)
    self:RegisterClickEvent(self.BtnCloseFilter, self.OnBtnCloseFilterClick)
    self:RegisterClickEvent(self.ToggleRandomFashion, self.OnToggleRandomFashionClick)
    self:RegisterClickEvent(self.BtnRandomFashion, self.OnBtnRandomFashionClick)
    self.BtnLensOut.CallBack = function()
        self:OnBtnLensOut()
    end
    self.BtnLensIn.CallBack = function()
        self:OnBtnLensIn()
    end
    self.BtnSwitch.CallBack = function()
        self:OnSwitchWeaponViewType()
    end
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
    self:PlayAnimationWithMask(
    "AniPanelUnlockShowBegin",
    function()
        if XTool.UObjIsNil(animGo) then
            return
        end
        animGo.gameObject:SetActiveEx(false)

        XDataCenter.FashionManager.UnlockFashion(
        fashionId,
        function()
            local characterId = XDataCenter.FashionManager.GetCharacterId(fashionId)
            local isOwnCharacter = self.CharacterAgency:IsOwnCharacter(characterId)
            if isOwnCharacter then
                -- 拥有该角色，替换新涂装
                XDataCenter.FashionManager.UseFashion(
                fashionId,
                function()
                    XUiManager.TipText("UseSuccess")
                    self:UpdateFashionList(true)
                end,
                function()
                    self:UpdateFashionList(nil, true)
                end,
                true
                )
            end
            if XTool.UObjIsNil(self.GameObject) then
                return
            end

            self:ShowImgEffectHuanren(template.CharacterId)

            self:PlayUnLockAnimation()
            -- 拥有角色时，在穿戴涂装的协议回调中进行刷新
            if not isOwnCharacter then
                self:UpdateFashionList(nil, true)
            end
        end
        )
    end
    )
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
            XDataCenter.NieRManager.NieRCharacterChangeFashion(
            XDataCenter.NieRManager.GetSelNieRCharacter():GetNieRCharacterId(),
            self.CurFashionId,
            function()
                XUiManager.TipText("UseSuccess")
                self:UpdateFashionList(true)
            end
            )
        else
            XDataCenter.FashionManager.UseFashion(
            self.CurFashionId,
            function()
                XUiManager.TipText("UseSuccess")
                self:UpdateFashionList(true)
            end
            )
        end
    elseif LastSelectedTabIndex == BtnTabIndex.Weapon then
        local characterId = self.CharacterId
        XDataCenter.WeaponFashionManager.UseFashion(
        self.CurWeaponFashionId,
        characterId,
        function()
            XUiManager.TipText("UseSuccess")
            self:UpdateWeaponFashionList(true)
        end
        )
    elseif LastSelectedTabIndex == BtnTabIndex.HeadPortrait then
        if not self.CharacterAgency:IsOwnCharacter(self.CharacterId) then
            XUiManager.TipText("CharacterLock")
            return
        end

        local headInfo = self.HeadInfo
        self.CharacterAgency:CharacterSetHeadInfoRequest(
        self.CharacterId,
        headInfo.HeadFashionId,
        headInfo.HeadFashionType,
        function()
            XUiManager.TipText("UseSuccess")
            self:UpdateHeadPortraitList(true)
        end
        )
    end
end

function XUiFashion:RefreshRandomFashionBtns()
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    if not character then
        return
    end

    if character.RandomFashion then
        self.ToggleRandomFashion.isOn = true
    else
        self.ToggleRandomFashion.isOn = false
    end
    -- self.BtnRandomFashion.gameObject:SetActiveEx(character.RandomFashion)
    -- self.BtnBan.gameObject:SetActiveEx(character.RandomFashion)
    self.UseParent.gameObject:SetActiveEx(not character.RandomFashion)
end

function XUiFashion:OnToggleRandomFashionClick()
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    if not character then
        return
    end

    local targetState = nil
    if character.RandomFashion then
        targetState = false
    else
        targetState = true
    end
    XDataCenter.FashionManager.FashionRandomActiveRequest(self.CharacterId, targetState, function ()
        self:RefreshRandomFashionBtns()
    end)
end

function XUiFashion:OnBtnRandomFashionClick()
    XLuaUiManager.Open("UiFashionRandom", self.CharacterId)
end

function XUiFashion:OnBtnCloseFilterClick()
    self.PanelCharacterFilter.gameObject:SetActiveEx(false)
    self.PanelTagGroup.gameObject:SetActiveEx(true)
    self.PanelFilter:Close()
end

function XUiFashion:OnBtnCharacterFilterClick()
    self:ShowOrHideFilter()
end

function XUiFashion:ShowOrHideFilter()
    local activeSelf = nil
    activeSelf = self.PanelCharacterFilter.gameObject.activeSelf
    self.PanelCharacterFilter.gameObject:SetActiveEx(not activeSelf)
    -- 打开的时候刷新
    if not activeSelf then
        self.PanelFilter:DoSelectTag("BtnAll")
        self.PanelFilter:DoSelectCharacter(self.CharacterId)
        self.PanelFilter:Open()
    else
        self.PanelFilter:Close()
    end

    activeSelf = self.PanelTagGroup.gameObject.activeSelf
    self.PanelTagGroup.gameObject:SetActiveEx(not activeSelf)
end

-- function XUiFashion:OnBtnLastClick()
--     local characterIndex = self.LastSelectCharacterId
--     if characterIndex > 1 then
--         characterIndex = characterIndex - 1
--         self:OnSelectCharacter(characterIndex)
--         self:PlayAnimation("Qiehuan")
--     end
-- end

-- function XUiFashion:OnBtnNextClick()
--     local characterIndex = self.LastSelectCharacterId
--     if characterIndex < #self.CharacterList then
--         characterIndex = characterIndex + 1
--         self:OnSelectCharacter(characterIndex)
--         self:PlayAnimation("Qiehuan")
--     end
-- end

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
    local pos = self.ModelCamera[CameraIndex.Near].position
    self.ModelCamera[CameraIndex.Near].position = CS.UnityEngine.Vector3(pos.x, 1.7 - self.SliderCharacter.value, pos.z)
    self.ModelCamera[CameraIndex.Far].position = CS.UnityEngine.Vector3(pos.x, 1.7 - self.SliderCharacter.value, pos.z)
end

function XUiFashion:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.RoleModelPanel = XUiPanelRoleModel.New(root:FindTransform("UiModelParent"), self.Name, nil, true, nil, true)
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.ModelCamera = {
        [CameraIndex.Normal] = root:FindTransform("FashionCamNearMain"),
        [CameraIndex.Near] = root:FindTransform("FashionCamNearest"),
        [CameraIndex.FarNormal] = root:FindTransform("FashionCamFarMain"),
        [CameraIndex.Far] = root:FindTransform("FashionCamFarest"),
    }
    self:OnSliderCharacterChanged()
end

function XUiFashion:UpdateCamera(index)
    self.ModelCamera[CameraIndex.Normal].gameObject:SetActiveEx(CameraIndex.Normal == index)
    self.ModelCamera[CameraIndex.FarNormal].gameObject:SetActiveEx(CameraIndex.Normal == index)
    self.ModelCamera[CameraIndex.Near].gameObject:SetActiveEx(CameraIndex.Normal ~= index)
    self.ModelCamera[CameraIndex.Far].gameObject:SetActiveEx(CameraIndex.Normal ~= index)
end

function XUiFashion:PlayUnLockAnimation()
    local template = XDataCenter.FashionManager.GetFashionTemplate(self.CurFashionId)
    self.TxtDistanceDesc.text = template.Name

    local animGo = self.PanelAssistDistanceTip
    animGo.gameObject:SetActiveEx(true)
    self:PlayAnimation(
    "AniPanelAssistDistanceTip",
    function()
        if XTool.UObjIsNil(animGo) then
            return
        end
        animGo.gameObject:SetActiveEx(false)
    end
    )
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