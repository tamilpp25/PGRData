local TARGET_TYPE = {
    NONE = 0,
    BUILDING = 1,
}

---@class XUiPlanetBattleMainTargetGrid
local XUiPlanetBattleMainTargetGrid = XClass(nil, "XUiPlanetBattleMainTargetGrid")

function XUiPlanetBattleMainTargetGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPlanetBattleMainTargetGrid:Update(data)
    if data.Type == TARGET_TYPE.BUILDING then
        self.TxtBulidDesc.text = data.Desc
        self.TxtBulidNum01.text = data.Value1
        self.TxtBulidNum02.text = "/" .. data.Value2
        if data.Value1 >= data.Value2 then
            self.TxtBulidNum01.color = XUiHelper.Hexcolor2Color("FFFFFFFF")
            self.TxtBulidNum02.color = XUiHelper.Hexcolor2Color("FFFFFFFF")
        else
            self.TxtBulidNum01.color = XUiHelper.Hexcolor2Color("FF0000FF")
            self.TxtBulidNum02.color = XUiHelper.Hexcolor2Color("FFFFFFFF")
        end
    elseif data.Type == TARGET_TYPE.NONE then
        self.TxtBulidDesc.text = data.Desc
        self.TxtBulidNum01.text = ""
        self.TxtBulidNum02.text = ""
    end
end

return XUiPlanetBattleMainTargetGrid
