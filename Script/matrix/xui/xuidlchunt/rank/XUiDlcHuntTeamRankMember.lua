---@class XUiDlcHuntTeamRankMember
local XUiDlcHuntTeamRankMember = XClass(nil, "XUiDlcHuntTeamRankMember")

function XUiDlcHuntTeamRankMember:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.BtnHead, function()
        if not self._Data then
            return
        end
        XDataCenter.DlcHuntManager.OpenPlayerDetail(self._Data.PlayerId)
    end)
end

function XUiDlcHuntTeamRankMember:Update(data)
    self._Data = data
    self.StandIcon:SetRawImage(data.Icon)
    self.TxtNickname.text = data.Name
    self.ImgCaptain.gameObject:SetActiveEx(data.IsLeader)
end

return XUiDlcHuntTeamRankMember