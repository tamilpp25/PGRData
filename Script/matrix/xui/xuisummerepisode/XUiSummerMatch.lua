local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSummerMatch = XLuaUiManager.Register(XLuaUi, "UiSummerMatch")
local XUiGridMatchReward = require("XUi/XUiSummerEpisode/XUiGridMatchReward")
local XUiGridEliminate = require("XUi/XUiSummerEpisode/XUiGridEliminate")
local XUiGridEliminateIcon = require("XUi/XUiSummerEpisode/XUiGridEliminateIcon")

function XUiSummerMatch:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnRollBack.CallBack = function() self:OnBtnRollBackClick() end
    self.BtnRes.CallBack = function() self:OnBtnResClick() end

    self.GridReward.gameObject:SetActiveEx(false)
end

function XUiSummerMatch:OnStart(gameId)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRewardList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridMatchReward)

    self.ImgIcon.gameObject:SetActiveEx(false)

    self.Point = {}
    self.GridEliminate = {}
    self.PointIcons = {}
    for i = 1, 16 do
        self.Point[i] = self["Pos" .. tostring(i)]
        self.GridEliminate[i] = XUiGridEliminate.New(self.Point[i], self)
        local go = CS.UnityEngine.GameObject.Instantiate(self.ImgIcon.gameObject)
        go.transform:SetParent(self.PanelPos, false)
        go.transform.position = self.Point[i].position
        self.PointIcons[i] = XUiGridEliminateIcon.New(go)
        --self.PointIcons[i] = go:GetComponent("Image")
    end

    self.GameId = gameId

    self:SetupGameData()
    self:RegisterHelpBtn()
    self:SetTimer()
    self:TryShowHelpTip()
end

--弹出帮助
function XUiSummerMatch:TryShowHelpTip()
    local value = XDataCenter.EliminateGameManager.GetEliminateGamePrefs(self.GameId)
    if value == 0 then
        local config = XHelpCourseConfig.GetHelpCourseTemplateById(self.GameData.Config.HelpId)
        XUiManager.ShowHelpTip(config.Function)
        XDataCenter.EliminateGameManager.SaveEliminateGamePrefs(1, self.GameId)
    end
end


function XUiSummerMatch:SetupGameData()

    local gameData = XDataCenter.EliminateGameManager.GetEliminateGameData(self.GameId)
    if not gameData then
        return
    end

    self.GameData = gameData
    self:SetupReward()
    self:SetupDesc()
    self:SetupGrid()
end

function XUiSummerMatch:SetupDesc()
    self.PanelFlip.gameObject:SetActiveEx(self.GameData.State == XDataCenter.EliminateGameManager.EliminateGameState.Flip)
    self.PanelExchange.gameObject:SetActiveEx(self.GameData.State == XDataCenter.EliminateGameManager.EliminateGameState.Move)
    self.BtnRollBack.gameObject:SetActiveEx(not self.GameData.IsEliminateAll)
    if self.GameData.State == XDataCenter.EliminateGameManager.EliminateGameState.Flip then
        local flipCostItem = self.GameData.Config.FlipItemId
        local count = XDataCenter.ItemManager.GetCount(flipCostItem)
        self.TxtRewardCount.text = tostring(count)
        local icon = XDataCenter.ItemManager.GetItemIcon(flipCostItem)
        self.FlipRawImage:SetRawImage(icon)
    elseif self.GameData.State == XDataCenter.EliminateGameManager.EliminateGameState.Move then
        local costItem = self.GameData.Config.MoveItemId
        local count = XDataCenter.ItemManager.GetCount(costItem)
        self.TxtCount.text = tostring(count)
        local icon = XDataCenter.ItemManager.GetItemIcon(costItem)
        self.ExchangeRawImage:SetRawImage(icon)
    end
end

function XUiSummerMatch:SetupGrid()
    local lineCount = self.GameData.Config.LineCount
    local curGrids = self.GameData.CurGrids
    for i, v in ipairs(curGrids) do
        local index = v.X + (v.Y - 1) * lineCount
        local config = XEliminateGameConfig.GetEliminateGameGrid(v.Id)
        local girdTypeCfg = XEliminateGameConfig.GetEliminateGameGridByType(config.Type)
        self.GridEliminate[index]:SetSelected(false)
        self.GridEliminate[index]:SetData(v, self.GameId)

        if config.Type ~= XDataCenter.EliminateGameManager.EliminateGameSpecialType.Obstacle and config.Type ~= XDataCenter.EliminateGameManager.EliminateGameSpecialType.Space then
            self.PointIcons[index]:SetIcon(girdTypeCfg.TypePic)
        else
            self.PointIcons[index].GameObject:SetActiveEx(false)
        end

        if self.GameData.State == XDataCenter.EliminateGameManager.EliminateGameState.Flip then
            self.GridEliminate[index]:SetSelectedEnable(false)
            if v.State == XDataCenter.EliminateGameManager.EliminateGridState.Cover then
                self.GridEliminate[index]:SetupFlip()
            elseif v.State == XDataCenter.EliminateGameManager.EliminateGridState.Normal then
                if config.Type == XDataCenter.EliminateGameManager.EliminateGameSpecialType.Obstacle then
                    self.GridEliminate[index]:SetupForbidden()
                elseif config.Type == XDataCenter.EliminateGameManager.EliminateGameSpecialType.Space then
                    self.GridEliminate[index]:SetupNormal()
                    self.PointIcons[index].GameObject:SetActiveEx(false)
                else
                    self.GridEliminate[index]:SetupNormal()
                    self.PointIcons[index].GameObject:SetActiveEx(true)
                end
            elseif v.State == XDataCenter.EliminateGameManager.EliminateGridState.Reward then
                self.GridEliminate[index]:SetupReward()
                self.GridEliminate[index]:SetSelectedEnable(true)

                self.PointIcons[index].GameObject:SetActiveEx(false)
            end
        elseif self.GameData.State == XDataCenter.EliminateGameManager.EliminateGameState.Move then
            if v.State == XDataCenter.EliminateGameManager.EliminateGridState.Normal then
                if config.Type == XDataCenter.EliminateGameManager.EliminateGameSpecialType.Obstacle then
                    self.GridEliminate[index]:SetupForbidden()
                elseif config.Type == XDataCenter.EliminateGameManager.EliminateGameSpecialType.Space then
                    self.GridEliminate[index]:SetupNormal()
                    self.GridEliminate[index]:SetSelectedEnable(true)
                else
                    self.GridEliminate[index]:SetupNormal()
                    self.PointIcons[index].GameObject:SetActiveEx(true)
                    self.GridEliminate[index]:SetSelectedEnable(true)
                end
            elseif v.State == XDataCenter.EliminateGameManager.EliminateGridState.Reward then
                self.GridEliminate[index]:SetupReward()
                self.GridEliminate[index]:SetSelectedEnable(true)
                self.PointIcons[index].GameObject:SetActiveEx(false)
            end

            -- if config.Type == 0 then
            --     self.GridEliminate[index]:SetupForbidden()
            -- end
        end
    end
end

function XUiSummerMatch:OnClickGrid(gridData)

    if not gridData then
        return
    end

    local config = XEliminateGameConfig.GetEliminateGameGrid(gridData.Id)


    local lineCount = self.GameData.Config.LineCount

    if self.GameData.State == XDataCenter.EliminateGameManager.EliminateGameState.Flip then

        if gridData.State == XDataCenter.EliminateGameManager.EliminateGridState.Cover then
            if XDataCenter.EliminateGameManager.CheckCanFlipGrid(self.GameId) then
                XDataCenter.EliminateGameManager.RequestEliminateGameFlip(self.GameId, gridData.X, gridData.Y, function()

                    local index = gridData.X + (gridData.Y - 1) * lineCount

                    self.GridEliminate[index]:PlayFlipTimeline(function()

                        if config.Type == XDataCenter.EliminateGameManager.EliminateGameSpecialType.Obstacle then
                            self.GridEliminate[index]:SetupForbidden()
                        elseif config.Type == XDataCenter.EliminateGameManager.EliminateGameSpecialType.Space then
                            self.GridEliminate[index]:SetupNormal()
                            self.PointIcons[index].GameObject:SetActiveEx(false)
                        else
                            self.GridEliminate[index]:SetupNormal()
                            self.PointIcons[index].GameObject:SetActiveEx(true)
                        end

                        self:OnGridFilp(self.GridEliminate[index])
                    end)
                end)
            end
        end
    elseif self.GameData.State == XDataCenter.EliminateGameManager.EliminateGameState.Move then
        local index = gridData.X + (gridData.Y - 1) * lineCount

        if not XDataCenter.EliminateGameManager.CheckCanExchangeGrid(self.GameId, true) then
            return
        end

        if gridData.State == XDataCenter.EliminateGameManager.EliminateGridState.Normal then


            if self.CurSelectedGrid then
                if self.CurSelectedGrid.X == gridData.X and self.CurSelectedGrid.Y == gridData.Y then
                    self:ResetNeighBor()
                    self.GridEliminate[index]:SetSelected(false)
                    self.CurSelectedGrid = nil
                elseif self:IsNeighBor(gridData) then
                    self:ResetNeighBor()
                    XDataCenter.EliminateGameManager.RequestEliminateGameMove(self.GameId, self.CurSelectedGrid.X, self.CurSelectedGrid.Y, gridData.X, gridData.Y, function(eliminateGrids)
                        self:ExChangeGrid(self.CurSelectedGrid, gridData, eliminateGrids)
                    end)
                    --    end
                else
                    self:ResetNeighBor()
                    local selectedIndex = self.CurSelectedGrid.X + (self.CurSelectedGrid.Y - 1) * lineCount
                    self.GridEliminate[selectedIndex]:SetSelected(false)
                    self.CurSelectedGrid = nil
                    if config.Type ~= XDataCenter.EliminateGameManager.EliminateGameSpecialType.Space and config.Type ~= XDataCenter.EliminateGameManager.EliminateGameSpecialType.Obstacle then
                        self.CurSelectedGrid = gridData
                        self.GridEliminate[index]:SetSelected(true)
                        self:HighLightNeighBor(gridData)
                    end
                end
            else
                if config.Type ~= XDataCenter.EliminateGameManager.EliminateGameSpecialType.Space and config.Type ~= XDataCenter.EliminateGameManager.EliminateGameSpecialType.Obstacle then
                    self.CurSelectedGrid = gridData
                    self.GridEliminate[index]:SetSelected(true)
                    self:HighLightNeighBor(gridData)
                end
            end
        elseif gridData.State == XDataCenter.EliminateGameManager.EliminateGridState.Reward then
            if self.CurSelectedGrid then
                if self.CurSelectedGrid.X == gridData.X and self.CurSelectedGrid.Y == gridData.Y then
                    self:ResetNeighBor()
                    self.GridEliminate[index]:SetSelected(false)
                    self.CurSelectedGrid = nil
                elseif self:IsNeighBor(gridData) then
                    self:ResetNeighBor()
                    XDataCenter.EliminateGameManager.RequestEliminateGameMove(self.GameId, self.CurSelectedGrid.X, self.CurSelectedGrid.Y, gridData.X, gridData.Y, function(eliminateGrids)
                        self:ExChangeGrid(self.CurSelectedGrid, gridData, eliminateGrids)
                    end)
                else
                    self:ResetNeighBor()
                    local selectedIndex = self.CurSelectedGrid.X + (self.CurSelectedGrid.Y - 1) * lineCount
                    self.GridEliminate[selectedIndex]:SetSelected(false)
                    self.CurSelectedGrid = nil
                end
            end
        end
    end
end

--判断是否相邻
function XUiSummerMatch:IsNeighBor(gridData)
    if not self.NeighBors then
        return false
    end

    for _, v in ipairs(self.NeighBors) do
        if v.X == gridData.X and v.Y == gridData.Y then
            return true
        end
    end

    return false
end

--交换
function XUiSummerMatch:ExChangeGrid(girdA, girdB, eliminateGrids)

    local lineCount = self.GameData.Config.LineCount
    local indexA = girdA.X + (girdA.Y - 1) * lineCount
    local indexB = girdB.X + (girdB.Y - 1) * lineCount
    local iconA = self.PointIcons[indexA]
    local iconB = self.PointIcons[indexB]

    self.GridEliminate[indexA]:SetSelected(false)
    self.GridEliminate[indexB]:SetSelected(false)

    XLuaUiManager.SetMask(true)

    XUiHelper.DoMove(iconA.Transform, self.Point[indexB].localPosition, 0.5, XUiHelper.EaseType.Sin, function()
        self.CurSelectedGrid = nil
        if eliminateGrids and #eliminateGrids > 0 then
            self:EliminateGrid(eliminateGrids)
        else

            if XDataCenter.EliminateGameManager.CheckCanExchangeGrid(self.GameId) then
                self.CurSelectedGrid = girdA
                self.GridEliminate[indexA]:SetSelected(true)
                self:HighLightNeighBor(girdA)
            end
            XLuaUiManager.SetMask(false)
            self:Refresh()
        end
    end)


    XUiHelper.DoMove(iconB.Transform, self.Point[indexA].localPosition, 0.5, XUiHelper.EaseType.Sin)
    self.CurSelectedGrid = self.GridEliminate[indexA]


    self.GridEliminate[indexA].GridData = girdA
    self.GridEliminate[indexB].GridData = girdB




    self.PointIcons[indexA] = iconB
    self.PointIcons[indexB] = iconA
end

function XUiSummerMatch:EliminateGrid(eliminateGrids)
    local lineCount = self.GameData.Config.LineCount

    XScheduleManager.ScheduleOnce(function()
        for i, v in ipairs(eliminateGrids) do
            local index = v.X + (v.Y - 1) * lineCount
            self.PointIcons[index]:PlayTime(function()
                self.GridEliminate[index]:SetupReward()
                if i == #eliminateGrids then
                    XLuaUiManager.SetMask(false)
                    self:Refresh()
                    self:SetupReward()

                    if self.GameData.IsEliminateAll then
                        XUiManager.TipText("EliminateEnd", XUiManager.UiTipType.Tip)
                    end
                end
                self.PointIcons[index]:PlayTimelineEnd()

            end)
        end
    end, 0)
end


function XUiSummerMatch:Refresh()
    self.GameData = XDataCenter.EliminateGameManager.GetEliminateGameData(self.GameId)
    self:SetupDesc()
end

--高亮旁边的
function XUiSummerMatch:HighLightNeighBor(gridData)
    local lineCount = self.GameData.Config.LineCount
    self.NeighBors = {}

    local centerIndex = gridData.X + (gridData.Y - 1) * lineCount

    local upIndex = gridData.X + (gridData.Y - 2) * lineCount
    local y = gridData.Y - 2
    local grid = self.GridEliminate[upIndex]
    if y >= 0 and y <= lineCount and grid and (not grid:IsObstacle()) then
        grid:SetNeighBorSelected(true)
        table.insert(self.NeighBors, grid.GridData)
    end

    local downIndex = gridData.X + gridData.Y * lineCount
    y = gridData.Y
    grid = self.GridEliminate[downIndex]
    if y >= 0 and y <= lineCount and grid and (not grid:IsObstacle()) then
        grid:SetNeighBorSelected(true)
        table.insert(self.NeighBors, grid.GridData)
    end

    local leftIndex = (gridData.X - 1) + (gridData.Y - 1) * lineCount
    local x = (gridData.X - 1)
    grid = self.GridEliminate[leftIndex]

    if x > 0 and x <= #self.GridEliminate / lineCount and grid and (not grid:IsObstacle()) then
        grid:SetNeighBorSelected(true)
        table.insert(self.NeighBors, grid.GridData)
    end

    local rightIndex = (gridData.X + 1) + (gridData.Y - 1) * lineCount
    local x = (gridData.X + 1)
    grid = self.GridEliminate[rightIndex]

    if x > 0 and x <= #self.GridEliminate / lineCount and grid and (not grid:IsObstacle()) then
        grid:SetNeighBorSelected(true)
        table.insert(self.NeighBors, grid.GridData)
    end
end

--重置高亮
function XUiSummerMatch:ResetNeighBor()
    if not self.NeighBors then
        return
    end
    local lineCount = self.GameData.Config.LineCount

    for _, v in ipairs(self.NeighBors) do
        local index = v.X + (v.Y - 1) * lineCount
        self.GridEliminate[index]:SetNeighBorSelected(false)
    end

    self.NeighBors = {}
end

--翻转
function XUiSummerMatch:OnGridFilp(grid)

    self:SetupGrid()
    self:SetupDesc()
end


function XUiSummerMatch:SetupReward()
    local rewardList = self.GameData.Rewards
    if not rewardList then
        return
    end


    table.sort(rewardList, function(a, b)
        local isARewarded = XDataCenter.EliminateGameManager.IsRewarded(a.GameId, a.Id)
        local isAFinish = XDataCenter.EliminateGameManager.IsRewardFinish(a)

        local isBRewarded = XDataCenter.EliminateGameManager.IsRewarded(b.GameId, b.Id)
        local isBFinish = XDataCenter.EliminateGameManager.IsRewardFinish(b)
        local pA = 1
        local pB = 1

        if isAFinish then
            pA = pA + 2
        end

        if isARewarded then
            pA = pA - 3
        end

        if isBFinish then
            pB = pB + 2
        end

        if isBRewarded then
            pB = pB - 3
        end

        if pA == pB then
            return a.Id < b.Id
        end

        return pA > pB

    end)


    self.RewardList = rewardList


    self.DynamicTable:SetDataSource(self.RewardList)
    self.DynamicTable:ReloadDataSync()
end


function XUiSummerMatch:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSummerMatch:OnBtnRollBackClick()
    if not self.GameData.MoveCost or self.GameData.MoveCost <= 0 then
        XUiManager.TipText("EliminateCannotReset", XUiManager.UiTipType.Tip)
        return
    end

    local title = CS.XTextManager.GetText("EliminateResetTitle")
    local content = CS.XTextManager.GetText("EliminateResetContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    end, function()
        XDataCenter.EliminateGameManager.RequestEliminateGameReset(self.GameId, function()
            XUiManager.TipText("EliminateResetSuccess", XUiManager.UiTipType.Tip)
            self.CurSelectedGrid = nil
            self:SetupGameData()
        end)
    end)

end

function XUiSummerMatch:RegisterHelpBtn()
    local config = XHelpCourseConfig.GetHelpCourseTemplateById(self.GameData.Config.HelpId)
    self:BindHelpBtn(self.BtnHelpCourse, config.Function)
end

function XUiSummerMatch:OnBtnResClick()
    local itemId = -1
    if self.GameData.State == XDataCenter.EliminateGameManager.EliminateGameState.Flip then
        itemId = self.GameData.Config.FlipItemId
    elseif self.GameData.State == XDataCenter.EliminateGameManager.EliminateGameState.Move then
        itemId = self.GameData.Config.MoveItemId
    end

    XLuaUiManager.Open("UiTip", itemId, self.HideSkipBtn)

end


function XUiSummerMatch:OnBtnBackClick()
    self:Close()
end

function XUiSummerMatch:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.RewardList[index]
        if not data then return end
        grid:Refresh(data)
    end
end


function XUiSummerMatch:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ELIMINATEGAME_GET_REWARD then
        self:SetupReward()
        --elseif evt == XEventId.EVENT_ELIMINATEGAME_RESET then
        -- self:SetupReward()
    end
end

function XUiSummerMatch:OnGetEvents()
    return { XEventId.EVENT_ELIMINATEGAME_GET_REWARD, XEventId.EVENT_ELIMINATEGAME_RESET }
end


--停止计时器
function XUiSummerMatch:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--活动时间倒计时
function XUiSummerMatch:SetTimer()
    local endTimeSecond = XTime.ParseToTimestamp(self.GameData.Config.EndTimeStr)
    local now = XTime.GetServerNowTimestamp()
    if now <= endTimeSecond then
        local activeOverStr = CS.XTextManager.GetText("ArenaOnlineLeftTimeOver")
        self:StopTimer()
        if now <= endTimeSecond then
            self.TxtLeft.text = string.format("%s", XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.ACTIVITY))
        else
            self.TxtLeft.text = activeOverStr
        end

        self.Timer = XScheduleManager.ScheduleForever(function()
            now = XTime.GetServerNowTimestamp()
            if now > endTimeSecond then
                self:StopTimer()
                XUiManager.TipMsg(CS.XTextManager.GetText("EliminateTimeOut"))
                self:Close()
                return
            end
            if now <= endTimeSecond then
                self.TxtLeft.text = string.format("%s", XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.ACTIVITY))
            else
                self.TxtLeft.text = activeOverStr
            end
        end, XScheduleManager.SECOND, 0)
    end
end

function XUiSummerMatch:OnDisable()
    self:StopTimer()
end


function XUiSummerMatch:OnEnable()
    if XDataCenter.EliminateGameManager.CheckTimeOut(self.GameId, true) then
        XLuaUiManager.RunMain()
    end

    self:SetTimer()
end