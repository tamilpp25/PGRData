
local XUiRpgTowerBattleRoomExpand = XClass(nil, "XUiRpgTowerBattleRoomExpand")
function XUiRpgTowerBattleRoomExpand:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    -- XTeam
    self.Team = nil
end

-- team : XTeam
function XUiRpgTowerBattleRoomExpand:SetData(team)
    self.Team = team
    for index, robotId in pairs(self.Team:GetEntityIds()) do
        self["PanelTag" .. index].gameObject:SetActiveEx(false)
        if robotId and robotId > 0 then
            local charaId = XRobotManager.GetCharacterId(robotId)
            local chara = XDataCenter.RpgTowerManager.GetTeamMemberByCharacterId(charaId)
            if chara then
                self["PanelTag" .. index].gameObject:SetActiveEx(true)
                local talentType = chara:GetCharaTalentType()
                self["TxtContent" .. index].text = chara:GetCharaTalentTypeName()
                -- self["ImgDi" .. index]:SetSprite(XRpgTowerConfig.GetTalentTypeBattleRoomBgById(talentType))
                self["ImgDi" .. index]:SetSprite(XRpgTowerConfig.GetTalentTypeConfigByCharacterId(charaId, talentType).BattleRoomBg)
            end
        end
    end
end

return XUiRpgTowerBattleRoomExpand