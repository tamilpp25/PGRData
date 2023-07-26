XHomeBehaviorStatus = {
    IDLE = "IDLE", --正常
    SLEEP = "SLEEP", --睡觉

    TIRED = "TIRED", --想上床躺着
    ANNOY = "ANNOY", --想上沙发
    BORING = "BORING", --无聊，想聊天
    WANTTOUCH = "WANTTOUCH", --想要抚摸
    LAZY = "LAZY", --想翻柜子
    LOVE = "LOVE", --相思

    REWAWRD = "REWAWRD", --奖励
    GRAB_UP = "GRAB_UP", --抓起
    FONDLE = "FONDLE", --爱抚
    SELECTED = "SELECTED", --选中
    WAIT = "WAIT", --按下

    CLICK = "CLICK", --选中
    CHNGEPOS = "CHNGEPOS", -- 改变位置
    RELATIOM = "RELATIOM", --与家具交互
}

--爱抚类型
XHomeCharFondleType = {
    NORMAL = 0,
    TOUCH = 1,
    PUSH = 2,
    PLAY = 3,
    TOUCH_COMPLETE = 4,
    PUSH_COMPLETE = 5,
    PLAY_COMPLETE = 6,
    REFUSE = 7,
}