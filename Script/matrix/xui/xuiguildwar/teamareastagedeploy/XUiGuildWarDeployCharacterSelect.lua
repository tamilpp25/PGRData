local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiGuildWarCharacterSelectSelf = require("XUi/XUiGuildWar/TeamAreaStageDeploy/ChildPanel/XUiGuildWarTeamAreaCharacterSelectSelf")
local XUiGuildWarCharacterSelectAssistant = require("XUi/XUiGuildWar/TeamAreaStageDeploy/ChildPanel/XUiGuildWarTeamAreaCharacterSelectAssistant")

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

--复制XUiGuildWarAssistantSelect过来的(包括子界面) 部分代码结构较为蛋疼
---@class XUiGuildWarDeployCharacterSelect:XLuaUi@refer to XUiStrongholdRoomCharacter
local XUiGuildWarDeployCharacterSelect = XLuaUiManager.Register(XLuaUi, "UiGuildWarDeployCharacterSelect")

function XUiGuildWarDeployCharacterSelect:Ctor()
    self._CurrentCharacterId = false
    self._TabIndex = TabBtnIndex.Normal
    ---@type XTerm3SecretRootGWNode
    self._RootNode = false
    ---@type XTerm3SecretChildGWNode
    self._ChildNode = false
    ---@type XGuildWarAreaBuild
    self._Build = false --根节点队伍阵列 由多个队伍组成
    ---@type XGuildWarAreaBuild
    self._Team = false --当前选择的队伍
    self._MemberPos = false --当前选择的角色位置
    self._isDefaultSelect = true
end

--------- 打开界面 OpenData数据
--- RootNode : XGWNode(队伍区域战略点)
--- ChildNode : 区域子节点
--- MemberPos : 角色位置
function XUiGuildWarDeployCharacterSelect:OnStart(OpenData)
    self._RootNode = OpenData.RootNode
    self._ChildNode = OpenData.ChildNode
    self._Build = self._RootNode:GetTeamBuild()
    self._Team = self._ChildNode:GetXTeam()
    self._MemberPos = OpenData.MemberPos or 1
    self:InitSceneRoot()
    self:Init()
    self:UpdateDataSource()
    if self._isDefaultSelect then
        --若果第一次启动 则获取当前位置选择的角色 并跳到指定种类标签
        local member = self._Team:GetMember(self._MemberPos)
        if member then
            if member:IsAssitant() then
                self._TabIndex = TabBtnIndex.Assistant
            elseif XMVCA.XCharacter:GetIsIsomer(member:GetEntityId()) then
                self._TabIndex = TabBtnIndex.Isomer
            else
                self._TabIndex = TabBtnIndex.Normal
            end
        end
    end
    self.PanelCharacterTypeBtns:SelectIndex(self._TabIndex)
end

--初始化场景UI
function XUiGuildWarDeployCharacterSelect:InitSceneRoot()
    local root = self.UiModelGo.transform

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
--初始化UI
function XUiGuildWarDeployCharacterSelect:Init()
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

    local playAnimationCb = function(animName)
        self:PlayAnimationWithMask(animName)
    end
    
    -- assistant characters
    self.OthersPanel = XUiGuildWarCharacterSelectAssistant.New({
        Ui = self.PanelOthers,
        RootUi = self,
        XBuild = self._Build,
        XTeam = self._Team,
        MemberPos = self._MemberPos,
        SelectCharacterCb = handler(self, self.OnSelectCharacterData),
        PlayAnimationCB = playAnimationCb,
        CloseUiHandler = handler(self, self.Close),
        JoinTeamHandler = handler(self, self.OnBtnJoinTeamClicked),
        QuitTeamHandler = handler(self, self.OnBtnQuitTeamClick),
    })
    
    -- my characters
    self.SelfPanel = XUiGuildWarCharacterSelectSelf.New({
        Ui = self.PanelSelf,
        RootUi = self,
        XBuild = self._Build,
        XTeam = self._Team,
        MemberPos = self._MemberPos,
        SelectCharacterCb = handler(self, self.OnSelectCharacter),
        PlayAnimationCB = playAnimationCb,
        CloseUiHandler = handler(self, self.Close),
        JoinTeamHandler = handler(self, self.OnBtnJoinTeamClicked),
        QuitTeamHandler = handler(self, self.OnBtnQuitTeamClick),
    })

    -- button click
    self:RegisterClickEvent(self.BtnTeaching, self.OnBtnTeachingClick)

    -- filter
    self.BtnFilter.gameObject:SetActiveEx(true)
    self:RegisterClickEvent(self.BtnFilter, self.OnBtnFilterClick)
end
--启动
function XUiGuildWarDeployCharacterSelect:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE_CHARACTER_LIST, self.UpdateAssistantCharacterList, self)
end
--关闭
function XUiGuildWarDeployCharacterSelect:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE_CHARACTER_LIST, self.UpdateAssistantCharacterList, self)
    self.OthersPanel:OnDisable()
end

--更新界面数据 以及 界面
function XUiGuildWarDeployCharacterSelect:UpdateDataSource(selectedEntityId)
    --更新普通和独域角色界面
    if self._TabIndex == TabBtnIndex.Normal then
        self.SelfPanel:Show(XEnumConst.CHARACTER.CharacterType.Normal, selectedEntityId, self:GetFilterKey())
        self.OthersPanel:Hide()
        return
    end
    if self._TabIndex == TabBtnIndex.Isomer then
        self.SelfPanel:Show(XEnumConst.CHARACTER.CharacterType.Isomer, selectedEntityId, self:GetFilterKey())
        self.OthersPanel:Hide()
        return
    end
    --更新支援角色界面
    if self._TabIndex == TabBtnIndex.Assistant then
        self.SelfPanel:Hide()
        self.OthersPanel:Show(self:GetFilterKey())
        return
    end
    self.SelfPanel:Hide()
    self.OthersPanel:Hide()
end
--判断独域机体是否开启
function XUiGuildWarDeployCharacterSelect:IsIsomerLock()
    return not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer)
end
--点击左边类型按钮
function XUiGuildWarDeployCharacterSelect:OnBtnGroupCharacterTypeClicked(tabIndex)
    -- 检查功能是否开启
    if tabIndex == TabBtnIndex.Isomer and
        not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer)
    then
        return
    end
    self._TabIndex = tabIndex
    --如果是第一次加载（刚打开界面）
    if self._isDefaultSelect then 
        self._isDefaultSelect = false
        local member = self._Team:GetMember(self._MemberPos)
        self:UpdateDataSource(member and member:GetEntityId())
        return
    end
    self:UpdateDataSource()
end
--通过角色ID 玩家ID 选中角色 刷新界面
function XUiGuildWarDeployCharacterSelect:OnSelectCharacter(characterId, playerId)
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
    XRedPointManager.CheckOnceByButton(self.BtnTeaching, { XRedPointConditions.Types.CONDITION_CELICA_TEACH }, characterId)
end

-- 点击编入队伍按钮
-- memberData.EntityId
-- memberData.PlayerId
function XUiGuildWarDeployCharacterSelect:OnBtnJoinTeamClicked(memberData, pos, resultCB)
    local teamIndex = self._Build:GetXTeamIndex(self._Team)
    local result, msg = self._Build:SetUpEntity(teamIndex, memberData, pos)
    if result then --编入队伍成功
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildWarTeamAreaSetMemberSuccess"))
        resultCB(true) 
    end 
    if msg then --如果编入队伍需要玩家选择
        local title = CS.XTextManager.GetText("GuildWarTeamAreaTitle")
        XUiManager.DialogTip(title, msg, nil, nil, function()
            local result = self._Build:SetUpEntity(teamIndex, memberData, pos, true)
            if result then XUiManager.TipMsg(CS.XTextManager.GetText("GuildWarTeamAreaSetMemberSuccess")) end
            resultCB(result)
        end)
    else
        resultCB(false)
    end
end

-- 点击退出队伍按钮
function XUiGuildWarDeployCharacterSelect:OnBtnQuitTeamClick(pos)
    local teamIndex = self._Build:GetXTeamIndex(self._Team)
    return self._Build:KickOutPos(teamIndex, pos)
end

--通过数据组 选中角色 刷新界面
function XUiGuildWarDeployCharacterSelect:OnSelectCharacterData(data)
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
    XRedPointManager.CheckOnceByButton(self.BtnTeaching, { XRedPointConditions.Types.CONDITION_CELICA_TEACH }, characterId)
end

--更新角色模型显示
function XUiGuildWarDeployCharacterSelect:UpdateRoleModel()
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

--关闭自己界面
function XUiGuildWarDeployCharacterSelect:Close(updated, memberData)
    if updated then
        self:EmitSignal("UpdateEntityId", memberData)
    end
    XUiGuildWarDeployCharacterSelect.Super.Close(self)
end

--更新助战角色列表
function XUiGuildWarDeployCharacterSelect:UpdateAssistantCharacterList()
    self.OthersPanel:UpdateData()
end

--点击教学按钮
function XUiGuildWarDeployCharacterSelect:OnBtnTeachingClick()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self._CurrentCharacterId)
end

--根据按钮索引 获取角色种类
function XUiGuildWarDeployCharacterSelect:GetFilterKey()
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

--点击分类按钮
function XUiGuildWarDeployCharacterSelect:OnBtnFilterClick()
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
    XLuaUiManager.Open("UiCommonCharacterFilterTipsOptimization", panel:GetEntities(true), self:GetFilterKey(), function ()
        self:UpdateDataSource()
    end)
end

--界面销毁时
function XUiGuildWarDeployCharacterSelect:OnDestroy()
    XUiGuildWarDeployCharacterSelect.Super.OnDestroy(self)
    --在普通角色 支援角色详细界面里会建立筛选数据 在关闭界面时清理掉
    XDataCenter.CommonCharacterFiltManager.ClearCacheData()
end

return XUiGuildWarDeployCharacterSelect
