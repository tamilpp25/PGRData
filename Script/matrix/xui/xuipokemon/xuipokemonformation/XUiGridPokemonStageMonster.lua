local XUiGridPokemonStageMonster = XClass(nil, "XUiGridPokemonStageMonster")

function XUiGridPokemonStageMonster:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridPokemonStageMonster:Refresh(stageMonsterId)
    if self.TxtCareer then
        local careerName = XPokemonConfigs.GetStageMonsterCareerName(stageMonsterId)
        self.TxtCareer.text = careerName
    end

    if self.TxtAbility then
        local ability = XPokemonConfigs.GetStageMonsterAbility(stageMonsterId)
        self.TxtAbility.text = ability
    end

    if self.RImgHeadIcon then
        local icon = XPokemonConfigs.GetStageMonsterHeadIcon(stageMonsterId)
        self.RImgHeadIcon:SetRawImage(icon)
    end

    if self.ImgIconCareer then
        local icon = XPokemonConfigs.GetStageMonsterCareerIcon(stageMonsterId)
        self.ImgIconCareer:SetSprite(icon)
    end
end

return XUiGridPokemonStageMonster