--虚像地平线战斗准备换人界面
local XUiExpeditionRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiExpeditionRoomCharacter")
local XUiExpeditionRoomCharListPanel = require("XUi/XUiExpedition/Battle/ChangeMember/XUiExpeditionRoomCharListPanel")
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

function XUiExpeditionRoomCharacter:OnStart(teamData, changePos, cb)
    self.TeamData = teamData
    self.ChangePos = changePos
    local baseId = teamData[changePos]
    if baseId ~= 0 then
        local selectIndex = XDataCenter.ExpeditionManager.GetCharaDisplayIndex(baseId)
        self.CurrentSelect = selectIndex
    else
        self.CurrentSelect = 1
    end
    self.CharacterList:UpdateData(self.CurrentSelect)
    self.CallBack = cb
end

function XUiExpeditionRoomCharacter:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    self.CharacterList:UpdateData(self.CurrentSelect or 1)
end

function XUiExpeditionRoomCharacter:Refresh(characterId, robotId, baseId)
    self.RobotId = robotId
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
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    if not robotCfg then return end
    self.RoleModelPanel:UpdateRobotModel(robotId, characterId, callback, robotCfg and robotCfg.FashionId, robotCfg and robotCfg.WeaponId)
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
end

function XUiExpeditionRoomCharacter:OnBtnBackClick()
    self:Close()
end

function XUiExpeditionRoomCharacter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiExpeditionRoomCharacter:OnBtnJoinClick()
    local eChara = XDataCenter.ExpeditionManager.GetECharaByDisplayIndex(self.CurrentSelect)
    local id = eChara:GetBaseId()
    for k, v in pairs(self.TeamData) do
        if v == id then
            self.TeamData[k] = 0
            break
        end
    end

    self.TeamData[self.ChangePos] = id
    if self.CallBack then
        self.CallBack(self.TeamData)
        self.CallBack = nil
    end
    self:Close()
end

function XUiExpeditionRoomCharacter:OnBtnQuitClick()
    local count = 0
    for _, v in pairs(self.TeamData) do
        if v > 0 then
            count = count + 1
        end
    end

    local eChara = XDataCenter.ExpeditionManager.GetECharaByDisplayIndex(self.CurrentSelect)
    local id = eChara:GetBaseId()
    for k, v in pairs(self.TeamData) do
        if v == id then
            self.TeamData[k] = 0
            break
        end
    end

    if self.CallBack then
        self.CallBack(self.TeamData)
        self.CallBack = nil
    end
    self:Close()
end