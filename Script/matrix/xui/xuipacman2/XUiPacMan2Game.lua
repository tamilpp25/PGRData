local XUiPacMan2StarTarget = require("XUi/XUiPacMan2/XUiPacMan2StarTarget")
local XUiPacMan2GridLife = require("XUi/XUiPacMan2/XUiPacMan2GridLife")

local EntityEnum = {
    Orb = 1,
    Key = 2,
    GoldOrb = 3,
    TurnIntoFood = 4,
    TurnIntoShoe = 5,
    Ghost = 6,
    RangeGhost = 7,
    SlowGhost = 8,
    Shoe = 9,
    PlayerClone = 10,
    Food = 11,
}

---@class UiPacMan2Game : XLuaUi
---@field _Control XPacMan2Control
local XUiPacMan2Game = XLuaUiManager.Register(XLuaUi, "UiPacMan2Game")

function XUiPacMan2Game:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OpenPauseUi)
    self._StageId = false
    self._StagePrefab = false
    ---@type XPacMan2.XPacMan2GameManager
    self._GameManager = false
    ---@type XPacMan2.XPacMan2Movement
    self._PlayerMovement = false
    self._IsGameOver = false

    self._HpScoreRatio = 0

    self._DragOffset = XLuaVector2.New()
    self._OperationPos = XLuaVector2.New()

    self._ConfigStarList = false
    self._TargetList = {}
    self._LastScore = -1

    self._CountDown = 0
    --self._CountDownTimer = false

    self._CountDownText = {
        self.RawImgShuzi03,
        self.RawImgShuzi02,
        self.RawImgShuzi01,
        self.RawImgShuzi04,
    }

    self._Hp = false
    ---@type XUiPacMan2GridLife[]
    self._HpGrids = {}
    self.GridLife.gameObject:SetActiveEx(false)

    self._IsCountDown = false
end

function XUiPacMan2Game:OnStart(stageId)
    self._StageId = stageId
    self:StartGame()
end

function XUiPacMan2Game:OnDestroy()
    -- 因为会缓存 prefab，所以这里要手动销毁
    -- 避免下次打开游戏, 使用了缓存的prefab
    local prefabComponent = self.UiSceneInfo.Transform:GetComponent("XUiLoadPrefab")
    if prefabComponent then
        CS.UnityEngine.Object.Destroy(prefabComponent)
    end
    self._StagePrefab = nil
    self._GameManager = nil
    self._PlayerMovement = nil

    ---@type XGoInputHandler
    local goInputHandler = self.InputHandler
    goInputHandler:RemoveAllListeners()
    self._Control:SetPlaying(false)
end

function XUiPacMan2Game:OnEnable()
    self:Update()
    self._TimerId = XScheduleManager.ScheduleForever(function()
        self:Update()
    end, 100) -- 100ms
    self:AddListenerInput()

    -- 键盘图标显示
    if self.Keyboard then
        if XDataCenter.UiPcManager.IsPc() then
            self.Keyboard.gameObject:SetActiveEx(true)
        else
            self.Keyboard.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPacMan2Game:OnDisable()
    XScheduleManager.UnSchedule(self._TimerId)
    self._TimerId = false
    --if self._CountDownTimer then
    --    XScheduleManager.UnSchedule(self._CountDownTimer)
    --    self._CountDownTimer = false
    --end
end

local GameState = {
    None = 0,
    Playing = 1,
    Paused = 2,
    GameOver = 3,
    GameClear = 4,
}

function XUiPacMan2Game:Update()
    if self._IsGameOver then
        return
    end
    if self._GameManager then
        if self._GameManager:GetGameState() == GameState.GameClear
                or self._GameManager:GetGameState() == GameState.GameOver then
            self._IsGameOver = true
            self:OpenSettlement()
        else
            if self._GameManager.IsPauseOnHpDecrease then
                self._GameManager.IsPauseOnHpDecrease = false
                self:StartCountDown()
            end
        end
    end
    local hp = self._GameManager:GetPlayerHp()
    local score = self._GameManager:GetScore() + self:GetHpScore()
    local isUpdateScore = false
    if self._Hp ~= hp then
        local animation = self._Hp ~= false
        self._Hp = hp
        self:UpdateHp(hp, animation)
        isUpdateScore = true
    end
    if self._LastScore ~= score then
        self._LastScore = score
        self:UpdateStar(score)
        isUpdateScore = true
    end
    if isUpdateScore then
        self:UpdateScore(score)
    end
end

function XUiPacMan2Game:StartGame()
    local stageConfig = self._Control:GetStageConfig(self._StageId)
    local prefab = stageConfig.Prefab
    if not prefab or prefab == "" then
        XLog.Error("[UiPacMan2Game] StartGame prefab is nil")
        return
    end
    self._StagePrefab = self.UiSceneInfo.Transform:LoadPrefab(prefab, true, true)
    self._GameManager = self._StagePrefab:FindGameObject("PacManGameManager"):GetComponent("XPacMan2GameManager")
    self._PlayerMovement = self._GameManager.Player:GetComponent("XPacMan2Movement")
    self:ImportConfig()

    -- let's start the game
    self._GameManager:Pause()
    XMVCA.XPacMan2:PacMan2StageStartRequest(self._StageId, function(isSuccess)
        if isSuccess then
            self:StartCountDown()
        else
            XLog.Warning("[XUiPacMan2Game] 错误，应该关闭游戏界面")
            --self:Close()
        end
    end)
end

function XUiPacMan2Game:OpenSettlement()
    local score = self._GameManager.Score

    -- 血量得分
    local hpScore = self:GetHpScore()
    score = score + hpScore

    -- 跑鞋得分
    -- 这部分写在逻辑层，因为跑鞋的得分是动态变化的

    -- 食物得分
    -- 这部分写在逻辑层

    -- 只有成功才发送请求
    if self._GameManager:GetGameState() == GameState.GameClear then
        local data = {
            StageId = self._StageId,
            Score = score,
            --玩法耗时
            Time = math.floor(self._GameManager.Duration),
            --算力结晶
            Orbs = self._GameManager.Orbs,
            --吸入怪兽
            Kills = self._GameManager.Kills,
            --剩余生命
            Hp = self._GameManager:GetPlayerHp(),
            --是否触发1血保底系统
            IsLastHp = self._GameManager.IsLastHp,
            --冲刺穿越
            Shoe = {
                -- 普通怪
                { Id = EntityEnum.Ghost, Times = self._GameManager.ShoeNormalGhost, },
                -- 范围怪
                { Id = EntityEnum.RangeGhost, Times = self._GameManager.ShoeRangeGhost, },
                -- 淤泥怪
                { Id = EntityEnum.SlowGhost, Times = self._GameManager.ShoeSlowGhost, },
                -- 跑鞋道具
                { Id = EntityEnum.Shoe, Times = self._GameManager.ShoeProp, }
            },
        }
        XMVCA.XPacMan2:PacMan2SettleRequest(data)
    end

    ---@class XPacMan2SettlementData
    local data = {
        StageId = self._StageId,
        Score = score,
        IsWin = self._GameManager:GetGameState() == GameState.GameClear,
        Orbs = self._GameManager.Orbs,
        OrbScore = self._GameManager.OrbScore,
        Kills = self._GameManager.Kills,
        KillScore = self._GameManager.KillScore,
        Hp = self._GameManager:GetPlayerHp(),
        HpScore = hpScore,
        ShoeCount = self._GameManager.ShoeCount,
        ShoeScore = self._GameManager.ShoeScore,
    }
    XLuaUiManager.Open("UiPacMan2PopupSettlement", data)
end

function XUiPacMan2Game:ImportConfig()
    self._GameManager.ShouldPauseOnHpDecrease = true

    ---@type UnityEngine.GameObject
    local stagePrefab = self._StagePrefab
    local gameConfig = self._Control:GetGameConfig()

    ---@type XTablePacMan2Stage
    local stageConfig = self._Control:GetStageConfig(self._StageId)
    self._GameManager.OrbsToShowKey = stageConfig.RedOrb
    self._GameManager:SetOrbs(0)

    ---@type XPacMan2.XPacMan2Hp
    local hpComponent = self._GameManager.Player.transform:GetComponent(typeof(CS.XPacMan2.XPacMan2Hp))
    hpComponent.Lives = stageConfig.InitialHp
    hpComponent.MaxLives = stageConfig.InitialHp

    -- 魂石得分
    local orbScore = gameConfig.OrbScore.Value
    local orbs = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Orb), true)
    for i = 0, orbs.Length - 1 do
        local orb = orbs[i]
        orb.Score = orbScore
    end

    -- 怪物得分
    local killMonsterScore = gameConfig.KillMonsterScore.Value
    local ghosts = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Ghost), true)
    for i = 0, ghosts.Length - 1 do
        local ghost = ghosts[i]
        ghost.Score = killMonsterScore
    end

    -- 跑鞋得分
    --local shoeMonsterScore = gameConfig.ShoeMonsterScore.Value
    --local shoes = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Shoe), true)
    --for i = 0, shoes.Length - 1 do
    --    local shoe = shoes[i]
    --    shoe.Score = shoeMonsterScore
    --end
    -- 穿越跑鞋怪物才会得分
    if self._GameManager.ShoeScoreList then
        local shoeScoreList = gameConfig.ShoeMonsterScore.ValueArray
        for i = 1, #shoeScoreList do
            self._GameManager.ShoeScoreList:Add(shoeScoreList[i])
        end
    end

    -- hp得分
    self._HpScoreRatio = gameConfig.HpScore.Value

    -- 角色速度
    local characterSpeed = gameConfig.CharacterSpeed.Value
    local players = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Player), true)
    local characterTurningSpend = gameConfig.CharacterTurningSpend.Value
    for i = 0, players.Length - 1 do
        local player = players[i]
        ---@type UnityEngine.Transform
        local playerTransform = player.transform
        ---@type XPacMan2.XPacMan2Movement
        local movement = playerTransform:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:GetSpeed(characterSpeed)
        movement.RotateDuration = self:GetSpeed(characterTurningSpend)
    end

    -- 金魂石 XPacMan2GoldOrb
    local goldOrbConfig = self._Control:GetEntityConfig(EntityEnum.GoldOrb)
    local goldOrbs = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2GoldOrb), true)
    for i = 0, goldOrbs.Length - 1 do
        local goldOrb = goldOrbs[i]
        goldOrb.Hp = goldOrbConfig.Params[1]
    end

    -- 道具 XPacMan2TurnGhostIntoFood
    local turnIntoFoodConfig = self._Control:GetEntityConfig(EntityEnum.TurnIntoFood)
    local turnIntoFoods = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2TurnGhostIntoFood), true)
    for i = 0, turnIntoFoods.Length - 1 do
        ---@type XPacMan2.XPacMan2TurnGhostIntoFood
        local turnIntoFood = turnIntoFoods[i]
        turnIntoFood.Duration = turnIntoFoodConfig.Params[1]
    end

    -- 食物 XPacMan2Food
    local foodConfig = self._Control:GetEntityConfig(EntityEnum.Food)
    if foodConfig then
        local foods = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Food), true)
        for i = 0, foods.Length - 1 do
            local food = foods[i]
            local movement = food:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
            movement.Speed = self:GetSpeed(foodConfig.Speed)
        end
    end

    -- 跑鞋 XPacMan2TurnGhostIntoShoe
    local turnIntoShoeConfig = self._Control:GetEntityConfig(EntityEnum.TurnIntoShoe)
    local turnIntoShoes = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2TurnGhostIntoShoe), true)
    local shoeConfig = self._Control:GetEntityConfig(EntityEnum.Shoe)
    for i = 0, turnIntoShoes.Length - 1 do
        ---@type XPacMan2.XPacMan2TurnGhostIntoShoe
        local turnIntoShoe = turnIntoShoes[i]
        turnIntoShoe.Duration = turnIntoShoeConfig.Params[1]
        turnIntoShoe.SpeedOverlay = self:GetSpeed(shoeConfig.Params[2])
        turnIntoShoe.SpeedIncrease = self:GetSpeed(shoeConfig.Params[3])
        if shoeConfig.Params[4] and shoeConfig.Params[4] > 0 then
            turnIntoShoe.MaxLayer = shoeConfig.Params[4]
        end
    end

    -- 普通怪 XPacMan2Ghost
    local ghostConfig = self._Control:GetEntityConfig(EntityEnum.Ghost)
    local ghostPatrols = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2BehaviorGhostPatrol), true)
    for i = 0, ghostPatrols.Length - 1 do
        local ghost = ghostPatrols[i]

        local speed = ghostConfig.Speed
        local movement = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:GetSpeed(speed)
        movement.RotateDuration = ghostConfig.TurningDuration

        ---@type XPacMan2.XPacMan2BehaviorGhostRange
        local range = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2BehaviorGhostRange))
        if range then
            range.Range = Vector2(ghostConfig.AlertX, ghostConfig.AlertY)
            range:UpdateRangeVisible()
        end

        self:UpdateRange(range, ghostConfig.AlertVisibility)
    end

    -- 警戒怪 XPacMan2BehaviorGhostRange
    local ghostRangeConfig = self._Control:GetEntityConfig(EntityEnum.RangeGhost)
    local ghostRanges = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2BehaviorGhostRange), true)
    for i = 0, ghostRanges.Length - 1 do
        local ghost = ghostRanges[i]
        if ghost:GetType().Name == "XPacMan2BehaviorGhostRange" then
            local speed = ghostRangeConfig.Speed
            local movement = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
            movement.Speed = self:GetSpeed(speed)
            movement.RotateDuration = ghostRangeConfig.TurningDuration

            ---@type XPacMan2.XPacMan2BehaviorGhostRange
            local range = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2BehaviorGhostRange))
            if range then
                range.Range = Vector2(ghostRangeConfig.AlertX, ghostRangeConfig.AlertY)
                range:UpdateRangeVisible()
            end
            self:UpdateRange(range, ghostRangeConfig.AlertVisibility)
        end
    end

    -- 淤泥怪 XPacMan2SlowDown
    local ghostSlowConfig = self._Control:GetEntityConfig(EntityEnum.SlowGhost)
    local ghostSlowDowns = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SlowDown), true)
    for i = 0, ghostSlowDowns.Length - 1 do
        ---@type XPacMan2.XPacMan2SlowDown
        local ghost = ghostSlowDowns[i]
        local speed = ghostSlowConfig.Speed
        local movement = ghost.transform.parent:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:GetSpeed(speed)
        movement.RotateDuration = ghostSlowConfig.TurningDuration

        ---@type XPacMan2.XPacMan2BehaviorGhostRange
        local range = ghost.transform.parent:GetComponent(typeof(CS.XPacMan2.XPacMan2BehaviorGhostRange))
        if range then
            range.Range = Vector2(ghostSlowConfig.Params[2], ghostSlowConfig.Params[3])
            self:UpdateRange(range, true)
            range:UpdateRangeVisible()
        end

        ghost.SpeedMultipiler = ghostSlowConfig.Params[1] / 100
        --ghost.Range = Vector2(ghostSlowConfig.Params[2], ghostSlowConfig.Params[3])

        ---@type XPacMan2.XPacMan2SlowDown
        local slowDown = ghostSlowDowns[i]
        slowDown.Range = Vector2(ghostSlowConfig.Params[2], ghostSlowConfig.Params[3])
        slowDown:UpdateRange()
    end

    -- 跑鞋 XPacMan2Shoe
    local shoeConfig = self._Control:GetEntityConfig(EntityEnum.Shoe)
    local shoes = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Shoe), true)
    for i = 0, shoes.Length - 1 do
        local shoe = shoes[i]
        local shoeTransform = shoe.transform
        local movement = shoeTransform:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:GetSpeed(shoeConfig.Speed)
    end

    -- 分身 XPacMan2PlayerClone
    local playerCloneConfig = self._Control:GetEntityConfig(EntityEnum.PlayerClone)
    local playerClones = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2PlayerClone), true)
    for i = 0, playerClones.Length - 1 do
        local playerClone = playerClones[i]
        local playerCloneTransform = playerClone.transform
        local movement = playerCloneTransform:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:GetSpeed(playerCloneConfig.Speed)

        playerClone.Duration = playerCloneConfig.Params[1]
        playerClone.GhostStopDuration = playerCloneConfig.Params[2]
    end

    -- 星级
    self._ConfigStarList = stageConfig.Star

    -- 无敌效果的持续时间
    local invincibleValue = gameConfig.Invincible.Value
    if invincibleValue then
        local invincibles = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Invincible), true)
        for i = 0, invincibles.Length - 1 do
            local invincible = invincibles[i]
            invincible.Duration = invincibleValue / 1000
        end
    else
        XLog.Error("[XUiPacMan2Game] 找不到无敌时间长度的配置")
    end
end

function XUiPacMan2Game:GetSpeed(value)
    return value / 1000
end

function XUiPacMan2Game:UpdateRange(range, value)
    if value then
        range.RangeTransform.gameObject:SetActiveEx(true)
        range.IsRangeVisible = true
    else
        range.RangeTransform.gameObject:SetActiveEx(false)
        range.IsRangeVisible = false
    end
end

function XUiPacMan2Game:AddListenerInput()
    ---@type XGoInputHandler
    local goInputHandler = self.InputHandler
    goInputHandler:AddPointerDownListener(function(...)
        self:OnBeginDrag(...)
    end)
    goInputHandler:AddDragListener(function(...)
        self:OnDrag(...)
    end)
    goInputHandler:AddPointerUpListener(function(...)
        self:OnEndDrag(...)
    end)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPacMan2Game:OnBeginDrag(eventData)
    local x, y = self:GetPosByEventData(eventData)
    self._DragOffset.x = x
    self._DragOffset.y = y
end

-----@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPacMan2Game:OnDrag(eventData)
    local x, y = self:GetPosByEventData(eventData)
    local offsetX = x - self._DragOffset.x
    local offsetY = y - self._DragOffset.y

    local isTriggerMove = false
    if offsetX ^ 2 + offsetY ^ 2 > 100 then
        local atan = math.atan(offsetY, offsetX) * 180 / math.pi
        if atan < 45 and atan > -45 then
            self._PlayerMovement:MoveRight()
            isTriggerMove = true
        elseif atan > 135 or atan < -135 then
            self._PlayerMovement:MoveLeft()
            isTriggerMove = true
        elseif atan > 45 and atan < 135 then
            self._PlayerMovement:MoveUp()
            isTriggerMove = true
        elseif atan < -45 and atan > -135 then
            self._PlayerMovement:MoveDown()
            isTriggerMove = true
        end
    end

    -- 重置操控点
    if isTriggerMove then
        self._DragOffset.x = x
        self._DragOffset.y = y
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPacMan2Game:OnEndDrag(eventData)
    self._DragOffset.x = 0
    self._DragOffset.y = 0
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPacMan2Game:GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.InputHandler.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end
    local x, y = point.x, point.y
    return x, y
end

function XUiPacMan2Game:UpdateStar(score)
    local starDatas = {}
    for i = 1, #self._ConfigStarList do
        local starScore = self._ConfigStarList[i]
        ---@class XUiPacMan2StarTargetData
        local starData = {
            Star = i,
            Score = starScore,
            IsOn = score >= self._ConfigStarList[i],
        }
        table.insert(starDatas, starData)
    end
    XTool.UpdateDynamicItem(self._TargetList, starDatas, self.PanelStar1, XUiPacMan2StarTarget, self)
end

function XUiPacMan2Game:StartCountDown()
    self._IsCountDown = true
    self.PanelCountdown.gameObject:SetActiveEx(true)
    self:PlayAnimation("Countdown", function()
        self._IsCountDown = false
        self.PanelCountdown.gameObject:SetActiveEx(false)
        self._GameManager:Resume()
    end)
    --local countDown = 4
    --self._CountDown = countDown - 1
    --self:SetCountDownText(countDown - self._CountDown)
    --self.PanelCountdown.gameObject:SetAxctiveEx(true)
    --self._CountDownTimer = XScheduleManager.ScheduleForever(function()
    --    self._CountDown = self._CountDown - 1
    --    self:SetCountDownText(countDown - self._CountDown)
    --    if self._CountDown < 0 then
    --        XScheduleManager.UnSchedule(self._CountDownTimer)
    --        self._CountDownTimer = false
    --        self._GameManager:Resume()
    --        self.PanelCountdown.gameObject:SetActiveEx(false)
    --        self._IsCountDown = false
    --    end
    --end, XScheduleManager.SECOND)
end

function XUiPacMan2Game:SetCountDownText(value)
    for i = 1, 4 do
        local ui = self._CountDownText[i]
        if ui then
            if value then
                ui.gameObject:SetActiveEx(value == i)
            end
        end
    end
end

function XUiPacMan2Game:UpdateHp(hp, animation)
    for i = 1, hp do
        local gridLife = self._HpGrids[i]
        if not gridLife then
            local ui = XUiHelper.Instantiate(self.GridLife, self.GridLife.transform.parent)
            ui.gameObject:SetActiveEx(true)
            gridLife = XUiPacMan2GridLife.New(ui, self)
            table.insert(self._HpGrids, gridLife)
        end
        gridLife:Update(true, animation)
    end
    for i = hp + 1, #self._HpGrids do
        local gridLife = self._HpGrids[i]
        if gridLife then
            gridLife:Update(false, animation)
        end
    end
end

function XUiPacMan2Game:UpdateScore(score)
    if self._GameManager.Ui then
        self._GameManager.Ui:SetScore(score)
    end
end

function XUiPacMan2Game:GetHpScore()
    -- 血量得分
    local hp = self._GameManager:GetPlayerHp()
    local hpScore = hp * self._HpScoreRatio
    return hpScore
end

function XUiPacMan2Game:OpenPauseUi()
    if self._IsCountDown then
        return
    end
    self._GameManager:Pause()
    XLuaUiManager.Open("UiPacMan2PopupStageStop", self._StageId, function()
        self:StartCountDown()
        --self._GameManager:Resume()
    end)
end

return XUiPacMan2Game