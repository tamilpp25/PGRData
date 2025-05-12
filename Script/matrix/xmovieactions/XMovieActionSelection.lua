---@class XMovieActionSelection
---@field UiRoot XUiMovie
local XMovieActionSelection = XClass(XMovieActionBase, "XMovieActionSelection")

function XMovieActionSelection:Ctor(actionData)
    self.MAX_SELECTION_NUM = 3
    self.DEFAULT_SELECTION_TYPE = 1

    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    local replacePlayerName = XDataCenter.MovieManager.ReplacePlayerName

    self.DelaySelectKey = paramToNumber(params[1])
    self.IsLeft = params[11] == "1" -- 是否使用左边的UI显示，默认是用右边的UI显示

    -- 参数下标
    local contentIndexList = {2, 4, 6}      -- 选项内容
    local actionIdIndexList = {3, 5, 7}     -- 跳转ActionId
    local btnTypeIndexList = {8, 9, 10}     -- 按钮预设体
    local settingIndexList = {12, 13, 14}   -- 已阅读和存在前置未完成 表现

    local selectList = {}
    for i = 1, self.MAX_SELECTION_NUM do
        local contentIndex = contentIndexList[i]
        local idIndex = actionIdIndexList[i]
        local btnTypeIndex = btnTypeIndexList[i]
        local settingIndex = settingIndexList[i]

        local content = params[contentIndex]
        if content and content ~= "" then
            local data = {}
            data.Index = i
            data.DialogContent = replacePlayerName(content)
            data.ActionId = paramToNumber(params[idIndex])
            data.BtnType = params[btnTypeIndex]
            data.Setting = params[settingIndex]
            table.insert(selectList, data)
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
    self.RepeatClick = nil
end

function XMovieActionSelection:OnInit()
    --成环时隐藏掉导致成环的分支
    self.SelectList = {}
    for _, data in pairs(self.OriginalSelectList) do
        if data.ActionId ~= self.UiRoot.LastSelectedId then
            table.insert(self.SelectList, data)
        end
    end

    if not next(self.SelectList) then
        XLog.Error("XMovieActionSelection:OnRunning error:SelectList is empty, actionId is: " .. self.ActionId)
        return
    end

    -- 隐藏所有按钮，后面扩展新的按钮类型也不需要加代码
    local panel = self.IsLeft and self.UiRoot.PanelSelectLeft or self.UiRoot.PanelSelectRight
    panel.gameObject:SetActiveEx(true)
    local btnGroup = panel:GetObject("TabBtnSelectGroup").transform
    local childCount = btnGroup.childCount
    for i = 1, childCount do
        local childTran = btnGroup:GetChild(i-1)
        childTran.gameObject:SetActiveEx(false)
    end

    -- 初始化
    local name = self.IsLeft and "LeftSelectBtnDic" or "RightSelectBtnDic"
    local btnDic = self.UiRoot[name]
    if not btnDic then
        btnDic = {}
        self.UiRoot[name] = btnDic
    end

    -- 创建对应类型的按钮列表
    local btnList = {}
    local btnIndexDic = {}
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    local CSUiButtonState = CS.UiButtonState
    for _, selectData in ipairs(self.SelectList) do
        local btnType = selectData.BtnType or self.DEFAULT_SELECTION_TYPE -- 不填使用默认按钮

        -- 初始化对应btnType的按钮列表
        local btnGoList = btnDic[btnType]
        if not btnGoList then
            local btnSelect = panel:GetObject("BtnSelect"..btnType)
            btnGoList = { btnSelect }
            btnDic[btnType] = btnGoList
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
        local uiObj = btnGo:GetComponent("UiObject")
        local content = XMVCA.XMovie:ExtractGenderContent(selectData.DialogContent)
        content = XUiHelper.ReplaceTextNewLine(content)
        uiButton:SetButtonState(CSUiButtonState.Normal) -- XUiRichTextCustomRender组件需要显示出来再刷新文本，不然会显示空文本/出现乱码
        uiObj:GetObject("TxtNormal").text = content
        uiButton:SetButtonState(CSUiButtonState.Press)
        uiObj:GetObject("TxtPress").text = content
        uiButton:SetButtonState(CSUiButtonState.Disable)
        uiObj:GetObject("TxtDisable").text = content

        -- 未解锁
        local isLock = self:IsSelectionLock(selectData)
        uiButton:SetDisable(isLock)
        -- 已读
        local isReaded = self:IsSelectionReaded(selectData)
        local normalReadedLink = uiObj:GetObject("NormalReadedLink")
        if normalReadedLink then
            normalReadedLink.gameObject:SetActiveEx(isReaded)
        end
        local pressReadedLink = uiObj:GetObject("PressReadedLink")
        if pressReadedLink then
            pressReadedLink.gameObject:SetActiveEx(isReaded)
        end

        table.insert(btnList, uiButton)
    end
    
    panel:GetObject("TabBtnSelectGroup"):Init(btnList, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    self.UiRoot:SetBtnNextCallback(function() end)
    CS.XUiManagerExtension.ManualStop("UiMovie")
    self.SelectedActionId = 0
end

function XMovieActionSelection:OnRunning()
    self.RepeatClick = nil--进入动画播放完毕后按钮恢复可点击状态
end

function XMovieActionSelection:OnDestroy()
    self.UiRoot:RemoveBtnNextCallback()
    CS.XUiManagerExtension.ManualResume("UiMovie")
    self.RepeatClick = nil
    self.UiRoot.PanelSelectLeft.gameObject:SetActiveEx(false)
    self.UiRoot.PanelSelectRight.gameObject:SetActiveEx(false)
end

function XMovieActionSelection:OnClickTabCallBack(tabIndex)
    local selectData = self.SelectList[tabIndex]
    local isLock = self:IsSelectionLock(selectData)
    if isLock then return end
    
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

    self.UiRoot.LastSelectedId = self.SelectedActionId
    local ROLE_NAME = "[ " .. CS.XTextManager.GetText("StoryReviewTip") .. " ]"
    local content = XMVCA.XMovie:ExtractGenderContent(selectedData.DialogContent)
    XDataCenter.MovieManager.PushInReviewDialogList(ROLE_NAME, content)

    -- 自动播放情况下，在出现选项前一刻按下暂停键，会导致选择项按钮失效，界面无法操作
    local isMoviePause = XDataCenter.MovieManager.IsMoviePause()
    if isMoviePause then
        self.UiRoot:OnClickBtnPause()
    end
    -- 请求记录当前选项已选择
    local movieId = XDataCenter.MovieManager.GetCurPlayingMovieId()
    XMVCA.XMovie:RequestRecordOption(movieId, self.ActionId, tabIndex)

    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
end

function XMovieActionSelection:OnUndo()
    XDataCenter.MovieManager.RemoveFromReviewDialogList()
    self.UiRoot.LastSelectedId = nil
end

-- 选项是否阅读过
function XMovieActionSelection:IsSelectionReaded(selData)
    if selData.Setting == nil then
        return false
    end

    local movieId = XDataCenter.MovieManager.GetCurPlayingMovieId()
    return XMVCA.XMovie:IsOptionPassed(movieId, self.ActionId, selData.Index)
end

-- 选项是否上锁
function XMovieActionSelection:IsSelectionLock(selData)
    if selData.Setting == nil or selData.Setting == "" or selData.Setting == "-1" then
        return false
    end

    local movieId = XDataCenter.MovieManager.GetCurPlayingMovieId()
    local results = XMVCA.XMovie:SplitParam(selData.Setting, "|", true)
    local actionId = results[1]
    local optionIndex = results[2]
    local isPrePassed = XMVCA.XMovie:IsOptionPassed(movieId, actionId, optionIndex)
    return not isPrePassed
end

return XMovieActionSelection