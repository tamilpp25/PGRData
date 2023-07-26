local XUiGridWorldBossTeamList = XClass(nil, "XUiGridWorldBossTeamList")

function XUiGridWorldBossTeamList:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.MaxHeadNum = 3
end

function XUiGridWorldBossTeamList:Init(data)
    if not data then
        return
    end
    for i = 1, self.MaxHeadNum do
        if not data[i] or data[i].Id == 0 then
            self["TeamHeadObj" .. i].gameObject:SetActiveEx(false)
        else
            self["TeamHeadObj" .. i].gameObject:SetActiveEx(true)
            if i <= #data then
                self["TryMarkObj" .. i].gameObject:SetActiveEx(false)

                local characterId = data[i].Id
                local headInfo = data[i].CharacterHeadInfo or {}
                local iconPath = XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId, true, headInfo.HeadFashionId, headInfo.HeadFashionType)

                self["ImgHead" .. i]:SetRawImage(iconPath)

                self["TeamHeadObj" .. i].gameObject:SetActiveEx(true)
            else
                self["TeamHeadObj" .. i].gameObject:SetActiveEx(false)
            end
        end
    end
end

return XUiGridWorldBossTeamList