local XUiGridSkillEffectBall3D = XClass(XUiNode, "XUiGridSkillEffectBall3D")

function XUiGridSkillEffectBall3D:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    self.TempV3 = Vector3.zero

    self.BOffsetData = 
        {
            [1] = 0.01,
            [2] = 0.01,
            [3] = 0.05,
            [4] = - 0.02,
            [5] = 0,
            [6] = 0,
        }
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
    self.EffectBallSmallTxt.gameObject:SetActiveEx(EffectBallSmallTxt)  -- text
    self.EffectBallSmallTxt.text = textStr
    self.EffectBallSmallBtnRed.gameObject:SetActiveEx(EffectBallSmallBtnRed)

    self.EffectBallSmallLockExplode.gameObject:SetActiveEx(isEvo)  --球的进化演出

    if EffectBallSmallTxt then
        local UiCamUiQuality = self.Parent.ParentUi.PanelModel.UiCamUiQuality

        -- 日志
        -- local offsetY = UiCamUiQuality.transform.position.y - self.EffectBallSmallQuality.transform.position.y
        -- offsetY = math.abs(offsetY)
        -- local cameBallOffset = offsetY
        -- local cameText = UiCamUiQuality.transform.position.y - self.EffectBallSmallTxt.transform.position.y
        -- local offseset = cameText - cameBallOffset

        -- 修正位置text : 解二元一次方程 0.8045 = 1.05a + b， 1.06 = 1.299a + b
        -- self.TempV3 = self.EffectBallSmallTxt.transform.position
        -- self.TempV3.y = 1.0251 * UiCamUiQuality.transform.position.y - 0.272 - self.BOffsetData[curQuality]
        -- self.EffectBallSmallTxt.transform.position = self.TempV3
        -- --
        -- self.TempV3 = self.EffectBallSmallBtnBg.transform.position
        -- self.TempV3.y = 1.0251 * UiCamUiQuality.transform.position.y - 0.272 - 0.005 - self.BOffsetData[curQuality]
        -- self.EffectBallSmallBtnBg.transform.position = self.TempV3
    end
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