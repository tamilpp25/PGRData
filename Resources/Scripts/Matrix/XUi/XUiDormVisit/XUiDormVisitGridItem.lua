local XUiDormVisitGridItem = XClass(nil, "XUiDormVisitGridItem")
local TextManager = CS.XTextManager

function XUiDormVisitGridItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.OnBtnClickcb = function() self:OnBtnClick() end
    self.OnEnterDormcb = function() self:EnterDormVisitor() end
    self.TextOnline = TextManager.GetText("DormOnline")
    self.TextOffline = TextManager.GetText("DormOffline")
    XTool.InitUiObject(self)
end

function XUiDormVisitGridItem:OnBtnClick()
    if self.BtnVisit.ButtonState == CS.UiButtonState.Disable then
        return
    end
    
    if self.ItemData.DormitoryId == 0 then
        return
    end

    local charId = XDataCenter.DormManager.GetVisitorDormitoryCharacterId()
    XDataCenter.DormManager.RequestDormitoryVisit(self.ItemData.PlayerId, self.ItemData.DormitoryId, charId, self.OnEnterDormcb)
end

function XUiDormVisitGridItem:EnterDormVisitor()
    if XLuaUiManager.IsUiShow("UiDormVisit") then
        XLuaUiManager.Close("UiDormVisit")
    end
    local displaytype = XDormConfig.VisitDisplaySetType.MyFriend
    if self.UiRoot.CuTabType == XDormConfig.VisitTabTypeCfg.Visitor then
        displaytype = XDormConfig.VisitDisplaySetType.Stranger
    end

    if self.HostelSecond then
        self.HostelSecond.GameObject:SetActive(true)
        self.HostelSecond:OnRecordSelfDormId()
        XDataCenter.DormManager.VisitDormitory(displaytype, self.ItemData.DormitoryId)
        self.HostelSecond:UpdateData(displaytype, self.ItemData.DormitoryId, self.ItemData.PlayerId)
    else
        XLuaUiManager.Open("UiDormSecond", displaytype, self.ItemData.DormitoryId, self.ItemData.PlayerId)
        XDataCenter.DormManager.VisitDormitory(displaytype, self.ItemData.DormitoryId)
    end
end

function XUiDormVisitGridItem:Init(uiRoot)
    self.UiRoot = uiRoot
    self.HostelSecond = uiRoot.HostelSecond
    self.UiRoot:RegisterClickEvent(self.BtnVisit, self.OnBtnClickcb)
    self.BtnView.CallBack = function() self:OnBtnViewClick() end
end

function XUiDormVisitGridItem:GetMaxScore(atts)
    local score = 0
    local index = 1
    for i, v in pairs(atts) do
        if v > score then
            index = i
            score = v
        end
    end

    return index, score
end

-- 更新数据
function XUiDormVisitGridItem:OnRefresh(itemData)
    if not itemData then
        return
    end

    self.ItemData = itemData
    local dormitoryName = itemData.DormitoryName

    if dormitoryName ~= "" then
        if self.UiRoot.CuTabType == XDormConfig.VisitTabTypeCfg.MyFriend then
            local name = XDataCenter.SocialManager.GetPlayerRemark(itemData.PlayerId, itemData.PlayerName)
            self.TxtName.text = TextManager.GetText("DormVisitNameStyle", name, dormitoryName)
        else
            self.TxtName.text = TextManager.GetText("DormVisitNameStyle", itemData.PlayerName, dormitoryName)
        end
        local index, score = self:GetMaxScore(itemData.DormitoryAttr)
        self.TxtFeelDes.text = XFurnitureConfigs.GetDormFurnitureTypeName(index)
        self.TxtFeelCount.text = score
    else
        self.TxtName.text = TextManager.GetText("DormNoCount")
        self.TxtFeelDes.text = ""
        self.TxtFeelCount.text = ""
    end

    self.TxtTotalCount.text = itemData.FurnitureScore
    self.TxtFurnitureCount.text = itemData.FurnitureCount or 0

    XUiPLayerHead.InitPortrait(itemData.PlayerHead, itemData.PlayerHeadFrame, self.Head)

    if itemData.IsOnline then
        self.TxtOnline.text = self.TextOnline
    else
        self.TxtOnline.text = self.TextOffline
    end

    local playerId = self.ItemData.PlayerId
    local appearanceShowType = self.ItemData.DormitoryType
    local hasPermission = XDataCenter.DormManager.HasDormPermission(playerId, appearanceShowType)

    if hasPermission then
        self.BtnVisit:SetButtonState(XUiButtonState.Normal)
    else
        self.BtnVisit:SetButtonState(XUiButtonState.Disable)
    end
end

function XUiDormVisitGridItem:OnBtnViewClick()
    if not self.ItemData or not self.ItemData.PlayerId then
        return
    end

    --个人信息
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.ItemData.PlayerId)
end

return XUiDormVisitGridItem