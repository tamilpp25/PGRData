

local XUiGridAnnouncementBtn = XClass(nil, "XUiGridAnnouncementBtn")

---@desc 公告标签
---@field Activity 活动
---@field Supply 补给
---@field Important 重要
local NoticeTag = {
    Activity = 1,
    Supply = 2,
    Important = 3
}

--- 公告没有子页签，下标默认为 1
local HtmlIndex = 1


function XUiGridAnnouncementBtn:Ctor(ui, clickCb)
    XTool.InitUiObjectByUi(self, ui)
    self.ClickCb = clickCb
    self.BtnTab.CallBack = function() 
        self:OnBtnClick()
    end
end

function XUiGridAnnouncementBtn:Refresh(info)
    if not info then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.Info = info
    self.GameObject:SetActiveEx(true)
    local tag = info.Tag
    self.ImgActivity.gameObject:SetActiveEx(tag == NoticeTag.Activity)
    self.ImgFedd.gameObject:SetActiveEx(tag == NoticeTag.Supply)
    self.ImgImportant.gameObject:SetActiveEx(tag == NoticeTag.Important)
    self.BtnTab:SetNameByGroup(0, info.Title)
    self.BtnTab:ShowReddot(XDataCenter.NoticeManager.CheckInGameNoticeRedPointIndividual(info, HtmlIndex))
end

function XUiGridAnnouncementBtn:SetSelect(select)
    self.BtnTab:SetButtonState(select and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiGridAnnouncementBtn:OnBtnClick()
    local htmlKey = XDataCenter.NoticeManager.GetGameNoticeReadDataKey(self.Info, HtmlIndex)
    XDataCenter.NoticeManager.ChangeInGameNoticeReadStatus(htmlKey, true)
    self.BtnTab:ShowReddot(false)
    self:SetSelect(true)

    if self.ClickCb then
        self.ClickCb(self)
    end
end

return XUiGridAnnouncementBtn