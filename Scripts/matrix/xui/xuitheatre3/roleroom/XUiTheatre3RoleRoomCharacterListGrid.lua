local XUiTheatre3SettlementMemberCell = require("XUi/XUiTheatre3/Settlement/XUiTheatre3SettlementMemberCell")

---@class XUiTheatre3RoleRoomCharacterListGrid : XUiNode 成员列表
---@field Parent XUiTheatre3RoleRoomDetail
---@field _Control XTheatre3Control
local XUiTheatre3RoleRoomCharacterListGrid = XClass(XUiNode, "XUiTheatre3RoleRoomCharacterListGrid")

function XUiTheatre3RoleRoomCharacterListGrid:OnStart()
    ---@type XUiTheatre3SettlementMemberCell
    self._Character = XUiTheatre3SettlementMemberCell.New(self.CharacterGrid, self)
    self._Pool = {}
    if not self.ImgInitQuality then
        self.ImgInitQuality = XUiHelper.TryGetComponent(self.Transform, "CharHeadCurrentPerfab/PanelInitQuality/ImgInitQuality", "Image")
    end
    self.UiObject = XUiHelper.TryGetComponent(self.CharacterGrid, "", "UiObject")
end

function XUiTheatre3RoleRoomCharacterListGrid:SetData(character)
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(character.Id) -- 机器人的显示与对应的角色一样
    
    self._Id = character.Id
    self._Character:SetDataByMemberId(characterId)
    if self.UiObject then
        XTool.InitUiObjectByInstance(self.UiObject, self)
    end

    local cost = self._Control:GetCharacterCost(characterId)
    for i = 1, cost do
        local go = self._Pool[i]
        if not go then
            go = i == 1 and self.ImgEnergy or XUiHelper.Instantiate(self.ImgEnergy, self.ImgEnergy.parent)
            self._Pool[i] = go
        end
        go.gameObject:SetActiveEx(true)
    end
    for i = cost + 1, #self._Pool do
        self._Pool[i].gameObject:SetActiveEx(false)
    end

    self.TxtBattlePowerNum.text = math.floor(character.Ability)
    self.TxtLvNum.text = self._Control:GetCharacterLv(characterId)
    if self.ImgInTeam then
        self.ImgInTeam.gameObject:SetActiveEx(self._Control:GetEntityIdIsInTeam(self._Id))
    end
    -- 试玩tag
    if self.PanelTry then
        self.PanelTry.gameObject:SetActiveEx(XRobotManager.CheckIsRobotId(self._Id))
    end
    -- 属性tag
    if self.ImgType then
        self.ImgType:SetRawImage(characterAgency:GetCharacterElementIcon(self._Id))
    end
    -- 独域tag
    if self.PanelUniframe then
        local isUniframe = characterAgency:GetIsIsomer(character:GetId())
        self.PanelUniframe.gameObject:SetActiveEx(isUniframe)
    end
    -- 初始品质
    if self.ImgInitQuality then
        local initQuality = characterAgency:GetCharacterInitialQuality(self._Id)
        local icon = characterAgency:GetModelCharacterQualityIcon(initQuality).IconCharacterInit
        self.ImgInitQuality:SetSprite(icon)
    end
    -- 重复出战
    if self.PanelSameRole then
        local isRepeat = self._Control:IsCharacterRepeat(self._Id)
        self.PanelSameRole.gameObject:SetActiveEx(isRepeat)
    end
end

function XUiTheatre3RoleRoomCharacterListGrid:SetSelect(isSelected)
    self.PanelSelected.gameObject:SetActiveEx(isSelected)
end

return XUiTheatre3RoleRoomCharacterListGrid