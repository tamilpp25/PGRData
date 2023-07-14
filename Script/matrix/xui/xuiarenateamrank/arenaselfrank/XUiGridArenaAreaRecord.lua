local XUiGridArenaAreaRecord = XClass(nil, "XUiGridArenaAreaRecord")
local XUiGridArenaAreaCharacter = require("XUi/XUiArenaTeamRank/ArenaSelfRank/XUiGridArenaAreaCharacter")
local GridColor = {
    XUiHelper.Hexcolor2Color("4F99FF"),
    XUiHelper.Hexcolor2Color("FF1111"),
    XUiHelper.Hexcolor2Color("F9CB35"),
}
function XUiGridArenaAreaRecord:Ctor(transform)
    self.Transform = transform
    self.GameObject = transform.gameObject
    self.GridList = {}
    XTool.InitUiObject(self)
end

function XUiGridArenaAreaRecord:Refresh(data)
    self.Data = data
    self.TxtNumber.text = data.Point
    local areaCfg =  XArenaConfigs.GetArenaAreaStageCfgByAreaId(data.AreaId)
    self.TxtTitle.text = areaCfg.Name
    for i, _ in ipairs(data.CharacterList) do
        if not self.GridList[i] then
            local obj = CS.UnityEngine.GameObject.Instantiate(self.GridTeamRole, self.PanelCharContent)
            self.GridList[i] = XUiGridArenaAreaCharacter.New(obj)
        end
        self.GridList[i]:Refresh(data.CharacterList[i], data.PartnerList[i], data.AbilityList[i], data.QualityList[i], data.CharacterHeadInfoList[i], GridColor[i])
    end
    self.GridTeamRole.gameObject:SetActiveEx(false)
end


return XUiGridArenaAreaRecord