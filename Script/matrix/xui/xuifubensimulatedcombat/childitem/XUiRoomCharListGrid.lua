--战斗成员选择界面 成员列表
local XUiSimulatedCombatRoomCharListGrid = XClass(nil, "XUiExpeditionRoomCharacterGrid")
function XUiSimulatedCombatRoomCharListGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiSimulatedCombatRoomCharListGrid:Init(ui, rootUi)
    self.RootUi = rootUi
    self.PanelSelected.gameObject:SetActiveEx(false)
    self:SetInTeam(false)
end
 
function XUiSimulatedCombatRoomCharListGrid:Refresh(charId)
    local data = XDataCenter.FubenSimulatedCombatManager.GetCurStageMemberDataByCharId(charId)
    if not data then
        XLog.Error("无法找到data, charId = ", charId)
        return
    end
    self.Data = data
    self.RobotId = data.RobotId
    self.CharacterId = charId
    
    self.RImgHeadIcon:SetRawImage(XRobotManager.GetRobotSmallHeadIcon(self.RobotId))
    self.TxtFight.text = XRobotManager.GetRobotAbility(self.RobotId)
    self.TxtLevel.text = data.Star
    self:RefreshElements()
end

function XUiSimulatedCombatRoomCharListGrid:SetSelect(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
    self.IsSelect = isSelect
    if isSelect and self.Data then self.RootUi:Refresh(self.CharacterId, self.RobotId) end
end

function XUiSimulatedCombatRoomCharListGrid:SetInTeam(isInTeam)
    self.ImgInTeam.gameObject:SetActiveEx(isInTeam)
end

function XUiSimulatedCombatRoomCharListGrid:RefreshElements()
    local elementList = XMVCA.XCharacter:GetCharacterAllElement(self.CharacterId, true)
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if rImg and elementList[i] then
            rImg.transform.gameObject:SetActiveEx(true)
            local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        elseif rImg and not elementList[i] then
            rImg.transform.gameObject:SetActiveEx(false)
        end
    end
end

return XUiSimulatedCombatRoomCharListGrid