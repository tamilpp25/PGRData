local tableInsert = table.insert
local MAX_SELECTION_NUM = 3
local DEFAULT_SELECTION_TYPE = 1
local ROLE_NAME = "[ " .. CS.XTextManager.GetText("StoryReviewTip") .. " ]"
local LastSelectedId

local CSInstantiate = CS.UnityEngine.Object.Instantiate

local XMovieActionSelection = XClass(XMovieActionBase, "XMovieActionSelection")

function XMovieActionSelection:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    local replacePlayerName = XDataCenter.MovieManager.ReplacePlayerName

    self.DelaySelectKey = paramToNumber(params[1])

    -- 下标
    local contentIndexList = {2, 4, 6}
    local actionIdIndexList = {3, 5, 7}
    local btnTypeIndexList = {8, 9, 10}

    local selectList = {}
    for i = 1, MAX_SELECTION_NUM do
        local contentIndex = contentIndexList[i]
        local idIndex = actionIdIndexList[i]
        local btnTypeIndex = btnTypeIndexList[i]

        local content = params[contentIndex]
        if content and content ~= "" then
            local data = {}
            data.DialogContent = replacePlayerName(content)
            data.ActionId = paramToNumber(params[idIndex])
            data.BtnType = params[btnTypeIndex]
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

function XMovieActionSelection:OnUiRootDestroy()
    LastSelectedId = nil
    self.RepeatClick = nil
end

function XMovieActionSelection:OnInit()
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

    -- 隐藏所有按钮，后面扩展新的按钮类型也不需要加代码
    local childCount = self.UiRoot.TabBtnSelectGroup.transform.childCount
    for i = 1, childCount do
        local childTran = self.UiRoot.TabBtnSelectGroup.transform:GetChild(i-1)
        childTran.gameObject:SetActiveEx(false)
    end

    -- 初始化
    if not self.UiRoot.TypeSelectBtnDic then
        self.UiRoot.TypeSelectBtnDic = {}
    end

    -- 创建对应类型的按钮列表
    local btnList = {}
    local btnIndexDic = {}
    for _, selectData in ipairs(self.SelectList) do
        local btnType = selectData.BtnType or DEFAULT_SELECTION_TYPE -- 不填使用默认按钮

        -- 初始化对应btnType的按钮列表
        local btnGoList = self.UiRoot.TypeSelectBtnDic[btnType]
        if not btnGoList then
            local btnSelect = self.UiRoot["BtnSelect"..btnType]
            btnGoList = { btnSelect }
            self.UiRoot.TypeSelectBtnDic[btnType] = btnGoList
        end

        -- 获取/创建按钮实例
        local index = (btnIndexDic[btnType] or 0) + 1
        btnIndexDic[btnType] = index
        local btnGo = btnGoList[index]
        if not btnGo then
            local cloneGo = btnGoList[1].gameObject
            btnGo = CSInstantiate(cloneGo.gameObject, cloneGo.transform.parent)
            table.insert(btnGoList, btnGo)
        end

        btnGo.gameObject:SetActiveEx(true)
        btnGo.transform:SetAsLastSibling()
        local uiButton = btnGo:GetComponent("XUiButton")
        uiButton:SetName(selectData.DialogContent)
        table.insert(btnList, uiButton)
    end

    self.UiRoot.TabBtnSelectGroup:Init(btnList, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    self.UiRoot.PanelSelectableDialog.gameObject:SetActiveEx(true)
    CS.XUiManagerExtension.ManualStop("UiMovie")
    self.SelectedActionId = 0
end

function XMovieActionSelection:OnRunning()
    self.RepeatClick = nil--进入动画播放完毕后按钮恢复可点击状态
end

function XMovieActionSelection:OnDestroy()
    CS.XUiManagerExtension.ManualResume("UiMovie")
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

    -- 自动播放情况下，在出现选项前一刻按下暂停键，会导致选择项按钮失效，界面无法操作
    local isMoviePause = XDataCenter.MovieManager.IsMoviePause()
    if isMoviePause then
        self.UiRoot:OnClickBtnPause()
    end
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
end

function XMovieActionSelection:OnUndo()
    XDataCenter.MovieManager.RemoveFromReviewDialogList()
    LastSelectedId = nil
end

return XMovieActionSelection