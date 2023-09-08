---@class XRiftLuckyNodeData 幸运关信息
local XRiftLuckyNodeData = XClass(nil, "XRiftLuckyNodeData")

function XRiftLuckyNodeData:Ctor()
    self._ChapterId = nil
    self._LayerId = nil
    self._LuckyValue = 0
    self._AllMonsters = {}
    self._MaxLuckyValue = XDataCenter.RiftManager:GetMaxLuckyValue()
end

function XRiftLuckyNodeData:RefreshNode(data)
    self._ChapterId = data.ChapterId
    self._LayerId = data.LayerId
    self._StageDatas = data.StageDatas
end

function XRiftLuckyNodeData:RefreshLuckyValue(data)
    self._LuckyValue = data
end

function XRiftLuckyNodeData:GetLuckValueProgress()
    local progress = self._LuckyValue / self._MaxLuckyValue
    progress = progress >= 1 and 1 or progress
    progress = progress < 0 and 0 or progress
    return progress
end

---幸运关掉落由最高通关层决定
function XRiftLuckyNodeData:GetLuckPlugins()
    local layerId = XDataCenter.RiftManager.GetMaxPassFightLayerId()
    local config = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftLayerDetail)[layerId]
    return config and config.LuckPluginList or {}
end

---插件掉落概率
function XRiftLuckyNodeData:GetLuckPluginDrop(index)
    local layerId = XDataCenter.RiftManager.GetMaxPassFightLayerId()
    local config = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftLayerDetail)[layerId]
    return config.LuckPluginDropList[index] or 0
end

---和服务器约定协议，幸运节点的id为-1 不和 index同步
function XRiftLuckyNodeData:GetId()
    return -1
end

---最高通关层的
---@return XRiftFightLayer
function XRiftLuckyNodeData:GetLuckLayer()
    local layerId = XDataCenter.RiftManager.GetMaxPassFightLayerId()
    return XDataCenter.RiftManager.GetEntityFightLayerById(layerId)
end

---幸运关关卡Id
function XRiftLuckyNodeData:GetLuckStageId()
    if self._StageDatas then
        local riftStageId = self._StageDatas[1].RiftStageId
        if XTool.IsNumberValid(riftStageId) then
            local stage = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftStage)[riftStageId]
            return stage.StageId
        end
    end
    -- 开始战斗前服务端不会下发
    local maxPass = XDataCenter.RiftManager.GetMaxPassFightLayerId()
    local layer = XDataCenter.RiftManager.GetEntityFightLayerById(maxPass)
    local nodes = XRiftConfig.GetNodeRandomById(layer.Config.LuckyNodeRandomGroupId)
    local stageConfig = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftStage, nodes[1].RiftStageIds[1])
    return stageConfig.StageId -- 幸运关比较特殊
end

---@type XRiftMonster[]
function XRiftLuckyNodeData:GetLuckMonster()
    local stageId = self:GetLuckStageId()
    return XDataCenter.RiftManager:GetMonsterByStageId(stageId)
end

return XRiftLuckyNodeData