local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridPokemonMemberMonster = XClass(nil, "XUiGridPokemonMemberMonster")

function XUiGridPokemonMemberMonster:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb

    XTool.InitUiObject(self)

    self.BtnKickout.CallBack = function() self:OnClickBtnKickout() end
    self.BtnSwitch.CallBack = function() self:OnClickBtnSwitch() end
    self.BtnSelect.CallBack = function() self:OnClickBtnSelect() end
end

function XUiGridPokemonMemberMonster:Refresh(pos, recommendCareer, monsterId, selectPos, stageMonsterCareer)
    self.Pos = pos
    self.SelectPos = selectPos
    local isEmpty = not monsterId or monsterId == 0

    --位置未解锁
    local isLock = XDataCenter.PokemonManager.IsTeamPosLock(pos)
    if isLock then

        self.PanelLock.gameObject:SetActiveEx(true)
        self.PanelInformation.gameObject:SetActiveEx(false)
        self.PanelRecommend.gameObject:SetActiveEx(false)
        self.PanelSwitch.gameObject:SetActiveEx(false)
        self.PanelKickout.gameObject:SetActiveEx(false)

        return
    end

    --位置处于选中状态
    if selectPos then

        if pos == selectPos and not isEmpty then

            --设置为可下阵状态
            self.PanelLock.gameObject:SetActiveEx(false)
            self.PanelInformation.gameObject:SetActiveEx(true)
            self.PanelRecommend.gameObject:SetActiveEx(false)
            self.PanelSwitch.gameObject:SetActiveEx(false)
            self.PanelKickout.gameObject:SetActiveEx(true)

        else

            --设置为可交换位置状态
            self.PanelLock.gameObject:SetActiveEx(false)
            self.PanelInformation.gameObject:SetActiveEx(false)
            self.PanelRecommend.gameObject:SetActiveEx(false)
            self.PanelSwitch.gameObject:SetActiveEx(true)
            self.PanelKickout.gameObject:SetActiveEx(false)

        end

        return
    end

    --位置未上阵怪物
    if isEmpty then

        if recommendCareer then

            local icon = XPokemonConfigs.GetCareerIcon(recommendCareer)
            self.ImgIconCareerRecommend:SetSprite(icon)
            self.ImgIconCareerRecommend.gameObject:SetActiveEx(false)

            local careerName = XPokemonConfigs.GetCareerName(recommendCareer)
            self.TxtRecommendCareer.text = CSXTextManagerGetText("PokemonMonsterRecommendCareer", careerName)
            self.TxtRecommendCareer.gameObject:SetActiveEx(false)

        else

            self.ImgIconCareerRecommend.gameObject:SetActiveEx(false)
            self.TxtRecommendCareer.gameObject:SetActiveEx(false)

        end

        self.PanelRecommend.gameObject:SetActiveEx(true)
        self.PanelInformation.gameObject:SetActiveEx(false)
        self.PanelLock.gameObject:SetActiveEx(false)
        self.PanelKickout.gameObject:SetActiveEx(false)
        self.PanelSwitch.gameObject:SetActiveEx(false)

        return
    end

    local headIcon = XPokemonConfigs.GetMonsterHeadIcon(monsterId)
    self.RImgHeadIcon:SetRawImage(headIcon)

    local careerIcon = XPokemonConfigs.GetMonsterCareerIcon(monsterId)
    self.ImgIconCareer:SetSprite(careerIcon)

    if self.TxtCareer then
        local careerName = XPokemonConfigs.GetMonsterCareerName(monsterId)
        self.TxtCareer.text = careerName
    end

    local costEnergy = XPokemonConfigs.GetMonsterEnergyCost(monsterId)
    self.TxtCostEnergy.text = CSXTextManagerGetText("PokemonMonsterEnergyCost", costEnergy)

    local ability = XDataCenter.PokemonManager.GetMonsterAbility(monsterId)
    self.TxtAbility.text = ability

    local isCareerUp = XPokemonConfigs.IsMonsterCareerUp(monsterId, stageMonsterCareer)
    self.IconUp.gameObject:SetActiveEx(isCareerUp)

    local isCareerDown = XPokemonConfigs.IsMonsterCareerDown(monsterId, stageMonsterCareer)
    self.IconDown.gameObject:SetActiveEx(isCareerDown)

    if self.PanelBoss then
        local isBoss = XPokemonConfigs.CheckMonsterType(monsterId, XPokemonConfigs.MonsterType.Boss)
        self.PanelBoss.gameObject:SetActiveEx(isBoss)
    end

    self.PanelInformation.gameObject:SetActiveEx(true)
    self.PanelRecommend.gameObject:SetActiveEx(false)
    self.PanelLock.gameObject:SetActiveEx(false)
    self.PanelKickout.gameObject:SetActiveEx(false)
    self.PanelSwitch.gameObject:SetActiveEx(false)
end

function XUiGridPokemonMemberMonster:OnClickBtnKickout()
    self.ClickCb(self.Pos)
end

function XUiGridPokemonMemberMonster:OnClickBtnSwitch()
    self.ClickCb(self.Pos)
end

function XUiGridPokemonMemberMonster:OnClickBtnSelect()
    self.ClickCb(self.Pos)
end

return XUiGridPokemonMemberMonster