local XUiGridBfrtCharacter = require("XUi/XUiBfrt/BattleRoom/XUiGridBfrtCharacter")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local CSXTextManagerGetText = CS.XTextManager.GetText
local ANIMATION_OPEN = "AniBfrtRoomCharacterBegin"
local CONDITION_HEX_COLOR = {
    [true] = "000000FF",
    [false] = "BC0F23FF",
}
local TabBtnIndex = {
    Normal = 1,
    Isomer = 2,
}
local CharacterTypeConvert = {
    [TabBtnIndex.Normal] = XEnumConst.CHARACTER.CharacterType.Normal,
    [TabBtnIndex.Isomer] = XEnumConst.CHARACTER.CharacterType.Isomer,
}
local TabBtnIndexConvert = {
    [XEnumConst.CHARACTER.CharacterType.Normal] = TabBtnIndex.Normal,
    [XEnumConst.CHARACTER.CharacterType.Isomer] = TabBtnIndex.Isomer,
}

---@class XUiBfrtRoomCharacter:XLuaUi
local XUiBfrtRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiBfrtRoomCharacter")

function XUiBfrtRoomCharacter:OnAwake()
    self:InitAutoScript()
    self:InitComponentState()

    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)

    self.GridIndex = {}
    self.TagCacheDic = {}
    self.SortFunction = {}
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default] = function(leftCharacter, rightCharacter)
        local leftNotInTeam = not self:CheckCharacterInTeam(leftCharacter.Id)
        local leftNotInTeamList = self.CheckIsInTeamListCb(leftCharacter.Id) == nil
        local leftAbility = leftCharacter.Ability
        local leftLevel = leftCharacter.Level
        local leftQuality = leftCharacter.Quality
        local leftPriority = XMVCA.XCharacter:GetCharacterPriority(leftCharacter.Id)

        local rightNotInTeam = not self:CheckCharacterInTeam(rightCharacter.Id)
        local rightNotInTeamList = self.CheckIsInTeamListCb(rightCharacter.Id) == nil
        local rightAbility = rightCharacter.Ability
        local rightLevel = rightCharacter.Level
        local rightQuality = rightCharacter.Quality
        local rightPriority = XMVCA.XCharacter:GetCharacterPriority(rightCharacter.Id)

        if leftNotInTeam ~= rightNotInTeam then
            return leftNotInTeam
        end

        if leftNotInTeamList ~= rightNotInTeamList then
            return leftNotInTeamList
        end

        if leftAbility ~= rightAbility then
            return leftAbility > rightAbility
        end

        if leftLevel ~= rightLevel then
            return leftLevel > rightLevel
        end

        if leftQuality ~= rightQuality then
            return leftQuality > rightQuality
        end

        return leftPriority < rightPriority
    end
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Quality] = function(leftCharacter, rightCharacter)
        local leftQuality = leftCharacter.Quality
        local rightQuality = rightCharacter.Quality
        if leftQuality ~= rightQuality then
            return leftQuality > rightQuality
        end
        return self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default](leftCharacter, rightCharacter)
    end
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Level] = function(leftCharacter, rightCharacter)
        local leftLevel = leftCharacter.Level
        local rightLevel = rightCharacter.Level
        if leftLevel ~= rightLevel then
            return leftLevel > rightLevel
        end
        return self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default](leftCharacter, rightCharacter)
    end
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Ability] = function(leftCharacter, rightCharacter)
        local leftAbility = leftCharacter.Ability
        local rightAbility = rightCharacter.Ability
        if leftAbility ~= rightAbility then
            return leftAbility > rightAbility
        end
        return self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default](leftCharacter, rightCharacter)
    end

    self.CharacterGrids = {}
end

function XUiBfrtRoomCharacter:OnStart(viewData)
    self:UpdateViewData(viewData)
    self:UpdateTxtRequireAbility()
    self:PlayAnimation(ANIMATION_OPEN)

    XEventManager.AddEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.UpdateTeamPrefab, self)
end

function XUiBfrtRoomCharacter:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.UpdateTeamPrefab, self)
end

function XUiBfrtRoomCharacter:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    self:UpdateCurCharacterGrid()
end

function XUiBfrtRoomCharacter:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiBfrtRoomCharacter:InitComponentState()
    self.GridBfrtCharacter.gameObject:SetActiveEx(false)
    self.BtnJoinTeam.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiBfrtRoomCharacter:UpdateViewData(viewData)
    if not viewData.TeamCharacterIdList or not viewData.TeamSelectPos then
        XLog.Error("XUiBfrtRoomCharacter:UpdateViewData error: TeamCharacterIdList or TeamSelectPos do not exist!")
        return
    end

    self.EchelonId = viewData.EchelonId
    self.GroupId = viewData.BfrtGroupId
    self.StageId = viewData.StageId
    self.RequireAbility = viewData.RequireAbility
    self.TeamCharacterIdList = viewData.TeamCharacterIdList
    self.TeamSelectPos = viewData.TeamSelectPos
    self.EchelonIndex = viewData.EchelonIndex
    self.EchelonType = viewData.EchelonType
    self.CheckIsInTeamListCb = viewData.CheckIsInTeamListCb
    self.CharacterSwapEchelonCb = viewData.CharacterSwapEchelonCb
    self.TeamResultCb = viewData.TeamResultCb
    self.EchelonRequireCharacterNum = viewData.EchelonRequireCharacterNum
    self.CharacterLimitType = XFubenConfigs.GetStageCharacterLimitType(self.StageId)
    self.LimitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(self.StageId)

    self:InitRequireCharacterInfo()
    self:InitCharacterTypeBtns()
end

function XUiBfrtRoomCharacter:InitRequireCharacterInfo()
    local characterLimitType = self.CharacterLimitType

    if not XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType) then
        self.PanelRequireCharacter.gameObject:SetActiveEx(false)
        return
    else
        self.PanelRequireCharacter.gameObject:SetActiveEx(true)
    end

    local icon = XFubenConfigs.GetStageCharacterLimitImageTeamEdit(characterLimitType)
    self.ImgRequireCharacter:SetSprite(icon)
end

function XUiBfrtRoomCharacter:ResetTeamData()
    self.TeamCharacterIdList = { 0, 0, 0 }
end

function XUiBfrtRoomCharacter:RefreshCharacterTypeTips()
    local limitBuffId = self.LimitBuffId
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    local characterLimitType = self.CharacterLimitType
    local text = XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, limitBuffId)
    self.TxtRequireCharacter.text = text
end

function XUiBfrtRoomCharacter:InitCharacterTypeBtns()
    self.BtnTabShougezhe.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Isomer))

    local tabBtns = { self.BtnTabGouzaoti, self.BtnTabShougezhe }
    self.PanelCharacterTypeBtns:Init(tabBtns, function(index) self:TrySelectCharacterType(index) end)

    local characterLimitType = self.CharacterLimitType
    local lockGouzaoti = characterLimitType == XFubenConfigs.CharacterLimitType.Isomer
    local lockShougezhe = not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer) or characterLimitType == XFubenConfigs.CharacterLimitType.Normal
    self.BtnTabGouzaoti:SetDisable(lockGouzaoti)
    self.BtnTabShougezhe:SetDisable(lockShougezhe)

    --检查选择角色类型是否和副本限制类型冲突
    local characterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(self.CharacterLimitType)
    local tempCharacterType = self:GetTeamCharacterType()
    if tempCharacterType and not (tempCharacterType == XEnumConst.CHARACTER.CharacterType.Normal and lockGouzaoti
    or tempCharacterType == XEnumConst.CHARACTER.CharacterType.Isomer and lockShougezhe) then
        characterType = tempCharacterType
    end
    self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndexConvert[characterType])
end

function XUiBfrtRoomCharacter:TrySelectCharacterType(index)
    local characterType = CharacterTypeConvert[index]
    if characterType == XEnumConst.CHARACTER.CharacterType.Isomer and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer) then return end

    local characterLimitType = self.CharacterLimitType
    if characterLimitType == XFubenConfigs.CharacterLimitType.Normal then
        if characterType == XEnumConst.CHARACTER.CharacterType.Isomer then
            XUiManager.TipText("TeamSelectCharacterTypeLimitTipNormal")
            return
        end
    elseif characterLimitType == XFubenConfigs.CharacterLimitType.Isomer then
        if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
            XUiManager.TipText("TeamSelectCharacterTypeLimitTipIsomer")
            return
        end
        -- elseif characterLimitType == XFubenConfigs.CharacterLimitType.IsomerDebuff then
        --     if characterType == XEnumConst.CHARACTER.CharacterType.Isomer then
        --         local buffDes = XFubenConfigs.GetBuffDes(self.LimitBuffId)
        --         local content = CSXTextManagerGetText("TeamSelectCharacterTypeLimitTipIsomerDebuff", buffDes)
        --         local sureCallBack = function()
        --             self:OnSelectCharacterType(index)
        --         end
        --         local closeCallback = function()
        --             self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndexConvert[XEnumConst.CHARACTER.CharacterType.Normal])
        --         end
        --         XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, closeCallback, sureCallBack)
        --         return
        --     end
        -- elseif characterLimitType == XFubenConfigs.CharacterLimitType.NormalDebuff then
        --     if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
        --         local buffDes = XFubenConfigs.GetBuffDes(self.LimitBuffId)
        --         local content = CSXTextManagerGetText("TeamSelectCharacterTypeLimitTipNormalDebuff", buffDes)
        --         local sureCallBack = function()
        --             self:OnSelectCharacterType(index)
        --         end
        --         local closeCallback = function()
        --             self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndexConvert[XEnumConst.CHARACTER.CharacterType.Isomer])
        --         end
        --         XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, closeCallback, sureCallBack)
        --         return
        --     end
    end

    self:OnSelectCharacterType(index)
end

function XUiBfrtRoomCharacter:OnSelectCharacterType(index)
    if self.SelectTabBtnIndex == index then return end
    self.SelectTabBtnIndex = index

    XDataCenter.RoomCharFilterTipsManager.Reset()

    local characterType = CharacterTypeConvert[index]
    local charlist = XMVCA.XCharacter:GetOwnCharacterList(characterType)
    table.sort(charlist, self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default])

    self:RefreshCharacterTypeTips()
    self:UpdateCharacterList(charlist)
end

function XUiBfrtRoomCharacter:UpdateCharacterList(charlist)
    if not next(charlist) then
        self:SetPanelEmptyList(true)
        return
    end
    self:SetPanelEmptyList(false)

    for _, item in pairs(self.CharacterGrids) do
        item.GameObject:SetActiveEx(false)
    end

    local charDic = {}

    for i = 1, #charlist do
        local character = charlist[i]
        local characterId = character.Id
        charDic[characterId] = character

        local grid = self.CharacterGrids[characterId]
        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(self.GridBfrtCharacter)
            grid = XUiGridBfrtCharacter.New(self, item, character)
            grid.Transform:SetParent(self.PanelRoleContent, false)
            self.GridIndex[i] = grid
        else
            self.GridIndex[i]:Refresh(character)
        end
        self.CharacterGrids[characterId] = self.GridIndex[i]
        self.CharacterGrids[characterId]:SetInTeam(self.CheckIsInTeamListCb(characterId))
    end

    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    local teamCharIdMap = self.TeamCharacterIdList
    local teamSelectPos = self.TeamSelectPos
    local selectId = teamCharIdMap[teamSelectPos]
    if not selectId or selectId == 0
    or not self.CharacterGrids[selectId]
    or characterType ~= XMVCA.XCharacter:GetCharacterType(selectId)
    or not charDic[selectId]
    then
        selectId = charlist[1].Id
    end

    self:OnSelectCharacter(selectId)
end

function XUiBfrtRoomCharacter:SetPanelEmptyList(isEmpty)
    self.BtnQuitTeam.gameObject:SetActiveEx(false)
    self.BtnJoinTeam.gameObject:SetActiveEx(false)

    self.BtnConsciousness.gameObject:SetActiveEx(not isEmpty)
    self.BtnFashion.gameObject:SetActiveEx(not isEmpty)
    self.BtnWeapon.gameObject:SetActiveEx(not isEmpty)
    self.BtnPartner.gameObject:SetActiveEx(not isEmpty)

    self.PanelRoleModel.gameObject:SetActiveEx(not isEmpty)
    self.PanelRoleContent.gameObject:SetActiveEx(not isEmpty)
    self.PanelEmptyList.gameObject:SetActiveEx(isEmpty)
end

function XUiBfrtRoomCharacter:CenterToGrid(grid)
    -- local normalizedPosition
    -- local count = self.SViewCharacterList.content.transform.childCount
    -- local index = grid.Transform:GetSiblingIndex()
    -- if index > count / 2 then
    --     normalizedPosition = (index + 1) / count
    -- else
    --     normalizedPosition = (index - 1) / count
    -- end
    -- self.SViewCharacterList.verticalNormalizedPosition = math.max(0, math.min(1, (1 - normalizedPosition)))
end

function XUiBfrtRoomCharacter:OnSelectCharacter(selectId)
    if not selectId then
        return
    end

    self.CurCharacterId = selectId

    if self.CurCharacterGrid then
        self.CurCharacterGrid:SetSelect(false)
    end

    self.CurCharacterGrid = self.CharacterGrids[self.CurCharacterId]
    self.CurCharacterGrid:SetSelect(true)
    self:CenterToGrid(self.CurCharacterGrid)
    self:UpdateCurCharacterGrid()
end

function XUiBfrtRoomCharacter:UpdateCurCharacterGrid()
    local character = XMVCA.XCharacter:GetCharacter(self.CurCharacterId)
    self.CurCharacterGrid:Refresh(character)
    self:UpdateTeamBtn()
    self:UpdateTxtRequireAbilityColor()
    self:UpdateRoleModel()
end

function XUiBfrtRoomCharacter:UpdateTeamBtn()
    if not (self.TeamCharacterIdList and next(self.TeamCharacterIdList)) then
        return
    end

    local isInTeam = self:CheckCharacterInTeam(self.CurCharacterId)
    self.BtnQuitTeam.gameObject:SetActiveEx(isInTeam)
    self.BtnJoinTeam.gameObject:SetActiveEx(not isInTeam)
end

function XUiBfrtRoomCharacter:UpdateTxtRequireAbility()
    self.TxtRequireAbility.text = self.RequireAbility
    self.TxtEchelonName.text = XDataCenter.BfrtManager.GetEchelonNameTxt(self.EchelonType, self.EchelonIndex)
end

function XUiBfrtRoomCharacter:UpdateTxtRequireAbilityColor()
    local curCharacter = XMVCA.XCharacter:GetCharacter(self.CurCharacterId)
    local passed = curCharacter and curCharacter.Ability >= self.RequireAbility or false
    self.TxtRequireAbility.color = XUiHelper.Hexcolor2Color(CONDITION_HEX_COLOR[passed])
end

function XUiBfrtRoomCharacter:UpdateRoleModel()
    local characterId = self.CurCharacterId
    if not characterId then return end
    local targetPanelRole = self.PanelRoleModel
    local targetUiName = self.Name
    local charaterFunc = function(model)
        if not model then
            return
        end
        self.PanelDrag.Target = model.transform
        if self.SelectTabBtnIndex == TabBtnIndex.Normal then
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        elseif self.SelectTabBtnIndex == TabBtnIndex.Isomer then
            self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        end
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.RoleModelPanel:UpdateCharacterModel(self.CurCharacterId, targetPanelRole, targetUiName, charaterFunc)
end

function XUiBfrtRoomCharacter:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiBfrtRoomCharacter:AutoInitUi()
    self.BtnFashion = self.Transform:Find("SafeAreaContentPane/CharList/TeamBtn/BtnFashion"):GetComponent("Button")
    self.BtnConsciousness = self.Transform:Find("SafeAreaContentPane/CharList/TeamBtn/BtnConsciousness"):GetComponent("Button")
    self.BtnJoinTeam = self.Transform:Find("SafeAreaContentPane/CharList/TeamBtn/BtnJoinTeam"):GetComponent("Button")
    self.BtnQuitTeam = self.Transform:Find("SafeAreaContentPane/CharList/TeamBtn/BtnQuitTeam"):GetComponent("Button")
    self.SViewCharacterList = self.Transform:Find("SafeAreaContentPane/CharList/CharInfo/Left/SViewCharacterList"):GetComponent("ScrollRect")
    self.PanelRoleContent = self.Transform:Find("SafeAreaContentPane/CharList/CharInfo/Left/SViewCharacterList/Viewport/PanelRoleContent")
    self.GridBfrtCharacter = self.Transform:Find("SafeAreaContentPane/CharList/CharInfo/Left/SViewCharacterList/Viewport/PanelRoleContent/GridBfrtCharacter")
    self.PanelDrag = self.Transform:Find("SafeAreaContentPane/CharList/CharInfo/PanelDrag"):GetComponent("XDrag")
    self.PanelAsset = self.Transform:Find("SafeAreaContentPane/PanelAsset")
    self.BtnBack = self.Transform:Find("SafeAreaContentPane/Top/BtnBack"):GetComponent("Button")
    self.BtnMainUi = self.Transform:Find("SafeAreaContentPane/Top/BtnMainUi"):GetComponent("Button")
    self.BtnWeapon = self.Transform:Find("SafeAreaContentPane/CharList/TeamBtn/BtnWeapon"):GetComponent("Button")
end

function XUiBfrtRoomCharacter:AutoAddListener()
    self:RegisterClickEvent(self.BtnFashion, self.OnBtnFashionClick)
    self:RegisterClickEvent(self.BtnConsciousness, self.OnBtnConsciousnessClick)
    self:RegisterClickEvent(self.BtnJoinTeam, self.OnBtnJoinTeamClick)
    self:RegisterClickEvent(self.BtnQuitTeam, self.OnBtnQuitTeamClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnWeapon, self.OnBtnWeaponClick)
    self:RegisterClickEvent(self.BtnTeamPrefab, self.OnBtnTeamPrefabClick)
    self.BtnPartner.CallBack = function()
        self:OnBtnPartnerClick()
    end
    self.BtnFilter.CallBack = function()
        self:OnBtnFilterClick()
    end
end

function XUiBfrtRoomCharacter:OnBtnTeamPrefabClick()
    local stageId = self.StageId
    local limitBuffId = self.LimitBuffId
    local characterLimitType = self.CharacterLimitType
    local stageInfos = XDataCenter.FubenManager.GetStageInfo(stageId)
    local stageType = stageInfos and stageInfos.Type
    local closeCallback = function()
        self:CheckJoinTeamPrefab()
    end
    XLuaUiManager.Open("UiRoomTeamPrefab", nil, nil, characterLimitType, limitBuffId, stageType, nil, closeCallback, stageId)
end

function XUiBfrtRoomCharacter:OnBtnConsciousnessClick()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self.CurCharacterId)
end

function XUiBfrtRoomCharacter:OnBtnWeaponClick()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CurCharacterId, nil, true)
end

function XUiBfrtRoomCharacter:OnBtnFashionClick()
    XLuaUiManager.Open("UiFashion", self.CurCharacterId)
end

function XUiBfrtRoomCharacter:UpdateTeamPrefab(team)
    self.TeamDataPrefab = team.TeamData
    self.TeamDataIndex = 1
    XDataCenter.BfrtManager.SetTeamCaptainPos(self.EchelonId, team.CaptainPos)
    XDataCenter.BfrtManager.SetTeamFirstFightPos(self.EchelonId, team.FirstFightPos)
end

function XUiBfrtRoomCharacter:CheckJoinTeamPrefab()
    if not self.TeamDataIndex or not self.TeamDataPrefab then
        return
    end

    local index = self.TeamDataIndex
    local characterId = self.TeamDataPrefab[index]
    if not characterId then
        XUiManager.TipText("SCRoleSkillUploadSuccess")
        self:Close()
        return
    end

    local joinFunc = function()
        self.TeamDataIndex = self.TeamDataIndex + 1
        self:CheckJoinTeamPrefab()
    end
    self:OnJoinTeam(characterId, index, true, joinFunc, true)
end

function XUiBfrtRoomCharacter:OnJoinTeam(characterId, teamSelectPos, isNotClose, cb, isSkipTip)
    local callback = cb --成功或取消加入编队回调
    local teamSelectPos = teamSelectPos or self.TeamSelectPos
    if teamSelectPos > self.EchelonRequireCharacterNum then
        if callback then
            callback()
        end
        return
    end

    local characterId = characterId
    local isNotClose = isNotClose --是否不关闭本界面
    local isSkipTip = isSkipTip --是否跳过二次弹窗确认

    local joinFunc = function(isReset)
        local echelonIndex, echelonType = self.CheckIsInTeamListCb(characterId)
        if echelonIndex and echelonType then
            local sureCallback = function()
                if isReset then
                    self:ResetTeamData()
                end

                self.CharacterSwapEchelonCb(characterId, self.TeamCharacterIdList[teamSelectPos])
                self.TeamCharacterIdList[teamSelectPos] = characterId
                if not isNotClose then
                    self:Close()
                elseif callback then
                    callback()
                end
            end

            if isSkipTip then
                sureCallback()
                return
            end

            local title = CS.XTextManager.GetText("BfrtDeployTipTitle")
            local characterName = XMVCA.XCharacter:GetCharacterName(characterId)
            local oldEchelon = XDataCenter.BfrtManager.GetEchelonNameTxt(echelonType, echelonIndex)
            local newEchelon = XDataCenter.BfrtManager.GetEchelonNameTxt(self.EchelonType, self.EchelonIndex)
            local content = CS.XTextManager.GetText("BfrtDeployTipContent", characterName, oldEchelon, newEchelon)

            XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, callback, sureCallback)
        else
            if isReset then
                self:ResetTeamData()
            end

            self:QuitTeam(characterId)
            self.TeamCharacterIdList[teamSelectPos] = characterId
            if not isNotClose then
                self:Close()
            elseif callback then
                callback()
            end
        end
    end

    -- 角色类型不一致拦截
    local inTeamCharacterType = self:GetTeamCharacterType()
    if inTeamCharacterType then
        local characterType = characterId and characterId ~= 0 and XMVCA.XCharacter:GetCharacterType(characterId)
        if characterType and characterType ~= inTeamCharacterType then
            local content = CSXTextManagerGetText("TeamCharacterTypeNotSame")
            local sureCallBack = function()
                local isReset = true
                joinFunc(isReset)
            end
            XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallBack)
            return
        end
    end

    joinFunc()
end

function XUiBfrtRoomCharacter:OnBtnJoinTeamClick()
    local characterId = self.CurCharacterId
    self:OnJoinTeam(characterId)
end

function XUiBfrtRoomCharacter:OnBtnQuitTeamClick()
    self:QuitTeam(self.CurCharacterId)
    self:Close()
end

function XUiBfrtRoomCharacter:OnBtnBackClick()
    self:Close()
end

function XUiBfrtRoomCharacter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiBfrtRoomCharacter:OnBtnFilterClick()
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    XLuaUiManager.Open("UiRoomCharacterFilterTips",
    self,
    XRoomCharFilterTipsConfigs.EnumFilterType.Bfrt,
    XRoomCharFilterTipsConfigs.EnumSortType.Bfrt,
    characterType)
end

function XUiBfrtRoomCharacter:OnBtnPartnerClick()
    XDataCenter.PartnerManager.GoPartnerCarry(self.CurCharacterId, false)
end

function XUiBfrtRoomCharacter:QuitTeam(characterId)
    for index, existCharacterId in pairs(self.TeamCharacterIdList) do
        if characterId == existCharacterId then
            self.TeamCharacterIdList[index] = 0
            return
        end
    end
end

function XUiBfrtRoomCharacter:Close()
    if self.TeamResultCb then
        self.TeamResultCb(self.TeamCharacterIdList)
    end

    XUiBfrtRoomCharacter.Super.Close(self)
end

function XUiBfrtRoomCharacter:CheckCharacterInTeam(checkCharacterId)
    for _, characterId in pairs(self.TeamCharacterIdList) do
        if checkCharacterId == characterId then
            return true
        end
    end
    return false
end

function XUiBfrtRoomCharacter:GetTeamCharacterType()
    for k, v in pairs(self.TeamCharacterIdList) do
        if v ~= 0 then
            return XMVCA.XCharacter:GetCharacterType(v)
        end
    end
end

function XUiBfrtRoomCharacter:Filter(selectTagGroupDic, sortTagId, isThereFilterDataCb)
    local judgeCb = function(groupId, tagValue, character)
        local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(character.Id)
        local compareValue
        if groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Career then
            compareValue = detailConfig.Career
            if compareValue == tagValue then
                -- 当前角色满足该标签
                return true
            end
        elseif groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Element then
            compareValue = detailConfig.ObtainElementList
            for _, element in pairs(compareValue) do
                if element == tagValue then
                    -- 当前角色满足该标签
                    return true
                end
            end
        else
            XLog.Error(string.format("XUiBfrtRoomCharacter:Filter函数错误，没有处理排序组：%s的逻辑", groupId))
            return false
        end
    end

    local allChar = XMVCA.XCharacter:GetOwnCharacterList(CharacterTypeConvert[self.SelectTabBtnIndex])
    XDataCenter.RoomCharFilterTipsManager.Filter(self.TagCacheDic, selectTagGroupDic, allChar, judgeCb,
    function(filteredData)
        self:FilterRefresh(filteredData, sortTagId)
    end,
    isThereFilterDataCb)
end

function XUiBfrtRoomCharacter:FilterRefresh(filteredData, sortTagId)
    if self.SortFunction[sortTagId] then
        table.sort(filteredData, self.SortFunction[sortTagId])
    else
        XLog.Error(string.format("XUiBfrtRoomCharacter:FilterRefresh函数错误，没有定义标签：%s的排序函数", sortTagId))
        return
    end
    self:UpdateCharacterList(filteredData)
end