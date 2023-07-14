local XUiPanelStars = require("XUi/XUiPokemon/XUiMonster/XUiPanelStars")

local handler = handler
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridPokemonMonster = XClass(nil, "XUiGridPokemonMonster")

function XUiGridPokemonMonster:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self:SetSelect(false)
    self:SetDisable(false)

    if self.BtnClick then
        self.BtnClick.CallBack = handler(self, self.OnClickBtnClick)
    end

    XEventManager.AddEventListener(XEventId.EVENT_POKEMON_MONSTERS_LEVEL_UP, self.UpdateData, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKEMON_MONSTERS_STAR_UP, self.UpdateData, self)
end

function XUiGridPokemonMonster:UpdateData(monsterId)
    if not monsterId or monsterId ~= self.MonsterId then return end
    if XTool.UObjIsNil(self.GameObject) then return end
    self:Refresh(monsterId)
end

function XUiGridPokemonMonster:Refresh(monsterId, star, clickCb)
    self.MonsterId = monsterId
    self.ClickCb = clickCb

    if self.TxtCareer then
        local name = XPokemonConfigs.GetMonsterCareerName(monsterId)
        self.TxtCareer.text = name
    end

    if self.TxtCostEnergy then
        local costEnergy = XPokemonConfigs.GetMonsterEnergyCost(monsterId)
        self.TxtCostEnergy.text = CSXTextManagerGetText("PokemonMonsterEnergyCost", costEnergy)
    end

    if self.TxtLevel then
        local level = XDataCenter.PokemonManager.GetMonsterLevel(monsterId)
        self.TxtLevel.text = level
    end

    if self.RImgHeadIcon then
        local headIcon = XPokemonConfigs.GetMonsterHeadIcon(monsterId)
        self.RImgHeadIcon:SetRawImage(headIcon)
    end

    if self.ImgIconCareer then
        local careerIcon = XPokemonConfigs.GetMonsterCareerIcon(monsterId)
        self.ImgIconCareer:SetSprite(careerIcon)
    end

    if self.PanelBoss then
        local isBoss = XPokemonConfigs.CheckMonsterType(monsterId, XPokemonConfigs.MonsterType.Boss)
        self.PanelBoss.gameObject:SetActiveEx(isBoss)
    end

    if self.TxtAbility then
        local ability = XDataCenter.PokemonManager.GetMonsterAbility(monsterId)
        self.TxtAbility.text = ability
    end

    if self.ImgClass then
        local ratingIcon = XPokemonConfigs.GetMonsterRatingIcon(monsterId)
        local isEmpty = ratingIcon == ""
        self.ImgClass.gameObject:SetActiveEx(not isEmpty)
        if not isEmpty then
            self.ImgClass:SetSprite(ratingIcon)
        end
    end

    if self.ImgConsume then
        local rateIcon = XPokemonConfigs.GetMonsterRatingIcon(monsterId)
        local isEmpty = string.IsNilOrEmpty(rateIcon)
        self.ImgConsume.gameObject:SetActiveEx(not isEmpty)
        if not isEmpty then
            self.ImgConsume:SetSprite(rateIcon)
        end
    end

    if self.TxtConsume then
        self.TxtConsume.text = CS.XTextManager.GetText("PokemonMonsterEnergyCost",XPokemonConfigs.GetMonsterEnergyCost(monsterId))
    end

    if self.PanelCamp then
        self.PanelCamp.gameObject:SetActiveEx(XDataCenter.PokemonManager.CheckMonsterIsInTeam(monsterId))
    end

    if self.PanelStars then
        self.StarPanel = self.StarPanel or XUiPanelStars.New(self.PanelStars)
        star = star or XDataCenter.PokemonManager.GetMonsterStar(monsterId)
        local maxStar = XPokemonConfigs.GetMonsterStarMaxStar(monsterId)
        self.StarPanel:Refresh(star, maxStar)
    end
end

function XUiGridPokemonMonster:SetSelect(value)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(value)
    end
    if value == true then
        self:ShowRedDot(0)
        local key = string.format("%s_%s_%s", XPokemonConfigs.PokemonNewRoleClickedPrefix, tostring(XPlayer.Id), tostring(self.MonsterId))
        XSaveTool.SaveData(key, true)
    end
end

function XUiGridPokemonMonster:SetDisable(value)
    if self.PanelDisable then
        self.PanelDisable.gameObject:SetActiveEx(value)
    end
end

function XUiGridPokemonMonster:OnClickBtnClick()
    if self.ClickCb then
        self.ClickCb(self.MonsterId)
    end
end

function XUiGridPokemonMonster:ShowRedDot(count)
    if self.Red then
        self.Red.gameObject:SetActiveEx(count < 0)
    end
end

return XUiGridPokemonMonster