--虚像地平线战斗准备换人界面
local XUiExpeditionRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiExpeditionRoomCharacter")
local XUiExpeditionRoomCharListPanel = require("XUi/XUiExpedition/Battle/ChangeMember/XUiExpeditionRoomCharListPanel")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiExpeditionRoomCharacter:OnAwake()
    XTool.InitUiObject(self)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.CharacterList = XUiExpeditionRoomCharListPanel.New(self.SViewCharacterList, self)
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
    self:AddListener()
end

function XUiExpeditionRoomCharacter:OnStart(teamData, changePos, cb, stageId)
    self.TeamData = teamData
    self.ChangePos = changePos
    self.StageId = stageId
    self.CurrentBaseId = teamData[changePos]
    self.CallBack = cb
end

function XUiExpeditionRoomCharacter:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    self.CharacterList:UpdateData(self.CurrentBaseId)
end

function XUiExpeditionRoomCharacter:Refresh(characterId, baseId, robotId)
    self.CurrentBaseId = baseId
    self.CharacterId = characterId
    self:UpdateModel(characterId, robotId)
    self:SetTeamBtns(baseId)
end

function XUiExpeditionRoomCharacter:UpdateModel(characterId, robotId)
    if not characterId then return end
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    local callback = function()
        self.ModelReady = true
    end
    self.ModelReady = false
    local robotConfig = XRobotManager.GetRobotTemplate(robotId)
    self.RoleModelPanel:UpdateRobotModelNew(robotId, characterId, callback, robotConfig.FashionId, robotConfig.WeaponId)
end

function XUiExpeditionRoomCharacter:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiExpeditionRoomCharacter:OnDestroy()
    if self.CallBack then
        self.CallBack(self.TeamData)
        self.CallBack = nil
    end
end
function XUiExpeditionRoomCharacter:SetTeamBtns(baseId)
    local isInTeam = XDataCenter.ExpeditionManager.GetCharacterIsInTeam(baseId)
    self.BtnJoinTeam.gameObject:SetActiveEx(not isInTeam)
    self.BtnQuitTeam.gameObject:SetActiveEx(isInTeam)
    self.BtnLockTeam.gameObject:SetActiveEx(false)
end
function XUiExpeditionRoomCharacter:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET }
end

function XUiExpeditionRoomCharacter:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.Expedition then return end
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
    end
end
function XUiExpeditionRoomCharacter:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnJoinTeam, self.OnBtnJoinClick)
    self:RegisterClickEvent(self.BtnQuitTeam, self.OnBtnQuitClick)
    self:RegisterClickEvent(self.BtnLockTeam, self.OnBtnLockClick)
    self:RegisterClickEvent(self.BtnDeploy, self.OnBtnDeploy)
    self:RegisterClickEvent(self.BtnTeaching, self.OnBtnTeaching)
end

function XUiExpeditionRoomCharacter:OnBtnBackClick()
    self:CheckRoleInTeam()
end

function XUiExpeditionRoomCharacter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiExpeditionRoomCharacter:OnBtnJoinClick()
    for k, v in pairs(self.TeamData) do
        if v == self.CurrentBaseId then
            self.TeamData[k] = 0
            break
        end
    end

    self.TeamData[self.ChangePos] = self.CurrentBaseId
    self:CheckRoleInTeam()
end

function XUiExpeditionRoomCharacter:OnBtnQuitClick()
    for k, v in pairs(self.TeamData) do
        if v == self.CurrentBaseId then
            self.TeamData[k] = 0
            break
        end
    end

    self:CheckRoleInTeam()
end

function XUiExpeditionRoomCharacter:OnBtnLockClick()
    XUiManager.TipText("ExpeditionMemberLock")
end

function XUiExpeditionRoomCharacter:OnBtnDeploy()
    XLuaUiManager.Open("UiExpeditionRecruit")
end

function XUiExpeditionRoomCharacter:OnBtnTeaching()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self.CharacterId, true)
end

-- 检测队伍里的角色是否已解雇
function XUiExpeditionRoomCharacter:CheckRoleInTeam()
    local count = #self.TeamData
    for i = 1, count do
        local baseId = self.TeamData[i]
        if baseId > 0 then
            local isActive = XDataCenter.ExpeditionManager.IsMemberActive(baseId) -- 检测当前角色id是否在招募的队伍中
            if not isActive then
                self.TeamData[i] = 0
            end
        end
    end

    if self.CallBack then
        self.CallBack(self.TeamData)
        self.CallBack = nil
    end
    self:Close()
end