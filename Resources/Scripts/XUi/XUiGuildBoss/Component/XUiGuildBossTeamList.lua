--工会boss队员头像组件
local XUiGuildBossTeamList = XClass(nil, "XUiGuildBossTeamList")

function XUiGuildBossTeamList:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.MaxHeadNum = 3
end

function XUiGuildBossTeamList:Init(data, liberateLvs, needBigHead)
    for i = 1, self.MaxHeadNum do
        if data[i] <= 0 then
            self["TeamHeadObj" .. i].gameObject:SetActiveEx(false)
        else
            self["TeamHeadObj" .. i].gameObject:SetActiveEx(true)
            if i <= #data then
                self["TryMarkObj" .. i].gameObject:SetActiveEx(data[i] < 1000000)
                --Head
                local characterId
                if XRobotManager.CheckIsRobotId(data[i]) then
                    characterId = XRobotManager.GetCharacterId(data[i])
                else
                    characterId = data[i]
                end
                local iconPath
                if needBigHead then
                    iconPath = XDataCenter.CharacterManager.GetCharBigHeadIcon(characterId, liberateLvs[i], true)
                else
                    iconPath = XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId, liberateLvs[i], true)
                end
                self["ImgHead" .. i]:SetRawImage(iconPath)
                
                self["TeamHeadObj" .. i].gameObject:SetActiveEx(true)
            else
                self["TeamHeadObj" .. i].gameObject:SetActiveEx(false)
            end
        end
    end
end

return XUiGuildBossTeamList