local XUiPlanetUtil = require("XUi/XUiPlanet/Explore/View/XUiPlanetUtil")

---@class XUiPlanetBattleMainGridRole
local XUiPlanetBattleMainGridRole = XClass(nil, "XUiPlanetBattleMainGridRole")

function XUiPlanetBattleMainGridRole:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._Func = false
    self._Entity = false
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self._OnClick)
end

---@param entity XPlanetRunningExploreEntity
function XUiPlanetBattleMainGridRole:Update(entity, isLeader)
    self._Entity = entity
    if isLeader then
        self.PanelTag.gameObject:SetActiveEx(true)
    else
        self.PanelTag.gameObject:SetActiveEx(false)
    end
    local characterId = entity.Data.IdFromConfig
    local character = XDataCenter.PlanetExploreManager.GetCharacter(characterId)
    if character then
        self.RImgIcon:SetRawImage(character:GetIcon())
        self.RImgIcon.gameObject:SetActiveEx(true)
    else
        self.RImgIcon.gameObject:SetActiveEx(false)
    end

    local hp = entity.Attr.Life
    local hpMax = math.max(1, entity.Attr.MaxLife)
    XUiPlanetUtil.SetHp(self.ImgBar, hp / hpMax)

    if hp == 0 then
        self.ImgDead.gameObject:SetActiveEx(true)
    else
        self.ImgDead.gameObject:SetActiveEx(false)
    end
end

function XUiPlanetBattleMainGridRole:_OnClick()
    if self._Func then
        self._Func(self._Entity)
    end
end

function XUiPlanetBattleMainGridRole:RegisterClick(func)
    self._Func = func
end

return XUiPlanetBattleMainGridRole