local tableInsert = table.insert

local MAX_SELECTION_NUM = 3
local ROLE_NAME = "[ " .. CS.XTextManager.GetText("StoryReviewTip") .. " ]"

local LastSelectedId

local XMovieActionSelection = XClass(XMovieActionBase, "XMovieActionSelection")

function XMovieActionSelection:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    local replacePlayerName = XDataCenter.MovieManager.ReplacePlayerName

    self.DelaySelectKey = paramToNumber(params[1])

    local selectList = {}
    local selectParamsNum = MAX_SELECTION_NUM * 2 + 1
    for i = 2, selectParamsNum, 2 do
        if params[i] and params[i] ~= "" then
            local data = {}
            data.DialogContent = replacePlayerName(params[i])
            data.ActionId = paramToNumber(params[i + 1])
            tableInsert(selectList, data)
        end
    end
    self.OriginalSelectList = selectList
end

function XMovieActionSelection:IsBlock()
    return true
end

function XMovieActionSelection:CanContinue()
    return false
end

function XMovieActionSelection:GetSelectedActionId()
    return self.SelectedActionId or 0
end

function XMovieActionSelection:GetBeginAnim()
    return self.BeginAnim or "SelectEnable"
end

function XMovieActionSelection:OnUiRootInit()
    self.TabGroupList = {
        self.UiRoot.BtnSelect1,
        self.UiRoot.BtnSelect2,
        self.UiRoot.BtnSelect3,
    }
end

function XMovieActionSelection:OnUiRootDestroy()
    LastSelectedId = nil
    self.RepeatClick = nil
    self.TabGroupList = {}
end

function XMovieActionSelection:OnInit()
    self.UiRoot.TabBtnSelectGroup:Init(self.TabGroupList, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    self.UiRoot.PanelSelectableDialog.gameObject:SetActiveEx(true)

    self.SelectedActionId = 0

    --成环时隐藏掉导致成环的分支
    self.SelectList = {}
    for _, data in pairs(self.OriginalSelectList) do
        if data.ActionId ~= LastSelectedId then
            tableInsert(self.SelectList, data)
        end
    end

    if not next(self.SelectList) then
        XLog.Error("XMovieActionSelection:OnRunning error:SelectList is empty, actionId is: " .. self.ActionId)
        return
    end

    local dataNum = #self.SelectList
    for i = 1, dataNum do
        local btn = self.TabGroupList[i]
        local data = self.SelectList[i]
        btn:SetName(data.DialogContent)
        btn.gameObject:SetActiveEx(true)
    end

    for i = dataNum + 1, MAX_SELECTION_NUM do
        self.TabGroupList[i].gameObject:SetActiveEx(false)
    end
end

function XMovieActionSelection:OnRunning()
    self.RepeatClick = nil--进入动画播放完毕后按钮恢复可点击状态
end

function XMovieActionSelection:OnDestroy()
    self.RepeatClick = nil
    self.UiRoot.PanelSelectableDialog.gameObject:SetActiveEx(false)
end

function XMovieActionSelection:OnClickTabCallBack(tabIndex)
    if self.RepeatClick then return end
    self.RepeatClick = true

    local selectedData = self.SelectList[tabIndex]
    local delaySelectKey = self.DelaySelectKey
    local actionId = selectedData.ActionId
    if delaySelectKey == 0 then
        self.SelectedActionId = actionId
    else
        XDataCenter.MovieManager.DelaySelectAction(delaySelectKey, actionId)
    end

    LastSelectedId = self.SelectedActionId
    XDataCenter.MovieManager.PushInReviewDialogList(ROLE_NAME, selectedData.DialogContent)
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
end

function XMovieActionSelection:OnUndo()
    XDataCenter.MovieManager.RemoveFromReviewDialogList()
    LastSelectedId = nil
end

return XMovieActionSelection