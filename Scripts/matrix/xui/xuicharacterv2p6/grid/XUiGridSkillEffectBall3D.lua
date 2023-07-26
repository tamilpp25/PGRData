local XUiGridSkillEffectBall3D = XClass(XUiNode, "XUiGridSkillEffectBall3D")

function XUiGridSkillEffectBall3D:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
end

function XUiGridSkillEffectBall3D:GetState()
    local character = self.CharacterAgency:GetCharacter(self.CharacterId)

    local charQuality = character.Quality
    local isMaxQuality = self.CharacterAgency:GetCharMaxQuality(character.Id) == character.Quality
    local isMaxStars = character.Star == XEnumConst.CHARACTER.MAX_QUALITY_STAR

    -- 必须先判断最大品质 因为和非最大star冲突
    if charQuality == self.CurQuality and isMaxQuality then
        return XEnumConst.CHARACTER.QualityState.ActiveFinish
    elseif charQuality == self.CurQuality and not isMaxStars then
        return XEnumConst.CHARACTER.QualityState.Activing
    elseif charQuality == self.CurQuality and not isMaxQuality and isMaxStars then
        return XEnumConst.CHARACTER.QualityState.EvoEnable
    elseif charQuality > self.CurQuality then
        return XEnumConst.CHARACTER.QualityState.ActiveFinish
    elseif charQuality < self.CurQuality then
        return XEnumConst.CHARACTER.QualityState.Lock
    end
end

function XUiGridSkillEffectBall3D:Refresh(characterId, curQuality, isEvo)
    self.CharacterId = characterId
    self.CurQuality = curQuality
    local character = self.CharacterAgency:GetCharacter(self.CharacterId)

    local EffectBallSmallQuality = false -- 字母
    local EffectBallSmall = false  -- 球颜色
    local EffectBallSmallLock = false  --锁
    local EffectBallSmallLine = false   -- 球连接线
    local EffectBallSmallLineLock = true -- 连接线依赖
    local EffectBallSmallBtnBg = false  -- text背景底板
    local EffectBallSmallTxt = false  -- text
    local textStr = ""
    local EffectBallSmallBtnRed = false -- 红点

    local curState = self.CharacterAgency:GetQualityState(characterId, curQuality)
    if curState == XEnumConst.CHARACTER.QualityState.Activing then
        EffectBallSmallQuality = true
        EffectBallSmall = true
        EffectBallSmallBtnBg = true
        EffectBallSmallTxt = true
        textStr = CS.XTextManager.GetText("DormCharacterLevel", character.Star.."/"..XEnumConst.CHARACTER.MAX_QUALITY_STAR)
        EffectBallSmallBtnRed = XRedPointManager.CheckConditions({ XRedPointConditions.Types.CONDITION_CHARACTER_QUALITY }, characterId)
    elseif curState == XEnumConst.CHARACTER.QualityState.EvoEnable then
        EffectBallSmallQuality = true
        EffectBallSmall = true
        EffectBallSmallBtnBg = true
        EffectBallSmallTxt = true
        textStr = CS.XTextManager.GetText("CharacterQualityActiveEnable")
        EffectBallSmallBtnRed = XRedPointManager.CheckConditions({ XRedPointConditions.Types.CONDITION_CHARACTER_QUALITY }, characterId)
    elseif curState == XEnumConst.CHARACTER.QualityState.ActiveFinish then
        EffectBallSmallQuality = true
        EffectBallSmall = true
        EffectBallSmallLine = true
        EffectBallSmallLineLock = false
    elseif curState == XEnumConst.CHARACTER.QualityState.Lock then
        EffectBallSmallLock = true
    end

    self.EffectBallSmallQuality.gameObject:SetActiveEx(EffectBallSmallQuality) -- 字母
    self.EffectBallSmall.gameObject:SetActiveEx(EffectBallSmall)  -- 球颜色
    self.EffectBallSmallLock.gameObject:SetActiveEx(EffectBallSmallLock)  --锁
    self.EffectBallSmallLine.gameObject:SetActiveEx(EffectBallSmallLine)   -- 球连接线
    self.EffectBallSmallLineLock.gameObject:SetActiveEx(EffectBallSmallLineLock) -- 连接线依赖
    self.EffectBallSmallBtnBg.gameObject:SetActiveEx(EffectBallSmallBtnBg)  -- text背景底板
    -- self.EffectBallSmallTxt.gameObject:SetActiveEx(EffectBallSmallTxt)  -- text
    -- self.EffectBallSmallTxt.text = textStr
    -- self.EffectBallSmallBtnRed.gameObject:SetActiveEx(EffectBallSmallBtnRed)  -- text

    self.EffectBallSmallLockExplode.gameObject:SetActiveEx(isEvo)  --球的进化演出
end

function XUiGridSkillEffectBall3D:RefreshByEvoPerform(characterId, curQuality)
    self.EffectBallBigExplode.gameObject:SetActiveEx(true)
    self:Refresh(characterId, curQuality)
end

function XUiGridSkillEffectBall3D:PlayLineAnime(finCb)
    local animTrans = self.Transform:FindTransform("EffectBallSmallLine"):FindTransform("LineEnable")
    if XTool.UObjIsNil(animTrans) then
        return
    end
    animTrans:PlayTimelineAnimation(finCb)
end

return XUiGridSkillEffectBall3D