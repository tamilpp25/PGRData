local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiGuildWarCharacterSelectSelf = require("XUi/XUiGuildWar/Assistant/XUiGuildWarCharacterSelectSelf")
local XUiGuildWarCharacterSelectAssistant = require("XUi/XUiGuildWar/Assistant/XUiGuildWarCharacterSelectAssistant")
local XUiGuildWarCharacterFilter = require("XUi/XUiGuildWar/Assistant/Filter/XUiGuildWarCharacterFilter")

local TabBtnIndex = {
    Normal = 1,
    Isomer = 2,
    Assistant = 3
}

local FilterKey = {
    GuildWarSelfNormal = "GuildWarSelfNormal",
    GuildWarSelfIsomer = "GuildWarSelfIsomer",
    GuildWarOthers = "GuildWarAssistant"
}

---@class XUiGuildWarCharacterSelect:XLuaUi@refer to XUiStrongholdRoomCharacter
local XUiGuildWarCharacterSelect = XLuaUiManager.Register(XLuaUi, "UiGuildWarCharacterSelect")

function XUiGuildWarCharacterSelect:Ctor()
    self._CurrentCharacterId = false
    self._TabIndex = TabBtnIndex.Normal
    ---@type XGuildWarTeam
    self._Team = false
    self._Pos = false
    self._isDefaultSelect = true
end

function XUiGuildWarCharacterSelect:OnStart(team, pos)
    self._Team = team or XDataCenter.GuildWarManager.GetBattleManager():GetTeam()
    self._Pos = pos or 1
    self:Init()
    self:InitSceneRoot()
    XDataCenter.GuildWarManager.RequestAssistCharacterList()

    local member = self._Team:GetMember(self._Pos)
    if member and not member:IsEmpty() then
        self:UpdateDataSource(member:GetEntityId())
    else
        self:UpdateDataSource()
    end
end

function XUiGuildWarCharacterSelect:Init()
    -- model
    local panelModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelModel, self.Name, nil, true)

    -- main and back
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)

    -- PanelAsset
    local ItemId = XDataCenter.ItemManager.ItemId
    XUiPanelAsset.New(self, self.PanelAsset,
            ItemId.FreeGem,
            ItemId.ActionPoint,
            ItemId.Coin)

    -- 独域机体
    if self:IsIsomerLock() then
        self.BtnTabShougezhe:SetDisable(true)
    end

    -- 角色类型按钮组
    self.PanelCharacterTypeBtns:Init(
            {
                [TabBtnIndex.Normal] = self.BtnTabGouzaoti,
                [TabBtnIndex.Isomer] = self.BtnTabShougezhe,
                [TabBtnIndex.Assistant] = self.BtnTabHelp,
            },
            function(tabIndex)
                self:OnBtnGroupCharacterTypeClicked(tabIndex)
            end
    )

    local closeUiFunc = handler(self, self.Close)
    local playAnimationCb = function(animName)
        self:PlayAnimationWithMask(animName)
    end

    local path = CS.XGame.ClientConfig:GetString("UiPanelCommonCharacterFilterV2P6")
    local parentTransform = self.PanelCharacterFilter.transform
    local filterUi = parentTransform:LoadPrefab(path)

    ---@type XUiGuildWarCharacterFilter
    self._Filter = XUiGuildWarCharacterFilter.New(filterUi, self)

    -- assistant characters
    ---@type XUiGuildWarCharacterSelectAssistant
    self.OthersPanel = XUiGuildWarCharacterSelectAssistant.New(self.PanelOthers, handler(self, self.OnSelectCharacterData), closeUiFunc, playAnimationCb,
            self._Team, self._Pos, self, self._Filter
    )
    -- my characters
    ---@type XUiGuildWarCharacterSelectSelf
    self.SelfPanel = XUiGuildWarCharacterSelectSelf.New(self.PanelSelf, handler(self, self.OnSelectCharacter), closeUiFunc, playAnimationCb,
            self._Team, self._Pos)

    self:InitFilter()

    -- button click
    self:RegisterClickEvent(self.BtnTeaching, self.OnBtnTeachingClick)
    self.BtnTeaching:ShowReddot(false)

    -- filter
    self.BtnFilter.gameObject:SetActiveEx(true)
    self:RegisterClickEvent(self.BtnFilter, self.OnBtnFilterClick)
end

function XUiGuildWarCharacterSelect:OnEnable()
    if self._TabIndex == TabBtnIndex.Normal then
        self.SelfPanel:UpdateCharacter()
        self._Filter:OnlyRefreshData()
    end
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE_CHARACTER_LIST, self.UpdateAssistantCharacterList, self)
end

function XUiGuildWarCharacterSelect:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE_CHARACTER_LIST, self.UpdateAssistantCharacterList, self)
    self.OthersPanel:OnDisable()
end

function XUiGuildWarCharacterSelect:InitFilter()
    local XUiGuildWarCharacterSelectAssistantGrid = require("XUi/XUiGuildWar/Assistant/XUiGuildWarCharacterSelectAssistantGrid")
    local XUiGuildWarCharacterSelectSelfGrid = require("XUi/XUiGuildWar/Assistant/XUiGuildWarCharacterSelectSelfGrid")
    self._Filter:InitDynamicTable(XUiGuildWarCharacterSelectSelfGrid, XUiGuildWarCharacterSelectAssistantGrid, self.SelfPanel.SViewCharacterList, self.OthersPanel.SViewCharacterList)
    self:ImportAssistantCharacterList()

    self._Filter:InitData(function(t)
        if self._Filter:IsTagSupport() then
            self:OnSelectCharacterData(t)
            self.OthersPanel:UpdateCharacterData(t)
        else
            ---@type XCharacter
            local character = t
            self:OnSelectCharacter(character:GetId(), XPlayer.Id)
            self.SelfPanel:UpdateCharacterData(character)
        end

    end, function(targetBtn)
        self._Filter:ChangeDynamicTable()
        if self._Filter:IsTagSupport() then
            self.OthersPanel:Show()
            self.SelfPanel:Hide()
            local list = self:ImportAssistantCharacterList()

            local isValid = #list > 0
            self.OthersPanel:UpdateEmpty(isValid)
            self.BtnTeaching.gameObject:SetActiveEx(isValid)
        else
            if XTool.IsTableEmpty(self._Filter:GetCurShowList()) then
                self.BtnTeaching.gameObject:SetActiveEx(false)
                self.SelfPanel:Hide()
            else
                self.BtnTeaching.gameObject:SetActiveEx(true)
                self.SelfPanel:Show()
            end
            self.OthersPanel:Hide()
        end

    end, nil, function(index, grid, char)
        if self._Filter:IsTagSupport() then
            ---@type XUiGuildWarCharacterSelectAssistantGrid
            local g = grid
            g:Refresh(char)
        else
            ---@type XUiGuildWarCharacterSelectSelfGrid
            local g = grid
            ---@type XCharacter
            local character = char
            local characterId = character:GetId()
            g:Refresh(characterId)
            g:SetInTeam(self._Team:GetEntityIdIsInTeam(characterId, XPlayer.Id))
        end
    end)
end

function XUiGuildWarCharacterSelect:UpdateDataSource(characterId)
    local list = XMVCA.XCharacter:GetCharacterList()
    self._Filter:ImportList(list)
    self._Filter:RefreshList()
    if characterId then
        self._Filter:DoSelectCharacter(characterId)
    end
end

function XUiGuildWarCharacterSelect:IsIsomerLock()
    return not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer)
end

function XUiGuildWarCharacterSelect:OnBtnGroupCharacterTypeClicked(tabIndex)
    -- 检查功能是否开启
    if tabIndex == TabBtnIndex.Isomer and
            not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer)
    then
        return
    end
    self._TabIndex = tabIndex
    if self._isDefaultSelect then
        self._isDefaultSelect = false
        local member = self._Team:GetMember(self._Pos)
        self:UpdateDataSource(member and member:GetEntityId())
        return
    end
    self:UpdateDataSource()
end

function XUiGuildWarCharacterSelect:OnSelectCharacter(characterId, playerId)
    self._CurrentCharacterId = characterId
    if not characterId then
        self.RoleModelPanel:HideRoleModel()
        self.BtnTeaching.gameObject:SetActiveEx(false)
        return
    end
    self.BtnTeaching.gameObject:SetActiveEx(true)
    self.RoleModelPanel:ShowRoleModel()
    self.PlayerId = playerId
    self:UpdateRoleModel()
end

function XUiGuildWarCharacterSelect:OnSelectCharacterData(data)
    if not data then
        self.RoleModelPanel:HideRoleModel()
        self.BtnTeaching.gameObject:SetActiveEx(false)
        return
    end
    self.BtnTeaching.gameObject:SetActiveEx(true)
    self.RoleModelPanel:ShowRoleModel()
    local characterId = data.FightNpcData.Character.Id
    self._CurrentCharacterId = characterId
    self.PlayerId = data.PlayerId
    self:UpdateRoleModel()
end

function XUiGuildWarCharacterSelect:UpdateRoleModel()
    local playerId = self.PlayerId

    local characterId = self._CurrentCharacterId

    if not XTool.IsNumberValid(characterId) then
        self.RoleModelPanel.GameObject:SetActiveEx(false)
        return
    end
    self.RoleModelPanel.GameObject:SetActiveEx(true)

    local targetPanelRole = self.PanelRoleModel
    local targetUiName = self.Name
    local cb = function(model)
        if not model then
            return
        end
        self.PanelDrag.Target = model.transform
        if self.SelectTabIndex == TabBtnIndex.Normal then
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        elseif self.SelectTabIndex == TabBtnIndex.Isomer then
            self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        end
    end

    local fashionId = nil
    local growUpLevel = nil
    if XTool.IsNumberValid(playerId) and playerId ~= XPlayer.Id then
        --别人的角色信息
        fashionId = XDataCenter.GuildWarManager.GetAssistantCharacterFashion(characterId, playerId)
        growUpLevel = XDataCenter.GuildWarManager.GetAssistantCharacterLiberateLv(characterId, playerId)
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.RoleModelPanel:UpdateCharacterModel(
            characterId,
            targetPanelRole,
            targetUiName,
            cb,
            nil,
            fashionId,
            growUpLevel
    )
end

function XUiGuildWarCharacterSelect:InitSceneRoot()
    local root = self.UiModelGo.transform

    -- if self.PanelRoleModel then
    --     self.PanelRoleModel:DestroyChildren()
    -- end
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.ImgEffectLogoGouzao = root:FindTransform("ImgEffectLogoGouzao")
    self.ImgEffectLogoGanran = root:FindTransform("ImgEffectLogoGanran")
    self.CameraFar = {
        root:FindTransform("UiCamFarLv"),
        root:FindTransform("UiCamFarGrade"),
        root:FindTransform("UiCamFarQuality"),
        root:FindTransform("UiCamFarSkill"),
        root:FindTransform("UiCamFarrExchange"),
        root:FindTransform("UiCamFarEnhanceSkill"),
    }
    self.CameraNear = {
        root:FindTransform("UiCamNearLv"),
        root:FindTransform("UiCamNearGrade"),
        root:FindTransform("UiCamNearQuality"),
        root:FindTransform("UiCamNearSkill"),
        root:FindTransform("UiCamNearrExchange"),
        root:FindTransform("UiCamNearEnhanceSkill"),
    }
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiGuildWarCharacterSelect:Close(updated, memberData)
    if updated then
        self:EmitSignal("UpdateEntityId", memberData)
    end
    XUiGuildWarCharacterSelect.Super.Close(self)
end

function XUiGuildWarCharacterSelect:UpdateAssistantCharacterList()
    self:ImportAssistantCharacterList()
    if self._TabIndex == TabBtnIndex.Assistant then
        self._Filter:RefreshList()
    end
end

function XUiGuildWarCharacterSelect:ImportAssistantCharacterList()
    local list = self.OthersPanel:GetEntities()
    self._Filter:ImportSupportList(list)
    return list
end

function XUiGuildWarCharacterSelect:OnBtnTeachingClick()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self._CurrentCharacterId)
end

function XUiGuildWarCharacterSelect:GetFilterKey()
    if self._TabIndex == TabBtnIndex.Normal then
        return FilterKey.GuildWarSelfNormal
    end
    if self._TabIndex == TabBtnIndex.Isomer then
        return FilterKey.GuildWarSelfIsomer
    end
    if self._TabIndex == TabBtnIndex.Assistant then
        return FilterKey.GuildWarOthers
    end
end

function XUiGuildWarCharacterSelect:OnBtnFilterClick()
    local panel
    if self._TabIndex == TabBtnIndex.Normal then
        panel = self.SelfPanel
    end
    if self._TabIndex == TabBtnIndex.Isomer then
        panel = self.SelfPanel
    end
    if self._TabIndex == TabBtnIndex.Assistant then
        panel = self.OthersPanel
    end
    XLuaUiManager.Open("UiCommonCharacterFilterTipsOptimization", panel:GetEntities(true), self:GetFilterKey(), function()
        self:UpdateDataSource()
    end)
end

function XUiGuildWarCharacterSelect:OnDestroy()
    XUiGuildWarCharacterSelect.Super.OnDestroy(self)
    XDataCenter.CommonCharacterFiltManager.ClearCacheData()
end

return XUiGuildWarCharacterSelect
