local XUiUnionKillSelectRole = XLuaUiManager.Register(XLuaUi, "UiUnionKillXuanRen")
local XUiGridUnionCharacterItem = require("XUi/XUiFubenUnionKill/XUiGridUnionCharacterItem")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiUnionKillSelectRole:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
    XDataCenter.ItemManager.ItemId.FreeGem,
    XDataCenter.ItemManager.ItemId.ActionPoint,
    XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end

    self.BtnFashion.CallBack = function() self:OnBtnFashionClick() end
    self.BtnConsciousness.CallBack = function() self:OnBtnConsciousnessClick() end
    self.BtnWeapon.CallBack = function() self:OnBtnWeaponClick() end
    self.BtnJoinTeam.CallBack = function() self:OnBtnJoinTeamClick() end
    self.BtnQuitTeam.CallBack = function() self:OnBtnQuitTeamClick() end

    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")

    self.CharacterItemList = {}
end

function XUiUnionKillSelectRole:OnDestroy()
end


function XUiUnionKillSelectRole:OnStart(args)
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, nil, nil, true)
    self.StageId = args.StageId
    self.Index = args.Index
    self.DefaultSelectId = args.DefaultSelectId
    self.DefaultSelectOwner = args.DefaultSelectOwner
    self.InTeamList = args.InTeamList
    self.CharacterInTeamList = args.CharacterInTeamList
    self.CallBack = args.CallBack

    self.SelectableList = args.CharacterList
    table.sort(self.SelectableList, function(char1, char2)
        local flagWeight1 = char1.Flag == XFubenUnionKillConfigs.UnionKillCharType.Share and 1 or 0
        local flagWeight2 = char2.Flag == XFubenUnionKillConfigs.UnionKillCharType.Share and 1 or 0
        if flagWeight1 == flagWeight2 then
            return char1.Ability > char2.Ability
        end
        return flagWeight1 > flagWeight2
    end)

    self:SelectCharacterList()
end

function XUiUnionKillSelectRole:OnEnable()
    if self.SelectableList then
        for i = 1, #self.SelectableList do
            local characterItem = self.SelectableList[i]
            self.CharacterItemList[i]:UpdateGrid(characterItem)
        end
        if self.CurCharacter then
            local fashionId
            if self.CurCharacter.Flag == XFubenUnionKillConfigs.UnionKillCharType.Share then
                local shareNpcData = self.CurCharacter.OwnerInfo.ShareNpcData
                if shareNpcData then
                    fashionId = shareNpcData.Character.FashionId
                end
            else
                local characterInfo = XDataCenter.CharacterManager.GetCharacter(self.CurCharacter.Id)
                fashionId = characterInfo.FashionId
            end
            self:UpdateRoleModel(self.CurCharacter, fashionId)
        end
    end
end

function XUiUnionKillSelectRole:SelectCharacterList()
    -- local defaultCharacterId = self.SelectableList[1] and self.SelectableList[1].Id
    local defaultIndex = 1
    for i = 1, #self.SelectableList do
        local characterItem = self.SelectableList[i]
        if self.DefaultSelectId and characterItem.Id == self.DefaultSelectId then
            if self.DefaultSelectOwner and self.DefaultSelectOwner == characterItem.OwnerId then
                --defaultCharacterId = self.DefaultSelectId
                defaultIndex = i
            end
        end

        if not self.CharacterItemList[i] then
            local item = CS.UnityEngine.Object.Instantiate(self.GridMainLineCharacter)
            local grid = XUiGridUnionCharacterItem.New(self, item, characterItem, function(character)
                self:OnCharacterClick(character, i)
            end)
            grid.GameObject:SetActiveEx(true)
            grid.Transform:SetParent(self.PanelRoleContent, false)
            self.CharacterItemList[i] = grid
        end

        self.CharacterItemList[i]:UpdateGrid(characterItem)
        local key = string.format("%s_%s", tostring(characterItem.OwnerId), tostring(characterItem.Id))
        self.CharacterItemList[i]:SetInTeam(self.InTeamList[key])
        self.CharacterItemList[i]:SetHasSameCard(not self.InTeamList[key] and self.CharacterInTeamList[tostring(characterItem.Id)])
    end
    for i = #self.SelectableList + 1, #self.CharacterItemList do
        self.CharacterItemList[i].GameObject:SetActiveEx(false)
    end

    if defaultIndex > 0 then
        self:SetlectCharacter(defaultIndex)
    end
end

function XUiUnionKillSelectRole:OnCharacterClick(character, index)
    if self.CurCharacter and self.CurCharacter == character then
        return
    end
    if character then
        self.CurCharacter = character
    end
    if self.CurCharacterItem then
        self.CurCharacterItem:SetSelect(false)
    end

    -- local characterId = character.Id
    local fashionId
    if character.Flag == XFubenUnionKillConfigs.UnionKillCharType.Share then
        local shareNpcData = self.CurCharacter.OwnerInfo.ShareNpcData
        if shareNpcData then
            fashionId = shareNpcData.Character.FashionId
        end
    else
        local characterInfo = XDataCenter.CharacterManager.GetCharacter(self.CurCharacter.Id)
        fashionId = characterInfo.FashionId
    end
    self.CurCharacterItem = self.CharacterItemList[index]
    self.CurCharacterItem:UpdateGrid(self.CurCharacter)
    self.CurCharacterItem:SetSelect(true)
    local key = string.format("%s_%s", tostring(self.CurCharacter.OwnerId), tostring(self.CurCharacter.Id))
    self.CurCharacterItem:SetInTeam(self.InTeamList[key])
    self.CurCharacterItem:SetHasSameCard(not self.InTeamList[key] and self.CharacterInTeamList[tostring(self.CurCharacter.Id)])

    -- 更新按钮状态
    self:UpdateFunctionalBtns(self.CurCharacter)
    -- 更新角色模型
    self:UpdateRoleModel(self.CurCharacter, fashionId)
end

-- 更新按钮状态
function XUiUnionKillSelectRole:UpdateFunctionalBtns(characterItem)

    self.BtnFashion.gameObject:SetActiveEx(characterItem.Flag == XFubenUnionKillConfigs.UnionKillCharType.Own)
    self.BtnConsciousness.gameObject:SetActiveEx(characterItem.Flag == XFubenUnionKillConfigs.UnionKillCharType.Own)
    self.BtnWeapon.gameObject:SetActiveEx(characterItem.Flag == XFubenUnionKillConfigs.UnionKillCharType.Own)

    local teamCache = XDataCenter.FubenUnionKillManager.GetCacheTeam()
    local isJoin = false
    for k, v in pairs(teamCache or {}) do
        if k == self.Index and v.PlayerId == characterItem.OwnerId and v.CharacterId == characterItem.Id then
            isJoin = true
            break
        end
    end

    self.BtnJoinTeam.gameObject:SetActiveEx(not isJoin)
    self.BtnQuitTeam.gameObject:SetActiveEx(isJoin)
end

-- 更换模型
function XUiUnionKillSelectRole:UpdateRoleModel(character, fashionId)
    self.RoleModelPanel:UpdateCharacterModel(character.Id, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiUnionKillSelectRole, function(model)
        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        if not model then return end
        self.PanelDrag.Target = model.transform

        if character.Flag == XFubenUnionKillConfigs.UnionKillCharType.Share then
            self.RoleModelPanel:UpdateEquipsModelsByFightNpcData(model, character.OwnerInfo.ShareNpcData)
        end
    end, nil, fashionId)
end

function XUiUnionKillSelectRole:SetlectCharacter(index)
    local grid = self.CharacterItemList[index]
    if grid then
        self:Adjust2Center(grid)
    end

    local characterItem = self.SelectableList[index]
    self:OnCharacterClick(characterItem, index)
end

function XUiUnionKillSelectRole:OnBtnBackClick()
    if self.CallBack then
        self.CallBack(nil, false)
    end
    self:Close()
end

function XUiUnionKillSelectRole:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiUnionKillSelectRole:OnBtnFashionClick()
    -- 共享角色返回
    if not self.CurCharacter then return end
    XLuaUiManager.Open("UiFashion", self.CurCharacter.Id)
end

function XUiUnionKillSelectRole:OnBtnConsciousnessClick()
    -- 共享角色返回
    if not self.CurCharacter then return end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self.CurCharacter.Id)
end

function XUiUnionKillSelectRole:OnBtnWeaponClick()
    -- 共享角色返回
    if not self.CurCharacter then return end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CurCharacter.Id, nil, true)
end

function XUiUnionKillSelectRole:OnBtnJoinTeamClick()
    if not self.CurCharacter then return end
    -- 出现选中的角色已经存在队伍中
    local key = string.format("%s_%s", tostring(self.CurCharacter.OwnerId), tostring(self.CurCharacter.Id))
    if not self.InTeamList[key] and self.CharacterInTeamList[tostring(self.CurCharacter.Id)] then
        XUiManager.TipMsg(CS.XTextManager.GetText("UnionSelectSameRole"))
        return
    end

    if self.CallBack then
        self.CallBack(self.CurCharacter, true)
    end
    self:Close()
end

function XUiUnionKillSelectRole:OnBtnQuitTeamClick()
    if not self.CurCharacter then return end
    if self.CallBack then
        self.CallBack(self.CurCharacter, false)
    end
    self:Close()
end

function XUiUnionKillSelectRole:Adjust2Center(grid)
    local normalizedPosition
    local count = self.SViewCharacterList.content.transform.childCount
    local index = grid.Transform:GetSiblingIndex()
    if index > count / 2 then
        normalizedPosition = (index + 1) / count
    else
        normalizedPosition = (index - 1) / count
    end
    self.SViewCharacterList.verticalNormalizedPosition = math.max(0, math.min(1, (1 - normalizedPosition)))
end