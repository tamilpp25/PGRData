-- 兵法蓝图出战换人界面
local XUiRpgTowerRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiRpgTowerRoomCharacter")
local CharaListPanel = require("XUi/XUiRpgTower/Battle/ChangeMember/XUiRpgTowerRoomCharaListPanel")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiRpgTowerRoomCharacter:OnAwake()
    XTool.InitUiObject(self)
    self:InitPanels()
    self:InitButtons()
end

function XUiRpgTowerRoomCharacter:OnStart(xteam, changePos)
    self.TeamData = xteam:GetEntityIds()
    self.ChangePos = changePos
    local robotId = self.TeamData[changePos]
    if robotId and robotId > 0 then
        local characterId = XRobotManager.GetCharacterId(robotId)
        self.RCharacter = XDataCenter.RpgTowerManager.GetTeamMemberByCharacterId(characterId)
    end
    self:Refresh()
end

function XUiRpgTowerRoomCharacter:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    self.CharacterList:UpdateData(self.CurrentSelect or 1)
end

function XUiRpgTowerRoomCharacter:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiRpgTowerRoomCharacter:InitPanels()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.CharacterList = CharaListPanel.New(self.SViewCharacterList, self)
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiRpgTowerRoomCharacter:InitButtons()
    self.BtnBack.CallBack = function() self:OnClickBack() end
    self.BtnMainUi.CallBack = function() self:OnClickMainUi() end
    self:RegisterClickEvent(self.BtnJoinTeam, self.OnBtnJoinClick, self)
    self:RegisterClickEvent(self.BtnQuitTeam, self.OnBtnQuitClick, self)
end

function XUiRpgTowerRoomCharacter:OnClickBack()
    self:Close()
end

function XUiRpgTowerRoomCharacter:OnClickMainUi()
    XLuaUiManager.RunMain()
end

function XUiRpgTowerRoomCharacter:OnBtnJoinClick()
    local id = self.RCharacter:GetRobotId()
    local isUpdated = false
    for k, v in pairs(self.TeamData) do
        if v == id then
            self.TeamData[k] = 0
            isUpdated = true
            break
        end
    end
    local oldId = self.TeamData[self.ChangePos]
    self.TeamData[self.ChangePos] = id
    isUpdated = oldId ~= id
    self:Close(isUpdated, id)
end

function XUiRpgTowerRoomCharacter:OnBtnQuitClick()
    local id = self.RCharacter:GetRobotId()
    local isUpdated = false
    for k, v in pairs(self.TeamData) do
        if v == id then
            self.TeamData[k] = 0
            isUpdated = true
            break
        end
    end
    self:Close(isUpdated, id)
end

function XUiRpgTowerRoomCharacter:Refresh()
    self.CharacterList:UpdateData()
end

function XUiRpgTowerRoomCharacter:OnCharaSelect(rChara)
    self.RCharacter = rChara
    self:UpdateModel()
    self:SetTeamBtns()
end

function XUiRpgTowerRoomCharacter:UpdateModel()
    local characterId = self.RCharacter:GetCharacterId()
    local robotId = self.RCharacter:GetRobotId()
    if not characterId then return end
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    if not robotCfg then return end
    self.RoleModelPanel:UpdateRobotModel(robotId, characterId, nil, robotCfg and robotCfg.FashionId, robotCfg and robotCfg.WeaponId)
end

function XUiRpgTowerRoomCharacter:SetTeamBtns()
    local isInTeam = self.RCharacter:GetIsInTeam()
    self.BtnJoinTeam.gameObject:SetActiveEx(not isInTeam)
    self.BtnQuitTeam.gameObject:SetActiveEx(isInTeam)
end

function XUiRpgTowerRoomCharacter:OnGetEvents()
    return { XEventId.EVENT_RPGTOWER_RESET }
end

function XUiRpgTowerRoomCharacter:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_RPGTOWER_RESET then
        self:OnActivityReset()
    end
end

function XUiRpgTowerRoomCharacter:OnActivityReset()
    if self.IsReseting then return end
    self.IsReseting = true
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerFinished"))
end

function XUiRpgTowerRoomCharacter:Close(updated, id)
    if updated then
        self:EmitSignal("UpdateEntityId", id)
    end
    XUiRpgTowerRoomCharacter.Super.Close(self)
end