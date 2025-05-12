local TABLE_MAIL_PATH = "Client/Mail/Mail.tab"
local TABLE_MAIL_REWARD_GOODS_PATH = "Share/Mail/MailRewardGoods.tab"
local TABLE_FAVORITEMAIL_ACTIVITY_PATH = "Share/MailCollectionBox/MailCollectionBoxActivity.tab"
local TABLE_FAVORITEMAIL_MIAL_PATH = "Share/MailCollectionBox/MailCollectionBoxFavoriteMail.tab"
local TABLE_FAVORITEMAIL_TAG_PATH = "Share/MailCollectionBox/MailCollectionBoxFavoriteMailTag.tab"
local PERSISTENCE_FAVOR_MAILS_STATUS = "FavoriteMailsStatus"

---@class XMailModel : XModel
local XMailModel = XClass(XModel, "XMailModel")
function XMailModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._MailCache = {} --邮件的缓存
    self._FavoriteMailIds = nil --收藏字典 DictFavorMailCollection
    self._FavorMailActivity = nil --活动期间的收藏列表 ListFavorMailActivity


    self._FavoriteMailsStatus = nil --从本地持久化数据里获取好感度邮件的读取情况　外部只读

    self._IsCollectBoxDirty = true
    self._CollectBoxMailList = nil

    --config相关
    self._ConfigUtil:InitConfig({
        [TABLE_MAIL_PATH] = {XConfigUtil.ReadType.Int, XTable.XTableMail, "Id", XConfigUtil.CacheType.Normal},
        [TABLE_MAIL_REWARD_GOODS_PATH] = {XConfigUtil.ReadType.Int, XTable.XTableRewardGoods, "Id", XConfigUtil.CacheType.Normal},
        [TABLE_FAVORITEMAIL_ACTIVITY_PATH] = {XConfigUtil.ReadType.Int, XTable.XTableMailCollectionBoxActivity, "Id"},
        [TABLE_FAVORITEMAIL_MIAL_PATH] = {XConfigUtil.ReadType.Int, XTable.XTableMailCollectionBoxFavoriteMail, "Id", XConfigUtil.CacheType.Private},
        [TABLE_FAVORITEMAIL_TAG_PATH] = {XConfigUtil.ReadType.Int, XTable.XTableMailCollectionBoxFavoriteMailTag, "Id", XConfigUtil.CacheType.Private}
    })
    self.DictActivityMail = nil --邮箱id对应活动timeid

    self.DefaultCollectBoxMail = nil --需要排除活动类的

    self.FavoriteMailTagsDatas = nil

    self.MailRewardTemplates = nil
    --private
    --存储收藏邮件的具体数据
    self._favorMailDatas = {} --对应XMailConfig.FavoriteMailDatas 并没有用到
end

function XMailModel:UpdateMail(mailData)
    self._MailCache[mailData.Id] = mailData
end

function XMailModel:DeleteMail(mailId)
    self._MailCache[mailId] = nil
end

function XMailModel:GetMail(mailId)
    return self._MailCache[mailId]
end

function XMailModel:GetMailCache()
    return self._MailCache
end

--更新收藏字典
function XMailModel:SetFavoriteMailIds(ids)
    self._FavoriteMailIds = ids
    self._IsCollectBoxDirty = true
end

--获取收藏字典
function XMailModel:GetFavoriteMailIds()
    return self._FavoriteMailIds
end

--正在活动期间的收藏邮件列表
function XMailModel:SetFavorMailActivity(ids)
    self._FavorMailActivity = ids
end

function XMailModel:GetFavorMailActivity()
    return self._FavorMailActivity
end

function XMailModel:GetFavoriteMailsStatusData()
    if self._FavoriteMailsStatus == nil then
        self._FavoriteMailsStatus = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, PERSISTENCE_FAVOR_MAILS_STATUS)) or {}
    end
    return self._FavoriteMailsStatus
end

function XMailModel:GetFavoriteMailStatus(mailId)
    local data = self:GetFavoriteMailsStatusData()
    return data[mailId] or XEnumConst.MAIL_STATUS.STATUS_UNREAD
end

function XMailModel:SaveFavoriteMailsStatus()
    local data = self:GetFavoriteMailsStatusData()
    if #data > 0 then
        XSaveTool.RemoveData(string.format("%d%s", XPlayer.Id, PERSISTENCE_FAVOR_MAILS_STATUS))
    else
        XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, PERSISTENCE_FAVOR_MAILS_STATUS), data)
    end
end

function XMailModel:GetDictActivityMail()
    if not self.DictActivityMail then
        self.DictActivityMail = {}
        local activityFavoriteMailDatas = self:GetActivityFavoriteMailDatas()
        for k, data in pairs(activityFavoriteMailDatas) do
            for _,id in pairs(data.FavoriteMailIds) do
                self.DictActivityMail[id] = data
            end
        end
    end
    return self.DictActivityMail
end

function XMailModel:GetActivityFavoriteMailDatas()
    return self._ConfigUtil:Get(TABLE_FAVORITEMAIL_ACTIVITY_PATH)
end

----下面处理配置表相关
function XMailModel:GetActivityFavoriteMailData(id)
    local activityData = self:GetActivityFavoriteMailDatas()[id]
    if not activityData then
        XLog.ErrorTableDataNotFound("XMailModel.GetActivityFavoriteMailData", "tab", TABLE_FAVORITEMAIL_ACTIVITY_PATH, "id", tostring(id))
        return {
            Id = id,
            TimeId = 0,
            FavoriteMailIds = {}
        }
    end
    return activityData
end

function XMailModel:GetFavoriteMailDatasOrigin()
    return self._ConfigUtil:Get(TABLE_FAVORITEMAIL_MIAL_PATH)
end

function XMailModel:GetFavoriteMailCfgById(mailId)
    local cfg = self:GetFavoriteMailDatasOrigin()[mailId]
    if cfg then
        return cfg
    else
        XLog.ErrorTableDataNotFound("XMailModel.GetFavoriteMailCfgById", "tab", TABLE_FAVORITEMAIL_MIAL_PATH, "id", tostring(mailId))
    end
end

-------------------------------
--desc: 获取收藏角色好感邮件数据
--return data : XTable.XTableFavoriteMail
-------------------------------
function XMailModel:GetFavoriteMailData(id)
    --if self._favorMailDatas[id] then
    --    return self._favorMailDatas[id]
    --end
    local originData = self:GetFavoriteMailDatasOrigin()[id]
    if not originData then
        XLog.ErrorTableDataNotFound("XMailModel.GetFavoriteMailData", "tab", TABLE_FAVORITEMAIL_MIAL_PATH, "id", tostring(id))
        return nil
    end
    local sendTime = 0
    local expireTime = 0
    local DictActivityMail = self:GetDictActivityMail()
    if DictActivityMail[id] then
        sendTime,expireTime = XFunctionManager.GetTimeByTimeId(DictActivityMail[id].TimeId)
    end
    local stringShowtime = string.gsub(originData.ShowTime,"/","-")
    local timeStampShowtime = XTime.ParseToTimestamp(stringShowtime)
    local mailData = {
        Id = originData.Id,
        TagId = originData.TagId,
        ShowTime = stringShowtime,
        ShowTimeStamp = timeStampShowtime,
        MailIcon = originData.MailIcon,
        Desc = originData.Desc,
        Title = originData.Title,
        SendName = originData.SendName,
        Content = originData.Content,
        RewardIds = originData.RewardIds,
        SendTime = sendTime,
        ExpireTime = expireTime,
    }
    return mailData
end

-------------------------------
--desc: 获取玩家收藏箱邮件数据
-------------------------------
function XMailModel:GetCollectBoxDatas()
    if not self._IsCollectBoxDirty then
        return self._CollectBoxMailList
    end
    self._CollectBoxMailList = {}
    local defaultCollectBoxMail = self:GetDefaultCollectBoxMail()
    for id, data in pairs(defaultCollectBoxMail) do
        if not self._CollectBoxMailList[data.TagId] then self._CollectBoxMailList[data.TagId] = {} end
        table.insert(self._CollectBoxMailList[data.TagId], data)
    end

    --这里要加入领取过的收藏邮件
    for _, id in ipairs(self._FavoriteMailIds) do
        if not defaultCollectBoxMail[id] then --免得重复添加
            local data = self:GetFavoriteMailData(id)
            if not self._CollectBoxMailList[data.TagId] then self._CollectBoxMailList[data.TagId] = {} end
            table.insert(self._CollectBoxMailList[data.TagId], data)
        end
    end

    for tag,list in pairs(self._CollectBoxMailList) do
        table.sort(list,function(a,b)
            if not (a.ShowTimeStamp == b.ShowTimeStamp) then
                return a.ShowTimeStamp > b.ShowTimeStamp
            end
            return a.Id > b.Id
        end)
    end
    self._IsCollectBoxDirty = false
    return self._CollectBoxMailList
end

function XMailModel:GetDefaultCollectBoxMail()
    if not self.DefaultCollectBoxMail then --默认收藏邮件集合
        self.DefaultCollectBoxMail = {}
        local favoriteMailDatasOrigin = self:GetFavoriteMailDatasOrigin()
        for k, _ in pairs(favoriteMailDatasOrigin) do
            if not self:GetDictActivityMail()[k] then
                self.DefaultCollectBoxMail[k] = self:GetFavoriteMailData(k)
            end
        end
    end
    return self.DefaultCollectBoxMail
end

--获取所有收藏角色好感邮件Tag(分类)的数据
function XMailModel:GetFavoriteMailTagDatas()
    return self._ConfigUtil:Get(TABLE_FAVORITEMAIL_TAG_PATH)
end

--获取收藏角色好感邮件Tag(分类)的数据
function XMailModel:GetFavoriteMailTagData(id)
    local tagData = self:GetFavoriteMailTagDatas()[id]
    if not tagData then
        XLog.ErrorTableDataNotFound("XMailModel.GetFavoriteMailTagData", "tab", TABLE_FAVORITEMAIL_TAG_PATH, "id", tostring(id))
        return
    end
    return tagData
end

function XMailModel:GetRewardList(mailId)
    if self.MailRewardTemplates == nil then
        self.MailRewardTemplates = {}
    end

    if XTool.IsTableEmpty(self.MailRewardTemplates[mailId]) then
        -- 加载指定邮件的奖励道具数据
        local mailCfgs = self._ConfigUtil:Get(TABLE_MAIL_PATH)
        local mailCfg = mailCfgs[mailId]
        if mailCfg then
            local rewardGoodsTable = self._ConfigUtil:Get(TABLE_MAIL_REWARD_GOODS_PATH)
            local list = {}
            for _, id in pairs(mailCfg.RewardIds) do
                local tab = rewardGoodsTable[id]
                if not tab then
                    XLog.ErrorTableDataNotFound("XMailModel.Init", "MailRewardGoods", TABLE_MAIL_REWARD_GOODS_PATH, "id", tostring(id))
                    return
                end
                table.insert(list, XRewardManager.CreateRewardGoodsByTemplate(tab))
            end

            self.MailRewardTemplates[mailId] = list
        end
    end
    
    local rewardList = self.MailRewardTemplates[mailId]
    if not rewardList then
        XLog.ErrorTableDataNotFound("XMailModel.GetRewardList", "tab", TABLE_MAIL_REWARD_GOODS_PATH, "id", tostring(mailId))
        return
    end

    return rewardList
end


function XMailModel:ClearPrivate()
    --这里执行内部数据清理
    self._CollectBoxMailList = nil
    self._IsCollectBoxDirty = true
end

---重置所有的数据,用于重登
function XMailModel:ResetAll()
    self._MailCache = {}
    self._FavoriteMailIds = nil
    self._FavorMailActivity = nil
    self._FavoriteMailsStatus = nil
    self._IsCollectBoxDirty = true
    self._CollectBoxMailList = nil
end

return XMailModel