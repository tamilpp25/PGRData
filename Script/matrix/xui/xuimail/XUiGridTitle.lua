local XUiGridTitle = XClass(nil, "XUiGridTitle")
local TITLE_MAX_LENGTH = 22 --标题最大容纳字符窜长度

function XUiGridTitle:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitAutoScript()
    self:SetTitleBg(false)
end

function XUiGridTitle:InitAutoScript()
    self:AutoAddListener()
end

function XUiGridTitle:AutoAddListener()
    self.BtnTitle.CallBack = function()
        self:OnBtnTitleClick()
    end
end

function XUiGridTitle:OnBtnTitleClick()
    self.Base.CurMailInfo = self.MailInfo
    self:OpenMail(true)
end

function XUiGridTitle:OpenMail(IsPlayAnim)
    if self.Base.CurMailInfo.Id == self.MailInfo.Id then
        self.Base.GetItemCallBack = function()
            self:SetMailStatus(true)
        end
        self.Base:ClickMailGrid(self.MailInfo,IsPlayAnim)
        if self.Base.OldTitle then
            self.Base.OldTitle:SetTitleBg(false)
        end
        self.Base.OldTitle = self
        self:SetMailStatus(true)
        self:SetTitleBg(true)
        self:SetUnread(false)
    else
        self:SetTitleBg(false)
    end
end

function XUiGridTitle:SetUnread(IsUnread)
    self.TxtUnread.gameObject:SetActiveEx(IsUnread)
    self.ImgBgUnread.gameObject:SetActiveEx(IsUnread)
end

function XUiGridTitle:UpdateMailGrid(base,mailInfo)
    self.Base = base
    self.MailInfo = mailInfo
    if mailInfo.MailType == XEnumConst.MailType.Normal then
        self:UpdateMailNormal(mailInfo)
    elseif mailInfo.MailType == XEnumConst.MailType.FavoriteMail then
        self:UpdateMailFavor(mailInfo)
    end
end

--普通邮件刷新
function XUiGridTitle:UpdateMailNormal(mailInfo)
    self.TabCollection.gameObject:SetActiveEx(false)
    -- local mailId = mailInfo.Id
    self.TxtTitleRead.text = mailInfo.Title
    -- self.TxtDateRead.text = XTime.TimestampToGameDateTimeString(mailInfo.CreateTime)
    self.TxtDateRead.gameObject:SetActiveEx(false)
    self.TxtTitleUnread.text = mailInfo.Title
    -- self.TxtDateUnread.text = XTime.TimestampToGameDateTimeString(mailInfo.CreateTime)
    self.TxtDateUnread.gameObject:SetActiveEx(false)
    self:SetMailStatusByStatu()
    self:OpenMail(false)
end
--收藏角色好感邮件刷新
function XUiGridTitle:UpdateMailFavor(mailInfo)
    self.TabCollection.gameObject:SetActiveEx(true)
    local mailData = mailInfo.MailData
    local title = mailData.Title
    if string.Utf8LenCustom(title) > TITLE_MAX_LENGTH then
        title = string.Utf8SubCustom(title, 1, TITLE_MAX_LENGTH) .. "..."
    end
    self.TxtTitleRead.text = title
    self.TxtTitleUnread.text = title
    self.TxtDateRead.gameObject:SetActiveEx(false)
    self.TxtDateUnread.gameObject:SetActiveEx(false)

    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    mailInfo.Status = mailAgency:GetFavoriteMailStatus(mailInfo.Id)
    self:SetMailStatusByStatu()
    self:OpenMail(false)
end

function XUiGridTitle:SetMailStatusByStatu()
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    local isRead = mailAgency.IsRead(self.MailInfo.Status)
    self:SetMailStatus(isRead)
    self:SetUnread(not isRead)
end

function XUiGridTitle:SetMailStatus(isRead)
    self.ImgIconRead.gameObject:SetActiveEx(false)
    self.ImgIconUnRead.gameObject:SetActiveEx(false)
    self.ImgIconReadgift.gameObject:SetActiveEx(false)
    self.ImgIconUnReadgift.gameObject:SetActiveEx(false)
    --self.ImgRedDot.gameObject:SetActive(not isRead)
    local isHasReward = false
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    if self.MailInfo.MailType == XEnumConst.MailType.Normal then
        isHasReward = mailAgency:HasMailReward(self.MailInfo.Id)
    elseif self.MailInfo.MailType == XEnumConst.MailType.FavoriteMail then
        isHasReward = #self.MailInfo.MailData.RewardIds > 0
    end
    local isGetReward = mailAgency:IsMailGetReward(self.MailInfo.Id)

    if isHasReward and not isGetReward then

        self.ImgIconUnReadgift.gameObject:SetActiveEx(not isRead)
        self.ImgIconReadgift.gameObject:SetActiveEx(isRead)

    else
        self.ImgIconUnRead.gameObject:SetActiveEx(not isRead)
        self.ImgIconRead.gameObject:SetActiveEx(isRead)
    end
end


function XUiGridTitle:SetTitleBg(flag)
    self.ImgTitleBg.gameObject:SetActiveEx(flag)
end

return XUiGridTitle