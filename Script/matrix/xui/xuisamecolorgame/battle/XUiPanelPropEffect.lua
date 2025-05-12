---@class XUiPanelPropEffect : XUiNode 道具表现
---@field Parent XUiSCBattlePanelBoard
---@field _Control XSameColorControl
local XUiPanelPropEffect = XClass(XUiNode, "XUiPanelPropEffect")

function XUiPanelPropEffect:OnStart()
    ---@type XObjectPool
    self._EffectCommon = XObjectPool.New(function()
        return XUiHelper.Instantiate(self.EffectCommon, self.PanelPropEffect)
    end)
    ---@type XObjectPool
    self._EffectLineX = XObjectPool.New(function()
        return XUiHelper.Instantiate(self.EffectShiZiX, self.PanelPropEffect)
    end)
    ---@type XObjectPool
    self._EffectLineY = XObjectPool.New(function()
        return XUiHelper.Instantiate(self.EffectShiZiY, self.PanelPropEffect)
    end)

    self._DaoDanFlyTime = tonumber(self._Control:GetClientCfgStringValue("DaoDanFlyTime"))
    self._TouZiHeight = tonumber(self._Control:GetClientCfgStringValue("TouZiHeight"))
    self._TouZiTime = tonumber(self._Control:GetClientCfgStringValue("TouZiTime"))
    self._ShiZiTime = tonumber(self._Control:GetClientCfgStringValue("ShiZiTime"))
    self._DaoDanBoomEffect = self._Control:GetClientCfgStringValue("DaoDanRemoveEffect")
    self._PropAndWeakEffect = self._Control:GetClientCfgStringValue("PropAndWeakEffect")
    self._PropAndWeakEffectTime = tonumber(self._Control:GetClientCfgStringValue("PropAndWeakEffectTime"))
    self._TimeIds = {}
end

function XUiPanelPropEffect:OnDestroy()
    for timeId, _ in pairs(self._TimeIds) do
        XScheduleManager.UnSchedule(timeId)
    end
    self._EffectCommon:Clear()
    self._EffectLineX:Clear()
    self._EffectLineY:Clear()
end

function XUiPanelPropEffect:GetDistance(pos1, pos2)
    local x = pos1.x - pos2.x
    local y = pos1.y - pos2.y
    local z = pos1.z - pos2.z
    return math.sqrt(x * x + y * y + z * z)
end

---@param propBall XUiSCBattleGridBall|XSCBattleBallInfo
function XUiPanelPropEffect:PlayPropEffect(propBall, dimBallList)
    local ballId = propBall.ItemId or propBall.Ball:GetBallId()
    local skillId = XSameColorGameConfigs.GetBallConfig(ballId).SkillId
    self._EffectShowCfg = self._Control:GetSkillEffectShowCfg(skillId)
    if not self._EffectShowCfg or not self._EffectShowCfg.PropEffect then
        return
    end

    local shape = self._EffectShowCfg.Shape
    if shape == XEnumConst.SAME_COLOR_GAME.SkillType.TouZi then
        self:PlayTouZiDownEffect(propBall, dimBallList)
    elseif shape == XEnumConst.SAME_COLOR_GAME.SkillType.DaoDan then
        self:PlayDaoDanEffect(propBall, dimBallList)
    elseif shape == XEnumConst.SAME_COLOR_GAME.SkillType.LineX then
        self:PlayLineXYEffect(propBall, true, false)
    elseif shape == XEnumConst.SAME_COLOR_GAME.SkillType.LineY then
        self:PlayLineXYEffect(propBall, false, true)
    elseif shape == XEnumConst.SAME_COLOR_GAME.SkillType.LineXY then
        self:PlayLineXYEffect(propBall, true, true)
    elseif shape == XEnumConst.SAME_COLOR_GAME.SkillType.ZhaDan then
        self:PlayZhaDanEffect(propBall)
    end
end

---@param allBalls table<number, XUiSCBattleGridBall[]>
function XUiPanelPropEffect:PlayPropAndWeakCreateEffect(allBalls)
    local isPlayEffect = false
    for _, balls in pairs(allBalls) do
        for _, ball in pairs(balls) do
            local pos = self.Parent:GetBallGridLocalPosition(ball.Col, ball.Row)
            local effect = self:CreatePropAndWeakEffect(pos)
            local timeId = XScheduleManager.ScheduleOnce(function()
                self:RecycleCommonEffect(effect)
            end, self._PropAndWeakEffectTime)
            self._TimeIds[timeId] = true
            isPlayEffect = true
        end
    end
    return isPlayEffect
end

function XUiPanelPropEffect:CreateCommonEffect(localPosition, effectIndex, isMask)
    local eff = self._EffectCommon:Create()
    self:SetEffectMask(eff, isMask)
    self:LoadUiEffect(eff, effectIndex)
    eff.gameObject:SetActiveEx(true)
    eff.transform.localPosition = localPosition
    return eff
end

function XUiPanelPropEffect:CreateDaoDanBoomEffect(localPosition)
    local eff = self._EffectCommon:Create()
    self:SetEffectMask(eff, true)
    eff:LoadUiEffect(self._DaoDanBoomEffect, false, false)
    eff.gameObject:SetActiveEx(true)
    eff.transform.localPosition = localPosition
    return eff
end

function XUiPanelPropEffect:CreatePropAndWeakEffect(localPosition)
    local eff = self._EffectCommon:Create()
    self:SetEffectMask(eff, true)
    eff:LoadUiEffect(self._PropAndWeakEffect, false, false)
    eff.gameObject:SetActiveEx(true)
    eff.transform.localPosition = localPosition
    return eff
end

function XUiPanelPropEffect:SetEffectMask(eff, isMask)
    local uiEffectMaskObject = eff.transform:GetComponent("XUiEffectMaskObject")
    if uiEffectMaskObject then
        if isMask == nil then
            isMask = true
        end
        uiEffectMaskObject.enabled = isMask
    end
end

function XUiPanelPropEffect:LoadUiEffect(eff, effectIndex)
    effectIndex = effectIndex or 1
    local url = self._EffectShowCfg.PropEffect[effectIndex]
    eff:LoadUiEffect(url, false, false)
end

function XUiPanelPropEffect:RecycleCommonEffect(eff)
    eff.gameObject:SetActiveEx(false)
    self._EffectCommon:Recycle(eff)
end

---3x3范围的爆炸
---@param propBall XUiSCBattleGridBall
function XUiPanelPropEffect:PlayZhaDanEffect(propBall)
    local localPosition = self.Parent:GetBallGridLocalPosition(propBall.Col, propBall.Row)
    local eff = self:CreateCommonEffect(localPosition, nil, false)
    local timeId = XScheduleManager.ScheduleOnce(function()
        self:RecycleCommonEffect(eff)
    end, 500)
    self._TimeIds[timeId] = true
end

---十字特效
---@param propBall XUiSCBattleGridBall
function XUiPanelPropEffect:PlayLineXYEffect(propBall, isLineX, isLineY)
    local effX, effY
    local pos = self.Parent:GetBallGridLocalPosition(propBall.Col, propBall.Row)
    if isLineX then
        effX = self._EffectLineX:Create()
        self:LoadUiEffect(effX)
        effX.gameObject:SetActiveEx(true)
        effX.transform.localPosition = CS.UnityEngine.Vector3(0, pos.y, 0)
    end
    if isLineY then
        effY = self._EffectLineY:Create()
        self:LoadUiEffect(effY)
        effY.gameObject:SetActiveEx(true)
        effY.transform.localPosition = CS.UnityEngine.Vector3(pos.x, 0, 0)
    end
    local timeId = XScheduleManager.ScheduleOnce(function()
        if effX then
            effX.gameObject:SetActiveEx(false)
            self._EffectLineX:Recycle(effX)
        end
        if effY then
            effY.gameObject:SetActiveEx(false)
            self._EffectLineY:Recycle(effY)
        end
    end, self._ShiZiTime)
    self._TimeIds[timeId] = true
end

---导弹飞向目标球
---@param propBall XUiSCBattleGridBall
function XUiPanelPropEffect:PlayDaoDanEffect(propBall, dimBallList)
    if not dimBallList then
        return
    end
    local startPos = self.Parent:GetBallGridLocalPosition(propBall.Col, propBall.Row)
    for _, ball in pairs(dimBallList) do
        local endPos = self.Parent:GetBallGridLocalPosition(ball.PositionX, ball.PositionY)
        local eff = self:CreateCommonEffect(startPos)
        eff.transform:DOLocalMove(endPos, self._DaoDanFlyTime):OnComplete(function()
            local boom = self:CreateDaoDanBoomEffect(endPos)
            local timeId = XScheduleManager.ScheduleOnce(function()
                self:RecycleCommonEffect(boom)
            end, 1000)
            self._TimeIds[timeId] = true
            self:RecycleCommonEffect(eff)
        end)
    end
end

---骰子下落
---@param dimBallList XSCBattleBallInfo[]
function XUiPanelPropEffect:PlayTouZiDownEffect(propBall, dimBallList)
    if not dimBallList then
        return
    end
    for _, ball in pairs(dimBallList) do
        local endPos = self.Parent:GetBallGridLocalPosition(ball.PositionX, ball.PositionY)
        local startPos = CS.UnityEngine.Vector3(endPos.x, endPos.y + self._TouZiHeight, endPos.z)
        local downEffect = self:CreateCommonEffect(startPos)
        downEffect.transform:DOLocalMoveY(endPos.y, self._TouZiTime):OnComplete(function()
            self:RecycleCommonEffect(downEffect)
        end)
    end
end

return XUiPanelPropEffect