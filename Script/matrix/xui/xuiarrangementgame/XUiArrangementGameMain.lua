---@field _Control XArrangementGameControl
---@class XUiArrangementGameMain : XLuaUi
local XUiArrangementGameMain = XLuaUiManager.Register(XLuaUi, "UiArrangementGameMain")

function XUiArrangementGameMain:OnAwake()
    self:InitButton()
    self:InitUiShow()
end

function XUiArrangementGameMain:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnPrevious, self.OnBtnPreviousClick)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnBtnNextClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFinish, self.OnBtnFinishClick)
    self:BindHelpBtn(self.BtnHelp, "MusicGameActivityHelp")
end

-- 提前初始化好格子
function XUiArrangementGameMain:InitUiShow()
    self.GridObjA = self.GridOption:GetComponent(typeof(CS.UiObject))
    self.GridOption.transform:SetParent(self.PosA)
    local goB = XUiHelper.Instantiate(self.GridOption.gameObject, self.PosB)
    self.GridObjB = goB:GetComponent(typeof(CS.UiObject))
    
    local btnOptionA = self.GridObjA:GetObject("BtnOption")
    local btnOptionB = self.GridObjB:GetObject("BtnOption")
    XUiHelper.RegisterClickEvent(self, btnOptionA, self.OnBtnChooseA)
    XUiHelper.RegisterClickEvent(self, btnOptionB, self.OnBtnChooseB)
    self.BtnOptionA = btnOptionA
    self.BtnOptionB = btnOptionB

    local btnPlayA = self.GridObjA:GetObject("BtnPlay")
    local btnPlayB = self.GridObjB:GetObject("BtnPlay")
    XUiHelper.RegisterClickEvent(self, btnPlayA, self.OnBtnPlayA)
    XUiHelper.RegisterClickEvent(self, btnPlayB, self.OnBtnPlayB)
    self.BtnPlayA = btnPlayA
    self.BtnPlayB = btnPlayB

    self.GridObjA:GetObject("RImgIconA").gameObject:SetActive(true)
    self.GridObjA:GetObject("RImgIconB").gameObject:SetActive(false)
    self.GridObjB:GetObject("RImgIconA").gameObject:SetActive(false)
    self.GridObjB:GetObject("RImgIconB").gameObject:SetActive(true)
end

function XUiArrangementGameMain:OnStart(arrangementGameControlId, finishCb, arrangementUseItemCount)
    self.ArrangementGameControlId = arrangementGameControlId
    self.ArrangementUseItemCount = arrangementUseItemCount
    self.FinishCb = finishCb
    self.CurDepth = 1
    self:InitMapConfig()
    self:RefreshBtnState()
    self:RefreshSelectionInfo()

    self.BtnFinish:SetNameByGroup(1, arrangementUseItemCount or 0)
    self.BtnFinish:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.MusicGameArrangementItem))
end

function XUiArrangementGameMain:InitMapConfig()
    local allControlConfig = XMVCA.XArrangementGame:GetModelArrangementGameControl()[self.ArrangementGameControlId]
    local arrangementMusicIds = allControlConfig.MusicIds
    local allGameMusicConfig = XMVCA.XArrangementGame:GetModelArrangementGameMusic()
    -- 随便拿一个路线
    local tempArrangementMusicConfig = allGameMusicConfig[arrangementMusicIds[1]]
    local depth = #tempArrangementMusicConfig.Selections + 1 -- +1是根节点
    local rootNode = {SelectionId = 0, GameMusicId = 0}
    local depthList = {[1] = {rootNode}}
    for i = 2, depth, 1 do
        depthList[i] = {}
    end
    arrangementMusicIds = XTool.Clone(arrangementMusicIds)
    table.sort(arrangementMusicIds, function(a, b)
        return a < b
    end)
    -- 层序遍历二叉树的顺序列表
    for k, id in pairs(arrangementMusicIds) do
        local arrangementMusicConfig = allGameMusicConfig[id]
        for i = 2, depth, 1 do
            local targetTable = depthList[i]
            local targetInsertElement = arrangementMusicConfig.Selections[i - 1]
            if not table.containsKey(targetTable, "SelectionId", targetInsertElement) and #targetTable <= math.floor(2^(i-1)) then -- 二叉树每层最多2^(i-1)个节点
                table.insert(targetTable, {SelectionId = targetInsertElement, GameMusicId = id})
            end
        end
    end
    local orderInsertList = {}
    for i = 1, #depthList, 1 do
        appendArray(orderInsertList, depthList[i])
    end
    -- 组成二叉树数据
    local allSelectionConfigs = self._Control:GetModelArrangementGameSelection()
    self.BTree = XBTree.New()
    for i = 1, #orderInsertList, 1 do
        local selectionId = orderInsertList[i].SelectionId
        local selectionConfig = allSelectionConfigs[selectionId]
        self.BTree:LevelOrderInsert({SelectionConfig = selectionConfig, GameMusicId = orderInsertList[i].GameMusicId} or {Id = selectionId})
    end
    self.ResLevelOrderList = self.BTree:LevelOrder()
    self.CurShowNode = self.BTree.Root
end

-- 每次选择完按钮后刷新CurShowNode → 点击Next刷新选项信息
-- 点击Previous后设置CurShowNode为当前的父节点，然后刷新选项信息
function XUiArrangementGameMain:RefreshSelectionInfo()
    self.CurClickSelectNode = nil -- 这个变量拿来判断【下一步按钮激不激活】
    XLuaAudioManager.StopCurrentBGM() -- 停止当前BGM

    self.BtnPrevious.gameObject:SetActiveEx(self.CurShowNode.Depth > 1)
    self.BtnFinish.gameObject:SetActiveEx(self.CurShowNode.Depth == self.BTree:GetTreeDepth() - 1)
    self.BtnNext.gameObject:SetActiveEx(self.CurShowNode.Depth < self.BTree:GetTreeDepth() - 1)
    self.BtnPlayA:SetDisable(false) -- 每次点击上一步下一步将试听按钮的状态恢复
    self.BtnPlayB:SetDisable(false)

    local nodeA = self.CurShowNode.Left
    local nodeB = self.CurShowNode.Right

    self.GridObjA:GetObject("RImgIcon"):SetRawImage(nodeA.Data.SelectionConfig.Icon)
    self.GridObjB:GetObject("RImgIcon"):SetRawImage(nodeB.Data.SelectionConfig.Icon)

    self.GridObjA:GetObject("TxtDetail").text = nodeA.Data.SelectionConfig.Name
    self.GridObjB:GetObject("TxtDetail").text = nodeB.Data.SelectionConfig.Name

    local allGameMusicConfig = XMVCA.XArrangementGame:GetModelArrangementGameMusic()
    self.TxtDetail.text = XUiHelper.ConvertLineBreakSymbol(allGameMusicConfig[nodeA.Data.GameMusicId].MusicTexts[self.CurShowNode.Depth])

    self.CurNodeA = nodeA
    self.CurNodeB = nodeB
    -- 所有信息刷新完后再检查自动选择
    -- 自动选择(一般是回退上一步)
    local autoSelect = false
    local isA = true
    if self.CurShowNode.ExtraData then
        local lastSelectNode = self.CurShowNode.ExtraData
        if lastSelectNode == nodeA then
            isA = true
        elseif lastSelectNode == nodeB then
            isA = false
        end
        autoSelect = true
    end

    if autoSelect then
        if isA then
            self.BtnOptionA:SetButtonState(CS.UiButtonState.Select)
            self.BtnOptionB:SetButtonState(CS.UiButtonState.Normal)
            self:DoChoose(self.CurNodeA)
        else
            self.BtnOptionA:SetButtonState(CS.UiButtonState.Normal)
            self.BtnOptionB:SetButtonState(CS.UiButtonState.Select)
            self:DoChoose(self.CurNodeB)
        end
    else
        self.BtnOptionA:SetButtonState(CS.UiButtonState.Normal)
        self.BtnOptionB:SetButtonState(CS.UiButtonState.Normal)
    end

    self:RefreshBtnState()
end

function XUiArrangementGameMain:RefreshBtnState()
    self.BtnNext:SetDisable(not self.CurClickSelectNode)
    self.BtnFinish:SetDisable(not self.CurClickSelectNode)

    local isShow = false
    if self.CurClickSelectNode then
        local allPassArrangementMusicIds = XMVCA.XMusicGameActivity:GetPassArrangementMusicIds()
        local isInRes = table.contains(allPassArrangementMusicIds, self.CurClickSelectNode.Data.GameMusicId)
        if not isInRes then
            isShow = true
        end
    else
        isShow = false
    end
    self.BtnFinish:ShowTag(isShow)
end

function XUiArrangementGameMain:OnBtnPreviousClick()
    self.CurShowNode.ExtraData = nil
    self.CurShowNode = self.CurShowNode.Parent
    self:RefreshSelectionInfo()
end

function XUiArrangementGameMain:OnBtnNextClick()
    if not self.CurClickSelectNode then
        return
    end

    self.CurShowNode = self.CurClickSelectNode
    self:RefreshSelectionInfo()
end

function XUiArrangementGameMain:OnBtnFinishClick()
    if not self.CurClickSelectNode then
        return
    end

    if self.CurClickSelectNode.Depth ~= self.BTree:GetTreeDepth() then
        return
    end

    local resGameMusicId = self.CurClickSelectNode.Data.GameMusicId
    XLuaUiManager.PopThenOpen("UiArrangementGameStory", resGameMusicId, true)
    local allGameMusicConfig = XMVCA.XArrangementGame:GetModelArrangementGameMusic()
    local curConfig = allGameMusicConfig[resGameMusicId]
    if self.FinishCb then
        self.FinishCb(resGameMusicId, curConfig.Selections)
    end
end

-- 选择node一定会走着
function XUiArrangementGameMain:DoChoose(node)
    self.CurClickSelectNode = node
    -- 用ExtraData来保存当前展示节点最后点击选中的节点
    self.CurShowNode.ExtraData = node
end

function XUiArrangementGameMain:OnBtnChooseA()
    local isOn = self.BtnOptionA:GetToggleState()
    if isOn then
        self:DoChoose(self.CurNodeA)
    else
        self.CurShowNode.ExtraData = nil
        self.CurClickSelectNode = nil
    end

    self.BtnOptionB:SetButtonState(CS.UiButtonState.Normal)
    self:RefreshBtnState()
end

function XUiArrangementGameMain:OnBtnChooseB()
    local isOn = self.BtnOptionB:GetToggleState()
    if isOn then
        self:DoChoose(self.CurNodeB)
    else
        self.CurShowNode.ExtraData = nil
        self.CurClickSelectNode = nil
    end

    self.BtnOptionA:SetButtonState(CS.UiButtonState.Normal)
    self:RefreshBtnState()
end

function XUiArrangementGameMain:OnBtnPlayA()
    if self.BtnPlayA.ButtonState == CS.UiButtonState.Disable then
        return
    end

    if self.PlayALock then
        return
    end

    local finCb = function ()
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        self.BtnPlayA:SetDisable(false)
        self.PlayALock = false
    end
    self.CurMusicInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, self.CurNodeA.Data.SelectionConfig.TryCueId, true, finCb)
    self.BtnPlayA:SetDisable(true)
    self.BtnPlayB:SetDisable(false)
    self.PlayALock = true
end

function XUiArrangementGameMain:OnBtnPlayB()
    if self.BtnPlayB.ButtonState == CS.UiButtonState.Disable then
        return
    end

    if self.PlayBLock then
        return
    end

    local finCb = function ()
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        self.BtnPlayB:SetDisable(false)
        self.PlayBLock = false
    end
    self.CurMusicInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, self.CurNodeB.Data.SelectionConfig.TryCueId, true, finCb)
    self.BtnPlayB:SetDisable(true)
    self.BtnPlayA:SetDisable(false)
    self.PlayBLock = true
end

return XUiArrangementGameMain
