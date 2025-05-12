local XTemple2Enum = {
    COLOR = {
        None = 0,
        RED = 1,
        YELLOW = 2,
        BLUE = 3,
    },
    EVENT = {
        ARRIVE_GRID = 1,
        PASS_GRID = 2,
    },
    BUBBLE = {
        STORY = 1,
        EMOJI = 2,
    },
    GRID_SIZE = 80,
    BLOCK_SIZE = { X = 3, Y = 3 },
    RULE = {
        NEIGHBOUR_DIFF_COLOR_GRID_ADD = 1, --每有一个相连的不同色格子整个地块的分数+1。
        NEIGHBOUR_SAME_COLOR_GRID_ADD = 2, --与它相连成为一体的同色的地块每占一格分数就+1。
        NEIGHBOUR_DIFF_COLOR_GRID_MUL = 3, --跟此地块直接相连的不同色地块最终分数X2
        NEIGHBOUR_SAME_COLOR_GRID_MUL = 4, --跟此地块直接相连的同色地块最终分数X2
        LIKE = 5, --喜好
        DISLIKE = 6, --讨厌
        NEIGHBOUR_NOTHING = 7, -- 周围没有和任何东西相连
        NEIGHBOUR_SOME_THING_WITH_SCORE = 8, -- 周围有超过3分的艺术品
        PLAY_MOVIE_IF_EXCEED_A_CERTAIN_SCORE = 9, -- 超过一定分数后播放剧情
    },
    SCORE_TYPE = {
        TOTAL_SCORE = 1, -- 总分
        GRID_SCORE = 2, -- 格子分数
        PATH_SCORE = 3, -- 路径分数
        LIKE_SCORE = 4, -- 喜好分数（都由rule触发）
        TASK_SCORE = 5, -- 任务分数（都由rule触发）
        BASE_GIRD_SCORE = 6, -- 基础格子分(只作为预览使用)
    },
    SAVE_KEY_MODE_SCORE = "XTempleModeScore",
    OPERATION_TYPE = {
        ADD = 1,
        MODIFY = 2,
        DELETE = 3,
    },
    SHOP_ID = 1430,
    RULE_EFFECTIVE_RANGE = {
        GLOBAL = 1,
        GRID = 2,
    },
    CHAT_TYPE = {
        PATH_FAIL = 1,
        PUT_DOWN_BLOCK_FAIL = 2,
        PUT_DOWN_BLOCK_AND_SCORE = 3,
        GAME_SCORE = 4,
        ANY_BLOCK_UNUSED = 5,
        ANY_BLOCK_WITH_RULE = 6,
        FAVOURITE_BLOCK_UNUSED = 7,
        RULE = 8,
    },
    GRID = {
        EMPTY = 0, -- 空
        OBSTACLE = 100, -- 障碍物
        ENTRANCE = 101, -- 入口
        EXIT = 102, --出口
    },
    START_TYPE = {
        NORMAL = 1,
        LAST = 2,
        HISTORY = 3,
    },
    TASK = {
        [1] = 98881,    -- 页签1
        [2] = 98892,    -- 页签2
    }
}
return XTemple2Enum