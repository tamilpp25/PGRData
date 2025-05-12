local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local tableInsert = table.insert
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiFubenActivityPuzzleGamePanel = XClass(nil, "XUiFubenActivityPuzzleGamePanel")
local XUiFubenActivityPuzzlePieceItem = require("XUi/XUiFubenActivityPuzzle/XUiFubenActivityPuzzlePieceItem")

local Empty_Index = -1

function XUiFubenActivityPuzzleGamePanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiFubenActivityPuzzleGamePanel:Init()
    self.LongClicks = {}
    self:AutoRegisterListener()
    self:InitBlock()
    self.Camera = CS.XUiManager.Instance.UiCamera
    self.LongClicks[Empty_Index] = XUiButtonLongClick.New(self.PuzzleChipPointer, 5, self, nil, function () self:OnPuzzleChipDrag(Empty_Index) end, function () self:OnPuzzleChipUp() end, false)
    local DragItemRectTransform = self.PuzzleChipDragItem.transform:GetComponent("RectTransform")
    self.PieceMoveLimitX = (self.RectTransform.rect.width - DragItemRectTransform.rect.width)/2
    self.PieceMoveLimitY = (self.RectTransform.rect.height - DragItemRectTransform.rect.height)/2 

    self.RedPointId = XRedPointManager.AddRedPointEvent(self.BtnSwitch, self.OnCheckSwitchRedPoint, self, { XRedPointConditions.Types.CONDITION_DRAG_PUZZLE_GAME_SWITCH }, nil, true)
    self.RedPointVideoId = XRedPointManager.AddRedPointEvent(self.PlayVideoBtn, self.OnCheckVideoRedPoint, self, { XRedPointConditions.Types.CONDITION_DRAG_PUZZLE_GAME_VIDEO }, nil, false)
end

function XUiFubenActivityPuzzleGamePanel:OnCheckSwitchRedPoint(count)
    if count < 0 then
        self.BtnSwitch:ShowReddot(false)
        return
    end

    self.BtnSwitch:ShowReddot(self.PuzzleId and XDataCenter.FubenActivityPuzzleManager.CheckHasSwitchRedPointById(self.PuzzleId))
end

function XUiFubenActivityPuzzleGamePanel:OnCheckVideoRedPoint(count)
    self.PlayVideoBtn:ShowReddot(count >= 0)
end

function XUiFubenActivityPuzzleGamePanel:AutoRegisterListener()
    self.BtnSwitch.CallBack = function () self:OnClickBtnSwitch() end
    self.GetBtn.CallBack = function () self:OnClickBtnGetAll() end
    self.PlayVideoBtn.CallBack = function () self:OnClickBtnPlayVideo() end
end

function XUiFubenActivityPuzzleGamePanel:InitBlock()
    self.PuzzleBlocks = {}
    for i=1, 15, 1 do
        self["PuzzleBlock"..i] = XUiFubenActivityPuzzlePieceItem.New(self.RootUi, self["PuzzleImgLocation"..i])
        tableInsert(self.PuzzleBlocks, self["PuzzleBlock"..i])
    end

    for index, block in ipairs(self.PuzzleBlocks) do
        local pointer = self.PuzzleBlocks[index].Transform:GetComponent("XUiPointer")
        self.LongClicks[index] = XUiButtonLongClick.New(pointer, 5, self, nil, function () self:OnPuzzleChipDrag(index) end, function () self:OnPuzzleChipUp(true) end, false)
    end
end

function XUiFubenActivityPuzzleGamePanel:RefreshPanel(puzzleId)
    self.PuzzleId = puzzleId
    self.BtnSwitch:ShowReddot(self.PuzzleId and XDataCenter.FubenActivityPuzzleManager.CheckHasSwitchRedPointById(self.PuzzleId)) -- 刷新转化碎片按钮红点
    self:RefreshChipPanel(puzzleId)
    self:RefreshPuzzlePanel(puzzleId)
    self.SwitchEffect.gameObject:SetActive(false) -- 隐藏特效
    self.PuzzleCompleteEffect.gameObject:SetActive(false)
    XRedPointManager.Check(self.RedPointVideoId, puzzleId) -- 检查剧情红点
end

function XUiFubenActivityPuzzleGamePanel:RefreshChipPanel(puzzleId, isOnDrag)
    local puzzleTemplate = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(puzzleId)
    local pieceTable = XDataCenter.FubenActivityPuzzleManager.GetPieceTabelById(puzzleId)
    self.TxtPieceConsume.text = puzzleTemplate.PieceItemCount
    if not pieceTable or #pieceTable <= 0 then
        self.PuzzleChipImg.gameObject:SetActiveEx(false)
        self.TxtPieceNum.text = "0"
    elseif isOnDrag then
        if #pieceTable > 1 then
            local pieceIcon = XFubenActivityPuzzleConfigs.GetPieceIconById(pieceTable[#pieceTable-1].Id)
            self.PuzzleChipImg.gameObject:SetActiveEx(true)
            self.PuzzleChipImg:SetRawImage(pieceIcon)
            self.TxtPieceNum.text = #pieceTable-1
        else
            self.PuzzleChipImg.gameObject:SetActiveEx(false)
            self.TxtPieceNum.text = "0"
        end
    else
        local pieceIcon = XFubenActivityPuzzleConfigs.GetPieceIconById(pieceTable[#pieceTable].Id)
        self.PuzzleChipImg.gameObject:SetActiveEx(true)
        self.PuzzleChipImg:SetRawImage(pieceIcon)
        self.TxtPieceNum.text = #pieceTable
    end
end

function XUiFubenActivityPuzzleGamePanel:RefreshPuzzlePanel(puzzleId, targetIndex)

    local puzzleState = XDataCenter.FubenActivityPuzzleManager.GetPuzzleStateById(puzzleId)
    if puzzleState == XFubenActivityPuzzleConfigs.PuzzleState.Incomplete then
        self:SetInComplete(targetIndex)
    elseif puzzleState == XFubenActivityPuzzleConfigs.PuzzleState.Complete then
        self:SetComplete()
    elseif puzzleState == XFubenActivityPuzzleConfigs.PuzzleState.PuzzleCompleteButNotDecryption then
        self:SetDecryption()
    end
end

function XUiFubenActivityPuzzleGamePanel:OnClickBtnSwitch()
    XDataCenter.FubenActivityPuzzleManager.ExchangePiece(self.PuzzleId)
end

function XUiFubenActivityPuzzleGamePanel:OnClickBtnGetAll()
    XDataCenter.FubenActivityPuzzleManager.GetReward(self.PuzzleId, 0)
end

function XUiFubenActivityPuzzleGamePanel:OnClickBtnPlayVideo()
    local puzzleTemplate = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(self.PuzzleId)
    local movieId = puzzleTemplate.CompleteStoryId
    XDataCenter.MovieManager.PlayMovie(movieId)
    XSaveTool.SaveData(string.format("%s%s%s", XPlayer.Id, XFubenActivityPuzzleConfigs.PLAY_VIDEO_STATE_KEY ,self.PuzzleId), XFubenActivityPuzzleConfigs.PlayVideoState.Played)
    XEventManager.DispatchEvent(XEventId.EVENT_DRAG_PUZZLE_GAME_PLAYED_VIDEO, self.PuzzleId)
end

function XUiFubenActivityPuzzleGamePanel:SetInComplete(targetIndex)
    local puzzleTemplate = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(self.PuzzleId)
    local allCount = puzzleTemplate.RowSize * puzzleTemplate.ColSize
    local pieceTable = XDataCenter.FubenActivityPuzzleManager.GetPuzzlePieceTabelById(self.PuzzleId)
    self.PuzzleContent.gameObject:SetActiveEx(true)
    self.BtnSwitch:SetDisable(false, true)
    self.ArrowImg.gameObject:SetActiveEx(true)
    self.PuzzleImgBig.gameObject:SetActiveEx(false)
    self.PuzzleImgBigPassword.gameObject:SetActiveEx(false)
    self.GetBtn.gameObject:SetActiveEx(false)
    self.PlayVideoBtn.gameObject:SetActiveEx(false)
    if not pieceTable or XTool.GetTableCount(pieceTable) <= 0 then
        self.TxtPuzzleProgress.text = CSXTextManagerGetText("DragPuzzleActivityPuzzleProgress", 0, allCount)
        for _, block in pairs(self.PuzzleBlocks) do
            block:SetActive(false)
        end
    else
        self.TxtPuzzleProgress.text = CSXTextManagerGetText("DragPuzzleActivityPuzzleProgress", XDataCenter.FubenActivityPuzzleManager.GetPuzzlePieceSuccessCount(self.PuzzleId), allCount)
        for index, block in ipairs(self.PuzzleBlocks) do
            if pieceTable[index] then
                block:SetActive(true)
                block:HideCorrectAndMistakeEffect()
                local pieceIcon = XFubenActivityPuzzleConfigs.GetPieceIconById(pieceTable[index])
                block:SetRawImage(pieceIcon)
                local isCorrect = XDataCenter.FubenActivityPuzzleManager.CheckPieceIsCorrect(self.PuzzleId, index)
                block:SetCorrect(isCorrect)
                if targetIndex and targetIndex == index then
                    if isCorrect then block:ShowCorrectEffect() else block:ShowMistakeEffect() end
                end
            else
                block:SetActive(false)
            end
        end
    end
end

function XUiFubenActivityPuzzleGamePanel:SetComplete()
    local puzzleTemplate = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(self.PuzzleId)
    local allCount = puzzleTemplate.RowSize * puzzleTemplate.ColSize
    self.PuzzleImgBig:SetRawImage(puzzleTemplate.CompleteImageUrl)
    self.PuzzleContent.gameObject:SetActiveEx(false)
    self.BtnSwitch:SetDisable(true, false)
    self.ArrowImg.gameObject:SetActiveEx(false)
    self.PuzzleImgBig.gameObject:SetActiveEx(true)
    self.PuzzleImgBigPassword.gameObject:SetActiveEx(false)
    local gotCompleteRewardState = XDataCenter.FubenActivityPuzzleManager.CheckCompleteRewardIsGot(self.PuzzleId)
    local isGotCompleteReward = gotCompleteRewardState == XFubenActivityPuzzleConfigs.CompleteRewardState.Rewarded
    self.GetBtn.gameObject:SetActiveEx(not isGotCompleteReward)
    if puzzleTemplate.CompleteStoryId and puzzleTemplate.CompleteStoryId ~= "" then
        self.PlayVideoBtn.gameObject:SetActiveEx(isGotCompleteReward)
    else
        self.PlayVideoBtn.gameObject:SetActiveEx(false)
    end
    self.TxtPuzzleProgress.text = CSXTextManagerGetText("DragPuzzleActivityPuzzleProgress", XDataCenter.FubenActivityPuzzleManager.GetPuzzlePieceSuccessCount(self.PuzzleId), allCount)
end

function XUiFubenActivityPuzzleGamePanel:SetDecryption()
    local puzzleTemplate = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(self.PuzzleId)
    local allCount = puzzleTemplate.RowSize * puzzleTemplate.ColSize
    local decryptionImg = XFubenActivityPuzzleConfigs.GetPuzzleDecryptionImgUrl(self.PuzzleId)
    self.PuzzleContent.gameObject:SetActiveEx(false)
    self.BtnSwitch:SetDisable(true, false)
    self.ArrowImg.gameObject:SetActiveEx(false)
    self.PuzzleImgBigPassword.gameObject:SetActiveEx(true)
    self.PuzzleImgBig.gameObject:SetActiveEx(false)
    self.GetBtn.gameObject:SetActiveEx(false)
    self.PlayVideoBtn.gameObject:SetActiveEx(false)
    if decryptionImg and decryptionImg ~= "" then
        self.PuzzleImgBigPassword:SetRawImage(decryptionImg)
    end
    self.TxtPuzzleProgress.text = CSXTextManagerGetText("DragPuzzleActivityPuzzleProgress", XDataCenter.FubenActivityPuzzleManager.GetPuzzlePieceSuccessCount(self.PuzzleId), allCount)
end

function XUiFubenActivityPuzzleGamePanel:OnPuzzleChipDrag(index) -- 拖拽
    if self.LastClickIndex and self.LastClickIndex ~= index then
        self.LongClicks[self.LastClickIndex]:Reset()
        self:RefreshPanel(self.PuzzleId)
        self.LastClickIndex = nil
    end

    if not self.DragItem then -- 第一次进入拖拽 没有拖拽的碎片
        if index == Empty_Index then
            local hasValue, piece = XDataCenter.FubenActivityPuzzleManager.GetFirstPiece(self.PuzzleId)
            if hasValue then
                -- 读取所需数据
                self.PuzzlePieceTable = XDataCenter.FubenActivityPuzzleManager.GetPuzzlePieceTabelById(self.PuzzleId)
                self.NearestIndex = nil
                self:RefreshChipPanel(self.PuzzleId, true)-- 更新碎片列表UI
                self.DragItem = self.PuzzleChipDragItem
                self.DragItem.gameObject:SetActiveEx(true)
                self.DragItem:SetRawImage(XFubenActivityPuzzleConfigs.GetPieceIconById(piece.Id))
                -- 更新位置到鼠标位置
                self.DragItem.gameObject.transform.localPosition = self:GetPisont()
            end
        else
            local pieceId = XDataCenter.FubenActivityPuzzleManager.GetPuzzlePieceByIndex(self.PuzzleId, index)
            if pieceId then
                if not XDataCenter.FubenActivityPuzzleManager.CheckPieceIsCorrect(self.PuzzleId, index) then
                    self.CurDragPieceId = pieceId
                    self.CurDragPieceIdx = index
                    self.PuzzlePieceTable = XDataCenter.FubenActivityPuzzleManager.GetPuzzlePieceTabelById(self.PuzzleId)
                    self.NearestIndex = nil
                    self.PuzzleBlocks[index]:SetActive(false) -- 隐藏该格子碎片
                    self.DragItem = self.PuzzleChipDragItem
                    self.DragItem.gameObject:SetActiveEx(true)
                    self.DragItem:SetRawImage(XFubenActivityPuzzleConfigs.GetPieceIconById(pieceId))
                    self.DragItem.gameObject.transform.localPosition = self:GetPisont()
                end
            end
        end
        self.LastClickIndex = index

    else -- 持续更新拖拽的碎片位置
        self.DragItem.gameObject.transform.localPosition = self:GetPisont()
        local nearestIndex = 0
        if index == Empty_Index then
            nearestIndex = self:CalculateNearestBlockIndex()
        else
            nearestIndex = self:CalculateNearestBlockIndex(true)
        end
        if not self.NearestIndex then
            self.NearestIndex = nearestIndex
            self.PuzzleBlocks[nearestIndex]:SetLight(true)
        else
            if self.NearestIndex ~= nearestIndex then
                self.PuzzleBlocks[self.NearestIndex]:SetLight(false)
                self.NearestIndex = nearestIndex
                self.PuzzleBlocks[nearestIndex]:SetLight(true)
            end
        end
    end
end

function XUiFubenActivityPuzzleGamePanel:OnPuzzleChipUp(isChangePiece) -- 抬起
    if not self.NearestIndex then -- 点击抬起过快可能导致NearestIndex为空
        self:RefreshChipPanel(self.PuzzleId)
        self:RefreshPuzzlePanel(self.PuzzleId)
        if self.DragItem then
            self.DragItem.gameObject:SetActiveEx(false)
            self.DragItem = nil
            self.LastClickIndex = nil
        end
        return
    end
    if self.DragItem then
        self.DragItem.gameObject:SetActiveEx(false)
        self.DragItem = nil
        self.LastClickIndex = nil
        self.PuzzleBlocks[self.NearestIndex]:SetLight(false)
        if isChangePiece then
            XDataCenter.FubenActivityPuzzleManager.MovePieceFormPuzzle(self.PuzzleId, self.CurDragPieceId, self.CurDragPieceIdx,self.NearestIndex)
            self.CurDragPieceId = nil
            self.CurDragPieceIdx = nil
        else
            XDataCenter.FubenActivityPuzzleManager.MovePieceFormPieceTable(self.PuzzleId, self.NearestIndex)
        end
        self.NearestIndex = nil
    end
end

function XUiFubenActivityPuzzleGamePanel:GetPisont()
    local screenPoint
    if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor or CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer then
        screenPoint = CS.UnityEngine.Vector2(CS.UnityEngine.Input.mousePosition.x, CS.UnityEngine.Input.mousePosition.y)
    else
        screenPoint = CS.UnityEngine.Input.GetTouch(0).position
    end

    -- 设置拖拽
    local hasValue, v2 = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.RectTransform, screenPoint, self.Camera)
    if hasValue then
        local x = v2.x
        local y = v2.y
        if x < -self.PieceMoveLimitX then x = -self.PieceMoveLimitX elseif x > self.PieceMoveLimitX then x = self.PieceMoveLimitX end
        if y < -self.PieceMoveLimitY then y = -self.PieceMoveLimitY elseif y > self.PieceMoveLimitY then y = self.PieceMoveLimitY end
        return CS.UnityEngine.Vector3(x, y, 0)
    else
        return CS.UnityEngine.Vector3.zero
    end
end

function XUiFubenActivityPuzzleGamePanel:CalculateNearestBlockIndex(isCorrect)
    local nearestIndex = 0
    local nearestDistance = 0
    for index, block in ipairs(self.PuzzleBlocks) do
        if not self.PuzzlePieceTable[index] or (isCorrect and not XDataCenter.FubenActivityPuzzleManager.CheckPieceIsCorrect(self.PuzzleId, index)) then
            local x1 = self.DragItem.gameObject.transform.position.x
            local y1 = self.DragItem.gameObject.transform.position.y
            local x2 = self.PuzzleBlocks[index].Transform.position.x
            local y2 = self.PuzzleBlocks[index].Transform.position.y
            local distance = (y2-y1)^2 + (x2-x1)^2
            if nearestDistance == 0 then
                nearestIndex = index
                nearestDistance = distance
            else
                if distance < nearestDistance then
                    nearestIndex = index
                    nearestDistance = distance
                end
            end
        end
    end

    return nearestIndex
end

function XUiFubenActivityPuzzleGamePanel:ShowAwardAreaByList(areaIndexList)
    for _, index in pairs(areaIndexList) do
        if self.PuzzleBlocks[index] then
            self.PuzzleBlocks[index]:ShowAwardEffect(true)
        end
    end
end

function XUiFubenActivityPuzzleGamePanel:HideAllAwardArea()
    for _, block in pairs(self.PuzzleBlocks) do
        block:ShowAwardEffect(false)
    end
end

function XUiFubenActivityPuzzleGamePanel:ShowSwitchPieceEffect()
    self.SwitchEffect.gameObject:SetActive(false)
    self.SwitchEffect.gameObject:SetActive(true)
end

function XUiFubenActivityPuzzleGamePanel:ShowPuzzleCompleteEffect()
    self.PuzzleCompleteEffect.gameObject:SetActive(false)
    self.PuzzleCompleteEffect.gameObject:SetActive(true)
end

function XUiFubenActivityPuzzleGamePanel:OnRelease()
    XRedPointManager.RemoveRedPointEvent(self.RedPointId)
    XRedPointManager.RemoveRedPointEvent(self.RedPointVideoId)
end

return XUiFubenActivityPuzzleGamePanel