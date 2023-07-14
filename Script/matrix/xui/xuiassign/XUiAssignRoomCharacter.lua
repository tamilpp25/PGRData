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

local XUiAssignRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiAssignRoomCharacter")

function XUiAssignRoomCharacter:OnAwake()
    self:InitComponent()

    self.GridIndex = {}
    self.TagCacheDic = {}
    self.SortFunction = {}
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default] = function(leftCharacter, rightCharacter)
        local leftInTeam = self:IsInTeam(leftCharacter.Id)
        local leftLevel = leftCharacter.Level
        local leftQuality = leftCharacter.Quality
        local leftPriority = XCharacterConfigs.GetCharacterPriority(leftCharacter.Id)

        local rightInTeam = self:IsInTeam(rightCharacter.Id)
        local rightLevel = rightCharacter.Level
        local rightQuality = rightCharacter.Quality
        local rightPriority = XCharacterConfigs.GetCharacterPriority(rightCharacter.Id)

        if leftInTeam ~= rightInTeam then
            return rightInTeam
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
end

-- teamCharIdMap, teamSelectPos, cb, canQuitCharIdMap, teamOrderCharIdMap, ablityRequire, curTeamOrder
function XUiAssignRoomCharacter:OnStart(teamCharIdMap, teamSelectPos, cb, teamOrderCharIdMap, canQuitCharIdMap, ablityRequire, curTeamOrder, characterLimitType, limitBuffId, teamId)
    self.CharacterGrids = {}

    self.TeamCharIdMap = teamCharIdMap
    self.TeamSelectPos = teamSelectPos
    self.TeamResultCb = cb
    self.TeamOrderCharIdMap = teamOrderCharIdMap
    self.CanQuitCharIdMap = canQuitCharIdMap
    self.CurTeamOrder = curTeamOrder
    self.CharacterLimitType = characterLimitType or XFubenConfigs.CharacterLimitType.All
    self.LimitBuffId = limitBuffId
    self.TeamId = teamId

    self.TxtTeamInfoName.text = CS.XTextManager.GetText("AssignTeamTitle", self.CurTeamOrder) -- 作战梯队{0}
    self.TxtRequireAbility.text = ablityRequire and ablityRequire or ""

    self:InitRequireCharacterInfo()
    self:InitCharacterTypeBtns()
end

function XUiAssignRoomCharacter:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    self:UpdateInfo()
end

function XUiAssignRoomCharacter:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiAssignRoomCharacter:InitRequireCharacterInfo()
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

function XUiAssignRoomCharacter:RefreshCharacterTypeTips()
    local limitBuffId = self.LimitBuffId
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    local characterLimitType = self.CharacterLimitType
    if characterLimitType == XFubenConfigs.CharacterLimitType.IsomerDebuff
            or characterLimitType == XFubenConfigs.CharacterLimitType.NormalDebuff then
        self.TxtRequireCharacter.text = XFubenConfigs.GetStageMixCharacterLimitTips(characterLimitType, self:GetTeamDynamicCharacterTypes(), true)
        return
    end
    self.TxtRequireCharacter.text = XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, limitBuffId)
end

function XUiAssignRoomCharacter:GetTeamDynamicCharacterTypes()
    local result = {}
    if not self.CurCharacter then return result end

    local curSelectCharacterId = self.CurCharacter:GetId()
    local team = XDataCenter.FubenAssignManager.GetTeamDataById(self.TeamId)
    for pos, member in ipairs(team:GetMemberList()) do
        if member then
            local id = member:GetCharacterId()
            if id > 0 and pos ~= self.TeamSelectPos and id ~= curSelectCharacterId then
                table.insert(result, member:GetCharacterType())
            end
        end
    end
    local isInTeam = team:CheckIsInTeam(curSelectCharacterId)
    if not isInTeam then
        table.insert(result, XCharacterConfigs.GetCharacterType(curSelectCharacterId))
    else
        local member = team:GetMember(self.TeamSelectPos)
        if member then
            local memberId = member:GetCharacterId()
            if memberId > 0 and team:CheckIsInTeam(memberId) and memberId ~= curSelectCharacterId then
                table.insert(result, member:GetCharacterType())
            end
        end
    end
    return result
end

function XUiAssignRoomCharacter:ResetTeamData()
    local teamId = self.TeamId
    for k, characterId in pairs(self.TeamCharIdMap) do
        if XDataCenter.FubenAssignManager.IsCharacterInTeamById(teamId, characterId) then
            self.TeamCharIdMap[k] = 0
        end
    end
end

function XUiAssignRoomCharacter:InitCharacterTypeBtns()
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

function XUiAssignRoomCharacter:TrySelectCharacterType(index)
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

function XUiAssignRoomCharacter:OnSelectCharacterType(index)
    if self.SelectTabBtnIndex == index then return end
    self.SelectTabBtnIndex = index

    XDataCenter.RoomCharFilterTipsManager.Reset()

    local characterType = CharacterTypeConvert[index]

    local tmpTeamIdDic = {}
    for _, id in pairs(self.TeamCharIdMap) do
        tmpTeamIdDic[id] = true
    end

    local charlist = XDataCenter.CharacterManager.GetAssignCharacterListInTeam(characterType, tmpTeamIdDic)
    local teamCharIdMap = self.TeamCharIdMap
    local teamSelectPos = self.TeamSelectPos
    local selectId = teamCharIdMap[teamSelectPos]

    table.sort(charlist, self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default])

    self:RefreshCharacterTypeTips()
    self:UpdateCharacterList(charlist, function(charDic)
        if not selectId or selectId == 0
        or not self.CharacterGrids[selectId]
        or characterType ~= XCharacterConfigs.GetCharacterType(selectId)
        or not charDic[selectId]
        then
            selectId = charlist[1].Id
        end

        self:SelectCharacter(selectId)

        for _, id in pairs(teamCharIdMap) do
            if id > 0 then
                local grid = self.CharacterGrids[id]
                if grid then
                    grid:SetInTeam(true)
                end
            end
        end
    end)
end

function XUiAssignRoomCharacter:IsInTeam(charId)
    local tmpTeamIdDic = {}
    for _, id in pairs(self.TeamCharIdMap) do
        tmpTeamIdDic[id] = true
    end
    return tmpTeamIdDic[charId]
end

function XUiAssignRoomCharacter:CenterToGrid(grid)
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

function XUiAssignRoomCharacter:SelectCharacter(id)
    local grid = self.CharacterGrids[id]
    if grid then
        self:CenterToGrid(grid)
    end

    local character = grid and grid.Character
    self:UpdateInfo(character)
end

function XUiAssignRoomCharacter:SetPanelEmptyList(isEmpty)
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

function XUiAssignRoomCharacter:UpdateCharacterList(charList, cb)
    if not next(charList) then
        self:SetPanelEmptyList(true)
        return
    end
    self:SetPanelEmptyList(false)

    for _, item in pairs(self.CharacterGrids) do
        item:Reset()
    end

    self.CharacterGrids = {}
    local baseItem = self.GridCharacter
    local count = #charList
    local charDic = {}

    for i = 1, count do
        local char = charList[i]

        local grid = self.GridIndex[i]
        charDic[char.Id] = char

        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(baseItem)
            grid = XUiGridCharacter.New(item, self, char, function(character)
                self:UpdateInfo(character)
            end)

            grid.GameObject.name = char.Id
            grid.Transform:SetParent(self.PanelRoleContent, false)

            self.GridIndex[i] = grid
        else
            grid.GameObject.name = char.Id
        end
        self.CharacterGrids[char.Id] = grid
        grid:UpdateGrid(char)
        grid.GameObject:SetActiveEx(true)
        grid.Transform:SetAsLastSibling()
    end

    if cb then
        cb(charDic)
    end
end

function XUiAssignRoomCharacter:UpdateInfo(character)
    if character then
        self.CurCharacter = character
    end
    if not self.CurCharacter then return end

    if self.CurCharacterGrid then
        self.CurCharacterGrid:SetSelect(false)
    end

    self.CurCharacterGrid = self.CharacterGrids[self.CurCharacter.Id]
    self.CurCharacterGrid:UpdateGrid()
    self.CurCharacterGrid:SetSelect(true)
    self:UpdateTeamBtn()
    self:UpdateRoleModel()
    self:RefreshCharacterTypeTips()
    -- 检查教学功能按钮红点
    XRedPointManager.CheckOnceByButton(self.BtnTeaching, { XRedPointConditions.Types.CONDITION_CELICA_TEACH },
        self.CurCharacter.Id)
end

function XUiAssignRoomCharacter:UpdateTeamBtn()
    if not (self.TeamCharIdMap and next(self.TeamCharIdMap)) then
        return
    end

    self.BtnQuitTeam.gameObject:SetActiveEx(false)
    self.BtnJoinTeam.gameObject:SetActiveEx(false)

    -- 等待模型加载后设置按钮状态
    local characterId = self.CurCharacter.Id
    local isInTeam = self.TeamOrderCharIdMap[self.CurCharacter.Id]
    local isCanQuit = self.CanQuitCharIdMap[self.CurCharacter.Id]
    self.IsShowQuitTeamBtn = isInTeam and isCanQuit
    self.IsShowJoinTeamBtn = not isInTeam or not isCanQuit

    local isRobot = XRobotManager.CheckIsRobotId(characterId)
    local useFashion = true
    if isRobot then
        useFashion = XRobotManager.CheckUseFashion(characterId)
    end
    self.BtnPartner:SetDisable(isRobot, not isRobot)
    self.BtnFashion:SetDisable(not useFashion, useFashion)
    self.BtnConsciousness:SetDisable(isRobot, not isRobot)
    self.BtnWeapon:SetDisable(isRobot, not isRobot)
end

function XUiAssignRoomCharacter:UpdateRoleModel()
    local characterId = self.CurCharacter and self.CurCharacter.Id
    if not characterId then return end
    local targetPanelRole = self.PanelRoleModel
    local targetUiName = self.Name

    local func = function()
        self.BtnJoinTeam.gameObject:SetActiveEx(self.IsShowJoinTeamBtn)
        self.BtnQuitTeam.gameObject:SetActiveEx(self.IsShowQuitTeamBtn)
    end

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
    
    local isRobot = XRobotManager.CheckIsRobotId(characterId)
    if isRobot then
        local bot2CharId = XRobotManager.GetCharacterId(characterId)
        local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(bot2CharId)
        local entity = isOwn and XDataCenter.CharacterManager.GetCharacter(bot2CharId) or false
        if XRobotManager.CheckUseFashion(characterId) and entity then
            local viewModel = entity:GetCharacterViewModel()
            self.RoleModelPanel:UpdateCharacterModel(bot2CharId, targetPanelRole, targetUiName, charaterFunc, func, viewModel:GetFashionId())
        else
            local robotCfg = XRobotManager.GetRobotTemplate(characterId)
            local fashionId = robotCfg.FashionId
            local weaponId = robotCfg.WeaponId
            self.RoleModelPanel:UpdateRobotModel(characterId, bot2CharId, nil, fashionId, weaponId, cb)
        end
    else
        self.RoleModelPanel:UpdateCharacterModel(characterId, targetPanelRole, targetUiName, charaterFunc, func)
    end
end

function XUiAssignRoomCharacter:InitComponent()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.GridCharacter.gameObject:SetActiveEx(false)

    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnJoinTeam, self.OnBtnJoinTeamClick)
    self:RegisterClickEvent(self.BtnQuitTeam, self.OnBtnQuitTeamClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self.BtnPartner.CallBack = function() self:OnBtnPartnerClick() end
    self.BtnFashion.CallBack = function() self:OnBtnFashionClick() end
    self.BtnConsciousness.CallBack = function() self:OnBtnConsciousnessClick() end
    self.BtnWeapon.CallBack = function() self:OnBtnWeaponClick() end

    self.BtnFilter.CallBack = function()
        self:OnBtnFilterClick()
    end

    self.BtnTeaching.CallBack = function()
        self:OnBtnTeachingClicked()
    end
end

function XUiAssignRoomCharacter:OnBtnTeachingClicked()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self.CurCharacter:GetId(), true)
end

function XUiAssignRoomCharacter:OnBtnWeaponClick()
    XLuaUiManager.Open("UiEquipReplaceNew", self.CurCharacter.Id, nil, true)
end

function XUiAssignRoomCharacter:OnBtnConsciousnessClick()
    XLuaUiManager.Open("UiEquipAwarenessReplace", self.CurCharacter.Id, nil, true)
end

function XUiAssignRoomCharacter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiAssignRoomCharacter:OnBtnPartnerClick()
    XDataCenter.PartnerManager.GoPartnerCarry(self.CurCharacter.Id, false)
end

function XUiAssignRoomCharacter:OnBtnBackClick()
    if self.TeamResultCb then
        self.TeamResultCb(self.TeamCharIdMap)
    end
    self:Close()
end

function XUiAssignRoomCharacter:OnBtnJoinTeamClick()
    local selectId = self.CurCharacter.Id

    local joinFunc = function(isReset)
        local newTeamCharIdMap = self:GetNewTeamCharIdMap()
        -- 修改的角色id
        local fromCharacterId = newTeamCharIdMap[self.TeamSelectPos]
        -- 将要下队
        if not fromCharacterId or fromCharacterId == 0 then
            self:OnJoinTeam(isReset)
            return
        end

        local oldOrder = self.TeamOrderCharIdMap[fromCharacterId]
        -- 不在其他梯队
        if not oldOrder then
            self:OnJoinTeam(isReset)
            return
        end

        local newOrder = self.CurTeamOrder

        local title = CS.XTextManager.GetText("AssignDeployTipTitle")
        local characterName = XCharacterConfigs.GetCharacterName(fromCharacterId)
        local oldTeamName = CS.XTextManager.GetText("AssignTeamTitle", oldOrder) -- 作战梯队1
        local newTeamName = CS.XTextManager.GetText("AssignTeamTitle", newOrder)
        local content = CS.XTextManager.GetText("AssignDeployTipContent", characterName, oldTeamName, newTeamName)
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
            self:OnJoinTeam(isReset)
        end)
    end

    local finishFunc = function(isReset)
        XDataCenter.PracticeManager.OnJoinTeam(self.CurCharacter.Id, handler(self, self.OnBtnTeachingClicked), function()
            joinFunc(isReset)
        end)
    end

    -- 角色类型不一致拦截
    if self.CharacterLimitType == XFubenConfigs.CharacterLimitType.Isomer or
    self.CharacterLimitType == XFubenConfigs.CharacterLimitType.Normal then
        local inTeamCharacterType = self:GetTeamCharacterType()
        if inTeamCharacterType then
            local characterType = selectId and selectId ~= 0 and XCharacterConfigs.GetCharacterType(selectId)
            if characterType and characterType ~= inTeamCharacterType then
                local content = CSXTextManagerGetText("TeamCharacterTypeNotSame")
                local sureCallBack = function()
                    local isReset = true
                    finishFunc(isReset)
                end
                XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallBack)
                return
            end
        end
    end

    finishFunc()
end

function XUiAssignRoomCharacter:GetNewTeamCharIdMap()
    local newTeamCharIdMap = XTool.Clone(self.TeamCharIdMap)
    local fromCharacterId = self.CurCharacter.Id
    local toCharacterId = newTeamCharIdMap[self.TeamSelectPos] or 0
    -- 换人
    for pos, id in pairs(self.TeamCharIdMap) do
        if id == fromCharacterId then
            newTeamCharIdMap[pos] = toCharacterId
            break
        end
    end
    newTeamCharIdMap[self.TeamSelectPos] = fromCharacterId
    return newTeamCharIdMap
end

function XUiAssignRoomCharacter:OnJoinTeam(isReset)
    self.TeamCharIdMap = self:GetNewTeamCharIdMap()
    if isReset then
        self:ResetTeamData()
    end
    if self.TeamResultCb then
        self.TeamResultCb(self.TeamCharIdMap)
    end
    self:Close()
end

function XUiAssignRoomCharacter:OnBtnQuitTeamClick()
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

function XUiAssignRoomCharacter:OnBtnFashionClick()
    XLuaUiManager.Open("UiFashion", self.CurCharacter.Id)
end

function XUiAssignRoomCharacter:OnBtnFilterClick()
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    XLuaUiManager.Open("UiRoomCharacterFilterTips",
    self,
    XRoomCharFilterTipsConfigs.EnumFilterType.Assign,
    XRoomCharFilterTipsConfigs.EnumSortType.Assign,
    characterType)
end

function XUiAssignRoomCharacter:GetTeamCharacterType()
    local teamId = self.TeamId
    return XDataCenter.FubenAssignManager.GetTeamCharacterType(teamId)
end

function XUiAssignRoomCharacter:Filter(selectTagGroupDic, sortTagId, isThereFilterDataCb)
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

function XUiAssignRoomCharacter:FilterRefresh(filteredData, sortTagId)
    if self.SortFunction[sortTagId] then
        table.sort(filteredData, self.SortFunction[sortTagId])
    else
        XLog.Error(string.format("XUiBfrtRoomCharacter:FilterRefresh函数错误，没有定义标签：%s的排序函数", sortTagId))
        return
    end

    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    local teamCharIdMap = self.TeamCharIdMap
    local teamSelectPos = self.TeamSelectPos
    local selectId = teamCharIdMap[teamSelectPos]

    self:RefreshCharacterTypeTips()
    self:UpdateCharacterList(filteredData, function(charDic)
        if not selectId or selectId == 0
        or not self.CharacterGrids[selectId]
        or characterType ~= XCharacterConfigs.GetCharacterType(selectId)
        or not charDic[selectId]
        then
            selectId = filteredData[1].Id
        end

        self:SelectCharacter(selectId)

        for _, id in pairs(teamCharIdMap) do
            if id > 0 then
                local grid = self.CharacterGrids[id]
                if grid then
                    grid:SetInTeam(true)
                end
            end
        end
    end)
end