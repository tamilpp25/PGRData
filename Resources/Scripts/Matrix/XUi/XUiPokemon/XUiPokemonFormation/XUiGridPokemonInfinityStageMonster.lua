local XUiGridPokemonInfinityStageMonster = XClass(nil, "XUiGridPokemonInfinityStageMonster")

function XUiGridPokemonInfinityStageMonster:Ctor(ui, pos)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Pos = pos
    XTool.InitUiObject(self)
end

function XUiGridPokemonInfinityStageMonster:Refresh(monsterId)

    if self.TxtCareer then
        local careerName = XPokemonConfigs.GetMonsterCareerName(monsterId)
        self.TxtCareer.text = careerName
    end
    if self.TxtAbility then
        local fightStageId = XDataCenter.PokemonManager.GetRandomStageId()
        local stageId = XPokemonConfigs.GetStageIdByFightStageId(XDataCenter.PokemonManager.GetCurrActivityId(),fightStageId)
        local ability = XDataCenter.PokemonManager.GetShowAbility(stageId, self.Pos)
        self.TxtAbility.text = ability == 0 and "" or ability
    end

    if self.RImgHeadIcon then
        local icon = XPokemonConfigs.GetMonsterHeadIcon(monsterId)
        self.RImgHeadIcon:SetRawImage(icon)
    end

    if self.ImgIconCareer then
        local icon = XPokemonConfigs.GetMonsterCareerIcon(monsterId)
        self.ImgIconCareer:SetSprite(icon)
    end
end

return XUiGridPokemonInfinityStageMonster