---@class XRogueSimPropBox
local XRogueSimPropBox = XClass(nil, "XRogueSimPropBox")

function XRogueSimPropBox:Ctor()
    -- 唯一键生成序列
    self.Sequence = 0
    -- 道具数据列表
    ---@type XRogueSimProp[]
    self.PropData = {}
end

function XRogueSimPropBox:UpdatePropBoxData(data)
    self.Sequence = data.Sequence or 0
    self.PropData = {}
    self:UpdatePropData(data.PropDatas)
end

function XRogueSimPropBox:UpdatePropData(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddPropData(v)
    end
end

function XRogueSimPropBox:AddPropData(data)
    if not data then
        return
    end
    local prop = self.PropData[data.Id]
    if not prop then
        prop = require("XModule/XRogueSim/XEntity/XRogueSimProp").New()
        self.PropData[data.Id] = prop
    end
    prop:UpdatePropData(data)
end

-- 获取道具数据列表
function XRogueSimPropBox:GetPropData()
    return self.PropData
end

-- 获取道具数据通过自增Id
function XRogueSimPropBox:GetPropDataById(id)
    return self.PropData[id] or nil
end

return XRogueSimPropBox
