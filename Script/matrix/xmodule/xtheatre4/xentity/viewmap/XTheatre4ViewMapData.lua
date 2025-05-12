---@class XTheatre4ViewMapData
local XTheatre4ViewMapData = XClass(nil, "XTheatre4ViewMapData")

function XTheatre4ViewMapData:Ctor()
    -- 是否正在查看地图
    self.IsViewing = false
    -- 弹框参数列表
    self.PopupArgsList = false
    -- 进入类型
    self.EnterType = 0
end

function XTheatre4ViewMapData:SetIsViewing(isViewing)
    self.IsViewing = isViewing
end

function XTheatre4ViewMapData:AddPopupArgs(uiName, args)
    if not self.PopupArgsList then
        self.PopupArgsList = {}
    end
    self.PopupArgsList[uiName] = args
end

function XTheatre4ViewMapData:ClearPopupArgs()
    self.PopupArgsList = nil
end

function XTheatre4ViewMapData:SetEnterType(enterType)
    self.EnterType = enterType
end

function XTheatre4ViewMapData:GetIsViewing()
    return self.IsViewing or false
end

function XTheatre4ViewMapData:GetPopupArgs(uiName)
    if not self.PopupArgsList then
        return nil
    end
    return self.PopupArgsList[uiName] or nil
end

function XTheatre4ViewMapData:GetEnterType()
    return self.EnterType or 0
end

return XTheatre4ViewMapData
