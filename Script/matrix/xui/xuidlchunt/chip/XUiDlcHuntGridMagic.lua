---@class XUiDlcHuntGridMagic
local XUiDlcHuntGridMagic = XClass(nil, "XUiDlcHuntGridMagic")

function XUiDlcHuntGridMagic:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntGridMagic:Update(magicData)
    self.TxtSkillName.text = magicData.Name
    self.TxtSkillDes.text = magicData.Desc
    if magicData.IsActive then
        self.TxtSkillName.color = XUiHelper.Hexcolor2Color("76DDE5")
        self.TxtSkillDes.color = XUiHelper.Hexcolor2Color("76DDE5")
    else
        self.TxtSkillName.color = XUiHelper.Hexcolor2Color("979D9E")
        self.TxtSkillDes.color = XUiHelper.Hexcolor2Color("979D9E")
    end
end

return XUiDlcHuntGridMagic