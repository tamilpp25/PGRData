---@class XMailControl : XControl
---@field _Model XMailModel
local XMailControl = XClass(XControl, "XMailControl")
local METHOD_NAME = {
    MailReadRequest = "MailReadRequest",
    MailGetRewardRequest = "MailGetRewardRequest",
    MailGetSingleRewardRequest = "MailGetSingleRewardRequest",
    MailDeleteRequest = "MailDeleteRequest",
    MailCollectionBoxReceiveFavoriteMailIdsRequest = "MailCollectionBoxReceiveFavoriteMailIdsRequest", --请求收藏角色好感邮件
}
function XMailControl:OnInit()
    --初始化内部变量
end

-------------------------------
--desc: 获取自己收藏盒里一个分类下的所有邮件
--@int tag 分类ID
-------------------------------
function XMailControl:GetCollectBoxMailsByTag(tag)
    return self:GetCollectBoxDatas()[tag] or {}
end

--设置是否查阅过收藏盒界面红点状态
function XMailControl:SetUICollectBoxViewedRedPoint()
    ---@type XMailAgency
    local mailAgency = self:GetAgency()
    mailAgency:SetUICollectBoxViewedRedPoint()
end

--获取有邮件数据的Tag数据
function XMailControl:GetNotEmptyCollectionTagsData()
    local datas = {}
    local collectBox = self:GetCollectBoxDatas()
    for k,v in pairs(collectBox) do
        table.insert(datas,self._Model:GetFavoriteMailTagData(k))
    end
    table.sort(datas,function(a,b)
        return a.Id <= b.Id
    end)
    return datas
end

-------------------------------
--desc: 获取玩家收藏箱邮件数据
-------------------------------
function XMailControl:GetCollectBoxDatas()
    return self._Model:GetCollectBoxDatas()
end

--判断当前邮件是否有奖励
function XMailControl:HasMailReward(mailId)
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

--检查邮件是否保留
function XMailControl:_CheckMailReserve(mailId)
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
function XMailControl:_CheckMailExpire(mailId)
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

function XMailControl:ReadMail(mailId)
    if self:_CheckMailExpire(mailId) and not self:_CheckMailReserve(mailId) then
        return
    end

    local mail = self._Model:GetMail(mailId)
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    if mailAgency.IsRead(mail.Status) or mailAgency.IsDelete(mail.Status) then
        return
    end
    XLuaUiManager.SetMask(true)
    XNetwork.Call(METHOD_NAME.MailReadRequest, { Id = mailId }, function(res)
        if res.Code == XCode.Success then
            ---@type XMailAgency
            local mailAgency = self:GetAgency()
            if mailAgency:HasMailReward(mailId) then
                self:SetMailStatus(mailId, XEnumConst.MAIL_STATUS.STATUS_READ)
                self:GetAgency():SendAgencyEvent(XAgencyEventId.EVENT_MAIL_READ, mailId)
            else
                self:SetMailStatus(mailId, XEnumConst.MAIL_STATUS.STATUS_GETREWARD)
                self:GetAgency():SendAgencyEvent(XAgencyEventId.MAIL_STATUS_GETREWARD, mailId)
            end
        end
        XLuaUiManager.SetMask(false)
    end)
end

function XMailControl:DeleteMail(cb)
    XLuaUiManager.SetMask(true)
    XNetwork.Call(METHOD_NAME.MailDeleteRequest, nil, function(res)
        if res.DelIdList then
            for _, id in pairs(res.DelIdList) do
                self._Model:DeleteMail(id)
            end
        end
        self:GetAgency():SendAgencyEvent(XAgencyEventId.EVENT_MAIL_DELETE)
        cb()
        XLuaUiManager.SetMask(false)
    end)
end

-------------------------------
--desc: 更新领取奖励邮件后的数据
--@List<int> SuccessedIds 领取成功的邮件ID
-------------------------------
function XMailControl:UpdateGetFavorMailResult(SuccessedIds)
    local favoriteMailIds = self._Model:GetFavoriteMailIds()
    local favorMailActivity = self._Model:GetFavorMailActivity()

    for _, id in pairs(SuccessedIds) do
        if not table.contains(favoriteMailIds, id) then
            table.insert(favoriteMailIds, id)
        end
        for i=#favorMailActivity,1,-1 do --从活动的里面删除
            if favorMailActivity[i] == id then
                table.remove(favorMailActivity,i)
            end
        end
        self._Model:GetFavoriteMailsStatusData()[id] = nil --清理领取状态
    end
    self._Model:SetFavoriteMailIds(favoriteMailIds) --重新设置回去,更新标记
    self._Model:SaveFavoriteMailsStatus()
end

--服务器返回的状态
local MAIL_STATUS_DELETE = 4

function XMailControl:GetMailReward(mailId, cb)
    if not self:HasMailReward(mailId) then
        XUiManager.TipText("MailGetRewardEmpty")
        return
    end

    local mailData = self._Model:GetMail(mailId)
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    if mailAgency.IsGetReward(mailData.Status) then
        XUiManager.TipCode(XCode.MailManagerGetRewardRepeat)
        return
    end


    if self:_CheckMailExpire(mailId) and not self:_CheckMailReserve(mailId) then
        self._Model:DeleteMail(mailId)
        XUiManager.TipCode(XCode.MailManagerMailWasInvalid)
        cb(mailId)
        return
    end
    XLuaUiManager.SetMask(true)
    XNetwork.Call(METHOD_NAME.MailGetSingleRewardRequest, { Id = mailId }, function(res)
        local func = function()
            if res.Status == MAIL_STATUS_DELETE then
                self._Model:DeleteMail(mailId)
                XUiManager.TipCode(XCode.MailManagerMailWasInvalid)
                cb(mailId)
                return
            end
            self:SetMailStatus(mailId, res.Status)
            self:GetAgency():SendAgencyEvent(XAgencyEventId.EVENT_MAIL_GET_MAIL_REWARD)
            cb()
        end

        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            func()
        else
            XUiManager.OpenUiObtain(res.RewardGoodsList, nil, func)
        end
        XLuaUiManager.SetMask(false)
    end)
end


-------------------------------------
----desc: 获取全部邮件奖励
----流程: 1,先领取普通邮件(如果失败 直接错误返回)
----     2,再领取收藏邮件(如果失败 先显示普通邮件的奖励　再显示错误)
----     3,显示普通邮件奖励 再显示收藏邮件动画
-------------------------------------
function XMailControl:GetAllMailReward(resultCB)
    --此次请求结果
    local result = {
        NormalMailCode = XCode.Success, --普通邮件请求结果
        FavoriteMailCode = XCode.Success, --收藏邮件请求结果
        CollectBoxMail = {}, --收藏邮件成功列表
        RewardList = {}, --获得奖励列表
    }

    --领取所有普通邮件
    local function RequestNormalMail(normalCB)
        local mailIds = {}
        ---@type XMailAgency
        local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
        local mailCache = self._Model:GetMailCache()
        for id, mail in pairs(mailCache) do
            if self:_CheckMailExpire(id) then
                if not self:_CheckMailReserve(id) then
                    self._Model:DeleteMail(id)
                end
            elseif self:HasMailReward(id) and not mailAgency.IsGetReward(mail.Status) then
                table.insert(mailIds, id)
            end
        end
        if #mailIds <= 0 then
            result.NormalMailCode = XCode.Success
            normalCB()
        else
            XNetwork.Call(METHOD_NAME.MailGetRewardRequest, { IdList = mailIds }, function(response)
                if response.MailStatus then
                    for id, status in pairs(response.MailStatus) do
                        if status == MAIL_STATUS_DELETE then
                            self._Model:DeleteMail(id)
                        else
                            self:SetMailStatus(id, status)
                        end
                    end
                end
                result.RewardList = response.RewardGoodsList
                result.NormalMailCode = response.Code
                self:GetAgency():SendAgencyEvent(XAgencyEventId.EVENT_MAIL_GET_MAIL_REWARD)
                normalCB()
            end)
        end
    end

    --领取收藏邮件
    local function RequestFavorMail(favorCB)
        --领取所有收藏角色好感邮件
        local favorMailActivityIds = self._Model:GetFavorMailActivity()
        if #favorMailActivityIds <= 0 then
            result.FavoriteMailCode = XCode.Success
            favorCB()
        else
            local requestDatas = {
                FavoriteMailIds = favorMailActivityIds
            }
            XNetwork.Call(METHOD_NAME.MailCollectionBoxReceiveFavoriteMailIdsRequest, requestDatas, function(response)
                if response.Code == XCode.Success then
                    if #response.SuccessedIds > 0 then
                        self:UpdateGetFavorMailResult(response.SuccessedIds)
                        result.CollectBoxMail = response.SuccessedIds
                    end
                end
                result.FavoriteMailCode = response.Code
                if response.Rewards and #response.Rewards > 0 then
                    for _,value in pairs(response.Rewards) do
                        table.insert(result.RewardList,value)
                    end
                end
                self:GetAgency():SendAgencyEvent(XAgencyEventId.EVENT_GET_FAVORITE_MAIL_SYNC)
                favorCB()
            end)
        end
    end

    --处理结果
    local function HandleResult()
        self:GetAgency():SendAgencyEvent(XAgencyEventId.EVENT_MAIL_GET_ALL_MAIL_REWARD)
        if result.NormalMailCode == XCode.MailManagerGetMailRewardSomeGoodsMoreThanCapacity then
            local title = CS.XTextManager.GetText("TipTitle")
            local dialogTipCB = function() if resultCB then resultCB(result) end end
            XUiManager.DialogTip(title, CS.XTextManager.GetCodeText(result.NormalMailCode ), XUiManager.DialogType.Normal, dialogTipCB, dialogTipCB)
        elseif result.NormalMailCode ~= XCode.Success then
            XUiManager.TipCode(result.NormalMailCode)
            if resultCB then resultCB(result) end
        else
            local rewardCB = function()
                if result.FavoriteMailCode ~=  XCode.Success then
                    XUiManager.TipCode(result.FavoriteMailCode)
                end
                if resultCB then resultCB(result) end
            end
            if #result.RewardList > 0 then
                XUiManager.OpenUiObtain(result.RewardList, nil,rewardCB)
            else
                rewardCB()
            end
        end
    end
    XLuaUiManager.SetMask(true)
    --流程
    RequestNormalMail(function()
        if result.NormalMailCode ~= XCode.Success then
            HandleResult()
            XLuaUiManager.SetMask(false)
            return
        else
            RequestFavorMail(function()
                HandleResult()
                XLuaUiManager.SetMask(false)
                return
            end)
        end
    end)
end

--读取收藏角色好感邮件
function XMailControl:ReadFavoriteMail(mailId)
    self._Model:GetFavoriteMailsStatusData()[mailId] = XEnumConst.MAIL_STATUS.STATUS_READ
    self._Model:SaveFavoriteMailsStatus()
end

-------------------------------
--desc: 请求领取好感度邮件至收藏盒
--@List<int> mailIds: 要领取的邮件列表
-------------------------------
function XMailControl:RequestReceivedFavoriteMails(mailIds,resultCb)
    for i=#mailIds,1,-1 do
        if self:HasFavoriteMail(mailIds[i]) then
            table.remove(mailIds,i)
        end
    end
    if #mailIds == 0 then return end
    local requestDatas = {
        FavoriteMailIds = mailIds
    }
    XLuaUiManager.SetMask(true)
    XNetwork.Call(METHOD_NAME.MailCollectionBoxReceiveFavoriteMailIdsRequest, requestDatas, function(response)
        if response.Code == XCode.Success then
            if #response.SuccessedIds > 0 then
                self:UpdateGetFavorMailResult(response.SuccessedIds)
            end

        else
            XUiManager.TipCode(response.Code)
        end
        if response.Rewards and #response.Rewards > 0 then
            XUiManager.OpenUiObtain(response.Rewards, nil,function()
                if resultCb then resultCb(#response.SuccessedIds > 0) end
            end)
        else
            if resultCb then resultCb(#response.SuccessedIds > 0) end
        end
        self:GetAgency():SendAgencyEvent(XAgencyEventId.EVENT_GET_FAVORITE_MAIL_SYNC)
        XLuaUiManager.SetMask(false)
    end)
end

--获取邮件列表
function XMailControl:GetMailList()
    local list = {}
    --收藏邮件
    local favorMailActivity = self._Model:GetFavorMailActivity()
    for _, id in pairs(favorMailActivity) do
        local mailData = self._Model:GetFavoriteMailData(id)
        local data = {
            MailType = XEnumConst.MailType.FavoriteMail,
            Id = id,
            MailData = mailData,
            Status = self._Model:GetFavoriteMailStatus(id),
            SendTime = mailData.SendTime,
            ExpireTime = mailData.ExpireTime,
        }
        table.insert(list, data)
    end
    --普通邮件
    local mailCache = self._Model:GetMailCache()
    for k, mail in pairs(mailCache) do
        if mail.Status == XEnumConst.MAIL_STATUS.STATUS_READ then
            if self:HasMailReward(mail.Id) then
                self:SetMailStatus(mail.Id, XEnumConst.MAIL_STATUS.STATUS_READ)
            else
                self:SetMailStatus(mail.Id, XEnumConst.MAIL_STATUS.STATUS_GETREWARD)
            end
        end

        local isExpire = self:_CheckMailExpire(k)
        local isReserve = self:_CheckMailReserve(k)
        if not isExpire or isReserve then
            mail.MailType = XEnumConst.MailType.Normal
            table.insert(list, mail)
        end
    end

    table.sort(list, self._SortMailList)
    return list
end

function XMailControl._SortMailList(a, b)
    if a.MailType ~= b.MailType then
        return a.MailType > b.MailType
    end
    if a.MailType == XEnumConst.MailType.Normal then
        if a.Status ~= b.Status then
            return a.Status < b.Status
        else
            return a.ExpireTime < b.ExpireTime
        end
    elseif a.MailType == XEnumConst.MailType.FavoriteMail then
        if not (a.MailData.ShowTimeStamp == b.MailData.ShowTimeStamp) then
            return a.MailData.ShowTimeStamp > b.MailData.ShowTimeStamp
        end
        return a.Id > b.Id
    end
    return true
end

function XMailControl:GetMailCache(mailId)
    return self._Model:GetMail(mailId)
end

--收藏邮件
--判断是否有收藏邮件
function XMailControl:HasFavoriteMail(mailId)
    return table.contains(self._Model:GetFavoriteMailIds(), mailId)
end

function XMailControl:SyncMailEvent()
    self:GetAgency():SendAgencyEvent(XAgencyEventId.EVENT_MAIL_SYNC)
end

function XMailControl:IsMailGetReward(mailId)
    local mail = self._Model:GetMail(mailId)
    if not mail then
        return
    end
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    return mailAgency.IsGetReward(mail.Status)
end

--设置邮件状态
function XMailControl:SetMailStatus(id, status)
    local mail = self._Model:GetMail(id)
    if not mail then
        return
    end

    if status == XEnumConst.MAIL_STATUS.STATUS_UNREAD or (mail.Status & status) == status then
        return
    end

    mail.Status = mail.Status | status
end

--对问卷类型文本进行超链接解析
function XMailControl:FixSurveyContent(mailInfo)
    local content = mailInfo.Content or ""
    local pattern = '@&&.+,url=.+,qid=.+,title=.+'
    
    for str in string.gmatch(content, pattern) do
        local fixContent = '<a href=\"%s\">%s</a>'
        local btnContent = string.match(str,'@&&(.+),url')
        local link = string.match(str,'url=(.+),qid')
        --对链接增加参数
        local linkParm = '?sojumpparm=%s&parmsign=%s'
        local qid = string.match(str,'qid=(.+),title')
        linkParm = string.format(linkParm, XMVCA.XUrl:GetSojumpParm(), XMVCA.XUrl:GetParmSign(qid))
        fixContent = string.format(fixContent, link..linkParm,btnContent)
        local fixedContent = XUiHelper.GetText('MailHyperLink', link..linkParm, btnContent)
        fixedContent = string.gsub(fixedContent, "|", "\"")
        content = string.gsub(content, str, fixedContent)
    end
    return content
end

function XMailControl:GetFavoriteMailCfgById(mailId)
    return self._Model:GetFavoriteMailCfgById(mailId)
end

function XMailControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XMailControl:RemoveAgencyEvent()

end

function XMailControl:OnRelease()

end
return XMailControl