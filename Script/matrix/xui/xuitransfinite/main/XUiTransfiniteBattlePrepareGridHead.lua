---@class XUiTransfiniteBattlePrepareGridHead
local XUiTransfiniteBattlePrepareGridHead = XClass(nil, "XUiTransfiniteBattlePrepareGridHead")

function XUiTransfiniteBattlePrepareGridHead:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

---@param data XViewModelTransfiniteRoomMember
function XUiTransfiniteBattlePrepareGridHead:Update(data)
    if data then
        self.Head.gameObject:SetActiveEx(true)
        if self.BtnEmpty then
            self.BtnEmpty.gameObject:SetActiveEx(false)
        end
        self.ImgHpBar.fillAmount = data.Hp
        self.ImgSpBar.fillAmount = data.Sp
        self.StandIcon:SetRawImage(data.Icon)
        self.ImgFirstBg.gameObject:SetActiveEx(data.IsFirst)
        self.TxtCaptain.transform.parent.gameObject:SetActiveEx(data.IsCaptain)
        self.ImgDead.gameObject:SetActiveEx(data.IsDead)
    else
        self.Head.gameObject:SetActiveEx(false)
        if self.BtnEmpty then
            self.BtnEmpty.gameObject:SetActiveEx(true)
        end
    end
end

return XUiTransfiniteBattlePrepareGridHead