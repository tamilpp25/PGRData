---@class XUiDlcHuntChipBatchMagic
local XUiDlcHuntChipBatchMagic = XClass(nil, "XUiDlcHuntChipBatchMagic")

function XUiDlcHuntChipBatchMagic:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntChipBatchMagic:Update(data, isActive)
    if data then
        if isActive then
            self.TxtSkillName.color = XUiHelper.Hexcolor2Color("76DDE5")
            self.TxtSkillDes.color = XUiHelper.Hexcolor2Color("76DDE5")
        else
            self.TxtSkillName.color = XUiHelper.Hexcolor2Color("979D9E")
            self.TxtSkillDes.color = XUiHelper.Hexcolor2Color("979D9E")
        end
        self.TxtSkillName.text = data.Name
        self.TxtSkillDes.text = data.Desc
        self.GameObject:SetActiveEx(true)
    else
        self.GameObject:SetActiveEx(false)
    end
end

return XUiDlcHuntChipBatchMagic