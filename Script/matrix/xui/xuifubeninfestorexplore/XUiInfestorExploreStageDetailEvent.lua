local next = next
local stringGsub = string.gsub

local MAX_OPTION_NUM = 3

local XUiInfestorExploreStageDetailEvent = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreStageDetailEvent")

function XUiInfestorExploreStageDetailEvent:OnAwake()
    self:AutoAddListener()
end

function XUiInfestorExploreStageDetailEvent:OnStart(closeCb)
    self.CloseCb = closeCb
end

function XUiInfestorExploreStageDetailEvent:OnDisable()
    self.CloseCb()
end

function XUiInfestorExploreStageDetailEvent:Refresh(chapterId, nodeId)
    self.ChapterId = chapterId
    self.NodeId = nodeId

    local poolId = XDataCenter.FubenInfestorExploreManager.GetNodeEventPoolId(chapterId, nodeId)

    self.TxtName.text = XFubenInfestorExploreConfigs.GetEventPoolName(poolId)
    self.TxtDes.text = XFubenInfestorExploreConfigs.GetEventPoolDes(poolId)

    local bg = XDataCenter.FubenInfestorExploreManager.GetNodeStageBg(chapterId, nodeId)
    self.RImgIcon:SetRawImage(bg)

    if XDataCenter.FubenInfestorExploreManager.IsNodeSelectEvent(chapterId, nodeId) then
        for i = 1, MAX_OPTION_NUM do
            local btn = self["BtnOption" .. i]
            local desList = XFubenInfestorExploreConfigs.GetEventPoolMultiOptionDesList(poolId, i)
            if next(desList) then
                local des
                for _, desStr in pairs(desList) do
                    des = des and des .. desStr or desStr
                end
                des = stringGsub(des, "\\n", "\n")
                btn:SetNameByGroup(0, des)
                btn.gameObject:SetActiveEx(true)
            else
                btn.gameObject:SetActiveEx(false)
            end
        end
        self.PanelOptionList.gameObject:SetActiveEx(false)
        self.BtnConfirm.gameObject:SetActiveEx(false)
        self.PanelOption.gameObject:SetActiveEx(true)
    elseif XDataCenter.FubenInfestorExploreManager.IsNodeAutoEvent(chapterId, nodeId) then
        for i = 1, MAX_OPTION_NUM do
            local txt = self["TxtOption" .. i]
            local desList = XFubenInfestorExploreConfigs.GetEventPoolMultiOptionDesList(poolId, i)
            if next(desList) then
                local des
                for _, desStr in pairs(desList) do
                    des = des and des .. ", " .. desStr or desStr
                end
                txt.text = des
                txt.gameObject:SetActiveEx(true)
            else
                txt.gameObject:SetActiveEx(false)
            end
        end

        local btnName = XFubenInfestorExploreConfigs.GetEventPoolBtnName(poolId)
        self.BtnConfirm:SetNameByGroup(0, btnName)

        self.PanelOption.gameObject:SetActiveEx(false)
        self.BtnConfirm.gameObject:SetActiveEx(true)
        self.PanelOptionList.gameObject:SetActiveEx(true)
    end
end

function XUiInfestorExploreStageDetailEvent:AutoAddListener()
    self.BtnCloseMask.CallBack = function() self:Close() end
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
    self.BtnGuestbook.CallBack = function() self:OnClickBtnGuestbook() end
    for index = 1, MAX_OPTION_NUM do
        self["BtnOption" .. index].CallBack = function() self:OnSelectOption(index) end
    end
end

function XUiInfestorExploreStageDetailEvent:OnClickBtnConfirm()
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    if XDataCenter.FubenInfestorExploreManager.IsNodePassed(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreEventNodePassed")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreEventNodeNotReach")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeCurrentFinished(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreEventNodeCurrent")
        return
    end

    if not XDataCenter.FubenInfestorExploreManager.CheckActionPoint(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreActionPointNotEnough")
        return
    end

    local callBack = function()
        self:Close()
    end
    XDataCenter.FubenInfestorExploreManager.RequestInfestorExploreAutoEvent(nodeId, callBack)
end

function XUiInfestorExploreStageDetailEvent:OnSelectOption(index)
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    if XDataCenter.FubenInfestorExploreManager.IsNodePassed(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreEventNodePassed")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreEventNodeNotReach")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeCurrentFinished(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreEventNodeCurrent")
        return
    end

    if not XDataCenter.FubenInfestorExploreManager.CheckActionPoint(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreActionPointNotEnough")
        return
    end

    local poolId = XDataCenter.FubenInfestorExploreManager.GetNodeEventPoolId(chapterId, nodeId)
    local eventIds = XFubenInfestorExploreConfigs.GetEventPoolMultiOptionEventIds(poolId, index)
    local callBack = function()
        self:Close()
    end
    XDataCenter.FubenInfestorExploreManager.RequestInfestorExploreSelectEvent(nodeId, eventIds, callBack)
end

function XUiInfestorExploreStageDetailEvent:OnClickBtnGuestbook()
    XDataCenter.FubenInfestorExploreManager.OpenGuestBook(self.ChapterId)
end