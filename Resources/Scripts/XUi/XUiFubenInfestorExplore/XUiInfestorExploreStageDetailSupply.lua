local MAX_OPTION_NUM = 3
local EVENT_NAME_STR = CS.XTextManager.GetText("InfestorExploreSupplyNodeName")
local EVENT_DES_STR = CS.XTextManager.GetText("InfestorExploreSupplyNodeDes")

local XUiInfestorExploreStageDetailSupply = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreStageDetailSupply")

function XUiInfestorExploreStageDetailSupply:OnAwake()
    self:AutoAddListener()
end

function XUiInfestorExploreStageDetailSupply:OnStart(closeCb)
    self.CloseCb = closeCb
end

function XUiInfestorExploreStageDetailSupply:Refresh(chapterId, nodeId)
    self.NodeId = nodeId
    self.ChapterId = chapterId

    self.TxtName.text = EVENT_NAME_STR
    self.TxtDes.text = EVENT_DES_STR

    local bg = XDataCenter.FubenInfestorExploreManager.GetNodeStageBg(chapterId, nodeId)
    self.RImgIcon:SetRawImage(bg)

    local desList = XDataCenter.FubenInfestorExploreManager.GetSupplyNodeDesList(chapterId, nodeId)
    for i = 1, MAX_OPTION_NUM do
        local btn = self["BtnOption" .. i]
        local des = desList[i]
        btn:SetNameByGroup(0, des)
        btn.gameObject:SetActiveEx(true)
    end
end

function XUiInfestorExploreStageDetailSupply:OnDisable()
    self.CloseCb()
end

function XUiInfestorExploreStageDetailSupply:AutoAddListener()
    self.BtnCloseMask.CallBack = function() self:Close() end
    self.BtnGuestbook.CallBack = function() self:OnClickBtnGuestbook() end
    for index = 1, MAX_OPTION_NUM do
        self["BtnOption" .. index].CallBack = function() self:OnSelectOption(index) end
    end
end

function XUiInfestorExploreStageDetailSupply:OnSelectOption(index)
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    if XDataCenter.FubenInfestorExploreManager.IsNodePassed(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreSupplyNodePassed")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreSupplyNodeNotReach")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeCurrentFinished(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreSupplyNodeCurrent")
        return
    end

    if not XDataCenter.FubenInfestorExploreManager.CheckActionPoint(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreActionPointNotEnough")
        return
    end

    local callBack = function()
        self:Close()
    end
    XDataCenter.FubenInfestorExploreManager.RequestSupply(chapterId, nodeId, callBack)
end

function XUiInfestorExploreStageDetailSupply:OnClickBtnGuestbook()
    XDataCenter.FubenInfestorExploreManager.OpenGuestBook(self.ChapterId)
end