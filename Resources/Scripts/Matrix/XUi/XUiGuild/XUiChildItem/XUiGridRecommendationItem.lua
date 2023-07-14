local XUiGridRecommendationItem = XClass(nil, "XUiGridRecommendationItem")

function XUiGridRecommendationItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridRecommendationItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridRecommendationItem:OnClickStatus()
    self.CurStatus = not self.CurStatus
    self:SetSeleStatus(self.CurStatus)
end

function XUiGridRecommendationItem:SetSeleStatus(status)
    self.ItemData.Status = status
    self.SeleBgImg.gameObject:SetActiveEx(true)
    if status then
        self.UiRoot:RecordSeleId(self.ItemData.GuildId)
    else
        self.UiRoot:RemoveRecordSeleId(self.ItemData.GuildId)
    end
end

-- 更新数据
function XUiGridRecommendationItem:OnRefresh(itemdata)
    if not itemdata then
        return
    end

    self.ItemData = itemdata
    self.ItemData.GuildId = itemdata.Id
    self.TxtLv.text = itemdata.Level
    self.TxtName.text = itemdata.Name
    self.TextContributionNum.text = itemdata.ContributeIn7Days
    self.TextMemberNum.text = itemdata.MemberCount
    local config = XGuildConfig.GetGuildHeadPortraitById(itemdata.IconId)
    if config then
        local path = config.Icon
        self.ImgIcon:SetRawImage(path)
    end
    self.CurStatus = self.ItemData.Status or false
    self:SetSeleStatus(self.CurStatus)
end

function XUiGridRecommendationItem:SetApplyTag(bool)
    self.PanelApplyTag.gameObject:SetActiveEx(bool)
end
return XUiGridRecommendationItem