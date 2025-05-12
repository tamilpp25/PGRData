---@class XRiftLuckyNodeData 幸运关信息
local XRiftLuckyNodeData = XClass(nil, "XRiftLuckyNodeData")

function XRiftLuckyNodeData:Ctor()
    self._ChapterId = nil
    self._LayerId = nil
    self._LuckyValue = 0
    self._PassTime = 0
end

function XRiftLuckyNodeData:RefreshNode(data)
    self._ChapterId = data.ChapterId
    self._LayerId = data.LayerId
    self._StageDatas = data.StageDatas
end

function XRiftLuckyNodeData:RefreshLuckyValue(data)
    self._LuckyValue = data
end

function XRiftLuckyNodeData:GetLuckyValue()
    return self._LuckyValue
end

---和服务器约定协议，幸运节点的id为-1 不和 index同步
function XRiftLuckyNodeData:GetId()
    return -1
end

function XRiftLuckyNodeData:GetLuckRiftChapterId()
    return self._ChapterId
end

function XRiftLuckyNodeData:GetLuckRiftLayerId()
    return self._LayerId
end

---幸运关关卡Id
function XRiftLuckyNodeData:GetLuckRiftStageId()
    return self._StageDatas and self._StageDatas[1].RiftStageId or nil
end

function XRiftLuckyNodeData:SetPassTime(time)
    self._PassTime = time
end

function XRiftLuckyNodeData:GetPassTime()
    return self._PassTime
end

return XRiftLuckyNodeData