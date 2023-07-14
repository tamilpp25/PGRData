local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local TabBtnIndex = {
    Normal = 1,
    Isomer = 2,
}
local CharacterTypeConvert = {
    [TabBtnIndex.Normal] = XCharacterConfigs.CharacterType.Normal,
    [TabBtnIndex.Isomer] = XCharacterConfigs.CharacterType.Isomer,
}
local TabBtnIndexConvert = {
    [XCharacterConfigs.CharacterType.Normal] = TabBtnIndex.Normal,
    [XCharacterConfigs.CharacterType.Isomer] = TabBtnIndex.Isomer,
}

local XUiBabelTowerRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiBabelTowerRoomCharacter")

function XUiBabelTowerRoomCharacter:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    self.BtnFashion.CallBack = function() self:OnBtnFashionClick() end
    self.BtnConsciousness.CallBack = function() self:OnBtnConsciousnessClick() end
    self.BtnWeapon.CallBack = function() self:OnBtnWeaponClick() end
    self.BtnJoinTeam.CallBack = function() self:OnBtnJoinTeamClick() end
    self.BtnQuitTeam.CallBack = function() self:OnBtnQuitTeamClick() end
    self.BtnPartner.CallBack = function() self:OnBtnPartnerClick() end
    self.BtnFilter.CallBack = function()
        self:OnBtnFilterClick()
    end

    self.GridIndex = {}
    self.TagCacheDic = {}
    self.SortFunction = {}
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default] = function(leftCharacter, rightCharacter)
        local leftInTeam = self:IsInTeam(leftCharacter.Id)
        local rightInTeam = self:IsInTeam(rightCharacter.Id)

        if leftInTeam ~= rightInTeam then
            return leftInTeam
        end

        return leftCharacter.Ability > rightCharacter.Ability
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
        return leftCharacter.Ability > rightCharacter.Ability
    end

    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")

    self.GridCharacter.gameObject:SetActiveEx(false)

    self.CharacterGrids = {}
end

function XUiBabelTowerRoomCharacter:OnStart(args, cb)
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, nil, nil, true)
    self.StageId = args.StageId
    self.TeamId = args.TeamId
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TeamSelectPos = args.Index
    self.BanCharacters = {}
    self.TeamCharIdMap = args.CurTeamList
    self.CharacterLimitType = args.CharacterLimitType
    self.LimitBuffId = args.LimitBuffId
    self.TeamResultCb = cb

    self:InitRequireCharacterInfo()
    self:InitCharacterTypeBtns()
end

function XUiBabelTowerRoomCharacter:OnEnable()
    self:OnCharacterClick()
end

function XUiBabelTowerRoomCharacter:InitRequireCharacterInfo()
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

function XUiBabelTowerRoomCharacter:RefreshCharacterTypeTips()
    local limitBuffId = self.LimitBuffId
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    local characterLimitType = self.CharacterLimitType
    local text = XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, limitBuffId)
    self.TxtRequireCharacter.text = text
end

function XUiBabelTowerRoomCharacter:ResetTeamData()
    self.TeamCharIdMap = { 0, 0, 0 }
end

function XUiBabelTowerRoomCharacter:InitCharacterTypeBtns()
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
    if tempCharacterType and not (tempCharacterType == XCharacterConfigs.CharacterType.Normal and lockGouzaoti
    or tempCharacterType == XCharacterConfigs.CharacterType.Isomer and lockShougezhe) then
        characterType = tempCharacterType
    end
    self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndexConvert[characterType])
end

function XUiBabelTowerRoomCharacter:TrySelectCharacterType(index)
    local characterType = CharacterTypeConvert[index]
    if characterType == XCharacterConfigs.CharacterType.Isomer and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer) then return end

    local characterLimitType = self.CharacterLimitType
    if characterLimitType == XFubenConfigs.CharacterLimitType.Normal then
        if characterType == XCharacterConfigs.CharacterType.Isomer then
            XUiManager.TipText("TeamSelectCharacterTypeLimitTipNormal")
            return
        end
    elseif characterLimitType == XFubenConfigs.CharacterLimitType.Isomer then
        if characterType == XCharacterConfigs.CharacterType.Normal then
            XUiManager.TipText("TeamSelectCharacterTypeLimitTipIsomer")
            return
        end
        -- elseif characterLimitType == XFubenConfigs.CharacterLimitType.IsomerDebuff then
        --     if characterType == XCharacterConfigs.CharacterType.Isomer then
        --         local buffDes = XFubenConfigs.GetBuffDes(self.LimitBuffId)
        --         local content = CSXTextManagerGetText("TeamSelectCharacterTypeLimitTipIsomerDebuff", buffDes)
        --         local sureCallBack = function()
        --             self:OnSelectCharacterType(index)
        --         end
        --         local closeCallback = function()
        --             self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndexConvert[XCharacterConfigs.CharacterType.Normal])
        --         end
        --         XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, closeCallback, sureCallBack)
        --         return
        --     end
        -- elseif characterLimitType == XFubenConfigs.CharacterLimitType.NormalDebuff then
        --     if characterType == XCharacterConfigs.CharacterType.Normal then
        --         local buffDes = XFubenConfigs.GetBuffDes(self.LimitBuffId)
        --         local content = CSXTextManagerGetText("TeamSelectCharacterTypeLimitTipNormalDebuff", buffDes)
        --         local sureCallBack = function()
        --             self:OnSelectCharacterType(index)
        --         end
        --         local closeCallback = function()
        --             self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndexConvert[XCharacterConfigs.CharacterType.Isomer])
        --         end
        --         XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, closeCallback, sureCallBack)
        --         return
        --     end
    end

    self:OnSelectCharacterType(index)
end

function XUiBabelTowerRoomCharacter:OnSelectCharacterType(index)
    if self.SelectTabBtnIndex == index then return end
    self.SelectTabBtnIndex = index
    XDataCenter.RoomCharFilterTipsManager.Reset()

    local characterType = CharacterTypeConvert[index]
    local charlist = XDataCenter.CharacterManager.GetOwnCharacterList(characterType)
    table.sort(charlist, self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default])

    self:RefreshCharacterTypeTips()
    self:UpdateCharacterList(charlist)
end

function XUiBabelTowerRoomCharacter:SetPanelEmptyList(isEmpty)
    self.BtnQuitTeam.gameObject:SetActiveEx(false)
    self.BtnJoinTeam.gameObject:SetActiveEx(false)

    self.BtnConsciousness.gameObject:SetActiveEx(not isEmpty)
    self.BtnFashion.gameObject:SetActiveEx(not isEmpty)
    self.BtnWeapon.gameObject:SetActiveEx(not isEmpty)
    self.BtnPartner.gameObject:SetActiveEx(not isEmpty)

    self.PanelRoleContent.gameObject:SetActiveEx(not isEmpty)
    self.PanelRoleModel.gameObject:SetActiveEx(not isEmpty)
    self.PanelEmptyList.gameObject:SetActiveEx(isEmpty)
end

function XUiBabelTowerRoomCharacter:UpdateCharacterList(charlist)
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
        local char = charlist[i]
        local characterId = char.Id
        charDic[characterId] = char

        local grid = self.GridIndex[i]
        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(self.GridCharacter)
            grid = XUiGridCharacter.New(item, self, char, function(character)
                self:OnCharacterClick(character)
            end)
            grid.Transform:SetParent(self.PanelRoleContent, false)
            self.GridIndex[i] = grid
        end

        grid:UpdateGrid(char)
        grid:SetInTeam(false)
        -- 被禁用
        grid:SetLimited(self.BanCharacters[characterId])
        -- 被限制锁定
        grid:SetIsLock(not self.BanCharacters[characterId]
        and XDataCenter.FubenBabelTowerManager.IsCharacterLockByStageId(characterId, self.StageId, self.TeamId))
        grid.GameObject:SetActiveEx(true)
        self.CharacterGrids[characterId] = self.GridIndex[i]
    end

    local teamCharIdMap = self.TeamCharIdMap
    local teamSelectPos = self.TeamSelectPos

    for _, characterId in pairs(teamCharIdMap) do
        local grid = self.CharacterGrids[characterId]
        if grid then
            grid:SetInTeam(true)
        end
    end

    local selectId = teamCharIdMap[teamSelectPos]
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]

    if not selectId or selectId == 0
    or not self.CharacterGrids[selectId]
    or characterType ~= XCharacterConfigs.GetCharacterType(selectId)
    or not charDic[selectId]
    then
        selectId = charlist[1].Id
    end
    self:SelectCharacter(selectId)
end

function XUiBabelTowerRoomCharacter:IsInTeam(characterId)
    for _, v in pairs(self.TeamCharIdMap) do
        if v == characterId then
            return true
        end
    end
    return false
end

function XUiBabelTowerRoomCharacter:OnCharacterClick(character)
    if character then
        self.CurCharacter = character
    end
    if not self.CurCharacter then return end

    if self.CurCharacterItem then
        self.CurCharacterItem:SetSelect(false)
    end

    self.CurCharacterItem = self.CharacterGrids[self.CurCharacter.Id]
    self.CurCharacterItem:UpdateGrid()
    self.CurCharacterItem:SetSelect(true)
    self.CurCharacterItem:SetLimited(self.BanCharacters[self.CurCharacter.Id])
    self.CurCharacterItem:SetIsLock(not self.BanCharacters[self.CurCharacter.Id] and XDataCenter.FubenBabelTowerManager.IsCharacterLockByStageId(self.CurCharacter.Id, self.StageId, self.TeamId))

    self:CenterToGrid(self.CurCharacterItem)

    -- 更新按钮状态
    self:UpdateBtns(self.CurCharacter.Id)
    self:UpdateRoleMode(self.CurCharacter.Id)
end

-- 更新按钮状态
function XUiBabelTowerRoomCharacter:UpdateBtns(curCharacterId)
    local isInTeam = false
    for _, member_char_id in pairs(self.TeamCharIdMap or {}) do
        if curCharacterId == member_char_id then
            isInTeam = true
            break
        end
    end
    local oldMemberId = self.TeamCharIdMap[self.TeamSelectPos]
    local hasOldMember = oldMemberId ~= nil and oldMemberId ~= 0
    local isJoin = true
    if hasOldMember and isInTeam and oldMemberId == curCharacterId then
        isJoin = false
    end

    local isLock = XDataCenter.FubenBabelTowerManager.IsCharacterLockByStageId(curCharacterId, self.StageId, self.TeamId)
    local isBan = self.BanCharacters[curCharacterId]
    -- 点击有角色的位置
    -- 选择的人在队伍中
    -- 选择的人是当前角色-卸下
    -- 选择的人不是当前角色-替换
    -- 选择的人不在队伍中-替换
    -- 点击无角色的位置
    -- 选择的人在队伍中-替换
    -- 选择的人不在队伍中-上阵
    self.BtnLimit.gameObject:SetActiveEx(isBan)
    self.BtnLock.gameObject:SetActiveEx(not isBan and isLock)
    if isLock or isBan then
        self.BtnJoinTeam.gameObject:SetActiveEx(false)
        self.BtnQuitTeam.gameObject:SetActiveEx(false)
    else
        self.BtnJoinTeam.gameObject:SetActiveEx(isJoin)
        self.BtnQuitTeam.gameObject:SetActiveEx(not isJoin)
    end
end

--更新模型
function XUiBabelTowerRoomCharacter:UpdateRoleMode(characterId)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.RoleModelPanel:UpdateCharacterModel(characterId, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiBabelTowerRoomCharacter, function(model)
        if not model then return end
        self.PanelDrag.Target = model.transform
        if self.SelectTabBtnIndex == TabBtnIndex.Normal then
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        elseif self.SelectTabBtnIndex == TabBtnIndex.Isomer then
            self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        end
    end)
end

-- 选一个角色
function XUiBabelTowerRoomCharacter:SelectCharacter(id)
    local grid = self.CharacterGrids[id]
    local character = grid and grid.Character
    self:OnCharacterClick(character)
end

function XUiBabelTowerRoomCharacter:CenterToGrid(grid)
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

function XUiBabelTowerRoomCharacter:OnBtnBackClick()
    if self.TeamResultCb then
        self.TeamResultCb(self.TeamCharIdMap)
    end
    self:Close()
end

function XUiBabelTowerRoomCharacter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiBabelTowerRoomCharacter:OnBtnFashionClick()
    if not self.CurCharacter then return end
    XLuaUiManager.Open("UiFashion", self.CurCharacter.Id)
end

function XUiBabelTowerRoomCharacter:OnBtnConsciousnessClick()
    if not self.CurCharacter then return end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self.CurCharacter.Id)
end

function XUiBabelTowerRoomCharacter:OnBtnWeaponClick()
    if not self.CurCharacter then return end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CurCharacter.Id, nil, true)
end

function XUiBabelTowerRoomCharacter:OnBtnPartnerClick()
    XDataCenter.PartnerManager.GoPartnerCarry(self.CurCharacter.Id, false)
end

-- 加入队伍
function XUiBabelTowerRoomCharacter:OnBtnJoinTeamClick()
    if not self.CurCharacter then return end

    local selectId = self.CurCharacter.Id

    local joinFunc = function(isReset)
        if isReset then
            self:ResetTeamData()
        else
            for k, v in pairs(self.TeamCharIdMap) do
                if v == selectId then
                    self.TeamCharIdMap[k] = 0
                    break
                end
            end
        end

        local maxMemberCount = XDataCenter.FubenBabelTowerManager.GetMaxTeamMemberCount()
        if maxMemberCount < 3 then
            local currentMemberCount = 0
            for _, v in pairs(self.TeamCharIdMap) do
                if v > 0 then
                    currentMemberCount = currentMemberCount + 1
                end
            end
            if currentMemberCount >= maxMemberCount then
                XUiManager.TipMsg(XUiHelper.GetText("BabelTowerTeamLimitCount"))
                return
            end
        end

        self.TeamCharIdMap[self.TeamSelectPos] = selectId

        if self.TeamResultCb then
            self.TeamResultCb(self.TeamCharIdMap)
        end

        self:Close()
    end

    -- 角色类型不一致拦截
    local inTeamCharacterType = self:GetTeamCharacterType()
    if inTeamCharacterType then
        local characterType = XCharacterConfigs.GetCharacterType(selectId)
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
function XUiBabelTowerRoomCharacter:OnBtnQuitTeamClick()
    if not self.CurCharacter then return end

    local count = 0
    for _, v in pairs(self.TeamCharIdMap) do
        if v > 0 then
            count = count + 1
        end
    end

    local id = self.CurCharacter.Id
    for k, v in pairs(self.TeamCharIdMap) do
        if v == id then
            self.TeamCharIdMap[k] = 0
            break
        end
    end

    if self.TeamResultCb then
        self.TeamResultCb(self.TeamCharIdMap)
    end

    self:Close()
end

function XUiBabelTowerRoomCharacter:OnBtnFilterClick()
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    XLuaUiManager.Open("UiRoomCharacterFilterTips",
    self,
    XRoomCharFilterTipsConfigs.EnumFilterType.BabelTower,
    XRoomCharFilterTipsConfigs.EnumSortType.BabelTower,
    characterType)
end

function XUiBabelTowerRoomCharacter:GetTeamCharacterType()
    for k, v in pairs(self.TeamCharIdMap) do
        if v ~= 0 then
            return XCharacterConfigs.GetCharacterType(v)
        end
    end
end

function XUiBabelTowerRoomCharacter:Filter(selectTagGroupDic, sortTagId, isThereFilterDataCb)
    local judgeCb = function(groupId, tagValue, character)
        local detailConfig = XCharacterConfigs.GetCharDetailTemplate(character.Id)

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

    local allChar = XDataCenter.CharacterManager.GetOwnCharacterList(CharacterTypeConvert[self.SelectTabBtnIndex])
    XDataCenter.RoomCharFilterTipsManager.Filter(self.TagCacheDic, selectTagGroupDic, allChar, judgeCb,
    function(filteredData)
        self:FilterRefresh(filteredData, sortTagId)
    end,
    isThereFilterDataCb)
end

function XUiBabelTowerRoomCharacter:FilterRefresh(filteredData, sortTagId)
    if self.SortFunction[sortTagId] then
        table.sort(filteredData, self.SortFunction[sortTagId])
    else
        XLog.Error(string.format("XUiBfrtRoomCharacter:FilterRefresh函数错误，没有定义标签：%s的排序函数", sortTagId))
        return
    end
    self:UpdateCharacterList(filteredData)
end