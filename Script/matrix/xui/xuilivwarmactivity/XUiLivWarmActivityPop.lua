local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XUiLivWarmActivityPopGrid = require("XUi/XUiLivWarmActivity/XUiLivWarmActivityPopGrid")
local XUiLivWarmActivityRewardGrid = require("XUi/XUiLivWarmActivity/XUiLivWarmActivityRewardGrid")

local XUiLivWarmActivityPop = XLuaUiManager.Register(XLuaUi, "UiLivWarmActivityPop")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local Disable = CS.UiButtonState.Disable
local tableInsert = table.insert

local CanClearHeadMinCount = 3      --同一行或同一列中，相同颜色的格子消除的最小数量
local HelpKey = "LivWarmActivityHelp"

--超丽芙预热主界面（消消乐）
function XUiLivWarmActivityPop:OnAwake()
    self:RegisterButtonEvent()
    self.CurSelectTabIndex = 0
    self.MaxRewardProgress = 0      --当前选择的关卡最大消除进度奖励
    self.PhasesRewardGrids = {}
    self.PhasesRewardGridRects = {}
    self.GridMine.gameObject:SetActiveEx(false)
    self.RewardTmp.gameObject:SetActiveEx(false)

    self:InitLoseIcon()
    self:InitPanelSpecialTool()
end

function XUiLivWarmActivityPop:OnStart()
    self.GridTemplates = {}
    self.CanSwapGrids = {}     --可以和已选择的格子交换的格子位置

    self:InitChapterGroup()
    self:CheckAutoOpenHelp()
end

function XUiLivWarmActivityPop:OnEnable()
    self:StartActivityTimer()
    self:Refresh()
    self:UpdatePhasesRewardGrid()
end

function XUiLivWarmActivityPop:OnDisable()
    self:StopActivityTimer()
    self:StopPlayMoveActionTimer()
    self:StopRewardProgressTimer()
end

function XUiLivWarmActivityPop:CheckAutoOpenHelp()
    local isFirstOpenView = XDataCenter.LivWarmActivityManager.IsFirstOpenView()
    if isFirstOpenView then
        XUiManager.ShowHelpTip(HelpKey)
        XDataCenter.LivWarmActivityManager.SetFirstOpenViewCookie()
    end
end

function XUiLivWarmActivityPop:InitChapterGroup()
    self.StageIdList = XLivWarmActivityConfigs.GetLivWarmStageIdList()
    self.TabGroup = {}
    local defaultIndex = 1
    local btnName
    local btnEnName
    for i, stageId in ipairs(self.StageIdList) do
        local btn = i == 1 and self.BtnTog or CSUnityEngineObjectInstantiate(self.BtnTog, self.ChapterGroup.transform)
        btnName = XLivWarmActivityConfigs.GetLivWarmActivityStageClientStageName(stageId)
        btnEnName = XLivWarmActivityConfigs.GetLivWarmActivityStageClientStageEnName(stageId)
        btn:SetNameByGroup(0, btnName)
        btn:SetNameByGroup(1, btnEnName)
        tableInsert(self.TabGroup, btn)

        if XDataCenter.LivWarmActivityManager.IsUnlockStage(stageId) then
            defaultIndex = i
        end
    end
    self.ChapterGroup:Init(self.TabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    self.ChapterGroup:SelectIndex(defaultIndex)
end

function XUiLivWarmActivityPop:InitPanelSpecialTool()
    local itemId = XLivWarmActivityConfigs.GetLivWarmActivityItemId()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    self.AssetActivityPanel:Refresh({itemId})
    XDataCenter.ItemManager.AddCountUpdateListener({itemId}, function()
        self:UpdateLoseText()
        self.AssetActivityPanel:Refresh({itemId}) 
    end, self.AssetActivityPanel)
end

function XUiLivWarmActivityPop:InitLoseIcon()
    local itemId = XLivWarmActivityConfigs.GetLivWarmActivityItemId()
    local icon = XItemConfigs.GetItemIconById(itemId)
    self.LoseIcon:SetRawImage(icon)
end

function XUiLivWarmActivityPop:UpdateLoseText()
    if self.StageDb:IsWin() then
        self.PanelCondition.gameObject:SetActiveEx(false)
        return
    end

    local itemId = XLivWarmActivityConfigs.GetLivWarmActivityItemId()
    local useItemCount = XLivWarmActivityConfigs.GetLivWarmActivityUseItemCount()
    local itemCount = XDataCenter.ItemManager.GetCount(itemId)
    local color = itemCount < useItemCount and "#7EE4D7" or "#cc84d5"
    local isMaxItemUseCount = self:GetCurUseItemData()
    useItemCount = isMaxItemUseCount and 0 or useItemCount      --达到消耗上限显示0
    self.LoseText.text = CSXTextManagerGetText("LivWarmActivityUseItemCountText", color, useItemCount)
    self.PanelCondition.gameObject:SetActiveEx(true)
end

function XUiLivWarmActivityPop:Refresh()
    self:UpdateGridTemplates()
    self:UpdateReminderLoseText()
    self:UpdateChapterGroupState()
    self:UpdateLoseText()
    self:UpdateRedPoint()
    self:RefreshPanelEntranceRedPoint()
    self:UpdatePanelClearance()
end

function XUiLivWarmActivityPop:UpdatePanelClearance()
    if not self.StageDb:IsWin() then
        self.PanelClearance.gameObject:SetActiveEx(false)
        return
    end

    self.PanelClearance.gameObject:SetActiveEx(true)

    local stageId = self:GetStageId()
    self.TxtClearLevel.text = XLivWarmActivityConfigs.GetLivWarmActivityStageClientCgText(stageId)
    self.ImageCg:SetRawImage(XLivWarmActivityConfigs.GetLivWarmActivityStageClientCgPic(stageId))
end

function XUiLivWarmActivityPop:UpdateChapterGroupState()
    local btn
    local isUnLock

    for i, stageId in ipairs(self.StageIdList) do
        isUnLock = XDataCenter.LivWarmActivityManager.IsUnlockStage(stageId)
        btn = self.TabGroup[i]
        if btn then
            if btn.ButtonState == Disable and isUnLock then
                btn:SetDisable(false)
            elseif btn.ButtonState ~= Disable and not isUnLock then
                btn:SetDisable(true)
            end
        end
    end
end

function XUiLivWarmActivityPop:UpdatePhasesRewardGrid(isPlayPercentAnima)
    local stageId = self:GetStageId()
    local rewardProgressList = XLivWarmActivityConfigs.GetLivWarmActivityStageRewardProgress(stageId)
    local rewardIdList = XLivWarmActivityConfigs.GetLivWarmActivityStageRewardId(stageId)
    local dismisTotalProgres = self:GetDismisTotalProgress()
    local takeRewardProgressIndex = self.StageDb:GetTakeRewardProgressIndex()
    local activeProgressRectSize = self.RewardContent.rect.size
    local isReward = false
    self.MaxRewardProgress = rewardProgressList[#rewardProgressList]

    for i, rewardProgress in ipairs(rewardProgressList) do
        local grid = self.PhasesRewardGrids[i]
        if not grid then
            local obj = CSUnityEngineObjectInstantiate(self.RewardTmp, self.RewardContent)
            obj.gameObject:SetActiveEx(true)
            grid = XUiLivWarmActivityRewardGrid.New(self, obj, handler(self, self.ReceiveCallBack))
            self.PhasesRewardGrids[i] = grid
        end

        if not isReward and i > takeRewardProgressIndex and dismisTotalProgres >= rewardProgress then
            isReward = true
        end
        grid:SetData({StageId = stageId, RewardId = rewardIdList[i], RewardProgress = rewardProgress, RewardProgressIndex = i, IsReward = isReward})

        -- 自适应
        local rewardPercent = rewardProgress / self.MaxRewardProgress
        local adjustPosition = CS.UnityEngine.Vector3(activeProgressRectSize.x * rewardPercent, 44, 0)
        grid:SetRewardGridRectAnchoredPosition3D(adjustPosition)
    end

    for i, grid in ipairs(self.PhasesRewardGrids) do
        grid.GameObject:SetActiveEx(i <= #rewardIdList)
    end

    self:UpdatePanelPhasesReward(isPlayPercentAnima)
end

function XUiLivWarmActivityPop:UpdatePanelPhasesReward(isPlayAnima)
    self:StopRewardProgressTimer()

    for _, grid in ipairs(self.PhasesRewardGrids) do
        grid:Refresh()
    end

    local dismisTotalprogress = self:GetDismisTotalProgress()
    local percent = self.MaxRewardProgress ~= 0 and dismisTotalprogress / self.MaxRewardProgress or 0
    if not isPlayAnima then
        self.ImgProgress.fillAmount = percent
        return
    end

    local currFillAmount = self.ImgProgress.fillAmount
    local fillAmountDifference = percent - currFillAmount
    self.RewardProgressTimer = XUiHelper.Tween(1, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        self.ImgProgress.fillAmount = currFillAmount + f * fillAmountDifference
    end)
end

function XUiLivWarmActivityPop:StopRewardProgressTimer()
    if self.RewardProgressTimer then
        XScheduleManager.UnSchedule(self.RewardProgressTimer)
        self.RewardProgressTimer = nil
    end
end

function XUiLivWarmActivityPop:UpdateReminderLoseText()
    if self.StageDb:IsWin() then
        self.PanelReminder.gameObject:SetActiveEx(false)
        return
    end

    local _, curUseItemCount, maxItemCount = self:GetCurUseItemData()
    curUseItemCount = math.min(curUseItemCount, maxItemCount)
    self.ReminderLoseText.text = CSXTextManagerGetText("LivWarmActivityReminderLoseText", maxItemCount, curUseItemCount, maxItemCount)
    self.PanelReminder.gameObject:SetActiveEx(true)
end

function XUiLivWarmActivityPop:GetCurUseItemData()
    local stageId = self:GetStageId()
    local maxItemCount = XLivWarmActivityConfigs.GetLivWarmActivityStageMaxItemCount(stageId)
    local stageDb = XDataCenter.LivWarmActivityManager.GetStageDb(stageId)
    local curUseItemCount = stageDb:GetChangeCount()
    local isMaxItemUseCount = curUseItemCount >= maxItemCount
    return isMaxItemUseCount, curUseItemCount, maxItemCount
end

function XUiLivWarmActivityPop:UpdateGridTemplates()
    self:ClearCurSelectGrid()

    local isWin = self.StageDb:IsWin()
    local stageId = self:GetStageId()
    local gridData = XDataCenter.LivWarmActivityManager.GetGridData(stageId)
    for row, headTypeList in ipairs(gridData) do
        if not self.GridTemplates[row] then
            self.GridTemplates[row] = {}
        end

        for col, headType in ipairs(headTypeList) do
            local grid = self:GetGridTemplate(row, col)
            if not grid then
                local gridMine = CSUnityEngineObjectInstantiate(self.GridMine, self.PanelCase)
                gridMine.gameObject:SetActiveEx(true)
                grid = XUiLivWarmActivityPopGrid.New(gridMine, row, col, handler(self, self.ClickGrid))
                self.GridTemplates[row][col] = grid
            end

            if isWin then
                grid:Win()
            else
                grid:SetHeadType(headType, stageId)
            end
            grid:Reset()
        end
    end

    self.WinEffect.gameObject:SetActiveEx(isWin)
end

function XUiLivWarmActivityPop:StartActivityTimer()
    self:StopActivityTimer()
    if not XDataCenter.LivWarmActivityManager.CheckActivityIsOpen() then
        return
    end

    self:RefreshActivityTime()
    self.ActivityTimer = XScheduleManager.ScheduleForever(function() 
        if not XDataCenter.LivWarmActivityManager.CheckActivityIsOpen() then
            return
        end
        self:RefreshActivityTime()
    end, XScheduleManager.SECOND)
end

function XUiLivWarmActivityPop:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiLivWarmActivityPop:RefreshActivityTime()
    local timeId = XLivWarmActivityConfigs.GetLivWarmActivityTimeId()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local now = XTime.GetServerNowTimestamp()
    local offset = endTime - now
    if self.TxtTime then
        self.TxtTime.text = XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.ACTIVITY)
    end
end

function XUiLivWarmActivityPop:SetStageId(stageId)
    self.StageId = stageId
    self.StageDb = XDataCenter.LivWarmActivityManager.GetStageDb(stageId)
end

function XUiLivWarmActivityPop:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, HelpKey)
    self:RegisterClickEvent(self.PanelEntrance, self.OnPanelEntranceClick)
end

function XUiLivWarmActivityPop:OnClickTabCallBack(tabIndex)
    if self.CurSelectTabIndex == tabIndex then
        return
    end

    local stageId = self.StageIdList[tabIndex]
    if not XDataCenter.LivWarmActivityManager.IsUnlockStage(stageId) then
        local requireStageId = XLivWarmActivityConfigs.GetLivWarmActivityStageRequireStageId(stageId)
        local stageName = XLivWarmActivityConfigs.GetLivWarmActivityStageClientStageName(requireStageId)
        local tipDesc = CSXTextManagerGetText("LivWarmActivityStageLockTips", stageName)
        XUiManager.TipMsg(tipDesc)
        return
    end

    self:PlayAnimation("QieHuan")

    self.CurSelectTabIndex = tabIndex

    self:SetStageId(stageId)
    self:StopPlayMoveActionTimer()
    self:Refresh()
    self:UpdatePhasesRewardGrid()
end

--跳转至音频解谜
function XUiLivWarmActivityPop:OnPanelEntranceClick()
    local isPass,desc =  XDataCenter.LivWarmSoundsActivityManager.GetIsActCanOpen()
    if isPass then
        XLuaUiManager.Open("UiLivWarmSoundsActivity")
    else
        XUiManager.TipMsg(desc)
    end
end

function XUiLivWarmActivityPop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiLivWarmActivityPop:ClickGrid(grid)
    if self.PlayMoveActionTimer then
        grid:CanelSelectButton()
        return
    end

    local newHeadType = grid:GetHeadType()
    if not self.CurSelectGrid and (newHeadType == XLivWarmActivityConfigs.HeadType.NotClict or newHeadType == XLivWarmActivityConfigs.HeadType.Blank) then
        grid:CanelSelectButton()
        return
    end

    local stageId = self:GetStageId()
    local isFillUseMaxItemCount = XDataCenter.LivWarmActivityManager.IsFillUseMaxItemCount(stageId)
    if not isFillUseMaxItemCount and not XDataCenter.LivWarmActivityManager.IsItemFillCount() then
        XUiManager.TipText("LivWarmActivityItemNoEnough")
        grid:CanelSelectButton()
        self:UpdateLoseText()
        return
    end

    local newRow = grid:GetRow()
    local newColIndex = grid:GetColIndex()
    if self.CurSelectGrid then
        --前后两次选中的是同一个格子，取消选中
        local oldRow = self.CurSelectGrid:GetRow()
        local oldColIndex = self.CurSelectGrid:GetColIndex()
        if newRow == oldRow and newColIndex == oldColIndex then
            self:ClearCurSelectGrid()
            return
        end

        --新选择的格子没有和上一次选择的格子相邻
        if not self.CanSwapGrids[newRow] or not self.CanSwapGrids[newRow][newColIndex] then
            if newHeadType == XLivWarmActivityConfigs.HeadType.Blank or newHeadType == XLivWarmActivityConfigs.HeadType.NotClict then
                self:ClearCurSelectGrid()
            else
                self:SetCurSelectGrid(newRow, newColIndex, grid)
            end
            return
        end

        --新选择的格子和上一次选择的格子相邻且不可点击
        if newHeadType == XLivWarmActivityConfigs.HeadType.NotClict then
            return
        end

        --交换位置，检查是否消除，发给服务端
        self:CheckClearGridAndReq(newRow, oldRow, newColIndex, oldColIndex)
        return
    end

    self:SetCurSelectGrid(newRow, newColIndex, grid)
end

--播放选中的两个格子交换的动画
function XUiLivWarmActivityPop:StartPlayMoveActionTimer(stageId, newRow, oldRow, newColIndex, oldColIndex, clearGrids)
    if self:GetStageId() ~= stageId then
        return
    end

    local oldGrid = self:GetGridTemplate(oldRow, oldColIndex)
    local newGrid = self:GetGridTemplate(newRow, newColIndex)
    if not oldGrid or not newGrid then
        return
    end

    local oldGridBtn = oldGrid:GetBtnClickTransform()
    local newGridBtn = newGrid:GetBtnClickTransform()
    local oldGridPos = oldGridBtn.position
    local newGridPos = newGridBtn.position
    local direction = oldGridPos - newGridPos
    local isWin = self.StageDb:IsWin()

    self.PlayMoveActionTimer = XUiHelper.Tween(0.2, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        oldGridBtn.position = oldGridPos - f * direction
        newGridBtn.position = newGridPos + f * direction
    end, function()
        oldGrid:CanelSelectButton()
        newGrid:CanelSelectButton()

        local clearGridCount = 0
        for _, clearGrid in pairs(clearGrids) do
            for _ in pairs(clearGrid) do
                clearGridCount = clearGridCount + 1
            end
        end
        local totalClearGridCount = clearGridCount

        local playAnimaCb = function()
            clearGridCount = clearGridCount - 1
            if clearGridCount <= 0 then
                self:StopPlayMoveActionTimer()

                XDataCenter.LivWarmSoundsActivityManager.UpdateNewStage() --更新新关卡开启情况
                self:Refresh()
                self:UpdatePhasesRewardGrid(true)

                --没发生消除选中交换后的格子
                if totalClearGridCount == 0 then
                    local grid = self:GetGridTemplate(newRow, newColIndex)
                    self:SetCurSelectGrid(newRow, newColIndex, grid)
                end

                if isWin then
                    XUiManager.TipText("LivWarmActivityClearStage")
                    --self:PlayAnimation("WinEnable") 美术说不用播了
                end
            end
        end

        --动画播完后位置设置回去，然后设置交换后的头像，以及播放格子的消除动画
        local isPlayAnimaCb = false
        local oldHeadType = oldGrid:GetHeadType()
        local newHeadType = newGrid:GetHeadType()
        local stageId = self:GetStageId()
        oldGridBtn.position = oldGridPos
        newGridBtn.position = newGridPos
        oldGrid:SetHeadType(newHeadType, stageId)
        newGrid:SetHeadType(oldHeadType, stageId)
        for row, gridTemplates in ipairs(self.GridTemplates) do
            for col, gridTemplate in ipairs(gridTemplates) do
                if clearGrids[row] and clearGrids[row][col] then
                    isPlayAnimaCb = true
                    gridTemplate:PlayClearAnima(function()
                        gridTemplate:SetHeadType(XLivWarmActivityConfigs.HeadType.Blank, stageId)
                        playAnimaCb()
                    end)
                end
            end
        end

        if not isPlayAnimaCb then
            playAnimaCb()
        end
    end)
end

function XUiLivWarmActivityPop:StopPlayMoveActionTimer()
    if self.PlayMoveActionTimer then
        CS.XScheduleManager.UnSchedule(self.PlayMoveActionTimer)
        self.PlayMoveActionTimer = nil
    end
end

function XUiLivWarmActivityPop:SetCurSelectGrid(row, col, grid)
    if not grid then
        return
    end
    self:ClearCurSelectGrid()
    self:AddCanSwapGrid(row, col)
    grid:ClickButton()
    self.CurSelectGrid = grid
end

function XUiLivWarmActivityPop:ClearCurSelectGrid()
    if self.CurSelectGrid then
        self.CurSelectGrid:CanelSelectButton()
    end
    self.CurSelectGrid = nil
    self.CanSwapGrids = {}
end

--增加可以和当前选择的格子相邻的格子位置
function XUiLivWarmActivityPop:AddCanSwapGrid(curSelectGridRow, curSelectGridCol)
    --左上角为第一行第一列
    local upGridRow = curSelectGridRow - 1
    local downGridRow = curSelectGridRow + 1
    local leftGridCol = curSelectGridCol - 1
    local rightGridCol = curSelectGridCol + 1

    local gridTemplate = self:GetGridTemplate(upGridRow, curSelectGridCol)
    if gridTemplate then
        self:SetCanSwapGrids(upGridRow, curSelectGridCol)
    end

    gridTemplate = self:GetGridTemplate(downGridRow, curSelectGridCol)
    if gridTemplate then
        self:SetCanSwapGrids(downGridRow, curSelectGridCol)
    end

    gridTemplate = self:GetGridTemplate(curSelectGridRow, leftGridCol)
    if gridTemplate then
        self:SetCanSwapGrids(curSelectGridRow, leftGridCol)
    end

    gridTemplate = self:GetGridTemplate(curSelectGridRow, rightGridCol)
    if gridTemplate then
        self:SetCanSwapGrids(curSelectGridRow, rightGridCol)
    end
end

function XUiLivWarmActivityPop:SetCanSwapGrids(row, col)
    if not self.CanSwapGrids[row] then
        self.CanSwapGrids[row] = {}
    end
    self.CanSwapGrids[row][col] = true
end

function XUiLivWarmActivityPop:CheckClearGridAndReq(newRow, oldRow, newColIndex, oldColIndex)
    if (newRow == oldRow and newColIndex == oldColIndex) or (newRow ~= oldRow and newColIndex ~= oldColIndex) then
        return
    end

    local gridData = {}
    for row, gridTemplate in pairs(self.GridTemplates) do
        if not gridData[row] then
            gridData[row] = {}
        end
        for col, grid in pairs(gridTemplate) do
            gridData[row][col] = grid:GetHeadType()
        end
    end

    local clearGrids = {}           --确定要消除的格子的行列数据
    local waitClearGrids = {}       --缓存可能要消除的格子的行列数据
    local clearHeadTypes = {}       --消除的格子类型和数量
    local curWaitClearHeadType      --当前待消除的格子类型
    local gridTemp                  --当前行列的格子对象

    local oldHeadType = gridData[oldRow] and gridData[oldRow][oldColIndex]
    local newHeadType = gridData[newRow] and gridData[newRow][newColIndex]
    if not oldHeadType or not newHeadType then
        return
    end

    gridData[oldRow][oldColIndex] = newHeadType
    gridData[newRow][newColIndex] = oldHeadType

    local CheckSetClearGrids = function(clearHeadCount)
        if clearHeadCount >= CanClearHeadMinCount then
            for row, grids in pairs(waitClearGrids) do
                if not clearGrids[row] then
                    clearGrids[row] = {}
                end
                for col, headType in pairs(grids) do
                    clearGrids[row][col] = headType

                    if not clearHeadTypes[headType] then
                        clearHeadTypes[headType] = 0
                    end
                    clearHeadTypes[headType] = clearHeadTypes[headType] + 1
                end
            end
        end

        waitClearGrids = {}
    end

    local SetWaitClearGrids = function(row, col, headType)
        if not waitClearGrids[row] then
            waitClearGrids[row] = {}
        end
        waitClearGrids[row][col] = headType
    end

    local CheckSetWaitClearGrids = function(row, col, headType)
        return gridData[row] and gridData[row][col] == headType
    end

    --在同一行或同一列中，遍历相同类型且相邻的格子
    --isChangeRow：true的情况下遍历一列的格子；其他情况遍历一行的格子
    local Traverse = function(row, col, isChangeRow, headType)
        local isTraverseUpper = true        --是否继续往前遍历
        local isTraverseNext = true         --是否继续往后遍历
        local traverseCount = 0             --循环遍历次数
        local headCount = 1                 --相邻且相同类型的格子数量（包括自身）
        SetWaitClearGrids(row, col, headType)

        while isTraverseUpper or isTraverseNext do
            traverseCount = traverseCount + 1
            local upper = isChangeRow and row - traverseCount or col - traverseCount
            local next = isChangeRow and row + traverseCount or col + traverseCount
            local constant = isChangeRow and col or row

            if isChangeRow then
                if not gridData[upper] and not gridData[next] then
                    break
                end
            else
                if (not gridData[constant]) or (not gridData[constant][upper] and not gridData[constant][next]) then
                    break
                end
            end

            --往前遍历和当前格子类型相同的数量
            if isTraverseUpper then
                local rowTemp = isChangeRow and upper or constant
                local colTemp = isChangeRow and constant or upper
                if CheckSetWaitClearGrids(rowTemp, colTemp, headType) then
                    SetWaitClearGrids(rowTemp, colTemp, headType)
                    headCount = headCount + 1
                else
                    isTraverseUpper = false
                end
            end

            --往后遍历和当前格子类型相同的数量
            if isTraverseNext then
                local rowTemp = isChangeRow and next or constant
                local colTemp = isChangeRow and constant or next
                if CheckSetWaitClearGrids(rowTemp, colTemp, headType) then
                    SetWaitClearGrids(rowTemp, colTemp, headType)
                    headCount = headCount + 1
                else
                    isTraverseNext = false
                end
            end
        end
        CheckSetClearGrids(headCount)
    end

    if oldHeadType ~= XLivWarmActivityConfigs.HeadType.Blank and oldHeadType ~= XLivWarmActivityConfigs.HeadType.NotClict then
        Traverse(newRow, newColIndex, true, oldHeadType)       --遍历第二次选择的格子所在的列可消除的格子
        Traverse(newRow, newColIndex, false, oldHeadType)      --遍历第二次选择的格子所在的行可消除的格子
    end

    if newHeadType ~= XLivWarmActivityConfigs.HeadType.Blank and newHeadType ~= XLivWarmActivityConfigs.HeadType.NotClict then
        Traverse(oldRow, oldColIndex, true, newHeadType)       --遍历首次选择的格子所在的列可消除的格子
        Traverse(oldRow, oldColIndex, false, newHeadType)      --遍历首次选择的格子所在的行可消除的格子
    end

    --消除（如果有）并构建发给服务端的数据
    local dismisProgressCount = 0   --单次消除进度总和
    local stageId = self:GetStageId()

    local successCb = function()
        self:StartPlayMoveActionTimer(stageId, newRow, oldRow, newColIndex, oldColIndex, clearGrids)
    end
    
    for headType, dismisCount in pairs(clearHeadTypes) do
        dismisProgressCount = dismisProgressCount + math.ceil(dismisCount / CanClearHeadMinCount)   --同种颜色的头像一次性消除3个以上时，根据【消球数目/3】增加关卡进度，并且向上取整
    end

    for row, headTypes in pairs(gridData) do
        for col in pairs(headTypes) do
            if clearGrids[row] and clearGrids[row][col] then
                gridData[row][col] = XLivWarmActivityConfigs.HeadType.Blank
            end
        end
    end

    self:RequestLivWarmActivityChangeStage(gridData, dismisProgressCount, successCb)
end

function XUiLivWarmActivityPop:RequestLivWarmActivityChangeStage(gridData, dismisCount, successCb)
    self:ClearCurSelectGrid()
    local stageId = self:GetStageId()
    local dismisMaxCount = XLivWarmActivityConfigs.GetLivWarmActivityStageDismisMaxCount(stageId)
    local dismisTotalCount = self:GetDismisTotalProgress()
    local isWin = dismisTotalCount + dismisCount >= dismisMaxCount
    XDataCenter.LivWarmActivityManager.RequestLivWarmActivityChangeStage(stageId, dismisCount, isWin, gridData, successCb)
end

function XUiLivWarmActivityPop:ReceiveCallBack()
    local stageId = self:GetStageId()
    XDataCenter.LivWarmActivityManager.RequestLivWarmActivityTakeReward(stageId, function()
        self:UpdateRedPoint()
        self:UpdatePhasesRewardGrid()
    end)
end

function XUiLivWarmActivityPop:UpdateRedPoint()
    local btn
    local isShowReddot

    for i, stageId in ipairs(self.StageIdList) do
        btn = self.TabGroup[i]
        if btn then
            isShowReddot = XDataCenter.LivWarmActivityManager.CheckRewardRedPointByStageId(stageId)
            btn:ShowReddot(isShowReddot)
        end
    end
end

function XUiLivWarmActivityPop:GetStageId()
    return self.StageId
end

function XUiLivWarmActivityPop:GetDismisTotalProgress()
    local stageDb = self.StageDb
    return stageDb and stageDb:GetDismisCount()
end

function XUiLivWarmActivityPop:GetGridTemplate(row, col)
    return self.GridTemplates[row] and self.GridTemplates[row][col]
end

function XUiLivWarmActivityPop:RefreshPanelEntranceRedPoint()
    local result = XDataCenter.LivWarmSoundsActivityManager.CheckRedPoint()
    self.PanelEntrance:ShowReddot(result)
end