XDataCenter.BountyTaskManager = {}
setmetatable(XDataCenter.BountyTaskManager,
        {
            __index = function(table, key, value)
                XLog.Error("[BountyTaskManager] 赏金优化, 该副本已被屏蔽，如有问题，请联系立斌，谢谢")
            end
        })

XDataCenter.MonsterCombatManager = {}
setmetatable(XDataCenter.MonsterCombatManager,
        {
            __index = function(table, key, value)
                XLog.Error("[MonsterCombatManager] 战双BVB, 该副本已被屏蔽，如有问题，请联系立斌，谢谢")
            end
        })

XDataCenter.NieRManager = {}
setmetatable(XDataCenter.NieRManager,
        {
            __index = function(table, key, value)
                XLog.Error("[NieRManager] 尼尔, 该副本已被屏蔽，如有问题，请联系立斌，谢谢")
            end
        })

XDataCenter.FashionStoryManager = {}
setmetatable(XDataCenter.FashionStoryManager,
        {
            __index = function(table, key, value)
                XLog.Error("[FashionStoryManager] 涂装剧情, 该副本暂时被屏蔽，请在优化后提交，如有问题，请联系立斌，谢谢")
                XLog.Error("[FashionStoryManager] FubenActivity.tab表也要填上FashionStoryManager")
            end
        })
