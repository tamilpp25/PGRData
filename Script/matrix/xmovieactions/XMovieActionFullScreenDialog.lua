local pairs = pairs
local XUiGridSingleDialog = require("XUi/XUiMovie/XUiGridSingleDialog")
local DefaultColor = CS.UnityEngine.Color.white
local PlayingCvInfo
local stringUtf8Len = string.Utf8Len

local XMovieActionFullScreenDialog = XClass(XMovieActionBase, "XMovieActionFullScreenDialog")

function XMovieActionFullScreenDialog:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local dialogContent = XDataCenter.MovieManager.ReplacePlayerName(params[1])
    if not dialogContent or dialogContent == "" then
        XLog.Error("XMovieActionFullScreenDialog:Ctor error:DialogContent is empty, actionId is: " .. self.ActionId)
        return
    end
    self.DialogContent = dialogContent
    self.Color = params[2]
    self.Duration = paramToNumber(params[3])
    self.BgPath = params[4]
    self.CvId = paramToNumber(params[5])
    self.IsCanSkip = paramToNumber(params[6]) ~= 0
    self.ChangeLinePlus = paramToNumber(params[7])
    self.IsReset = paramToNumber(params[8]) ~= 0
    self.IsClose = paramToNumber(params[9]) ~= 0
    self.IsCenter = paramToNumber(params[10]) ~= 0
end

function XMovieActionFullScreenDialog:GetEndDelay()
    return self.IsAutoPlay and XMovieConfigs.AutoPlayDelay + stringUtf8Len(self.DialogContent) * XMovieConfigs.PerWordDelay or 0
end

function XMovieActionFullScreenDialog:IsBlock()
    return true
end

function XMovieActionFullScreenDialog:CanContinue()
    return not self.IsTyping
end

function XMovieActionFullScreenDialog:OnUiRootDestroy()
    self:StopLastCv()
end

function XMovieActionFullScreenDialog:OnInit()
    self.IsAutoPlay = XDataCenter.MovieManager.IsAutoPlay()
    self.UiRoot:SetBtnNextCallback(function() self:OnClickBtnSkipDialog() end)
    self.UiRoot.PanelFullScreenDialog.gameObject:SetActiveEx(true)
    self.UiRoot.GridSingleDialog.gameObject:SetActiveEx(false)

    local bgPath = self.BgPath
    if bgPath then
        self.UiRoot.RImgBgFullScreenDialog:SetRawImage(bgPath)
    end

    -- 在对话前创建空行
    if self.ChangeLinePlus < 0 then
        self:CreateEmptyGrid(math.abs(self.ChangeLinePlus))
    end

    local dialogContent = XMVCA.XMovie:ExtractGenderContent(self.DialogContent)
    local grid = self:GetDialogGridFromPool()
    grid:Refresh(dialogContent, self.IsCenter, self.Color, self.Duration, function()
        self:OnTypeWriterComplete()
    end)
    grid.GameObject:SetActiveEx(true)
    self.IsTyping = true

    -- 在对话后创建空行
    if self.ChangeLinePlus > 0 then
        self:CreateEmptyGrid(self.ChangeLinePlus)
    end

    local imgNext = self.UiRoot.ImgNext
    imgNext.transform:SetParent(grid.Transform, false)
    imgNext.gameObject:SetActiveEx(false)

    local iconNext = self.UiRoot.IconNext
    local color = self.Color and self.Color or DefaultColor
    iconNext.color = XUiHelper.Hexcolor2Color(color)

    local cvId = self.CvId
    if cvId ~= 0 then
        self:StopLastCv()
        PlayingCvInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, cvId)
    end

    local dialogName = ""
    XDataCenter.MovieManager.PushInReviewDialogList(dialogName, dialogContent)
end

function XMovieActionFullScreenDialog:OnDestroy()
    self.IsTyping = nil
    self.Skipped = nil
    self.IsAutoPlay = nil
    self:ClearDelayId() -- 清理定时器

    if self.IsReset then
        self:ClearAllDialogGrids()
    end

    if self.IsClose then
        self:ClearAllDialogGrids()
        self.UiRoot.PanelFullScreenDialog.gameObject:SetActiveEx(false)
    end
    self.UiRoot:RemoveBtnNextCallback()
end

function XMovieActionFullScreenDialog:OnClickBtnSkipDialog()
    if self.IsTyping then
        if not self.IsCanSkip then return end

        self.IsTyping = false
        self.Skipped = true

        local grid = self:GetCurDialogGrid()
        grid:StopTypeWriter()
        self.UiRoot.ImgNext.gameObject:SetActiveEx(true)
    else
        self.Skipped = true

        self:OnTypeWriterComplete()
    end
end

function XMovieActionFullScreenDialog:OnTypeWriterComplete()
    self.IsTyping = false
    self.UiRoot.ImgNext.gameObject:SetActiveEx(true)

    if self.IsAutoPlay or self.Skipped then
        self.Skipped = nil
        local ignoreLock = self.IsAutoPlay
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, ignoreLock)
    end
end

function XMovieActionFullScreenDialog:OnSwitchAutoPlay(autoPlay)
    self.IsAutoPlay = autoPlay
    self:ClearDelayId() -- 清理定时器
    if autoPlay and self.IsTyping == false then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
    end
end

function XMovieActionFullScreenDialog:GetDialogGridFromPool(isEmptyGrid)
    local gridList = self.UiRoot.FullScreenDialogGrids
    local curIndex = self.UiRoot.FullScreenDialogUsingIndex

    self.CurIndex = not isEmptyGrid and curIndex or self.CurIndex
    local grid = gridList[curIndex]
    if not grid then
        local obj = CS.UnityEngine.Object.Instantiate(self.UiRoot.GridSingleDialog, self.UiRoot.PanleContents)
        grid = XUiGridSingleDialog.New(obj)
        gridList[curIndex] = grid
    end
    grid.TypeWriter.gameObject:SetActiveEx(not isEmptyGrid)
    self.UiRoot.FullScreenDialogUsingIndex = curIndex + 1
    return grid
end

function XMovieActionFullScreenDialog:GetCurDialogGrid()
    local gridList = self.UiRoot.FullScreenDialogGrids
    local curIndex = self.CurIndex
    return gridList[curIndex]
end

function XMovieActionFullScreenDialog:ClearAllDialogGrids()
    self.UiRoot.FullScreenDialogUsingIndex = 1
    self.CurIndex = nil

    local gridList = self.UiRoot.FullScreenDialogGrids
    for _, grid in pairs(gridList) do
        grid:Reset()
        grid.GameObject:SetActiveEx(false)
    end
end

function XMovieActionFullScreenDialog:StopLastCv()
    if PlayingCvInfo then
        if PlayingCvInfo.Playing then
            PlayingCvInfo:Stop()
        end
        PlayingCvInfo = nil
    end
end

function XMovieActionFullScreenDialog:OnUndo()
    XDataCenter.MovieManager.RemoveFromReviewDialogList()
end

-- 创建空行
function XMovieActionFullScreenDialog:CreateEmptyGrid(num)
    for i = 1, num do
        local tmpGrid = self:GetDialogGridFromPool(true)
        local tmpDialogContent = " "
        tmpGrid:Refresh(tmpDialogContent)
        tmpGrid.GameObject:SetActiveEx(true)
    end
end

return XMovieActionFullScreenDialog