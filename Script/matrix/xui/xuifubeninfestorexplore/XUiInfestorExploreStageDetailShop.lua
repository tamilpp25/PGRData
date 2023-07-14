local CSXTextManagerGetText = CS.XTextManager.GetText
local EVENT_NAME_STR = CSXTextManagerGetText("InfestorExploreShopNodeName")
local EVENT_DES_STR = CSXTextManagerGetText("InfestorExploreShopNodeDes")

local XUiInfestorExploreStageDetailShop = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreStageDetailShop")

function XUiInfestorExploreStageDetailShop:OnAwake()
    self:AutoAddListener()
    self.BtnLeave.gameObject:SetActiveEx(false)
end

function XUiInfestorExploreStageDetailShop:OnStart(closeCb)
    self.CloseCb = closeCb
end

function XUiInfestorExploreStageDetailShop:OnDisable()
    self.CloseCb()
end

function XUiInfestorExploreStageDetailShop:Refresh(chapterId, nodeId)
    self.ChapterId = chapterId
    self.NodeId = nodeId

    self.TxtName.text = EVENT_NAME_STR
    self.TxtDes.text = EVENT_DES_STR

    local bg = XDataCenter.FubenInfestorExploreManager.GetNodeStageBg(chapterId, nodeId)
    self.RImgIcon:SetRawImage(bg)
end

function XUiInfestorExploreStageDetailShop:AutoAddListener()
    self.BtnCloseMask.CallBack = function() self:Close() end
    self.BtnGuestbook.CallBack = function() self:OnClickBtnGuestbook() end
    self.BtnEnter.CallBack = function() self:OnClickBtnEnter() end
end

function XUiInfestorExploreStageDetailShop:OnClickBtnEnter()
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    if XDataCenter.FubenInfestorExploreManager.IsNodePassed(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreShopNodePassed")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeCurrentFinished(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreShopNodeCurrentFinshed")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreShopNodeNotReach")
        return
    end

    if not XDataCenter.FubenInfestorExploreManager.CheckActionPoint(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreActionPointNotEnough")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.CheckShopExist() then
        XLuaUiManager.Open("UiInfestorExploreShop")
    else
        local callBack = function()
            XLuaUiManager.Open("UiInfestorExploreShop")
        end
        XDataCenter.FubenInfestorExploreManager.RequestShopInfo(nodeId, callBack)
    end

    self:Close()
end

function XUiInfestorExploreStageDetailShop:OnClickBtnGuestbook()
    XDataCenter.FubenInfestorExploreManager.OpenGuestBook(self.ChapterId)
end