local XUiDlcHuntTeamRankMember = require("XUi/XUiDlcHunt/Rank/XUiDlcHuntTeamRankMember")

---@class XUiDlcHuntTeamRankGrid
local XUiDlcHuntTeamRankGrid = XClass(nil, "XUiDlcHuntTeamRankGrid")

function XUiDlcHuntTeamRankGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._Member = {
        XUiDlcHuntTeamRankMember.New(self.GridMember1),
        XUiDlcHuntTeamRankMember.New(self.GridMember2),
        XUiDlcHuntTeamRankMember.New(self.GridMember3)
    }
end

function XUiDlcHuntTeamRankGrid:Update(data)
    if not data then
        for i = 1, #self._Member do
            self._Member[i].GameObject:SetActiveEx(false)
        end
        self.TxtRank.text = 0
        self.ImgRank.gameObject:SetActiveEx(false)
        self.TxtRank.gameObject:SetActiveEx(true)
        self.TxtPoint.text = XUiHelper.GetTime(0, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
        self.TxtDifficulty.text = ""
        return
    end
    for i = 1, #self._Member do
        local member = data.Members[i]
        if member then
            self._Member[i]:Update(member)
            self._Member[i].GameObject:SetActiveEx(true)
        else
            self._Member[i].GameObject:SetActiveEx(false)
        end
    end
    self.TxtPoint.text = data.Time
    self.TxtDifficulty.text = data.DifficultyName
    local image = XDlcHuntConfigs.GetRankImage(data.Rank)
    if image then
        self.ImgRank:SetSprite(image)
        self.ImgRank.gameObject:SetActiveEx(true)
        self.TxtRank.gameObject:SetActiveEx(false)
    else
        self.TxtRank.text = data.Rank
        self.ImgRank.gameObject:SetActiveEx(false)
        self.TxtRank.gameObject:SetActiveEx(true)
    end
end

return XUiDlcHuntTeamRankGrid