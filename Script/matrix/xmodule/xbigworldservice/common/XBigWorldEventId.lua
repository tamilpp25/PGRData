local id = 1000000

local function NewId() 
    id = id + 1
    return id
end

local dlcEventId = {
    -- 战斗端角色加载完成
    EVENT_LOCAL_PLAYER_NPC_LOAD_COMPLETED = NewId(),
    
    --刷新任务界面选中状态
    EVENT_REFRESH_QUEST_MAIN = NewId(),
    
    -- 空花Objective状态刷新
    EVENT_QUEST_OBJECTIVE_STATE_CHANGED = NewId(),
    
    -- 角色编队状态刷新
    EVENT_ROLE_TEAM_STATUS_REFRESH = NewId(),

    -- 短信领取任务
    EVENT_MESSAGE_QUEST_NOTIFY = NewId(),
    
    -- 咖啡回合开始
    EVENT_CAFE_ROUND_BEGIN = NewId(),
    
    -- 咖啡进入战斗
    EVENT_CAFE_ENTER_FIGHT = NewId(),

    -- 咖啡退出战斗
    EVENT_CAFE_EXIT_FIGHT = NewId(),
    
    -- 手牌更新
    EVENT_CAFE_UPDATE_PLAY_CARD = NewId(),

    --咖啡厅Hud刷新
    EVENT_CAFE_HUD_REFRESH = NewId(),

    --咖啡厅Hud隐藏
    EVENT_CAFE_HUD_HIDE = NewId(),

    -- 结算
    EVENT_CAFE_SETTLEMENT = NewId(),

    --回合播报
    EVENT_CAFE_REFRESH_BROADCAST = NewId(),
    
    --触发重抽
    EVENT_CAFE_RE_DRAW_CARD = NewId(),
    
    --NPC回合演出
    EVENT_CAFE_ROUND_NPC_SHOW = NewId(),
    
    --特效飞行完成
    EVENT_CAFE_EFFECT_FLY_COMPLETE = NewId(),
    
    --特效开始飞行
    EVENT_CAFE_EFFECT_BEGIN_FLY = NewId(),
    
    --吧台NPC角色改变了
    EVENT_CAFE_BAR_COUNTER_NPC_CHANGED = NewId(),
    
    --触发buff
    EVENT_CAFE_APPLY_BUFF = NewId(),
    
    --出牌区下标更新
    EVENT_CAFE_DEAL_INDEX_UPDATE = NewId(),
    
    --出牌
    EVENT_CAFE_DECK_TO_DEAL = NewId(),
    
    --牌组数量变化
    EVENT_CAFE_POOL_CARD_COUNT_UPDATE = NewId(),
    
    -- 追踪图钉
    EVENT_MAP_PIN_TRACK_CHANGE = NewId(),

    -- 添加图钉
    EVENT_MAP_PIN_ADD = NewId(),

    -- 删除图钉
    EVENT_MAP_PIN_REMOVE = NewId(),
    
    -- 开始传送图钉
    EVENT_MAP_PIN_BEGIN_TELEPORT = NewId(),
    
    -- 结束传送图钉
    EVENT_MAP_PIN_END_TELEPORT = NewId(),

    -- 商业街 关卡刷新
    EVENT_BUSINESS_STREET_STAGE_REFRESH = NewId(),

    -- 商业街建造刷新
    EVENT_BUSINESS_STREET_BUILD_REFRESH = NewId(),

    -- 商业街资源刷新
    EVENT_BUSINESS_STREET_RES_REFRESH = NewId(),

    -- 商业街BUFF刷新
    EVENT_BUSINESS_STREET_BUFF_REFRESH = NewId(),

    -- 商业街喜好说话刷新
    EVENT_BUSINESS_STREET_LIKE_TALK_REFRESH = NewId(),

    -- 商业街任务完成刷新
    EVENT_BUSINESS_STREET_FINISH_TASK_REFRESH = NewId(),

    -- 激活场景物体
    EVENT_SCENE_OBJECT_ACTIVATE = NewId(),

    -- 短信阅读完成
    EVENT_MESSAGE_FINISH_NOTIFY = NewId(),

    -- 收到短信
    EVENT_RECEIVE_MESSAGE_NOTIFY = NewId(),
    
    -- 宿舍预设刷新
    EVENT_DORM_LAYOUT_REFRESH = NewId(),
    
    -- 宿舍应用新预设
    EVENT_DORM_APPLY_NEW_LAYOUT = NewId(),
    
    -- 宿舍家具刷新
    EVENT_DORM_FURNITURE_REFRESH = NewId(),

    -- 设置重置
    EVENT_SETTING_RESET = NewId(),

    -- 设置保存
    EVENT_SETTING_SAVE = NewId(),

    -- 设置恢复默认
    EVENT_SETTING_RESTORE = NewId(),

    -- 解锁图文教程
    EVENT_TEACH_UNLOCK = NewId(),

    -- 阅读图文教程
    EVENT_TEACH_READ = NewId(),
    
    -- Mask黑屏关闭
    EVENT_BLACK_MASK_LOADING_CLOSE = NewId(),
    
    -- 战斗关卡开始更新
    EVENT_FIGHT_LEVEL_BEGIN_UPDATE = NewId(),
}

return dlcEventId