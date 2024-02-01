local PERSISTENCE_COLLECTBOX_REDPOINT = "CollectBoxRedPoint"

---@class XMailAgency : XAgency
---@field _Model XMailModel
local XMailAgency = XClass(XAgency, "XMailAgency")
function XMailAgency:OnInit()
    --初始化一些变量
end

function XMailAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyMails = Handler(self, self.NotifyMails)
    XRpc.NotifyLoginMailCollectionBoxData = Handler(self, self.NotifyLoginMailCollectionBoxData)
    XRpc.NotifyActivityMailCollectionBoxData = Handler(self, self.NotifyActivityMailCollectionBoxData)
end

function XMailAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--检查红点
function XMailAgency:HasFavoriteMailActivity()
    local favorMailActivity = self._Model:GetFavorMailActivity()
    if not favorMailActivity then
        return false
    end
    return #favorMailActivity > 0
end

---获取现在邮箱邮件个数
function XMailAgency:GetMailListCount()
    local count = 0
    local mailCache = self._Model:GetMailCache()
    for k, _ in pairs(mailCache) do
        if not self:_CheckMailExpire(k) then
            count = count + 1
        end
    end
    return count
end

--- 邮件是否达到数量上限
---@param hintTip boolean 是否弹出提示
function XMailAgency:CheckMailIsOverLimit(hintTip)
    local max = CS.XGame.Config:GetInt("MailCountLimit")
    local cur = self:GetMailListCount()
    if (max - cur) < 1 then
        if hintTip then
            XUiManager.TipMsg(CS.XTextManager.GetText("MailBoxIsFull"))
        end
        return true
    end
    return false
end

--获取是否查阅过收藏盒界面红点状态
function XMailAgency:GetUICollectBoxViewedRedPoint()
    local isRead = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, PERSISTENCE_COLLECTBOX_REDPOINT)) or false
    return not isRead
end

--设置是否查阅过收藏盒界面红点状态
function XMailAgency:SetUICollectBoxViewedRedPoint()
    XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, PERSISTENCE_COLLECTBOX_REDPOINT),true)
    self:SendAgencyEvent(XAgencyEventId.EVENT_COLLECTION_BOX_VIEW)
end

function XMailAgency.IsRead(status)
    return (status & XEnumConst.MAIL_STATUS.STATUS_READ) == XEnumConst.MAIL_STATUS.STATUS_READ
end

function XMailAgency.IsGetReward(status)
    return (status & XEnumConst.MAIL_STATUS.STATUS_GETREWARD) == XEnumConst.MAIL_STATUS.STATUS_GETREWARD
end

function XMailAgency.IsDelete(status)
    return (status & XEnumConst.MAIL_STATUS.STATUS_DELETE) == XEnumConst.MAIL_STATUS.STATUS_DELETE
end

function XMailAgency:IsMailGetReward(mailId)
    local mail = self._Model:GetMail(mailId)
    if not mail then
        return
    end

    return XMailAgency.IsGetReward(mail.Status)
end

function XMailAgency:HasMailReward(mailId)
    local mail = self._Model:GetMail(mailId)
    if not mail then
        return false
    end

    local rewardList = mail.RewardGoodsList
    if not rewardList then
        return false
    end

    if #rewardList > 0 then
        return true
    end

    return false
end

---是否是退款警告邮件
function XMailAgency:IsSpecialMail(mailInfo)
    return mailInfo.Type and mailInfo.Type == XEnumConst.MailType.SpecialMail
end

function XMailAgency:IsExpireAndReserve(mailId)
    return self:_CheckMailExpire(mailId) and self:_CheckMailReserve(mailId)
end

function XMailAgency:IsExpire(mailId)
    return self:_CheckMailExpire(mailId)
end

function XMailAgency:IsReserve(mailId)
    return self:_CheckMailReserve(mailId)
end

--检查邮件是否保留
function XMailAgency:_CheckMailReserve(mailId)
    local mail = self._Model:GetMail(mailId)
    if not mail then
        return false
    end

    if mail.Status == XEnumConst.MAIL_STATUS.STATUS_DELETE then
        return false
    end

    if not mail.ReserveTime or mail.ReserveTime <= 0 then
        return false
    end

    return XTime.GetServerNowTimestamp() <= mail.ReserveTime
end

--检查邮件是否过期
function XMailAgency:_CheckMailExpire(mailId)
    local mail = self._Model:GetMail(mailId)
    if not mail then
        return true
    end

    if mail.Status == XEnumConst.MAIL_STATUS.STATUS_DELETE then
        return true
    end

    if not mail.ExpireTime or mail.ExpireTime <= 0 then
        return false
    end

    return XTime.GetServerNowTimestamp() > mail.ExpireTime
end

--检查红点-----------------------------------
--有未读或者有奖励未领取
function XMailAgency:IsMailUnReadOrHasReward(mailId)
    if not mailId then
        return false
    end

    local mailData = self._Model:GetMail(mailId)
    if not mailData then
        return false
    end

    if self:_CheckMailExpire(mailId) then
        return false
    end

    if not XMailAgency.IsRead(mailData.Status) then
        return true
    end

    if not XMailAgency.IsGetReward(mailData.Status) and self:HasMailReward(mailId) then
        return true
    end

    return false
end

--获取没处理的邮件
function XMailAgency:GetHasUnDealMail()
    local mailList = self._Model:GetMailCache()
    local result = 0
    for _, mailInfo in pairs(mailList) do
        if self:IsMailUnReadOrHasReward(mailInfo.Id) then
            result = result + 1
        end
    end
    return result
end

-------------------------------
--desc: 从本地持久化数据里获取好感度邮件的读取情况
--return status
-------------------------------
function XMailAgency:GetFavoriteMailStatus(mailId)
    local data = self._Model:GetFavoriteMailsStatusData()
    return data[mailId] or XEnumConst.MAIL_STATUS.STATUS_UNREAD
end

---获取邮件奖励列表
---@param mailId number 邮件id
---@return any
function XMailAgency:GetRewardList(mailId)
    return self._Model:GetRewardList(mailId)
end

---处理邮件数据
function XMailAgency:_DealMailDatas(mailList, expireIdList)
    if mailList then
        for _, mail in pairs(mailList) do
            self._Model:UpdateMail(mail)
        end
    end

    if expireIdList then
        for _, id in pairs(expireIdList) do
            self._Model:DeleteMail(id)
        end
    end
    self:SendAgencyEvent(XAgencyEventId.EVENT_MAIL_SYNC)
end

---处理收藏角色好感的邮件数据
function XMailAgency:_DealMailCollectionBoxData(data)
    self._Model:SetFavoriteMailIds(data.MailCollectionBoxDataDb.ReceivedFavoriteMailIds) --先存起来
    self:_UpdateFavorMailActivity(data.OpenActivityIds)
    self:_UpdateFavoriteMailsStatus()
    self:SendAgencyEvent(XAgencyEventId.EVENT_FAVORITE_MAIL_SYNC)
end

function XMailAgency:_UpdateMailCollectionBoxData(data)
    self:_UpdateFavorMailActivity(data.OpenActivityIds)
    self:_UpdateFavoriteMailsStatus()
    self:SendAgencyEvent(XAgencyEventId.EVENT_FAVORITE_MAIL_SYNC)
end

function XMailAgency:_UpdateFavorMailActivity(openActivityIds)
    local favorMailActivity = {}
    local favoriteMailIds = self._Model:GetFavoriteMailIds()
    for _, autoId in pairs(openActivityIds) do
        local activityData = self._Model:GetActivityFavoriteMailData(autoId)
        for _, mailId in pairs(activityData.FavoriteMailIds) do
            if not table.contains(favoriteMailIds, mailId) then--没有在收藏列表里的就丢到活动期间的收藏列表里(没有领取)
                table.insert(favorMailActivity, mailId)
            end
        end
    end
    self._Model:SetFavorMailActivity(favorMailActivity)
end

---更新本地持久化的好感度邮件的读取情况
function XMailAgency:_UpdateFavoriteMailsStatus()
    local favoriteMailIds = self._Model:GetFavoriteMailIds()
    local fmData = self._Model:GetFavoriteMailsStatusData()
    for key, _ in pairs(fmData) do
        local exist = table.contains(favoriteMailIds, key)
        if not exist then
            fmData[key] = nil
        end
    end
    for _, id in pairs(favoriteMailIds) do
        if fmData[id] ~= XEnumConst.MAIL_STATUS.STATUS_READ then
            fmData[id] = XEnumConst.MAIL_STATUS.STATUS_UNREAD
        end
    end
    self._Model:SaveFavoriteMailsStatus() --更新完要保存
end

-------协议相关--------
function XMailAgency:NotifyMails(data)
    self:_DealMailDatas(data.NewMailList, data.ExpireIdList)
    CsXGameEventManager.Instance:Notify(XAgencyEventId.EVENT_MAIL_COUNT_CHANGE) --这个C#的接口,还是得保留
end

function XMailAgency:NotifyLoginMailCollectionBoxData(data)
    self:_DealMailCollectionBoxData(data)
end

function XMailAgency:NotifyActivityMailCollectionBoxData(data)
    self:_UpdateMailCollectionBoxData(data)
end
return XMailAgency