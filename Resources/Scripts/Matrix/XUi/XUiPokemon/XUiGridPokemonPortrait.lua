local XUiGridPokemonPortrait = XClass(nil, "XUiGridPokemonPortrait")

function XUiGridPokemonPortrait:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MonsterId = 0
    XTool.InitUiObject(self)
end


function XUiGridPokemonPortrait:Refresh(monsterId, isInfinityStage)
    self.GameObject:SetActiveEx(monsterId)
    if not monsterId then
        return
    end
    self.MonsterId = monsterId
    if isInfinityStage then
        self.ImgBossIcon:SetRawImage(XPokemonConfigs.GetMonsterHeadIcon(monsterId))
        self.ImgTheAttack:SetSprite(XPokemonConfigs.GetMonsterCareerIcon(monsterId))
    else
        self.ImgBossIcon:SetRawImage(XPokemonConfigs.GetStageMonsterHeadIcon(monsterId))
        self.ImgTheAttack:SetSprite(XPokemonConfigs.GetStageMonsterCareerIcon(monsterId))
    end

end

return XUiGridPokemonPortrait