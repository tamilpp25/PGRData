---Agency的事件, 通过XMVCA派发
XAgencyEventId = {
    --邮件事件
    EVENT_MAIL_SYNC = "EVENT_MAIL_SYNC", --服务端同步邮件,
    EVENT_MAIL_READ = "EVENT_MAIL_READ", --读取邮件,
    MAIL_STATUS_GETREWARD = "MAIL_STATUS_GETREWARD", --领取奖励
    EVENT_MAIL_DELETE = "EVENT_MAIL_DELETE", --删除邮件,
    EVENT_MAIL_GET_MAIL_REWARD = "EVENT_MAIL_GET_MAIL_REWARD", --领取邮件附件
    EVENT_MAIL_GET_ALL_MAIL_REWARD = "EVENT_MAIL_GET_ALL_MAIL_REWARD", --一键领取附件
    EVENT_MAIL_COUNT_CHANGE = "EVENT_MAIL_COUNT_CHANGE", --邮件数发生改变

    --收藏角色好感度邮件事件
    EVENT_FAVORITE_MAIL_SYNC = "EVENT_FAVORITE_MAIL_SYNC", --服务端同步邮件,
    EVENT_GET_FAVORITE_MAIL_SYNC = "EVENT_GET_FAVORITE_MAIL_SYNC", --领取邮件附件
    EVENT_COLLECTION_BOX_VIEW = "EVENT_COLLECTION_BOX_VIEW", --领取邮件附件
}

---Control内部事件, 通过Agency派发
XControlEventId = {

}