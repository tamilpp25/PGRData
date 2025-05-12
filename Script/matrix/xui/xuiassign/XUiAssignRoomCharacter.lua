local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
local XUiAssignRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiAssignRoomCharacter")

local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local TipCount = 0
local TempOrgCharList = {}

local TabBtnIndex = {
    Normal = 1,
    Isomer = 2,
}

function XUiAssignRoomCharacter:OnAwake()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    ag = XMVCA:GetAgency(ModuleId.XCommonCharacterFilter)
    ---@type XCommonCharacterFilterAgency
    self.FiltAgecy = ag

    self.CharacterGrids = {}
    self:InitButton()
    self:InitModel()
    -- self:InitDynamicTable()
end

function XUiAssignRoomCharacter:InitButton()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.GridCharacter.gameObject:SetActiveEx(false)

    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnJoinTeam, self.OnBtnJoinTeamClick)
    self:RegisterClickEvent(self.BtnQuitTeam, self.OnBtnQuitTeamClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnTeamPrefab, self.OnBtnTeamPrefabClick)
    self:RegisterClickEvent(self.BtnPartner, self.OnBtnPartnerClick)
    self:RegisterClickEvent(self.BtnFashion, self.OnBtnFashionClick)
    self:RegisterClickEvent(self.BtnConsciousness, self.OnBtnConsciousnessClick)
    self:RegisterClickEvent(self.BtnWeapon, self.OnBtnWeaponClick)
    self:RegisterClickEvent(self.BtnTeaching, self.OnBtnTeachingClicked)

    self:RegisterClickEvent(self.BtnFilter, self.OnBtnFilterClick)


    -- local tabBtns = { self.BtnTabGouzaoti, self.BtnTabShougezhe }
    -- self.PanelCharacterTypeBtns:Init(tabBtns, function(index) self:OnSelectCharacterType(index) end)

    XEventManager.AddEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.RefreshTeamData, self)
end

function XUiAssignRoomCharacter:InitModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiCharacterSystemV2P6, nil, true, nil, true)
end

function XUiAssignRoomCharacter:InitFilter()
    self.PanelFilter = self.FiltAgecy:InitFilter(self.PanelCharacterFilter, self)
    local onSeleCb = function (character)
        self:OnRoleCharacter(character)
    end
    local tagClickedCb = function ()
        self:UpdateRightCharacterInfo()
    end

    local refreshGridsFun = function (index, grid, data)
        local isInTeam = XDataCenter.FubenAssignManager.CheckCharacterInCurGroupTeam(data.Id, self.GroupId)
        local isLock = XDataCenter.FubenAssignManager.CheckCharacterInMultiTeamLock(data.Id, self.GroupId)
        grid:UpdateGrid(data)
        grid:SetInTeam(isInTeam and not isLock)
        grid:SetIsLock(isLock)
    end
    
    local checkIsInTeam = function (id)
        return not XDataCenter.FubenAssignManager.CheckCharacterInCurGroupTeam(id, self.GroupId)
    end
    self.PanelFilter:InitData(onSeleCb, tagClickedCb, nil, 
    refreshGridsFun, XUiGridCharacter, checkIsInTeam)
    local list = self.CharacterAgency:GetOwnCharacterList()
    self.PanelFilter:ImportList(list, self.OrgSeleCharacterId)
end

-- function XUiAssignRoomCharacter:InitDynamicTable()
--     self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
--     self.DynamicTable:SetProxy(XUiGridCharacter, self)
--     self.DynamicTable:SetDelegate(self)
-- end

function XUiAssignRoomCharacter:OnStart(orgSeleCharacterId, teamId, clickTeamPos, teamOrderInGroup, groupId, ablityRequire)
    TipCount = 0
    self.OrgSeleCharacterId = orgSeleCharacterId
    self.TeamId = teamId
    self.ClickTeamPos = clickTeamPos
    self.TeamOrderInGroup = teamOrderInGroup
    self.GroupId = groupId
    self.AblityRequire = ablityRequire

    self.CurrTeamData = XDataCenter.FubenAssignManager.GetTeamDataById(teamId)
    
    if groupId then
        self.ChapterId = XFubenAssignConfigs.GetChapterIdByGroupId(groupId)
        self.GroupData = XDataCenter.FubenAssignManager.GetGroupDataById(groupId)
    end

    if self.ChapterId then
        self.ChapterData = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)
    end

    -- 自动选中点击的角色
    if XTool.IsNumberValid(orgSeleCharacterId) then
        local charaType = XMVCA.XCharacter:GetCharacterType(orgSeleCharacterId)
        local charcter = XMVCA.XCharacter:GetCharacter(orgSeleCharacterId)
        self.InitCharacterType = charaType
        self.LastSelectNormalCharacter = charaType == TabBtnIndex.Normal and charcter or self.LastSelectNormalCharacter 
        self.LastSelectIsomerCharacter = charaType == TabBtnIndex.Isomer and charcter or self.LastSelectIsomerCharacter 
    end
    self:InitFilter()
end

function XUiAssignRoomCharacter:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    -- self.PanelCharacterTypeBtns:SelectIndex(self.InitCharacterType or TabBtnIndex.Normal)

    -- 部分ui文本
    self.TxtTeamInfoName.text = CS.XTextManager.GetText("AssignTeamTitle", self.TeamOrderInGroup) -- 作战梯队{0}
    self.TxtRequireAbility.text = self.AblityRequire and self.AblityRequire or ""
    self.PanelFilter:RefreshList()
end

-- function XUiAssignRoomCharacter:OnSelectCharacterType(index)
--     if index == TabBtnIndex.Isomer and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer) then
--         return
--     end

--     self.SelectTabBtnIndex = index
--     if index == TabBtnIndex.Normal then
--         self.ImgEffectHuanren.gameObject:SetActiveEx(false)
--         self.ImgEffectHuanren.gameObject:SetActiveEx(true)
--         self:UpdateCharacters(self.LastSelectNormalCharacter)
--     elseif index == TabBtnIndex.Isomer then
--         self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
--         self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
--         self:UpdateCharacters(self.LastSelectIsomerCharacter)
--     end
-- end

-- function XUiAssignRoomCharacter:RoleSortFun(list)
--     local unInTeamList = {}
--     local inTeamList = {}

--     for i, character in ipairs(list) do
--         if XDataCenter.FubenAssignManager.CheckCharacterInCurGroupTeam(character.Id, self.GroupId) then
--             table.insert(inTeamList, character)
--         else
--             table.insert(unInTeamList, character)
--         end
--     end

--     return appendArray(unInTeamList, inTeamList)
-- end

-- -- 刷新左边角色列表
-- function XUiAssignRoomCharacter:UpdateCharacters(character)
--     local characterType = self.SelectTabBtnIndex
--     local filterList = XDataCenter.CommonCharacterFiltManager.GetSelectListData(characterType)
--     local charList = filterList or XMVCA.XCharacter:GetOwnCharacterList(characterType)
--     charList = self:RoleSortFun(charList)
--     local index = 1
--     if character then
--         local isIn, curIndex = table.contains(charList, character)
--         index = isIn and curIndex or index
--     end
    
--     self.CurrCharListIndex = index
--     self:UpdateDynamicTable(charList, index)
-- end

-- function XUiAssignRoomCharacter:UpdateDynamicTable(list, index)
--     self.CurrShowList = list
--     self.DynamicTable:SetDataSource(list)
--     self.DynamicTable:ReloadDataASync(index or 1)
-- end

-- function XUiAssignRoomCharacter:OnDynamicTableEvent(event, index, grid)
--     if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
--         local isCurrSelected = self.CurrCharListIndex == index
--         local character = self.CurrShowList[index]
--         local isInTeam = XDataCenter.FubenAssignManager.CheckCharacterInCurGroupTeam(character.Id, self.GroupId)
--         local isLock = XDataCenter.FubenAssignManager.CheckCharacterInMultiTeamLock(character.Id, self.GroupId)

--         grid:UpdateGrid(character)
--         grid:SetInTeam(isInTeam and not isLock)
--         grid:SetIsLock(isLock)
--         grid:SetSelect(isCurrSelected)

--         if isCurrSelected then
--             self:OnRoleCharacter(self.CurrShowList[index])
--             self.CurrGrid = grid
--         end
--     elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
--         self.CurrGrid:SetSelect(false)
--         grid:SetSelect(true)
--         self:OnRoleCharacter(self.CurrShowList[index])
--         self.CurrGrid = grid
--         self.CurrCharListIndex = index
--     end
-- end

-- 角色被选中
function XUiAssignRoomCharacter:OnRoleCharacter(character)
    if not character then
        return
    end
    self.CurCharacter = character
    if XMVCA.XCharacter:GetCharacterType(character.Id) == TabBtnIndex.Normal then
        self.LastSelectNormalCharacter = self.CurCharacter
    else 
        self.LastSelectIsomerCharacter = self.CurCharacter
    end

    self:UpdateRightCharacterInfo()
    self:UpdateRoleModel()
end

-- 刷新右边信息
function XUiAssignRoomCharacter:UpdateRightCharacterInfo()
    if not self.CurCharacter then
        return
    end
    local isInCurrTeam = self.CurrTeamData:CheckIsInTeam(self.CurCharacter.Id)
    
    self.BtnJoinTeam.gameObject:SetActiveEx(not isInCurrTeam)
    self.BtnQuitTeam.gameObject:SetActiveEx(isInCurrTeam)
    
    local curShowList = self.PanelFilter:GetCurShowList()
    local isListEmpty = XTool.IsTableEmpty(curShowList)
    if isListEmpty then
        self.BtnJoinTeam.gameObject:SetActiveEx(false)
        self.BtnQuitTeam.gameObject:SetActiveEx(false)
    end

    self.TeamBtn.gameObject:SetActiveEx(not isListEmpty)
    self.BtnTeaching.gameObject:SetActiveEx(not isListEmpty)

    -- self.BtnConsciousness.gameObject:SetActiveEx(not isListEmpty)
    -- self.BtnFashion.gameObject:SetActiveEx(not isListEmpty)
    -- self.BtnWeapon.gameObject:SetActiveEx(not isListEmpty)
    -- self.BtnPartner.gameObject:SetActiveEx(not isListEmpty)

    -- self.PanelRoleContent.gameObject:SetActiveEx(not isListEmpty)
    -- self.PanelRoleModel.gameObject:SetActiveEx(not isListEmpty)
    -- self.PanelEmptyList.gameObject:SetActiveEx(isListEmpty)
end

-- 刷新3D模型
function XUiAssignRoomCharacter:UpdateRoleModel()
    if not self.CurCharacter then
        return
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    local cb = function(model)
        self.PanelDrag.Target = model.transform
        local isSomer = self.CharacterAgency:GetIsIsomer(self.CurCharacter.Id)
        if isSomer then
            self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        else
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        end
    end
   
    --MODEL_UINAME对应UiModelTransform表，设置模型位置
    self.RoleModelPanel:UpdateCharacterModel(self.CurCharacter.Id, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiCharacterSystemV2P6, cb)
end

-- 通过队伍预设更新队伍
function XUiAssignRoomCharacter:RefreshTeamData(teamPrefabData)
    local prefabCharList = teamPrefabData.TeamData
    
    local currCharList = self.CurrTeamData:GetMemberList()
    TempOrgCharList = XTool.Clone(currCharList)
    local isLimit = nil
    local afterList = {}
    for pos, v in pairs(currCharList) do
        local charIdInPrefab = prefabCharList[pos]
        local spPos = XDataCenter.FubenAssignManager.GetMemberOrderByIndex(pos, #currCharList)
        if self:CheckLimitBeforeChangeTeam(charIdInPrefab, spPos) then
            isLimit = true
        end
        afterList[pos] = prefabCharList[pos]
    end

    self.CurrTeamData:SetMemberList(afterList)

    local prefabCaptainPos = teamPrefabData.CaptainPos
    local prefabFirstFightPos = teamPrefabData.FirstFightPos
    prefabCaptainPos = prefabCaptainPos > #currCharList and 1 or prefabCaptainPos
    prefabFirstFightPos = prefabFirstFightPos > #currCharList and 1 or prefabFirstFightPos

    self.CurrTeamData:SetLeaderIndex(prefabCaptainPos)
    self.CurrTeamData:SetFirstFightIndex(prefabFirstFightPos)
end

function XUiAssignRoomCharacter:CheckLimitBeforeChangeTeam(charId, pos, isAfterClose)
    -- 队伍压制拦截
    if XDataCenter.FubenAssignManager.CheckCharacterInMultiTeamLock(charId, self.GroupId) then
        XUiManager.TipError(CS.XTextManager.GetText("StrongholdElectricDeployInTeamLock"))
        return true
    end

    -- 检测多队伍间互相替换
    local isIn, otherTeamData, otherTeamOrder = XDataCenter.FubenAssignManager.CheckCharacterInCurGroupTeam(charId, self.GroupId)
    if isIn and otherTeamData ~= self.CurrTeamData then
        -- 在其他编队
        local title = CS.XTextManager.GetText("AssignDeployTipTitle")
        local characterName = XMVCA.XCharacter:GetCharacterName(charId)
        local oldTeamName = CS.XTextManager.GetText("AssignTeamTitle", otherTeamOrder)
        local newTeamName = CS.XTextManager.GetText("AssignTeamTitle", self.TeamOrderInGroup)
        local content = CS.XTextManager.GetText("AssignDeployTipContent", characterName, oldTeamName, newTeamName)
        local CloseTeamPrefabCb = function ()
            TipCount = TipCount - 1
            if XLuaUiManager.IsUiShow("UiRoomTeamPrefab") and TipCount == 0 then
                XLuaUiManager.Close("UiRoomTeamPrefab")
            end

            if isAfterClose then
                self:Close()
            end
        end
        TipCount = TipCount + 1
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function ()
            -- 如果是在队伍内进行的位置更改 要把被更改的也一起还原
            local orgMemberData = TempOrgCharList[pos]
            if not orgMemberData then
                return
            end
            local orgCharId = orgMemberData:GetCharacterId()
            local _, memberDataNew, index = self.CurrTeamData:CheckIsInTeam(orgCharId)
            if memberDataNew then
                memberDataNew:SetCharacterId(TempOrgCharList[index]:GetCharacterId())
            end

            local memberData = self.CurrTeamData:GetMemberList()[pos]
            if memberData then
                memberData:SetCharacterId(orgCharId)
            end
            CloseTeamPrefabCb()
        end, function ()
            local otherTeamPos = otherTeamData:GetCharacterOrder(charId)
            -- 确认交换角色
            XDataCenter.FubenAssignManager.SwapMultiTeamMember(self.CurrTeamData, pos, otherTeamData, otherTeamPos)
            CloseTeamPrefabCb()
        end)
        return true
    end

    return false
end

function XUiAssignRoomCharacter:OnBtnJoinTeamClick()
    if self:CheckLimitBeforeChangeTeam(self.CurCharacter.Id, self.ClickTeamPos, true) then
        return
    end

    self.CurrTeamData:SetMember(self.ClickTeamPos, self.CurCharacter.Id)
    self:Close()
end

-- 队伍预设
function XUiAssignRoomCharacter:OnBtnTeamPrefabClick()
    local stageId = self.GroupData:GetStageId()[1]

    local characterLimitType = XTool.IsNumberValid(stageId) and XFubenConfigs.GetStageCharacterLimitType(stageId)
    local stageInfo = XTool.IsNumberValid(stageId) and XDataCenter.FubenManager.GetStageInfo(stageId) or {}
    local stageType = stageInfo.Type

    local closeCb = function()
        self:Close()
    end

    XLuaUiManager.Open("UiRoomTeamPrefab", 
    self.CurrTeamData:GetLeaderIndex(),
    self.CurrTeamData:GetFirstFightIndex(), 
    characterLimitType,
    nil, 
    stageType, 
    nil, 
    closeCb, 
    stageId)
end

function XUiAssignRoomCharacter:OnBtnTeachingClicked()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self.CurCharacter:GetId(), true)
end

function XUiAssignRoomCharacter:OnBtnWeaponClick()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CurCharacter.Id, nil, true)
end

function XUiAssignRoomCharacter:OnBtnConsciousnessClick()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self.CurCharacter.Id)
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

function XUiAssignRoomCharacter:OnBtnQuitTeamClick()
    local pos = self.CurrTeamData:GetCharacterOrder(self.CurCharacter.Id)
    self.CurrTeamData:SetMember(pos, 0)

    self:Close()
end

function XUiAssignRoomCharacter:OnBtnFashionClick()
    XLuaUiManager.Open("UiFashion", self.CurCharacter.Id)
end

function XUiAssignRoomCharacter:OnBtnFilterClick()
    local characterType = self.SelectTabBtnIndex
    local characterList = self:RoleSortFun(XMVCA.XCharacter:GetOwnCharacterList(characterType))
    XLuaUiManager.Open("UiCommonCharacterFilterTipsOptimization", characterList, characterType, function (afterFiltList)
        self.CurrRoleListIndex = 1
        self:UpdateDynamicTable(afterFiltList)
    end, characterType)
end

function XUiAssignRoomCharacter:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiAssignRoomCharacter:OnDestroy()
    XDataCenter.CommonCharacterFiltManager.ClearCacheData() --清除筛选缓存数据
    XEventManager.RemoveEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.RefreshTeamData, self)
end