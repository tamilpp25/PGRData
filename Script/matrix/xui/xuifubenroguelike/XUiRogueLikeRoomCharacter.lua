local XUiGridRogueLikeCharacter = require("XUi/XUiFubenRogueLike/XUiGridRogueLikeCharacter")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local CSXTextManagerGetText = CS.XTextManager.GetText

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

local XUiRogueLikeRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiRogueLikeRoomCharacter")

function XUiRogueLikeRoomCharacter:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    self.BtnFashion.CallBack = function() self:OnBtnFashionClick() end
    self.BtnConsciousness.CallBack = function() self:OnBtnConsciousnessClick() end
    self.BtnWeapon.CallBack = function() self:OnBtnWeaponClick() end
    self.BtnJoinTeam.CallBack = function() self:OnBtnJoinTeamClick() end
    self.BtnQuitTeam.CallBack = function() self:OnBtnQuitTeamClick() end
    self.BtnFilter.CallBack = function()
        self:OnBtnFilterClick()
    end

    self.GridIndex = {}
    self.TagCacheDic = {}
    self.SortFunction = {}
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default] = function(leftCharacter, rightCharacter)
        local leftInTeam = self:IsInTeam(leftCharacter.Id)
        local leftAbility = leftCharacter.Ability
        local leftLevel = leftCharacter.Level
        local leftQuality = leftCharacter.Quality
        local leftPriority = XMVCA.XCharacter:GetCharacterPriority(leftCharacter.Id)

        local rightInTeam = self:IsInTeam(rightCharacter.Id)
        local rightAbility = rightCharacter.Ability
        local rightLevel = rightCharacter.Level
        local rightQuality = rightCharacter.Quality
        local rightPriority = XMVCA.XCharacter:GetCharacterPriority(rightCharacter.Id)

        if leftInTeam ~= rightInTeam then
            return leftInTeam
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

    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")

    self.GridCharacter.gameObject:SetActiveEx(false)
end

-- 选择角色
-- 选择机器人
function XUiRogueLikeRoomCharacter:OnStart(args)
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, nil, nil, true)
    local teamSelectPos = self.TeamSelectPos
    self.TeamSelectPos = args.TeamSelectPos
    self.TeamCharIdMap = args.TeamCharIdMap
    self.Type = args.Type
    self.CharacterLimitType = args.CharacterLimitType
    self.LimitBuffId = args.LimitBuffId
    self.CallBack = args.CallBack
    self.CancelCallBack = args.CancelCallBack
    self.CharacterGrids = {}

    self:InitRequireCharacterInfo()
    self:InitCharacterTypeBtns()
    self:SetBtnStates()
end

function XUiRogueLikeRoomCharacter:OnEnable()
    if self:IsCharacterType() and self.CharacterGrids then
        self:OnCharacterClick()
    end
end

function XUiRogueLikeRoomCharacter:SetBtnStates()
    local isCharacter = self:IsCharacterType()
    self.BtnFashion.gameObject:SetActiveEx(isCharacter)
    self.BtnConsciousness.gameObject:SetActiveEx(isCharacter)
    self.BtnWeapon.gameObject:SetActiveEx(isCharacter)
end

function XUiRogueLikeRoomCharacter:InitRequireCharacterInfo()
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

function XUiRogueLikeRoomCharacter:RefreshCharacterTypeTips()
    local limitBuffId = self.LimitBuffId
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    local characterLimitType = self.CharacterLimitType
    local text = XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, limitBuffId)
    self.TxtRequireCharacter.text = text
end

function XUiRogueLikeRoomCharacter:InitCharacterTypeBtns()
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

function XUiRogueLikeRoomCharacter:TrySelectCharacterType(index)
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
    elseif characterLimitType == XFubenConfigs.CharacterLimitType.IsomerDebuff then
        if characterType == XEnumConst.CHARACTER.CharacterType.Isomer then
            -- local buffDes = XFubenConfigs.GetBuffDes(self.LimitBuffId)
            -- local content = CSXTextManagerGetText("TeamSelectCharacterTypeLimitTipIsomerDebuff", buffDes)
            -- local sureCallBack = function()
            --     self:OnSelectCharacterType(index)
            -- end
            -- local closeCallback = function()
            --     self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndexConvert[XEnumConst.CHARACTER.CharacterType.Normal])
            -- end
            -- XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, closeCallback, sureCallBack)
            -- return
        end
    elseif characterLimitType == XFubenConfigs.CharacterLimitType.NormalDebuff then
        if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
            -- local buffDes = XFubenConfigs.GetBuffDes(self.LimitBuffId)
            -- local content = CSXTextManagerGetText("TeamSelectCharacterTypeLimitTipNormalDebuff", buffDes)
            -- local sureCallBack = function()
            --     self:OnSelectCharacterType(index)
            -- end
            -- local closeCallback = function()
            --     self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndexConvert[XEnumConst.CHARACTER.CharacterType.Isomer])
            -- end
            -- XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, closeCallback, sureCallBack)
            -- return
        end
    end

    self:OnSelectCharacterType(index)
end

function XUiRogueLikeRoomCharacter:OnSelectCharacterType(index)
    if self.SelectTabBtnIndex == index then return end
    self.SelectTabBtnIndex = index

    XDataCenter.RoomCharFilterTipsManager.Reset()

    local charlist
    local characterType = CharacterTypeConvert[index]
    if self:IsCharacterType() then
        charlist = XMVCA.XCharacter:GetOwnCharacterList(characterType)
        table.sort(charlist, self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default])
    else
        charlist = XDataCenter.FubenRogueLikeManager.GetAssistRobots(characterType)
    end

    self:RefreshCharacterTypeTips()
    self:UpdateCharacterList(charlist)
end

function XUiRogueLikeRoomCharacter:SetPanelEmptyList(isEmpty)
    self.BtnQuitTeam.gameObject:SetActiveEx(false)
    self.BtnJoinTeam.gameObject:SetActiveEx(false)

    self.BtnConsciousness.gameObject:SetActiveEx(not isEmpty)
    self.BtnFashion.gameObject:SetActiveEx(not isEmpty)
    self.BtnWeapon.gameObject:SetActiveEx(not isEmpty)

    self.PanelRoleContent.gameObject:SetActiveEx(not isEmpty)
    self.PanelRoleModel.gameObject:SetActiveEx(not isEmpty)
    self.PanelEmptyList.gameObject:SetActiveEx(isEmpty)
    self:SetBtnStates()
end

function XUiRogueLikeRoomCharacter:UpdateCharacterList(charlist)
    if not next(charlist) then
        self:SetPanelEmptyList(true)
        return
    end
    self:SetPanelEmptyList(false)

    for _, item in pairs(self.CharacterGrids) do
        item:Reset()
    end

    self.CharacterGrids = {}
    local charDic = {}
    for i = 1, #charlist do
        local characterId = charlist[i].Id
        charDic[characterId] = charlist[i]

        local grid = self.GridIndex[i]
        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(self.GridCharacter)
            grid = XUiGridRogueLikeCharacter.New(self, item, function(character)
                self:OnCharacterClick(character)
            end, characterId, self.Type)
            grid.Transform:SetParent(self.PanelRoleContent, false)
            self.GridIndex[i] = grid
        end
        if self:IsCharacterType() then
            grid:UpdateGrid(XMVCA.XCharacter:GetCharacter(characterId))
            grid:SetArrowUp(XDataCenter.FubenRogueLikeManager.IsTeamEffectCharacter(characterId))
        else
            grid:UpdateGrid(XRobotManager.GetRobotTemplate(characterId))
            grid:SetArrowUp(false)
        end
        grid:SetInTeam(self:IsInTeam(characterId))
        grid.GameObject:SetActiveEx(true)
        self.CharacterGrids[characterId] = grid
    end

    local teamCharIdMap = self.TeamCharIdMap
    local teamSelectPos = self.TeamSelectPos
    local selectId = teamCharIdMap[teamSelectPos]
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]

    if not selectId or selectId == 0
    or not self.CharacterGrids[selectId]
    or characterType ~= XMVCA.XCharacter:GetCharacterType(selectId)
    or not charDic[selectId]
    then
        selectId = charlist[1].Id
    end
    self:SelectCharacter(selectId)
end

function XUiRogueLikeRoomCharacter:OnCharacterClick(character)
    if character then
        self.CurCharacter = character
    end
    if not self.CurCharacter then return end

    if self.CurCharacterItem then
        self.CurCharacterItem:SetSelect(false)
    end

    local characterId = self.CurCharacter.Id
    self.CurCharacterItem = self.CharacterGrids[characterId]
    self.CurCharacterItem:UpdateGrid()
    self.CurCharacterItem:SetSelect(true)
    self.CurCharacterItem:SetInTeam(self:IsInTeam(characterId))

    -- 更新按钮状态
    self:UpdateBtns(characterId)
    self:CenterToGrid(self.CurCharacterItem)
    local fashioId = (not self:IsCharacterType()) and character.FashionId or nil
    self:UpdateRoleMode(characterId, fashioId)
    self.CurCharacterItem:SetArrowUp(self:IsCharacterType() and XDataCenter.FubenRogueLikeManager.IsTeamEffectCharacter(characterId))
end

-- 更新按钮状态
function XUiRogueLikeRoomCharacter:UpdateBtns(curCharacterId)
    local isJoin = true
    for k, v in pairs(self.TeamCharIdMap) do
        if v == curCharacterId then
            isJoin = false
        end
    end

    self.BtnJoinTeam.gameObject:SetActiveEx(isJoin)
    self.BtnQuitTeam.gameObject:SetActiveEx(not isJoin)
end

--更新模型
function XUiRogueLikeRoomCharacter:UpdateRoleMode(characterId, fashionId)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.RoleModelPanel:UpdateCharacterModel(characterId, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiRogueLikeRoomCharacter, function(model)
        if not model then return end
        self.PanelDrag.Target = model.transform
        if self.SelectTabBtnIndex == TabBtnIndex.Normal then
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        elseif self.SelectTabBtnIndex == TabBtnIndex.Isomer then
            self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        end
    end, nil, fashionId)
end

-- 选一个角色
function XUiRogueLikeRoomCharacter:SelectCharacter(id)
    local grid = self.CharacterGrids[id]
    local character = grid and grid.Template
    self:OnCharacterClick(character)
end

function XUiRogueLikeRoomCharacter:CenterToGrid(grid)
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

function XUiRogueLikeRoomCharacter:IsCharacterType()
    return self.Type == XFubenRogueLikeConfig.SelectCharacterType.Character
end

function XUiRogueLikeRoomCharacter:IsInTeam(characterId)
    for _, v in pairs(self.TeamCharIdMap) do
        if v == characterId then
            return true
        end
    end
    return false
end

function XUiRogueLikeRoomCharacter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiRogueLikeRoomCharacter:OnBtnFashionClick()
    if not self.CurCharacter then return end
    XLuaUiManager.Open("UiFashion", self.CurCharacter.Id)
end

function XUiRogueLikeRoomCharacter:OnBtnConsciousnessClick()
    if not self.CurCharacter then return end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self.CurCharacter.Id)
end

function XUiRogueLikeRoomCharacter:OnBtnWeaponClick()
    if not self.CurCharacter then return end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CurCharacter.Id, nil, true)
end

-- 加入队伍
function XUiRogueLikeRoomCharacter:OnBtnJoinTeamClick()
    if not self.CurCharacter then return end

    local selectId = self.CurCharacter.Id
    local joinFunc = function(isReset)
        if self.CallBack then self.CallBack(selectId, true, isReset) end
        self:Close()
    end

    -- 角色类型不一致拦截
    local inTeamCharacterType = self:GetTeamCharacterType()
    if inTeamCharacterType then
        local characterType = XMVCA.XCharacter:GetCharacterType(selectId)
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

-- 移出队伍
function XUiRogueLikeRoomCharacter:OnBtnQuitTeamClick()
    if not self.CurCharacter then return end
    if self.CallBack then
        self.CallBack(self.CurCharacter.Id, false)
    end
    self:Close()
end

function XUiRogueLikeRoomCharacter:OnBtnBackClick()
    self:Close()
    if self.CancelCallBack then
        self.CancelCallBack()
    end
end

function XUiRogueLikeRoomCharacter:OnBtnFilterClick()
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    XLuaUiManager.Open("UiRoomCharacterFilterTips",
    self,
    XRoomCharFilterTipsConfigs.EnumFilterType.RogueLike,
    XRoomCharFilterTipsConfigs.EnumSortType.RogueLike,
    characterType, false, not self:IsCharacterType())
end

function XUiRogueLikeRoomCharacter:GetTeamCharacterType()
    for k, v in pairs(self.TeamCharIdMap) do
        if v ~= 0 then
            return XMVCA.XCharacter:GetCharacterType(v)
        end
    end
end

function XUiRogueLikeRoomCharacter:Filter(selectTagGroupDic, sortTagId, isThereFilterDataCb)
    local judgeCb = function(groupId, tagValue, character)
        local detailConfig
        if self:IsCharacterType() then
            detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(character.Id)
        else
            local robotTemplate = XRobotManager.GetRobotTemplate(character.Id)
            detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(robotTemplate.CharacterId)
        end

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
            return
        end
    end

    local allChar
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    if self:IsCharacterType() then
        allChar = XMVCA.XCharacter:GetOwnCharacterList(characterType)
    else
        allChar = XDataCenter.FubenRogueLikeManager.GetAssistRobots(characterType)
    end

    XDataCenter.RoomCharFilterTipsManager.Filter(self.TagCacheDic, selectTagGroupDic, allChar, judgeCb,
    function(filteredData)
        self:FilterRefresh(filteredData, sortTagId)
    end,
    isThereFilterDataCb)
end

function XUiRogueLikeRoomCharacter:FilterRefresh(filteredData, sortTagId)
    if self:IsCharacterType() then
        if self.SortFunction[sortTagId] then
            table.sort(filteredData, self.SortFunction[sortTagId])
        else
            XLog.Error(string.format("XUiBfrtRoomCharacter:FilterRefresh函数错误，没有定义标签：%s的排序函数", sortTagId))
            return
        end
    end

    self:UpdateCharacterList(filteredData)
end