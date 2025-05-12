local DunhuangEnum = require("XModule/XDunhuang/Data/XDunhuangEnum")

---@class XDunhuangControl : XControl
---@field private _Model XDunhuangModel
local XDunhuangControl = XClass(XControl, "XDunhuangControl")
function XDunhuangControl:OnInit()
    self._UiData = {
        Time = "",
        PaintingProgress1 = "0/??",
        PaintingProgress2 = "0",
        PaintingNumberProgress = 0,
        ---@type XDunhuangPaintingData[]
        PaintingListUnlock = {},
        ---@type XDunhuangPaintingData[]
        PaintingListAll = {},
        PaintingSelected = {
            Id = 0,
            Icon = "",
            Name = "",
            Desc = "",
            IsShowUnlockButton = false,
            Price = 0,
            IsMoneyEnough = false,
        },
        ---@type XDunhuangPaintingDrawData
        PaintingEditingOnGame = false,

        ---@type XDunhuangPaintingDrawData[]
        PaintingToDraw = false,

        ---@type XDunhuangRewardData[]
        RewardList = {}
    }
    self._UiState = DunhuangEnum.UiState.None
    ---@type XDunhuangGame
    self._Game = false
    self._IsPaintingDirty = false
    ---@type XDunhuangPainting
    self._SelectedPaintingOnHangBook = false

    ---@type XDunhuangPainting
    self._SelectedPaintingOnGame = false

    self._UiFillBarProgress = {
        [0] = 0,
        [1] = 0.194,
        [2] = 0.362,
        [3] = 0.526,
        [4] = 0.694,
        [5] = 0.866,
    }
end

function XDunhuangControl:OnRelease()
    self._UiData = nil
end

--region ui
function XDunhuangControl:GetUiData()
    return self._UiData
end

function XDunhuangControl:UpdatePaintingUnlockProgress()
    local uiData = self._UiData
    local paintingAmount = self._Model:GetFinishPaintingAmount()
    local maxPaintingAmount = self._Model:GetMaxPaintingAmount()
    uiData.PaintingProgress1 = paintingAmount .. "/" .. maxPaintingAmount
    uiData.PaintingProgress2 = paintingAmount

    local configRewards = self._Model:GetConfigReward()
    local unlockAmount = self._Model:GetUnlockPaintingAmount()

    local index = 0
    for i = 1, #configRewards do
        local reward = configRewards[i]
        local paintingNum = reward.PaintingNum
        if unlockAmount >= paintingNum then
            index = i
        end
    end

    if index == #configRewards then
        uiData.PaintingNumberProgress = 1
    else
        -- 因为是非等长进度条
        local currentProgress = self._UiFillBarProgress[index]
        local nextProgress = self._UiFillBarProgress[index + 1]
        local currentReward = configRewards[index]
        local nextReward = configRewards[index + 1]
        local currentPaintingNum = currentReward and currentReward.PaintingNum or 0
        local diff = nextReward.PaintingNum - currentPaintingNum
        local remainder = unlockAmount - currentPaintingNum
        local diffProgress = remainder / diff
        diffProgress = XMath.Clamp(diffProgress, 0, 1)
        uiData.PaintingNumberProgress = (nextProgress - currentProgress) * diffProgress + currentProgress
    end
end

function XDunhuangControl:SetPaintingListSortEnableIfNewPaintingUnlock()
    self._UiData.PaintingListUnlock = nil
end

-- 如果有新的图片解锁，触发更新
function XDunhuangControl:IsPaintingListDirty()
    if not self._UiData.PaintingListUnlock then
        return true
    end
    local allPainting = self._Model:GetUnlockPainting()
    if #allPainting ~= #self._UiData.PaintingListUnlock then
        return true
    end
    return false
end

function XDunhuangControl:UpdatePaintingListUnlock()
    local uiData = self._UiData
    local oldData = uiData.PaintingListUnlock
    local oldIndex
    if oldData then
        oldIndex = {}
        for i = 1, #oldData do
            local oldPainting = oldData[i]
            oldIndex[oldPainting.Id] = i
        end
    end

    local allPainting = self._Model:GetUnlockPainting()
    local list = {}
    for i = 1, #allPainting do
        local paintingId = allPainting[i]
        local painting = self._Model:GetPainting(paintingId)
        local paintingData = self:GetPaintingData(painting)
        list[#list + 1] = paintingData
    end
    if oldIndex and #list == #oldData then
        table.sort(list, function(a, b)
            local oldIndex1 = oldIndex[a.Id] or a.Id
            local oldIndex2 = oldIndex[b.Id] or b.Id
            return oldIndex1 < oldIndex2
        end)
    else
        table.sort(list, function(a, b)
            if a.IsNew ~= b.IsNew then
                return a.IsNew
            end
            return a.Id < b.Id
        end)
    end
    uiData.PaintingListUnlock = list
end

function XDunhuangControl:UpdateTime(notKickOut)
    local remainTime = self._Model:GetActivityRemainTime()
    if remainTime < 0 then
        remainTime = 0
    end
    if remainTime == 0 then
        -- onEnable时不能触发关闭
        if notKickOut then
            return
        end
        XUiManager.TipText("ActivityAlreadyClose")
        self:CloseThisModule()
        return false
    end
    local text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.DAY_HOUR_2)
    self._UiData.Time = text
    return true
end

function XDunhuangControl:UpdateAllPainting(isFirstLoad)
    local allPainting = self._Model:GetAllPainting()
    local uiData = self._UiData
    local list = {}
    local oldData = uiData.PaintingListAll
    uiData.PaintingListAll = list
    for i = 1, #allPainting do
        local painting = allPainting[i]
        local paintingData = self:GetPaintingData(painting)
        paintingData.IsNew = false
        --paintingData.IsUsing = game:IsOnPaint(painting)
        list[#list + 1] = paintingData
    end

    if isFirstLoad then
        table.sort(list, function(a, b)
            if a.IsUnlock ~= b.IsUnlock then
                return a.IsUnlock
            end
            return a.Id < b.Id
        end)
    else
        local oldIndex = {}
        for i = 1, #oldData do
            local oldPainting = oldData[i]
            oldIndex[oldPainting.Id] = i
        end
        table.sort(list, function(a, b)
            local indexA = oldIndex[a.Id] or 0
            local indexB = oldIndex[b.Id] or 0
            if indexA ~= indexB then
                return indexA < indexB
            end

            if a.IsUnlock ~= b.IsUnlock then
                return a.IsUnlock
            end
            return a.Id < b.Id
        end)
    end
end

---@param painting XDunhuangPainting
function XDunhuangControl:GetPaintingData(painting)
    local game = self:_GetGame()
    local isUnlock = self._Model:IsHasPainting(painting)
    ---@class XDunhuangPaintingData
    local paintingData = {
        IsNew = isUnlock and painting:IsNewPainting(),
        IsUsing = game:IsOnPaint(painting),
        Icon = painting:GetIcon(),
        Name = painting:GetName(),
        Id = painting:GetId(),
        IsUnlock = isUnlock,
        IsAfford = (not isUnlock) and painting:IsAfford()
    }
    return paintingData
end

function XDunhuangControl:UpdateHangBookSelectedPainting()
    local uiData = self._UiData
    local selectedPainting = self._SelectedPaintingOnHangBook
    if not selectedPainting then
        local allPainting = self._Model:GetAllPainting()
        selectedPainting = allPainting[1]
        self._SelectedPaintingOnHangBook = selectedPainting
    end
    if not selectedPainting then
        XLog.Error("[XDunhuangControl] 选中图片存在问题")
        return
    end
    local isHasPainting = self._Model:IsHasPainting(selectedPainting)
    local paintingSelected = uiData.PaintingSelected
    paintingSelected.Id = selectedPainting:GetId()
    paintingSelected.Name = selectedPainting:GetName()
    paintingSelected.Icon = selectedPainting:GetIcon()
    paintingSelected.Desc = selectedPainting:GetDesc()
    paintingSelected.Price = selectedPainting:GetPrice()
    paintingSelected.IsMoneyEnough = selectedPainting:IsAfford()
    paintingSelected.IsShowUnlockButton = not isHasPainting
end

function XDunhuangControl:GetActivityTasks()
    return self._Model:GetActivityTasks()
end
--endregion ui

function XDunhuangControl:CloseThisModule()
    XLuaUiManager.SafeClose("UiDunhuangMain")
    XLuaUiManager.SafeClose("UiDunhuangTask")
    XLuaUiManager.SafeClose("UiDunhuangHandbook")
    XLuaUiManager.SafeClose("UiDunhuangEdit")
end

function XDunhuangControl:_GetGame()
    if not self._Game then
        local XDunhuangGame = require("XModule/XDunhuang/Data/XDunhuangGame")
        self._Game = XDunhuangGame.New()
        self:InitPaintingFromServerData()
    end
    return self._Game
end

function XDunhuangControl:ClearGame()
    self._Game = false
end

function XDunhuangControl:InitPaintingFromServerData()
    local paintings = {}
    local serverData = self._Model:GetPaintingsDraw()
    for i = 1, #serverData do
        local data = serverData[i]
        local painting = self._Model:GetPainting(data.Id)
        if painting then
            paintings[#paintings + 1] = painting
            -- todo
            data = XTool.Clone(data)
            data.Scale = data.Scale / 1000
            painting:SetDataFromSave(data)
        end
    end

    local game = self:_GetGame()
    game:SetPaintings(paintings)
end

function XDunhuangControl:GetUiState()
    return self._UiState
end

function XDunhuangControl:SetUiState(uiState)
    self._UiState = uiState
end

function XDunhuangControl:IsPaintingDirty()
    return self._IsPaintingDirty
end

---@param paintingData XDunhuangPaintingData
function XDunhuangControl:SetSelectedPaintingOnHangBook(paintingData)
    if not paintingData then
        XLog.Error("[XDunhuangControl] 选中了不存在的图片")
        return
    end
    local id = paintingData.Id
    local painting = self._Model:GetPainting(id)
    if not painting then
        XLog.Error("[XDunhuangControl] 选中了不存在的图片:", id)
        return
    end

    self._SelectedPaintingOnHangBook = painting
    XEventManager.DispatchEvent(XEventId.EVENT_DUNHUANG_SELECT_PAINTING)
end

function XDunhuangControl:SetSelectedPaintingOnGame(paintingData)
    if not paintingData then
        self._SelectedPaintingOnGame = false
        XEventManager.DispatchEvent(XEventId.EVENT_DUNHUANG_SELECT_PAINTING)
        return
    end
    local id = paintingData.Id
    local painting = self._Model:GetPainting(id)
    if not painting then
        XLog.Error("[XDunhuangControl] 选中了不存在的图片:", id)
        return
    end
    painting:SetPaintingNotNew()

    local game = self:_GetGame()
    if game:InsertPainting(painting) then
        self._IsPaintingDirty = true
    end
    self._SelectedPaintingOnGame = painting
    XEventManager.DispatchEvent(XEventId.EVENT_DUNHUANG_SELECT_PAINTING)
end

function XDunhuangControl:RequestUnlockPainting()
    XMVCA.XDunhuang:RequestUnlockPainting(self._SelectedPaintingOnHangBook)
end

function XDunhuangControl:RemovePaintingNewFlag()
    local allPainting = self._Model:GetAllPainting()
    for i = 1, #allPainting do
        local painting = allPainting[i]
        painting:SetPaintingNotNew()
    end
end

function XDunhuangControl:UpdateGameSelectedPainting()
    if self._SelectedPaintingOnGame then
        local painting = self._SelectedPaintingOnGame
        local uiData = self._UiData
        uiData.PaintingEditingOnGame = painting:GetDataToDraw()
    else
        local uiData = self._UiData
        uiData.PaintingEditingOnGame = false
    end
    --XEventManager.DispatchEvent(XEventId.EVENT_DUNHUANG_UPDATE_GAME)
end

function XDunhuangControl:UpdateDraw()
    local uiData = self._UiData
    local game = self:_GetGame()
    local paintingToDraw = {}
    uiData.PaintingToDraw = paintingToDraw

    ---@type XDunhuangPainting[]
    local paintings = game:GetPaintings()
    for i = 1, #paintings do
        local painting = paintings[i]
        local dataToDraw = painting:GetDataToDraw()
        paintingToDraw[i] = dataToDraw

        --if painting:Equals(self._SelectedPaintingOnGame) then
        --    dataToDraw.IsOnTop = true
        --end
    end
end

function XDunhuangControl:SetEditingPaintingPosition(offsetX, offsetY)
    local painting = self._SelectedPaintingOnGame
    if not painting then
        return
    end
    painting:SetPosOffset(offsetX, offsetY)
    self._IsPaintingDirty = true
end

function XDunhuangControl:RemoveEditingPainting()
    local game = self:_GetGame()
    game:RemovePainting(self._SelectedPaintingOnGame)
    self:SetSelectedPaintingOnGame(false)
    self._IsPaintingDirty = true
end

function XDunhuangControl:ClearGamePainting()
    local game = self:_GetGame()
    game:ClearPaintings()
    self:SetSelectedPaintingOnGame(false)
    self._IsPaintingDirty = true
end

function XDunhuangControl:AutoRequestSaveGame()
    if self._IsPaintingDirty then
        self:RequestSaveGame()
    end
end

function XDunhuangControl:RequestSaveGame()
    local game = self:_GetGame()
    local paintings = game:GetPaintings()
    XMVCA.XDunhuang:RequestSave(paintings)
    self:SetSelectedPaintingOnGame(false)
    self._IsPaintingDirty = false
end

function XDunhuangControl:OnClickFlipX()
    local painting = self._SelectedPaintingOnGame
    if not painting then
        return
    end
    painting:DoFlipX()
end

function XDunhuangControl:SetEditingPaintingOnScale()
    local painting = self._SelectedPaintingOnGame
    if not painting then
        return
    end
    painting:OnScaleBegin()
end

function XDunhuangControl:SetEditingPaintingScale(x, y)
    local painting = self._SelectedPaintingOnGame
    if not painting then
        return
    end
    painting:SetRotationOffset(Vector2(x, y))
    self._IsPaintingDirty = true
end

function XDunhuangControl:IsFirstShare()
    return self._Model:IsFirstShare()
end

function XDunhuangControl:SetNotFirstShare()
    XMVCA.XDunhuang:RequestShareReward()
end

function XDunhuangControl:UpdateReward()
    local list = {}
    local configRewards = self._Model:GetConfigReward()
    local unlockAmount = self._Model:GetUnlockPaintingAmount()
    for i = 1, #configRewards do
        local reward = configRewards[i]
        local rewardId = reward.RewardId
        local rewards = XRewardManager.GetRewardList(rewardId)
        ---@class XDunhuangRewardData
        local rewardData = {
            ItemData = rewards[1],
            IsOn = unlockAmount >= reward.PaintingNum,
            IsReceived = self._Model:IsRewardReceived(reward.Id),
            Id = reward.Id,
        }
        rewardData.TextNum = reward.PaintingNum
        list[#list + 1] = rewardData
    end

    local uiData = self._UiData
    uiData.RewardList = list
end

function XDunhuangControl:SetPaintingFrameSize(width, height)
    self._Model:SetPaintingFrameSize(width, height)
end

function XDunhuangControl:GetFirstShareReward()
    local reward = self._Model:GetFirstReward()
    return reward
end

function XDunhuangControl:ClearSelectedPainting()
    self:SetSelectedPaintingOnGame(false)
end

function XDunhuangControl:GetIsFirstTimeEnter()
    return self._Model:GetIsFirstTimeEnter()
end

function XDunhuangControl:SetIsFirstTimeEnter()
    local key = self._Model:GetFirstTimeEnterKey()
    XSaveTool.SaveData(key, 1)
end

function XDunhuangControl:IsTaskCanAchieved()
    return self._Model:IsTaskCanAchieved()
end

function XDunhuangControl:IsPaintingAfford()
    return self._Model:IsPaintingAfford()
end

return XDunhuangControl