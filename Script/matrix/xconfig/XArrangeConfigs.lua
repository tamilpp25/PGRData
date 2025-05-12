local QualityBgPath = {
    CS.XGame.ClientConfig:GetString("CommonBagWhite"),
    CS.XGame.ClientConfig:GetString("CommonBagGreed"),
    CS.XGame.ClientConfig:GetString("CommonBagBlue"),
    CS.XGame.ClientConfig:GetString("CommonBagPurple"),
    CS.XGame.ClientConfig:GetString("CommonBagGold"),
    CS.XGame.ClientConfig:GetString("CommonBagRed"),
    CS.XGame.ClientConfig:GetString("CommonBagRed"),
}

local QualityPath = {
    CS.XGame.ClientConfig:GetString("QualityIconColor1"),
    CS.XGame.ClientConfig:GetString("QualityIconColor2"),
    CS.XGame.ClientConfig:GetString("QualityIconColor3"),
    CS.XGame.ClientConfig:GetString("QualityIconColor4"),
    CS.XGame.ClientConfig:GetString("QualityIconColor5"),
    CS.XGame.ClientConfig:GetString("QualityIconColor6"),
    CS.XGame.ClientConfig:GetString("QualityIconColor7"),
}


XArrangeConfigs = XArrangeConfigs or {}

XArrangeConfigs.Types = {
    Error    = 0,
    Item        = 1, --道具
    Character = 2, --成员
    Weapon    = 3, --武器
    Wafer    = 4, --意识
    Part        = 6,
    Fashion    = 7, --时装
    BaseEquip = 8, --基地装备
    Furniture = 9, --家具
    HeadPortrait = 10, --头像
    DormCharacter = 11, --宿舍构造体
    ChatEmoji = 12, --聊天表情
    WeaponFashion = 13, --武器投影
    Collection = 14, --收藏
    Background = 15, --场景
    Pokemon = 16, --口袋战双
    Partner = 17,--伙伴
    Nameplate = 18, --铭牌
    RankScore = 20, --等级评分
    Medal    = 21, --勋章
    DrawTicket = 22, --免费抽奖券
    GuildGoods = 23, --公会道具
    DlcHuntChip = 24, --dlcHunt芯片
    ItemCollection = 25, --道具收藏
    ChatBoard = 26, --聊天框
    SgDormFurniture = 27, --空花宿舍家具
    SgDormFashion = 28, --空花宿舍涂装
    QuestItem = 29, --空花任务道具
}

function XArrangeConfigs.GetType(id)
    return math.floor(id / 1000000) + 1
end

function XArrangeConfigs.GeQualityBgPath(quality)
    if not quality then
        XLog.Error("XArrangeConfigs.GeQualityBgPath 函数错误: 参数quality不能为空")
        return
    end
    return QualityBgPath[quality]
end

function XArrangeConfigs.GeQualityPath(quality)
    if not quality then
        XLog.Error("XArrangeConfigs.GeQualityBgPath 函数错误: 参数quality不能为空")
        return
    end
    return QualityPath[quality]
end