---@class XUiTheatre3SettlementMemberCell : XUiNode 成员
---@field Parent
---@field _Control XTheatre3Control
local XUiTheatre3SettlementMemberCell = XClass(XUiNode, "XUiTheatre3SettlementMemberCell")

function XUiTheatre3SettlementMemberCell:OnStart()

end

---只显示成员头像
function XUiTheatre3SettlementMemberCell:SetDataByMemberId(memberId)
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local characterIcon = characterAgency:GetCharSmallHeadIcon(memberId)
    self.ImgRole:SetRawImage(characterIcon)

    self.ImgType.gameObject:SetActiveEx(true)
    self.PanelLv.gameObject:SetActiveEx(false)
    self.PanelExp.gameObject:SetActiveEx(false)
    self.PanelLvUp.gameObject:SetActiveEx(false)
end

---显示成员等级信息
---@param data XTheatre3Character
function XUiTheatre3SettlementMemberCell:SetData(data)
    local nowLevel, nowExp, nowNeedExp = self._Control:CalculateCharacterLevel(data.CharacterId, data.Level, data.Exp, data.ExpTemp)
    self.TxtLv.text = nowLevel
    if nowNeedExp == 0 then
        self.ImgExp.fillAmount = 1
    else
        self.ImgExp.fillAmount = nowExp / nowNeedExp
    end
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local characterIcon = characterAgency:GetCharSmallHeadIcon(data.CharacterId)
    self.ImgRole:SetRawImage(characterIcon)

    self.ImgType.gameObject:SetActiveEx(false)
    self.PanelLv.gameObject:SetActiveEx(true)
    self.PanelExp.gameObject:SetActiveEx(true)
    self.PanelLvUp.gameObject:SetActiveEx(nowLevel > data.Level)
end

return XUiTheatre3SettlementMemberCell