local XUiDeploySlotGrid = require("XUi/XUiDoubleTowers/Deploy/XUiDeploySlotGrid")

--==============================
---@desc 战备界面-插件格子
--==============================
local XUiSlotGrid = XClass(XUiDeploySlotGrid, "XUiSlotGrid")

function XUiSlotGrid:InitUi()
    self.Icon = XUiHelper.TryGetComponent(self.Transform, "PartnerIcon", "RawImage")
    self.BtnDetail = XUiHelper.TryGetComponent(self.Transform, "BtnCarryPartner", "XUiButton")
    self.PanelNoPartner = XUiHelper.TryGetComponent(self.Transform, "PanelNoPartner")
    self.ImgLevelBg = XUiHelper.TryGetComponent(self.Transform, "ImgLevelBg")
    self.TxtSubSkillLevel = XUiHelper.TryGetComponent(self.ImgLevelBg.transform, "RawImage/TxtSubSkillLevel", "Text")
    self.BtnLock = XUiHelper.TryGetComponent(self.Transform, "BtnLock", "XUiButton")
end

--==============================
---@desc 重写点击方法
--==============================
function XUiSlotGrid:OnBtnDetailClick()
    XLuaUiManager.Open("UiDoubleTowersDeploy", self.ModuleType)
end

--==============================
---@desc 战备界面-天赋页签
--==============================
local XUiTalentPanel = XClass(nil, "XUiTalentPanel")

--模块类型 --> 最大插件数
local Type2SkillNumber = {
    [XDoubleTowersConfigs.ModuleType.Role] = XDoubleTowersConfigs.GetRolePluginMaxCount(),
    [XDoubleTowersConfigs.ModuleType.Guard] = XDoubleTowersConfigs.GetGuardPluginMaxCount()
}

function XUiTalentPanel:Ctor(ui, moduleType)
    XTool.InitUiObjectByUi(self, ui)
    self.MaxPluginCount = Type2SkillNumber[moduleType]

    self.BaseInfo = XDataCenter.DoubleTowersManager.GetBaseInfo()
    self.TeamDb = self.BaseInfo:GetTeamDb()
    self.ModuleType = moduleType
    
    self:InitCb()
end

function XUiTalentPanel:Refresh()
    self.PluginGrids = {}
    self.BasePluginId = self.TeamDb:GetBasePluginId(self.ModuleType)
    self.PluginList = self.TeamDb:GetPluginList(self.ModuleType)
    for idx = 1, self.MaxPluginCount do
        local grid = self.PluginGrids[idx]
        if not grid then
            grid = XUiSlotGrid.New(self["Skill" .. idx], idx, true, self.ModuleType)
            self.PluginGrids[idx] = grid
        end
        grid:Refresh(self.PluginList[idx])
    end
    local hasBasePlugin = XTool.IsNumberValid(self.BasePluginId)
    self.RImgBasePluginIcon.gameObject:SetActiveEx(hasBasePlugin)
    if hasBasePlugin then
        if self.ModuleType == XDoubleTowersConfigs.ModuleType.Role then
            local icon  = XDoubleTowersConfigs.GetRoleIconByPluginLevelId(self.BasePluginId)
            self.RImgBasePluginIcon:SetRawImage(icon)
        elseif self.ModuleType == XDoubleTowersConfigs.ModuleType.Guard then
            local icon  = XDoubleTowersConfigs.GetGuardIconByPluginLevelId(self.BasePluginId, true)
            self.RImgBasePluginIcon:SetRawImage(icon)
        end
    end
end

function XUiTalentPanel:InitCb()
    self.BtnBasePlugin.CallBack = function()
        XLuaUiManager.Open("UiDoubleTowersDeploy", self.ModuleType)
    end
end

-- XUiCharacter
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiDoubleTowersRoom:XLuaUi
local XUiDoubleTowersRoom = XLuaUiManager.Register(XLuaUi, "UiDoubleTowersRoom")

function XUiDoubleTowersRoom:Ctor()
    self._StageId = false
    self._PanelModelPanel = false
end

function XUiDoubleTowersRoom:OnAwake()
end

function XUiDoubleTowersRoom:OnStart(stageId)
    self._StageId = stageId

    self:InitUi()

    -- back, main, asset
    self:BindExitBtns(self.BtnBack, self.BtnMain)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.DoubleTower)

    -- model
    self:InitRole()

    -- 角色点击
    self:RegisterClickEvent(self.BtnChar2, self.OnBtnCharClicked)

    -- 部署
    self:RegisterClickEvent(
        self.BtnDeploy,
        function()
            XLuaUiManager.Open("UiDoubleTowersDeploy")
        end
    )

    -- fight
    self:RegisterClickEvent(
        self.BtnEnterFight,
        function()
            if not self._StageId then
                return
            end
            local stageConfig = XDataCenter.FubenManager.GetStageCfg(self._StageId)
            local teamId = XDoubleTowersConfigs.TeamId
            local team = XDataCenter.DoubleTowersManager.GetXTeam()
            local isEmpty = team and team:GetIsEmpty()
            if isEmpty then
                XUiManager.TipText("DoubleTowersChooseTeamMember")
                return
            end
            local isAssist = false
            local challengeCount = 1
            XDataCenter.DoubleTowersManager.RequestDoubleTowerSetTeam(
                function(res)
                    if XLuaUiManager.IsUiShow(self.Name) then
                        XLuaUiManager.Close(self.Name)
                    end
                    XDataCenter.FubenManager.EnterFight(stageConfig, teamId, isAssist, challengeCount)
                end
            )
        end
    )

    -- pet
    self:InitPet()
end

function XUiDoubleTowersRoom:OnEnable()
    self:Refresh()
end

function XUiDoubleTowersRoom:InitRole(model)
    local uiModelRoot = self.PanelFirstRole2

    -- 背景特效
    local teamConfig = XTeamConfig.GetTeamCfgById(1)
    -- local panelRoleBGEffectGo = uiModelRoot:FindTransform("PanelRoleEffect").gameObject
    -- panelRoleBGEffectGo:LoadPrefab(teamConfig.EffectPath, false)

    local uiModelRoot = self.UiModelGo.transform
    self._PanelModelPanel =
        XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelRoleModel2"), self.Name, nil, true, nil, true, true)
    self.BtnEnterFight:SetDisable(true)
end

function XUiDoubleTowersRoom:Refresh()
    self:UpdateRoleModel()
    self:UpdatePartners()
    self.TalentPanelRole:Refresh()
    self.TalentPanelGuard:Refresh()
end

--更新模型
function XUiDoubleTowersRoom:UpdateRoleModel()
    local team = self:GetXTeam()
    local entityId = team.EntitiyIds[team.CaptainPos]
    local charId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    local roleModelPanel = self._PanelModelPanel
    roleModelPanel:ShowRoleModel() -- 先Active 再加载模型以及播放动画
    local callback = function()
        self.BtnEnterFight:SetDisable(false)
    end

    local uiPanelRoleModel = self._PanelModelPanel
    local characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
    self.ImgAdd2.gameObject:SetActiveEx(characterViewModel == nil)
    if characterViewModel then
        local sourceEntityId = characterViewModel:GetSourceEntityId()
        uiPanelRoleModel:UpdateCharacterModel(
            sourceEntityId,
            nil,
            nil,
            callback,
            nil,
            characterViewModel:GetFashionId()
        )
        uiPanelRoleModel:ShowRoleModel()
        self:UpdateCharacterInfo(true)
    else
        uiPanelRoleModel:HideRoleModel()
        self.CharacterInfo2.gameObject:SetActiveEx(false)
        self.PanelFirstRole2.gameObject:SetActiveEx(false)
    end
end

function XUiDoubleTowersRoom:UpdateCharacterInfo(isShow)
    self.PanelFirstRole2.gameObject:SetActiveEx(isShow)
    self.CharacterInfo2.gameObject:SetActiveEx(isShow)
    if isShow then
        local team = self:GetXTeam()
        local entityId = team:GetEntityIdByTeamPos(team:GetCaptainPos())
        local character = XDataCenter.CharacterManager.GetCharacter(entityId)
        if character then
            local characterViewModel = character:GetCharacterViewModel()
            if characterViewModel then
                self.TxtFight2.text = characterViewModel:GetAbility(entityId)
                self.RImgType2:SetRawImage(characterViewModel:GetProfessionIcon())
            else
                self.PanelFirstRole2.gameObject:SetActiveEx(false)
                self.CharacterInfo2.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiDoubleTowersRoom:OnBtnCharClicked()
    RunAsyn(
        function()
            local team = self:GetXTeam()
            local index = team:GetCaptainPos()
            local oldEntityId = team:GetEntityIdByTeamPos(index)
            local proxy = self.Proxy
            XLuaUiManager.Open("UiBattleRoomRoleDetail", self._StageId, team, index, proxy)
            local signalCode, newEntityId = XLuaUiManager.AwaitSignal("UiBattleRoomRoleDetail", "UpdateEntityId", self)
            if signalCode ~= XSignalCode.SUCCESS then
                return
            end
            if oldEntityId == newEntityId then
                return
            end
            if team:GetEntityIdByTeamPos(index) <= 0 then
                return
            end
            -- 播放音效
            local soundType = XEnumConst.Favorability.SoundEventType.MemberJoinTeam
            if team:GetCaptainPos() == index then
                soundType = XEnumConst.Favorability.SoundEventType.CaptainJoinTeam
            end
            XMVCA.XFavorability:PlayCvByType(XEntityHelper.GetCharacterIdByEntityId(newEntityId), soundType)
            XDataCenter.DoubleTowersManager.SetRoleId(newEntityId)
            XDataCenter.DoubleTowersManager.RequestDoubleTowerSetTeam()
        end
    )
end

function XUiDoubleTowersRoom:InitPet()
    -- 宠物加号点击
    local btn = self.CharacterPets2:GetObject("BtnClick")
    self:RegisterClickEvent(
        btn,
        function()
            local team = self:GetXTeam()
            XDataCenter.PartnerManager.GoPartnerCarry(team:GetEntityIdByTeamPos(team:GetCaptainPos()), false)
        end
    )
    self:UpdatePartners()
end

-- 这一块都是复制的代码
function XUiDoubleTowersRoom:UpdatePartners()
    local entityId = 0
    local partner = nil
    local characterViewModel = nil
    local uiObjPartner
    local rImgParnetIcon = nil
    local team = self:GetXTeam()
    entityId = team:GetEntityIdByTeamPos(team:GetCaptainPos())
    partner = self.Proxy:GetPartnerByEntityId(entityId)
    characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
    uiObjPartner = self.CharacterPets2
    uiObjPartner.gameObject:SetActiveEx(characterViewModel ~= nil)
    rImgParnetIcon = uiObjPartner:GetObject("RImgType")
    rImgParnetIcon.gameObject:SetActiveEx(partner ~= nil)
    if partner then
        rImgParnetIcon:SetRawImage(partner:GetIcon())
    end
end

function XUiDoubleTowersRoom:InitUi()
    self.UiPointerCharacter = self.BtnChar2:GetComponent("XUiPointer")
    local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
    self.Proxy = XUiBattleRoleRoomDefaultProxy.New(self:GetXTeam(), self._StageId)

    self.TalentPanelRole = XUiTalentPanel.New(self.PanelTalentRole, XDoubleTowersConfigs.ModuleType.Role)
    self.TalentPanelGuard = XUiTalentPanel.New(self.PanelTalentGuard, XDoubleTowersConfigs.ModuleType.Guard)
end

function XUiDoubleTowersRoom:GetXTeam()
    return XDataCenter.DoubleTowersManager.GetXTeam()
end
