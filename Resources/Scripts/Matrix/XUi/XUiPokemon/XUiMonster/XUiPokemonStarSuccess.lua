local XUiGridPokemonMonster = require("XUi/XUiPokemon/XUiMonster/XUiGridPokemonMonster")

local XUiPokemonStarSuccess = XLuaUiManager.Register(XLuaUi, "UiPokemonStarSuccess")

function XUiPokemonStarSuccess:OnAwake()
    self:AutoAddListener()
end

function XUiPokemonStarSuccess:OnStart(monsterId, oldStar)
    self.MonsterId = monsterId
    self.OldStar = oldStar
end

function XUiPokemonStarSuccess:OnEnable()
    self:UpdatePreview()
end

function XUiPokemonStarSuccess:UpdatePreview()
    local monsterId = self.MonsterId
    local oldStar = self.OldStar
    local star = XDataCenter.PokemonManager.GetMonsterStar(monsterId)

    self.LeftGrid = self.LeftGrid or XUiGridPokemonMonster.New(self.GridMonsterLeft)
    self.LeftGrid:Refresh(monsterId, oldStar)

    self.RightGrid = self.RightGrid or XUiGridPokemonMonster.New(self.GridMonsterRight)
    self.RightGrid:Refresh(monsterId, star)

    local maxLevel = XDataCenter.PokemonManager.GetMonsterMaxLevel(monsterId)
    self.TxtLevelLimit.text = maxLevel

    local unlockSkillIds = XDataCenter.PokemonManager.GetMonsterStarUnlockSkillIds(monsterId, star)
    local showSkillId = unlockSkillIds[1]
    if showSkillId then
        local skillName = XPokemonConfigs.GetMonsterSkillName(showSkillId)
        self.TxtSkillName.text = skillName

        local skillIcon = XPokemonConfigs.GetMonsterSkillIcon(showSkillId)
        self.RImgSkillIcon:SetRawImage(skillIcon)

        self.PanelNewSkill.gameObject:SetActiveEx(true)
    else
        self.PanelNewSkill.gameObject:SetActiveEx(false)
    end
end

function XUiPokemonStarSuccess:AutoAddListener()
    self.BtnDarkBg.CallBack = function() self:OnClickBtnBack() end
end

function XUiPokemonStarSuccess:OnClickBtnBack()
    self:Close()
end
