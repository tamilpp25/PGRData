local XUiGridWinRole = XClass(nil, "XUiGridWinRole")

function XUiGridWinRole:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- 机器人
function XUiGridWinRole:UpdateRobotInfo(robotId, starNum)
    local data = XRobotManager.GetRobotTemplate(robotId)
    self.TxtStar.text = starNum
    local icon = XDataCenter.CharacterManager.GetCharBigHeadIcon(data.CharacterId)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
end

return XUiGridWinRole