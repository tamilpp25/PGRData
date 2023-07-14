local XUiPanelBoard = XClass(nil, "XUiPanelBoard")
local XUiGridBall = require("XUi/XUiSameColorGame/Battle/XUiGridBall")
local XUiGridPos = require("XUi/XUiSameColorGame/Battle/XUiGridPos")
local CSTextManagerGetText = CS.XTextManager.GetText
local ComboSoundMaxIndex = 4
local Vector3 = CS.UnityEngine.Vector3
local Vector2 = CS.UnityEngine.Vector2
local MinSize = 4
local MaxSize = 6
function XUiPanelBoard:Ctor(ui,base, role)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Role = role
    XTool.InitUiObject(self)

    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self.FinishCountDic = {}
    self.ComboCountText:TextToSprite(0,0)
    self.ComboSoundIndex = 1
    self.OldCombo = 0
    self.OldComboLevel = 0
    self.PanelCombo.gameObject:SetActiveEx(false)
    self:InitEffect()
    self:InitPos()
end

function XUiPanelBoard:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ADDBUFF, self.ShowBallEffect, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_SUBBUFF, self.ShowBallEffect, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_MAPINIT, self.InitBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALLREMOVE, self.RemoveBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALLDROP, self.DropBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALLADD, self.AddBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_SHUFFLE, self.ShuffleBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALLSWAP, self.SwapBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALLCHANGECOLOR, self.ChangeBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_UNPREP_SKILL, self.UnSelectBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_PREP_SKILL, self.UnSelectBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ACTIONLIST_OVER, self.CloseCombo, self)
end

function XUiPanelBoard:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ADDBUFF, self.ShowBallEffect, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_SUBBUFF, self.ShowBallEffect, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_MAPINIT, self.InitBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALLREMOVE, self.RemoveBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALLDROP, self.DropBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALLADD, self.AddBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_SHUFFLE, self.ShuffleBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALLSWAP, self.SwapBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALLCHANGECOLOR, self.ChangeBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_UNPREP_SKILL, self.UnSelectBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_PREP_SKILL, self.UnSelectBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ACTIONLIST_OVER, self.CloseCombo, self)
end

local GetTruePos = function(row, col, IsMiniRow, IsMiniCol, MaxSize)
    local IsNotUse = (IsMiniRow and (row == 1 or row == MaxSize)) or (IsMiniCol and (col == 1 or col == MaxSize))
    local trueCol = IsMiniCol and col - 1 or col
    local trueRow = IsMiniRow and row - 1 or row

    return (not IsNotUse) and trueRow, trueCol
end

function XUiPanelBoard:InitEffect()
    self.EffectCombo = {
        self.EffectComboW,
        self.EffectComboY,
        self.EffectComboR,
        }
    self.EffectComboR.gameObject:SetActiveEx(false)
    self.EffectComboW.gameObject:SetActiveEx(false)
    self.EffectComboY.gameObject:SetActiveEx(false)
end

function XUiPanelBoard:InitPos()
    self.GridPosDic = {}
    self.GridBallList = {}
    self.GridPos.gameObject:SetActiveEx(false)
    self.GridBall.gameObject:SetActiveEx(false)

    local boardRow = self.Role:GetRow()
    local boardCol = self.Role:GetCol()
    local IsMiniRow = boardRow < MaxSize
    local IsMiniCol = boardCol < MaxSize

    for row = 1 , MaxSize do
        for col = 1 , MaxSize do
            ----------------正位初始化------------------------
            local trueRow, trueCol = GetTruePos(row, col, IsMiniRow, IsMiniCol, MaxSize)
            local posKey = XSameColorGameConfigs.CreatePosKey(trueCol, trueRow)
            local obj = CS.UnityEngine.Object.Instantiate(self.GridPos, self.PanelPosParent)
            obj.gameObject.name = string.format("Pos%s", posKey)
            obj.gameObject:SetActiveEx(true)
            local posX = self.GridPos.sizeDelta.x * ((col - 1) - (MaxSize / 2 - 0.5))
            local posY = self.GridPos.sizeDelta.y * ((MaxSize / 2 - 0.5) - (row - 1))
            obj.transform.localPosition = Vector3(posX, posY, 0)
            local gridPos = XUiGridPos.New(obj, trueRow, trueCol)
            gridPos:ShowGrid(posKey)
            if posKey then
                self.GridPosDic[posKey] = gridPos
                ----------逆位初始化------------------------------
                local subPosKey = XSameColorGameConfigs.CreatePosKey(trueCol, -trueRow)
                local subPosObj = CS.UnityEngine.Object.Instantiate(self.GridPos, self.PanelPosParent)
                subPosObj.gameObject.name = string.format("Pos%s", subPosKey)
                subPosObj.gameObject:SetActiveEx(false)
                local subGridPos = XUiGridPos.New(subPosObj, -trueRow, trueCol)
                local tmpPos = gridPos.Transform.localPosition
                local offset = (gridPos.Row * 2 - 1) * (self.GridPos.sizeDelta.y)
                subGridPos.Transform.localPosition = Vector3(tmpPos.x , tmpPos.y + offset, tmpPos.z)
                self.GridPosDic[subPosKey] = subGridPos
                ----------------球初始化---------------------
                local ballObj = CS.UnityEngine.Object.Instantiate(self.GridBall, self.PanelBallParent)
                ballObj.gameObject:SetActiveEx(true)
                table.insert(self.GridBallList, XUiGridBall.New(ballObj, self))
            end

        end
    end

    self.PanelBallParent.sizeDelta = Vector2(boardCol * self.GridPos.sizeDelta.x ,boardRow * self.GridPos.sizeDelta.y)
end

function XUiPanelBoard:ShowCombo(count)
    local comboLevel = self.BattleManager:GetBattleComboLevel(count)
    self.ComboCountText:TextToSprite(count,comboLevel - 1)
    self.ComboTitle:TextToSprite("c",comboLevel - 1)
    
    if count > 1 then
        self.PanelCombo.gameObject:SetActiveEx(true)
        self.Base:PlayAnimation("ComboTextEnable")
        self:ShowComboEffect(comboLevel)
    end

    if self.OldCombo < count and count > 1 then
        self.ComboSoundIndex = self.ComboSoundIndex < ComboSoundMaxIndex and self.ComboSoundIndex + 1 or ComboSoundMaxIndex
    else
        self.ComboSoundIndex = 1
    end
    self.OldCombo = count
    self.Base:PlayGameSound(string.format("Remove%d",self.ComboSoundIndex))
end

function XUiPanelBoard:CloseCombo()
    if self.OldCombo <= 1 then
        return
    end

    self.Base:PlayAnimation("ComboTextDisable")
    self.ComboFlagDic = {}
    self.OldComboLevel = 0
    self.OldCombo = 0
end

function XUiPanelBoard:ShowBallEffect()
    for _,ball in pairs(self.GridBallList or {}) do
        ball:SelectEffect()
    end
end

function XUiPanelBoard:ShowComboEffect(comboLevel)
    if self.OldComboLevel ~= comboLevel then
        for index,effect in pairs(self.EffectCombo or {}) do
            effect.gameObject:SetActiveEx(false)
            effect.gameObject:SetActiveEx(index == comboLevel)
        end
    end
    self.OldComboLevel = comboLevel
end

-----------------------------------------BallEvent-------------------------------------------------
function XUiPanelBoard:InitBall(data)
    local ballList = data.BallList
    for index,ballData in pairs(ballList or {}) do
        local gridBall = self.GridBallList[index]
        if gridBall then
            gridBall:UpdateGrid(self.Role:GetBall(ballData.ItemId))
            gridBall:SelectEffect()
            local posKey = XSameColorGameConfigs.CreatePosKey(ballData.PositionX, ballData.PositionY)
            local gridPos = self.GridPosDic[posKey]
            gridBall:EqualPosToGridPos(gridPos)
        end
    end
    self.BattleManager:DoActionFinish(data.ActionType)
end

function XUiPanelBoard:RemoveBall(data)
    local ballList = data.RemoveBallList
    local gridBallList = {}

    for _,ballData in pairs(ballList or {}) do
        local gridBall = self:GetBallGrid(ballData.PositionX, ballData.PositionY)
        table.insert(gridBallList, gridBall)
    end
    
    self:PlayBallWait(gridBallList, "RemoveBall", "Before", function ()
            local combo = self.BattleManager:GetCountCombo()
            self:ShowCombo(combo)

            self.BallCount = {}
            for _,ballData in pairs(ballList or {}) do
                local removePosKey = XSameColorGameConfigs.CreatePosKey(ballData.PositionX, ballData.PositionY)
                local removeGridPos = self.GridPosDic[removePosKey]
                removeGridPos:ShowRemoveEffect()

                self.BallCount[ballData.PositionX] = self.BallCount[ballData.PositionX] and self.BallCount[ballData.PositionX] + 1 or 1
                local gridBall = self:GetBallGrid(ballData.PositionX, ballData.PositionY)
                local tagPosKey = XSameColorGameConfigs.CreatePosKey(ballData.PositionX, -self.BallCount[ballData.PositionX])
                local tagGridPos = self.GridPosDic[tagPosKey]
                gridBall:CloseEffect()
                gridBall:EqualPosToGridPos(tagGridPos)
            end

            self:PlayBallWait(gridBallList, "RemoveBall", "After", function ()
                    self.BattleManager:DoActionFinish(data.ActionType)
                end)
        end)
end

function XUiPanelBoard:DropBall(data)
    local dropBallList = data.DropBallList
    local ballData = {}
    for _,dropBall in pairs(dropBallList or {}) do
        local tmepBall = {StartX = dropBall.StartPositionX, StartY = dropBall.StartPositionY,
            EndX = dropBall.EndPositionX, EndY = dropBall.EndPositionY}
        table.insert(ballData, tmepBall)
    end

    self:MoveBall(ballData, "DropBall", function ()
            self.BattleManager:DoActionFinish(data.ActionType)
        end)
end

function XUiPanelBoard:AddBall(data)
    local addBallList = data.AddBallList
    local ballData = {}

    for _,dropBall in pairs(addBallList or {}) do
        if self.BallCount[dropBall.PositionX] then
            local tmepBall = {ItemId = dropBall.ItemId, StartX = dropBall.PositionX, StartY = (dropBall.PositionY - self.BallCount[dropBall.PositionX] - 1),
                EndX = dropBall.PositionX, EndY = dropBall.PositionY}
            table.insert(ballData, tmepBall)
        end
    end
    self:SetBallId(ballData)
    self:MoveBall(ballData, "AddBall", function ()
            self.BattleManager:DoActionFinish(data.ActionType)
        end)
end

function XUiPanelBoard:SwapBall(data)
    local ballList = {}
    ballList[1] = {StartX = data.SourceBall.PositionX, StartY = data.SourceBall.PositionY,
        EndX = data.DestinationBall.PositionX, EndY = data.DestinationBall.PositionY}

    ballList[2] = {StartX = data.DestinationBall.PositionX, StartY = data.DestinationBall.PositionY,
        EndX = data.SourceBall.PositionX, EndY = data.SourceBall.PositionY}
    self:MoveBall(ballList, "SwapBall", function ()
            self.BattleManager:DoActionFinish(data.ActionType)
        end)
end

function XUiPanelBoard:ChangeBall(data)
    local ballList = data.BallList
    for _,ballData in pairs(ballList or {}) do
        local gridBall = self:GetBallGrid(ballData.PositionX, ballData.PositionY)
        gridBall:UpdateGrid(self.Role:GetBall(ballData.ItemId))
        gridBall:SelectEffect()
    end
    self.BattleManager:DoActionFinish(data.ActionType)
end

function XUiPanelBoard:ShuffleBall(data)
    self:InitBall(data)
    XUiManager.TipText("SameColorGameShuffleBallHint")
end

-----------------------------------------------------------------------------------------------------------
function XUiPanelBoard:GetBallGrid(x, y)
    for _,ball in pairs(self.GridBallList or {}) do
        local position = ball:GetPositionIndex()
        if position.x == x and position.y == y then
            return ball
        end
    end
    return
end

function XUiPanelBoard:SetBallId(ballList)
    for index,ballData in pairs(ballList or {}) do
        local gridBall = self:GetBallGrid(ballData.StartX, ballData.StartY)
        if gridBall then
            gridBall:UpdateGrid(self.Role:GetBall(ballData.ItemId))
            gridBall:SelectEffect()
        end
    end

end

function XUiPanelBoard:MoveBall(ballList, countKey, cb)
    self.FinishCountDic[countKey] = 0

    if ballList and next(ballList) then
        for index,ballData in pairs(ballList) do
            local ball = self:GetBallGrid(ballData.StartX, ballData.StartY)
            local posKey = XSameColorGameConfigs.CreatePosKey(ballData.EndX, ballData.EndY)
            local gridPos = self.GridPosDic[posKey]
            ball:MoveToGridPos(gridPos, function ()
                    self:CheckFinishCount(#ballList, countKey, cb)
                end)
        end
    else
        self:CheckFinishCount(0, countKey, cb)
    end

end

function XUiPanelBoard:PlayBallWait(gridballList, countKey, waitName, cb)
    self.FinishCountDic[countKey] = 0

    if gridballList and next(gridballList) then
        for index,gridBall in pairs(gridballList) do
            gridBall:PlayWait(waitName, function ()
                    self:CheckFinishCount(#gridballList, countKey, cb)
                end)
        end
    else
        self:CheckFinishCount(0, countKey, cb)
    end

end

function XUiPanelBoard:DoSelectBall(ball)
    local prepSkill = self.BattleManager:GetPrepSkill()

    if not prepSkill then
        self:NormalSelect(ball)
    else
        self:SkillSelect(ball, prepSkill)
    end
end

function XUiPanelBoard:NormalSelect(ball)
    if not self.SelectedBall then
        self.SelectedBall = ball
        ball:ShowSelect(true)
    else
        local IsCanRequset = true
        if self.SelectedBall ~= ball then
            local startPos = {PositionX = self.SelectedBall.Col, PositionY = self.SelectedBall.Row}
            local endPos = {PositionX = ball.Col, PositionY = ball.Row}
            IsCanRequset = XSameColorGameConfigs.CheckPosIsAdjoin(startPos, endPos) and self.SelectedBall:GetBallId() ~= ball:GetBallId()
            if IsCanRequset then
                XDataCenter.SameColorActivityManager.RequestSwapBall(startPos, endPos, function ()
                        self.BattleManager:CheckActionList()
                    end)
            else
                self.SelectedBall:ShowSelect(false)
                self.SelectedBall = ball
                ball:ShowSelect(true)
            end
        end

        if IsCanRequset then
            self.SelectedBall:ShowSelect(false)
            self.SelectedBall = nil
        end
    end
end

function XUiPanelBoard:SkillSelect(ball, prepSkill)
    local skillId = prepSkill:GetSkillId()
    local skillGroupId = prepSkill:GetSkillGroupId()
    if prepSkill:GetControlType() == XSameColorGameConfigs.ControlType.ClickBall then
        self:DoOneBallSkill(ball, skillGroupId, skillId)
    elseif prepSkill:GetControlType() == XSameColorGameConfigs.ControlType.ClickTwoBall then
        self:DoTwoBallSkill(ball, skillGroupId, skillId)
    elseif prepSkill:GetControlType() == XSameColorGameConfigs.ControlType.ClickPopup then
        self:DoPopUpSkill(ball, skillGroupId, skillId)
    end
end

function XUiPanelBoard:DoOneBallSkill(ball, skillGroupId, skillId)
    local ball_1 = {
        ItemId = ball:GetBallId(),
        PositionX = ball.Col,
        PositionY = ball.Row
    }
    XDataCenter.SameColorActivityManager.RequestUseItem(skillGroupId, skillId, {Item1 = ball_1, Item2 = {}})
end

function XUiPanelBoard:DoTwoBallSkill(ball, skillGroupId, skillId)
    if not self.SelectedBall then
        self.SelectedBall = ball
        ball:ShowSelect(true)
    else
        local ball_1 = {
            ItemId = self.SelectedBall:GetBallId(),
            PositionX = self.SelectedBall.Col,
            PositionY = self.SelectedBall.Row
        }
        local ball_2 = {
            ItemId = ball:GetBallId(),
            PositionX = ball.Col,
            PositionY = ball.Row
        }
        if self.SelectedBall ~= ball then
            XDataCenter.SameColorActivityManager.RequestUseItem(skillGroupId, skillId, {Item1 = ball_1, Item2 = ball_2})
        end
        self.SelectedBall:ShowSelect(false)
        self.SelectedBall = nil
    end
end

function XUiPanelBoard:DoPopUpSkill(selectBall, skillGroupId, skillId)
    local ball_1 = {
        ItemId = selectBall:GetBallId(),
        PositionX = selectBall.Col,
        PositionY = selectBall.Row
    }
    XLuaUiManager.Open("UiSameColorGameChangeColor", self.Role,
        CSTextManagerGetText("SameColorGameColorSelect"),
        function (ball)
            return ball:GetBallId() ~= selectBall:GetBallId()
        end,
        nil,
        function (ball_2, cb)
            XDataCenter.SameColorActivityManager.RequestUseItem(skillGroupId, skillId, {Item1 = ball_1, Item2 = ball_2}, cb)
        end)
end

function XUiPanelBoard:UnSelectBall()
    for _,gridBall in pairs(self.GridBallList or {}) do
        gridBall:ShowSelect(false)
    end
    self.SelectedBall = nil
end

function XUiPanelBoard:StopBallTween()
    local IsHasTimer = false
    for _,ball in pairs(self.GridBallList or {}) do
        if ball:StopTween() then
            IsHasTimer = true
        end
    end
end

function XUiPanelBoard:CheckFinishCount(maxCount, key, cb)
    self.FinishCountDic[key] = self.FinishCountDic[key] + 1
    if self.FinishCountDic[key] >= maxCount then
        if cb then cb() end
    end
end
return XUiPanelBoard