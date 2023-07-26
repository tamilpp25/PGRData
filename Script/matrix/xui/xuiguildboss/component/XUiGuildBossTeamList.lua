--工会boss队员头像组件
local XUiGuildBossTeamList = XClass(nil, "XUiGuildBossTeamList")

function XUiGuildBossTeamList:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.MaxHeadNum = 3
end

function XUiGuildBossTeamList:Init(data, characterHeadInfoList, needBigHead)
    characterHeadInfoList = characterHeadInfoList or {}
    local emptyNum = 0
    for i = 1, self.MaxHeadNum do
        self["TeamHeadObj" .. i].gameObject:SetActiveEx(false)
        if data[i] and data[i] <= 0 then
            emptyNum = emptyNum + 1 -- 靠左对齐
        else
            local index = i - emptyNum
            self["TeamHeadObj" .. index].gameObject:SetActiveEx(true)
            if i <= #data then
                self["TryMarkObj" .. index].gameObject:SetActiveEx(data[i] < 1000000)
                --Head
                local characterId
                if XRobotManager.CheckIsRobotId(data[i]) then
                    characterId = XRobotManager.GetCharacterId(data[i])
                else
                    characterId = data[i]
                end
                local iconPath
                local headInfo = characterHeadInfoList[i] or {}
                if needBigHead then
                    iconPath = XDataCenter.CharacterManager.GetCharBigHeadIcon(characterId, true, headInfo.HeadFashionId, headInfo.HeadFashionType)
                else
                    iconPath = XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId, true, headInfo.HeadFashionId, headInfo.HeadFashionType)
                end
                self["ImgHead" .. index]:SetRawImage(iconPath)

                self["TeamHeadObj" .. index].gameObject:SetActiveEx(true)
            else
                self["TeamHeadObj" .. index].gameObject:SetActiveEx(false)
            end
        end
    end
end

return XUiGuildBossTeamList