local XUiPlanetRunningFight = require("XUi/XUiPlanet/Fight/XUiPlanetRunningFight")
local XUiPlanetRunningEntity = require("XUi/XUiPlanet/Fight/XUiPlanetRunningEntity")
local Vector3 = CS.UnityEngine.Vector3
local OFFSET_POSITION_ATTACKER = 120
local TIME_SCALE = XPlanetExploreConfigs.TIME_SCALE_FIGHT

---@class XUiPlanetFightMain:XLuaUi
local XUiPlanetFightMain = XLuaUiManager.Register(XLuaUi, "UiPlanetFightMain")

function XUiPlanetFightMain:Ctor()
    self._Timer = false
    ---@type XUiPlanetRunningFight
    self._Fight = false
end

function XUiPlanetFightMain:OnAwake()
    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnSkip, self._OnClickSkip)
    self:RegisterClickEvent(self.BtnAuto, self._OnClickAuto)
    self:RegisterClickEvent(self.BtnAuto02, self._OnClickAuto)
end

function XUiPlanetFightMain:OnDestroy()
    if self._Fight then
        self._Fight:Destroy()
        self._Fight = false
    end
end

function XUiPlanetFightMain:OnStart(data)
    CS.UnityEngine.Time.timeScale = XDataCenter.PlanetExploreManager.GetTimeScale()
    self:UpdateBtnAuto()
    data = data or XDataCenter.PlanetExploreManager.GetFightData()
    self:Run(data)
end

function XUiPlanetFightMain:OnEnable()
    self:UpdateBtnAuto()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:Update()
        end, 0)
    end
end

function XUiPlanetFightMain:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
    CS.UnityEngine.Time.timeScale = TIME_SCALE.NORMAL
end

function XUiPlanetFightMain:Update()
    if not self._Fight then
        XLog.Error("[XUiPlanetFightMain] fight不存在, 但还在update")
        return
    end
    self._Fight:Update(CS.UnityEngine.Time.deltaTime)
end

function XUiPlanetFightMain:Run(data)
    self._Fight = XUiPlanetRunningFight.New()
    --self._Fight:CreateFight()
    self._Fight:SetData(data)
    self:CreateUiEntity()
    self:BindAnimationAttack()
    self._Fight:Init()
end

function XUiPlanetFightMain:_OnClickSkip()
    if self._Fight.IsEnd then
        XLuaUiManager.Close(self.Name)
        return
    end
    self._Fight:Skip()
end

function XUiPlanetFightMain:_OnClickAuto()
    local timeScale = CS.UnityEngine.Time.timeScale
    if timeScale == TIME_SCALE.NORMAL then
        CS.UnityEngine.Time.timeScale = TIME_SCALE.X2
    elseif timeScale == TIME_SCALE.X2 then
        CS.UnityEngine.Time.timeScale = TIME_SCALE.NORMAL
    else
        CS.UnityEngine.Time.timeScale = TIME_SCALE.NORMAL
    end
    XDataCenter.PlanetExploreManager.SetTimeScale(CS.UnityEngine.Time.timeScale)
    self:UpdateBtnAuto()
end

function XUiPlanetFightMain:UpdateBtnAuto()
    local timeScale = CS.UnityEngine.Time.timeScale
    if timeScale == TIME_SCALE.X2 then
        self.BtnAuto.gameObject:SetActiveEx(true)
        self.BtnAuto02.gameObject:SetActiveEx(false)
    else
        self.BtnAuto.gameObject:SetActiveEx(false)
        self.BtnAuto02.gameObject:SetActiveEx(true)
    end
end

function XUiPlanetFightMain:CreateUiEntity()
    local playerArray = self._Fight:GetPlayerEntityArray()
    local bossArray = self._Fight:GetBossEntityArray()

    -- 应对2个角色和1个角色下, 居中的问题
    local role1 = self.Role1
    local role3 = self.Role3
    local boss1 = self.Boss1
    local boss3 = self.Boss3
    local positionArrayRole = self:CalculatePosition(role1.transform.localPosition, role3.transform.localPosition, #playerArray)
    local positionArrayBoss = self:CalculatePosition(boss1.transform.localPosition, boss3.transform.localPosition, #bossArray)

    local entityPlayerArray = {}
    for i = 1, 3 do
        local entity = playerArray[i]
        if entity then
            local entityId = entity.Id
            local uiName = string.format("Role%d", i)
            local uiRole = XUiHelper.TryGetComponent(self[uiName], "Holder/PanelRole", "Transform")
            if not uiRole then
                uiRole = CS.UnityEngine.Object.Instantiate(self.PanelRole, self[uiName]:FindTransform("Holder"), false)
            end
            uiRole.gameObject:SetActiveEx(true)
            uiRole.parent.parent.localPosition = positionArrayRole[i]

            ---@type XUiPlanetRunningEntity
            local uiEntity = XUiPlanetRunningEntity.New(uiRole)
            local positionAttacker = Vector3()
            local positionOriginal = uiEntity:GetPositionOriginal()
            positionAttacker.x = positionOriginal.x
            positionAttacker.y = positionOriginal.y + OFFSET_POSITION_ATTACKER
            positionAttacker.z = positionOriginal.z
            uiEntity:SetPositionAttacker(positionAttacker)

            local characterId = entity.DataId.IdFromConfig
            uiEntity:SetIcon(XPlanetCharacterConfigs.GetCharacterIcon(characterId))
            self._Fight:BindUiEntity(entityId, uiEntity)
            entityPlayerArray[#entityPlayerArray + 1] = uiEntity
        end
    end

    for i = 1, 3 do
        local entity = bossArray[i]
        if entity then
            local entityId = entity.Id
            local uiName = string.format("Boss%d", i)
            local uiRole = XUiHelper.TryGetComponent(self[uiName], "Holder/PanelRole", "Transform")
            if not uiRole then
                uiRole = CS.UnityEngine.Object.Instantiate(self.PanelRole, self[uiName]:FindTransform("Holder"), false)
            end
            uiRole.gameObject:SetActiveEx(true)
            uiRole.parent.parent.localPosition = positionArrayBoss[i]

            ---@type XUiPlanetRunningEntity
            local uiEntity = XUiPlanetRunningEntity.New(uiRole)
            local positionAttacker = Vector3()
            local positionOriginal = uiEntity:GetPositionOriginal()
            positionAttacker.x = positionOriginal.x
            positionAttacker.y = positionOriginal.y - OFFSET_POSITION_ATTACKER
            positionAttacker.z = positionOriginal.z
            uiEntity:SetPositionAttacker(positionAttacker)

            local bossId = entity.DataId.IdFromConfig
            uiEntity:SetIcon(XPlanetStageConfigs.GetBossIcon(bossId))
            self._Fight:BindUiEntity(entityId, uiEntity)
        end
    end

    self.PanelRole.gameObject:SetActiveEx(false)
end

function XUiPlanetFightMain:BindAnimationAttack()
    local timelineHelper = self.UiPlanetFightAttack
    self._Fight:BindAnimationAttack(timelineHelper)
end

function XUiPlanetFightMain:CalculatePosition(position1, position2, needAmount)
    if needAmount >= 3 then
        return { position1, (position1 + position2) / 2, position2 }
    end
    if needAmount == 2 then
        local offset = (position2 - position1) / 3
        local p1 = position1 + offset
        local p2 = position1 + offset * 2
        local manualOffsetX = 50
        p1.x = p1.x - manualOffsetX
        p2.x = p2.x + manualOffsetX
        return { p1, p2 }
    end
    if needAmount == 1 then
        return { (position1 + position2) / 2 }
    end
    return {}
end

return XUiPlanetFightMain