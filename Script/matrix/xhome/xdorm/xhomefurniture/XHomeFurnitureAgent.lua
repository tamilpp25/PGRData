local XHomeFurnitureAgent = XLuaBehaviorManager.RegisterAgent(XLuaBehaviorAgent, "HomeFurniture")

function XHomeFurnitureAgent:OnAwake()
    self.Path = {}
end

-- 设置家具数据
function XHomeFurnitureAgent:SetHomeFrunitureObj(homeFurnitureObj)
    self.HomeFurnitureObj = homeFurnitureObj
end

-- 状态改变
function XHomeFurnitureAgent:ChangeStatus(state)
    self.HomeFurnitureObj:ChangeStatus(state)
end

-- 检测是否在家具上方
function XHomeFurnitureAgent:CheckRayCastFurnitureNode()
    return self.HomeFurnitureObj:CheckRayCastFurnitureNode()
end

-- 还原家具位置
function XHomeFurnitureAgent:ResetFurnituePistionNode()
    return self.HomeFurnitureObj:ResetFurnituePistionNode()
end

 -- 播放家具动画
function XHomeFurnitureAgent:DoActionNode(actionId,needFadeCross,crossDuration)
    return self.HomeFurnitureObj:DoActionNode(actionId,needFadeCross,crossDuration)
end

 -- 播放家具特效
function XHomeFurnitureAgent:DoEffectNode(effectId)
    return self.HomeFurnitureObj:DoEffectNode(effectId)
end

 -- 隐藏家具
function XHomeFurnitureAgent:HideFurnitureNode()
    return self.HomeFurnitureObj:HideFurnitureNode()
end

 -- 改变家具位置
function XHomeFurnitureAgent:ChangeFurnituePositionNode()
    return self.HomeFurnitureObj:ChangeFurnituePositionNode()
end

-- 保存家具变更所在房间
function XHomeFurnitureAgent:SaveFurnitureInRoomNode()
    self.HomeFurnitureObj:SaveFurnitureInRoomNode()
end

-- 获取ID
function XHomeFurnitureAgent:GetId()
    return self.HomeFurnitureObj.Data.Id
end
